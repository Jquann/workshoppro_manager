import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/invoice.dart';
import '../../firestore_service.dart';
import 'invoice_list.dart';
// import 'service_to_invoice.dart';

class InvoiceDashboard extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const InvoiceDashboard({super.key, this.scaffoldKey});

  @override
  State<InvoiceDashboard> createState() => _InvoiceDashboardState();
}

class _InvoiceDashboardState extends State<InvoiceDashboard> {
  List<Invoice> invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<Invoice>>? _invoicesSubscription;

  @override
  void initState() {
    super.initState();
    _loadInvoicesFromFirestore();
  }

  @override
  void dispose() {
    _invoicesSubscription?.cancel();
    super.dispose();
  }

  void _loadInvoicesFromFirestore() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _invoicesSubscription?.cancel(); // Cancel previous subscription if exists
    _invoicesSubscription = _firestoreService.invoicesStream().listen(
      (List<Invoice> fetchedInvoices) {
        if (mounted) {
          setState(() {
            invoices = fetchedInvoices;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load invoices: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  int get pendingCount =>
      invoices.where((invoice) => invoice.status == 'Pending').length;

  int get approvedCount =>
      invoices.where((invoice) => invoice.status == 'Approved').length;

  int get rejectedCount =>
      invoices.where((invoice) => invoice.status == 'Rejected').length;

  int get paidCount =>
      invoices.where((invoice) => invoice.paymentStatus == 'Paid').length;

  int get unpaidCount =>
      invoices.where((invoice) => invoice.paymentStatus == 'Unpaid'  && invoice.status != 'Rejected').length;

  double get totalRevenue => invoices
      .where((invoice) => invoice.paymentStatus == 'Paid')
      .fold(0, (sum, invoice) => sum + invoice.grandTotal);

  double get pendingRevenue => invoices
      .where(
        (invoice) =>
            invoice.paymentStatus == 'Unpaid' && invoice.status != 'Rejected',
      )
      .fold(0, (sum, invoice) => sum + invoice.grandTotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 24),
          onPressed: () {
            widget.scaffoldKey?.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'Invoices',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.sync_alt),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ServiceToInvoiceMigration(),
          //       ),
          //     );
          //   },
          //   tooltip: 'Service to Invoice Migration',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadInvoicesFromFirestore,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading invoices...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInvoicesFromFirestore,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice Overview
                      const Text(
                        'Invoice Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              'Pending',
                              pendingCount.toString(),
                              Colors.orange,
                              Icons.pending_actions,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              'Approved',
                              approvedCount.toString(),
                              Colors.blue,
                              Icons.thumb_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              'Rejected',
                              rejectedCount.toString(),
                              Colors.red,
                              Icons.thumb_down,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Payment Overview
                      const Text(
                        'Payment Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              'Paid',
                              paidCount.toString(),
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusCard(
                              'Unpaid',
                              unpaidCount.toString(),
                              Colors.red,
                              Icons.cancel,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Revenue Overview
                      const Text(
                        'Revenue Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildRevenueCard(
                              'Total Revenue',
                              'RM ${totalRevenue.toStringAsFixed(2)}',
                              Colors.green,
                              Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRevenueCard(
                              'Pending Revenue',
                              'RM ${pendingRevenue.toStringAsFixed(2)}',
                              Colors.orange,
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),

                      if (invoices.isEmpty) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No invoices found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Invoices will appear here once services are converted to invoices',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // View All Invoices Button - Static at bottom
                if (invoices.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InvoiceList(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list),
                            SizedBox(width: 8),
                            Text(
                              'View All Invoices',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
