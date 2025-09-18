class VehicleModel {
  String id;
  String customerName;
  String make;
  String model;
  int year;
  String carPlate;
  String? description; // optional
  String status;       // "active" or "inactive"

  VehicleModel({
    required this.id,
    required this.customerName,
    required this.make,
    required this.model,
    required this.year,
    required this.carPlate,
    this.description,
    this.status = 'active', // default is active
  });

  factory VehicleModel.fromMap(String id, Map<String, dynamic> m) {
    return VehicleModel(
      id: id,
      customerName: m['customerName'] ?? '',
      make: m['make'] ?? '',
      model: m['model'] ?? '',
      year: (m['year'] ?? 0) is int
          ? m['year']
          : int.tryParse('${m['year']}') ?? 0,
      carPlate: m['carPlate'] ?? '',
      description: m['description'],
      status: m['status'] ?? 'active', // fallback if missing
    );
  }

  Map<String, dynamic> toMap() => {
    'customerName': customerName,
    'make': make,
    'model': model,
    'year': year,
    'carPlate': carPlate,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'status': status,   // include in Firestore
    'updatedAt': DateTime.now(),
  };
}
