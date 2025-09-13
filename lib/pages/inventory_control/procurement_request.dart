import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/inventory_control/procurement_request_detail.dart';
import 'procurement_request_detail.dart'; // Import the detail page

class ProcurementRequestPage extends StatefulWidget {
  @override
  _ProcurementRequestPageState createState() => _ProcurementRequestPageState();
}

class _ProcurementRequestPageState extends State<ProcurementRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Procurement Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('procurement_requests').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return Center(child: Text('No procurement requests found.'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              return _buildRequestCard(data, requests[index].id);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewRequestDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'Pending';
    final eta = data['eta'] != null ? (data['eta'] as Timestamp).toDate() : null;
    final deliveryStatus = data['deliveryStatus'] ?? 'Pending';
    Color statusColor;
    switch (status) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'In Transit':
        statusColor = Colors.yellow[700]!;
        break;
      case 'Delayed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcurementRequestDetailPage(data: data),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['partName'] ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Quantity: ${data['requestedQty'] ?? ''}'),
              SizedBox(height: 4),
              Text('Status: $status', style: TextStyle(color: statusColor)),
              SizedBox(height: 4),
              Text('Delivery Status: $deliveryStatus'),
              SizedBox(height: 4),
              Text('ETA: ${eta != null ? eta.toLocal().toString().split(' ')[0] : 'Not set'}'),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewRequestDialog(BuildContext context) {
    final partNameController = TextEditingController();
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Procurement Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: partNameController,
              decoration: InputDecoration(labelText: 'Part Name'),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firestore.collection('procurement_requests').add({
                'partName': partNameController.text,
                'requestedQty': int.tryParse(qtyController.text) ?? 0,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'Pending',
                'deliveryStatus': 'Pending',
                'eta': null,
              });
              Navigator.pop(ctx);
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
