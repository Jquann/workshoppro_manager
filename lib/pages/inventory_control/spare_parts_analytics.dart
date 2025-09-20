import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class SparePartsAnalyticsScreen extends StatefulWidget {
  @override
  _SparePartsAnalyticsScreenState createState() => _SparePartsAnalyticsScreenState();
}


class _SparePartsAnalyticsScreenState extends State<SparePartsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, Map<String, dynamic>> categoryAnalytics = {};
  Map<String, double> utilizationPercentages = {};
  List<Map<String, dynamic>> topUsedParts = [];
  List<Map<String, dynamic>> filteredTopUsedParts = [];
  int totalPartsCount = 0;
  int totalUsedCount = 0;

  // Filter state
  String _selectedTimeFilter = 'All Time';
  String _selectedSortOrder = 'Utilization (High to Low)';
  final List<String> _timeFilterOptions = [
    'All Time', 'Last 30 Days', 'Last 3 Months', 'Last 6 Months', 'Last Year'
  ];
  final List<String> _sortOrderOptions = [
    'Utilization (High to Low)', 'Utilization (Low to High)', 'Usage (High to Low)', 'Usage (Low to High)', 'Stock (High to Low)', 'Stock (Low to High)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch inventory parts and build a map by normalized part name and category
      QuerySnapshot inventorySnapshot = await _firestore.collection('inventory_parts').get();
      Map<String, Map<String, dynamic>> inventoryMap = {};
      Map<String, List<Map<String, dynamic>>> categoryPartsMap = {};
      int totalParts = 0;

      for (var categoryDoc in inventorySnapshot.docs) {
        Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
        categoryData.forEach((partId, partData) {
          if (partData is Map<String, dynamic>) {
            String nameRaw = partData['name'] ?? '';
            String name = nameRaw.trim().toLowerCase();
            String category = partData['category'] ?? 'Unknown';
            if (name.isNotEmpty) {
              inventoryMap[name] = partData;
              categoryPartsMap.putIfAbsent(category, () => []);
              categoryPartsMap[category]!.add({...partData, 'normalizedName': name});
              totalParts++;
            }
          }
        });
      }

      // Fetch part usage from vehicles collection and their service records
      QuerySnapshot vehiclesSnapshot = await _firestore.collection('vehicles').get();
      Map<String, int> partUsageMap = {};
      int totalPartsUsed = 0;

      for (var vehicleDoc in vehiclesSnapshot.docs) {
        // Fetch service records for this vehicle
        QuerySnapshot serviceRecordsSnapshot = await _firestore
            .collection('vehicles')
            .doc(vehicleDoc.id)
            .collection('service_records')
            .get();

        for (var serviceDoc in serviceRecordsSnapshot.docs) {
          Map<String, dynamic> serviceData = serviceDoc.data() as Map<String, dynamic>;
          List<dynamic> parts = serviceData['parts'] ?? [];

          for (var part in parts) {
            String partNameRaw = part['name'] ?? '';
            String partName = partNameRaw.trim().toLowerCase();
            int quantity = 1; // Default quantity if not specified

            // Try to get quantity from various possible fields
            if (part['quantity'] != null) {
              quantity = int.tryParse(part['quantity'].toString()) ?? 1;
            } else if (part['qty'] != null) {
              quantity = int.tryParse(part['qty'].toString()) ?? 1;
            }

            if (partName.isEmpty) continue;

            partUsageMap[partName] = (partUsageMap[partName] ?? 0) + quantity;
            totalPartsUsed += quantity;
          }
        }
      }

      // Build topUsedParts with usage, stock, and category, and utilization
      List<Map<String, dynamic>> partsUsage = [];
      partUsageMap.forEach((partNameNormalized, usedCount) {
        Map<String, dynamic>? inventory = inventoryMap[partNameNormalized];
        String partNameRaw = inventory != null ? (inventory['name'] ?? partNameNormalized) : partNameNormalized;
        final isMissing = inventory == null;
        final currentStock = !isMissing ? (inventory['quantity'] ?? 0) : 0;
        final category = !isMissing ? (inventory['category'] ?? '-') : '-';
        double utilizationRate;
        String utilizationLabel;
        if (isMissing) {
          utilizationRate = 100.0;
          utilizationLabel = 'Not in inventory';
        } else if (currentStock == 0) {
          utilizationRate = 100.0;
          utilizationLabel = 'Out of stock';
        } else {
          utilizationRate = (usedCount + currentStock) > 0 ? (usedCount / (usedCount + currentStock)) * 100 : 0.0;
          utilizationLabel = '${utilizationRate.toStringAsFixed(1)}%';
        }
        partsUsage.add({
          'partName': partNameRaw,
          'usedCount': usedCount,
          'category': category,
          'currentStock': currentStock,
          'utilizationRate': utilizationRate,
          'utilizationLabel': utilizationLabel,
          'inventoryMissing': isMissing,
        });
      });
      partsUsage.sort((a, b) => b['usedCount'].compareTo(a['usedCount']));

      // Build category analytics
      Map<String, Map<String, dynamic>> categoryAnalyticsMap = {};
      Map<String, double> utilizationPercentagesMap = {};
      categoryPartsMap.forEach((category, partsList) {
        int totalCategoryParts = partsList.length;
        int lowStockParts = 0;
        int requestedParts = 0;
        int totalCategoryStock = 0;
        int totalCategoryUsed = 0;
        for (var part in partsList) {
          String normalizedName = part['normalizedName'] ?? '';
          int stock = part['quantity'] ?? 0;
          int threshold = part['lowStockThreshold'] ?? 0;
          int used = partUsageMap[normalizedName] ?? 0;
          totalCategoryStock += stock;
          totalCategoryUsed += used;
          if (stock <= threshold) lowStockParts++;
          if (used > 0) requestedParts++;
        }
        double utilizationRate = (totalCategoryUsed + totalCategoryStock) > 0 ? (totalCategoryUsed / (totalCategoryUsed + totalCategoryStock)) * 100 : 0.0;
        categoryAnalyticsMap[category] = {
          'totalParts': totalCategoryParts,
          'usedParts': totalCategoryUsed,
          'lowStockParts': lowStockParts,
          'requestedParts': requestedParts,
          'utilizationRate': utilizationRate,
        };
        utilizationPercentagesMap[category] = utilizationRate;
      });

      setState(() {
        topUsedParts = partsUsage.take(10).toList();
        totalUsedCount = totalPartsUsed;
        totalPartsCount = totalParts;
        categoryAnalytics = categoryAnalyticsMap;
        utilizationPercentages = utilizationPercentagesMap;
        _applyFilters();
        _isLoading = false;
      });

      print('✅ Analytics data updated from vehicles: Total Parts: $totalParts, Total Used: $totalPartsUsed');

    } catch (e) {
      print('❌ Error fetching analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(topUsedParts);
    // Time filter (if implemented, would filter by service record date)
    // For now, just sort
    switch (_selectedSortOrder) {
      case 'Utilization (High to Low)':
        filtered.sort((a, b) => b['utilizationRate'].compareTo(a['utilizationRate']));
        break;
      case 'Utilization (Low to High)':
        filtered.sort((a, b) => a['utilizationRate'].compareTo(b['utilizationRate']));
        break;
      case 'Usage (High to Low)':
        filtered.sort((a, b) => b['usedCount'].compareTo(a['usedCount']));
        break;
      case 'Usage (Low to High)':
        filtered.sort((a, b) => a['usedCount'].compareTo(b['usedCount']));
        break;
      case 'Stock (High to Low)':
        filtered.sort((a, b) => b['currentStock'].compareTo(a['currentStock']));
        break;
      case 'Stock (Low to High)':
        filtered.sort((a, b) => a['currentStock'].compareTo(b['currentStock']));
        break;
    }
    filteredTopUsedParts = filtered;
  }

  void _applyTimeFilterToCategoryAnalytics() {
    // This method will re-fetch and filter analytics data based on the selected time filter
    _fetchAnalyticsDataWithTimeFilter();
  }

  DateTime _getFilterStartDate() {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'Last 30 Days':
        return now.subtract(Duration(days: 30));
      case 'Last 3 Months':
        return now.subtract(Duration(days: 90));
      case 'Last 6 Months':
        return now.subtract(Duration(days: 180));
      case 'Last Year':
        return now.subtract(Duration(days: 365));
      case 'All Time':
      default:
        return DateTime(2000); // Very old date to include all records
    }
  }

  Future<void> _fetchAnalyticsDataWithTimeFilter() async {
    setState(() => _isLoading = true);
    try {
      final filterStartDate = _getFilterStartDate();

      // Fetch inventory parts and build a map by normalized part name and category
      QuerySnapshot inventorySnapshot = await _firestore.collection('inventory_parts').get();
      Map<String, Map<String, dynamic>> inventoryMap = {};
      Map<String, List<Map<String, dynamic>>> categoryPartsMap = {};
      int totalParts = 0;

      for (var categoryDoc in inventorySnapshot.docs) {
        Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
        categoryData.forEach((partId, partData) {
          if (partData is Map<String, dynamic>) {
            String nameRaw = partData['name'] ?? '';
            String name = nameRaw.trim().toLowerCase();
            String category = partData['category'] ?? 'Unknown';
            if (name.isNotEmpty) {
              inventoryMap[name] = partData;
              categoryPartsMap.putIfAbsent(category, () => []);
              categoryPartsMap[category]!.add({...partData, 'normalizedName': name});
              totalParts++;
            }
          }
        });
      }

      // Fetch part usage from vehicles collection with time filtering
      QuerySnapshot vehiclesSnapshot = await _firestore.collection('vehicles').get();
      Map<String, int> partUsageMap = {};
      int totalPartsUsed = 0;

      for (var vehicleDoc in vehiclesSnapshot.docs) {
        // Fetch service records for this vehicle with time filter
        Query serviceRecordsQuery = _firestore
            .collection('vehicles')
            .doc(vehicleDoc.id)
            .collection('service_records');

        // Apply time filter if not "All Time"
        if (_selectedTimeFilter != 'All Time') {
          serviceRecordsQuery = serviceRecordsQuery.where(
            'serviceDate',
            isGreaterThanOrEqualTo: filterStartDate
          );
        }

        QuerySnapshot serviceRecordsSnapshot = await serviceRecordsQuery.get();

        for (var serviceDoc in serviceRecordsSnapshot.docs) {
          Map<String, dynamic> serviceData = serviceDoc.data() as Map<String, dynamic>;

          // Additional date check for documents that might have different date field names
          DateTime? serviceDate;
          if (serviceData['serviceDate'] != null) {
            if (serviceData['serviceDate'] is Timestamp) {
              serviceDate = (serviceData['serviceDate'] as Timestamp).toDate();
            } else if (serviceData['serviceDate'] is String) {
              try {
                serviceDate = DateTime.parse(serviceData['serviceDate']);
              } catch (e) {
                // If parsing fails, skip this record for time filtering
                serviceDate = null;
              }
            }
          }

          // Skip if we have a date filter but no valid service date
          if (_selectedTimeFilter != 'All Time' && serviceDate != null && serviceDate.isBefore(filterStartDate)) {
            continue;
          }

          List<dynamic> parts = serviceData['parts'] ?? [];

          for (var part in parts) {
            String partNameRaw = part['name'] ?? '';
            String partName = partNameRaw.trim().toLowerCase();
            int quantity = 1; // Default quantity if not specified

            // Try to get quantity from various possible fields
            if (part['quantity'] != null) {
              quantity = int.tryParse(part['quantity'].toString()) ?? 1;
            } else if (part['qty'] != null) {
              quantity = int.tryParse(part['qty'].toString()) ?? 1;
            }

            if (partName.isEmpty) continue;

            partUsageMap[partName] = (partUsageMap[partName] ?? 0) + quantity;
            totalPartsUsed += quantity;
          }
        }
      }

      // Build topUsedParts with usage, stock, and category, and utilization
      List<Map<String, dynamic>> partsUsage = [];
      partUsageMap.forEach((partNameNormalized, usedCount) {
        Map<String, dynamic>? inventory = inventoryMap[partNameNormalized];
        String partNameRaw = inventory != null ? (inventory['name'] ?? partNameNormalized) : partNameNormalized;
        final isMissing = inventory == null;
        final currentStock = !isMissing ? (inventory['quantity'] ?? 0) : 0;
        final category = !isMissing ? (inventory['category'] ?? '-') : '-';
        double utilizationRate;
        String utilizationLabel;
        if (isMissing) {
          utilizationRate = 100.0;
          utilizationLabel = 'Not in inventory';
        } else if (currentStock == 0) {
          utilizationRate = 100.0;
          utilizationLabel = 'Out of stock';
        } else {
          utilizationRate = (usedCount + currentStock) > 0 ? (usedCount / (usedCount + currentStock)) * 100 : 0.0;
          utilizationLabel = '${utilizationRate.toStringAsFixed(1)}%';
        }
        partsUsage.add({
          'partName': partNameRaw,
          'usedCount': usedCount,
          'category': category,
          'currentStock': currentStock,
          'utilizationRate': utilizationRate,
          'utilizationLabel': utilizationLabel,
          'inventoryMissing': isMissing,
        });
      });
      partsUsage.sort((a, b) => b['usedCount'].compareTo(a['usedCount']));

      // Build category analytics
      Map<String, Map<String, dynamic>> categoryAnalyticsMap = {};
      Map<String, double> utilizationPercentagesMap = {};
      categoryPartsMap.forEach((category, partsList) {
        int totalCategoryParts = partsList.length;
        int lowStockParts = 0;
        int requestedParts = 0;
        int totalCategoryStock = 0;
        int totalCategoryUsed = 0;
        for (var part in partsList) {
          String normalizedName = part['normalizedName'] ?? '';
          int stock = part['quantity'] ?? 0;
          int threshold = part['lowStockThreshold'] ?? 0;
          int used = partUsageMap[normalizedName] ?? 0;
          totalCategoryStock += stock;
          totalCategoryUsed += used;
          if (stock <= threshold) lowStockParts++;
          if (used > 0) requestedParts++;
        }
        double utilizationRate = (totalCategoryUsed + totalCategoryStock) > 0 ? (totalCategoryUsed / (totalCategoryUsed + totalCategoryStock)) * 100 : 0.0;
        categoryAnalyticsMap[category] = {
          'totalParts': totalCategoryParts,
          'usedParts': totalCategoryUsed,
          'lowStockParts': lowStockParts,
          'requestedParts': requestedParts,
          'utilizationRate': utilizationRate,
        };
        utilizationPercentagesMap[category] = utilizationRate;
      });

      setState(() {
        topUsedParts = partsUsage.take(10).toList();
        totalUsedCount = totalPartsUsed;
        totalPartsCount = totalParts;
        categoryAnalytics = categoryAnalyticsMap;
        utilizationPercentages = utilizationPercentagesMap;
        _applyFilters();
        _isLoading = false;
      });

      print('✅ Analytics data updated with time filter "$_selectedTimeFilter": Total Parts: $totalParts, Total Used: $totalPartsUsed');

    } catch (e) {
      print('❌ Error fetching filtered analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Flexible(
          child: Text(
            'Spare Parts Analytics',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Usage Charts',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Tab(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Top Parts',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [

          _buildChartsTab(),
          _buildTopPartsTab(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownTableAll() {
    final categoryNames = categoryAnalytics.keys.toList();
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 600), // Ensure minimum width for table
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 48,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 14,
            ),
            columns: const [
              DataColumn(label: Text('Category', overflow: TextOverflow.ellipsis)),
              DataColumn(label: Text('Total', overflow: TextOverflow.ellipsis)),
              DataColumn(label: Text('Used', overflow: TextOverflow.ellipsis)),
              DataColumn(label: Text('Low Stock', overflow: TextOverflow.ellipsis)),
              DataColumn(label: Text('Requested', overflow: TextOverflow.ellipsis)),
              DataColumn(label: Text('Utilization', overflow: TextOverflow.ellipsis)),
            ],
            rows: categoryNames.map((cat) {
              final data = categoryAnalytics[cat];
              final hasParts = (data != null && (data['totalParts'] ?? 0) > 0);
              return DataRow(cells: [
                DataCell(Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataCell(Text(hasParts ? data['totalParts'].toString() : '-', style: TextStyle(fontSize: 13))),
                DataCell(Text(hasParts ? data['usedParts'].toString() : '-', style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w600))),
                DataCell(Text(hasParts ? data['lowStockParts'].toString() : '-', style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w600))),
                DataCell(Text(hasParts ? data['requestedParts'].toString() : '-', style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w600))),
                DataCell(Text(hasParts ? '${data['utilizationRate'].toStringAsFixed(1)}%' : '-', style: TextStyle(fontSize: 13, color: hasParts ? _getUtilizationColor(data['utilizationRate']) : Colors.grey, fontWeight: FontWeight.w600))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnalyticsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Breakdown (tables only) with export button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category Breakdown (Table)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: categoryAnalytics.isNotEmpty ? _exportCategoryBreakdownToPDF : null,
                  icon: Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Time Filter for Category Breakdown Table
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: _selectedTimeFilter,
                decoration: InputDecoration(
                  labelText: 'Time Filter',
                  prefixIcon: Icon(Icons.filter_list, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _timeFilterOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeFilter = newValue;
                      // Apply time filtering to category analytics
                      _applyTimeFilterToCategoryAnalytics();
                    });
                  }
                },
              ),
            ),

            SizedBox(height: 16),
            _buildCategoryBreakdownTableAll(),
            SizedBox(height: 24),
            // Usage Chart (at the very bottom)
            Text(
              'Usage by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildUsageChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownTable(String categoryName) {
    // Find all parts in this category
    final parts = topUsedParts.where((part) => part['category'] == categoryName).toList();
    if (parts.isEmpty) {
      return Container(
        margin: EdgeInsets.only(bottom: 24),
        child: Text('No parts found for $categoryName', style: TextStyle(color: Colors.grey)),
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$categoryName Parts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 48,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontSize: 14,
              ),
              columns: const [
                DataColumn(label: Text('Part Name', overflow: TextOverflow.ellipsis)),
                DataColumn(label: Text('Used', overflow: TextOverflow.ellipsis)),
                DataColumn(label: Text('Stock', overflow: TextOverflow.ellipsis)),
                DataColumn(label: Text('Utilization', overflow: TextOverflow.ellipsis)),
              ],
              rows: parts.map((part) {
                return DataRow(cells: [
                  DataCell(Container(width: 120, child: Text(part['partName'].toString(), overflow: TextOverflow.ellipsis, maxLines: 2, style: TextStyle(fontSize: 13)))),
                  DataCell(Text(part['usedCount'].toString(), style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w600))),
                  DataCell(Text(part['currentStock'].toString(), style: TextStyle(fontSize: 13, color: Colors.blue[700], fontWeight: FontWeight.w600))),
                  DataCell(Text('${part['utilizationRate'].toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, color: _getUtilizationColor(part['utilizationRate']), fontWeight: FontWeight.w600))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsedPartsTable() {
    if (topUsedParts.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No usage data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        headingRowHeight: 48,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          fontSize: 14,
        ),
        columns: const [
          DataColumn(
            label: Text('Part Name', overflow: TextOverflow.ellipsis),
          ),
          DataColumn(
            label: Text('Category', overflow: TextOverflow.ellipsis),
          ),
          DataColumn(
            label: Text('Used', overflow: TextOverflow.ellipsis),
          ),
          DataColumn(
            label: Text('Stock', overflow: TextOverflow.ellipsis),
          ),
        ],
        rows: topUsedParts.map((part) {
          return DataRow(cells: [
            DataCell(
              Container(
                width: 120,
                child: Text(
                  part['partName'].toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            DataCell(
              Container(
                width: 80,
                child: Text(
                  part['category'].toString(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            DataCell(
              Text(
                part['usedCount'].toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
            DataCell(
              Text(
                part['currentStock'].toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTopPartsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Most Used Spare Parts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Filter bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              // Time Filter Dropdown
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeFilter,
                  decoration: InputDecoration(
                    labelText: 'Time Filter',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: _timeFilterOptions.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTimeFilter = val!;
                      _applyFilters();
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              // Sort By Dropdown
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedSortOrder,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: _sortOrderOptions.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSortOrder = val!;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredTopUsedParts.isEmpty
              ? Center(child: Text('No usage data available'))
              : ListView.builder(
                  itemCount: filteredTopUsedParts.length,
                  itemBuilder: (context, index) {
                    final part = filteredTopUsedParts[index];
                    return _buildTopPartCard(part, index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(MapEntry<String, Map<String, dynamic>> entry) {
    final categoryName = entry.key;
    final data = entry.value;
    final utilizationRate = data['utilizationRate'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUtilizationColor(utilizationRate).withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${utilizationRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getUtilizationColor(utilizationRate),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('Total', data['totalParts'].toString(), Colors.blue)),
                        SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('Used', data['usedParts'].toString(), Colors.green)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('Low Stock', data['lowStockParts'].toString(), Colors.orange)),
                        SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('Requested', data['requestedParts'].toString(), Colors.red)),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildMiniStat('Total', data['totalParts'].toString(), Colors.blue)),
                    Expanded(child: _buildMiniStat('Used', data['usedParts'].toString(), Colors.green)),
                    Expanded(child: _buildMiniStat('Low Stock', data['lowStockParts'].toString(), Colors.orange)),
                    Expanded(child: _buildMiniStat('Requested', data['requestedParts'].toString(), Colors.red)),
                  ],
                );
              }
            },
          ),

          SizedBox(height: 12),

          // Utilization Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: (utilizationRate / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: _getUtilizationColor(utilizationRate),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTopPartCard(Map<String, dynamic> part, int rank) {
    final utilizationRate = part['utilizationRate'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // Part Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part['partName'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                Text(
                  part['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      'Used: ${part['usedCount']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Stock: ${part['currentStock']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Utilization Rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${utilizationRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getUtilizationColor(utilizationRate),
                ),
              ),
              Text(
                'Utilization',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    if (categoryAnalytics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxUsage = categoryAnalytics.values
        .map((data) => data['usedParts'] as int)
        .fold(0, (max, current) => current > max ? current : max);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: categoryAnalytics.entries.map((entry) {
          final usedParts = entry.value['usedParts'] as int;
          final height = maxUsage > 0 ? (usedParts / maxUsage) * 150 : 10.0;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$usedParts',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: 36,
                  height: height.clamp(10.0, 150.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 60,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getUtilizationColor(double percentage) {
    if (percentage >= 80) return Colors.red;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.yellow[700]!;
    if (percentage >= 20) return Colors.green;
    return Colors.blue;
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.orange;
    if (rank <= 6) return Colors.blue;
    return Colors.grey;
  }

  Future<void> _exportCategoryBreakdownToPDF() async {
    try {
      final pdf = pw.Document();

      // Get current date for the report
      final DateTime now = DateTime.now();
      final String currentDate = '${now.day}/${now.month}/${now.year}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Spare Parts Analytics Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Category Breakdown Analysis',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on: $currentDate',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary Statistics
                pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 20),
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Categories: ${categoryAnalytics.length}'),
                          pw.Text('Total Parts Count: $totalPartsCount'),
                          pw.Text('Total Parts Used: $totalUsedCount'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category Breakdown Table
                pw.Text(
                  'Category Breakdown Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  headers: ['Category', 'Total', 'Used', 'Low Stock', 'Requested', 'Utilization'],
                  data: categoryAnalytics.entries.map((entry) {
                    final categoryName = entry.key;
                    final data = entry.value;
                    final hasParts = (data['totalParts'] ?? 0) > 0;

                    return [
                      categoryName,
                      hasParts ? data['totalParts'].toString() : '-',
                      hasParts ? data['usedParts'].toString() : '-',
                      hasParts ? data['lowStockParts'].toString() : '-',
                      hasParts ? data['requestedParts'].toString() : '-',
                      hasParts ? '${data['utilizationRate'].toStringAsFixed(1)}%' : '-',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                    5: pw.Alignment.center,
                  },
                ),

                pw.SizedBox(height: 20),

                // Footer
                pw.Container(
                  margin: pw.EdgeInsets.only(top: 20),
                  child: pw.Text(
                    'Note: This report shows the current state of spare parts inventory and usage analytics.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Show PDF preview and print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Spare_Parts_Category_Breakdown_$currentDate.pdf',
      );

    } catch (e) {
      print('❌ Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

