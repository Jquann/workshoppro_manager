import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunicationType {
  phone,
  email,
  sms,
  meeting,
  note,
  followUp,
  complaint,
  inquiry,
  other
}

enum CommunicationStatus {
  pending,
  completed,
  cancelled,
  followUp
}

class CommunicationModel {
  final String id;
  final String customerId;
  final String customerName;
  final CommunicationType type;
  final String subject;
  final String description;
  final CommunicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledDate;
  final String? phoneNumber;
  final String? emailAddress;
  final List<String> attachments;
  final String? createdBy; // User who created this communication
  final Map<String, dynamic>? metadata; // Additional flexible data

  CommunicationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledDate,
    this.phoneNumber,
    this.emailAddress,
    this.attachments = const [],
    this.createdBy,
    this.metadata,
  });

  factory CommunicationModel.fromMap(String id, Map<String, dynamic> data) {
    return CommunicationModel(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      type: CommunicationType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'other'),
        orElse: () => CommunicationType.other,
      ),
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      status: CommunicationStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => CommunicationStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      phoneNumber: data['phoneNumber'],
      emailAddress: data['emailAddress'],
      attachments: List<String>.from(data['attachments'] ?? []),
      createdBy: data['createdBy'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'type': type.name,
      'subject': subject,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'attachments': attachments,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  CommunicationModel copyWith({
    String? customerId,
    String? customerName,
    CommunicationType? type,
    String? subject,
    String? description,
    CommunicationStatus? status,
    DateTime? scheduledDate,
    String? phoneNumber,
    String? emailAddress,
    List<String>? attachments,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return CommunicationModel(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      scheduledDate: scheduledDate ?? this.scheduledDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  String get typeDisplayName {
    switch (type) {
      case CommunicationType.phone:
        return 'Phone Call';
      case CommunicationType.email:
        return 'Email';
      case CommunicationType.sms:
        return 'SMS';
      case CommunicationType.meeting:
        return 'Meeting';
      case CommunicationType.note:
        return 'Note';
      case CommunicationType.followUp:
        return 'Follow Up';
      case CommunicationType.complaint:
        return 'Complaint';
      case CommunicationType.inquiry:
        return 'Inquiry';
      case CommunicationType.other:
        return 'Other';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CommunicationStatus.pending:
        return 'Pending';
      case CommunicationStatus.completed:
        return 'Completed';
      case CommunicationStatus.cancelled:
        return 'Cancelled';
      case CommunicationStatus.followUp:
        return 'Follow Up Required';
    }
  }

  String getFormattedDate({bool includeTime = true}) {
    final date = createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (includeTime) {
        return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Today';
    } else if (difference.inDays == 1) {
      if (includeTime) {
        return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (includeTime) {
        return '${weekdays[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return weekdays[date.weekday - 1];
    } else {
      if (includeTime) {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}