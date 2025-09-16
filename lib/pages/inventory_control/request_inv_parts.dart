import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPartRequestsPage extends StatefulWidget {
  const InventoryPartRequestsPage({Key? key}) : super(key: key);

  @override
  State<InventoryPartRequestsPage> createState() => _InventoryPartRequestsPageState();
}

class _InventoryPartRequestsPageState extends State<InventoryPartRequestsPage> {
  final _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> sampleInventoryRequests = [
    {
      'partId': 'SP0001',
      'partName': 'Engine Oil (5W-30)',
      'quantityRequested': 2,
      'requester': 'Alice Tan',
      'requesterId': 'user_001',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'For scheduled maintenance'
    },
    {
      'partId': 'SP0013',
      'partName': 'Water Pumps (common models)',
      'quantityRequested': 1,
      'requester': 'Bob Lee',
      'requesterId': 'user_002',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Urgent replacement'
    },
    {
      'partId': 'SP0015',
      'partName': 'Brake Pads (Front & Rear)',
      'quantityRequested': 4,
      'requester': 'Charlie Lim',
      'requesterId': 'user_003',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Customer complaint: squeaking brakes'
    },
    {
      'partId': 'SP0020',
      'partName': 'Car Batteries (12V - common sizes)',
      'quantityRequested': 1,
      'requester': 'Diana Ng',
      'requesterId': 'user_004',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Battery replacement'
    },
    {
      'partId': 'SP0031',
      'partName': 'Wiper Blades (18", 20", 22", 24")',
      'quantityRequested': 2,
      'requester': 'Eddie Wong',
      'requesterId': 'user_005',
      'status': 'pending',
      'requestedAt': Timestamp.now(),
      'notes': 'Visibility issue'
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

  Future<void> _handleRequestAction(String requestId, String partId, int quantityRequested, String action) async {
    try {
      final requestRef = _firestore.collection('inventory_requests').doc(requestId);
      final partRef = _firestore.collection('inventory_parts').doc(partId);
      if (action == 'accept') {
        // Get current part quantity
        final partDoc = await partRef.get();
        final partData = partDoc.data() as Map<String, dynamic>?;
        final currentQty = partData?['quantity'] ?? 0;
        if (currentQty < quantityRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient inventory!'), backgroundColor: Colors.red),
          );
          return;
        }
        // Update part quantity and request status
        await partRef.update({'quantity': currentQty - quantityRequested});
        await requestRef.update({'status': 'accepted'});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request accepted.'), backgroundColor: Colors.green),
        );
      } else if (action == 'reject') {
        await requestRef.update({'status': 'rejected'});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request rejected.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAllRequests() async {
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
            icon: Icon(Icons.cloud_upload),
            tooltip: 'Upload Sample Requests',
            onPressed: _uploadSampleRequests,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Delete All Requests',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete All Requests'),
                  content: Text('Are you sure you want to delete ALL inventory part requests? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _deleteAllRequests();
              }
            },
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
            return Center(child: Text('No requests found.'));
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final partId = data['partId'] ?? '';
              final partName = data['partName'] ?? '-';
              final quantityRequested = data['quantityRequested'] ?? 0;
              final requester = data['requester'] ?? '-';
              final status = data['status'] ?? 'pending';
              final requestedAt = data['requestedAt'] != null ? (data['requestedAt'] as Timestamp).toDate() : null;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Requested Qty: $quantityRequested'),
                      Text('Requester: $requester'),
                      if (requestedAt != null)
                        Text('Requested At: ${requestedAt.day}/${requestedAt.month}/${requestedAt.year} ${requestedAt.hour}:${requestedAt.minute.toString().padLeft(2, '0')}'),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(label: Text(status.toUpperCase()), backgroundColor: status == 'accepted' ? Colors.green[100] : status == 'rejected' ? Colors.red[100] : Colors.grey[200]),
                          Spacer(),
                          if (status == 'pending') ...[
                            ElevatedButton(
                              onPressed: () => _handleRequestAction(requestId, partId, quantityRequested, 'accept'),
                              child: Text('Accept'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleRequestAction(requestId, partId, quantityRequested, 'reject'),
                              child: Text('Reject'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ],
                      ),
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
}
