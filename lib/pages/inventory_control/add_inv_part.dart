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
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? selectedCategory;
  List<String> categories = [];
  bool _isLoading = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _testFirestoreConnection();
    if (widget.part != null) {
      _partNameController.text = widget.part!.name;
      _partIdController.text = widget.part!.id;
      _supplierController.text = widget.part!.supplier;
      _quantityController.text = widget.part!.quantity.toString();
      _descriptionController.text = widget.part!.description;
      selectedCategory = widget.part!.category;
      // Safe access to barcode field
      if (widget.part!.barcode.isNotEmpty) {
        _barcodeController.text = widget.part!.barcode;
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

  // Test Firestore connection
  Future<void> _testFirestoreConnection() async {
    try {
      // Try to write a test document
      await _firestore.collection('connection_test').doc('test').set({
        'message': 'Firestore connected successfully!',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore connection successful!');

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Firestore connected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firestore connection failed: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Scan Barcode


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
      Map<String, dynamic> partData = {
        'partName': _partNameController.text.trim(),
        'partId': _partIdController.text.trim(),
        'category': selectedCategory,
        'supplier': _supplierController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'isLowStock': (int.tryParse(_quantityController.text.trim()) ?? 0) < 15,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.documentId != null) {
        // Edit
        await _firestore
            .collection('inventory_parts')
            .doc(widget.documentId)
            .update(partData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Part updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add
        partData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('inventory_parts').add(partData);
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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Add New Part',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header inside white container
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Add New Part',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parts Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 20),

                              // Part Name
                              _buildInputField(
                                label: 'Part Name :',
                                controller: _partNameController,
                                hintText: 'Enter Part Name',
                                isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Part ID
                              _buildInputField(
                                label: 'Part ID:',
                                controller: _partIdController,
                                hintText: 'Enter Part ID',
                                isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Category Dropdown
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category : *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedCategory == null
                                            ? Colors.red[300]!
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCategory,
                                        hint: Text(
                                          'Select Category',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        items: categories.map((
                                          String category,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Text(category),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedCategory = newValue;
                                          });
                                        },
                                        icon: Icon(Icons.keyboard_arrow_down),
                                        iconSize: 24,
                                        isExpanded: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Supplier
                              _buildInputField(
                                label: 'Supplier :',
                                controller: _supplierController,
                                hintText: 'Enter Supplier Name',
                                isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Quantity
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quantity *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    width: 120,
                                    child: TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Enter valid number';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Description
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description :',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    height: 100,
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextFormField(
                                      controller: _descriptionController,
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter description...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Barcode field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Barcode:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _barcodeController,
                                          decoration: InputDecoration(
                                            hintText: 'Scan or enter barcode',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 40),

                              // Add Part Button
                              Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _submitPartToFirestore,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoading
                                        ? Colors.grey[300]
                                        : Colors.blue[50],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.blue),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Adding Part...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Add Part to Firestore',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    _quantityController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
