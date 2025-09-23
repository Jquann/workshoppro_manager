import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPartRequestsPage extends StatefulWidget {
  const InventoryPartRequestsPage({Key? key}) : super(key: key);

  @override
  State<InventoryPartRequestsPage> createState() => _InventoryPartRequestsPageState();
}

class _InventoryPartRequestsPageState extends State<InventoryPartRequestsPage> {
  final _firestore = FirebaseFirestore.instance;

  // Sample requests using actual part IDs from your Firestore database
  final List<Map<String, dynamic>> sampleInventoryRequests = [
    {
      'partId': 'PRT017',
      'partName': 'Car Batteries (12V - common sizes)',
      'quantityRequested': 2,
      'requester': 'Alice Tan',
      'requesterId': 'user_001',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'For scheduled maintenance'
    },
    {
      'partId': 'PRT017',
      'partName': 'Car Batteries (12V - common sizes)',
      'quantityRequested': 5,
      'requester': 'Bob Lee',
      'requesterId': 'user_002',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Urgent replacement'
    },
    {
      'partId': 'PRT017',
      'partName': 'Car Batteries (12V - common sizes)',
      'quantityRequested': 15,
      'requester': 'Charlie Lim',
      'requesterId': 'user_003',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'This should be rejected - requesting more than available (current stock: 10)'
    },
    {
      'partId': 'PRT031',
      'partName': 'Bumpers (Front and Rear)',
      'quantityRequested': 1,
      'requester': 'Diana Ng',
      'requesterId': 'user_004',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Single bumper replacement'
    },
    {
      'partId': 'PRT031',
      'partName': 'Bumpers (Front and Rear)',
      'quantityRequested': 12,
      'requester': 'Eddie Wong',
      'requesterId': 'user_005',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'This should be rejected - requesting more than available (current stock: 9)'
    },
  ];

