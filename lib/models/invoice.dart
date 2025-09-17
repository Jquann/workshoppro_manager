import '../pages/vehicles/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String invoiceId; // IV0001
  final String customerName; // 
  final String vehiclePlate;
  final String jobId;
  final String assignedMechanicId;

  final String status; // Pending, Approved, Rejected
  final String paymentStatus; // Paid, Unpaid
  final DateTime? paymentDate;

  final DateTime issueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<PartLine> parts;
  final List<LaborLine> labor;
  final double subtotal;
  final double tax;
  final double grandTotal;

  final String notes;
  final String createdBy;

  Invoice({
    required this.invoiceId,
    required this.customerName,
    required this.vehiclePlate,
    required this.jobId,
    required this.assignedMechanicId,
    required this.status,
    required this.paymentStatus,
    this.paymentDate,
    required this.issueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.parts,
    required this.labor,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.notes,
    required this.createdBy,
  });

  // Computed totals
  double get partsTotal => parts.fold<double>(0, (s, p) => s + p.unitPrice * p.quantity);
  double get laborTotal => labor.fold<double>(0, (s, l) => s + l.rate * l.hours);

  // Helper method to parse date from either Timestamp or String
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now(); // fallback
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'] ?? '',
      customerName: json['customerName'] ?? '',
      vehiclePlate: json['vehiclePlate'] ?? '',
      jobId: json['jobId'] ?? '',
      assignedMechanicId: json['assignedMechanicId'] ?? '',
      status: json['status'] ?? 'Pending',
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      paymentDate: json['paymentDate'] != null
          ? _parseDate(json['paymentDate'])
          : null,
      issueDate: _parseDate(json['issueDate']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      parts: (json['parts'] as List? ?? [])
          .map((part) => PartLine.fromMap(part))
          .toList(),
      labor: (json['labor'] as List? ?? [])
          .map((labor) => LaborLine.fromMap(labor))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'customerName': customerName,
      'vehiclePlate': vehiclePlate,
      'jobId': jobId,
      'assignedMechanicId': assignedMechanicId,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate?.toIso8601String(),
      'issueDate': issueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'parts': parts.map((part) => part.toMap()).toList(),
      'labor': labor.map((labor) => labor.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'grandTotal': grandTotal,
      'notes': notes,
      'createdBy': createdBy,
    };
  }
}