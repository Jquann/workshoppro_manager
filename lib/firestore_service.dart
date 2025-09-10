import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'pages/vehicles/vehicle.dart';
import 'pages/vehicles/service_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _vc => _db.collection('vehicles');

  // VEHICLES
  Stream<List<VehicleModel>> vehiclesStream({String q = ''}) {
    return _vc.orderBy('customerName').snapshots().map((s) {
      final list = s.docs.map((d) => VehicleModel.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
      if (q.isEmpty) return list;
      final needle = q.toLowerCase();
      return list.where((v) => ('${v.customerName} ${v.make} ${v.model} ${v.year} ${v.vin}').toLowerCase().contains(needle)).toList();
    });
  }

  Future<VehicleModel?> getVehicle(String id) async {
    final doc = await _vc.doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<String> addVehicle(VehicleModel v) async {
    final ref = await _vc.add(v.toMap()..putIfAbsent('createdAt', () => DateTime.now()));
    return ref.id;
  }

  Future<void> updateVehicle(VehicleModel v) => _vc.doc(v.id).update(v.toMap());

  // SERVICES (subcollection)
  CollectionReference _svc(String vehicleId) => _vc.doc(vehicleId).collection('service_records');

  Stream<List<ServiceRecordModel>> serviceStream(String vehicleId) {
    return _svc(vehicleId).orderBy('date', descending: true).snapshots().map((s) =>
        s.docs.map((d) => ServiceRecordModel.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());
  }

  Future<String> addService(String vehicleId, ServiceRecordModel r) async {
    try {
      final ref = await _svc(vehicleId).add(r.toMap());
      // ignore: avoid_print
      print('addService OK → ${ref.path}');
      return ref.id;
    } catch (e, st) {
      // ignore: avoid_print
      print('addService ERROR: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateService(String vehicleId, ServiceRecordModel r) => _svc(vehicleId).doc(r.id).update(r.toMap());
  Future<void> deleteService(String vehicleId, String id) => _svc(vehicleId).doc(id).delete();
}
