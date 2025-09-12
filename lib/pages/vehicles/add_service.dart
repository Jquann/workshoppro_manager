import 'package:flutter/material.dart';
import 'service_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

class InventoryPartVM {
  final String category;
  final String name;
  final double price;
  final int quantity;
  final String? unit;
  const InventoryPartVM({
    required this.category,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit,
  });
  String get key => '$category|$name';
}

class AddService extends StatefulWidget {
  final String vehicleId;
  const AddService({super.key, required this.vehicleId});

  @override
  State<AddService> createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  final _form = GlobalKey<FormState>();
  final _date = TextEditingController();
  final _desc = TextEditingController();
  final _mech = TextEditingController();
  final _notes = TextEditingController();

  final _partName = TextEditingController();
  final _partQty = TextEditingController();
  final _partPrice = TextEditingController();

  final _laborName = TextEditingController();
  final _laborHours = TextEditingController();
  final _laborRate = TextEditingController();

  final List<PartLine> _parts = [];
  final List<LaborLine> _labor = [];

  // ---- Inventory UI state ----
  static const List<String> _categories = <String>[
    'Body','Brakes','Consumables','Electrical','Engine',
    'Exhaust','Maintenance','Suspension','Transmission',
  ];
  String? _selectedCategory;
  List<InventoryPartVM> _availableParts = [];
  InventoryPartVM? _selectedPart;
  final Map<String, InventoryPartVM> _invIndex = {}; // key -> vm
  final Map<String, int> _stockDeltas = {}; // "cat|name" -> qty used (to reduce)

  @override
  void initState() {
    super.initState();
    _date.text = _fmt(DateTime.now());
  }

  @override
  void dispose() {
    _date.dispose();
    _desc.dispose();
    _mech.dispose();
    _notes.dispose();
    _partName.dispose();
    _partQty.dispose();
    _partPrice.dispose();
    _laborName.dispose();
    _laborHours.dispose();
    _laborRate.dispose();
    super.dispose();
  }

  // ---- parsing helpers ----
  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;
  double _toDouble(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0;

  // ---- UI tokens ----
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

  double get _partsTotal =>
      _parts.fold<double>(0, (s, p) => s + p.unitPrice * p.quantity);
  double get _laborTotal =>
      _labor.fold<double>(0, (s, l) => s + l.rate * l.hours);
  double get _grandTotal => _partsTotal + _laborTotal;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Add Service',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        elevation: 0.2,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottom),
            children: [
              const _SectionTitle('Service Details'),
              _label('Date'),
              TextFormField(
                controller: _date,
                readOnly: true,
                decoration: _input('Select date'),
                validator: _req,
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              _label('Desc'),
              TextFormField(
                  controller: _desc,
                  decoration: _input('Please enter description'),
                  validator: _req),
              const SizedBox(height: 14),
              _label('Mechanic'),
              TextFormField(
                  controller: _mech,
                  decoration: _input('Please enter mechanic'),
                  validator: _req),

              const SizedBox(height: 18),
              const _SectionTitle('Parts Replaced'),
              _inventoryPartEditor(),

              ..._parts.map(_partPillWithStock).toList(),

              const SizedBox(height: 18),
              const _SectionTitle('Labor'),
              _laborEditor(),
              ..._labor.map((l) => _pill(
                '${l.name}  •  ${l.hours}h @ \$${l.rate.toStringAsFixed(2)}',
                onDelete: () => setState(() => _labor.remove(l)),
              )),

              const SizedBox(height: 18),
              _totalsCard(),

              const SizedBox(height: 18),
              const _SectionTitle('Notes'),
              TextFormField(
                  controller: _notes,
                  decoration: _input('Optional'),
                  maxLines: 3),

              const SizedBox(height: 24),
              ElevatedButton(
                style: _primaryBtn,
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- helpers ----------
  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
  );

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_date.text) ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) _date.text = _fmt(d);
  }

