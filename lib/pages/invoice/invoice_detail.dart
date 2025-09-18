import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workshoppro_manager/pages/invoice/service_to_invoice.dart';
import '../../models/invoice.dart';
import '../../pages/vehicles/service_model.dart';
import '../../firestore_service.dart';

class InvoiceDetail extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetail({super.key, required this.invoice});

  @override
  State<InvoiceDetail> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends State<InvoiceDetail> {
  // Currency formatter for Malaysian Ringgit
  final _currency = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM',
    decimalDigits: 2,
  );
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedPaymentMethod;
  bool _isLoading = false;
  late Invoice _currentInvoice;

  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Bank Transfer',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateInvoiceStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      // Update status in Firestore
      await _firestoreService.updateInvoiceStatus(
        _currentInvoice.invoiceId,
        newStatus,
      );

      // Fetch the updated invoice from Firestore to ensure we have the latest data
      final updatedInvoice = await _firestoreService.getInvoice(
        _currentInvoice.invoiceId,
      );

      if (updatedInvoice != null) {
        setState(() {
          _currentInvoice = updatedInvoice;
        });
      } else {
        // Fallback to local update if fetch fails
        setState(() {
          _currentInvoice = Invoice(
            invoiceId: _currentInvoice.invoiceId,
            customerName: _currentInvoice.customerName,
            vehiclePlate: _currentInvoice.vehiclePlate,
            jobId: _currentInvoice.jobId,
            assignedMechanicId: _currentInvoice.assignedMechanicId,
            status: newStatus,
            paymentStatus: _currentInvoice.paymentStatus,
            paymentDate: _currentInvoice.paymentDate,
            issueDate: _currentInvoice.issueDate,
            createdAt: _currentInvoice.createdAt,
            updatedAt: DateTime.now(),
            parts: _currentInvoice.parts,
            labor: _currentInvoice.labor,
            subtotal: _currentInvoice.subtotal,
            tax: _currentInvoice.tax,
            grandTotal: _currentInvoice.grandTotal,
            notes: _currentInvoice.notes,
            createdBy: _currentInvoice.createdBy,
          );
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${newStatus.toLowerCase()} successfully'),
            backgroundColor: newStatus == 'Approved'
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePaymentStatus(String paymentMethod) async {
    setState(() => _isLoading = true);

    try {
      // Update payment status in Firestore
      await _firestoreService.updatePaymentStatus(
        _currentInvoice.invoiceId,
        'Paid',
        paymentDate: DateTime.now(),
      );

      // Fetch the updated invoice from Firestore to ensure we have the latest data
      final updatedInvoice = await _firestoreService.getInvoice(
        _currentInvoice.invoiceId,
      );

      if (updatedInvoice != null) {
        setState(() {
          _currentInvoice = updatedInvoice;
          _selectedPaymentMethod = null;
        });
      } else {
        // Fallback to local update if fetch fails
        setState(() {
          _currentInvoice = Invoice(
            invoiceId: _currentInvoice.invoiceId,
            customerName: _currentInvoice.customerName,
            vehiclePlate: _currentInvoice.vehiclePlate,
            jobId: _currentInvoice.jobId,
            assignedMechanicId: _currentInvoice.assignedMechanicId,
            status: _currentInvoice.status,
            paymentStatus: 'Paid',
            paymentDate: DateTime.now(),
            issueDate: _currentInvoice.issueDate,
            createdAt: _currentInvoice.createdAt,
            updatedAt: DateTime.now(),
            parts: _currentInvoice.parts,
            labor: _currentInvoice.labor,
            subtotal: _currentInvoice.subtotal,
            tax: _currentInvoice.tax,
            grandTotal: _currentInvoice.grandTotal,
            notes: _currentInvoice.notes,
            createdBy: _currentInvoice.createdBy,
          );
          _selectedPaymentMethod = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded successfully via $paymentMethod'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${_currentInvoice.invoiceId}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Print invoice functionality (to be implemented)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print functionality coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _currentInvoice.invoiceId,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _currency.format(_currentInvoice.grandTotal),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Status Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _currentInvoice.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getStatusColor(
                                    _currentInvoice.status,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _currentInvoice.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(
                                    _currentInvoice.status,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getPaymentStatusColor(
                                  _currentInvoice.paymentStatus,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getPaymentStatusColor(
                                    _currentInvoice.paymentStatus,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _currentInvoice.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: _getPaymentStatusColor(
                                    _currentInvoice.paymentStatus,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Invoice Details Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Customer',
                          _currentInvoice.customerName,
                        ),
                        _buildDetailRow(
                          'Vehicle',
                          _currentInvoice.vehiclePlate,
                        ),
                        _buildDetailRow(
                          'Mechanic',
                          _currentInvoice.assignedMechanicId,
                        ),
                        _buildDetailRow(
                          'Created By',
                          _currentInvoice.createdBy,
                        ),
                        // Show payment method if invoice is paid
                        if (_currentInvoice.paymentStatus.toLowerCase() ==
                                'paid' &&
                            _currentInvoice.paymentMethod != null)
                          _buildDetailRow(
                            'Payment Method',
                            _currentInvoice.paymentMethod!,
                            valueColor: Colors.green[700],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Dates Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Important Dates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Issue Date',
                          '${_currentInvoice.issueDate.day}/${_currentInvoice.issueDate.month}/${_currentInvoice.issueDate.year}',
                        ),
                        _buildDetailRow(
                          'Created Date',
                          '${_currentInvoice.createdAt.day}/${_currentInvoice.createdAt.month}/${_currentInvoice.createdAt.year}',
                        ),
                        _buildDetailRow(
                          'Last Updated',
                          '${_currentInvoice.updatedAt.day}/${_currentInvoice.updatedAt.month}/${_currentInvoice.updatedAt.year}',
                        ),
                        if (_currentInvoice.paymentDate != null)
                          _buildDetailRow(
                            'Payment Date',
                            '${_currentInvoice.paymentDate!.day}/${_currentInvoice.paymentDate!.month}/${_currentInvoice.paymentDate!.year}',
                            valueColor: Colors.green[700],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Parts Card
                if (_currentInvoice.parts.isNotEmpty)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._currentInvoice.parts.map(
                            (part) => _buildPartCard(part),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Labor Card
                if (_currentInvoice.labor.isNotEmpty)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Labor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._currentInvoice.labor.map(
                            (labor) => _buildLaborCard(labor),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Invoice Summary Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Parts Total',
                          _currentInvoice.partsTotal,
                        ),
                        _buildSummaryRow(
                          'Labor Total',
                          _currentInvoice.laborTotal,
                        ),
                        _buildSummaryRow('Subtotal', _currentInvoice.subtotal),
                        _buildSummaryRow('Tax (6%)', _currentInvoice.tax),
                        const Divider(thickness: 2),
                        _buildSummaryRow(
                          'Grand Total',
                          _currentInvoice.grandTotal,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Notes Card (only show if notes exist)
                if (_currentInvoice.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentInvoice.notes,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Payment Method Selection (for approved but unpaid invoices)
                if (_currentInvoice.status.toLowerCase() == 'approved' &&
                    _currentInvoice.paymentStatus.toLowerCase() ==
                        'unpaid') ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Select Payment Method',
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            },
                          ),
                          if (_selectedPaymentMethod != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _updatePaymentStatus(
                                        _selectedPaymentMethod!,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text('Mark as Paid'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Action Buttons at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildActionButtons(),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Show approve/reject buttons for pending invoices
    if (_currentInvoice.status.toLowerCase() == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _updateInvoiceStatus('Rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _updateInvoiceStatus('Approved'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Approve',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // Show reject button for approved but unpaid invoices
    if (_currentInvoice.status.toLowerCase() == 'approved' &&
        _currentInvoice.paymentStatus.toLowerCase() == 'unpaid') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _updateInvoiceStatus('Rejected'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Reject Invoice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Return empty container for other states
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(PartLine part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: ${part.quantity}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Unit Price: ${_currency.format(part.unitPrice)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total: ${_currency.format(part.unitPrice * part.quantity)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaborCard(LaborLine labor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labor.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hours: ${labor.hours.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Rate: ${_currency.format(labor.rate)}/hr',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total: ${_currency.format(labor.hours * labor.rate)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            _currency.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
