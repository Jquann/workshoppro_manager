import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int totalPartsCount = 0;
  int totalUsedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      // Fetch part usage from invoices collection
      QuerySnapshot invoiceSnapshot = await _firestore.collection('invoices').get();
      Map<String, int> partUsageMap = {};
      int totalPartsUsed = 0;
      for (var invoiceDoc in invoiceSnapshot.docs) {
        Map<String, dynamic> data = invoiceDoc.data() as Map<String, dynamic>;
        List<dynamic> parts = data['parts'] ?? [];
        for (var part in parts) {
          String partNameRaw = part['name'] ?? '';
          String partName = partNameRaw.trim().toLowerCase();
          int quantity = part['quantity'] ?? 0;
          if (partName.isEmpty) continue;
          partUsageMap[partName] = (partUsageMap[partName] ?? 0) + quantity;
          totalPartsUsed += quantity;
        }
      }

      // Build topUsedParts with usage, stock, and category, and utilization
      List<Map<String, dynamic>> partsUsage = [];
      partUsageMap.forEach((partNameNormalized, usedCount) {
        Map<String, dynamic>? inventory = inventoryMap[partNameNormalized];
        String partNameRaw = inventory != null ? (inventory['name'] ?? partNameNormalized) : partNameNormalized;
        final isMissing = inventory == null;
        final currentStock = !isMissing ? (inventory['quantity'] ?? 0) : 0;
        final category = !isMissing ? inventory['category'] ?? '-' : '-';
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
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching analytics data: $e');
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
        title: Text(
          'Spare Parts Analytics',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
          isScrollable: true, // Add scrollable tabs for better responsiveness
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Usage Charts'),
            Tab(text: 'Top Parts'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildTopPartsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnalyticsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards - Improved responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile layout - stack cards vertically
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Parts',
                              totalPartsCount.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Parts Used',
                              totalUsedCount.toString(),
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Categories',
                              categoryAnalytics.length.toString(),
                              Icons.category,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Avg Utilization',
                              '${_calculateAverageUtilization().toStringAsFixed(1)}%',
                              Icons.percent,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Tablet/Desktop layout - single row
                  return Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Total Parts', totalPartsCount.toString(), Icons.inventory, Colors.blue)),
                      SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Parts Used', totalUsedCount.toString(), Icons.trending_up, Colors.green)),
                      SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Categories', categoryAnalytics.length.toString(), Icons.category, Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Avg Utilization', '${_calculateAverageUtilization().toStringAsFixed(1)}%', Icons.percent, Colors.purple)),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 24),

            // Category Breakdown
            Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),

            ...categoryAnalytics.entries.map((entry) => _buildCategoryCard(entry)),
          ],
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
            // Utilization Chart
            Text(
              'Utilization Rates by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 250, // Increased height for better visibility
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildUtilizationChart(),
            ),
            SizedBox(height: 24),

            // Top Used Parts Table
            Text(
              'Top Used Spare Parts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildTopUsedPartsTable(),
            ),
            SizedBox(height: 24),

            // Usage Trend
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
              height: 250, // Increased height for better visibility
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
      child: Container(
        width: MediaQuery.of(context).size.width > 600
            ? MediaQuery.of(context).size.width - 64
            : null,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 48,
          dataRowHeight: 56,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 14,
          ),
          columns: const [
            DataColumn(
              label: Expanded(
                child: Text('Part Name', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Category', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Used', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Stock', overflow: TextOverflow.ellipsis),
              ),
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
      ),
    );
  }

  Widget _buildTopPartsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnalyticsData,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Most Used Spare Parts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: topUsedParts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No usage data available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: topUsedParts.length,
                    itemBuilder: (context, index) {
                      final part = topUsedParts[index];
                      return _buildTopPartCard(part, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                // Mobile layout - stack mini stats vertically
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
                // Desktop layout - single row
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

  Widget _buildUtilizationChart() {
    if (utilizationPercentages.isEmpty) {
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

    final sortedEntries = utilizationPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedEntries.map((entry) {
          final percentage = entry.value;
          final height = (percentage / 100) * 150; // Increased chart height
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getUtilizationColor(percentage),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: 36,
                  height: height.clamp(10.0, 150.0),
                  decoration: BoxDecoration(
                    color: _getUtilizationColor(percentage),
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

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }


  double _calculateAverageUtilization() {
    if (utilizationPercentages.isEmpty) return 0.0;
    final sum = utilizationPercentages.values.fold(0.0, (sum, value) => sum + value);
    return sum / utilizationPercentages.length;
  }
}
