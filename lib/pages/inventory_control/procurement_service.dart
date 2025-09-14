// Updated procurement_service.dart with real email functionality

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/part.dart';

class ProcurementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Submit procurement request with real email sending
  static Future<String> submitProcurementRequestWithEmail({
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
      'status': 'Pending Email', // Initial status
      'deliveryStatus': 'Pending',
      'requestedBy': 'Workshop Manager',
      'requestedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'eta': null,
      'trackingNumber': null,
      'emailContent': generateProcurementEmail(part, quantity, priority, supplier, requiredBy, notes, requestId),
    };

    // Save to Firestore - this will trigger the Cloud Function to send email
    await _firestore
        .collection('procurement_requests')
        .doc(requestId)
        .set(requestData);

    return requestId;
  }

  // Listen to real-time status updates
  static Stream<DocumentSnapshot> getProcurementRequestStatus(String requestId) {
    return _firestore
        .collection('procurement_requests')
        .doc(requestId)
        .snapshots();
  }

  // Get all procurement requests with real-time updates
  static Stream<QuerySnapshot> getProcurementRequestsStream() {
    return _firestore
        .collection('procurement_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  // Manually update request status (for testing or manual intervention)
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

  // Resend email for failed requests
  static Future<void> resendEmail(String requestId) async {
    try {
      final callable = _functions.httpsCallable('resendProcurementEmail');
      await callable.call({'requestId': requestId});
    } catch (e) {
      throw Exception('Failed to resend email: $e');
    }
  }

  // Update procurement history for parts
  static Future<void> updatePartProcurementHistory(
      String partId,
      String requestId,
      int quantity,
  ) async {
    final historyData = {
      'partId': partId,
      'requestId': requestId,
      'quantity': quantity,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'Pending',
    };

    await _firestore
        .collection('procurement_history')
        .add(historyData);
  }

  // Generate unique request ID
  static String _generateRequestId() {
    return 'PR${DateTime.now().millisecondsSinceEpoch}';
  }

  // All other existing helper methods remain the same...
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

  static String generateProcurementEmail(
      Part part,
      int quantity,
      String priority,
      String supplier,
      DateTime? requiredBy,
      String notes,
      String requestId,
      ) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';
    final requiredByText = requiredBy != null
        ? '${requiredBy.day}/${requiredBy.month}/${requiredBy.year}'
        : 'As soon as possible';

    return '''
Subject: [${priority.toUpperCase()}] Procurement Request - ${part.name} - Order #$requestId

Dear $supplier Team,

We would like to request the following spare part for our workshop:

PART DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Part Name: ${part.name}
Part ID: ${part.id}
Category: ${part.category}
Current Stock: ${part.quantity} units
Reorder Threshold: ${part.lowStockThreshold} units
Requested Quantity: $quantity units
Priority: $priority
Required By: $requiredByText

REQUEST DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Request ID: $requestId
Date Requested: $formattedDate
Requested By: Workshop Manager
${notes.isNotEmpty ? '\nSpecial Instructions:\n$notes\n' : ''}

Please confirm this order by clicking the confirmation link in the email or reply with:
• Availability confirmation
• Unit price and total cost  
• Estimated delivery date
• Any minimum order requirements
• Delivery charges (if applicable)

Best regards,
Workshop Manager
Greenstem Automotive Workshop
''';
  }
}