// Updated enhanced_procurement_dialog.dart with Gmail SMTP email functionality

import 'package:flutter/material.dart';
import '../../models/part.dart';
import 'procurement_service.dart';
import 'procurement_tracking_screen.dart';
import 'gmail_email_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_data_manager.dart';
import 'supplier_price.dart';

class EnhancedProcurementDialog extends StatefulWidget {
  final Part part;

  const EnhancedProcurementDialog({Key? key, required this.part}) : super(key: key);

  @override
  _EnhancedProcurementDialogState createState() => _EnhancedProcurementDialogState();
}

class _EnhancedProcurementDialogState extends State<EnhancedProcurementDialog> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedPriority = 'Normal';
  String _selectedSupplier = '';
  DateTime? _requiredByDate;
  bool _isSubmitting = false;
  final InventoryDataManager _inventoryManager = InventoryDataManager(FirebaseFirestore.instance);
  final SupplierPricingManager _supplierPricingManager = SupplierPricingManager(FirebaseFirestore.instance);
  bool _isSupplierActionLoading = false;
  bool _isEnhancedSupplierActionLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.part.supplier.isNotEmpty
        ? widget.part.supplier
        : GmailEmailService.getSupplierList().first;
    _qtyController.text = GmailEmailService.calculateRecommendedQuantity(widget.part).toString();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double horizontalPadding = constraints.maxWidth < 500 ? 12 : 32;
                  double headerFontSize = constraints.maxWidth < 500 ? 16 : 18;
                  double labelFontSize = constraints.maxWidth < 500 ? 14 : 16;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPartInfoCard(),
                        SizedBox(height: 20),
                        _buildRequestDetails(),
                        SizedBox(height: 20),
                        _buildGmailEmailPreview(),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildGmailActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: Colors.orange[700], size: 24),
          SizedBox(width: 12),
          Text(
            'Send Email to Supplier',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPartInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Part Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoRow(Icons.build, widget.part.name, fontWeight: FontWeight.w600),
          SizedBox(height: 8),
          _buildInfoRow(Icons.qr_code, 'ID: ${widget.part.id}'),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Current Stock: ${widget.part.quantity}'),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.part.isLowStock ? Colors.red[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.part.isLowStock ? 'LOW STOCK' : 'IN STOCK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.part.isLowStock ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {FontWeight? fontWeight}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontWeight: fontWeight)),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),

        // Quantity Input
        TextFormField(
          controller: _qtyController,
          keyboardType: TextInputType.number,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            labelText: 'Quantity Needed *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.format_list_numbered),
            helperText: 'Recommended: ${GmailEmailService.calculateRecommendedQuantity(widget.part)}',
          ),
        ),
        SizedBox(height: 16),

        // Priority Selection
        Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Urgent', 'Normal', 'When Available'].map((priority) {
            return ChoiceChip(
              label: Text(priority),
              selected: _selectedPriority == priority,
              onSelected: _isSubmitting ? null : (selected) {
                if (selected) {
                  setState(() => _selectedPriority = priority);
                }
              },
              selectedColor: GmailEmailService.getPriorityColor(priority),
              labelStyle: TextStyle(
                color: _selectedPriority == priority ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),

        // Supplier Selection
        DropdownButtonFormField<String>(
          value: _selectedSupplier,
          decoration: InputDecoration(
            labelText: 'Supplier',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.business),
          ),
          items: GmailEmailService.getSupplierList().map((supplier) {
            return DropdownMenuItem(value: supplier, child: Text(supplier));
          }).toList(),
          onChanged: _isSubmitting ? null : (value) => setState(() => _selectedSupplier = value!),
        ),
        SizedBox(height: 16),

        // Required By Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.calendar_today),
          title: Text('Required By Date'),
          subtitle: Text(_requiredByDate != null
              ? '${_requiredByDate!.day}/${_requiredByDate!.month}/${_requiredByDate!.year}'
              : 'Select date (optional)'),
          onTap: _isSubmitting ? null : _selectDate,
        ),
        SizedBox(height: 16),

        // Special Notes
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            labelText: 'Special Notes / Instructions',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.note_alt),
            hintText: 'Any specific requirements, delivery instructions, etc.',
          ),
        ),
      ],
    );
  }

  Widget _buildGmailEmailPreview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                '📧 Gmail SMTP Email Will Be Sent To:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Email: ${GmailEmailService.getSupplierEmail(_selectedSupplier)}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Subject: [${_selectedPriority.toUpperCase()}] Procurement Request - ${widget.part.name}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Direct Gmail SMTP - No third-party services!',
                  style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
                Text(
                  '📧 Professional HTML email with beautiful design',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
                Text(
                  '🔒 Uses your Gmail account - Completely secure',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGmailActionButtons() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitGmailEmailRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Sending...', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Send via Gmail', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        SizedBox(height: 12),

        if (_isSupplierActionLoading || _isEnhancedSupplierActionLoading)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _requiredByDate = date);
    }
  }

  Future<void> _submitGmailEmailRequest() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit request with FREE Gmail SMTP - NO third-party services needed!
      final requestId = await GmailEmailService.submitProcurementRequestWithGmail(
        part: widget.part,
        quantity: qty,
        priority: _selectedPriority,
        supplier: _selectedSupplier,
        requiredBy: _requiredByDate,
        notes: _notesController.text.trim(),
      );

      Navigator.pop(context);

      // Show success with tracking option
      _showGmailEmailSentSuccess(requestId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showGmailEmailSentSuccess(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 24),
            SizedBox(width: 8),
            Text('Gmail Email Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your procurement request has been sent via Gmail SMTP for FREE!'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ No third-party services needed!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Text('📧 Direct Gmail SMTP - 100% Free', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  SizedBox(height: 4),
                  Text('Request ID: $requestId', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Sent to: ${GmailEmailService.getSupplierEmail(_selectedSupplier)}'),
                  SizedBox(height: 4),
                  Text('Supplier can reply via email to confirm/reject.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProcurementTrackingScreen(),
                ),
              );
            },
            child: Text('Track Requests'),
          ),
        ],
      ),
    );
  }
}