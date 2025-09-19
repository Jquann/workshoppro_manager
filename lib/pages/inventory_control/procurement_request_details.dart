import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProcurementRequestDetailsPage extends StatefulWidget {
  final String requestId;
  const ProcurementRequestDetailsPage({Key? key, required this.requestId}) : super(key: key);

  @override
  State<ProcurementRequestDetailsPage> createState() => _ProcurementRequestDetailsPageState();
}

class _ProcurementRequestDetailsPageState extends State<ProcurementRequestDetailsPage> {
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() { _isLoading = true; });
    final doc = await FirebaseFirestore.instance.collection('procurement_requests').doc(widget.requestId).get();
    if (doc.exists) {
      setState(() {
        _requestData = doc.data();
        _selectedStatus = _requestData?['status'] ?? 'Requested';
        _isLoading = false;
      });
    } else {
      setState(() {
        _requestData = null;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSteps() {
    final neutralColor = Colors.grey[800];
    final deliveredColor = Colors.green[700];
    final allSteps = [
      {'label': 'Requested', 'icon': Icons.assignment_outlined, 'color': neutralColor},
      {'label': 'Confirmed', 'icon': Icons.verified_outlined, 'color': neutralColor},
      {'label': 'Ordered', 'icon': Icons.shopping_cart_outlined, 'color': neutralColor},
      {'label': 'Paid', 'icon': Icons.credit_card_outlined, 'color': neutralColor},
      {'label': 'Shipped', 'icon': Icons.local_shipping_outlined, 'color': neutralColor},
      {'label': 'Delivered', 'icon': Icons.location_on_outlined, 'color': deliveredColor},
    ];

    // If status is rejected, show steps up to where rejection happened
    if (_selectedStatus == 'Rejected') {
      // Check if there's a rejectedAfter field to know where rejection happened
      String? rejectedAfter = _requestData?['rejectedAfter'];
      List<Map<String, dynamic>> stepsToShow = [];

      if (rejectedAfter != null) {
        // Find the index where rejection happened
        int rejectedIndex = allSteps.indexWhere((step) => step['label'] == rejectedAfter);
        if (rejectedIndex != -1) {
          // Show steps up to the rejected point
          stepsToShow = allSteps.sublist(0, rejectedIndex + 1);
        } else {
          // If rejectedAfter is not found, just show the first step
          stepsToShow = [allSteps[0]];
        }
      } else {
        // Default: assume rejected after 'Requested' if no specific info
        stepsToShow = [allSteps[0]];
      }

      // Add rejected status
      stepsToShow.add({'label': 'Rejected', 'icon': Icons.cancel, 'color': Colors.red});
      return stepsToShow;
    }

    // For non-rejected status, show the entire flow
    return allSteps;
  }

  Widget _buildVerticalStatusFlow(List<Map<String, dynamic>> steps, int currentIndex) {
    bool isRejected = _selectedStatus == 'Rejected';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps.length, (idx) {
        final step = steps[idx];
        final isCurrentStep = idx == currentIndex;
        final isRejectedStep = step['label'] == 'Rejected';
        final isCompletedStep = idx < currentIndex;

        Color iconColor;
        Color textColor;

        if (isRejectedStep) {
          iconColor = Colors.red[700]!;
          textColor = Colors.red[700]!;
        } else if (step['label'] == 'Delivered') {
          iconColor = Colors.green[700]!;
          textColor = Colors.green[700]!;
        } else {
          iconColor = Colors.grey[800]!;
          textColor = Colors.grey[900]!;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(0), // No colored background
                  child: Icon(
                    step['icon'],
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 16),
            Text(
              step['label'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.w500,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Procurement Request Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRequestDetails,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _requestData == null
              ? Center(child: Text('Request not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Header Section
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _requestData?['partName'] ?? 'Part',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ID: ${_requestData?['requestId'] ?? widget.requestId}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Chip(
                                  label: Text(
                                    (_selectedStatus ?? '').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedStatus == 'Rejected' ? Colors.red : Colors.blue[900],
                                    ),
                                  ),
                                  backgroundColor: _selectedStatus == 'Rejected' ? Colors.red[100] : Colors.blue[100],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Enhanced Details Section
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.inventory,
                              'Quantity',
                              '${_requestData?['quantity'] ?? _requestData?['requestedQty'] ?? '-'}',
                              Colors.blue,
                            ),
                            SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.business,
                              'Supplier',
                              _requestData?['supplier'] ?? '-',
                              Colors.orange,
                            ),
                            SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.email,
                              'Email',
                              _requestData?['supplierEmail'] ?? '-',
                              Colors.green,
                            ),
                            SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.access_time,
                              'ETA',
                              _requestData?['eta'] != null ? _formatDateTime(_requestData?['eta']) : '-',
                              Colors.purple,
                            ),
                            SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.schedule,
                              'Requested',
                              _requestData?['requestedDate'] ?? '-',
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Delivery Status Section
                      Text(
                        'Delivery Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final steps = _getSteps();
                          int currentIndex = -1;
                          String? currentStatus = _selectedStatus?.trim();
                          if (currentStatus != null && currentStatus.isNotEmpty) {
                            for (int i = 0; i < steps.length; i++) {
                              String stepLabel = steps[i]['label'].toString().trim();
                              if (stepLabel == currentStatus) {
                                currentIndex = i;
                                break;
                              }
                            }
                            if (currentIndex == -1) {
                              for (int i = 0; i < steps.length; i++) {
                                String stepLabel = steps[i]['label'].toString().trim().toLowerCase();
                                String statusLower = currentStatus.toLowerCase();
                                if (stepLabel == statusLower) {
                                  currentIndex = i;
                                  break;
                                }
                              }
                            }
                            if (currentIndex == -1 && currentStatus.toLowerCase() == 'delivered') {
                              currentIndex = steps.length - 1;
                            }
                          }
                          return _buildVerticalStatusFlow(steps, currentIndex);
                        },
                      ),
                      // Proof of Delivery Section
                      if ((_selectedStatus?.toLowerCase() == 'delivered') && _requestData != null) ...[
                        SizedBox(height: 24),
                        Text(
                          'Proof of Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            // Use local asset image based on category
                            final category = _requestData?['category'] as String?;
                            final assetMap = {
                              'body': 'lib/pages/inventory_control/images/body_proof_delivery_image.png',
                              'break': 'lib/pages/inventory_control/images/break_proof_delivery_image.png',
                              'electrical': 'lib/pages/inventory_control/images/electrical_proof_delivery_image.png',
                              'engine': 'lib/pages/inventory_control/images/engine_proof_delivery_image.png',
                              'exhaust': 'lib/pages/inventory_control/images/exhaust_proof_delivery_image.png',
                              'interior': 'lib/pages/inventory_control/images/interior_proof_delivery_image.png',
                              'steering': 'lib/pages/inventory_control/images/steering_proof_delivery_image.png',
                              'suspension': 'lib/pages/inventory_control/images/suspension_proof_delivery_image.png',
                            };
                            final assetPath = assetMap[category?.toLowerCase() ?? ''] ?? null;
                            if (assetPath != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  assetPath,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: Center(child: Text('Failed to load image')),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Text(
                                    'No proof of delivery image for this category',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],

                      // Last Updated
                      Text(
                        'Last updated: ${_requestData?['lastUpdated']?.toString() ?? '-'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic eta) {
    if (eta is Timestamp) {
      final date = eta.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (eta is DateTime) {
      return '${eta.day}/${eta.month}/${eta.year} ${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';
    } else if (eta is String) {
      return '-';
    }
    return '-';
  }
}
