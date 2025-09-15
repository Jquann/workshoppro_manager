import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_model.dart';
import 'package:workshoppro_manager/firestore_service.dart';

class EditVehicle extends StatefulWidget {
  final VehicleModel vehicle;
  const EditVehicle({super.key, required this.vehicle});
  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> {
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kFieldBg = Color(0xFFEFF3F7);

  @override
  void initState() {
    super.initState();
    selectedCustomerName = widget.vehicle.customerName;
    // Initialize customer data
    _initializeCustomerData();
  }

  void _initializeCustomerData() async {
    // Get the customer ID based on the customer name
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('customerName', isEqualTo: widget.vehicle.customerName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        selectedCustomerId = querySnapshot.docs.first.id;
      });
    }
  }

  final _form = GlobalKey<FormState>();
  late final TextEditingController _model =
  TextEditingController(text: widget.vehicle.model);
  late final TextEditingController _make =
  TextEditingController(text: widget.vehicle.make);
  late final TextEditingController _year =
  TextEditingController(text: widget.vehicle.year.toString());
  late final TextEditingController _vin =
  TextEditingController(text: widget.vehicle.vin);
  late final TextEditingController _desc =
  TextEditingController(text: widget.vehicle.description ?? '');
  String? selectedCustomerId;
  String? selectedCustomerName;
  final _db = FirestoreService();

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
        borderSide: const BorderSide(color: _kDivider)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDivider)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.2)),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Vehicle',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20),
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
            padding: EdgeInsets.fromLTRB(20, 16, 20,
                MediaQuery.of(context).viewPadding.bottom + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Vehicle Model'),
                TextFormField(
                    controller: _model,
                    decoration:
                    _input('Please enter the vehicle model'),
                    validator: _req),
                const SizedBox(height: 16),

                _label('Vehicle Make'),
                TextFormField(
                    controller: _make,
                    decoration:
                    _input('Please enter the vehicle make'),
                    validator: _req),
                const SizedBox(height: 16),

                _label('Vehicle Year'),
                TextFormField(
                  controller: _year,
                  decoration: _input('Please enter the vehicle year'),
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

                _label('Description (Optional)'),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: _input('Enter description'),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _primaryBtn,
                    onPressed: () async {
                      if (!_form.currentState!.validate()) return;
                      await _db.updateVehicle(VehicleModel(
                        id: widget.vehicle.id,
                        customerName: selectedCustomerName ?? widget.vehicle.customerName,
                        make: _make.text.trim(),
                        model: _model.text.trim(),
                        year: int.parse(_year.text.trim()),
                        vin: _vin.text.trim(),
                        description: _desc.text.trim().isEmpty
                            ? null
                            : _desc.text.trim(),
                      ));
                      if (mounted) Navigator.pop(context);
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
    child:
    Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _yearV(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 1886 || n > DateTime.now().year + 1) return 'Invalid year';
    return null;
  }
}
