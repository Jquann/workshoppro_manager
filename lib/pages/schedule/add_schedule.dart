import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_model.dart';
import '../vehicles/add_vehicle.dart';

class AddSchedulePage extends StatefulWidget {
  final ScheduleModel? schedule;

  const AddSchedulePage({Key? key, this.schedule}) : super(key: key);

  @override
  _AddSchedulePageState createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> with TickerProviderStateMixin {
  // Enhanced color scheme - consistent with other add pages
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerController = TextEditingController();
  final _mechanicController = TextEditingController();

  DateTime _selectedDate = DateTime.now(); // Allow today's date
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  String _selectedServiceType = 'Oil Change';
  String? _selectedPartsCategory;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedVehicleId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _showCustomerSuggestions = false;

  // Service types matching the template
  final List<String> _serviceTypes = [
    'Oil Change',
    'Tire Rotation',
    'Brake Inspection',
    'Lunch Break',
    'Engine Tune-Up',
    'Transmission Service',
  ];

  List<String> _partsCategories = [];
  bool _partsCatsLoading = true;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.schedule != null) {
      _populateFields();
    }

    // Load customers data
    _loadCustomers();
    _loadPartsCategories();

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

  void _populateFields() {
    final schedule = widget.schedule!;
    _titleController.text = schedule.title;
    _descriptionController.text = schedule.description;
    _selectedDate = schedule.startTime;
    _startTime = TimeOfDay.fromDateTime(schedule.startTime);
    _endTime = TimeOfDay.fromDateTime(schedule.endTime);
    _selectedServiceType = schedule.serviceType;
    _selectedPartsCategory = schedule.partsCategory;
    _selectedCustomerId = schedule.customerId;
    _selectedCustomerName = schedule.customerName;
    _selectedVehicleId = schedule.vehicleId;

    // Populate customer name and mechanic name in text fields
    if (schedule.customerName != null) {
      _customerController.text = schedule.customerName!;
    }
    if (schedule.mechanicName != null) {
      _mechanicController.text = schedule.mechanicName!;
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customerController.dispose();
    _mechanicController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final snapshot = await _firestore
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
      _selectedCustomerId = customer['id'];
      _selectedCustomerName = customer['customerName'];
      _customerController.text = customer['customerName'] ?? '';
      _showCustomerSuggestions = false;
      _selectedVehicleId = null; // Clear vehicle selection
    });
  }

  // Enhanced UI tokens - consistent with other add pages
  InputDecoration _input(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 14, color: _kGrey.withValues(alpha: 0.8)),
    prefixIcon: icon != null
        ? Container(
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: 20, color: _kGrey),
    )
        : null,
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Enhanced App Bar
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
                  widget.schedule != null ? 'Edit Schedule' : 'Add Schedule',
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
                          _buildBasicInfoCard(),
                          const SizedBox(height: 24),
                          _buildDateTimeCard(),
                          const SizedBox(height: 24),
                          _buildCustomerCard(),
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
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCard(
      icon: Icons.event_note,
      title: 'Schedule Information',
      child: Column(
        children: [
          _buildFormField(
            label: 'Title',
            child: TextFormField(
              controller: _titleController,
              decoration: _input('Enter schedule title', icon: Icons.title),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Service Type',
            child: DropdownButtonFormField<String>(
              decoration: _input('Select service type', icon: Icons.build),
              value: _selectedServiceType,
              items: _serviceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value!;
                });
              },
              validator: (value) => value == null ? 'Please select a service type' : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Parts Category (Optional)',
            child: _partsCatsLoading
                ? TextFormField(
              enabled: false,
              decoration: _input('Loading categories...', icon: Icons.category),
            )
                : DropdownButtonFormField<String>(
              decoration: _input('Select parts category', icon: Icons.category),
              value: (_selectedPartsCategory != null &&
                  _partsCategories.contains(_selectedPartsCategory))
                  ? _selectedPartsCategory
                  : null, // avoid assertion if preselected value isn't in list
              hint: const Text('Select category'),
              isExpanded: true,
              items: (() {
                // If editing and the record has a category that no longer exists,
                // we still show it at the top to avoid breaking the value binding.
                final items = List<String>.from(_partsCategories);
                if (_selectedPartsCategory != null &&
                    !items.contains(_selectedPartsCategory)) {
                  items.insert(0, _selectedPartsCategory!);
                }
                return items
                    .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                    .toList();
              })(),
              onChanged: (value) {
                setState(() {
                  _selectedPartsCategory = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Mechanic Name',
            child: TextFormField(
              controller: _mechanicController,
              decoration: _input('Enter mechanic name', icon: Icons.engineering),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description',
            child: TextFormField(
              controller: _descriptionController,
              decoration: _input('Enter description'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return _buildCard(
      icon: Icons.schedule,
      title: 'Date & Time',
      child: Column(
        children: [
          _buildFormField(
            label: 'Date',
            child: InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _kGrey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: _kGrey),
                  ],
                ),
              ),
            ),
          ),
          // Date booking info (updated to allow today)
          if (widget.schedule == null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Emergency appointments can be scheduled for today',
                style: TextStyle(
                  fontSize: 13,
                  color: _kSuccess,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Start Time',
                  child: InkWell(
                    onTap: () => _selectTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: _kGrey, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  label: 'End Time',
                  child: InkWell(
                    onTap: () => _selectTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: _kGrey, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _endTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Working hours: 8:00 AM - 5:00 PM',
              style: TextStyle(
                fontSize: 13,
                color: _kGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _buildCard(
      icon: Icons.person,
      title: 'Customer & Vehicle Information',
      child: Column(
        children: [
          _buildFormField(
            label: 'Customer *',
            child: Column(
              children: [
                TextFormField(
                  controller: _customerController,
                  decoration: _input('Type customer name...', icon: Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a customer';
                    }
                    if (_selectedCustomerId == null) {
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
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Vehicle *',
            child: _selectedCustomerId == null
                ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDivider),
                color: _kLightGrey.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, color: _kGrey),
                  const SizedBox(width: 12),
                  Text(
                    'Please select a customer first',
                    style: TextStyle(color: _kGrey, fontSize: 13),
                  ),
                ],
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('vehicles')
                  .where('customerName', isEqualTo: _selectedCustomerName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const CircularProgressIndicator(color: _kPrimary),
                  );
                }

                final vehicles = snapshot.data?.docs ?? [];

                if (vehicles.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kDivider),
                      color: _kLightGrey.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No vehicles found for this customer',
                                style: TextStyle(color: _kGrey, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVehicle(
                                    customerId: _selectedCustomerId,
                                    customerName: _selectedCustomerName,
                                  ),
                                ),
                              );
                              // If a vehicle was added, it will automatically refresh via StreamBuilder
                            },
                            icon: Icon(Icons.add, size: 18),
                            label: const Text('Add Vehicle for Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: BorderSide(color: _kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  decoration: _input('Select vehicle', icon: Icons.directions_car),
                  value: _selectedVehicleId,
                  hint: const Text('Select vehicle'),
                  isExpanded: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a vehicle';
                    }
                    return null;
                  },
                  items: vehicles.map((vehicle) {
                    final data = vehicle.data() as Map<String, dynamic>;
                    final make = data['make'] ?? '';
                    final model = data['model'] ?? '';
                    final carPlate = data['carPlate'] ?? '';
                    return DropdownMenuItem<String>(
                      value: vehicle.id,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '$make $model ($carPlate)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                );
              },
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDarkText,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        onPressed: _isLoading ? null : _saveSchedule,
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
          widget.schedule != null ? 'Update Schedule' : 'Save Schedule',
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

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today, // Allow booking from today onwards
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      // Check if time is within business hours (8 AM - 5 PM)
      if (picked.hour < 8 || picked.hour >= 17) {
        _showSnackBar('Working hours are from 8:00 AM to 5:00 PM only', Colors.red);
        return;
      }

      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Auto-adjust end time if it's before start time or outside business hours
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute) ||
              _endTime.hour >= 17) {
            int nextHour = _startTime.hour + 1;
            if (nextHour >= 17) {
              nextHour = 16; // Cap at 4 PM so end time doesn't exceed 5 PM
            }
            _endTime = TimeOfDay(
              hour: nextHour,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
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

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate business hours (8 AM - 5 PM)
    if (_startTime.hour < 8 || _startTime.hour >= 17 || _endTime.hour < 8 || _endTime.hour >= 17) {
      _showSnackBar('Working hours are from 8:00 AM to 5:00 PM only', Colors.red);
      return;
    }

    // Validate date - allow booking from today onwards
    if (widget.schedule == null) { // Only check for new schedules, not when editing
      final today = DateTime.now();
      final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);

      if (selectedDateOnly.isBefore(todayOnly)) {
        _showSnackBar('Cannot schedule appointments for past dates', Colors.red);
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final scheduleData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'serviceType': _selectedServiceType,
        'customerId': _selectedCustomerId,
        'customerName': _selectedCustomerName,
        'vehicleId': _selectedVehicleId,
        'mechanicId': null, // Can be added later
        'mechanicName': _mechanicController.text.trim().isEmpty ? null : _mechanicController.text.trim(),
        'partsCategory': _selectedPartsCategory,
        'status': 'scheduled', // Always default to scheduled as per requirement
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.schedule != null) {
        // Update existing schedule
        await _firestore.collection('schedules').doc(widget.schedule!.id).update(scheduleData);
        _showSnackBar('Schedule updated successfully!', _kSuccess);
      } else {
        // Create new schedule
        scheduleData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('schedules').add(scheduleData);
        _showSnackBar('Schedule created successfully!', _kSuccess);
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Failed to save schedule: $e', _kError);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPartsCategories() async {
    try {
      final snap = await _firestore.collection('inventory_parts').get();
      final cats = snap.docs.map((d) => d.id).toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _partsCategories = cats;
        _partsCatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _partsCatsLoading = false);
      _showSnackBar('Failed to load parts categories: $e', _kError);
    }
  }

}