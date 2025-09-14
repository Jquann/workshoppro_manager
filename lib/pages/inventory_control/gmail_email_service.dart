// Gmail SMTP Email Service - FREE email sending for procurement requests
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import '../../models/part.dart';

class GmailEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gmail SMTP Configuration - UPDATE WITH YOUR ACTUAL APP PASSWORD
  static const String _gmailUsername = 'workshopmanagera@gmail.com';
  static const String _gmailAppPassword = 'yxdb xpgx otmt nlbk'; // Replace with actual app password

  // Submit procurement request with Gmail SMTP
  static Future<String> submitProcurementRequestWithGmail({
    required Part part,
    required int quantity,
    required String priority,
    required String supplier,
    DateTime? requiredBy,
    String notes = '',
  }) async {
    final requestId = _generateRequestId();

    // Create request data
    final requestData = {
      'requestId': requestId,
      'partId': part.id,
      'partName': part.name,
      'category': part.category,
      'requestedQty': quantity,
      'currentStock': part.quantity,
      'lowStockThreshold': part.lowStockThreshold,
      'priority': priority,
      'supplier': supplier,
      'supplierEmail': getSupplierEmail(supplier),
      'requiredByDate': requiredBy,
      'specialNotes': notes,
      'status': 'Sending Email...', // Initial status
      'deliveryStatus': 'Pending',
      'requestedBy': 'Workshop Manager',
      'requestedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'eta': null,
      'trackingNumber': null,
    };

    // Save to Firestore first
    await _firestore
        .collection('procurement_requests')
        .doc(requestId)
        .set(requestData);

    try {
      // Send email using Gmail SMTP
      await _sendEmailViaGmailSMTP(part, quantity, priority, supplier, requiredBy, notes, requestId);

      // Update status to "Email Sent"
      await _firestore
          .collection('procurement_requests')
          .doc(requestId)
          .update({
            'status': 'Email Sent - Awaiting Response',
            'emailSentAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

    } catch (error) {
      // Update status to indicate email failed
      await _firestore
          .collection('procurement_requests')
          .doc(requestId)
          .update({
            'status': 'Email Failed - Please Retry',
            'errorMessage': error.toString(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      throw error; // Re-throw to show error in UI
    }

    return requestId;
  }

  // Send email using Gmail SMTP
  static Future<void> _sendEmailViaGmailSMTP(
    Part part,
    int quantity,
    String priority,
    String supplier,
    DateTime? requiredBy,
    String notes,
    String requestId,
  ) async {
    final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';
    final requiredByText = requiredBy != null
        ? '${requiredBy.day}/${requiredBy.month}/${requiredBy.year}'
        : 'As soon as possible';

    // Create beautiful HTML email content
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .part-details { background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0; }
            .urgent { border-left: 5px solid #dc3545; }
            .normal { border-left: 5px solid #007bff; }
            .when-available { border-left: 5px solid #28a745; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; margin-top: 20px; }
            .btn { background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 5px; }
            .confirm-btn { background: #28a745; }
            .reject-btn { background: #dc3545; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔧 Procurement Request - Order #$requestId</h1>
            <p>Greenstem Automotive Workshop</p>
        </div>
        
        <div class="content">
            <h2>Dear $supplier Team,</h2>
            <p>We would like to request the following spare part for our workshop:</p>
            
            <div class="part-details ${priority.toLowerCase().replaceAll(' ', '-')}">
                <h3>📦 Part Information</h3>
                <p><strong>Part Name:</strong> ${part.name}</p>
                <p><strong>Part ID:</strong> ${part.id}</p>
                <p><strong>Category:</strong> ${part.category}</p>
                <p><strong>Current Stock:</strong> ${part.quantity} units</p>
                <p><strong>Reorder Threshold:</strong> ${part.lowStockThreshold} units</p>
                <p><strong>Requested Quantity:</strong> $quantity units</p>
                <p><strong>Priority:</strong> <span style="font-weight: bold; color: ${_getPriorityColorHex(priority)};">$priority</span></p>
                <p><strong>Required By:</strong> $requiredByText</p>
            </div>
            
            <div class="part-details">
                <h3>📋 Request Details</h3>
                <p><strong>Request ID:</strong> $requestId</p>
                <p><strong>Date Requested:</strong> $formattedDate</p>
                <p><strong>Requested By:</strong> Workshop Manager</p>
                ${notes.isNotEmpty ? '<p><strong>Special Instructions:</strong><br>$notes</p>' : ''}
            </div>
            
            <h3>📧 How to Respond</h3>
            <p>Please reply to this email with the following information:</p>
            <ul>
                <li><strong>To CONFIRM:</strong> Reply with "CONFIRM-$requestId"</li>
                <li><strong>To REJECT:</strong> Reply with "REJECT-$requestId"</li>
                <li>Availability confirmation</li>
                <li>Unit price and total cost</li>
                <li>Estimated delivery date</li>
                <li>Any minimum order requirements</li>
                <li>Delivery charges (if applicable)</li>
            </ul>
        </div>
        
        <div class="footer">
            <p><strong>Best regards,</strong><br>
            Workshop Manager<br>
            Greenstem Automotive Workshop<br>
            📧 ${_gmailUsername}</p>
        </div>
    </body>
    </html>
    ''';

    final message = Message()
      ..from = Address(_gmailUsername, 'Greenstem Automotive Workshop')
      ..recipients.add(getSupplierEmail(supplier))
      ..subject = '[${priority.toUpperCase()}] Procurement Request - ${part.name} - Order #$requestId'
      ..html = htmlContent;

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email via Gmail SMTP: $e');
    }
  }

  // Helper methods
  static String _generateRequestId() {
    return 'PR${DateTime.now().millisecondsSinceEpoch}';
  }

  static int calculateRecommendedQuantity(Part part) {
    return part.isLowStock ? (part.lowStockThreshold * 2) : part.lowStockThreshold;
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent': return Colors.red;
      case 'Normal': return Colors.blue;
      case 'When Available': return Colors.green;
      default: return Colors.grey;
    }
  }

  static String _getPriorityColorHex(String priority) {
    switch (priority) {
      case 'Urgent': return '#dc3545';
      case 'Normal': return '#007bff';
      case 'When Available': return '#28a745';
      default: return '#6c757d';
    }
  }

  static List<String> getSupplierList() {
    return ['Bosch', 'Denso', 'NGK', 'Castrol', 'Shell', 'Default Supplier'];
  }

  static String getSupplierEmail(String supplier) {
    final supplierEmails = {
      'Bosch': 'charlesyeongz@gmail.com',
      'Denso': 'charlesyeongz@gmail.com',
      'NGK': 'charlesyeongz@gmail.com',
      'Castrol': 'charlesyeongz@gmail.com',
      'Shell': 'charlesyeongz@gmail.com',
      'Default Supplier': 'charlesyeongz@gmail.com',
    };
    return supplierEmails[supplier] ?? 'charlesyeongz@gmail.com';
  }

  // Resend email for failed requests
  static Future<void> resendEmail(String requestId) async {
    try {
      final doc = await _firestore.collection('procurement_requests').doc(requestId).get();
      if (!doc.exists) throw Exception('Request not found');

      final data = doc.data()!;
      final part = Part(
        id: data['partId'],
        name: data['partName'],
        category: data['category'],
        quantity: data['currentStock'],
        lowStockThreshold: data['lowStockThreshold'],
        supplier: data['supplier'],
        isLowStock: (data['currentStock'] ?? 0) <= (data['lowStockThreshold'] ?? 0),
      );

      await _sendEmailViaGmailSMTP(
        part,
        data['requestedQty'],
        data['priority'],
        data['supplier'],
        data['requiredByDate']?.toDate(),
        data['specialNotes'] ?? '',
        requestId,
      );

      // Update status
      await _firestore.collection('procurement_requests').doc(requestId).update({
        'status': 'Email Sent - Awaiting Response',
        'emailSentAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to resend email: $e');
    }
  }

  // Update request status manually
  static Future<void> updateRequestStatus(String requestId, String status, {
    String? notes,
    DateTime? estimatedDelivery,
    double? unitPrice,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (notes != null) updateData['supplierNotes'] = notes;
    if (estimatedDelivery != null) updateData['estimatedDelivery'] = estimatedDelivery;
    if (unitPrice != null) updateData['unitPrice'] = unitPrice;

    await _firestore
        .collection('procurement_requests')
        .doc(requestId)
        .update(updateData);
  }

  // Public method for manual status update (for tracking screen)
  static Future<void> updateRequestStatusManually({
    required String requestId,
    required String status,
    String? notes,
    DateTime? estimatedDelivery,
    double? unitPrice,
  }) async {
    await updateRequestStatus(requestId, status, notes: notes, estimatedDelivery: estimatedDelivery, unitPrice: unitPrice);
  }

  // Get procurement requests stream for tracking
  static Stream<QuerySnapshot> getProcurementRequestsStream() {
    return _firestore
        .collection('procurement_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  // Get single request status
  static Stream<DocumentSnapshot> getProcurementRequestStatus(String requestId) {
    return _firestore
        .collection('procurement_requests')
        .doc(requestId)
        .snapshots();
  }
}
