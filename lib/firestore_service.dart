import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'models/invoice.dart';
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

  Future<void> reduceStock(
    String category,
    String partName,
    int usedQty,
  ) async {
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
  Stream<List<VehicleModel>> vehiclesStream({String q = '', String? status}) {
    // In-memory filter for status to avoid composite index requirements.
    return _vc.orderBy('customerName').snapshots().map((s) {
      var list = s.docs
          .map(
            (d) => VehicleModel.fromMap(d.id, d.data() as Map<String, dynamic>),
          )
          .toList();

      if (status != null) {
        final want = status.toLowerCase();
        list = list.where((v) => v.status == want).toList();
      }

      if (q.isNotEmpty) {
        final needle = q.toLowerCase();
        list = list.where((v) {
          final hay =
              '${v.customerName} ${v.make} ${v.model} ${v.year} ${v.carPlate}'
                  .toLowerCase();
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

  Future<String> addVehicle(VehicleModel v, {String? customerId}) async {
    final vehicleId = await _nextFormattedId('vehicles', 'VH', 4);
    final payload = {
      'id': vehicleId,
      ...v.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Start a batch write to update both vehicle and customer
    final batch = _db.batch();

    // Add the vehicle
    batch.set(_vc.doc(vehicleId), payload);

    // Update the customer's vehicleIds if customerId is provided
    if (customerId != null) {
      batch.update(_db.collection('customers').doc(customerId), {
        'vehicleIds': FieldValue.arrayUnion([vehicleId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return vehicleId;
  }

  Future<void> updateVehicle(VehicleModel v) => _vc.doc(v.id).update({
    ...v.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteVehicle(String vehicleId, String status) async {
    await _vc.doc(vehicleId).update({
      'status': status.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== CUSTOMERS =====
  Stream<QuerySnapshot> get customersStream =>
      _db.collection('customers').orderBy('customerName').snapshots();

  // ===== SERVICES =====
  CollectionReference _svc(String vehicleId) =>
      _vc.doc(vehicleId).collection('service_records');

  Stream<List<ServiceRecordModel>> serviceStream(String vehicleId) {
    return _svc(vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => ServiceRecordModel.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
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
    return serviceId;
  }

  Future<void> updateService(String vehicleId, ServiceRecordModel r) => _svc(
    vehicleId,
  ).doc(r.id).update({...r.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteService(String vehicleId, String id) =>
      _svc(vehicleId).doc(id).delete();

  // ===== Photos for service (NEW) =====
  /// Appends photo URLs to `photos` array on the service document.
  Future<void> updateServicePhotos(
    String vehicleId,
    String serviceId,
    List<String> urls,
  ) async {
    if (urls.isEmpty) return;
    await _svc(vehicleId).doc(serviceId).set({
      'photos': FieldValue.arrayUnion(urls),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// (Optional) Replace the entire photos array.
  Future<void> setServicePhotos(
    String vehicleId,
    String serviceId,
    List<String> urls,
  ) async {
    await _svc(vehicleId).doc(serviceId).update({
      'photos': urls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== Invoice =====
  CollectionReference get _invoices => _db.collection('invoices');

  /// Creates an invoice from a service record
  Future<String> addInvoice(
    String vehicleId,
    ServiceRecordModel serviceRecord,
    String customerName,
    String vehiclePlate,
    String assignedMechanicId,
    String createdBy,
  ) async {
    // Generate invoice ID in format IV0001, IV0002, etc.
    final invoiceId = await _nextFormattedId('invoices', 'IV', 4);

    // Calculate totals
    final partsTotal = serviceRecord.partsTotal;
    final laborTotal = serviceRecord.laborTotal;
    final subtotal = partsTotal + laborTotal;
    const taxRate = 0.06; // 6% tax
    final tax = subtotal * taxRate;
    final grandTotal = subtotal + tax;

    final now = DateTime.now();

    final invoice = Invoice(
      invoiceId: invoiceId,
      customerName: customerName,
      vehiclePlate: vehiclePlate,
      jobId: serviceRecord.id,
      // Use service record ID as job ID
      assignedMechanicId: assignedMechanicId,
      status: 'Pending',
      // Default status
      paymentStatus: 'Unpaid',
      // Default payment status
      paymentDate: null,
      issueDate: now,
      createdAt: now,
      updatedAt: now,
      parts: serviceRecord.parts,
      labor: serviceRecord.labor,
      subtotal: subtotal,
      tax: tax,
      grandTotal: grandTotal,
      notes: serviceRecord.notes ?? '',
      createdBy: createdBy,
    );

    await _invoices.doc(invoiceId).set({
      ...invoice.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return invoiceId;
  }

  /// Get all invoices
  Stream<List<Invoice>> invoicesStream() {
    return _invoices
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Invoice.fromJson({
                  'invoiceId': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get a specific invoice
  Future<Invoice?> getInvoice(String invoiceId) async {
    final doc = await _invoices.doc(invoiceId).get();
    if (!doc.exists) return null;
    return Invoice.fromJson({
      'invoiceId': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    await _invoices.doc(invoiceId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String invoiceId,
    String paymentStatus, {
    DateTime? paymentDate,
  }) async {
    final updateData = <String, Object>{
      'paymentStatus': paymentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (paymentStatus == 'Paid' && paymentDate != null) {
      updateData['paymentDate'] = paymentDate.toIso8601String();
    } else if (paymentStatus == 'Unpaid') {
      updateData['paymentDate'] = FieldValue.delete();
    }

    await _invoices.doc(invoiceId).update(updateData);
  }
}
