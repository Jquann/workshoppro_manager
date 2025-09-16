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
      QuerySnapshot categorySnapshot = await _firestore.collection('inventory_parts').get();
      Map<String, Map<String, dynamic>> analytics = {};
      Map<String, double> utilization = {};
      List<Map<String, dynamic>> partsUsage = [];
      int totalParts = 0;
      int totalUsed = 0;

      for (var categoryDoc in categorySnapshot.docs) {
        String categoryName = categoryDoc.id;
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;

        int categoryTotal = 0;
        int categoryUsed = 0;
        int categoryLowStock = 0;
        int categoryRequested = 0;

        data.forEach((partName, partData) {
          if (partData is Map<String, dynamic>) {
            categoryTotal++;
            totalParts++;

            int quantity = partData['quantity'] ?? 0;
            int originalQuantity = partData['originalQuantity'] ?? quantity;
            bool isLowStock = partData['isLowStock'] ?? false;
            bool isRequested = partData['isRequested'] ?? false;

            int usedCount = originalQuantity - quantity;
            if (usedCount > 0) {
              categoryUsed += usedCount;
              totalUsed += usedCount;

              // Add to parts usage list
              partsUsage.add({
                'partName': partName,
                'category': categoryName,
                'usedCount': usedCount,
                'totalCount': originalQuantity,
                'currentStock': quantity,
                'utilizationRate': originalQuantity > 0 ? (usedCount / originalQuantity) * 100 : 0,
              });
            }

            if (isLowStock) categoryLowStock++;
            if (isRequested) categoryRequested++;
          }
        });

        analytics[categoryName] = {
          'totalParts': categoryTotal,
          'usedParts': categoryUsed,
          'lowStockParts': categoryLowStock,
          'requestedParts': categoryRequested,
          'utilizationRate': categoryTotal > 0 ? (categoryUsed / categoryTotal) * 100 : 0,
        };

        utilization[categoryName] = categoryTotal > 0 ? (categoryUsed / categoryTotal) * 100 : 0;
      }

      // Sort parts by usage count
      partsUsage.sort((a, b) => b['usedCount'].compareTo(a['usedCount']));

      setState(() {
        categoryAnalytics = analytics;
        utilizationPercentages = utilization;
        topUsedParts = partsUsage.take(10).toList();
        totalPartsCount = totalParts;
        totalUsedCount = totalUsed;
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
            // Summary Cards
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
            SizedBox(height: 16),

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
              height: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildUtilizationChart(),
            ),
            SizedBox(height: 24),

            // Parts Distribution Pie Chart
            Text(
              'Parts Distribution',
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
              child: _buildDistributionChart(),
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
              height: 200,
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
                Text(
                  'Most Used Spare Parts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
            color: Colors.grey.withOpacity(0.1),
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
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUtilizationColor(utilizationRate).withOpacity(0.2),
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

          Row(
            children: [
              Expanded(
                child: _buildMiniStat('Total', data['totalParts'].toString(), Colors.blue),
              ),
              Expanded(
                child: _buildMiniStat('Used', data['usedParts'].toString(), Colors.green),
              ),
              Expanded(
                child: _buildMiniStat('Low Stock', data['lowStockParts'].toString(), Colors.orange),
              ),
              Expanded(
                child: _buildMiniStat('Requested', data['requestedParts'].toString(), Colors.red),
              ),
            ],
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
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
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
            color: Colors.grey.withOpacity(0.1),
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
                ),
                Text(
                  part['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Used: ${part['usedCount']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
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
      return Center(child: Text('No data available'));
    }
    final sortedEntries = utilizationPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedEntries.map((entry) {
          final percentage = entry.value;
          final height = (percentage / 100) * 120;
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
                  height: height.clamp(10.0, 120.0),
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

  Widget _buildDistributionChart() {
    if (categoryAnalytics.isEmpty) {
      return Center(child: Text('No data available'));
    }
    return Column(
      children: [
        Container(
          height: 120,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: _getPieChartColors(),
                  stops: _getPieChartStops(),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categoryAnalytics.entries.map((entry) {
              final index = categoryAnalytics.keys.toList().indexOf(entry.key);
              final color = _getCategoryColor(index);
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      entry.key,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageChart() {
    if (categoryAnalytics.isEmpty) {
      return Center(child: Text('No data available'));
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
          final height = maxUsage > 0 ? (usedParts / maxUsage) * 120 : 10.0;
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
                  height: height.clamp(10.0, 120.0),
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

  List<Color> _getPieChartColors() {
    return categoryAnalytics.entries.map((entry) {
      final index = categoryAnalytics.keys.toList().indexOf(entry.key);
      return _getCategoryColor(index);
    }).toList();
  }

  List<double> _getPieChartStops() {
    final total = categoryAnalytics.values
        .map((data) => data['totalParts'] as int)
        .fold(0, (sum, current) => sum + current);

    if (total == 0) return [1.0];

    double currentStop = 0.0;
    return categoryAnalytics.values.map((data) {
      final percentage = (data['totalParts'] as int) / total;
      currentStop += percentage;
      return currentStop;
    }).toList();
  }

  double _calculateAverageUtilization() {
    if (utilizationPercentages.isEmpty) return 0.0;
    final sum = utilizationPercentages.values.fold(0.0, (sum, value) => sum + value);
    return sum / utilizationPercentages.length;
  }
}
