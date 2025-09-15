import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String emailAddress;
  final List<String> vehicleIds; // Store associated vehicle IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.vehicleIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(String id, Map<String, dynamic> data) {
    return CustomerModel(
      id: id,
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      emailAddress: data['emailAddress'] ?? '',
      vehicleIds: List<String>.from(data['vehicleIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'vehicleIds': vehicleIds,
    };
  }

  CustomerModel copyWith({
    String? customerName,
    String? phoneNumber,
    String? emailAddress,
    List<String>? vehicleIds,
  }) {
    return CustomerModel(
      id: id,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}