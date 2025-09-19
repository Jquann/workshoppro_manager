import 'package:cloud_firestore/cloud_firestore.dart';

class PartLine {
  final String name;
  final int quantity;
  final double unitPrice;
  final String? category; // optional

  const PartLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.category,
  });

  factory PartLine.fromMap(Map<String, dynamic> m) => PartLine(
    name: (m['name'] ?? '').toString(),
    quantity: (m['quantity'] is int)
        ? m['quantity'] as int
        : int.tryParse('${m['quantity']}') ?? 0,
    unitPrice: (m['unitPrice'] is num)
        ? (m['unitPrice'] as num).toDouble()
        : double.tryParse('${m['unitPrice']}') ?? 0.0,
    category: (m['category'] ?? m['partsCategory'])?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
    if (category != null && category!.isNotEmpty) 'category': category,
  };
}

class LaborLine {
  final String name;
  final double hours;
  final double rate;

  const LaborLine({
    required this.name,
    required this.hours,
    required this.rate,
  });

  factory LaborLine.fromMap(Map<String, dynamic> m) => LaborLine(
    name: (m['name'] ?? '').toString(),
    hours: (m['hours'] is num)
        ? (m['hours'] as num).toDouble()
        : double.tryParse('${m['hours']}') ?? 0.0,
    rate: (m['rate'] is num)
        ? (m['rate'] as num).toDouble()
        : double.tryParse('${m['rate']}') ?? 0.0,
  );

  Map<String, dynamic> toMap() => {'name': name, 'hours': hours, 'rate': rate};
}

class ServiceRecordModel {
  String id;
  DateTime date;
  String description;
  String mechanic;
  String status; // string-based status
  List<PartLine> parts;
  List<LaborLine> labor;
  String? notes;
  String? partsCategory; // optional: record-level category

  // Firestore timestamps
  DateTime? createdAt;
  DateTime? updatedAt;

  // denormalized (from DB) – optional
  final double? partsTotalDb;
  final double? laborTotalDb;
  final double? totalDb;

  static const String statusAssign = 'scheduled';
  static const String statusInProgress = 'in progress';
  static const String statusCompleted = 'completed';
  static const String statusCancel = 'cancelled';

  ServiceRecordModel({
    required this.id,
    required this.date,
    required this.description,
    required this.mechanic,
    this.status = statusInProgress, // default so it shows under your tabs
    this.parts = const [],
    this.labor = const [],
    this.notes,
    this.partsCategory,
    this.createdAt,
    this.updatedAt,
    this.partsTotalDb,
    this.laborTotalDb,
    this.totalDb,
  });

  // computed totals
  double get partsTotal =>
      parts.fold(0.0, (s, p) => s + p.unitPrice * p.quantity);

  double get laborTotal => labor.fold(0.0, (s, l) => s + l.rate * l.hours);

  double get total => partsTotal + laborTotal;

  // prefer DB totals if present
  double get displayTotal =>
      (totalDb ?? (partsTotalDb ?? partsTotal) + (laborTotalDb ?? laborTotal));

  factory ServiceRecordModel.fromMap(String id, Map<String, dynamic> m) {
    // date
    final ts = m['date'];
    final dt = ts is Timestamp
        ? ts.toDate()
        : DateTime.tryParse('$ts') ?? DateTime.now();

    // make a list of maps, ignoring any non-map entries (e.g. stray doubles)
    List<Map<String, dynamic>> _asListOfMaps(dynamic x) {
      if (x is List) {
        return x
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (x is Map) {
        return x.values
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return const [];
    }

    final partsList = _asListOfMaps(m['parts']);
    final laborList = _asListOfMaps(m['labor']);

    DateTime? _parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ServiceRecordModel(
      id: id,
      date: dt,
      description: (m['description'] ?? '').toString(),
      mechanic: (m['mechanic'] ?? '').toString(),
      status: (m['status'] ?? statusInProgress).toString(),
      parts: partsList.map((e) => PartLine.fromMap(e)).toList(),
      labor: laborList.map((e) => LaborLine.fromMap(e)).toList(),
      notes: (m['notes'] as String?),
      partsCategory: (m['partsCategory'] as String?),
      createdAt: _parseTs(m['createdAt']),
      updatedAt: _parseTs(m['updatedAt']),
      partsTotalDb:
      (m['partsTotal'] is num) ? (m['partsTotal'] as num).toDouble() : null,
      laborTotalDb:
      (m['laborTotal'] is num) ? (m['laborTotal'] as num).toDouble() : null,
      totalDb: (m['total'] is num) ? (m['total'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    final p = partsTotal;
    final l = laborTotal;
    final t = p + l;
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'mechanic': mechanic,
      'status': status,
      'parts': parts.map((e) => e.toMap()).toList(),
      'labor': labor.map((e) => e.toMap()).toList(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (partsCategory != null && partsCategory!.isNotEmpty)
        'partsCategory': partsCategory,
      // denormalized
      'partsTotal': p,
      'laborTotal': l,
      'total': t,
    };
  }

  // status options used by UI
  static List<String> get statusOptions => [
    statusAssign,
    statusInProgress,
    statusCompleted,
    statusCancel,
  ];

  bool get isStatusValid => statusOptions.contains(status);
}