  // ---------- Inventory editor ----------
  Widget _inventoryPartEditor() {
    final stockLine = (_selectedPart == null)
        ? null
        : Text(
      'Stock: ${_selectedPart!.quantity} ${_selectedPart!.unit ?? "pcs"}',
      style: const TextStyle(color: _kGrey, fontSize: 13),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: _input('Select Category'),
          value: _selectedCategory,
          isExpanded: true,
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (cat) async {
            if (cat == null) return;
            setState(() {
              _selectedCategory = cat;
              _selectedPart = null;
              _partName.clear();
              _partPrice.clear();
              _partQty.clear();
              _availableParts = [];
            });
            final fetched = await _fetchParts(cat);
            setState(() => _availableParts = fetched);
          },
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<InventoryPartVM>(
          decoration: _input('Select Part'),
          value: _selectedPart,
          isExpanded: true,
          items: _availableParts
              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
              .toList(),
          onChanged: (p) {
            if (p == null) return;
            setState(() {
              _selectedPart = p;
              _partName.text = p.name;
              _partPrice.text = p.price.toStringAsFixed(2);
            });
          },
        ),
        const SizedBox(height: 6),
        if (stockLine != null) stockLine,

        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _partQty,
                decoration: _input('Qty'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _partPrice,
                readOnly: true,
                decoration: _input('Price (auto)'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: _kBlue),
              onPressed: _onAddPartFromInventory,
              tooltip: 'Add part line',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 16, color: _kDivider),
      ],
    );
  }

  Future<List<InventoryPartVM>> _fetchParts(String category) async {
    final rows = await FirestoreService().getPartsByCategory(category);
    final list = <InventoryPartVM>[];
    for (final m in rows) {
      final vm = InventoryPartVM(
        category: category,
        name: (m['name'] ?? '') as String,
        price: (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0,
        quantity: (m['quantity'] ?? 0) as int,
        unit: m['unit'] as String?,
      );
      list.add(vm);
      _invIndex[vm.key] = vm;
    }
    return list;
  }

  void _onAddPartFromInventory() {
    if (_selectedPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a part')),
      );
      return;
    }
    final q = _toInt(_partQty.text);
    if (q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }
    final stock = _selectedPart!.quantity;
    if (q > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $stock in stock for "${_selectedPart!.name}"')),
      );
      return;
    }

    setState(() {
      _parts.add(PartLine(
        name: _selectedPart!.name,
        quantity: q,
        unitPrice: _selectedPart!.price,
      ));
      final k = _selectedPart!.key;
      _stockDeltas[k] = (_stockDeltas[k] ?? 0) + q;
      _partQty.clear();
    });
  }

  // ---- labor editor (unchanged) ----
  Widget _laborEditor() => Row(children: [
    Expanded(child: TextField(controller: _laborName, decoration: _input('Name'))),
    const SizedBox(width: 8),
    SizedBox(
      width: 80,
      child: TextField(
        controller: _laborHours,
        decoration: _input('Hrs'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(
      width: 120,
      child: TextField(
        controller: _laborRate,
        decoration: _input('Rate'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.add_circle, color: _kBlue),
      onPressed: () {
        final name = _laborName.text.trim();
        final h = _toDouble(_laborHours.text);
        final r = _toDouble(_laborRate.text);
        if (name.isEmpty || h <= 0) return;
        setState(() {
          _labor.add(LaborLine(name: name, hours: h, rate: r));
          _laborName.clear();
          _laborHours.clear();
          _laborRate.clear();
        });
      },
    ),
  ]);

  // ---- pills ----
  Widget _pill(String text, {required VoidCallback onDelete}) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kDivider),
    ),
    child: Row(children: [
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      IconButton(onPressed: onDelete,
          icon: const Icon(Icons.close, size: 18, color: _kGrey))
    ]),
  );

  Widget _partPillWithStock(PartLine p) {
    InventoryPartVM? inv;
    for (final e in _invIndex.entries) {
      if (e.value.name == p.name) { inv = e.value; break; }
    }
    final top = '${p.name}  •  ${p.quantity} × \$${p.unitPrice.toStringAsFixed(2)}';
    final k = inv?.key;
    final willDeduct = (k != null) ? (_stockDeltas[k] ?? p.quantity) : p.quantity;
    final bottom = (inv == null)
        ? 'Stock: (unknown in inventory)'
        : 'Stock: ${inv.quantity} ${inv.unit ?? "pcs"}  •  Using: $willDeduct';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(top, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(bottom, style: const TextStyle(fontSize: 12, color: _kGrey)),
            ],
          )),
          IconButton(
            onPressed: () {
              setState(() {
                if (inv != null) {
                  final key = inv.key;
                  final cur = _stockDeltas[key] ?? 0;
                  final next = cur - p.quantity;
                  if (next > 0) { _stockDeltas[key] = next; } else { _stockDeltas.remove(key); }
                }
                _parts.remove(p);
              });
            },
            icon: const Icon(Icons.close, size: 18, color: _kGrey),
          ),
        ],
      ),
    );
  }

  // ---- totals card ----
  Widget _totalsCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kDivider),
    ),
    child: Column(
      children: [
        _totalRow('Parts', _partsTotal),
        const SizedBox(height: 6),
        _totalRow('Labor', _laborTotal),
        const Divider(height: 16, color: _kDivider),
        _totalRow('Total', _grandTotal, bold: true),
      ],
    ),
  );

  Widget _totalRow(String k, double v, {bool bold = false}) => Row(
    children: [
      Expanded(child: Text(k,
          style: TextStyle(fontSize: 15, color: Colors.black,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600))),
      Text('\$${v.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 15,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
    ],
  );

  // ---- SAVE: save service + reduce inventory stock ----
  Future<void> _onSave() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final record = ServiceRecordModel(
      id: '',
      date: DateTime.parse(_date.text),
      description: _desc.text.trim(),
      mechanic: _mech.text.trim(),
      parts: List.of(_parts),
      labor: List.of(_labor),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    final newId = await FirestoreService().addService(widget.vehicleId, record);
    // print('Saved service docId = $newId');

    for (final e in _stockDeltas.entries) {
      final parts = e.key.split('|'); // [category, name]
      if (parts.length != 2) continue;
      final category = parts[0];
      final name = parts[1];
      await FirestoreService().reduceStock(category, name, e.value);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
  );
}