  Future<void> _uploadSampleRequests() async {
    try {
      for (final req in sampleInventoryRequests) {
        await _firestore.collection('inventory_requests').add(req);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample requests uploaded.'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading requests: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Returns part data for structure: inventory_parts/{CategoryDoc} where each part is a map field:
  // inventory_parts/Body (doc) with field PRT031: { id, name, quantity, ... }
  Future<Map<String, dynamic>?> _getPartByPartId(String partId) async {
    try {
      final categories = ['Body', 'Brakes', 'Electrical', 'Engine', 'Exhaust', 'Interior', 'Steering', 'Suspension'];

      for (final category in categories) {
        final catRef = _firestore.collection('inventory_parts').doc(category);
        final catSnap = await catRef.get();
        if (!catSnap.exists) continue;
        final data = catSnap.data() as Map<String, dynamic>;

        // 1) Exact field key equals partId
        if (data.containsKey(partId) && data[partId] is Map) {
          final map = Map<String, dynamic>.from(data[partId] as Map);
          return {
            ...map,
            'categoryDocId': category,
            'writeMode': 'mapField',
            'fieldPrefix': partId,
          };
        }

        // 2) Or any field with id matching partId
        for (final entry in data.entries) {
          if (entry.value is Map) {
            final map = Map<String, dynamic>.from(entry.value as Map);
            if ((map['id'] ?? entry.key) == partId) {
              return {
                ...map,
                'categoryDocId': category,
                'writeMode': 'mapField',
                'fieldPrefix': entry.key,
              };
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching part by id: $e');
      return null;
    }
  }

  Future<void> _handleRequestAction(String requestId, String partId, int quantityRequested, String action) async {
    try {
      final requestRef = _firestore.collection('inventory_requests').doc(requestId);

      if (action == 'accept') {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        // Fetch part details from Firestore
        final partData = await _getPartByPartId(partId);

        // Hide loading indicator
        Navigator.of(context).pop();

        if (partData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Part not found in inventory!\nSearched for Part ID: $partId'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        final currentQuantity = ((partData['quantity'] ?? 0) as num).toInt();
        final partName = partData['name']?.toString() ?? 'Unknown Part';

        // Quick pre-check before confirmation
        if (currentQuantity < quantityRequested) {
          await requestRef.update({
            'status': 'rejected',
            'rejectionReason': 'Insufficient stock. Available: $currentQuantity, Requested: $quantityRequested',
            'processedAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request rejected. Available: $currentQuantity, Requested: $quantityRequested'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        // Ask user to confirm
        final confirmed = await _showConfirmationDialog(
          context,
          'Confirm Request Approval',
          'Part: $partName\n'
          'Available Stock: $currentQuantity\n'
          'Requested Quantity: $quantityRequested\n'
          'Remaining after approval: ${currentQuantity - quantityRequested}\n\n'
          'Do you want to approve this request?',
        );
        if (!confirmed) return;

        // Transaction to re-check latest stock and update atomically
        final writeMode = partData['writeMode'];
        final String? categoryDocId = partData['categoryDocId'];
        final String? fieldPrefix = partData['fieldPrefix'];

        final result = await _firestore.runTransaction<String>((tx) async {
          // Ensure request is still pending
          final reqSnap = await tx.get(requestRef);
          if (!reqSnap.exists) return 'error:request_missing';
          final req = reqSnap.data() as Map<String, dynamic>;
          if ((req['status'] ?? 'pending') != 'pending') return 'noop:already_processed';

          if (writeMode == 'mapField') {
            final catRef = _firestore.collection('inventory_parts').doc(categoryDocId!);
            final catSnap = await tx.get(catRef);
            if (!catSnap.exists) return 'error:category_missing';
            final data = catSnap.data() as Map<String, dynamic>;
            final map = Map<String, dynamic>.from((data[fieldPrefix!] ?? {}) as Map);
            final liveQty = ((map['quantity'] ?? 0) as num).toInt();
            if (liveQty < quantityRequested) {
              tx.update(requestRef, {
                'status': 'rejected',
                'rejectionReason': 'Insufficient stock. Available: $liveQty, Requested: $quantityRequested',
                'processedAt': Timestamp.now(),
              });
              return 'rejected:stock';
            }
            tx.update(catRef, {
              '$fieldPrefix.quantity': liveQty - quantityRequested,
            });
            tx.update(requestRef, {
              'status': 'accepted',
              'processedAt': Timestamp.now(),
            });
            return 'accepted';
          }

          return 'error:unknown_write_mode';
        });

        if (result == 'accepted') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request approved! Stock updated.'), backgroundColor: Colors.green),
          );
        } else if (result.startsWith('rejected')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request rejected due to insufficient stock.'), backgroundColor: Colors.red),
          );
        } else if (result == 'noop:already_processed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request already processed.'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing request ($result).'), backgroundColor: Colors.red),
          );
        }
      } else if (action == 'reject') {
        final confirmed = await _showConfirmationDialog(
          context,
          'Confirm Request Rejection',
          'Are you sure you want to reject this request?',
        );
        if (!confirmed) return;

        await requestRef.update({
          'status': 'rejected',
          'rejectionReason': 'Manually rejected by manager',
          'processedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request rejected successfully.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing request: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteAllRequests() async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete All Requests',
      'Are you sure you want to delete all requests? This action cannot be undone.',
    );
    if (!confirmed) return;

    try {
      final snapshot = await _firestore.collection('inventory_requests').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All requests deleted.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting requests: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Part Requests'),
        actions: [
          IconButton(
            onPressed: _uploadSampleRequests,
            icon: Icon(Icons.upload),
            tooltip: 'Upload Sample Requests',
          ),
          IconButton(
            onPressed: _deleteAllRequests,
            icon: Icon(Icons.delete_forever),
            tooltip: 'Delete All Requests',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('inventory_requests').orderBy('requestedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No requests found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _uploadSampleRequests,
                    icon: Icon(Icons.upload),
                    label: Text('Upload Sample Requests'),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final partId = data['partId'] ?? '';
              final partName = data['partName'] ?? '-';
              final quantityRequested = data['quantityRequested'] ?? 0;
              final requester = data['requester'] ?? '-';
              final status = data['status'] ?? 'pending';
              final notes = data['notes'] ?? '';
              final requestedAt = data['requestedAt'] != null ? (data['requestedAt'] as Timestamp).toDate() : null;
              final processedAt = data['processedAt'] != null ? (data['processedAt'] as Timestamp).toDate() : null;
              final rejectionReason = data['rejectionReason'] ?? '';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partName,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildInfoRow('Part ID:', partId),
                      _buildInfoRow('Requested Qty:', quantityRequested.toString()),
                      _buildInfoRow('Requester:', requester),
                      if (requestedAt != null) _buildInfoRow('Requested At:', _formatDateTime(requestedAt)),
                      if (processedAt != null) _buildInfoRow('Processed At:', _formatDateTime(processedAt)),
                      if (notes.isNotEmpty) _buildInfoRow('Notes:', notes),
                      if (rejectionReason.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Rejection Reason: $rejectionReason',
                                    style: TextStyle(color: Colors.red[800], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (status == 'pending') ...[
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _handleRequestAction(requestId, partId, quantityRequested, 'reject'),
                              icon: Icon(Icons.cancel, size: 16),
                              label: Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _handleRequestAction(requestId, partId, quantityRequested, 'accept'),
                              icon: Icon(Icons.check, size: 16),
                              label: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
