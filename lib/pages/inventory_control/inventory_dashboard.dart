import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_inv_part.dart';
import 'all_inv_part.dart';
import 'inventory_data_manager.dart';
import '../navigations/drawer.dart';
import 'procurement_tracking_screen.dart';
import 'request_inv_parts.dart';
import 'spare_parts_analytics.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int totalParts = 0;
  int partsUsed = 0;
  int partsRequested = 0;
  int lowStockParts = 0;
  bool _isLoading = true;

  Map<String, int> categoryUsage = {
    'Engine': 0,
    'Brakes': 0,
    'Tires': 0,
    'Suspension': 0,
    'Electrical': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchInventoryStats();
  }

  // Fetch all category documents and their parts from Firestore, calculate usage, and show top 5 categories
  Future<void> _fetchInventoryStats() async {
    try {
      QuerySnapshot inventorySnapshot = await _firestore.collection('inventory_parts').get();
      Map<String, String> partCategoryMap = {};
      int totalPartItems = 0; // <-- Correct total parts counter
      for (var categoryDoc in inventorySnapshot.docs) {
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;
        // Count each part field in the category document
        data.forEach((partId, partData) {
          if (partData is Map<String, dynamic>) {
            totalPartItems++;
            String nameRaw = partData['name'] ?? '';
            String name = nameRaw.trim().toLowerCase();
            String category = partData['category'] ?? 'Unknown';
            if (name.isNotEmpty) {
              partCategoryMap[name] = category;
            }
          }
        });
      }

      // Step 2: Get all invoices and sum usage by category
      QuerySnapshot invoiceSnapshot = await _firestore.collection('invoices').get();
      Map<String, int> usageByCategory = {
        'Engine': 0,
        'Brakes': 0,
        'Tires': 0,
        'Suspension': 0,
        'Electrical': 0,
      };
      int used = 0;
      int requested = 0;
      int lowStock = 0;
      for (var invoiceDoc in invoiceSnapshot.docs) {
        Map<String, dynamic> invoiceData = invoiceDoc.data() as Map<String, dynamic>;
        List<dynamic> parts = invoiceData['parts'] ?? [];
        for (var part in parts) {
          String partNameRaw = part['name'] ?? '';
          String partName = partNameRaw.trim().toLowerCase();
          int quantity = part['quantity'] ?? 0;
          String category = partCategoryMap[partName] ?? 'Unknown';
          if (usageByCategory.containsKey(category)) {
            usageByCategory[category] = usageByCategory[category]! + quantity;
          }
          used += quantity;
        }
      }

      // Step 3: (Optional) Get requested/low stock from inventory if needed for other cards
      for (var categoryDoc in inventorySnapshot.docs) {
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;
        data.forEach((partId, partData) {
          if (partData is Map<String, dynamic>) {
            int quantity = partData['quantity'] ?? 0;
            bool isLowStock = partData['isLowStock'] ?? false;
            bool isRequested = partData['isRequested'] ?? false;
            if (isRequested || isLowStock) {
              requested++;
            }
            if (isLowStock) {
              lowStock++;
            }
          }
        });
      }

      setState(() {
        totalParts = totalPartItems; // <-- Set correct total parts value
        partsUsed = used;
        partsRequested = requested;
        lowStockParts = lowStock;
        categoryUsage = usageByCategory;
        _isLoading = false;
      });
      print('✅ Inventory stats updated from invoices: Total: $totalParts, Used: $partsUsed, Requested: $partsRequested, UsageByCategory: $categoryUsage');
    } catch (e) {
      print('❌ Error fetching inventory stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getUsageHeight(String category) {
    int count = categoryUsage[category] ?? 0;
    int maxCount = categoryUsage.values.fold(0, (max, current) => current > max ? current : max);
    if (maxCount == 0) return 0.1;
    return (count / maxCount).clamp(0.1, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: CustomDrawer(), // Use the drawer from drawer.dart
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu, color: Colors.black, size: 28),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Inventory',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await _fetchInventoryStats();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewPartScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add, color: Colors.black, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _fetchInventoryStats,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                if (_isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllInventoryPartsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Overview Cards
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AllInventoryPartsScreen(),
                                    ),
                                  );
                                },
                                child: _buildOverviewCard(
                                  'Total Parts',
                                  _isLoading ? '...' : '$totalParts',
                                  _isLoading,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AllInventoryPartsScreen(),
                                    ),
                                  );
                                },
                                child: _buildOverviewCard(
                                  'Parts Used',
                                  _isLoading ? '...' : '$partsUsed',
                                  _isLoading,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Parts Requested Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllInventoryPartsScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: partsRequested > 10
                                  ? Colors.red[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: partsRequested > 10
                                    ? Colors.red[200]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Low Stock',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (partsRequested > 10)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Urgent',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _isLoading ? '...' : '$partsRequested',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: partsRequested > 10
                                        ? Colors.red[700]
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Part Usage Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Part Usage',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SparePartsAnalyticsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'View Analytics',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        Text(
                          'Part Usage by Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Chart Container
                        Container(
                          height: 200,
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildChartBar(
                                      'Engine',
                                      _getUsageHeight('Engine'),
                                      Colors.blue,
                                    ),
                                    _buildChartBar(
                                      'Brakes',
                                      _getUsageHeight('Brakes'),
                                      Colors.red,
                                    ),
                                    _buildChartBar(
                                      'Tires',
                                      _getUsageHeight('Tires'),
                                      Colors.orange,
                                    ),
                                    _buildChartBar(
                                      'Suspension',
                                      _getUsageHeight('Suspension'),
                                      Colors.green,
                                    ),
                                    _buildChartBar(
                                      'Electrical',
                                      _getUsageHeight('Electrical'),
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                        ),

                        SizedBox(height: 32),

                        // Procurement Section
                        Text(
                          'Procurement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Recent Procurement Requests Preview (always visible, any status)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.track_changes, color: Colors.orange[700], size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Recent Procurement Requests',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProcurementTrackingScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              FutureBuilder<QuerySnapshot>(
                                future: _firestore
                                    .collection('procurement_requests')
                                    .orderBy('requestedAt', descending: true)
                                    .limit(3)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      height: 60,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.orange[600],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'No recent procurement requests',
                                          style: TextStyle(
                                            color: Colors.orange[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Always show the 3 most recent requests, any status
                                  return Column(
                                    children: snapshot.data!.docs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return _buildProcurementPreviewItem(data);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Recent Part Requests Preview
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.assignment, color: Colors.teal[700], size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Recent Part Requests',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InventoryPartRequestsPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.teal[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              FutureBuilder<QuerySnapshot>(
                                future: _firestore
                                    .collection('inventory_requests')
                                    .orderBy('requestedAt', descending: true)
                                    .limit(3)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      height: 60,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.teal[600],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'No recent part requests',
                                          style: TextStyle(
                                            color: Colors.teal[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: snapshot.data!.docs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return _buildPartRequestPreviewItem(data);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32), // Space for bottom navigation
                        SizedBox(height: 16),


                        SizedBox(height: 32),

                        // Bottom navigation placeholder
                        SizedBox(height: 16),

                        // Data Import Button

                      ], // End of children for Column
                    ), // End of Column
                  ), // End of SingleChildScrollView
                ), // End of RefreshIndicator
              ), // End of Container
            ), // End of Expanded
          ], // End of children for main Column
        ), // End of main Column
      ), // End of SafeArea
    ); // End of Scaffold
  }


  Widget _buildOverviewCard(String title, String value, bool isLoading) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 120 * height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProcurementPreviewItem(Map<String, dynamic> data) {
    final requestId = data['requestId'] ?? '';
    final partName = data['partName'] ?? 'Unknown Part';
    final quantity = data['requestedQty'] ?? data['quantity'] ?? 0;
    final status = data['status'] ?? 'Pending';
    final supplier = data['supplier'] ?? 'N/A';
    final timestamp = (data['requestedAt'] is Timestamp)
        ? (data['requestedAt'] as Timestamp).toDate()
        : null;
    final isUrgent = status == 'Urgent';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isUrgent ? Colors.red[200]! : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isUrgent ? Colors.red[700] : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Supplier: $supplier', // This will now show the supplier name
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 14,
                    color: isUrgent ? Colors.red[700] : Colors.grey[700],
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timestamp != null ? '${timestamp.day}/${timestamp.month}/${timestamp.year}' : '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 4),
              if (isUrgent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Urgent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartRequestPreviewItem(Map<String, dynamic> data) {
    final requestId = data['requestId'] ?? '';
    final partName = data['partName'] ?? 'Unknown Part';
    final requestedBy = data['requestedBy'] ?? 'N/A';
    final status = data['status'] ?? 'Pending';
    final requestedAt = (data['requestedAt'] as Timestamp).toDate();
    final isApproved = status == 'Approved';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isApproved ? Colors.green[200]! : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isApproved ? Colors.green[700] : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Requested by: $requestedBy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 14,
                    color: isApproved ? Colors.green[700] : Colors.grey[700],
                    fontWeight: isApproved ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 4),
              if (isApproved)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Approved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
