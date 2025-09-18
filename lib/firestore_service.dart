import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle_model.dart';
import 'models/invoice.dart';
import 'pages/vehicles/service_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _vc => _db.collection('vehicles');

  CollectionReference get _counters => _db.collection('counters');

  // -------------------- INVENTORY (NEW) --------------------
  // Each document in `inventory_parts` is a category (e.g., "Body", "Brakes")
  // Inside the doc: a map keyed by partId (e.g., "PRT031") -> { id, name, price, quantity, lowStockThreshold, isLowStock, suppliers, ... }
  CollectionReference get _inventory => _db.collection('inventory_parts');

  /// Return all parts under a category doc, including the partId key.
  Future<List<Map<String, dynamic>>> getPartsByCategory(String category) async {
    final doc = await _inventory.doc(category).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final out = <Map<String, dynamic>>[];

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        // Ensure the id field is present; fall back to the key if absent.
        out.add({
          'partId': entry.key,
          'id': value['id'] ?? entry.key,
          'name': value['name'] ?? '',
          'price': (value['price'] is num)
              ? (value['price'] as num).toDouble()
              : 0.0,
          'quantity': (value['quantity'] is num)
              ? (value['quantity'] as num).toInt()
              : 0,
          'unit': value['unit'],
          'category': value['category'] ?? category,
          'lowStockThreshold': (value['lowStockThreshold'] is num)
              ? (value['lowStockThreshold'] as num).toInt()
              : 0,
          'isLowStock': value['isLowStock'] == true,
          'suppliers': value['suppliers'], // keep as-is (array/map)
        });
      }
    }
    return out;
  }

  /// Get a single part object by category + partId key (e.g., "Body", "PRT031").
  Future<Map<String, dynamic>?> getPart(String category, String partId) async {
    final snap = await _inventory.doc(category).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    final v = data[partId];
    if (v is! Map<String, dynamic>) return null;
    return {'partId': partId, ...v};
  }

  /// Internal helper: recompute isLowStock based on quantity & threshold.
  bool _calcIsLowStock(int qty, int threshold) => qty <= threshold;

  /// Set stock to an absolute value (e.g., in an Edit Stock screen).
  Future<void> setStock(String category, String partId, int newQty) async {
    final ref = _inventory.doc(category);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() as Map<String, dynamic>);
      if (!data.containsKey(partId)) return;

      final part = Map<String, dynamic>.from(data[partId] as Map);
      final qty = newQty < 0 ? 0 : newQty;
      final threshold = (part['lowStockThreshold'] is num)
          ? (part['lowStockThreshold'] as num).toInt()
          : 0;

      part['quantity'] = qty;
      part['isLowStock'] = _calcIsLowStock(qty, threshold);

      tx.update(ref, {partId: part});
    });
  }

  /// Increase stock by qty (e.g., received items).
  Future<void> increaseStock(String category, String partId, int qty) async {
    if (qty <= 0) return;
    final ref = _inventory.doc(category);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() as Map<String, dynamic>);
      if (!data.containsKey(partId)) return;

      final part = Map<String, dynamic>.from(data[partId] as Map);
      final current = (part['quantity'] is num)
          ? (part['quantity'] as num).toInt()
          : 0;
      final threshold = (part['lowStockThreshold'] is num)
          ? (part['lowStockThreshold'] as num).toInt()
          : 0;

      final newQty = current + qty;
      part['quantity'] = newQty;
      part['isLowStock'] = _calcIsLowStock(newQty, threshold);

      tx.update(ref, {partId: part});
    });
  }

  /// Reduce stock by qty (e.g., used in a service). Clamps at 0.
  Future<void> reduceStock(String category, String partId, int usedQty) async {
    if (usedQty <= 0) return;
    final ref = _inventory.doc(category);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() as Map<String, dynamic>);
      if (!data.containsKey(partId)) return;

      final part = Map<String, dynamic>.from(data[partId] as Map);
      final current = (part['quantity'] is num)
          ? (part['quantity'] as num).toInt()
          : 0;
      final threshold = (part['lowStockThreshold'] is num)
          ? (part['lowStockThreshold'] as num).toInt()
          : 0;

      final newQty = (current - usedQty);
      final clamped = newQty < 0 ? 0 : newQty;

      part['quantity'] = clamped;
      part['isLowStock'] = _calcIsLowStock(clamped, threshold);

      tx.update(ref, {partId: part});
    });
  }

  /// Adjust stock by delta (+/-). Wrapper over increase/reduce.
  Future<void> adjustStock(String category, String partId, int delta) async {
    if (delta == 0) return;
    if (delta > 0) {
      await increaseStock(category, partId, delta);
    } else {
      await reduceStock(category, partId, -delta);
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

    final batch = _db.batch();
    batch.set(_vc.doc(vehicleId), payload);

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

  // ===== Photos for service =====
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

  // ===== Invoices =====
  CollectionReference get _invoices => _db.collection('invoices');

  // Helper function to generate random payment method based on ratio
  // Cash:Credit Card:BankTransfer:Cheque = 5:3:1:1
  String _getRandomPaymentMethod() {
    final methods = [
      'Cash', 'Cash', 'Cash', 'Cash', 'Cash', // 5 parts
      'Credit Card', 'Credit Card', 'Credit Card', // 3 parts
      'Bank Transfer', // 1 part
      'Cheque', // 1 part
    ];
    methods.shuffle();
    return methods.first;
  }

  Future<String> addInvoice(
    String vehicleId,
    ServiceRecordModel serviceRecord,
    String customerName,
    String vehiclePlate,
    String assignedMechanicId,
    String createdBy, {
    String? customStatus,
    String? customPaymentStatus,
    String? customPaymentMethod,
    DateTime? customCreatedAt,
  }) async {
    final invoiceId = await _nextFormattedId('invoices', 'IV', 4);

    final partsTotal = serviceRecord.partsTotal;
    final laborTotal = serviceRecord.laborTotal;
    final subtotal = partsTotal + laborTotal;
    const taxRate = 0.06;
    final tax = subtotal * taxRate;
    final grandTotal = subtotal + tax;

    // Use service's last update date or custom date
    final invoiceDate =
        customCreatedAt ?? serviceRecord.updatedAt ?? DateTime.now();

    // Default to approved and paid for migration, or use custom values
    final status = customStatus ?? 'Pending';
    final paymentStatus = customPaymentStatus ?? 'Unpaid';
    final paymentMethod =
        customPaymentMethod ??
        (paymentStatus == 'Paid' ? _getRandomPaymentMethod() : null);

    final invoice = Invoice(
      invoiceId: invoiceId,
      customerName: customerName,
      vehiclePlate: vehiclePlate,
      jobId: serviceRecord.id,
      assignedMechanicId: assignedMechanicId,
      status: status,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentDate: paymentStatus == 'Paid' ? invoiceDate : null,
      issueDate: invoiceDate,
      createdAt: invoiceDate,
      updatedAt: invoiceDate,
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

  Future<Invoice?> getInvoice(String invoiceId) async {
    final doc = await _invoices.doc(invoiceId).get();
    if (!doc.exists) return null;
    return Invoice.fromJson({
      'invoiceId': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    await _invoices.doc(invoiceId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentStatus(
    String invoiceId,
    String paymentStatus, {
    String? paymentMethod,
    DateTime? paymentDate,
  }) async {
    final updateData = <String, Object>{
      'paymentStatus': paymentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (paymentStatus == 'Paid') {
      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }
      if (paymentDate != null) {
        updateData['paymentDate'] = paymentDate.toIso8601String();
      }
    } else if (paymentStatus == 'Unpaid') {
      updateData['paymentDate'] = FieldValue.delete();
      updateData['paymentMethod'] = FieldValue.delete();
    }

    await _invoices.doc(invoiceId).update(updateData);
  }
}
