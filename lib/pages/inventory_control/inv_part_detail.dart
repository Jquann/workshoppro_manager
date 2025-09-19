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
        // Look for the part using its ID as the field name in the database
        final partData = data[partId] as Map<String, dynamic>?;

        if (partData != null) {
          int quantity = partData['quantity'] ?? 0;

          if (quantity > 0) {
            // Cannot delete - quantity is not 0
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cannot Delete Part',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Part must have 0 quantity before deletion. Current stock: $quantity units',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[600],
                duration: Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
              ),
            );
            return;
          }
        } else {
          // Part not found in database
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Part Not Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The part "$partId" could not be found in the database',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
          return;
        }
      }

      // Quantity is 0, proceed with deletion using part ID as field name
      await firestore.collection('inventory_parts').doc(categoryId).update({partId: FieldValue.delete()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Part Deleted Successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Part "$partId" has been permanently removed from inventory',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deletion Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'An error occurred while deleting the part. Please try again.',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, String categoryId, String partId) {
    // Get part name for better context
    final partName = part?.name ?? 'Unknown Part';

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Colors.red[600],
                size: 24
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Deletion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to permanently delete this part:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.blue[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Part Name',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      partName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.tag, color: Colors.orange[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Part ID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      partId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Parts can only be deleted if quantity is 0\n• This action cannot be undone\n• All part data will be permanently lost',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to proceed?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
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
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePart(context, categoryId, partId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_forever, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Delete Part',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                      padding: EdgeInsets.zero,
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
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: $partId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
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
                            color: Colors.blue.withOpacity(0.08),
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
                                  color: _getCategoryColor(displayPart.category).withOpacity(0.3),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Enhanced Part Info Tags
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildInfoTag(
                            'Category: ${displayPart.category}',
                            _getCategoryColor(displayPart.category).withOpacity(0.15),
                            textColor: _getCategoryColor(displayPart.category),
                          ),
                          SizedBox(width: 8),
                          if (displayPart.unit.isNotEmpty) ...[
                            _buildInfoTag(
                              'Unit: ${displayPart.unit}',
                              Colors.purple[100]!,
                              textColor: Colors.purple[700]!,
                            ),
                            SizedBox(width: 8),
                          ],
                          if (displayPart.isLowStock)
                            _buildInfoTag(
                              '⚠️ Low Stock Alert',
                              Colors.red[100]!,
                              textColor: Colors.red[700]!,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Stock Information Section
                    _buildSectionCard(
                      title: 'Stock Information',
                      icon: Icons.inventory_2,
                      color: Colors.green,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shopping_cart, size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Request to Reload Stock',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                    SizedBox(height: 24),

                    // Recent Activity Section
                    _buildSectionCard(
                      title: 'Recent Activity',
                      icon: Icons.history,
                      color: Colors.blue,
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Edit Part',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Delete Part',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
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
            color: Colors.grey.withOpacity(0.1),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
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
              // Text(
              //   '$quantity / $reorderLevel',
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.bold,
              //     color: barColor,
              //   ),
              // ),
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

