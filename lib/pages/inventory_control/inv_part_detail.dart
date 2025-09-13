import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_inv_part.dart';
import '../../models/part.dart';

class PartDetailsScreen extends StatelessWidget {
  final Part? part;

  const PartDetailsScreen({Key? key, this.part}) : super(key: key);

  Future<void> _deletePart(BuildContext context, String categoryId, String partName) async {
    final firestore = FirebaseFirestore.instance;
    try {
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
        title: Text('Delete Part'),
        content: Text('Are you sure you want to delete this part?'),
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

  void _showProcurementRequestDialog(BuildContext context, Part part) {
    final TextEditingController qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request to Reload Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Part: ${part.name}'),
            SizedBox(height: 8),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity Needed'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0) {
                await FirebaseFirestore.instance.collection('procurement_requests').add({
                  'partId': part.id,
                  'partName': part.name,
                  'requestedQty': qty,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'Pending',
                  'deliveryStatus': 'Pending',
                  'eta': null,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Procurement request submitted!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
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
                                  _buildInfoRow('Reorder Level', '15'),
                                  SizedBox(height: 12),
                                  _buildStockLevelBar(displayPart.quantity, 15),
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Manufacturer',
                                    displayPart.manufacturer.isNotEmpty
                                        ? displayPart.manufacturer
                                        : 'Not specified',
                                  ),
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    'Status',
                                    displayPart.isLowStock
                                        ? 'Low Stock'
                                        : 'In Stock',
                                  ),
                                  if (displayPart.isLowStock || displayPart.quantity <= 15) ...[
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddNewPartScreen(
                                            part: displayPart,
                                            documentId: displayPart.documentId,
                                          ),
                                        ),
                                      );
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
      barColor = Colors.yellow[700]!;
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
