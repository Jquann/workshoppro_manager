import 'package:flutter/material.dart';
import 'service_model.dart';
import 'edit_service.dart';

class ViewService extends StatelessWidget {
  final String vehicleId;            // <-- NEW
  final ServiceRecordModel record;
  const ViewService({
    super.key,
    required this.vehicleId,
    required this.record,
  });

  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    final total = record.total;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Record',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditService(
                    vehicleId: vehicleId,
                    record: record,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Service Details',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          _kv('Date', _fmt(record.date)),
          _kv('Desc', record.description),
          _kv('Mechanic', record.mechanic),
          const SizedBox(height: 12),
          const Text('Parts Replaced',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ...record.parts.map((p) => _line(
            p.name,
            '\$${(p.unitPrice * p.quantity).toStringAsFixed(2)}',
            sub: 'Quantity: ${p.quantity}',
          )),
          const SizedBox(height: 12),
          const Text('Labor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ...record.labor.map((l) => _line(
            l.name,
            '\$${(l.rate * l.hours).toStringAsFixed(2)}',
            sub: 'Hours: ${l.hours.toStringAsFixed(0)}',
          )),
          const Divider(),
          _line('Total Cost', '\$${total.toStringAsFixed(2)}'),
          if ((record.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Notes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(record.notes!, style: const TextStyle(color: _kGrey)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(children: [
    SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: _kGrey, fontSize: 13)),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    ),
    const Divider(height: 1, color: _kDivider),
  ]);

  Widget _line(String k, String v, {String? sub}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub,
                  style: const TextStyle(color: _kGrey, fontSize: 12)),
            ),
        ]),
  );

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
