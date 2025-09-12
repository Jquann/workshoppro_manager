import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'pages/vehicles/service_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _vc => _db.collection('vehicles');
  CollectionReference get _counters => _db.collection('counters');

  // -------------------- INVENTORY (ADDED) --------------------
  // inventory_parts collection where each document is a category (e.g. 'Body'),
  // and each field inside the doc is a part map keyed by the part's display name.
  CollectionReference get _inventory => _db.collection('inventory_parts');

  /// Read one inventory category document and return its parts as a list of maps.
  /// Expected doc shape (like your screenshot):
  /// inventory_parts/{category}:
  ///   "Cabin Air Filters": { name, price, quantity, unit, category?, ... }
  Future<List<Map<String, dynamic>>> getPartsByCategory(String category) async {
    final doc = await _inventory.doc(category).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;

    final List<Map<String, dynamic>> out = [];
    for (final entry in data.entries) {
      final v = entry.value;
      if (v is Map<String, dynamic>) {
        out.add({
          'name': v['name'] ?? entry.key,          // fall back to field key
          'price': v['price'] ?? 0,
          'quantity': v['quantity'] ?? 0,
          'unit': v['unit'],
          'category': v['category'] ?? category,   // fall back to doc id
        });
      }
    }
    return out;
  }

  /// Atomically decrease stock for a part inside a category document.
  /// We avoid dot-paths (your keys have spaces/quotes) by updating the whole nested map.
  Future<void> reduceStock(String category, String partName, int usedQty) async {
    if (usedQty <= 0) return;
    final ref = _inventory.doc(category);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() as Map<String, dynamic>);
      if (!data.containsKey(partName)) return;

      final part = Map<String, dynamic>.from(data[partName] as Map);
      final currentQty = (part['quantity'] ?? 0) as int;
      final newQty = currentQty - usedQty;
      part['quantity'] = newQty < 0 ? 0 : newQty;

      // Update only that single field (no dot path)
      tx.update(ref, { partName: part });
    });
  }
  // ------------------ END INVENTORY (ADDED) ------------------

  // ===== ID GENERATOR (transaction-safe) =====
  Future<String> _nextFormattedId(
      String counterName,
      String prefix,
      int paddingLength,
      ) async {
    final ref = _counters.doc(counterName);
    return _db.runTransaction<String>((tx) async {
      final snap = await tx.get(ref);
      int current = 0;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>? ?? {};
        current = (data['count'] as int?) ?? 0;
      }
      final next = current + 1;
      tx.set(ref, {'count': next}, SetOptions(merge: true));
      return '$prefix${next.toString().padLeft(paddingLength, '0')}';
    });
  }

  // ===== VEHICLES =====
  Stream<List<VehicleModel>> vehiclesStream({String q = ''}) {
    return _vc.orderBy('customerName').snapshots().map((s) {
      final list = s.docs
          .map((d) => VehicleModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      if (q.isEmpty) return list;
      final needle = q.toLowerCase();
      return list.where((v) {
        final hay = '${v.customerName} ${v.make} ${v.model} ${v.year} ${v.vin}'.toLowerCase();
        return hay.contains(needle);
      }).toList();
    });
  }

  Future<VehicleModel?> getVehicle(String id) async {
    final doc = await _vc.doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Create vehicle with ID like 'VH0001' and also store it as field 'id'
  Future<String> addVehicle(VehicleModel v) async {
    final vehicleId = await _nextFormattedId('vehicles', 'VH', 4);

    final base = v.toMap();
    final payload = {
      'id': vehicleId, // <-- store ID as a field
      ...base,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _vc.doc(vehicleId).set(payload);
    // ignore: avoid_print
    print('addVehicle OK → $vehicleId');
    return vehicleId;
  }

  Future<void> updateVehicle(VehicleModel v) =>
      _vc.doc(v.id).update({
        ...v.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ===== SERVICES (subcollection per vehicle) =====
  CollectionReference _svc(String vehicleId) =>
      _vc.doc(vehicleId).collection('service_records');

  Stream<List<ServiceRecordModel>> serviceStream(String vehicleId) {
    return _svc(vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
        .map((d) => ServiceRecordModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  /// Create service with ID like 'SV0001' (counter is PER VEHICLE) and store as field 'id'
  Future<String> addService(String vehicleId, ServiceRecordModel r) async {
    final serviceId = await _nextFormattedId('services_$vehicleId', 'SV', 4);

    final base = r.toMap();
    final payload = {
      'id': serviceId, // <-- store ID as a field
      ...base,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _svc(vehicleId).doc(serviceId).set(payload);
    // ignore: avoid_print
    print('addService OK → $vehicleId/$serviceId');
    return serviceId;
  }

  Future<void> updateService(String vehicleId, ServiceRecordModel r) =>
      _svc(vehicleId).doc(r.id).update({
        ...r.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteService(String vehicleId, String id) =>
      _svc(vehicleId).doc(id).delete();
}
