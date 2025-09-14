import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'service_model.dart';

final _currency =
NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

class ViewService extends StatelessWidget {
  final String vehicleId; // kept for routing parity
  final ServiceRecordModel record;
  const ViewService({
    super.key,
    required this.vehicleId,
    required this.record,
  });

  // tokens
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kCard = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    // same scaling system as ViewVehicle
    final w = MediaQuery.of(context).size.width;
    const base = 375.0;
    final s = (w / base).clamp(0.95, 1.12);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Record',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: (22 * s).clamp(20, 24), // match ViewVehicle title
          ),
        ),
        centerTitle: true,
        elevation: 0.2,
        backgroundColor: Colors.white,
      ),

      body: ListView(
        padding: EdgeInsets.all(16 * s),
        children: [
          // ---------- Service Details ----------
          _sectionTitle('Service Details', s),
          _kv('Date', _fmt(record.date), s),
          _kv('Desc', record.description, s),
          _kv('Mechanic', record.mechanic, s),

          SizedBox(height: 18 * s),

          // ---------- Parts ----------
          _sectionTitle('Parts Replaced', s),
          ...record.parts.map((p) => _lineItem(
            name: p.name,
            amount: _currency.format(p.unitPrice * p.quantity),
            sub: 'Quantity: ${p.quantity}',
            s: s,
          )),

          SizedBox(height: 18 * s),

          // ---------- Labor ----------
          _sectionTitle('Labor', s),
          ...record.labor.map((l) => _lineItem(
            name: l.name,
            amount: _currency.format(l.rate * l.hours),
            sub: 'Hours: ${_trimHours(l.hours)}',
            s: s,
          )),

          SizedBox(height: 8 * s),
          const Divider(height: 1, color: _kDivider),

          // ---------- Total ----------
          Padding(
            padding: EdgeInsets.only(top: 12 * s),
            child: _lineItem(
              name: 'Total Cost',
              amount: _currency.format(record.displayTotal),
              s: s,
              bold: true,
              showSub: false,
            ),
          ),

          // ---------- Notes ----------
          if ((record.notes ?? '').isNotEmpty) ...[
            SizedBox(height: 16 * s),
            _sectionTitle('Notes', s),
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kDivider),
              ),
              child: Text(
                record.notes!,
                style: TextStyle(
                  color: _kGrey,
                  fontSize: (15 * s).clamp(14, 17), // bumped to match vehicle info
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- section/title ----------
  Widget _sectionTitle(String text, double s) => Padding(
    padding: EdgeInsets.only(top: 6 * s, bottom: 8 * s),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: (20 * s).clamp(18, 22), // bigger for section headers
      ),
    ),
  );

  // ---------- key/value row ----------
  Widget _kv(String k, String v, double s) => Column(
    children: [
      SizedBox(
        height: (56 * s).clamp(52, 64),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: TextStyle(
                  color: _kGrey,
                  fontSize: (16 * s).clamp(15, 17), // label font
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: (17 * s).clamp(16, 19), // value font
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: _kDivider),
    ],
  );

  // ---------- line item (name + amount + optional sub) ----------
  Widget _lineItem({
    required String name,
    required String amount,
    required double s,
    String? sub,
    bool showSub = true,
    bool bold = false,
  }) {
    final nameStyle = TextStyle(
      fontSize: (17 * s).clamp(16, 19),
      fontWeight: FontWeight.w500,
    );
    final amountStyle = TextStyle(
      fontSize: (17 * s).clamp(16, 19),
      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
    );
    final subStyle = TextStyle(
      color: _kBlue,
      fontSize: (14 * s).clamp(13, 15),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: nameStyle)),
              Text(amount, style: amountStyle),
            ],
          ),
          if (showSub && sub != null)
            Padding(
              padding: EdgeInsets.only(top: 2 * s),
              child: Text(sub, style: subStyle),
            ),
        ],
      ),
    );
  }

  static String _trimHours(double h) {
    final asInt = h.toInt();
    return (h == asInt)
        ? '$asInt'
        : h.toStringAsFixed(h.truncateToDouble() == h ? 0 : 1);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}
