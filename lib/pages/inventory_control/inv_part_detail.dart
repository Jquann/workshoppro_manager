import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/inventory_control/procurement_dialog.dart' as pd show EnhancedProcurementDialog;
import '../../models/part.dart';
import 'edit_part_bottom_sheet.dart';

class PartDetailsScreen extends StatelessWidget {
  final Part? part;

  const PartDetailsScreen({Key? key, this.part}) : super(key: key);

  Future<void> _deletePart(BuildContext context, String categoryId, String partId) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // First check if quantity is 0
      final doc = await firestore.collection('inventory_parts').doc(categoryId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final partData = data[partId] as Map<String, dynamic>?;

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
      await firestore.collection('inventory_parts').doc(categoryId).update({partId: FieldValue.delete()});
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

  void _showDeleteDialog(BuildContext context, String categoryId, String partId) {
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
              'Part: $partId',
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
              _deletePart(context, categoryId, partId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditPartBottomSheet(BuildContext context, Part part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditPartBottomSheet(part: part),
    );
  }

  // Replace your existing _showProcurementRequestDialog method with this simple version:
  void _showProcurementRequestDialog(BuildContext context, Part part) {
    showDialog(
      context: context,
      builder: (ctx) => pd.EnhancedProcurementDialog(part: part),
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
          lowStockThreshold: 15,
        );

    // Get the part ID directly from the id field (as shown in database)
    String partId = displayPart.id.isNotEmpty
        ? displayPart.id
        : 'PRT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Part Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header inside white container with better design
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Part Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'ID: $partId',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content with improved design
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Part Title Card with enhanced design
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.blue[50]!, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(displayPart.category),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getCategoryColor(displayPart.category).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(displayPart.category),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayPart.name,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Part ID: $partId',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (displayPart.description.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            displayPart.description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Part Info Tags with better design
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildInfoTag(
                                  'Category: ${displayPart.category}',
                                  _getCategoryColor(displayPart.category).withValues(alpha: 0.15),
                                  textColor: _getCategoryColor(displayPart.category),
                                ),
                                if (displayPart.unit.isNotEmpty)
                                  _buildInfoTag(
                                    'Unit: ${displayPart.unit}',
                                    Colors.purple[100]!,
                                    textColor: Colors.purple[700]!,
                                  ),
                                if (displayPart.isLowStock)
                                  _buildInfoTag(
                                    '⚠️ Low Stock Alert',
                                    Colors.red[100]!,
                                    textColor: Colors.red[700]!,
                                  ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // Stock Information Section
                            _buildSectionHeader('Stock Information', Icons.inventory_2),
                            SizedBox(height: 16),

                            // Stock Info Card with enhanced design
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Current Quantity',
                                    '${displayPart.quantity}',
                                    Icons.inventory,
                                    Colors.blue,
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Reorder Level',
                                    '${displayPart.lowStockThreshold}',
                                    Icons.warning,
                                    Colors.orange,
                                  ),
                                  SizedBox(height: 20),
                                  _buildStockLevelBar(displayPart.quantity, displayPart.lowStockThreshold),
                                  SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Price per Unit',
                                    displayPart.price > 0 ? 'RM ${displayPart.price.toStringAsFixed(2)}' : 'Not specified',
                                    Icons.attach_money,
                                    Colors.green,
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Stock Status',
                                    displayPart.isLowStock ? 'Low Stock' : 'In Stock',
                                    displayPart.isLowStock ? Icons.error : Icons.check_circle,
                                    displayPart.isLowStock ? Colors.red : Colors.green,
                                  ),
                                  if (displayPart.isLowStock || displayPart.quantity <= displayPart.lowStockThreshold) ...[
                                    SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _showProcurementRequestDialog(context, displayPart),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[600],
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_cart, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Request to Reload Stock',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 32),

                            // Usage History Section
                            _buildSectionHeader('Recent Activity', Icons.history),
                            SizedBox(height: 16),

                            // Usage History Items with better design
                            _buildUsageHistoryItem(
                              'Used in Service',
                              '03/03/2025',
                              '-2',
                              Colors.red,
                              Icons.remove_circle_outline,
                            ),
                            SizedBox(height: 12),
                            _buildUsageHistoryItem(
                              'Restocked',
                              '01/03/2025',
                              '+20',
                              Colors.green,
                              Icons.add_circle_outline,
                            ),
                            SizedBox(height: 40),

                            // Action Buttons with enhanced design
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showEditPartBottomSheet(context, displayPart);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit Part',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (displayPart.documentId.isNotEmpty) {
                                        _showDeleteDialog(
                                          context,
                                          displayPart.documentId,
                                          displayPart.id, // Use id instead of name
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Cannot delete: No documentId'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Part',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTag(String text, Color backgroundColor, {Color? textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: (textColor ?? Colors.black).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.black,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: quantityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: quantityColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: quantityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: quantityColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              quantity,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: quantityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelBar(int quantity, int reorderLevel) {
    double percent = reorderLevel > 0 ? (quantity / reorderLevel) : 1.0;
    percent = percent.clamp(0.0, 2.0);
    Color barColor;
    String statusText;

    if (percent > 1.2) {
      barColor = Colors.green[600]!;
      statusText = 'Stock Sufficient';
    } else if (percent > 1.0) {
      barColor = Colors.orange[600]!;
      statusText = 'Near Reorder Level';
    } else {
      barColor = Colors.red[600]!;
      statusText = 'Below Reorder Level';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Level Progress',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$quantity / $reorderLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent > 2.0 ? 1.0 : percent / 2.0,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                percent <= 1.0 ? Icons.warning : Icons.check_circle,
                size: 16,
                color: barColor,
              ),
              SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
