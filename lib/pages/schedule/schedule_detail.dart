import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_model.dart';
import 'add_schedule.dart';

class ScheduleDetailPage extends StatefulWidget {
  final String scheduleId;

  const ScheduleDetailPage({Key? key, required this.scheduleId}) : super(key: key);

  @override
  _ScheduleDetailPageState createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDarkText = Color(0xFF1C1C1E);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('schedules').doc(widget.scheduleId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Schedule not found'));
          }

          final schedule = ScheduleModel.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  child: Material(
                    color: _kLightGrey,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _kDarkText,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: _kDarkText),
                    onPressed: () => _navigateToEditSchedule(schedule),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: _kError),
                    onPressed: () => _showDeleteConfirmation(schedule),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text(
                    'Schedule Details',
                    style: TextStyle(
                      color: _kDarkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          _kLightGrey.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildScheduleHeader(schedule),
                      const SizedBox(height: 24),
                      _buildScheduleDetails(schedule),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleHeader(ScheduleModel schedule) {
    final startTime = '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getServiceColor(schedule.serviceType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getServiceIcon(schedule.serviceType),
                  color: _getServiceColor(schedule.serviceType),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.serviceType,
                      style: TextStyle(
                        fontSize: 14,
                        color: _kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(schedule.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(schedule.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(schedule.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${schedule.startTime.day}/${schedule.startTime.month}/${schedule.startTime.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetails(ScheduleModel schedule) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 16),
          if (schedule.description.isNotEmpty) ...[
            _buildDetailItem('Description', schedule.description),
            const SizedBox(height: 16),
          ],
          if (schedule.customerName != null) ...[
            _buildDetailItem('Customer', schedule.customerName!),
            const SizedBox(height: 16),
          ],
          if (schedule.vehicleId != null) ...[
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('vehicles').doc(schedule.vehicleId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final vehicleData = snapshot.data!.data() as Map<String, dynamic>;
                  final make = vehicleData['make'] ?? '';
                  final model = vehicleData['model'] ?? '';
                  final plateNumber = vehicleData['plateNumber'] ?? '';
                  final year = vehicleData['year'] ?? '';
                  final vehicleInfo = '$year $make $model ($plateNumber)';
                  return Column(
                    children: [
                      _buildDetailItem('Vehicle', vehicleInfo),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ],
          if (schedule.mechanicName != null) ...[
            _buildDetailItem('Mechanic', schedule.mechanicName!),
            const SizedBox(height: 16),
          ],
          _buildDetailItem('Status', _getStatusText(schedule.status)),
          const SizedBox(height: 16),
          _buildDetailItem('Created', _formatDateTime(schedule.createdAt)),
          if (schedule.updatedAt != schedule.createdAt) ...[
            const SizedBox(height: 16),
            _buildDetailItem('Updated', _formatDateTime(schedule.updatedAt)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kGrey,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kDarkText,
            ),
          ),
        ),
      ],
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEditSchedule(ScheduleModel schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSchedulePage(schedule: schedule),
      ),
    );
  }

  void _showDeleteConfirmation(ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: Text('Are you sure you want to delete "${schedule.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSchedule(schedule.id);
              },
              style: TextButton.styleFrom(foregroundColor: _kError),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule deleted successfully'),
          backgroundColor: _kSuccess,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete schedule: $e'),
          backgroundColor: _kError,
        ),
      );
    }
  }
}