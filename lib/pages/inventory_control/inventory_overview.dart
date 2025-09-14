import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_inv_part.dart';
import 'all_inv_part.dart';
import 'inventory_data_manager.dart';
import '../navigations/drawer.dart';
import 'procurement_tracking_screen.dart';

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
      QuerySnapshot categorySnapshot = await _firestore.collection('inventory_parts').get();
      Map<String, int> usage = {};
      int total = 0;
      int used = 0;
      int requested = 0;
      int lowStock = 0;
      for (var categoryDoc in categorySnapshot.docs) {
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;
        int categoryCount = 0;
        data.forEach((partName, partData) {
          if (partData is Map<String, dynamic>) {
            categoryCount++;
            total++;
            int quantity = partData['quantity'] ?? 0;
            bool isLowStock = partData['isLowStock'] ?? false;
            // Count used parts (assuming parts with quantity < original are "used")
            if (quantity > 0) {
              used += (50 - quantity); // Assuming 50 was original quantity
            }
            if (isLowStock) {
              lowStock++;
              requested++;
            }
          }
        });
        usage[categoryDoc.id] = categoryCount;
      }
      // Sort usage and get top 5
      final sortedUsage = Map.fromEntries(
        usage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );
      final top5Usage = Map<String, int>.fromEntries(sortedUsage.entries.take(5));
      setState(() {
        totalParts = total;
        partsUsed = used > 0 ? used : 320;
        partsRequested = requested > 0 ? requested : lowStock;
        lowStockParts = lowStock;
        categoryUsage = top5Usage;
        _isLoading = false;
      });
      print('✅ Inventory stats updated: Total: $total, Used: $used, Requested: $requested, Top5: $top5Usage');
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
                        onTap: _fetchInventoryStats,
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
                                      'Parts Requested',
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
                        Text(
                          'Part Usage',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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

                        // Request New Parts Button
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
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Request New Parts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),
                        // View Procurement Requests Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProcurementTrackingScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Track Procurement Requests',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    Text(
                                      'Monitor email status & supplier responses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.track_changes,
                                  color: Colors.orange[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32), // Space for bottom navigation
                        SizedBox(height: 16),

                        // Data Import/Export Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text('Delete All Spare Parts'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Delete All Spare Parts'),
                                      content: Text('Are you sure you want to delete ALL spare parts? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      // Get all categories from Firestore
                                      final snapshot = await FirebaseFirestore.instance.collection('inventory_parts').get();
                                      final categories = snapshot.docs.map((doc) => doc.id).toList();
                                      await InventoryDataManager(FirebaseFirestore.instance).deleteAllInventoryParts(categories);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('✅ All spare parts deleted.'), backgroundColor: Colors.green),
                                      );
                                      await _fetchInventoryStats();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('❌ Failed to delete: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.upload, color: Colors.white),
                                label: Text('Upload All Spare Parts'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Upload All Spare Parts'),
                                      content: Text('Are you sure you want to upload the latest spare parts? This will overwrite existing data.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text('Upload', style: TextStyle(color: Colors.blue)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await InventoryDataManager(FirebaseFirestore.instance).uploadDefaultParts(InventoryDataManager.getDefaultPartsWithIds());
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('✅ All spare parts uploaded.'), backgroundColor: Colors.green),
                                      );
                                      await _fetchInventoryStats();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('❌ Failed to upload: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),

                        // Bottom navigation placeholder
                        SizedBox(height: 16),

                        // Data Import Button

                      ],
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
}
