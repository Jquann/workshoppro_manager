import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import 'invoice_list.dart';

class InvoiceDashboard extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const InvoiceDashboard({super.key, this.scaffoldKey});

  @override
  State<InvoiceDashboard> createState() => _InvoiceDashboardState();
}

class _InvoiceDashboardState extends State<InvoiceDashboard> {
  List<Invoice> invoices = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    // Sample invoice data
    final sampleData = [
      {
        "invoiceId": "INV-2025-013",
        "customerId": "CUS-1012",
        "vehicleId": "VH-9090",
        "jobId": "JOB-5670",
        "assignedMechanicId": "MECH-010",
        "issueDate": "2025-09-10T10:00:00Z",
        "status": "Approved",
        "paymentStatus": "Unpaid",
        "paymentDate": null,
        "items": [
          {
            "description": "Oil Change",
            "quantity": 1,
            "unitPrice": 180.00,
            "total": 180.00,
          },
          {
            "description": "Wheel Alignment",
            "quantity": 1,
            "unitPrice": 120.00,
            "total": 120.00,
          },
        ],
        "subtotal": 300.00,
        "tax": 18.00,
        "grandTotal": 318.00,
        "notes": "Customer requested synthetic oil.",
        "createdBy": "manager_02",
        "createdAt": "2025-09-10T10:00:00Z",
        "updatedAt": "2025-09-10T11:00:00Z",
      },
      {
        "invoiceId": "INV-2025-014",
        "customerId": "CUS-1015",
        "vehicleId": "VH-9111",
        "jobId": "JOB-5671",
        "assignedMechanicId": "MECH-011",
        "issueDate": "2025-09-11T09:30:00Z",
        "status": "Pending",
        "paymentStatus": "Unpaid",
        "paymentDate": null,
        "items": [
          {
            "description": "Brake Pad Replacement",
            "quantity": 2,
            "unitPrice": 150.00,
            "total": 300.00,
          },
        ],
        "subtotal": 300.00,
        "tax": 18.00,
        "grandTotal": 318.00,
        "notes": "Urgent service requested.",
        "createdBy": "manager_01",
        "createdAt": "2025-09-11T09:30:00Z",
        "updatedAt": "2025-09-11T10:00:00Z",
      },
      {
        "invoiceId": "INV-2025-015",
        "customerId": "CUS-1020",
        "vehicleId": "VH-9222",
        "jobId": "JOB-5672",
        "assignedMechanicId": "MECH-007",
        "issueDate": "2025-09-12T14:00:00Z",
        "status": "Approved",
        "paymentStatus": "Paid",
        "paymentDate": "2025-09-13T10:15:00Z",
        "items": [
          {
            "description": "Engine Overhaul",
            "quantity": 1,
            "unitPrice": 2500.00,
            "total": 2500.00,
          },
          {
            "description": "Coolant",
            "quantity": 2,
            "unitPrice": 80.00,
            "total": 160.00,
          },
        ],
        "subtotal": 2660.00,
        "tax": 159.60,
        "grandTotal": 2819.60,
        "notes": "Customer opted for full overhaul package.",
        "createdBy": "manager_03",
        "createdAt": "2025-09-12T14:00:00Z",
        "updatedAt": "2025-09-13T10:20:00Z",
      },
      {
        "invoiceId": "INV-2025-016",
        "customerId": "CUS-1030",
        "vehicleId": "VH-9333",
        "jobId": "JOB-5673",
        "assignedMechanicId": "MECH-008",
        "issueDate": "2025-09-13T08:45:00Z",
        "status": "Rejected",
        "paymentStatus": "Unpaid",
        "paymentDate": null,
        "items": [
          {
            "description": "Transmission Repair",
            "quantity": 1,
            "unitPrice": 1800.00,
            "total": 1800.00,
          },
        ],
        "subtotal": 1800.00,
        "tax": 108.00,
        "grandTotal": 1908.00,
        "notes": "Rejected due to incorrect parts listed.",
        "createdBy": "manager_02",
        "createdAt": "2025-09-13T08:45:00Z",
        "updatedAt": "2025-09-13T09:10:00Z",
      },
      {
        "invoiceId": "INV-2025-017",
        "customerId": "CUS-1040",
        "vehicleId": "VH-9444",
        "jobId": "JOB-5674",
        "assignedMechanicId": "MECH-009",
        "issueDate": "2025-09-14T15:20:00Z",
        "status": "Approved",
        "paymentStatus": "Paid",
        "paymentDate": "2025-09-15T11:00:00Z",
        "items": [
          {
            "description": "Battery Replacement",
            "quantity": 1,
            "unitPrice": 450.00,
            "total": 450.00,
          },
          {
            "description": "Air Filter",
            "quantity": 1,
            "unitPrice": 80.00,
            "total": 80.00,
          },
        ],
        "subtotal": 530.00,
        "tax": 31.80,
        "grandTotal": 561.80,
        "notes": "Paid via online banking.",
        "createdBy": "manager_01",
        "createdAt": "2025-09-14T15:20:00Z",
        "updatedAt": "2025-09-15T11:05:00Z",
      },
    ];

    setState(() {
      invoices = sampleData.map((json) => Invoice.fromJson(json)).toList();
    });
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
      invoices.where((invoice) => invoice.paymentStatus == 'Unpaid').length;

  double get totalRevenue => invoices
      .where((invoice) => invoice.paymentStatus == 'Paid')
      .fold(0, (sum, invoice) => sum + invoice.grandTotal);

  double get pendingRevenue => invoices
      .where((invoice) => invoice.paymentStatus == 'Unpaid')
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Overview
                const Text(
                  'Invoice Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              ],
            ),
          ),

          // View All Invoices Button - Static at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      builder: (context) => InvoiceList(invoices: invoices),
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
