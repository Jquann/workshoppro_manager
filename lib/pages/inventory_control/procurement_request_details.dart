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

      try {
        final doc = await FirebaseFirestore.instance.collection('procurement_requests').doc(widget.requestId).get();
        if (doc.exists) {
          final data = doc.data();
          final newStatus = data?['status'] ?? 'Requested';
          final newDeliveryStatus = data?['deliveryStatus'] ?? '';
          final oldStatus = _selectedStatus;

          print('Status change detected: $oldStatus -> $newStatus, deliveryStatus: $newDeliveryStatus');

          // Check if status or deliveryStatus changed to 'Delivered' and update inventory
          bool isDelivered = (newStatus.toString().toLowerCase() == 'delivered') || (newDeliveryStatus.toString().toLowerCase() == 'delivered');
          bool wasDelivered = (oldStatus?.toLowerCase() == 'delivered');

          // Fix: Check if inventory was NOT updated (could be null or false)
          bool inventoryNotUpdated = data?['inventoryUpdated'] != true;

          if (!wasDelivered && isDelivered && inventoryNotUpdated) {
            print('Status or deliveryStatus changed to delivered, updating inventory...');
            await _updateInventoryOnDelivery(data);
          }

          setState(() {
            _requestData = data;
            _selectedStatus = newStatus;
            _isLoading = false;
          });
        } else {
          setState(() {
            _requestData = null;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching request details: $e');
        setState(() {
          _requestData = null;
          _isLoading = false;
        });
      }
    }

    Future<void> _updateInventoryOnDelivery(Map<String, dynamic>? requestData) async {
      if (requestData == null) return;

      try {
        // Fix: Check if inventory was already updated (could be null initially)
        if (requestData['inventoryUpdated'] == true) {
          print('Inventory already updated for this request');
          return;
        }

        final partId = requestData['partId'] as String?;
        final partName = requestData['partName'] as String? ??
            requestData['name'] as String? ??
            requestData['itemName'] as String?;
        final category = requestData['category'] as String? ??
            requestData['partCategory'] as String?;

        // Fix: Priority order for quantity fields - check requestedQty first
        final deliveredQty = (requestData['requestedQty'] ??
            requestData['quantity'] ??
            requestData['requestedQuantity']) as int?;

        print('Updating inventory for: partId=$partId, partName=$partName, category=$category, quantity=$deliveredQty');

        if (partId == null || category == null || deliveredQty == null) {
          print('Missing required data for inventory update');
          print('Available request data keys: ${requestData.keys.toList()}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot update inventory: Missing partId, category, or quantity data'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // Fix: Based on image 4, the structure is inventory_parts/{category} where parts are fields in the document
        final categoryDocRef = FirebaseFirestore.instance
            .collection('inventory_parts')
            .doc(category);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Read the category document
          final snapshot = await transaction.get(categoryDocRef);

          if (!snapshot.exists) {
            print('Category document "$category" not found');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "$category" not found in inventory.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Get the document data
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data == null) {
            print('No data in category document');
            return;
          }

          // Check if the part exists as a field in the document
          if (!data.containsKey(partId)) {
            print('Part "$partName" ($partId) not found as field in category "$category".');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Part "$partName" ($partId) not found in inventory category "$category".'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Get the part data
          final partData = data[partId] as Map<String, dynamic>?;
          if (partData == null) {
            print('Part data is null for $partId');
            return;
          }

          final currentQty = (partData['quantity'] as int?) ?? 0;
          final newQty = currentQty + deliveredQty;
          final lowStockThreshold = (partData['lowStockThreshold'] as int?) ?? 0;

          // Create updated part data
          final updatedPartData = Map<String, dynamic>.from(partData);
          updatedPartData['quantity'] = newQty;
          updatedPartData['lastRestocked'] = FieldValue.serverTimestamp();
          updatedPartData['lastRestockQty'] = deliveredQty;
          updatedPartData['isLowStock'] = newQty <= lowStockThreshold;

          // Update the category document with the new part data
          transaction.update(categoryDocRef, {
            partId: updatedPartData,
          });

          // Update procurement request to mark inventory updated
          final reqDocRef = FirebaseFirestore.instance
              .collection('procurement_requests')
              .doc(widget.requestId);

          transaction.update(reqDocRef, {
            'inventoryUpdated': true,
            'inventoryUpdateDate': FieldValue.serverTimestamp(),
          });

          print('Updated inventory part "$partName" ($partId) in category "$category": $currentQty + $deliveredQty = $newQty');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inventory updated successfully! Added $deliveredQty units of $partName'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error updating inventory: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update inventory: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
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
        String? rejectedAfter = _requestData?['rejectedAfter'];
        List<Map<String, dynamic>> stepsToShow = [];

        if (rejectedAfter != null) {
          int rejectedIndex = allSteps.indexWhere((step) => step['label'] == rejectedAfter);
          if (rejectedIndex != -1) {
            stepsToShow = allSteps.sublist(0, rejectedIndex + 1);
          } else {
            stepsToShow = [allSteps[0]];
          }
        } else {
          stepsToShow = [allSteps[0]];
        }

        stepsToShow.add({'label': 'Rejected', 'icon': Icons.cancel, 'color': Colors.red});
        return stepsToShow;
      }

      // For non-rejected status, return all steps (filtering will be done later)
      return allSteps;
    }

    Widget _buildVerticalStatusFlow(List<Map<String, dynamic>> steps, int currentIndex) {
      // Only show steps up to the current index + 1
      List<Map<String, dynamic>> stepsToShow;
      if (currentIndex >= 0) {
        stepsToShow = steps.sublist(0, currentIndex + 1);
      } else {
        // If no current status found, show only the first step
        stepsToShow = steps.isNotEmpty ? [steps[0]] : [];
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(stepsToShow.length, (idx) {
          final step = stepsToShow[idx];
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
          } else if (isCurrentStep) {
            // Highlight current step
            iconColor = Colors.blue[700]!;
            textColor = Colors.blue[700]!;
          } else if (isCompletedStep) {
            // Completed steps in green
            iconColor = Colors.green[600]!;
            textColor = Colors.green[600]!;
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
                    padding: EdgeInsets.all(0),
                    child: Icon(
                      step['icon'],
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  if (idx < stepsToShow.length - 1)
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
            // Add manual inventory update button for delivered items
            if (_selectedStatus?.toLowerCase() == 'delivered' && _requestData?['inventoryUpdated'] != true)
              IconButton(
                icon: Icon(Icons.add_box),
                tooltip: 'Update Inventory',
                onPressed: () async {
                  await _updateInventoryOnDelivery(_requestData);
                  await _fetchRequestDetails(); // Refresh data
                },
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
                      _requestData?['partName'] ?? _requestData?['name'] ?? _requestData?['itemName'] ?? 'Part',
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
                      '${_requestData?['quantity'] ?? _requestData?['requestedQty'] ?? _requestData?['requestedQuantity'] ?? '-'}',
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
                      Icons.schedule,
                      'Requested',
                      _requestData?['requestedDate'] ?? _formatDateTime(_requestData?['requestedat']) ?? '-',
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
                    // First try exact match
                    for (int i = 0; i < steps.length; i++) {
                      String stepLabel = steps[i]['label'].toString().trim();
                      if (stepLabel == currentStatus) {
                        currentIndex = i;
                        break;
                      }
                    }

                    // If no exact match, try case-insensitive match
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

                    // If still no match and it's 'delivered', set to last step
                    if (currentIndex == -1 && currentStatus.toLowerCase() == 'delivered') {
                      currentIndex = steps.length - 1;
                    }

                    // If still no match, default to first step (Requested)
                    if (currentIndex == -1) {
                      currentIndex = 0;
                    }
                  } else {
                    // Default to first step if no status
                    currentIndex = 0;
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
                      'brakes': 'lib/pages/inventory_control/images/break_proof_delivery_image.png',
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

              SizedBox(height: 16),

              // Last Updated
              Text(
                'Last updated: ${_requestData?['lastUpdated']?.toString() ?? DateTime.now().toString()}',
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
        return eta;
      }
      return '-';
    }
  }

