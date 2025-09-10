class VehicleModel {
  String id;
  String customerName;
  String make;
  String model;
  int year;
  String vin;
  String? description; // optional

  VehicleModel({
    required this.id,
    required this.customerName,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    this.description,
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
      vin: m['vin'] ?? '',
      description: m['description'],
    );
  }

  Map<String, dynamic> toMap() => {
    'customerName': customerName,
    'make': make,
    'model': model,
    'year': year,
    'vin': vin,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'updatedAt': DateTime.now(),
  };
}
