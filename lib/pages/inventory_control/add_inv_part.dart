import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/part.dart';

class AddNewPartScreen extends StatefulWidget {
  final Part? part;
  final String? documentId;

  const AddNewPartScreen({Key? key, this.part, this.documentId})
    : super(key: key);

  @override
  _AddNewPartScreenState createState() => _AddNewPartScreenState();
}

class _AddNewPartScreenState extends State<AddNewPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partNameController = TextEditingController();
  final _partIdController = TextEditingController();
  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _supplierEmailController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _isLowStockController = TextEditingController();
  // Supplier fields
  final _supplierLeadTimeController = TextEditingController();
  final _supplierMinOrderQtyController = TextEditingController();
  final _supplierIsPrimaryController = TextEditingController();
  final _supplierReliabilityScoreController = TextEditingController();
  final _supplierPriceController = TextEditingController();

  String? selectedCategory;
  List<String> categories = [];
  bool _isLoading = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchNextSparePartId();
    _testFirestoreConnection();
    if (widget.part != null) {
      _partNameController.text = widget.part!.name;
      _partIdController.text = widget.part!.id;
      _supplierController.text = widget.part!.supplier;
      _descriptionController.text = widget.part!.description;
      _lowStockThresholdController.text = widget.part!.lowStockThreshold.toString();
      selectedCategory = widget.part!.category;
      _supplierEmailController.text = widget.part!.supplierEmail;
      _priceController.text = widget.part!.price.toString();
      _quantityController.text = widget.part!.quantity.toString();
      _isLowStockController.text = widget.part!.isLowStock.toString();
      // Supplier fields - properly access map values
      if (widget.part!.suppliers.isNotEmpty) {
        var supplier = widget.part!.suppliers.first;
        _supplierLeadTimeController.text = (supplier['leadTime'] ?? 0).toString();
        _supplierMinOrderQtyController.text = (supplier['minOrderQty'] ?? 1).toString();
        _supplierIsPrimaryController.text = (supplier['isPrimary'] ?? true).toString();
        _supplierReliabilityScoreController.text = (supplier['reliabilityScore'] ?? 1.0).toString();
        _supplierPriceController.text = (supplier['price'] ?? 0).toString();
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('inventory_parts').get();
      List<String> fetchedCategories = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      setState(() {});
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchNextSparePartId() async {
    try {
      final categoriesSnapshot = await _firestore.collection('inventory_parts').get();
      List<String> categoryNames = categoriesSnapshot.docs.map((doc) => doc.id).toList();
      List<String> ids = [];
      for (final category in categoryNames) {
        final categoryDoc = await _firestore.collection('inventory_parts').doc(category).get();
        if (categoryDoc.exists) {
          final categoryData = categoryDoc.data();
          if (categoryData != null) {
            categoryData.forEach((key, value) {
              if (value is Map<String, dynamic> && value.containsKey('id')) {
                final id = value['id'];
                if (id is String && id.startsWith('PRT')) {
                  ids.add(id);
                }
              }
            });
          }
        }
      }
      int maxId = 0;
      for (var id in ids) {
        final match = RegExp(r'PRT(\d{3})').firstMatch(id);
        if (match != null) {
          int num = int.parse(match.group(1)!);
          if (num > maxId) maxId = num;
        }
      }
      String nextId = 'PRT' + (maxId + 1).toString().padLeft(3, '0');
      if (mounted) {
        setState(() {
          _partIdController.text = nextId;
        });
      }
    } catch (e) {
      print('Error fetching next part id: $e');
      if (mounted) {
        setState(() {
          _partIdController.text = 'PRT001';
        });
      }
    }
  }

  // Test Firestore connection
  Future<void> _testFirestoreConnection() async {
    try {
      // Try to write a test document
      await _firestore.collection('connection_test').doc('test').set({
        'message': 'Firestore connected successfully!',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore connection successful!');


    } catch (e) {
      print('❌ Firestore connection failed: $e');

    }
  }

  // Add or Edit part in Firestore
  Future<void> _submitPartToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // Use part ID as field name in the category document (based on database structure)
      String partFieldName = _partIdController.text.trim(); // Use part ID as field name
      int lowStockThreshold = int.tryParse(_lowStockThresholdController.text.trim()) ?? 0;

      Map<String, dynamic> partData = {
        'id': _partIdController.text.trim(),
        'name': _partNameController.text.trim(),
        'category': selectedCategory,
        'description': _descriptionController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'lowStockThreshold': int.tryParse(_lowStockThresholdController.text.trim()) ?? 0,
        'isLowStock': (int.tryParse(_quantityController.text.trim()) ?? 0) <= lowStockThreshold,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'suppliers': [
          {
            'email': _supplierEmailController.text.trim(),
            'isPrimary': (_supplierIsPrimaryController.text.trim().toLowerCase() == 'true'),
            'leadTime': int.tryParse(_supplierLeadTimeController.text.trim()) ?? 0,
            'minOrderQty': int.tryParse(_supplierMinOrderQtyController.text.trim()) ?? 1,
            'name': _supplierController.text.trim(),
            'price': double.tryParse(_supplierPriceController.text.trim()) ?? 0,
            'reliabilityScore': double.tryParse(_supplierReliabilityScoreController.text.trim()) ?? 1.0,
          }
        ],
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.documentId != null) {
        // Edit existing part - update the field in the category document using part ID as field name
        await _firestore
            .collection('inventory_parts')
            .doc(selectedCategory)
            .update({
              partFieldName: partData,
            });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Part updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new part as a field in the category document using part ID as field name
        await _firestore
            .collection('inventory_parts')
            .doc(selectedCategory)
            .update({
              partFieldName: partData,  // Add part using part ID as field name
            });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Part added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Part',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Create inventory part',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Form Content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionCard(
                        title: 'Basic Information',
                        icon: Icons.info_outline,
                        color: Colors.blue,
                        children: [
                          _buildInputField(
                            label: 'Part Name',
                            controller: _partNameController,
                            hintText: 'Enter part name',
                            isRequired: true,
                            icon: Icons.build_circle_outlined,
                          ),
                          SizedBox(height: 16),
                          _buildReadOnlyField(
                            label: 'Part ID',
                            value: _partIdController.text,
                            icon: Icons.qr_code,
                          ),
                          SizedBox(height: 16),
                          _buildCategoryDropdown(),
                          SizedBox(height: 16),
                          _buildDescriptionField(),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Stock & Pricing Section
                      _buildSectionCard(
                        title: 'Stock & Pricing',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.green,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Quantity',
                                  controller: _quantityController,
                                  hintText: '0',
                                  isRequired: true,
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Price (RM)',
                                  controller: _priceController,
                                  hintText: '0.00',
                                  isRequired: true,
                                  icon: Icons.attach_money,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInputField(
                            label: 'Low Stock Threshold',
                            controller: _lowStockThresholdController,
                            hintText: 'Enter threshold value',
                            isRequired: true,
                            icon: Icons.warning_amber_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Supplier Information Section
                      _buildSectionCard(
                        title: 'Primary Supplier',
                        icon: Icons.business_outlined,
                        color: Colors.orange,
                        children: [
                          _buildInputField(
                            label: 'Supplier Name',
                            controller: _supplierController,
                            hintText: 'Enter supplier name',
                            isRequired: true,
                            icon: Icons.store,
                          ),
                          SizedBox(height: 16),
                          _buildInputField(
                            label: 'Supplier Email',
                            controller: _supplierEmailController,
                            hintText: 'supplier@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Lead Time (days)',
                                  controller: _supplierLeadTimeController,
                                  hintText: '7',
                                  isRequired: true,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Min Order Qty',
                                  controller: _supplierMinOrderQtyController,
                                  hintText: '1',
                                  isRequired: true,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Supplier Price (RM)',
                                  controller: _supplierPriceController,
                                  hintText: '0.00',
                                  isRequired: true,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Reliability Score',
                                  controller: _supplierReliabilityScoreController,
                                  hintText: '0.85',
                                  isRequired: true,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildSwitchField(
                            label: 'Set as Primary Supplier',
                            controller: _supplierIsPrimaryController,
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPartToFirestore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading ? Colors.grey[300] : Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: Colors.blue.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Adding Part...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Part',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 20), // Bottom padding for scroll
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Section Card Builder
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Read-only Field
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.blue[600], size: 20),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value.isEmpty ? 'Auto-generated' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced Category Dropdown
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedCategory == null ? Colors.red[300]! : Colors.grey[300]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Icon(Icons.category_outlined, color: Colors.grey[600], size: 20),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text(
                      'Select category',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selectedCategory == null)
          Padding(
            padding: EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Please select a category',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Enhanced Description Field
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter part description...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16, right: 12, top: 16),
                child: Icon(Icons.description_outlined, color: Colors.grey[600], size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced Switch Field
  Widget _buildSwitchField({
    required String label,
    required TextEditingController controller,
  }) {
    bool switchValue = controller.text.toLowerCase() == 'true';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: switchValue ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: switchValue ? Colors.blue[200]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            switchValue ? Icons.star : Icons.star_outline,
            color: switchValue ? Colors.blue[600] : Colors.grey[600],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: switchValue ? Colors.blue[800] : Colors.grey[700],
              ),
            ),
          ),
          Switch(
            value: switchValue,
            onChanged: (value) {
              setState(() {
                controller.text = value.toString();
              });
            },
            activeColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  // Enhanced Input Field Builder
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    if (keyboardType == TextInputType.number ||
                        keyboardType == TextInputType.numberWithOptions(decimal: true)) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid number';
                      }
                    }
                    if (keyboardType == TextInputType.emailAddress) {
                      if (!value.contains('@') && value.trim().isNotEmpty) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  }
                : null,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: icon != null
                  ? Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(icon, color: Colors.grey[600], size: 20),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _partIdController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    _lowStockThresholdController.dispose();
    _supplierEmailController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _isLowStockController.dispose();
    _supplierLeadTimeController.dispose();
    _supplierMinOrderQtyController.dispose();
    _supplierIsPrimaryController.dispose();
    _supplierReliabilityScoreController.dispose();
    _supplierPriceController.dispose();
    super.dispose();
  }
}
