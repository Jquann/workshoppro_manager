// widgets/procurement_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/inventory_control/procurement_service.dart';
import 'gmail_email_service.dart';

class ProcurementTrackingScreen extends StatelessWidget {
  const ProcurementTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Procurement Requests',
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: GmailEmailService.getProcurementRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildRequestCard(context, data);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No procurement requests yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Requests will appear here when you submit them',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Unknown';
    final priority = data['priority'] ?? 'Normal';
    final requestedAt = data['requestedAt'] as Timestamp?;
    final lastUpdated = data['lastUpdated'] as Timestamp?;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100]!,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  data['partName'] ?? 'Unknown Part',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          SizedBox(height: 8),

          // Request Details
          Row(
            children: [
              Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('ID: ${data['requestId']}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 4),

          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Qty: ${data['requestedQty']}', style: TextStyle(color: Colors.grey[600])),
              SizedBox(width: 20),
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(data['supplier'] ?? 'Unknown', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 4),

          // Priority and Timing
          Row(
            children: [
              _buildPriorityChip(priority),
              Spacer(),
              if (requestedAt != null)
                Text(
                  'Requested: ${_formatDate(requestedAt.toDate())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),

          // Status Details
          if (status != 'Pending Email') ...[
            SizedBox(height: 12),
            _buildStatusDetails(data),
          ],

          // Last Updated
          if (lastUpdated != null) ...[
            SizedBox(height: 8),
            Text(
              'Last updated: ${_formatDateTime(lastUpdated.toDate())}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],

          // Action Buttons
          SizedBox(height: 12),
          _buildActionButtons(context, data),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending email':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case 'email sent':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case 'confirmed by supplier':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case 'rejected by supplier':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      case 'email failed':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ProcurementService.getPriorityColor(priority).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ProcurementService.getPriorityColor(priority),
        ),
      ),
    );
  }

  Widget _buildStatusDetails(Map<String, dynamic> data) {
    final status = data['status'];

    if (status == 'Confirmed by Supplier') {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supplier Confirmation Details:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            SizedBox(height: 4),
            if (data['unitPrice'] != null)
              Text('Unit Price: \$${data['unitPrice'].toStringAsFixed(2)}'),
            if (data['estimatedDelivery'] != null)
              Text('Estimated Delivery: ${_formatDate((data['estimatedDelivery'] as Timestamp).toDate())}'),
            if (data['supplierNotes'] != null && data['supplierNotes'].isNotEmpty)
              Text('Notes: ${data['supplierNotes']}'),
          ],
        ),
      );
    } else if (status == 'Rejected by Supplier') {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejection Reason:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
            SizedBox(height: 4),
            Text(data['rejectionReason'] ?? 'No reason provided'),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'];
    final requestId = data['requestId'];

    return Row(
      children: [
        if (status == 'Email Failed - Check Configuration') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await GmailEmailService.resendEmail(requestId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email resent successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resending email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('Resend Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        if (status == 'Sending Email...' || status == 'Email Sent - Awaiting Response') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showManualUpdateDialog(context, requestId),
              icon: Icon(Icons.edit, size: 16),
              label: Text('Update Status'),
            ),
          ),
        ],
      ],
    );
  }

  void _showManualUpdateDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Request Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Mark as Confirmed'),
              subtitle: Text('Supplier has confirmed the order'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(context, requestId, 'Confirmed by Supplier');
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title: Text('Mark as Rejected'),
              subtitle: Text('Supplier has rejected the order'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(context, requestId, 'Rejected by Supplier');
              },
            ),
            ListTile(
              leading: Icon(Icons.local_shipping, color: Colors.blue),
              title: Text('Mark as In Delivery'),
              subtitle: Text('Order is being shipped'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(context, requestId, 'In Delivery');
              },
            ),
            ListTile(
              leading: Icon(Icons.done_all, color: Colors.purple),
              title: Text('Mark as Delivered'),
              subtitle: Text('Order has been received'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(context, requestId, 'Delivered');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String requestId, String status) async {
    try {
      await GmailEmailService.updateRequestStatusManually(
        requestId: requestId,
        status: status
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}