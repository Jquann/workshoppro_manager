import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice_pdf_service.dart';
import 'invoice_gmail_service.dart';
import '../../models/invoice.dart';
import '../../models/service_model.dart';
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

  Future<void> _exportInvoiceToPdf() async {
    setState(() => _isLoading = true);

    try {
      // Generate PDF bytes using the static method
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        _currentInvoice,
      );

      // Save PDF to device storage with invoiceId_timestamp format
      final filePath = await InvoicePdfService.saveInvoicePdf(
        _currentInvoice,
        pdfBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice PDF saved successfully!\nPath: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export invoice to PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvoivePdfToEmail() async {
    try {
      // Get customer emails by name
      final customerEmails = await _firestoreService.getCustomerEmailsByName(
        _currentInvoice.customerName,
      );

      if (customerEmails.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email found for this customer'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show dialog with email selection
      final selectedEmail = await showDialog<Map<String, String>>(
        context: context,
        builder: (BuildContext context) {
          return _EmailSelectionDialog(
            customerEmails: customerEmails,
            invoice: _currentInvoice,
          );
        },
      );

      if (selectedEmail != null) {
        await _sendEmailWithPdf(selectedEmail);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error retrieving customer emails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmailWithPdf(Map<String, String> selectedCustomer) async {
    setState(() => _isLoading = true);

    try {
      // Generate PDF bytes
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        _currentInvoice,
      );

      // Send email with PDF attachment
      await InvoiceGmailService.sendInvoicePdf(
        recipientEmail: selectedCustomer['email']!,
        recipientName: selectedCustomer['name']!,
        invoice: _currentInvoice,
        pdfBytes: pdfBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice sent successfully to ${selectedCustomer['email']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invoice email: $e'),
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
          // Send Invoice PDF to Email Button
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _sendInvoivePdfToEmail,
            tooltip: 'Send Invoice via Email',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportInvoiceToPdf,
            tooltip: 'Export Invoice to PDF',
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
                                ).withValues(alpha: 0.2),
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
                                ).withValues(alpha: 0.2),
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
                // (Including all cards for invoice details, dates, parts, labor, summary, notes, payment method selection)
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
              color: Colors.black.withValues(alpha: 0.3),
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

class _EmailSelectionDialog extends StatefulWidget {
  final List<Map<String, String>> customerEmails;
  final Invoice invoice;

  const _EmailSelectionDialog({
    required this.customerEmails,
    required this.invoice,
  });

  @override
  State<_EmailSelectionDialog> createState() => _EmailSelectionDialogState();
}

class _EmailSelectionDialogState extends State<_EmailSelectionDialog> {
  Map<String, String>? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Default to first option
    if (widget.customerEmails.isNotEmpty) {
      _selectedCustomer = widget.customerEmails.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Send Invoice via Email',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice: ${widget.invoice.invoiceId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Customer Email:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Map<String, String>>(
                      value: _selectedCustomer,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      menuMaxHeight: 200,
                      items: widget.customerEmails.map((customer) {
                        return DropdownMenuItem<Map<String, String>>(
                          value: customer,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customer['name']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                customer['email']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value;
                        });
                      },
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Preview:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${_selectedCustomer!['email']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Subject: Invoice ${widget.invoice.invoiceId} - Workshop Pro Manager',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Attachment: Invoice_${widget.invoice.invoiceId}.pdf',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedCustomer != null
                        ? () => Navigator.of(context).pop(_selectedCustomer)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
