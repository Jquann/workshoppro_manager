import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProcurementRequestDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProcurementRequestDetailPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Pending';
    final eta = data['eta'] != null ? (data['eta'] as Timestamp).toDate() : null;
    final deliveryStatus = data['deliveryStatus'] ?? 'Pending';
    final partName = data['partName'] ?? '';
    final requestedQty = data['requestedQty'] ?? '';
    Color barColor;
    double progress;
    switch (deliveryStatus) {
      case 'Delivered':
        barColor = Colors.green;
        progress = 1.0;
        break;
      case 'In Transit':
        barColor = Colors.yellow[700]!;
        progress = 0.5;
        break;
      case 'Delayed':
        barColor = Colors.red;
        progress = 0.5;
        break;
      default:
        barColor = Colors.grey;
        progress = 0.0;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Procurement Request Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Quantity: $requestedQty', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Status: $status', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Delivery Status: $deliveryStatus', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('ETA: ${eta != null ? eta.toLocal().toString().split(' ')[0] : 'Not set'}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 32),
            Text('Delivery Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 18,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              deliveryStatus == 'Delivered'
                  ? 'Delivered'
                  : deliveryStatus == 'In Transit'
                      ? 'In Transit'
                      : deliveryStatus == 'Delayed'
                          ? 'Delayed'
                          : 'Pending',
              style: TextStyle(fontSize: 14, color: barColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

