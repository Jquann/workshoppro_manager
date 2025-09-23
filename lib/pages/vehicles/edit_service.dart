import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

final _currency = NumberFormat.currency(
  locale: 'ms_MY',
  symbol: 'RM',
  decimalDigits: 2,
);

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

class _EditServiceState extends State<EditService>
    with TickerProviderStateMixin {
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

  static const int _maxNotesLen = 500;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _date = TextEditingController(
    text: _fmt(widget.record.date),
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.record.description,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.record.notes ?? '',
  );

  final _partQty = TextEditingController();
  final _partPrice = TextEditingController();

  // Parts list being edited
  late final List<PartLine> _parts = List.of(widget.record.parts);

  List<String> _categories = [];
  bool _catsLoading = true;
  String? _selectedCategory;
  List<InventoryPartVM> _availableParts = [];
  InventoryPartVM? _selectedPart;

  // Mechanics dropdown
  List<Map<String, dynamic>> _mechanics = [];
  bool _mechanicsLoading = true;
  String? _selectedMechanicId;
  String? _selectedMechanicName;

  // Inventory indices
  final Map<String, InventoryPartVM> _invIndex = {}; // key -> vm
  late final List<PartLine> _originalParts = List.of(widget.record.parts);

  String? _partsError; // inline error for parts section

  // animations
  late final AnimationController _fadeAnimationController;
  late final AnimationController _slideAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOut,
          ),
        );
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _loadCategories();
    _loadMechanics();

    _selectedMechanicName = widget.record.mechanic;
    _selectedCategory = widget.record.partsCategory;
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _date.dispose();
    _desc.dispose();
    _notes.dispose();
    _partQty.dispose();
    _partPrice.dispose();
    super.dispose();
  }

  // ---------- utils ----------
  bool get _isEditable =>
      widget.record.status != ServiceRecordModel.statusCompleted &&
          widget.record.status != ServiceRecordModel.statusCancel;

  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  InputDecoration _input(
      String hint, {
        IconData? icon,
        String? suffix,
      }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: _kGrey.withValues(alpha: 0.8)),
        prefixIcon: icon != null
            ? Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: _kGrey),
        )
            : null,
        suffixText: suffix,
        suffixStyle:
        TextStyle(color: _kGrey.withValues(alpha: 0.8), fontSize: 13),
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _kError, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _kError, width: 2),
        ),
      );

  // ----- inventory helpers -----
  Future<void> _preloadInventory(List<String> categories) async {
    final svc = FirestoreService();
    for (final c in categories) {
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
    for (final vm in _invIndex.values) {
      if (vm.name == p.name && (vm.price - p.unitPrice).abs() < 0.01) return vm;
    }
    return null;
  }

  // ---------- totals / labor ----------
  double get _partsTotal =>
      _parts.fold<double>(0, (s, p) => s + p.unitPrice * p.quantity);

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

  // ---------- validation gate ----------
  bool _validateBeforeSave() {
    _partsError = null;

    final ok = _form.currentState?.validate() ?? false;
    if (!ok) {
      setState(() {}); // show field errors
      return false;
    }

    // Date sanity
    try {
      final d = DateTime.parse(_date.text);
      if (d.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        _showSnackBar('Date cannot be in the far future', _kError);
        return false;
      }
    } catch (_) {
      _showSnackBar('Invalid date format', _kError);
      return false;
    }

    // Mechanic (dropdown already validates, double-check here)
    if ((_selectedMechanicId == null || _selectedMechanicId!.isEmpty) &&
        (widget.record.mechanic.isEmpty)) {
      _showSnackBar('Please select a mechanic', _kError);
      return false;
    }

    // Require at least one part (align with AddService behavior)
    if (_parts.isEmpty) {
      setState(() => _partsError = 'Add at least one part to continue');
      _showSnackBar('Please add at least one part', _kError);
      return false;
    }

    return true;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    if (!_isEditable) {
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
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _kDarkText,
                      size: 20,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Service Record (Read-Only)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _kDarkText,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Cannot Be Edited',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This service is ${widget.record.status} and cannot be modified.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _kDarkText,
                    size: 20,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Edit Service',
                style: TextStyle(
                  color: _kDarkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                        Row(
                          children: [
                            Expanded(child: _buildResetButton()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSaveButton()),
                          ],
                        ),
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

  // ----- sections -----
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kDarkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDarkText,
          ),
        ),
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
              decoration: _input(
                'Select date',
                icon: Icons.calendar_today_rounded,
              ),
              validator: _req,
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description',
            child: TextFormField(
              controller: _desc,
              decoration: _input(
                'Enter service description',
                icon: Icons.description_rounded,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'This field is required';
                }
                if (v.trim().length < 3) {
                  return 'Please enter at least 3 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Mechanic',
            child: _mechanicsLoading
                ? Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _kDivider.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 20, color: _kGrey),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(_kPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading mechanics...',
                    style: TextStyle(color: _kGrey, fontSize: 14),
                  ),
                ],
              ),
            )
                : _mechanics.isEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                    Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No mechanics found. Please add mechanics in User Management.',
                      style:
                      TextStyle(color: _kGrey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
                : DropdownButtonFormField<String>(
              decoration: _input('Select mechanic',
                  icon: Icons.person_rounded),
              value: _selectedMechanicId,
              hint: const Text('Select mechanic'),
              isExpanded: true,
              validator: (value) {
                if ((value == null || value.isEmpty) &&
                    widget.record.mechanic.isEmpty) {
                  return 'Please select a mechanic';
                }
                return null;
              },
              items: _mechanics.map((mechanic) {
                return DropdownMenuItem<String>(
                  value: mechanic['id'],
                  child: Text(
                    mechanic['name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMechanicId = value;
                  final selectedMechanic =
                  _mechanics.firstWhere(
                        (m) => m['id'] == value,
                    orElse: () => <String, dynamic>{},
                  );
                  _selectedMechanicName =
                  selectedMechanic['name'];
                });
              },
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
          if (_partsError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _partsError!,
                style: const TextStyle(
                    color: _kError,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
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
          _buildInfoRow(
            'Hourly Rate',
            _currency.format(_hourlyRate),
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Labor Cost',
            _currency.format(_laborAuto),
            icon: Icons.build_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            'Labor is auto-calculated from parts by category using your default hours policy.',
            style: TextStyle(
              fontSize: 12,
              color: _kGrey.withValues(alpha: 0.9),
            ),
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
        maxLength: _maxNotesLen,
        buildCounter: (_, {currentLength = 0, isFocused = false, maxLength}) =>
        null,
        validator: (v) {
          if (v != null && v.length > _maxNotesLen) {
            return 'Notes must be <= $_maxNotesLen characters';
          }
          return null;
        },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _reset,
      icon: const Icon(Icons.restart_alt_rounded),
      label: const Text('Reset'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kDarkText,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: _kDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTotalsCard() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _kPrimary.withValues(alpha: 0.05),
          _kSecondary.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: _kCardShadow,
          offset: const Offset(0, 2),
          blurRadius: 12,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  color: _kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Service Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kDarkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _totalRow('Parts', _partsTotal,
              icon: Icons.build_circle_rounded),
          const SizedBox(height: 12),
          _totalRow('Labor', _laborAuto, icon: Icons.work_rounded),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kPrimary.withValues(alpha: 0.3),
                  _kSecondary.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _totalRow(
            'Total',
            _grandTotal,
            bold: true,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    ),
  );

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _kLightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _kGrey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _kGrey.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kDarkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String k, double v, {bool bold = false, IconData? icon}) =>
      Row(
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

  // ----- inventory editor -----
  Widget _inventoryPartEditor() {
    final stockLine = (_selectedPart == null)
        ? null
        : Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kSuccess.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_rounded,
              size: 16, color: _kSuccess),
          const SizedBox(width: 8),
          Text(
            'Stock: ${_selectedPart!.quantity} ${_selectedPart!.unit ?? "pcs"}',
            style: const TextStyle(
              color: _kSuccess,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
            decoration:
            _input('Select category', icon: Icons.category_rounded),
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
            decoration:
            _input('Select part', icon: Icons.build_circle_rounded),
            value: _selectedPart,
            isExpanded: true,
            items: _availableParts
                .map(
                  (p) => DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    Text(
                      _currency.format(p.price),
                      style: TextStyle(
                        color: _kGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
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
                child: TextFormField(
                  controller: _partQty,
                  decoration: _input('Qty'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (_) {
                    // validate only when a part is selected and qty is non-empty
                    if (_selectedPart == null) return null;
                    if (_partQty.text.trim().isEmpty) return null;
                    final q = _toInt(_partQty.text);
                    if (q <= 0) return 'Enter a quantity > 0';
                    final stock = _selectedPart!.quantity;
                    // count existing of this line in _parts
                    final currentUsed = _parts
                        .where((p) =>
                    p.name == _selectedPart!.name &&
                        (p.unitPrice - _selectedPart!.price).abs() < 0.01)
                        .fold<int>(0, (s, p) => s + p.quantity);
                    final allowed = stock - currentUsed;
                    if (q > allowed) return 'Only $allowed left in stock';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildFormField(
                label: 'Price',
                child: TextFormField(
                  controller: _partPrice,
                  readOnly: true,
                  decoration: _input('Price', suffix: 'RM'),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _onAddPartFromInventory,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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

    // run validators to show qty issues if any
    _form.currentState?.validate();

    final q = _toInt(_partQty.text);
    if (q <= 0) {
      _showSnackBar('Quantity must be greater than 0', _kError);
      return;
    }

    final part = _selectedPart!;
    final stock = part.quantity;

    // current used of this exact line (name+price)
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
      final idx = _parts.indexWhere(
            (p) => p.name == part.name && (p.unitPrice - part.price).abs() < 0.01,
      );
      if (idx >= 0) {
        final cur = _parts[idx];
        _parts[idx] = PartLine(
          name: cur.name,
          quantity: cur.quantity + q,
          unitPrice: cur.unitPrice,
        );
      } else {
        _parts.add(PartLine(name: part.name, quantity: q, unitPrice: part.price));
      }

      // clear inputs & selection to avoid lingering red border
      _partQty.clear();
      _selectedPart = null;
      _partPrice.clear();

      _partsError = null;
    });

    // refresh validators to clear error border
    _form.currentState?.validate();
    FocusScope.of(context).unfocus();

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
            child: const Icon(
              Icons.build_circle_rounded,
              size: 16,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.quantity} × ${_currency.format(p.unitPrice)} = ${_currency.format(p.unitPrice * p.quantity)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _kGrey.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _kError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
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

  // ----- sync to schedules -----
  Future<void> _syncToSchedules(ServiceRecordModel serviceRecord) async {
    try {
      final schedules = await FirebaseFirestore.instance
          .collection('schedules')
          .where('vehicleId', isEqualTo: widget.vehicleId)
          .where('serviceType', isEqualTo: serviceRecord.description)
          .get();

      for (final doc in schedules.docs) {
        final scheduleData = doc.data();

        String scheduleStatus;
        switch (serviceRecord.status) {
          case ServiceRecordModel.statusCompleted:
            scheduleStatus = 'completed';
            break;
          case ServiceRecordModel.statusCancel:
            scheduleStatus = 'cancelled';
            break;
          default:
            scheduleStatus = scheduleData['status'] ?? 'pending';
        }

        await doc.reference.update({
          'status': scheduleStatus,
          'mechanic': serviceRecord.mechanic,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing to schedules: $e');
    }
  }

  // ----- save -----
  Future<void> _onSave() async {
    if (!_validateBeforeSave()) return;
    FocusScope.of(context).unfocus();

    final hours = _computedHours;
    final rate = _hourlyRate;

    final updated = ServiceRecordModel(
      id: widget.record.id,
      date: DateTime.parse(_date.text),
      description: _desc.text.trim(),
      mechanic: _selectedMechanicName ?? widget.record.mechanic,
      status: widget.record.status,
      parts: List.of(_parts),
      labor: hours > 0
          ? [LaborLine(name: 'Labor', hours: hours, rate: rate)]
          : const [],
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      partsCategory: _selectedCategory,
    );

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
      await FirestoreService().updateService(widget.vehicleId, updated);
      await _syncToSchedules(updated);

      // If completed: try to create invoice
      if (updated.status == ServiceRecordModel.statusCompleted) {
        final vehicle = await FirestoreService().getVehicle(widget.vehicleId);
        if (vehicle != null) {
          try {
            await FirestoreService().addInvoice(
              widget.vehicleId,
              updated,
              vehicle.customerName,
              vehicle.carPlate,
              updated.mechanic,
              updated.mechanic,
            );
          } catch (invoiceError) {
            print('Failed to create invoice: $invoiceError');
          }
        }
      }

      // Inventory delta vs original
      Map<String, int> countByKey(List<PartLine> parts) {
        final m = <String, int>{};
        for (final p in parts) {
          final vm = _lookupInventory(p);
          if (vm == null) continue;
          m[vm.key] = (m[vm.key] ?? 0) + p.quantity;
        }
        return m;
      }

      final before = countByKey(_originalParts);
      final after = countByKey(_parts);
      final keys = <String>{...before.keys, ...after.keys};
      for (final k in keys) {
        final b = before[k] ?? 0;
        final a = after[k] ?? 0;
        final d = a - b;
        if (d == 0) continue;
        final parts = k.split('|'); // [category, partId]
        if (parts.length != 2) continue;
        if (d > 0) {
          await FirestoreService().reduceStock(parts[0], parts[1], d);
        } else {
          await FirestoreService().increaseStock(parts[0], parts[1], -d);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context, true);
      _showSnackBar('Service updated successfully!', _kSuccess);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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

  void _reset() {
    FocusScope.of(context).unfocus();

    setState(() {
      _date.text = _fmt(widget.record.date);
      _desc.text = widget.record.description;
      _notes.text = widget.record.notes ?? '';

      _parts
        ..clear()
        ..addAll(widget.record.parts.map((p) =>
            PartLine(name: p.name, quantity: p.quantity, unitPrice: p.unitPrice)));

      _selectedCategory = widget.record.partsCategory;
      _selectedPart = null;
      _availableParts = [];
      _partQty.clear();
      _partPrice.clear();
      _partsError = null;
    });

    _showSnackBar('Restored original service data', _kSuccess);
  }

  Future<void> _loadMechanics() async {
    try {
      setState(() => _mechanicsLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'mechanic')
          .get();

      final mechanicsList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      mechanicsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      if (!mounted) return;
      setState(() {
        _mechanics = mechanicsList;
        _mechanicsLoading = false;

        if (_selectedMechanicName != null && _selectedMechanicName!.isNotEmpty) {
          final matchingMechanic = mechanicsList.firstWhere(
                (m) => m['name'] == _selectedMechanicName,
            orElse: () => {},
          );
          if (matchingMechanic.isNotEmpty) {
            _selectedMechanicId = matchingMechanic['id'];
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _mechanicsLoading = false);
      _showSnackBar('Failed to load mechanics: $e', _kError);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await FirestoreService().getPartCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _catsLoading = false;
      });

      await _preloadInventory(cats);
      if (mounted) setState(() {}); // refresh totals once inventory is in
    } catch (e) {
      if (!mounted) return;
      setState(() => _catsLoading = false);
      _showSnackBar('Failed to load categories: $e', _kError);
    }
  }
}
