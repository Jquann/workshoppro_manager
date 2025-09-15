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
      Map<String, dynamic> customerData = {
        'customerName': _customerNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'emailAddress': _emailController.text.trim(),
        'vehicleIds': [],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.documentId != null) {
        // Edit
        await _firestore.collection('customers').doc(widget.documentId).update(customerData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Customer updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add
        customerData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('customers').add(customerData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Customer added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    widget.customer != null ? 'Edit Customer' : 'Add New Customer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header inside white container
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            widget.customer != null ? 'Edit Customer' : 'Add New Customer',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 20),

                              // Customer Name
                              _buildInputField(
                                label: 'Customer Name :',
                                controller: _customerNameController,
                                hintText: 'Enter Customer Name',
                                isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Phone Number
                              _buildInputField(
                                label: 'Phone Number :',
                                controller: _phoneNumberController,
                                hintText: 'Enter Phone Number',
                                isRequired: true,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'This field is required';
                                  }
                                  if (value.trim().length < 8) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Email Address
                              _buildInputField(
                                label: 'Email Address :',
                                controller: _emailController,
                                hintText: 'Enter Email Address',
                                isRequired: true,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'This field is required';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 40),

                              // Add/Update Customer Button
                              Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitCustomerToFirestore,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoading ? Colors.grey[300] : Colors.blue[50],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              widget.customer != null ? 'Updating Customer...' : 'Adding Customer...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          widget.customer != null ? 'Update Customer in Firestore' : 'Add Customer to Firestore',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ?? (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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