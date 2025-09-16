import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryDataManager {
  final FirebaseFirestore _firestore;

  InventoryDataManager(this._firestore);

  // Static default parts data
  static final List<Map<String, dynamic>> defaultParts = [
    // Engine System
    { 'name': 'Engine Oil (5W-30)', 'category': 'Engine', 'price': 120.0, 'supplier': 'Shell', 'supplierEmail': 'info@shell.com', 'quantity': 50, 'unit': 'Litre', 'isLowStock': false, 'lowStockThreshold': 15 }, // RM120 per litre (reasonable for branded synthetic oil)
    { 'name': 'Engine Oil (10W-40)', 'category': 'Engine', 'price': 110.0, 'supplier': 'Castrol', 'supplierEmail': 'info@castrol.com', 'quantity': 50, 'unit': 'Litre', 'isLowStock': false, 'lowStockThreshold': 15 }, // RM110 per litre (reasonable)
    { 'name': 'Oil Filters', 'category': 'Engine', 'price': 25.0, 'supplier': 'Bosch', 'supplierEmail': 'info@bosch.com', 'quantity': 30, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM25 (reasonable)
    { 'name': 'Air Filters (Engine)', 'category': 'Engine', 'price': 30.0, 'supplier': 'Denso', 'supplierEmail': 'info@denso.com', 'quantity': 30, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM30 (reasonable)
    { 'name': 'Fuel Filters', 'category': 'Engine', 'price': 35.0, 'supplier': 'Bosch', 'supplierEmail': 'info@bosch.com', 'quantity': 20, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 8 }, // RM35 (reasonable)
    { 'name': 'Spark Plugs', 'category': 'Engine', 'price': 18.0, 'supplier': 'NGK', 'supplierEmail': 'info@ngk.com', 'quantity': 40, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 15 }, // RM18 (reasonable)
    { 'name': 'Serpentine Belts', 'category': 'Engine', 'price': 45.0, 'supplier': 'Gates', 'supplierEmail': 'info@gates.com', 'quantity': 15, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 5 }, // RM45 (reasonable)
    { 'name': 'Timing Belts', 'category': 'Engine', 'price': 60.0, 'supplier': 'Gates', 'supplierEmail': 'info@gates.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM60 (reasonable)
    { 'name': 'Coolant/Antifreeze', 'category': 'Engine', 'price': 40.0, 'supplier': 'Prestone', 'supplierEmail': 'info@prestone.com', 'quantity': 25, 'unit': 'Litre', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM40 (reasonable)
    { 'name': 'Radiator Hoses', 'category': 'Engine', 'price': 22.0, 'supplier': 'Dayco', 'supplierEmail': 'info@dayco.com', 'quantity': 20, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 8 }, // RM22 (reasonable)
    { 'name': 'Engine Gaskets (Valve cover, Oil pan)', 'category': 'Engine', 'price': 55.0, 'supplier': 'Victor Reinz', 'supplierEmail': 'info@victorreinz.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM55 (reasonable)
    { 'name': 'Water Pumps (common models)', 'category': 'Engine', 'price': 120.0, 'supplier': 'Aisin', 'supplierEmail': 'info@aisin.com', 'quantity': 8, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 2 }, // RM120 (reasonable)
    // Braking System
    { 'name': 'Brake Pads (Front & Rear)', 'category': 'Brakes', 'price': 80.0, 'supplier': 'Brembo', 'supplierEmail': 'info@brembo.com', 'quantity': 20, 'unit': 'Set', 'isLowStock': false, 'lowStockThreshold': 8 }, // RM80 (reasonable)
    { 'name': 'Brake Discs/Rotors', 'category': 'Brakes', 'price': 150.0, 'supplier': 'Brembo', 'supplierEmail': 'info@brembo.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM150 (reasonable)
    { 'name': 'Brake Fluid (DOT 3/DOT 4)', 'category': 'Brakes', 'price': 25.0, 'supplier': 'Bosch', 'supplierEmail': 'info@bosch.com', 'quantity': 30, 'unit': 'Litre', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM25 (reasonable)
    { 'name': 'Brake Hoses', 'category': 'Brakes', 'price': 20.0, 'supplier': 'TRW', 'supplierEmail': 'info@trw.com', 'quantity': 15, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 5 }, // RM20 (reasonable)
    // Electrical System
    { 'name': 'Car Batteries (12V - common sizes)', 'category': 'Electrical', 'price': 250.0, 'supplier': 'Amaron', 'supplierEmail': 'info@amaron.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM250 (reasonable)
    { 'name': 'Headlight Bulbs (H4, H7)', 'category': 'Electrical', 'price': 15.0, 'supplier': 'Philips', 'supplierEmail': 'info@philips.com', 'quantity': 30, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM15 (reasonable)
    { 'name': 'Tail Light Bulbs', 'category': 'Electrical', 'price': 10.0, 'supplier': 'Osram', 'supplierEmail': 'info@osram.com', 'quantity': 30, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM10 (reasonable)
    { 'name': 'Automotive Fuses (10A, 15A, 20A, 30A)', 'category': 'Electrical', 'price': 2.0, 'supplier': 'Bosch', 'supplierEmail': 'info@bosch.com', 'quantity': 50, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 20 }, // RM2 (reasonable)
    { 'name': 'Relays (basic automotive relays)', 'category': 'Electrical', 'price': 8.0, 'supplier': 'Bosch', 'supplierEmail': 'info@bosch.com', 'quantity': 20, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 5 }, // RM8 (reasonable)
    // Suspension & Steering
    { 'name': 'Shock Absorbers (common sizes)', 'category': 'Suspension', 'price': 180.0, 'supplier': 'KYB', 'supplierEmail': 'info@kyb.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM180 (reasonable)
    { 'name': 'Tie Rod Ends', 'category': 'Suspension', 'price': 35.0, 'supplier': 'TRW', 'supplierEmail': 'info@trw.com', 'quantity': 15, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 5 }, // RM35 (reasonable)
    { 'name': 'Ball Joints', 'category': 'Suspension', 'price': 50.0, 'supplier': 'Moog', 'supplierEmail': 'info@moog.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM50 (reasonable)
    { 'name': 'Control Arm Bushings', 'category': 'Suspension', 'price': 40.0, 'supplier': 'Energy Suspension', 'supplierEmail': 'info@energysuspension.com', 'quantity': 10, 'unit': 'Set', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM40 (reasonable)
    { 'name': 'Steering Rack (reconditioned)', 'category': 'Steering', 'price': 300.0, 'supplier': 'A1 Cardone', 'supplierEmail': 'info@a1cardone.com', 'quantity': 5, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 2 }, // RM300 (reasonable)
    { 'name': 'Power Steering Pumps', 'category': 'Steering', 'price': 250.0, 'supplier': 'Aisin', 'supplierEmail': 'info@aisin.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM250 (reasonable)
    // Exhaust System
    { 'name': 'Mufflers (universal fit)', 'category': 'Exhaust', 'price': 100.0, 'supplier': 'Walker', 'supplierEmail': 'info@walker.com', 'quantity': 15, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 5 }, // RM100 (reasonable)
    { 'name': 'Exhaust Pipes (aluminized steel)', 'category': 'Exhaust', 'price': 70.0, 'supplier': 'Dynomax', 'supplierEmail': 'info@dynomax.com', 'quantity': 20, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 8 }, // RM70 (reasonable)
    { 'name': 'Catalytic Converters (universal fit)', 'category': 'Exhaust', 'price': 200.0, 'supplier': 'MagnaFlow', 'supplierEmail': 'info@magnaflow.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM200 (reasonable)
    // Body Parts
    { 'name': 'Bumpers (Front and Rear)', 'category': 'Body', 'price': 250.0, 'supplier': 'Replace', 'supplierEmail': 'info@replace.com', 'quantity': 5, 'unit': 'Set', 'isLowStock': false, 'lowStockThreshold': 2 }, // RM250 (reasonable)
    { 'name': 'Fenders', 'category': 'Body', 'price': 150.0, 'supplier': 'Replace', 'supplierEmail': 'info@replace.com', 'quantity': 10, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 3 }, // RM150 (reasonable)
    { 'name': 'Hoods', 'category': 'Body', 'price': 300.0, 'supplier': 'Replace', 'supplierEmail': 'info@replace.com', 'quantity': 5, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 2 }, // RM300 (reasonable)
    { 'name': 'Trunks', 'category': 'Body', 'price': 350.0, 'supplier': 'Replace', 'supplierEmail': 'info@replace.com', 'quantity': 5, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 2 }, // RM350 (reasonable)
    // Interior Parts
    { 'name': 'Seat Covers (Universal)', 'category': 'Interior', 'price': 100.0, 'supplier': 'Covercraft', 'supplierEmail': 'info@covercraft.com', 'quantity': 20, 'unit': 'Set', 'isLowStock': false, 'lowStockThreshold': 8 }, // RM100 (reasonable)
    { 'name': 'Floor Mats (Universal)', 'category': 'Interior', 'price': 50.0, 'supplier': 'WeatherTech', 'supplierEmail': 'info@weathertech.com', 'quantity': 30, 'unit': 'Set', 'isLowStock': false, 'lowStockThreshold': 10 }, // RM50 (reasonable)
    { 'name': 'Steering Wheel Covers', 'category': 'Interior', 'price': 25.0, 'supplier': 'Pilot', 'supplierEmail': 'info@pilot.com', 'quantity': 40, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 15 }, // RM25 (reasonable)
    { 'name': 'Gear Shift Knobs', 'category': 'Interior', 'price': 15.0, 'supplier': 'Blox Racing', 'supplierEmail': 'info@bloxracing.com', 'quantity': 50, 'unit': 'Piece', 'isLowStock': false, 'lowStockThreshold': 20 }, // RM15 (reasonable)
  ];

  // Fetches all inventory parts from Firestore
  Future<List<Map<String, dynamic>>> fetchAllInventoryParts() async {
    final snapshot = await _firestore.collection('inventory_parts').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Deletes all inventory parts for the given categories
  Future<void> deleteAllInventoryParts(List<String> categories) async {
    for (final category in categories) {
      await _firestore.collection('inventory_parts').doc(category).delete();
    }
  }

  // Uploads the default parts to Firestore, overwriting existing data
  Future<void> uploadDefaultParts(List<Map<String, dynamic>> partsWithIds) async {
    // Group parts by category
    final Map<String, Map<String, dynamic>> categoryData = {};
    for (final part in partsWithIds) {
      final category = part['category'] as String;
      final partId = part['id'] as String;
      categoryData.putIfAbsent(category, () => {});
      categoryData[category]![part['name']] = part;
    }
    // Upload each category document
    for (final entry in categoryData.entries) {
      await _firestore.collection('inventory_parts').doc(entry.key).set(entry.value);
    }
  }

  // Returns default parts with unique IDs
  static List<Map<String, dynamic>> getDefaultPartsWithIds() {
    int counter = 1;
    return defaultParts.map((part) {
      final newPart = Map<String, dynamic>.from(part);
      newPart['id'] = 'PRT${counter.toString().padLeft(3, '0')}';
      counter++;
      return newPart;
    }).toList();
  }
}
