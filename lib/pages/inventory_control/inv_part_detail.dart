import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/inventory_control/procurement_dialog.dart';
import '../../models/part.dart';

class PartDetailsScreen extends StatelessWidget {
  final Part? part;

  const PartDetailsScreen({Key? key, this.part}) : super(key: key);

  Future<void> _deletePart(BuildContext context, String categoryId, String partName) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // First check if quantity is 0
      final doc = await firestore.collection('inventory_parts').doc(categoryId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final partData = data[partName] as Map<String, dynamic>?;

        if (partData != null) {
          int quantity = partData['quantity'] ?? 0;

          if (quantity > 0) {
            // Cannot delete - quantity is not 0
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Cannot delete part: Quantity must be 0 before deletion. Current quantity: $quantity'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      }

      // Quantity is 0, proceed with deletion
      await firestore.collection('inventory_parts').doc(categoryId).update({partName: FieldValue.delete()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Part deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting part: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, String categoryId, String partName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Part'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this part?'),
            SizedBox(height: 8),
            Text(
              'Part: $partName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                '⚠️ Note: Parts can only be deleted if quantity is 0',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePart(context, categoryId, partName);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditPartDialog(BuildContext context, Part part) {
    final TextEditingController nameController = TextEditingController(text: part.name);
    final TextEditingController supplierController = TextEditingController(text: part.supplier);
    final TextEditingController thresholdController = TextEditingController(text: part.lowStockThreshold.toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue[700], size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Edit Part Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Part Overview Section
                          Text(
                            'Part Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 12),

                          // Read-only information
                          _buildReadOnlyField('Part ID', part.id),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Category', part.category),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Current Quantity', '${part.quantity}'),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Description', part.description.isNotEmpty ? part.description : 'Not specified'),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Supplier', part.supplier.isNotEmpty ? part.supplier : 'Not specified'),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Barcode', part.barcode.isNotEmpty ? part.barcode : 'Not specified'),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Price', part.price > 0 ? '\$${part.price.toStringAsFixed(2)}' : 'Not specified'),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Unit', part.unit.isNotEmpty ? part.unit : 'Not specified'),

                          SizedBox(height: 24),

                          // Editable Section
                          Text(
                            'Editable Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 12),

                          // Editable Part Name
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Part Name *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.build),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Part name is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Editable Supplier
                          TextFormField(
                            controller: supplierController,
                            decoration: InputDecoration(
                              labelText: 'Supplier',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Editable Low Stock Threshold
                          TextFormField(
                            controller: thresholdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Low Stock Threshold *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.warning),
                              helperText: 'Alert when quantity falls below this number',
                            ),
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
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await _updatePart(
                                  context,
                                  part,
                                  nameController.text.trim(),
                                  supplierController.text.trim(),
                                  int.parse(thresholdController.text.trim()),
                                );
                                Navigator.pop(ctx);
                                Navigator.pop(context); // Go back to previous screen
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Error updating part: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
        ),
      )
      );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updatePart(BuildContext context, Part part, String newName, String newSupplier, int newThreshold) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Calculate new low stock status
      bool newIsLowStock = part.quantity <= newThreshold;

      Map<String, dynamic> updatedData = {
        'name': newName,
        'sparePartId': part.id,
        'category': part.category,
        'supplier': newSupplier,
        'quantity': part.quantity,
        'lowStockThreshold': newThreshold,
        'description': part.description,
        'manufacturer': part.manufacturer,
        'barcode': part.barcode,
        'price': part.price,
        'unit': part.unit,
        'isLowStock': newIsLowStock,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If the part name changed, we need to delete the old field and create a new one
      if (newName != part.name) {
        // Delete old field
        await firestore.collection('inventory_parts').doc(part.category).update({
          part.name: FieldValue.delete(),
        });

        // Add new field with updated name
        await firestore.collection('inventory_parts').doc(part.category).update({
          newName: updatedData,
        });
      } else {
        // Just update the existing field
        await firestore.collection('inventory_parts').doc(part.category).update({
          part.name: updatedData,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Part updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      throw e;
    }
  }

  // Replace your existing _showProcurementRequestDialog method with this simple version:
  // Replace your existing _showProcurementRequestDialog method with this simple version:
  void _showProcurementRequestDialog(BuildContext context, Part part) {
    showDialog(
      context: context,
      builder: (ctx) => EnhancedProcurementDialog(part: part),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use provided part or default values
    final displayPart =
        part ??
        Part(
          id: 'PRT001',
          name: 'Spark Plug',
          quantity: 42,
          isLowStock: false,
          category: 'Engine',
          manufacturer: 'EngineCorp',
          description: 'High-quality spark plug for automotive engines',
          documentId: '',
          lowStockThreshold: 15, // Use default threshold for demo part
        );

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
                    'Part Details',
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
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Part Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Part Title
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      displayPart.category,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(displayPart.category),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayPart.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (displayPart
                                          .description
                                          .isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          displayPart.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Part Info Tags
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildInfoTag(
                                  'Part ID: ${displayPart.id}',
                                  Colors.grey[300]!,
                                ),
                                _buildInfoTag(
                                  displayPart.category,
                                  _getCategoryColor(
                                    displayPart.category,
                                  ).withValues(alpha: 0.2),
                                ),
                                if (displayPart.isLowStock)
                                  _buildInfoTag(
                                    'Low Stock',
                                    Colors.red[100]!,
                                    textColor: Colors.red[700]!,
                                  ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // Stock Information Section
                            _buildSectionHeader('Stock Information'),
                            SizedBox(height: 16),

                            // Stock Info Card
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Current Quantity',
                                    '${displayPart.quantity}',
                                  ),
                                  SizedBox(height: 12),
                                  _buildInfoRow('Reorder Level', '${displayPart.lowStockThreshold}'),
                                  SizedBox(height: 12),
                                  _buildStockLevelBar(displayPart.quantity, displayPart.lowStockThreshold),
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Supplier',
                                    displayPart.supplier.isNotEmpty
                                        ? displayPart.supplier
                                        : 'Not specified',
                                  ),
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Status',
                                    displayPart.isLowStock
                                        ? 'Low Stock'
                                        : 'In Stock',
                                  ),
                                  if (displayPart.isLowStock || displayPart.quantity <= displayPart.lowStockThreshold) ...[
                                    SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _showProcurementRequestDialog(context, displayPart),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text('Request to Reload Stock'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 32),

                            // Usage History Section
                            _buildSectionHeader('Recent Activity'),
                            SizedBox(height: 16),

                            // Usage History Items (Sample data - you can extend this with real data)
                            _buildUsageHistoryItem(
                              'Used in Service',
                              '03/03/2025',
                              '-2',
                              Colors.red,
                            ),
                            SizedBox(height: 12),
                            _buildUsageHistoryItem(
                              'Restocked',
                              '01/03/2025',
                              '+20',
                              Colors.green,
                            ),
                            SizedBox(height: 40),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showEditPartDialog(context, displayPart);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Edit Part',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (displayPart.documentId.isNotEmpty) {
                                        _showDeleteDialog(
                                          context,
                                          displayPart.documentId,
                                          displayPart.name,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '❌ Cannot delete: No documentId',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[50],
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Delete Part',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoTag(String text, Color backgroundColor, {Color? textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageHistoryItem(
    String title,
    String date,
    String quantity,
    Color quantityColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            quantity,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: quantityColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelBar(int quantity, int reorderLevel) {
    double percent = reorderLevel > 0 ? (quantity / reorderLevel) : 1.0;
    percent = percent.clamp(0.0, 2.0); // Cap at 2x reorder level
    Color barColor;
    if (percent > 1.2) {
      barColor = Colors.green;
    } else if (percent > 1.0) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Level: $quantity / $reorderLevel',
          style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent > 2.0 ? 1.0 : percent / 2.0, // 100% = 2x reorder level
            minHeight: 16,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        SizedBox(height: 4),
        Text(
          percent <= 1.0
              ? 'Below Reorder Level'
              : percent <= 1.2
                  ? 'Near Reorder Level'
                  : 'Stock Sufficient',
          style: TextStyle(
            fontSize: 12,
            color: barColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Colors.blue;
      case 'brakes':
        return Colors.red;
      case 'tires':
        return Colors.orange;
      case 'suspension':
        return Colors.green;
      case 'electrical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Icons.settings;
      case 'brakes':
        return Icons.stop_circle;
      case 'tires':
        return Icons.circle;
      case 'suspension':
        return Icons.height;
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.build;
    }
  }
}
