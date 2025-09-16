import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProcurementRequestDetailsPage extends StatelessWidget {
  final String requestId;
  const ProcurementRequestDetailsPage({Key? key, required this.requestId}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchRequestDetails() async {
    final doc = await FirebaseFirestore.instance.collection('procurement_requests').doc(requestId).get();
    return doc.exists ? doc.data() : null;
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
            onPressed: () {
              // Force rebuild by pushing a new instance
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProcurementRequestDetailsPage(requestId: requestId),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Request not found'));
          }
          final data = snapshot.data!;
          final status = data['status'] ?? 'Requested';
          final steps = [
            {'label': 'Requested', 'icon': Icons.assignment},
            {'label': 'Ordered', 'icon': Icons.shopping_cart},
            {'label': 'Paid', 'icon': Icons.credit_card},
            {'label': 'Shipped', 'icon': Icons.local_shipping},
            {'label': 'Delivered', 'icon': Icons.location_on},
          ];
          int currentStep = steps.indexWhere((s) => s['label'] == status);
          if (currentStep == -1) currentStep = 0;
          final eta = data['eta'] != null ? _formatDateTime(data['eta']) : '-';
          final supplierName = data['supplier'] ?? '-';
          final supplierEmail = data['supplierEmail'] ?? '-';
          final quantity = data['quantity'] ?? data['requestedQty'] ?? '-';
          final lastUpdated = data['lastUpdated']?.toString() ?? '-';
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['partName'] ?? 'Part',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('ID: ${data['requestId'] ?? requestId}', style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 16),
                    Chip(
                      label: Text(status.toUpperCase()),
                      backgroundColor: Colors.blue[100],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.blue, size: 20),
                    SizedBox(width: 4),
                    Text('Qty: $quantity'),
                    SizedBox(width: 16),
                    Icon(Icons.business, color: Colors.orange, size: 20),
                    SizedBox(width: 4),
                    Text(supplierName),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.green, size: 20),
                    SizedBox(width: 4),
                    Text(supplierEmail),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.purple, size: 20),
                    SizedBox(width: 4),
                    Text('ETA: $eta'),
                  ],
                ),
                SizedBox(height: 8),
                Text('Requested: ${data['requestedDate'] ?? '-'}', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 24),
                Center(child: Text('Delivery Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(steps.length, (i) {
                    final isActive = i <= currentStep;
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isActive ? Colors.green : Colors.grey[300],
                          child: Icon(steps[i]['icon'] as IconData, color: isActive ? Colors.white : Colors.grey[600], size: 28),
                        ),
                        SizedBox(height: 8),
                        Text(
                          steps[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.grey[600],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: 12),
                Row(
                  children: List.generate(steps.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        color: i < currentStep ? Colors.green : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                SizedBox(height: 24),
                Text('Last updated: $lastUpdated', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          );
        },
      ),
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
