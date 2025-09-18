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
    // New optional params to allow external control
    String? requestIdOverride,
    String? poNumber,
    DateTime? requestedAt,
    String requestorName = 'Workshop Manager',
    String requestorId = 'WM-001',
  }) async {
    final String requestId = requestIdOverride ?? _generateReadableRequestId();
    final DateTime now = requestedAt ?? DateTime.now();

    final String dateKey = _fmtDateKey(now); // yymmdd
    final String poMonthKey = _fmtPoMonthKey(now); // yyyy-MM

    // Create request data
    final requestData = {
      'requestId': requestId,
      'poNumber': poNumber,
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
      'requestedBy': requestorName,
      'requestorId': requestorId,
      'requestedAt': Timestamp.fromDate(now),
      'lastUpdated': FieldValue.serverTimestamp(),
      'eta': null,
      'trackingNumber': null,
      // helper fields for filtering and counters
      'requestDateKey': dateKey,
      'poMonthKey': poMonthKey,
    };

    // Save to Firestore first
    await _firestore.collection('procurement_requests').doc(requestId).set(requestData);

    try {
      // Send email using Gmail SMTP
      await _sendEmailViaGmailSMTP(
        part,
        quantity,
        priority,
        supplier,
        requiredBy,
        notes,
        requestId,
        poNumber: poNumber,
        requestorName: requestorName,
        requestorId: requestorId,
        requestedAt: now,
      );

      // Update status to "Email Sent"
      await _firestore.collection('procurement_requests').doc(requestId).update({
        'status': 'Email Sent - Awaiting Response',
        'emailSentAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Update status to indicate email failed
      await _firestore.collection('procurement_requests').doc(requestId).update({
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
    String requestId, {
    String? poNumber,
    String requestorName = 'Workshop Manager',
    String requestorId = 'WM-001',
    DateTime? requestedAt,
  }) async {
    final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

    final currentDate = requestedAt ?? DateTime.now();
    final formattedDate = _fmtHumanDate(currentDate);
    final requiredByText = requiredBy != null ? _fmtHumanDate(requiredBy) : 'As soon as possible';

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
            .critical { border-left: 5px solid #dc3545; }
            .high { border-left: 5px solid #fd7e14; }
            .medium { border-left: 5px solid #0d6efd; }
            .low { border-left: 5px solid #6c757d; }
            .footer { background: #f8f9fa; padding: 15px; text-align: center; margin-top: 20px; }
            .pill { display: inline-block; padding: 4px 10px; border-radius: 999px; color: #fff; font-weight: 600; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🔧 Procurement Request - Order #$requestId</h1>
            ${poNumber != null ? '<p>PO Number: <strong>$poNumber</strong></p>' : ''}
            <p>Greenstem Automotive Workshop</p>
        </div>
        
        <div class="content">
            <h2>Dear $supplier Team,</h2>
            <p>We would like to request the following spare part for our workshop:</p>
            
            <div class="part-details ${priority.toLowerCase()}">
                <h3>📦 Part Information</h3>
                <p><strong>Part Name:</strong> ${part.name}</p>
                <p><strong>Part ID:</strong> ${part.id}</p>
                <p><strong>Category:</strong> ${part.category}</p>
                <p><strong>Current Stock:</strong> ${part.quantity} ${part.unit.isNotEmpty ? part.unit : 'units'}</p>
                <p><strong>Reorder Threshold:</strong> ${part.lowStockThreshold} ${part.unit.isNotEmpty ? part.unit : 'units'}</p>
                <p><strong>Requested Quantity:</strong> $quantity ${part.unit.isNotEmpty ? part.unit : 'units'}</p>
                <p><strong>Priority:</strong> <span class="pill" style="background:${_getPriorityColorHex(priority)}">$priority</span></p>
                <p><strong>Required Delivery Date:</strong> $requiredByText</p>
            </div>
            
            <div class="part-details">
                <h3>📋 Request Details</h3>
                <p><strong>Request ID:</strong> $requestId</p>
                ${poNumber != null ? '<p><strong>PO Number:</strong> $poNumber</p>' : ''}
                <p><strong>Date Requested:</strong> $formattedDate</p>
                <p><strong>Requested By:</strong> $requestorName ($requestorId)</p>
                ${notes.isNotEmpty ? '<p><strong>Justification / Notes:</strong><br>$notes</p>' : ''}
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
            $requestorName ($requestorId)<br>
            Greenstem Automotive Workshop<br>
            📧 ${_gmailUsername}</p>
        </div>
    </body>
    </html>
    ''';

    final message = Message()
      ..from = Address(_gmailUsername, 'Greenstem Automotive Workshop')
      ..recipients.add(getSupplierEmail(supplier))
      ..subject = '[${priority.toUpperCase()}] Procurement Request - ${part.name} - Order #$requestId${poNumber != null ? ' | PO $poNumber' : ''}'
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
  static String _generateReadableRequestId() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final seq = now.millisecondsSinceEpoch % 1000; // fallback pseudo-seq (not used when overridden)
    return 'REQ-$yy$mm$dd-${seq.toString().padLeft(3, '0')}';
  }

  static String _fmtDateKey(DateTime d) {
    final yy = (d.year % 100).toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yy$mm$dd';
  }

  static String _fmtPoMonthKey(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$yyyy-$mm';
  }

  static String _fmtHumanDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min:$ss';
  }

  static int calculateRecommendedQuantity(Part part) {
    return part.isLowStock ? (part.lowStockThreshold * 2) : part.lowStockThreshold;
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String _getPriorityColorHex(String priority) {
    switch (priority) {
      case 'Critical':
        return '#dc3545';
      case 'High':
        return '#fd7e14';
      case 'Medium':
        return '#0d6efd';
      case 'Low':
        return '#6c757d';
      default:
        return '#6c757d';
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
        unit: data['unit'] ?? '',
      );

      await _sendEmailViaGmailSMTP(
        part,
        data['requestedQty'],
        data['priority'],
        data['supplier'],
        data['requiredByDate']?.toDate(),
        data['specialNotes'] ?? '',
        requestId,
        poNumber: data['poNumber'],
        requestorName: data['requestedBy'] ?? 'Workshop Manager',
        requestorId: data['requestorId'] ?? 'WM-001',
        requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
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

    await _firestore.collection('procurement_requests').doc(requestId).update(updateData);
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
    return _firestore.collection('procurement_requests').orderBy('requestedAt', descending: true).snapshots();
  }

  // Get single request status
  static Stream<DocumentSnapshot> getProcurementRequestStatus(String requestId) {
    return _firestore.collection('procurement_requests').doc(requestId).snapshots();
  }
}
