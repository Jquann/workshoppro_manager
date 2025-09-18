import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String serviceType;
  final String? customerId;
  final String? customerName;
  final String? vehicleId;
  final String? mechanicId;
  final String? mechanicName;
  final String? partsCategory; // Parts replaced category
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    this.customerId,
    this.customerName,
    this.vehicleId,
    this.mechanicId,
    this.mechanicName,
    this.partsCategory,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ScheduleModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      serviceType: data['serviceType'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'],
      vehicleId: data['vehicleId'],
      mechanicId: data['mechanicId'],
      mechanicName: data['mechanicName'],
      partsCategory: data['partsCategory'],
      status: data['status'] ?? 'scheduled',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'serviceType': serviceType,
      'customerId': customerId,
      'customerName': customerName,
      'vehicleId': vehicleId,
      'mechanicId': mechanicId,
      'mechanicName': mechanicName,
      'partsCategory': partsCategory,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}