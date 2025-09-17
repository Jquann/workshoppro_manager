import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'service_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

final _currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

class InventoryPartVM {
  final String category;
  final String partId;
  final String name;
  final double price;
  final int quantity;
  final String? unit;

  const InventoryPartVM({
    required this.category,
    required this.partId,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit,
  });

  String get key => '$category|$partId';
}

class EditService extends StatefulWidget {
  final String vehicleId;
  final ServiceRecordModel record;
  const EditService({super.key, required this.vehicleId, required this.record});

  @override
  State<EditService> createState() => _EditServiceState();
}

class _EditServiceState extends State<EditService> with TickerProviderStateMixin {
  // --- colors (match AddService) ---
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSecondary = Color(0xFF5856D6);
  static const _kSuccess = Color(0xFF34C759);
  static const _kWarning = Color(0xFFFF9500);
  static const _kError = Color(0xFFFF3B30);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kDarkText = Color(0xFF1C1C1E);
  static const _kCardShadow = Color(0x1A000000);

  // --- Labor policy (same as AddService) ---
  static const double _hourlyRate = 80.0; // RM/hour
  static const Map<String, double> _defaultHoursByCategory = {
    'Body': 0.3,
    'Brakes': 0.8,
    'Consumables': 0.2,
    'Electrical': 0.7,
    'Engine': 1.2,
    'Exhaust': 0.6,
    'Maintenance': 0.4,
    'Suspension': 1.0,
    'Transmission': 1.5,
  };

  final _form = GlobalKey<FormState>();
  late final TextEditingController _date = TextEditingController(text: _fmt(widget.record.date));
  late final TextEditingController _desc = TextEditingController(text: widget.record.description);
  late final TextEditingController _mech = TextEditingController(text: widget.record.mechanic);
  late final TextEditingController _notes = TextEditingController(text: widget.record.notes ?? '');

  final _partQty = TextEditingController();
  final _partPrice = TextEditingController();

  // Parts list being edited
  late final List<PartLine> _parts = List.of(widget.record.parts);

  // For inventory dropdowns
  static const List<String> _categories = <String>[
    'Body','Brakes','Consumables','Electrical','Engine','Exhaust','Maintenance','Suspension','Transmission',
  ];
  String? _selectedCategory;
  List<InventoryPartVM> _availableParts = [];
  InventoryPartVM? _selectedPart;

  // Inventory indices
  final Map<String, InventoryPartVM> _invIndex = {}; // key -> vm
  // Track deltas vs ORIGINAL record to adjust stock correctly on save.
  late final List<PartLine> _originalParts = List.of(widget.record.parts);

