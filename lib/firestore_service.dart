import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'pages/vehicles/service_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _vc => _db.collection('vehicles');
  CollectionReference get _counters => _db.collection('counters');

  // -------------------- INVENTORY --------------------
  CollectionReference get _inventory => _db.collection('inventory_parts');

  Future<List<Map<String, dynamic>>> getPartsByCategory(String category) async {
    final doc = await _inventory.doc(category).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final out = <Map<String, dynamic>>[];
    for (final entry in data.entries) {
      final v = entry.value;
      if (v is Map<String, dynamic>) {
        out.add({
          'name': v['name'] ?? entry.key,
          'price': v['price'] ?? 0,
          'quantity': v['quantity'] ?? 0,
          'unit': v['unit'],
          'category': v['category'] ?? category,
        });
      }
    }
    return out;
  }

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

      tx.update(ref, {partName: part});
    });
  }

  Future<void> increaseStock(String category, String partName, int qty) async {
    if (qty <= 0) return;
    final ref = _inventory.doc(category);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() as Map<String, dynamic>);
      if (!data.containsKey(partName)) return;

      final part = Map<String, dynamic>.from(data[partName] as Map);
      final currentQty = (part['quantity'] ?? 0) as int;
      part['quantity'] = currentQty + qty;

      tx.update(ref, {partName: part});
    });
  }

  Future<void> adjustStock(String category, String partName, int delta) async {
    if (delta == 0) return;
    if (delta > 0) {
      await increaseStock(category, partName, delta);
    } else {
      await reduceStock(category, partName, -delta);
    }
  }
  // ------------------ END INVENTORY ------------------

  // ===== ID GENERATOR =====
  Future<String> _nextFormattedId(String counterName, String prefix, int paddingLength) async {
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
  Stream<List<VehicleModel>> vehiclesStream({String q = '', String? status}) {
    // In-memory filter for status to avoid composite index requirements.
    return _vc.orderBy('customerName').snapshots().map((s) {
      var list = s.docs
          .map((d) => VehicleModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      if (status != null) {
        final want = status.toLowerCase();
        list = list.where((v) => v.status == want).toList();
      }

      if (q.isNotEmpty) {
        final needle = q.toLowerCase();
        list = list.where((v) {
          final hay = '${v.customerName} ${v.make} ${v.model} ${v.year} ${v.vin}'.toLowerCase();
          return hay.contains(needle);
        }).toList();
      }
      return list;
    });
  }

  Future<VehicleModel?> getVehicle(String id) async {
    final doc = await _vc.doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<String> addVehicle(VehicleModel v) async {
    final vehicleId = await _nextFormattedId('vehicles', 'VH', 4);
    final payload = {
      'id': vehicleId,
      ...v.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _vc.doc(vehicleId).set(payload);
    // ignore: avoid_print
    print('addVehicle OK → $vehicleId');
    return vehicleId;
  }

  Future<void> updateVehicle(VehicleModel v) => _vc.doc(v.id).update({
    ...v.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteVehicle(String vehicleId, bool isActive) async {
    await _vc.doc(vehicleId).update({
      'status': isActive ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== SERVICES =====
  CollectionReference _svc(String vehicleId) => _vc.doc(vehicleId).collection('service_records');

  Stream<List<ServiceRecordModel>> serviceStream(String vehicleId) {
    return _svc(vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
        .map((d) => ServiceRecordModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<String> addService(String vehicleId, ServiceRecordModel r) async {
    final serviceId = await _nextFormattedId('services_$vehicleId', 'SV', 4);
    final payload = {
      'id': serviceId,
      ...r.toMap(),
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
