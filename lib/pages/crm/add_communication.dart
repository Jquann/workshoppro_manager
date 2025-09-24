import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/communication_model.dart';
import '../../services/communication_service.dart';

class AddCommunicationPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final CommunicationModel? communication; // For editing existing communication

  const AddCommunicationPage({
    Key? key,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.communication,
  }) : super(key: key);

  @override
  _AddCommunicationPageState createState() => _AddCommunicationPageState();
}

class _AddCommunicationPageState extends State<AddCommunicationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CommunicationService _communicationService = CommunicationService();
  
  // Form controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Form state
  CommunicationType _selectedType = CommunicationType.note;
  CommunicationStatus _selectedStatus = CommunicationStatus.completed;
  DateTime? _scheduledDate;
  bool _isLoading = false;
  
  // UI Colors
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kPrimary = Color(0xFF007AFF);
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Pre-fill phone and email from customer data
    _phoneController.text = widget.customerPhone ?? '';
    _emailController.text = widget.customerEmail ?? '';
    
    // If editing existing communication, populate fields
    if (widget.communication != null) {
      final comm = widget.communication!;
      _subjectController.text = comm.subject;
      _descriptionController.text = comm.description;
      _selectedType = comm.type;
      _selectedStatus = comm.status;
      _scheduledDate = comm.scheduledDate;
      _phoneController.text = comm.phoneNumber ?? widget.customerPhone ?? '';
      _emailController.text = comm.emailAddress ?? widget.customerEmail ?? '';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess ? Icons.check_circle : Icons.error,
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

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveCommunication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final communication = CommunicationModel(
        id: widget.communication?.id ?? '',
        customerId: widget.customerId,
        customerName: widget.customerName,
        type: _selectedType,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        createdAt: widget.communication?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        scheduledDate: _scheduledDate,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        emailAddress: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        createdBy: 'Current User', // You can get this from auth service
      );

      if (widget.communication != null) {
        // Update existing communication
        await _communicationService.updateCommunication(
          widget.communication!.id,
          communication.toMap(),
        );
        _showSnackBar('Communication updated successfully', _kSuccess);
      } else {
        // Create new communication
        await _communicationService.createCommunication(communication);
        _showSnackBar('Communication saved successfully', _kSuccess);
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error saving communication: $e', _kError);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CommunicationType.values.map((type) {
                final isSelected = _selectedType == type;
                return InkWell(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _kPrimary : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      type.name == 'phone' ? 'Phone Call' :
                      type.name == 'email' ? 'Email' :
                      type.name == 'sms' ? 'SMS' :
                      type.name == 'meeting' ? 'Meeting' :
                      type.name == 'note' ? 'Note' :
                      type.name == 'followUp' ? 'Follow Up' :
                      type.name == 'complaint' ? 'Complaint' :
                      type.name == 'inquiry' ? 'Inquiry' : 'Other',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CommunicationStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                return InkWell(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _kPrimary : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      status.name == 'pending' ? 'Pending' :
                      status.name == 'completed' ? 'Completed' :
                      status.name == 'cancelled' ? 'Cancelled' : 'Follow Up Required',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.communication != null;
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Communication' : 'New Communication',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCommunication,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(Icons.person, color: _kPrimary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customerName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (widget.customerPhone != null || widget.customerEmail != null)
                              Text(
                                widget.customerPhone ?? widget.customerEmail ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Type Selector
              _buildTypeSelector(),
              
              const SizedBox(height: 20),
              
              // Subject Field
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'Enter communication subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _kPrimary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Subject is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Description Field
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Enter detailed description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _kPrimary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status Selector
              _buildStatusSelector(),
              
              const SizedBox(height: 20),
              
              // Contact Information (if relevant to type)
              if (_selectedType == CommunicationType.phone || _selectedType == CommunicationType.sms)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        prefixIcon: Icon(Icons.phone, color: _kPrimary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _kPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (_selectedType == CommunicationType.email)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter email address',
                        prefixIcon: Icon(Icons.email, color: _kPrimary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _kPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Scheduled Date (for follow-ups or meetings)
              if (_selectedStatus == CommunicationStatus.followUp || _selectedType == CommunicationType.meeting)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: _selectDateTime,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: _kPrimary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scheduled Date & Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _scheduledDate != null
                                      ? DateFormat('MMM dd, yyyy \'at\' HH:mm').format(_scheduledDate!)
                                      : 'Tap to select date and time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _scheduledDate != null ? Colors.black54 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}