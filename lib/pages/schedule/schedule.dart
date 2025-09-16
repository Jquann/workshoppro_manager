import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_model.dart';
import 'add_schedule.dart';
import 'schedule_detail.dart';

class SchedulePage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SchedulePage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with TickerProviderStateMixin {
  static const _kPrimary = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kSurface = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  
  // Date range selection
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  // Filter options
  String _selectedStatusFilter = 'all'; // all, scheduled, in_progress, completed, cancelled
  final List<String> _statusOptions = [
    'all',
    'scheduled', 
    'in_progress',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with today's date
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () => _navigateToAddSchedule(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, c) {
                const base = 375.0;
                final s = (c.maxWidth / base).clamp(0.95, 1.15);
                return Column(
                  children: [
                    // Date Range Selector (like search box)
                    Container(
                      margin: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 10 * s),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kDivider.withOpacity(0.5)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showDateRangePicker,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _kGrey,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getDateRangeText(),
                                  style: TextStyle(
                                    fontSize: (14 * s).clamp(13, 16),
                                    color: _kGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: _kGrey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Search Box
                    Container(
                      margin: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 16 * s),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kDivider.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search schedules, customers, services...',
                          hintStyle: TextStyle(
                            color: _kGrey,
                            fontSize: (14 * s).clamp(13, 16),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: _kGrey,
                            size: 20,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: _kGrey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * s,
                            vertical: 16 * s,
                          ),
                        ),
                      ),
                    ),

                    // Status Filter Chips
                    Container(
                      margin: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusOptions.length,
                        itemBuilder: (context, index) {
                          final status = _statusOptions[index];
                          final isSelected = _selectedStatusFilter == status;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                _getStatusDisplayName(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : _kGrey,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: _getStatusColor(status),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? _getStatusColor(status) : Colors.grey.shade300,
                                width: 1,
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        },
                      ),
                    ),

                    // Schedule List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _getSchedulesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: _kPrimary),
                            );
                          }

                          final schedules = snapshot.data?.docs ?? [];
                          final filteredSchedules = _filterSchedules(schedules);

                          // 区分两种空状态：完全没有数据 vs 过滤后没有结果
                          if (schedules.isEmpty) {
                            // 完全没有调度数据，显示添加按钮
                            return _buildEmptyState();
                          } else if (filteredSchedules.isEmpty) {
                            // 有数据但过滤后为空，显示过滤结果为空的提示
                            return _buildNoFilterResultsState();
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16 * s),
                            itemCount: filteredSchedules.length,
                            itemBuilder: (context, index) {
                              final schedule = ScheduleModel.fromFirestore(
                                filteredSchedules[index].data() as Map<String, dynamic>,
                                filteredSchedules[index].id,
                              );
                              return _buildScheduleCard(schedule, s);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule, double s) {
    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleDetailPage(scheduleId: schedule.id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16 * s),
          child: Row(
            children: [
              // Service Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getServiceColor(schedule.serviceType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getServiceIcon(schedule.serviceType),
                  color: _getServiceColor(schedule.serviceType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Schedule Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: TextStyle(
                        fontSize: (16 * s).clamp(15, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: (14 * s).clamp(13, 16),
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (schedule.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        schedule.customerName!,
                        style: TextStyle(
                          fontSize: (13 * s).clamp(12, 15),
                          color: _kGrey,
                        ),
                      ),
                    ],
                    if (schedule.vehicleId != null) ...[
                      const SizedBox(height: 2),
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('vehicles').doc(schedule.vehicleId).get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final vehicleData = snapshot.data!.data() as Map<String, dynamic>;
                            final make = vehicleData['make'] ?? '';
                            final model = vehicleData['model'] ?? '';
                            final carPlate = vehicleData['carPlate'] ?? '';
                            return Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 12,
                                  color: _kGrey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$make $model ($carPlate)',
                                    style: TextStyle(
                                      fontSize: (12 * s).clamp(11, 14),
                                      color: _kGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(schedule.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(schedule.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(schedule.status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: _kGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding a new schedule',
            style: TextStyle(
              fontSize: 14,
              color: _kGrey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddSchedule,
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: _kGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules match your filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your date range or status filter',
            style: TextStyle(
              fontSize: 14,
              color: _kGrey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedStatusFilter = 'all';
                searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Date picker methods
  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _getDateRangeText() {
    if (_startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day) {
      return '${_startDate.day}/${_startDate.month}/${_startDate.year}';
    } else {
      return '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}';
    }
  }

  Stream<QuerySnapshot> _getSchedulesStream() {
    // Use the selected date range
    DateTime startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    DateTime endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    return _firestore
        .collection('schedules')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startTime', descending: true) // 改为倒序：从新到旧
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterSchedules(List<QueryDocumentSnapshot> schedules) {
    return schedules.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final schedule = ScheduleModel.fromFirestore(data, doc.id);

      // Filter by status
      if (_selectedStatusFilter != 'all' && schedule.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
        return false;
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!schedule.title.toLowerCase().contains(query) &&
            !(schedule.customerName?.toLowerCase().contains(query) ?? false) &&
            !schedule.serviceType.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'oil change':
        return Icons.oil_barrel;
      case 'tire rotation':
        return Icons.tire_repair;
      case 'brake inspection':
        return Icons.car_crash;
      case 'lunch break':
        return Icons.restaurant;
      case 'engine tune-up':
        return Icons.build;
      case 'transmission service':
        return Icons.settings;
      default:
        return Icons.build;
    }
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'oil change':
        return Colors.orange;
      case 'tire rotation':
        return Colors.blue;
      case 'brake inspection':
        return Colors.red;
      case 'lunch break':
        return Colors.green;
      case 'engine tune-up':
        return Colors.purple;
      case 'transmission service':
        return Colors.teal;
      default:
        return _kPrimary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return _kPrimary;
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return _kGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'All';
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _navigateToAddSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSchedulePage(),
      ),
    );
  }
}