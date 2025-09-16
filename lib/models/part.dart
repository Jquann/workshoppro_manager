import 'package:cloud_firestore/cloud_firestore.dart';

class Part {
  final String id;
  final String name;
  final int quantity;
  final bool isLowStock;
  final String category;
  final String manufacturer;
  final String description;
  final String documentId;
  final String supplier;
  final String barcode;
  final double price;
  final String unit;
  final String sparePartId;
  final int lowStockThreshold;
  final String supplierEmail;

  Part({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isLowStock,
    this.category = '',
    this.manufacturer = '',
    this.description = '',
    this.documentId = '',
    this.supplier = '',
    this.barcode = '',
    this.price = 0.0,
    this.unit = '',
    this.sparePartId = '',
    this.lowStockThreshold = 15,
    this.supplierEmail = '',
  });

  // Factory constructor to create Part from Firestore document
  factory Part.fromFirestore(Map<String, dynamic> data, String docId) {
    return Part(
      id: data['partId'] ?? data['sparePartId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      isLowStock: data['isLowStock'] ?? false,
      category: data['category'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      description: data['description'] ?? '',
      documentId: docId,
      supplier: data['supplier'] ?? '',
      barcode: data['barcode'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      sparePartId: data['sparePartId'] ?? '',
      lowStockThreshold: data['lowStockThreshold'] ?? 15,
      supplierEmail: data['supplierEmail'] ?? '',
    );
  }

  // Convert Part to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'partId': id,
      'name': name,
      'quantity': quantity,
      'isLowStock': isLowStock,
      'category': category,
      'manufacturer': manufacturer,
      'description': description,
      'supplier': supplier,
      'barcode': barcode,
      'price': price,
      'unit': unit,
      'sparePartId': sparePartId,
      'lowStockThreshold': lowStockThreshold,
      'supplierEmail': supplierEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
