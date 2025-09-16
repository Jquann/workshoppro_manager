import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';

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

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if email already exists in Firestore
  Future<bool> _checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('customers')
          .where('emailAddress', isEqualTo: email.trim())
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

  // Check if phone number already exists in Firestore
  Future<bool> _checkPhoneExists(String phoneNumber) async {
    try {
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      final query = await _firestore
          .collection('customers')
          .where('phoneNumber', isEqualTo: formattedPhone)
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
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _customerNameController.text = widget.customer!.customerName;
      _phoneNumberController.text = widget.customer!.phoneNumber;
      _emailController.text = widget.customer!.emailAddress;
    }
  }

  Future<void> _submitCustomerToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check for duplicate email
      bool emailExists = await _checkEmailExists(_emailController.text);
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ This email address is already registered!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Check for duplicate phone number
      bool phoneExists = await _checkPhoneExists(_phoneNumberController.text);
      if (phoneExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ This phone number is already registered!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      Map<String, dynamic> customerData = {
        'customerName': _customerNameController.text.trim(),
        'phoneNumber': _formatPhoneNumber(_phoneNumberController.text),
        'emailAddress': _emailController.text.trim(),
        'vehicleIds': [],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.documentId != null) {
        // Edit
        await _firestore.collection('customers').doc(widget.documentId).update(customerData);
      } else {
        // Add
        customerData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('customers').add(customerData);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Add Customer',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),

              _buildInputField(
                label: 'Customer Name',
                controller: _customerNameController,
                hintText: 'Enter customer name',
              ),
              SizedBox(height: 16),

              _buildInputField(
                label: 'Phone Number',
                controller: _phoneNumberController,
                hintText: 'Enter phone number (e.g., 0123456789)',
                keyboardType: TextInputType.phone,
                validator: (value) {
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
                },
              ),
              SizedBox(height: 16),

              _buildInputField(
                label: 'Email Address',
                controller: _emailController,
                hintText: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCustomerToFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.customer != null ? 'Update Customer' : 'Add Customer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}