import 'package:flutter/material.dart';
import 'service_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

class EditService extends StatefulWidget {
  final String vehicleId;
  final ServiceRecordModel record;
  const EditService({super.key, required this.vehicleId, required this.record});

  @override
  State<EditService> createState() => _EditServiceState();
}

class _EditServiceState extends State<EditService> {
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  final _form = GlobalKey<FormState>();
  late final TextEditingController _date  = TextEditingController(text: _fmt(widget.record.date));
  late final TextEditingController _desc  = TextEditingController(text: widget.record.description);
  late final TextEditingController _mech  = TextEditingController(text: widget.record.mechanic);
  late final TextEditingController _notes = TextEditingController(text: widget.record.notes ?? '');

  final _partName = TextEditingController();
  final _partQty = TextEditingController();
  final _partPrice = TextEditingController();

  final _laborName = TextEditingController();
  final _laborHours = TextEditingController();
  final _laborRate = TextEditingController();

  late List<PartLine> _parts = List.of(widget.record.parts);
  late List<LaborLine> _labor = List.of(widget.record.labor);

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 15, color: _kGrey),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBlue),
    ),
  );

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
    backgroundColor: _kBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  );

  @override
  void dispose() {
    _date.dispose(); _desc.dispose(); _mech.dispose(); _notes.dispose();
    _partName.dispose(); _partQty.dispose(); _partPrice.dispose();
    _laborName.dispose(); _laborHours.dispose(); _laborRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Service', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true, elevation: 0.2, backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              const _SectionTitle('Service Details'),
              _label('Date'),
              TextFormField(readOnly: true, controller: _date, decoration: _input('Select date'), validator: _req, onTap: _pickDate),
              const SizedBox(height: 14),
              _label('Desc'),
              TextFormField(controller: _desc, decoration: _input('Please enter description'), validator: _req),
              const SizedBox(height: 14),
              _label('Mechanic'),
              TextFormField(controller: _mech, decoration: _input('Please enter mechanic'), validator: _req),

              const SizedBox(height: 18),
              const _SectionTitle('Parts Replaced'),
              _partEditor(),
              ..._parts.map((p) => _pill('${p.name}  •  ${p.quantity} × \$${p.unitPrice.toStringAsFixed(2)}',
                  onDelete: () => setState(() => _parts.remove(p)))),

              const SizedBox(height: 18),
              const _SectionTitle('Labor'),
              _laborEditor(),
              ..._labor.map((l) => _pill('${l.name}  •  ${l.hours}h @ \$${l.rate.toStringAsFixed(2)}',
                  onDelete: () => setState(() => _labor.remove(l)))),

              const SizedBox(height: 18),
              const _SectionTitle('Notes'),
              TextFormField(controller: _notes, decoration: _input('Optional'), maxLines: 3),

              const SizedBox(height: 24),
              ElevatedButton(
                style: _primaryBtn,
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final record = ServiceRecordModel(
                    id: widget.record.id,
                    date: DateTime.parse(_date.text),
                    description: _desc.text.trim(),
                    mechanic: _mech.text.trim(),
                    parts: _parts,
                    labor: _labor,
                    notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                  );
                  await FirestoreService().updateService(widget.vehicleId, record);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helpers (same as add)
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_date.text) ?? now;
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(now.year - 10), lastDate: DateTime(now.year + 1));
    if (d != null) _date.text = _fmt(d);
  }

  Widget _partEditor() => Row(children: [
    Expanded(child: TextField(controller: _partName, decoration: _input('Name'))),
    const SizedBox(width: 8),
    SizedBox(width: 80, child: TextField(controller: _partQty, decoration: _input('Qty'), keyboardType: TextInputType.number)),
    const SizedBox(width: 8),
    SizedBox(width: 120, child: TextField(controller: _partPrice, decoration: _input('Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
    IconButton(icon: const Icon(Icons.add_circle, color: _kBlue), onPressed: () {
      final q = int.tryParse(_partQty.text.trim()) ?? 0;
      final p = double.tryParse(_partPrice.text.trim()) ?? 0;
      if (_partName.text.trim().isEmpty || q <= 0) return;
      setState(() {
        _parts.add(PartLine(name: _partName.text.trim(), quantity: q, unitPrice: p));
        _partName.clear(); _partQty.clear(); _partPrice.clear();
      });
    }),
  ]);

  Widget _laborEditor() => Row(children: [
    Expanded(child: TextField(controller: _laborName, decoration: _input('Name'))),
    const SizedBox(width: 8),
    SizedBox(width: 80, child: TextField(controller: _laborHours, decoration: _input('Hrs'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
    const SizedBox(width: 8),
    SizedBox(width: 120, child: TextField(controller: _laborRate, decoration: _input('Rate'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
    IconButton(icon: const Icon(Icons.add_circle, color: _kBlue), onPressed: () {
      final h = double.tryParse(_laborHours.text.trim()) ?? 0;
      final r = double.tryParse(_laborRate.text.trim()) ?? 0;
      if (_laborName.text.trim().isEmpty || h <= 0) return;
      setState(() {
        _labor.add(LaborLine(name: _laborName.text.trim(), hours: h, rate: r));
        _laborName.clear(); _laborHours.clear(); _laborRate.clear();
      });
    }),
  ]);

  Widget _pill(String text, {required VoidCallback onDelete}) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kDivider)),
    child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 14))), IconButton(onPressed: onDelete, icon: const Icon(Icons.close, size: 18, color: _kGrey))]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text; const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 8),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
  );
}
