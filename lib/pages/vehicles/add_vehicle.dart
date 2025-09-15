import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'vehicle_model.dart';
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

class _AddVehicleState extends State<AddVehicle> {
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kFieldBg = Color(0xFFEFF3F7);

  final _form = GlobalKey<FormState>();
  final _model = TextEditingController();
  final _make = TextEditingController();
  final _year = TextEditingController();
  final _vin = TextEditingController();
  final _desc = TextEditingController();
  final _db = FirestoreService();
  String? selectedCustomerId;
  String? selectedCustomerName;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      selectedCustomerId = widget.customerId;
      selectedCustomerName = widget.customerName;
    }
  }

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 15, color: _kGrey),
    isDense: true,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: _kFieldBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBlue, width: 1.2),
    ),
  );

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
    backgroundColor: _kBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(56),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  );

  @override
  void dispose() {
    _model.dispose();
    _make.dispose();
    _year.dispose();
    _vin.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Vehicle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.2,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Vehicle Model'),
                TextFormField(
                    controller: _model,
                    decoration: _input('Please enter the vehicle model'),
                    validator: _req),
                const SizedBox(height: 16),

                _label('Vehicle Make'),
                TextFormField(
                    controller: _make,
                    decoration: _input('Please enter the vehicle make'),
                    validator: _req),
                const SizedBox(height: 16),

                _label('Vehicle Year'),
                TextFormField(
                  controller: _year,
                  decoration: _input('Please enter the vehicle year').copyWith(
                    helperText: 'Year Must be between 1980 and 2025',
                    helperStyle: const TextStyle(
                        fontSize: 15,
                        color: _kBlue),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _yearV,
                ),
                const SizedBox(height: 16),

                _label('Vehicle Identification Number (VIN)'),
                TextFormField(
                    controller: _vin,
                    decoration: _input('Please enter the VIN'),
                    validator: _req),
                const SizedBox(height: 16),

                if (widget.customerId == null) ...[
                  _label('Customer'),
                  StreamBuilder<QuerySnapshot>(
                    stream: _db.customersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading customers');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final customers = snapshot.data?.docs ?? [];
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: _kFieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kDivider),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCustomerId,
                          decoration: InputDecoration(
                            hintText: 'Select customer',
                            hintStyle: TextStyle(fontSize: 15, color: _kGrey),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            border: InputBorder.none,
                          ),
                          items: customers.map((customer) {
                            final data = customer.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: customer.id,
                              child: Text(data['customerName'] ?? 'Unknown Customer'),
                            );
                          }).toList(),
                          validator: (value) => value == null ? 'Please select a customer' : null,
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
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                _label('Description (Optional)'),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: _input('Enter description'),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _primaryBtn,
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;
                      final vehicleId = await _db.addVehicle(
                        VehicleModel(
                          id: '',
                          customerName: widget.customerName ?? selectedCustomerName!,
                          make: _make.text.trim(),
                          model: _model.text.trim(),
                          year: int.parse(_year.text.trim()),
                          vin: _vin.text.trim(),
                          description: _desc.text.trim().isEmpty
                              ? null
                              : _desc.text.trim(),
                          status: 'active',
                        ),
                        customerId: widget.customerId ?? selectedCustomerId,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vehicle added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      if (mounted) Navigator.pop(context, vehicleId);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style:
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _yearV(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 1980 || n > DateTime.now().year + 1) {
      return 'Invalid year';
    }
    return null;
  }
}