  // animations
  late final AnimationController _fadeAnimationController;
  late final AnimationController _slideAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut));
    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    // Preload inventory for ALL categories so we can map names->categories for delta calc.
    _preloadInventory();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _date.dispose();
    _desc.dispose();
    _mech.dispose();
    _notes.dispose();
    _partQty.dispose();
    _partPrice.dispose();
    super.dispose();
  }

  // ---------- utils ----------
  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;
  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  InputDecoration _input(String hint, {IconData? icon, String? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 14, color: _kGrey.withValues(alpha: 0.8)),
    prefixIcon: icon != null
        ? Container(padding: const EdgeInsets.all(12), child: Icon(icon, size: 20, color: _kGrey))
        : null,
    suffixText: suffix,
    suffixStyle: TextStyle(color: _kGrey.withValues(alpha: 0.8), fontSize: 13),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _kDivider.withValues(alpha: 0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _kDivider.withValues(alpha: 0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kError, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kError, width: 2),
    ),
  );

  // ----- inventory helpers -----

  Future<void> _preloadInventory() async {
    final svc = FirestoreService();
    for (final c in _categories) {
      final rows = await svc.getPartsByCategory(c);
      for (final m in rows) {
        final vm = InventoryPartVM(
          category: c,
          partId: (m['partId'] ?? m['id'] ?? '') as String,
          name: (m['name'] ?? '') as String,
          price: (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0,
          quantity: (m['quantity'] ?? 0) as int,
          unit: m['unit'] as String?,
        );
        _invIndex[vm.key] = vm;
      }
    }
    if (mounted) setState(() {});
  }

  Future<List<InventoryPartVM>> _fetchParts(String category) async {
    final rows = await FirestoreService().getPartsByCategory(category);
    final list = <InventoryPartVM>[];
    for (final m in rows) {
      final vm = InventoryPartVM(
        category: category,
        name: (m['name'] ?? '') as String,
        partId: (m['partId'] ?? m['id'] ?? '') as String,
        price: (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0,
        quantity: (m['quantity'] ?? 0) as int,
        unit: m['unit'] as String?,
      );
      list.add(vm);
      _invIndex[vm.key] = vm;
    }
    return list;
  }

  InventoryPartVM? _lookupInventory(PartLine p) {
    // Strict match: same name and (almost) same price.
    for (final vm in _invIndex.values) {
      if (vm.name == p.name && (vm.price - p.unitPrice).abs() < 0.01) return vm;
    }
    return null;
  }

  // ---------- totals / labor ----------
  double get _partsTotal => _parts.fold<double>(0, (s, p) => s + p.unitPrice * p.quantity);

  double get _computedHours {
    double h = 0.0;
    for (final p in _parts) {
      final inv = _lookupInventory(p);
      final perUnit = _defaultHoursByCategory[inv?.category ?? ''] ?? 0.0;
      h += p.quantity * perUnit;
    }
    return h;
  }

  double get _laborAuto => _computedHours * _hourlyRate;
  double get _grandTotal => _partsTotal + _laborAuto;

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: Material(
                color: _kLightGrey,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kDarkText, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Edit Service',
                  style: TextStyle(color: _kDarkText, fontWeight: FontWeight.w700, fontSize: 20)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.white, _kLightGrey.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _form,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceDetailsCard(),
                        const SizedBox(height: 24),
                        _buildPartsCard(),
                        const SizedBox(height: 24),
                        _buildLaborCard(),
                        const SizedBox(height: 24),
                        _buildTotalsCard(),
                        const SizedBox(height: 24),
                        _buildNotesCard(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- sections (same card style as AddService) -----

  Widget _buildCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kCardShadow, offset: const Offset(0, 2), blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kDarkText)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ]),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDarkText)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildServiceDetailsCard() {
    return _buildCard(
      icon: Icons.build_rounded,
      title: 'Service Details',
      child: Column(
        children: [
          _buildFormField(
            label: 'Date',
            child: TextFormField(
              controller: _date,
              readOnly: true,
              decoration: _input('Select date', icon: Icons.calendar_today_rounded),
              validator: _req,
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description',
            child: TextFormField(
              controller: _desc,
              decoration: _input('Enter service description', icon: Icons.description_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Mechanic',
            child: TextFormField(
              controller: _mech,
              decoration: _input('Enter mechanic name', icon: Icons.person_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsCard() {
    return _buildCard(
      icon: Icons.settings_rounded,
      title: 'Parts Replaced',
      child: Column(
        children: [
          _inventoryPartEditor(),
          if (_parts.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._parts.map((part) => _buildPartPill(part)),
          ],
        ],
      ),
    );
  }

  Widget _buildLaborCard() {
    return _buildCard(
      icon: Icons.work_rounded,
      title: 'Labor',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoRow('Hourly Rate', _currency.format(_hourlyRate), icon: Icons.schedule_rounded),
          const SizedBox(height: 12),
          _buildInfoRow('Labor Cost', _currency.format(_laborAuto), icon: Icons.build_rounded),
          const SizedBox(height: 8),
          Text(
            'Labor is auto-calculated from parts by category using your default hours policy.',
            style: TextStyle(fontSize: 12, color: _kGrey.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildCard(
      icon: Icons.note_rounded,
      title: 'Additional Notes',
      child: TextFormField(
        controller: _notes,
        decoration: _input('Enter any additional notes'),
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _onSave,
        icon: const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text(
          'Save Service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsCard() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [_kPrimary.withValues(alpha: 0.05), _kSecondary.withValues(alpha: 0.05)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      boxShadow: [BoxShadow(color: _kCardShadow, offset: const Offset(0, 2), blurRadius: 12)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration:
                BoxDecoration(color: _kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_rounded, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Service Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kDarkText)),
            ],
          ),
          const SizedBox(height: 20),
          _totalRow('Parts', _partsTotal, icon: Icons.build_circle_rounded),
          const SizedBox(height: 12),
          _totalRow('Labor', _laborAuto, icon: Icons.work_rounded),
          const SizedBox(height: 16),
          Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [
            _kPrimary.withValues(alpha: 0.3), _kSecondary.withValues(alpha: 0.3),
          ]))),
          const SizedBox(height: 16),
          _totalRow('Total', _grandTotal, bold: true, icon: Icons.account_balance_wallet_rounded),
        ],
      ),
    ),
  );

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: _kLightGrey.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _kGrey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(color: _kGrey.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kDarkText)),
        ],
      ),
    );
  }

  Widget _totalRow(String k, double v, {bool bold = false, IconData? icon}) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 16, color: bold ? _kPrimary : _kGrey),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Text(
          k,
          style: TextStyle(
            fontSize: bold ? 16 : 15,
            color: bold ? _kDarkText : _kGrey.withValues(alpha: 0.8),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      Text(
        _currency.format(v),
        style: TextStyle(
          fontSize: bold ? 18 : 15,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: bold ? _kPrimary : _kDarkText,
        ),
      ),
    ],
  );

  // ----- inventory editor (match AddService) -----

  Widget _inventoryPartEditor() {
    final stockLine = (_selectedPart == null)
        ? null
        : Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kSuccess.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_rounded, size: 16, color: _kSuccess),
          const SizedBox(width: 8),
          Text(
            'Stock: ${_selectedPart!.quantity} ${_selectedPart!.unit ?? "pcs"}',
            style: const TextStyle(color: _kSuccess, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Category',
          child: DropdownButtonFormField<String>(
            decoration: _input('Select category', icon: Icons.category_rounded),
            value: _selectedCategory,
            isExpanded: true,
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (cat) async {
              if (cat == null) return;
              setState(() {
                _selectedCategory = cat;
                _selectedPart = null;
                _partPrice.clear();
                _partQty.clear();
                _availableParts = [];
              });
              final fetched = await _fetchParts(cat);
              setState(() => _availableParts = fetched);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Part',
          child: DropdownButtonFormField<InventoryPartVM>(
            decoration: _input('Select part', icon: Icons.build_circle_rounded),
            value: _selectedPart,
            isExpanded: true,
            items: _availableParts
                .map((p) => DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                  Expanded(child: Text(p.name)),
                  Text(_currency.format(p.price),
                      style: TextStyle(color: _kGrey, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ))
                .toList(),
            onChanged: (p) {
              if (p == null) return;
              setState(() {
                _selectedPart = p;
                _partPrice.text = p.price.toStringAsFixed(2);
              });
            },
          ),
        ),
        if (stockLine != null) ...[const SizedBox(height: 12), stockLine],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildFormField(
                label: 'Quantity',
                child: TextField(
                  controller: _partQty,
                  decoration: _input('Qty'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildFormField(
                label: 'Price',
                child: TextField(
                  controller: _partPrice,
                  readOnly: true,
                  decoration: _input('Price', suffix: 'RM'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kPrimary, _kSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 6)],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _onAddPartFromInventory,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onAddPartFromInventory() {
    if (_selectedPart == null) {
      _showSnackBar('Please select a part', _kWarning);
      return;
    }

    final q = _toInt(_partQty.text);
    if (q <= 0) {
      _showSnackBar('Quantity must be greater than 0', _kError);
      return;
    }

    final part = _selectedPart!;
    final stock = part.quantity;

    // Determine how many of THIS exact part (name+price) already in list
    final currentUsed = _parts
        .where((p) => p.name == part.name && (p.unitPrice - part.price).abs() < 0.01)
        .fold<int>(0, (s, p) => s + p.quantity);

    if (currentUsed + q > stock) {
      final left = stock - currentUsed;
      _showSnackBar(
        'Only $stock in stock for "${part.name}". You already added $currentUsed. You can add up to $left more.',
        _kError,
      );
      return;
    }

    setState(() {
      final idx = _parts.indexWhere((p) => p.name == part.name && (p.unitPrice - part.price).abs() < 0.01);
      if (idx >= 0) {
        final cur = _parts[idx];
        _parts[idx] = PartLine(name: cur.name, quantity: cur.quantity + q, unitPrice: cur.unitPrice);
      } else {
        _parts.add(PartLine(name: part.name, quantity: q, unitPrice: part.price));
      }
      _partQty.clear();
    });

    _showSnackBar('Part added successfully', _kSuccess);
  }

  Widget _buildPartPill(PartLine p) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: _kLightGrey.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.build_circle_rounded, size: 16, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDarkText)),
              const SizedBox(height: 2),
              Text(
                '${p.quantity} × ${_currency.format(p.unitPrice)} = ${_currency.format(p.unitPrice * p.quantity)}',
                style: TextStyle(fontSize: 12, color: _kGrey.withValues(alpha: 0.8)),
              ),
            ]),
          ),
          Container(
            decoration: BoxDecoration(color: _kError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _parts.remove(p);
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded, size: 18, color: _kError),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ----- save -----

  Future<void> _onSave() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // compute auto labor so toMap() writes laborTotal/total correctly
    final hours = _computedHours;
    final rate = _hourlyRate;

    // Build updated record (keep status unchanged)
    final updated = ServiceRecordModel(
      id: widget.record.id,
      date: DateTime.parse(_date.text),
      description: _desc.text.trim(),
      mechanic: _mech.text.trim(),
      status: widget.record.status, // keep original status
      parts: List.of(_parts),
      labor: hours > 0 ? [LaborLine(name: 'Labor', hours: hours, rate: rate)] : const [],
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    // loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              CircularProgressIndicator(color: _kPrimary, strokeWidth: 3),
              SizedBox(width: 20),
              Text('Updating service...'),
            ],
          ),
        ),
      ),
    );

    try {
      // 1) Update service
      await FirestoreService().updateService(widget.vehicleId, updated);

      // 2) Compute inventory delta vs original and apply
      Map<String, int> countByKey(List<PartLine> parts) {
        final m = <String, int>{};
        for (final p in parts) {
          final vm = _lookupInventory(p);
          if (vm == null) continue; // skip parts not from inventory
          m[vm.key] = (m[vm.key] ?? 0) + p.quantity;
        }
        return m;
      }

      final before = countByKey(_originalParts);
      final after = countByKey(_parts);

      // For each key union, calc delta = after - before
      final keys = <String>{...before.keys, ...after.keys};
      for (final k in keys) {
        final b = before[k] ?? 0;
        final a = after[k] ?? 0;
        final d = a - b;
        if (d == 0) continue;

        final parts = k.split('|'); // [category, partId]

        if (parts.length != 2) continue;

        if (d > 0) {
          // used more -> reduce stock
          await FirestoreService().reduceStock(parts[0], parts[1], d);
        } else {
          // used less -> restock (-d)
          await FirestoreService().increaseStock(parts[0], parts[1], -d);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);          // close loading dialog
      Navigator.pop(context, true);    // close edit page & signal "updated"
      _showSnackBar('Service updated successfully!', _kSuccess);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showSnackBar('Failed to update service: $e', _kError);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_date.text) ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _kDarkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) _date.text = _fmt(d);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess
                  ? Icons.check_circle_rounded
                  : color == _kError
                  ? Icons.error_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
