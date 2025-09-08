import 'package:flutter/material.dart';

class AddCustomerPage extends StatefulWidget {
  @override
  _AddCustomerPageState createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vinController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add Customer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: 'Customer Name',
                      placeholder: 'Enter customer name',
                      controller: _customerNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Phone Number',
                      placeholder: 'Enter phone number',
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Email Address',
                      placeholder: 'Enter email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Vehicle Make',
                      placeholder: 'Enter vehicle make',
                      controller: _vehicleMakeController,
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Vehicle Model',
                      placeholder: 'Enter vehicle model',
                      controller: _vehicleModelController,
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Vehicle Year',
                      placeholder: 'Enter vehicle year',
                      controller: _vehicleYearController,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),

                    _buildInputField(
                      label: 'Vehicle Identification Number (VIN)',
                      placeholder: 'Enter VIN',
                      controller: _vinController,
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: EdgeInsets.all(16),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
    required String placeholder,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFE8EDF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Color(0xFF8E98A8),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      // Create customer object with form data
      Map<String, String> customerData = {
        'customerName': _customerNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'emailAddress': _emailController.text,
        'vehicleMake': _vehicleMakeController.text,
        'vehicleModel': _vehicleModelController.text,
        'vehicleYear': _vehicleYearController.text,
        'vin': _vinController.text,
      };

      // Here you would typically save to database or API
      print('Customer Data: $customerData');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );

      // Close the page and return the customer data
      Navigator.pop(context, customerData);
    }
  }
}