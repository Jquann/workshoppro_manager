import 'item.dart';

class Invoice {
  final String invoiceId;
  final String customerId;
  final String vehicleId;
  final String jobId;
  final String assignedMechanicId;

  final String status; // Pending, Approved, Rejected
  final String paymentStatus; // Paid, Unpaid
  final DateTime? paymentDate;

  final DateTime issueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<Item> items;
  final double subtotal;
  final double tax;
  final double grandTotal;

  final String notes;
  final String createdBy;

  Invoice({
    required this.invoiceId,
    required this.customerId,
    required this.vehicleId,
    required this.jobId,
    required this.assignedMechanicId,
    required this.status,
    required this.paymentStatus,
    this.paymentDate,
    required this.issueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.notes,
    required this.createdBy,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'],
      customerId: json['customerId'],
      vehicleId: json['vehicleId'],
      jobId: json['jobId'],
      assignedMechanicId: json['assignedMechanicId'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      issueDate: DateTime.parse(json['issueDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: (json['items'] as List)
          .map((item) => Item.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      notes: json['notes'],
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'jobId': jobId,
      'assignedMechanicId': assignedMechanicId,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate?.toIso8601String(),
      'issueDate': issueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'grandTotal': grandTotal,
      'notes': notes,
      'createdBy': createdBy,
    };
  }
}
