import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/part.dart';

class EditPartBottomSheet extends StatefulWidget {
  final Part part;

  const EditPartBottomSheet({Key? key, required this.part}) : super(key: key);

  @override
  _EditPartBottomSheetState createState() => _EditPartBottomSheetState();
}

class _EditPartBottomSheetState extends State<EditPartBottomSheet> {
  late TextEditingController nameController;
  late TextEditingController thresholdController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController unitController;
  final _formKey = GlobalKey<FormState>();

  // Supplier management
  List<Map<String, TextEditingController>> supplierControllers = [];
  List<bool> isPrimaryList = [];
  List<TextEditingController> priceControllers = [];
  List<TextEditingController> leadTimeControllers = [];
  List<TextEditingController> minOrderQtyControllers = [];
  List<TextEditingController> reliabilityScoreControllers = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.part.name);
    thresholdController = TextEditingController(text: widget.part.lowStockThreshold.toString());
    descriptionController = TextEditingController(text: widget.part.description);
    priceController = TextEditingController(text: widget.part.price > 0 ? widget.part.price.toStringAsFixed(2) : '');
    unitController = TextEditingController(text: widget.part.unit);

    // Initialize supplier controllers from part.suppliers
    if (widget.part.suppliers.isNotEmpty) {
      for (var supplier in widget.part.suppliers) {
        _addSupplierController(
          name: supplier['name']?.toString() ?? '',
          email: supplier['email']?.toString() ?? '',
          isPrimary: supplier['isPrimary'] ?? false,
          price: supplier['price']?.toString() ?? '',
          leadTime: supplier['leadTime']?.toString() ?? '',
          minOrderQty: supplier['minOrderQty']?.toString() ?? '',
          reliabilityScore: supplier['reliabilityScore']?.toString() ?? '',
        );
      }
    } else {
      _addSupplierController(); // Show one empty field if no suppliers
    }
  }

  void dispose() {
    nameController.dispose();
    thresholdController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    unitController.dispose();

    // Dispose all supplier controllers
    for (var controllers in supplierControllers) {
      controllers['name']?.dispose();
      controllers['email']?.dispose();
      priceControllers[supplierControllers.indexOf(controllers)].dispose();
      leadTimeControllers[supplierControllers.indexOf(controllers)].dispose();
      minOrderQtyControllers[supplierControllers.indexOf(controllers)].dispose();
      reliabilityScoreControllers[supplierControllers.indexOf(controllers)].dispose();
    }
    super.dispose();
  }

  void _addSupplierController({String name = '', String email = '', bool isPrimary = false, String price = '', String leadTime = '', String minOrderQty = '', String reliabilityScore = ''}) {
    setState(() {
      supplierControllers.add({
        'name': TextEditingController(text: name),
        'email': TextEditingController(text: email),
      });
      isPrimaryList.add(isPrimary);
      priceControllers.add(TextEditingController(text: price));
      leadTimeControllers.add(TextEditingController(text: leadTime));
      minOrderQtyControllers.add(TextEditingController(text: minOrderQty));
      reliabilityScoreControllers.add(TextEditingController(text: reliabilityScore));
    });
  }

  void _removeSupplierController(int index) {
    if (supplierControllers.length > 1) {
      setState(() {
        supplierControllers[index]['name']?.dispose();
        supplierControllers[index]['email']?.dispose();
        priceControllers[index].dispose();
        leadTimeControllers[index].dispose();
        minOrderQtyControllers[index].dispose();
        reliabilityScoreControllers[index].dispose();
        supplierControllers.removeAt(index);
        isPrimaryList.removeAt(index);
        priceControllers.removeAt(index);
        leadTimeControllers.removeAt(index);
        minOrderQtyControllers.removeAt(index);
        reliabilityScoreControllers.removeAt(index);
      });
    }
  }

  Widget _buildSupplierField(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business, color: Colors.green[700], size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Supplier ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (isPrimaryList[index]) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Primary',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: supplierControllers.length > 1 ? Colors.red[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: supplierControllers.length > 1 ? Colors.red[200]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: supplierControllers.length > 1 ? () => _removeSupplierController(index) : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: supplierControllers.length > 1 ? Colors.red[600] : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: supplierControllers[index]['name'],
                      decoration: InputDecoration(
                        labelText: 'Supplier Name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: supplierControllers[index]['email'],
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: priceControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Price (RM)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        prefixText: 'RM ',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: leadTimeControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Lead Time (days)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: minOrderQtyControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Min Order Qty',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: reliabilityScoreControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Reliability Score',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPrimaryList[index] ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimaryList[index] ? Colors.blue[200]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Switch(
                    value: isPrimaryList[index],
                    onChanged: (val) {
                      setState(() {
                        for (int i = 0; i < isPrimaryList.length; i++) {
                          isPrimaryList[i] = false;
                        }
                        isPrimaryList[index] = val;
                      });
                    },
                    activeColor: Colors.blue[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set as Primary Supplier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isPrimaryList[index] ? Colors.blue[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePart() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Collect suppliers data
        List<Map<String, dynamic>> suppliers = [];
        for (int i = 0; i < supplierControllers.length; i++) {
          String name = supplierControllers[i]['name']!.text.trim();
          String email = supplierControllers[i]['email']!.text.trim();
          String price = priceControllers[i].text.trim();
          String leadTime = leadTimeControllers[i].text.trim();
          String minOrderQty = minOrderQtyControllers[i].text.trim();
          String reliabilityScore = reliabilityScoreControllers[i].text.trim();
          bool isPrimary = isPrimaryList[i];

          if (name.isNotEmpty || email.isNotEmpty) {
            // Create supplier data
            Map<String, dynamic> supplierData = {
              'name': name,
              'email': email,
              'isPrimary': isPrimary,
              'price': double.tryParse(price) ?? 0.0,
              'leadTime': int.tryParse(leadTime) ?? 3,
              'minOrderQty': int.tryParse(minOrderQty) ?? 10,
              'reliabilityScore': double.tryParse(reliabilityScore) ?? 0.85,
            };

            suppliers.add(supplierData);
          }
        }

        final firestore = FirebaseFirestore.instance;
        final lowStockThreshold = int.parse(thresholdController.text.trim());
        final updatedPrice = double.tryParse(priceController.text.trim()) ?? widget.part.price;

        // Get the correct part ID - prioritize the existing ID structure
        String partId = widget.part.id.isNotEmpty ? widget.part.id :
                       widget.part.sparePartId.isNotEmpty ? widget.part.sparePartId :
                       'PRT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

        // Create updated part data that matches the Firestore structure
        final updatedPartData = {
          'id': partId,
          'name': nameController.text.trim(),
          'category': widget.part.category,
          'quantity': widget.part.quantity, // preserve current quantity
          'isLowStock': widget.part.quantity <= lowStockThreshold,
          'lowStockThreshold': lowStockThreshold,
          'description': descriptionController.text.trim(),
          'price': updatedPrice,
          'unit': unitController.text.trim(),
          'suppliers': suppliers,
          'manufacturer': widget.part.manufacturer, // preserve existing manufacturer
          'barcode': widget.part.barcode, // preserve existing barcode
          'supplier': suppliers.isNotEmpty ? suppliers.first['name'] : widget.part.supplier, // use first supplier as main supplier
          'supplierEmail': suppliers.isNotEmpty ? suppliers.first['email'] : widget.part.supplierEmail,
          'sparePartId': partId, // ensure sparePartId is set
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('🔧 Updating part with data: $updatedPartData');
        print('📍 Document path: inventory_parts/${widget.part.category}');
        print('🔑 Field key: $partId');

        // Update the part in Firestore using the correct document structure
        await firestore.collection('inventory_parts').doc(widget.part.category).update({
          partId: updatedPartData  // Use part ID as field name
        });

        // Hide loading indicator
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Part updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Close the bottom sheet and return to previous screen
        Navigator.pop(context);

        // Optionally navigate back to refresh the previous screen
        Navigator.pop(context);

      } catch (e) {
        // Hide loading indicator if still showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        print('❌ Error updating part: $e');
        print('📊 Part data attempted: ${widget.part.toString()}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error updating part: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updatePart(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildReadOnlyField(String label, String value) {
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
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? helperText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
          prefixText: prefixText,
          helperText: helperText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the part ID - prioritize sparePartId, then id, then generate one
    String partId = widget.part.sparePartId.isNotEmpty
        ? widget.part.sparePartId
        : widget.part.id.isNotEmpty
            ? widget.part.id
            : 'PRT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Part Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Part ID: $partId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Section with better design
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.info, color: Colors.blue[700], size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Part Overview',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildReadOnlyField('Part ID', partId),
                            SizedBox(height: 16),
                            _buildReadOnlyField('Category', widget.part.category),
                            SizedBox(height: 16),
                            _buildTextFormField(
                              controller: nameController,
                              labelText: 'Part Name *',
                              prefixIcon: Icons.build,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Part name is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Stock Info Section with enhanced design
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[200]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.inventory, color: Colors.orange[700], size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Stock Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildReadOnlyField('Current Quantity', '${widget.part.quantity}'),
                            SizedBox(height: 16),
                            _buildTextFormField(
                              controller: thresholdController,
                              labelText: 'Low Stock Threshold *',
                              prefixIcon: Icons.warning,
                              keyboardType: TextInputType.number,
                              helperText: 'Alert when quantity falls below this number',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Threshold is required';
                                }
                                final threshold = int.tryParse(value.trim());
                                if (threshold == null || threshold < 0) {
                                  return 'Please enter a valid number (0 or greater)';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFormField(
                                    controller: priceController,
                                    labelText: 'Price (RM)',
                                    prefixText: 'RM ',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextFormField(
                                    controller: unitController,
                                    labelText: 'Unit',
                                    prefixIcon: Icons.straighten,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Description Section
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple[200]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.description, color: Colors.purple[700], size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Additional Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildTextFormField(
                              controller: descriptionController,
                              labelText: 'Description',
                              prefixIcon: Icons.description,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Suppliers Section with enhanced design
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.08),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.business, color: Colors.green[700], size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Supplier Management',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ...supplierControllers.asMap().entries.map((entry) {
                              return _buildSupplierField(entry.key);
                            }).toList(),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _addSupplierController(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Supplier',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Enhanced Footer with action buttons
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[800]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _updatePart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

