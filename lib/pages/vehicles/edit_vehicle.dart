import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'vehicle_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

class EditVehicle extends StatefulWidget {
  final VehicleModel vehicle;
  const EditVehicle({super.key, required this.vehicle});
  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> with TickerProviderStateMixin {
  // —— Same tokens as AddVehicle ——
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSecondary = Color(0xFF5856D6);
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kDarkText = Color(0xFF1C1C1E);
  static const _kCardShadow = Color(0x1A000000);

  final _form = GlobalKey<FormState>();
  final _model = TextEditingController();
  final _make = TextEditingController();
  final _year = TextEditingController();
  final _carPlate = TextEditingController();
  final _desc = TextEditingController();
  final _db = FirestoreService();

  String? selectedCustomerId;
  String? selectedCustomerName;

  // Preselect helper
  bool _customerPreselected = false;

  // Animations
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Prefill fields from vehicle
    _model.text = widget.vehicle.model;
    _make.text = widget.vehicle.make;
    _year.text = widget.vehicle.year.toString();
    _carPlate.text = widget.vehicle.carPlate;
    _desc.text = widget.vehicle.description ?? '';
    selectedCustomerName = widget.vehicle.customerName;

    // Find current customerId from name (your original behavior)
    _initializeCustomerData();

    // Animations
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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  Future<void> _initializeCustomerData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('customerName', isEqualTo: widget.vehicle.customerName)
        .limit(1)
        .get();

    if (!mounted) return;
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        selectedCustomerId = querySnapshot.docs.first.id;
      });
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _model.dispose();
    _make.dispose();
    _year.dispose();
    _carPlate.dispose();
    _desc.dispose();
    super.dispose();
  }

  // —— Same input deco as AddVehicle ——
  InputDecoration _input(String hint, {IconData? icon, String? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 14, color: _kGrey.withValues(alpha: 0.8)),
    prefixIcon: icon != null
        ? Container(
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: 20, color: _kGrey),
    )
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
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: _kPrimary, width: 2),
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // —— SliverAppBar identical to AddVehicle ——
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
                'Edit Vehicle',
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
                    colors: [
                      Colors.white,
                      _kLightGrey.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // —— Body (cards + animations) ——
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
                        _buildCustomerCard(),
                        const SizedBox(height: 24),
                        _buildVehicleDetailsCard(),
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

  // —— Customer card: shows NAME, preselected, same look as AddVehicle ——
  Widget _buildCustomerCard() {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Customer Information',
      child: _buildFormField(
        label: 'Customer',
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.customersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Error loading customers', style: TextStyle(color: _kError)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
                ),
              );
            }

            final customers = snapshot.data?.docs ?? [];

            // Extra safety: if we haven't preselected yet, try to match by current name
            if (!_customerPreselected && customers.isNotEmpty && selectedCustomerId == null && selectedCustomerName != null) {
              QueryDocumentSnapshot? match;
              for (final c in customers) {
                final d = c.data() as Map<String, dynamic>;
                if ((d['customerName'] ?? '') == selectedCustomerName) {
                  match = c;
                  break;
                }
              }
              if (match != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final d = match!.data() as Map<String, dynamic>;
                  setState(() {
                    selectedCustomerId = match!.id;
                    selectedCustomerName = d['customerName'];
                    _customerPreselected = true;
                  });
                });
              }
            }

            final items = customers.map((customer) {
              final data = customer.data() as Map<String, dynamic>;
              return DropdownMenuItem<String>(
                value: customer.id,
                child: Text(
                  data['customerName'] ?? 'Unknown Customer',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              );
            }).toList();

            return DropdownButtonFormField<String>(
              decoration: _input('Select customer', icon: Icons.people_rounded),
              value: selectedCustomerId,
              isExpanded: true,
              hint: Text(
                selectedCustomerName ?? 'Select customer',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              // Ensure the collapsed view shows NAME
              selectedItemBuilder: (context) {
                return customers.map((customer) {
                  final data = customer.data() as Map<String, dynamic>;
                  final name = data['customerName'] ?? 'Unknown Customer';
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList();
              },
              validator: (value) => value == null ? 'Please select a customer' : null,
              items: items,
              onChanged: (value) {
                setState(() {
                  selectedCustomerId = value;
                  if (value != null) {
                    final customer = customers.firstWhere((c) => c.id == value);
                    final data = customer.data() as Map<String, dynamic>;
                    selectedCustomerName = data['customerName'];
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }

  // —— Details card (same as AddVehicle) ——
  Widget _buildVehicleDetailsCard() {
    return _buildCard(
      icon: Icons.directions_car_rounded,
      title: 'Vehicle Details',
      child: Column(
        children: [
          _buildFormField(
            label: 'Vehicle Make',
            child: TextFormField(
              controller: _make,
              decoration: _input('Enter vehicle make', icon: Icons.business_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Vehicle Model',
            child: TextFormField(
              controller: _model,
              decoration: _input('Enter vehicle model', icon: Icons.car_repair_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Vehicle Year',
            child: TextFormField(
              controller: _year,
              decoration: _input('Enter year', icon: Icons.calendar_today_rounded).copyWith(
                helperText: 'Year must be between 1980 and ${DateTime.now().year + 1}',
                helperStyle: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: _yearV,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Car Plate Number',
            child: TextFormField(
              controller: _carPlate,
              decoration: _input('Enter VIN number', icon: Icons.qr_code_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description (Optional)',
            child: TextFormField(
              controller: _desc,
              decoration: _input('Enter additional details'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  // —— Shared card shell ——
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
            spreadRadius: 0,
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

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
          'Save Changes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // —— Validators (match AddVehicle) ——
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _yearV(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final n = int.tryParse(v);
    if (n == null || n < 1980 || n > DateTime.now().year + 1) {
      return 'Invalid year';
    }
    return null;
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

  Future<void> _onSave() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (selectedCustomerId == null) {
      _showSnackBar('Please select a customer', _kError);
      return;
    }

    // Loading dialog (same style as AddVehicle)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircularProgressIndicator(color: _kPrimary, strokeWidth: 3),
              const SizedBox(width: 20),
              const Text('Updating vehicle...'),
            ],
          ),
        ),
      ),
    );

    try {
      final updatedVehicle = VehicleModel(
        id: widget.vehicle.id,
        customerName: selectedCustomerName ?? widget.vehicle.customerName,
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.parse(_year.text.trim()),
        carPlate: _carPlate.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        status: widget.vehicle.status, // preserve
      );

      // —— Keep your existing manual reassignment logic ——
      if (selectedCustomerId != null &&
          selectedCustomerName != widget.vehicle.customerName) {
        // Remove from old customer (by name)
        final oldCustomerQuery = await FirebaseFirestore.instance
            .collection('customers')
            .where('customerName', isEqualTo: widget.vehicle.customerName)
            .limit(1)
            .get();

        if (oldCustomerQuery.docs.isNotEmpty) {
          final oldCustomerDoc = oldCustomerQuery.docs.first;
          final oldVehicleIds = List<String>.from(oldCustomerDoc.data()['vehicleIds'] ?? []);
          oldVehicleIds.remove(widget.vehicle.id);
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(oldCustomerDoc.id)
              .update({'vehicleIds': oldVehicleIds});
        }

        // Add to new customer (by selected id)
        final newCustomerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(selectedCustomerId)
            .get();

        final newVehicleIds = List<String>.from(newCustomerDoc.data()?['vehicleIds'] ?? []);
        if (!newVehicleIds.contains(widget.vehicle.id)) {
          newVehicleIds.add(widget.vehicle.id);
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(selectedCustomerId)
              .update({'vehicleIds': newVehicleIds});
        }
      }

      // Update vehicle document itself
      await _db.updateVehicle(updatedVehicle);

      if (mounted) {
        Navigator.pop(context); // close loading
        Navigator.pop(context, true); // success
        _showSnackBar('Vehicle updated successfully!', _kSuccess);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        _showSnackBar('Failed to update vehicle: $e', _kError);
      }
    }
  }
}
