import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'pages/vehicles/vehicle.dart'; // remove if unused
import 'pages/vehicles/service_model.dart';
import 'package:workshoppro_manager/models/item.dart';
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _vc => _db.collection('vehicles');
  CollectionReference get _counters => _db.collection('counters');

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
