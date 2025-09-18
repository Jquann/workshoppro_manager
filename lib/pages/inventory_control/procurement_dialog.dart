// Enhanced Procurement Dialog with modern UI design matching edit_part_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/part.dart';
import 'procurement_tracking_screen.dart';
import 'gmail_email_service.dart';

class EnhancedProcurementDialog extends StatefulWidget {
  final Part part;

  const EnhancedProcurementDialog({Key? key, required this.part}) : super(key: key);

  @override
  State<EnhancedProcurementDialog> createState() => _EnhancedProcurementDialogState();
}

class _EnhancedProcurementDialogState extends State<EnhancedProcurementDialog> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPriority = 'Medium';
  Map<String, dynamic>? _selectedSupplier;
  DateTime? _requiredByDate;
  bool _isSubmitting = false;
  bool _isLoadingSuppliers = true;
  List<Map<String, dynamic>> _suppliers = [];
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _qtyController.text = widget.part.lowStockThreshold.toString();
    _qtyController.addListener(_updateTotalPrice);
    _fetchSuppliers();
  }

  void _updateTotalPrice() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = _selectedSupplier != null && _selectedSupplier!['price'] != null
        ? (_selectedSupplier!['price'] as num).toDouble()
        : 0.0;
    setState(() {
      _totalPrice = qty > 0 ? price * qty : 0.0;
    });
  }

  Future<void> _fetchSuppliers() async {
    setState(() { _isLoadingSuppliers = true; });

    try {
      final firestore = FirebaseFirestore.instance;

      // Try multiple approaches to find suppliers
      List<Map<String, dynamic>> suppliers = [];

      // First, try to get suppliers from the part's category document
      final doc = await firestore.collection('inventory_parts').doc(widget.part.category).get();
      if (doc.exists) {
        final data = doc.data();

        // Try different part ID formats
        List<String> possibleIds = [
          widget.part.id,
          widget.part.sparePartId,
          widget.part.name.toLowerCase().replaceAll(' ', '_'),
        ].where((id) => id.isNotEmpty).toList();

        for (String partId in possibleIds) {
          final partData = data?[partId] as Map<String, dynamic>?;
          if (partData != null && partData['suppliers'] != null) {
            for (var s in partData['suppliers']) {
              String displayName = (s['name'] ?? s['email'] ?? 'Unknown Supplier').toString();
              String value = (s['email'] ?? s['name'] ?? displayName).toString();
              if (value.trim().isEmpty) continue;
              suppliers.add({
                'name': s['name'] ?? '',
                'displayName': displayName,
                'value': value,
                'email': s['email']?.toString(),
                'price': s['price'],
                'reliability': s['reliability'],
              });
            }
            break; // Found suppliers, no need to try other IDs
          }
        }
      }

      // If no suppliers found in Firestore, add some demo suppliers based on part category
      if (suppliers.isEmpty) {
        suppliers = _getDemoSuppliers();
      }

      // Deduplicate by unique 'value' and keep stable order
      final seen = <String>{};
      final deduped = <Map<String, dynamic>>[];
      for (final s in suppliers) {
        final v = (s['value'] ?? '').toString();
        if (v.isEmpty) continue;
        if (seen.add(v)) deduped.add(s);
      }

      // Ensure selected value matches one of items; otherwise set to null
      String? nextSelected;
      if (_selectedSupplier != null && deduped.any((s) => s['value'].toString() == _selectedSupplier!['value'])) {
        nextSelected = _selectedSupplier!['value'];
      } else if (deduped.isNotEmpty) {
        nextSelected = deduped.first['value'] as String?;
      }

      setState(() {
        _suppliers = deduped;
        _selectedSupplier = nextSelected != null ? deduped.firstWhere((s) => s['value'] == nextSelected) : null;
      });
      _updateTotalPrice();

    } catch (e) {
      print('Error fetching suppliers: $e');
      // Fallback to demo suppliers on error
      final demo = _getDemoSuppliers();
      setState(() {
        _suppliers = demo;
        _selectedSupplier = demo.isNotEmpty ? demo.first : null;
      });
    } finally {
      setState(() { _isLoadingSuppliers = false; });
    }
  }

  List<Map<String, dynamic>> _getDemoSuppliers() {
    // Return demo suppliers based on part category
    final category = widget.part.category.toLowerCase();

    if (category.contains('engine') || category.contains('motor')) {
      return [
        {
          'displayName': 'AutoParts Malaysia Sdn Bhd',
          'value': 'autoparts@example.com',
          'email': 'autoparts@example.com',
          'price': 150.0,
          'reliability': 4.5,
        },
        {
          'displayName': 'Engine Components Supply',
          'value': 'engine@supply.com',
          'email': 'engine@supply.com',
          'price': 180.0,
          'reliability': 4.2,
        },
      ];
    } else if (category.contains('electronic') || category.contains('electric')) {
      return [
        {
          'displayName': 'Electronics Hub Malaysia',
          'value': 'electronics@hub.my',
          'email': 'electronics@hub.my',
          'price': 85.0,
          'reliability': 4.7,
        },
        {
          'displayName': 'Tech Components Sdn Bhd',
          'value': 'tech@components.com',
          'email': 'tech@components.com',
          'price': 95.0,
          'reliability': 4.3,
        },
      ];
    } else {
      return [
        {
          'displayName': 'General Parts Supplier',
          'value': 'general@parts.com',
          'email': 'general@parts.com',
          'price': 50.0,
          'reliability': 4.0,
        },
        {
          'displayName': 'Workshop Supply Co',
          'value': 'workshop@supply.co',
          'email': 'workshop@supply.co',
          'price': 65.0,
          'reliability': 4.4,
        },
        {
          'displayName': 'Industrial Parts Malaysia',
          'value': 'industrial@parts.my',
          'email': 'industrial@parts.my',
          'price': 75.0,
          'reliability': 4.1,
        },
      ];
    }
  }

  @override
  void dispose() {
    _qtyController.removeListener(_updateTotalPrice);
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? helperText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
          prefixText: prefixText,
          helperText: helperText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.priority_high, color: Colors.orange[700], size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Request Priority',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['Critical', 'High', 'Medium', 'Low'].map((level) {
              final isSelected = _selectedPriority == level;
              Color bgColor;
              Color textColor;
              IconData? icon;
              switch (level) {
                case 'Critical':
                  bgColor = isSelected ? Colors.red[700]! : Colors.red[200]!;
                  textColor = Colors.white;
                  icon = Icons.warning_amber_rounded;
                  break;
                case 'High':
                  bgColor = isSelected ? Colors.orange[600]! : Colors.orange[200]!;
                  textColor = Colors.white;
                  icon = Icons.priority_high;
                  break;
                case 'Medium':
                  bgColor = isSelected ? Colors.blue[600]! : Colors.blue[100]!;
                  textColor = Colors.white;
                  icon = Icons.info_outline;
                  break;
                default:
                  bgColor = isSelected ? Colors.green[600]! : Colors.green[100]!;
                  textColor = Colors.white;
                  icon = Icons.check_circle_outline;
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = level;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? bgColor : Colors.grey[300]!,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected && level == 'Critical'
                        ? [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: textColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        level,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (level == 'Critical' && isSelected)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.business, color: Colors.green[700], size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Supplier Selection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _isLoadingSuppliers
              ? Center(child: CircularProgressIndicator())
              : _suppliers.isEmpty
                  ? Center(
                      child: Text(
                        'No suppliers found for this part.',
                        style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          isExpanded: true,
                          value: _selectedSupplier,
                          hint: Text('Select a supplier'),
                          items: _suppliers.map((supplier) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: supplier,
                              child: Text(
                                _supplierLabel(supplier),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (context) {
                            return _suppliers.map((supplier) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _supplierLabel(supplier),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              );
                            }).toList();
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplier = value;
                            });
                            _updateTotalPrice();
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Supplier',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: EdgeInsets.all(16),
                            labelStyle: TextStyle(color: Colors.grey[600]),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a supplier';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        if (_selectedSupplier != null && _selectedSupplier!['price'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green[700], size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Total Price: RM${_totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '(${_selectedSupplier!['price']} × ${_qtyController.text})',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today, color: Colors.purple[700], size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Required Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectDate,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _requiredByDate != null
                              ? _fmtHumanDate(_requiredByDate!)
                              : 'Select required date (optional)',
                          style: TextStyle(
                            color: _requiredByDate != null ? Colors.grey[800] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the part ID - prioritize sparePartId, then id, then generate one
    String partId = widget.part.sparePartId.isNotEmpty
        ? widget.part.sparePartId
        : widget.part.id.isNotEmpty
        ? widget.part.id
        : 'PRT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo[700]!, Colors.indigo[500]!],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.assignment_add, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Procurement Request',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Create and email PO to supplier',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Part Information Section
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue[200]!, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.info, color: Colors.blue[700], size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Part Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: widget.part.isLowStock ? Colors.red[100] : Colors.green[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: widget.part.isLowStock ? Colors.red[300]! : Colors.green[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      'Stock: ${widget.part.quantity}',
                                      style: TextStyle(
                                        color: widget.part.isLowStock ? Colors.red[700] : Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildReadOnlyField('Part ID', partId),
                              SizedBox(height: 16),
                              _buildReadOnlyField('Part Name', widget.part.name),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField('Category', widget.part.category.isNotEmpty ? widget.part.category : '-'),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildReadOnlyField('Unit', widget.part.unit.isNotEmpty ? widget.part.unit : 'units'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Request Details Section
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.teal[200]!, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.assignment, color: Colors.teal[700], size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Request Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildTextFormField(
                                controller: _qtyController,
                                labelText: 'Quantity Needed *',
                                prefixIcon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                helperText: 'Recommended: ${widget.part.lowStockThreshold}',
                                validator: (value) {
                                  final qty = int.tryParse(value ?? '');
                                  if (qty == null || qty <= 0) {
                                    return 'Please enter a valid quantity';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _notesController,
                                labelText: 'Notes (Optional)',
                                prefixIcon: Icons.note,
                                maxLines: 3,
                                helperText: 'Additional details or special instructions',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Priority Selector
                        _buildPrioritySelector(),
                        SizedBox(height: 20),
                        // Supplier Dropdown
                        _buildSupplierDropdown(),
                        SizedBox(height: 20),
                        // Date Selector
                        _buildDateSelector(),
                      ],
                    ),
                  ),
                ),
              ),
              // Enhanced Footer with action buttons
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo[600]!, Colors.indigo[800]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitGmailEmailRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSubmitting)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                Icon(Icons.send, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                _isSubmitting ? 'Sending...' : 'Send PO via Gmail',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _requiredByDate = date);
  }

  Future<void> _submitGmailEmailRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final requestId = await GmailEmailService.submitProcurementRequestWithGmail(
        part: widget.part,
        quantity: qty,
        priority: _selectedPriority,
        supplierName: _selectedSupplier?['name'] ?? '',
        supplierEmail: _selectedSupplier?['email'] ?? '',
        requiredBy: _requiredByDate,
        notes: _notesController.text,
        requestorName: 'Workshop Manager',
        requestorId: 'WM-001',
      );

      _showSuccess(requestId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
            ),
            SizedBox(width: 12),
            Text('Gmail Email Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your procurement request has been emailed to the supplier.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.confirmation_number, color: Colors.green[700], size: 18),
                      SizedBox(width: 8),
                      Text('Request ID: $requestId', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.green[700], size: 18),
                      SizedBox(width: 8),
                      Text('Direct Gmail SMTP - 100% Free', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Supplier can reply via email to confirm/reject.', style: TextStyle(color: Colors.green[600])),
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[800]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProcurementTrackingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Track Requests',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtHumanDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$yyyy-$mm-$dd';
  }

  String _supplierLabel(Map<String, dynamic> s) {
    final name = (s['displayName'] ?? '').toString();
    final email = (s['email'] ?? '').toString();
    final price = s['price'];
    final parts = <String>[name];
    if (email.isNotEmpty) parts.add(email);
    if (price != null) parts.add('RM${price.toString()}');
    return parts.join('  •  ');
  }
}
