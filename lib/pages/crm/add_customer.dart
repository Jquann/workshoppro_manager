import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';

class MalaysianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    
    // Remove all non-digit characters
    String digits = newText.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present and has digits
    if (digits.isNotEmpty && !digits.startsWith('0')) {
      digits = '0$digits';
    }
    
    // Limit to 11 digits maximum
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    
    String formatted = '';
    
    // Format based on length
    if (digits.length >= 3) {
      formatted = digits.substring(0, 3);
      
      if (digits.length > 3) {
        if (digits.length <= 6) {
          formatted += '-${digits.substring(3)}';
        } else if (digits.length <= 10) {
          formatted += '-${digits.substring(3, 6)} ${digits.substring(6)}';
        } else {
          // 11 digits: 012-3456 7890
          formatted += '-${digits.substring(3, 7)} ${digits.substring(7)}';
        }
      }
    } else {
      formatted = digits;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class Customer extends CustomerModel {
  Customer({
    required String id,
    required String customerName,
    required String phoneNumber,
    required String emailAddress,
    required List<String> vehicleIds,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          customerName: customerName,
          phoneNumber: phoneNumber,
          emailAddress: emailAddress,
          vehicleIds: vehicleIds,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      emailAddress: data['emailAddress'] ?? '',
      vehicleIds: List<String>.from(data['vehicleIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AddCustomerPage extends StatefulWidget {
  final Customer? customer;
  final String? documentId;

  const AddCustomerPage({Key? key, this.customer, this.documentId}) : super(key: key);

  @override
  _AddCustomerPageState createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> with TickerProviderStateMixin {
  // Enhanced color scheme - consistent with add_vehicle.dart
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSecondary = Color(0xFF5856D6);
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kDarkText = Color(0xFF1C1C1E);
  static const _kCardShadow = Color(0x1A000000);

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _customerNameController.text = widget.customer!.customerName;
      // Format phone number when loading existing customer
      _phoneNumberController.text = _formatPhoneNumber(widget.customer!.phoneNumber);
      _emailController.text = widget.customer!.emailAddress;
    }

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

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Enhanced UI tokens - consistent with add_vehicle.dart
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

  // Check if email already exists in Firestore (only among non-deleted records)
  Future<bool> _checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('customers')
          .where('emailAddress', isEqualTo: email.trim())
          .where('isDeleted', isEqualTo: false)
          .get();
      
      // If editing, exclude the current document
      if (widget.documentId != null) {
        return query.docs.any((doc) => doc.id != widget.documentId);
      }
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if phone number already exists in Firestore (only among non-deleted records)
  Future<bool> _checkPhoneExists(String phoneNumber) async {
    try {
      String cleanPhone = phoneNumber.trim().replaceAll(RegExp(r'[^\d]'), ''); // Store only digits
      final query = await _firestore
          .collection('customers')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      // If editing, exclude the current document
      if (widget.documentId != null) {
        return query.docs.any((doc) => doc.id != widget.documentId);
      }
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Format phone number to Malaysian format starting with 0
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digits = phoneNumber.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    
    // Format based on length
    if (digits.length == 10) {
      // Format: 012-345 6789
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 11) {
      // Format: 012-3456 7890
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    
    return phoneNumber; // Return original if format doesn't match
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar - consistent with add_vehicle.dart
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
                widget.customer != null ? 'Edit Customer' : 'Add Customer',
                style: const TextStyle(
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
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomerDetailsCard(),
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

  Widget _buildCustomerDetailsCard() {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Customer Information',
      child: Column(
        children: [
          _buildFormField(
            label: 'Customer Name',
            child: TextFormField(
              controller: _customerNameController,
              decoration: _input('Enter customer name', icon: Icons.person_outline_rounded),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Phone Number',
            child: TextFormField(
              controller: _phoneNumberController,
              decoration: _input('Enter phone number', icon: Icons.phone_rounded).copyWith(
                helperText: 'Format: 0xx-xxx xxxx (Malaysian numbers only)',
                helperStyle: TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: _phoneValidator,
              keyboardType: TextInputType.phone,
              inputFormatters: [MalaysianPhoneFormatter()],
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Email Address',
            child: TextFormField(
              controller: _emailController,
              decoration: _input('Enter email address', icon: Icons.email_rounded),
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
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
        onPressed: _isLoading ? null : _submitCustomerToFirestore,
        icon: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, color: Colors.white),
        label: Text(
          widget.customer != null ? 'Update Customer' : 'Save Customer',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    String phoneNumber = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present for validation
    if (!phoneNumber.startsWith('0')) {
      phoneNumber = '0$phoneNumber';
    }
    
    // Check if it's a valid Malaysian phone number (10-11 digits with leading 0)
    if (phoneNumber.length < 10 || phoneNumber.length > 11) {
      return 'Please enter a valid Malaysian phone number';
    }
    
    // Check if it starts with valid Malaysian mobile prefixes (01x)
    if (!phoneNumber.startsWith('01')) {
      return 'Please enter a valid Malaysian mobile number starting with 01';
    }
    
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
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

  Future<void> _submitCustomerToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check for duplicate email
      bool emailExists = await _checkEmailExists(_emailController.text);
      if (emailExists) {
        _showSnackBar('This email address is already registered!', _kError);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Check for duplicate phone number
      bool phoneExists = await _checkPhoneExists(_phoneNumberController.text);
      if (phoneExists) {
        _showSnackBar('This phone number is already registered!', _kError);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      String newCustomerName = _customerNameController.text.trim();
      
      Map<String, dynamic> customerData = {
        'customerName': newCustomerName,
        'phoneNumber': _phoneNumberController.text.trim().replaceAll(RegExp(r'[^\d]'), ''), // Store only digits
        'emailAddress': _emailController.text.trim(),
        'isDeleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only set vehicleIds for new customers, preserve existing for updates
      if (widget.documentId == null) {
        customerData['vehicleIds'] = [];
      }
      
      if (widget.documentId != null) {
        // Edit - Check if customer name has changed
        String? oldCustomerName = widget.customer?.customerName;
        if (oldCustomerName != null && oldCustomerName != newCustomerName) {
          // Update customer document first
          await _firestore.collection('customers').doc(widget.documentId).update(customerData);
          
          // Update all vehicles that belong to this customer
          await _updateVehicleCustomerNames(oldCustomerName, newCustomerName);
          
          _showSnackBar('Customer and related vehicles updated successfully!', _kSuccess);
        } else {
          // Just update customer document (no name change)
          await _firestore.collection('customers').doc(widget.documentId).update(customerData);
          _showSnackBar('Customer updated successfully!', _kSuccess);
        }
      } else {
        // Add
        customerData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('customers').add(customerData);
        _showSnackBar('Customer added successfully!', _kSuccess);
      }
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Failed to save customer: $e', _kError);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update all vehicle records that have the old customer name
  Future<void> _updateVehicleCustomerNames(String oldCustomerName, String newCustomerName) async {
    try {
      // Find all vehicles with the old customer name
      QuerySnapshot vehicleQuery = await _firestore
          .collection('vehicles')
          .where('customerName', isEqualTo: oldCustomerName)
          .get();
      
      // Update each vehicle document with the new customer name
      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot vehicleDoc in vehicleQuery.docs) {
        batch.update(vehicleDoc.reference, {
          'customerName': newCustomerName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Commit the batch update
      await batch.commit();
      
      print('Updated ${vehicleQuery.docs.length} vehicle(s) with new customer name: $newCustomerName');
    } catch (e) {
      print('Error updating vehicle customer names: $e');
      // Don't throw here - we want the customer update to succeed even if vehicle update fails
    }
  }
}