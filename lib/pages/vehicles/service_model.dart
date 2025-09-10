import 'package:cloud_firestore/cloud_firestore.dart';

class PartLine {
  final String name;
  final int quantity;
  final double unitPrice;

  const PartLine({required this.name, required this.quantity, required this.unitPrice});

  factory PartLine.fromMap(Map<String, dynamic> m) => PartLine(
    name: (m['name'] ?? '').toString(),
    quantity: (m['quantity'] is int)
        ? m['quantity'] as int
        : int.tryParse('${m['quantity']}') ?? 0,
    unitPrice: (m['unitPrice'] is num)
        ? (m['unitPrice'] as num).toDouble()
        : double.tryParse('${m['unitPrice']}') ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class LaborLine {
  final String name;
  final double hours;
  final double rate;

  const LaborLine({required this.name, required this.hours, required this.rate});

  factory LaborLine.fromMap(Map<String, dynamic> m) => LaborLine(
    name: (m['name'] ?? '').toString(),
    hours: (m['hours'] is num)
        ? (m['hours'] as num).toDouble()
        : double.tryParse('${m['hours']}') ?? 0.0,
    rate: (m['rate'] is num)
        ? (m['rate'] as num).toDouble()
        : double.tryParse('${m['rate']}') ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'hours': hours,
    'rate': rate,
  };
}

class ServiceRecordModel {
  String id;
  DateTime date;
  String description;
  String mechanic;
  List<PartLine> parts;
  List<LaborLine> labor;
  String? notes;

  // denormalized (from DB) – optional
  final double? partsTotalDb;
  final double? laborTotalDb;
  final double? totalDb;

  ServiceRecordModel({
    required this.id,
    required this.date,
    required this.description,
    required this.mechanic,
    this.parts = const [],
    this.labor = const [],
    this.notes,
    this.partsTotalDb,
    this.laborTotalDb,
    this.totalDb,
  });

  // compute from arrays
  double get partsTotal => parts.fold(0.0, (s, p) => s + p.unitPrice * p.quantity);
  double get laborTotal  => labor.fold(0.0, (s, l) => s + l.rate * l.hours);
  double get total       => partsTotal + laborTotal;

  // prefer DB totals if present, else compute
  double get displayTotal => (totalDb ?? (partsTotalDb ?? partsTotal) + (laborTotalDb ?? laborTotal));

  factory ServiceRecordModel.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['date'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts') ?? DateTime.now();

    final partsList = (m['parts'] as List?) ?? const [];
    final laborList = (m['labor'] as List?) ?? const [];

    return ServiceRecordModel(
      id: id,
      date: dt,
      description: (m['description'] ?? '').toString(),
      mechanic: (m['mechanic'] ?? '').toString(),
      parts: partsList.map((e) => PartLine.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      labor: laborList.map((e) => LaborLine.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      notes: (m['notes'] as String?),
      partsTotalDb: (m['partsTotal'] is num) ? (m['partsTotal'] as num).toDouble() : null,
      laborTotalDb: (m['laborTotal'] is num) ? (m['laborTotal'] as num).toDouble() : null,
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
      'parts': parts.map((e) => e.toMap()).toList(),
      'labor': labor.map((e) => e.toMap()).toList(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      // denormalized
      'partsTotal': p,
      'laborTotal': l,
      'total': t,
    };
  }
}
