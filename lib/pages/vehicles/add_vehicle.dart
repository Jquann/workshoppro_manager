import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

class AddVehicle extends StatefulWidget {
  final String? customerId;
  final String? customerName;

  const AddVehicle({
    super.key,
    this.customerId,
    this.customerName,
  });

  @override
  State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> with TickerProviderStateMixin {
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
  final _customerController = TextEditingController();
  final _db = FirestoreService();
  String? selectedCustomerId;
  String? selectedCustomerName;
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _showCustomerSuggestions = false;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      selectedCustomerId = widget.customerId;
      selectedCustomerName = widget.customerName;
      _customerController.text = widget.customerName ?? '';
    }

    // Load customers data
    _loadCustomers();

    // Initialize animations
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

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  Future<void> _loadCustomers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('isDeleted', isEqualTo: false)
          .get();
      
      setState(() {
        _allCustomers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _filteredCustomers = _allCustomers;
      });
    } catch (e) {
      print('Error loading customers: $e');
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
        _showCustomerSuggestions = false;
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          final name = (customer['customerName'] ?? '').toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
        _showCustomerSuggestions = true;
      }
    });
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      selectedCustomerId = customer['id'];
      selectedCustomerName = customer['customerName'];
      _customerController.text = customer['customerName'] ?? '';
      _showCustomerSuggestions = false;
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _model.dispose();
    _make.dispose();
    _year.dispose();
    _carPlate.dispose();
    _customerController.dispose();
    _desc.dispose();
    super.dispose();
  }

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
                'Add Vehicle',
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

          // Content
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
                        if (widget.customerId == null) _buildCustomerCard(),
                        if (widget.customerId == null) const SizedBox(height: 24),
                        _buildVehicleDetailsCard(),
                        const SizedBox(height: 12),
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

  Widget _buildCustomerCard() {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Customer Information',
      child: _buildFormField(
        label: 'Customer',
        child: Column(
          children: [
            TextFormField(
              controller: _customerController,
              decoration: _input('Type customer name...', icon: Icons.people_rounded),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a customer';
                }
                if (selectedCustomerId == null) {
                  return 'Please select a customer from the suggestions';
                }
                return null;
              },
              onChanged: _filterCustomers,
              onTap: () {
                if (_customerController.text.isNotEmpty) {
                  _filterCustomers(_customerController.text);
                }
              },
            ),
            if (_showCustomerSuggestions && _filteredCustomers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: _kDivider),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.person, color: _kPrimary, size: 20),
                      title: Text(
                        customer['customerName'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: customer['phoneNumber'] != null
                          ? Text(
                              customer['phoneNumber'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _kGrey,
                              ),
                            )
                          : null,
                      onTap: () => _selectCustomer(customer),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                helperText: 'Year must be between 1980 and 2025',
                helperStyle: TextStyle(
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
              decoration: _input('Enter Car Plate Number', icon: Icons.qr_code_rounded),
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
          'Save Vehicle',
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
      onPressed: _resetForm,
      icon: const Icon(Icons.restart_alt_rounded),
      label: const Text('Reset'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kDarkText,
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: _kDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> _resetForm() async {
    FocusScope.of(context).unfocus();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.restart_alt_rounded, color: _kPrimary),
            SizedBox(width: 8),
            Text('Reset form'),
          ],
        ),
        content: const Text('Clear all fields and selections?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {

      _make.clear();
      _model.clear();
      _year.clear();
      _carPlate.clear();
      _desc.clear();
      _customerController.clear();

      if (widget.customerId == null) {
        selectedCustomerId = null;
        selectedCustomerName = null;
        _showCustomerSuggestions = false;
        _filteredCustomers = _allCustomers;
      }
    });

    _showSnackBar('Form cleared', _kSuccess);
  }

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

  // Validate that the customer is not deleted
  Future<bool> _validateCustomerNotDeleted(String customerId) async {
    try {
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();
      
      if (!customerDoc.exists) {
        return false; // Customer doesn't exist
      }
      
      Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
      return customerData['isDeleted'] != true; // Return false if deleted
    } catch (e) {
      return false; // In case of error, assume invalid
    }
  }

  Future<void> _onSave() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (widget.customerId == null && selectedCustomerId == null) {
      _showSnackBar('Please select a customer', _kError);
      return;
    }

    // Validate that selected customer is not deleted
    String customerIdToCheck = widget.customerId ?? selectedCustomerId ?? '';
    if (customerIdToCheck.isEmpty) {
      _showSnackBar('Customer ID is missing', _kError);
      return;
    }
    bool isCustomerValid = await _validateCustomerNotDeleted(customerIdToCheck);
    if (!isCustomerValid) {
      _showSnackBar('Selected customer has been deleted. Please choose another customer.', _kError);
      return;
    }

    // Show loading
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
              const Text('Saving vehicle...'),
            ],
          ),
        ),
      ),
    );

    try {
      final vehicleId = await _db.addVehicle(
        VehicleModel(
          id: '',
          customerName: widget.customerName ?? selectedCustomerName ?? 'Unknown Customer',
          make: _make.text.trim(),
          model: _model.text.trim(),
          year: int.parse(_year.text.trim()),
          carPlate: _carPlate.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          status: 'active',
        ),
        customerId: widget.customerId ?? selectedCustomerId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, vehicleId); // Close add vehicle page
        _showSnackBar('Vehicle added successfully!', _kSuccess);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Failed to save vehicle: $e', _kError);
      }
    }
  }
}