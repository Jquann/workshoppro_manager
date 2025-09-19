import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_model.dart';
import 'add_schedule.dart';
import '../vehicles/add_service.dart';
import '../vehicles/view_service.dart';
import '../../models/service_model.dart';

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
                  // Only show edit and delete icons if status is not completed or cancelled
                  if (schedule.status.toLowerCase() != 'completed' && 
                      schedule.status.toLowerCase() != 'cancelled') ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: _kDarkText),
                      onPressed: () => _navigateToEditSchedule(schedule),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: _kError),
                      onPressed: () => _showDeleteConfirmation(schedule),
                    ),
                  ],
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
            ],
          ),
          const SizedBox(height: 16),
          // Status section with enhanced design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(schedule.status).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(schedule.status).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(schedule.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(schedule.status),
                    color: _getStatusColor(schedule.status),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusText(schedule.status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(schedule.status),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showStatusEditDialog(schedule),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: _kGrey,
                    ),
                  ),
                ),
              ],
            ),
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
                  final plateNumber = vehicleData['carPlate'] ?? vehicleData['plateNumber'] ?? '';
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
          if (schedule.partsCategory != null) ...[
            _buildDetailItem('Parts Category', schedule.partsCategory!),
            const SizedBox(height: 16),
          ],
          _buildDetailItem('Status', _getStatusText(schedule.status)),
          const SizedBox(height: 16),
          _buildDetailItem('Created', _formatDateTime(schedule.createdAt)),
          if (schedule.updatedAt != schedule.createdAt) ...[
            const SizedBox(height: 16),
            _buildDetailItem('Updated', _formatDateTime(schedule.updatedAt)),
          ],
          // Add Service button based on status and service record existence
          if (schedule.status.toLowerCase() == 'scheduled') ...[
            const SizedBox(height: 24),
            FutureBuilder<bool>(
              future: _hasServiceRecords(schedule),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _kPrimary));
                }
                
                final hasRecords = snapshot.data ?? false;
                if (hasRecords) {
                  return _buildViewServiceDetailsButton(schedule);
                } else {
                  return _buildAccessToServiceButton(schedule);
                }
              },
            ),
          ] else if (schedule.status.toLowerCase() == 'in_progress') ...[
            const SizedBox(height: 24),
            _buildViewServiceDetailsButton(schedule),
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

  Widget _buildAccessToServiceButton(ScheduleModel schedule) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, const Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _navigateToAddService(schedule),
        icon: const Icon(Icons.build_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Access to Service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildViewServiceDetailsButton(ScheduleModel schedule) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kSuccess, const Color(0xFF32A852)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kSuccess.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _navigateToViewService(schedule),
        icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 24),
        label: const Text(
          'View Service Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
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

  void _navigateToAddService(ScheduleModel schedule) async {
    // Check if vehicleId exists
    if (schedule.vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle associated with this schedule'),
          backgroundColor: _kError,
        ),
      );
      return;
    }

    // Navigate to AddService without updating schedule status first
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddService(
          vehicleId: schedule.vehicleId!,
          scheduleId: schedule.id,
          customerName: schedule.customerName,
          mechanicName: schedule.mechanicName,
          serviceType: schedule.serviceType,
          partsCategory: schedule.partsCategory,
        ),
      ),
    );

    // Only update schedule status to in_progress if service was successfully saved
    if (result == true) {
      await _updateScheduleStatusSilently(schedule.id, 'in_progress');
    }
  }

  void _navigateToViewService(ScheduleModel schedule) async {
    // Check if vehicleId exists
    if (schedule.vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle associated with this schedule'),
          backgroundColor: _kError,
        ),
      );
      return;
    }

    try {
      // Look for service records for this vehicle that match the schedule criteria
      // Use a simpler query to avoid index requirements
      final serviceSnapshot = await _firestore
          .collection('vehicles')
          .doc(schedule.vehicleId!)
          .collection('service_records')
          .where('description', isEqualTo: schedule.serviceType)
          .get();

      if (serviceSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No service record found for this schedule'),
            backgroundColor: _kError,
          ),
        );
        return;
      }

      // Filter results locally if there are multiple records
      final scheduleDate = schedule.startTime;
      final startOfDay = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 7));
      
      ServiceRecordModel? matchingRecord;
      for (final doc in serviceSnapshot.docs) {
        final serviceData = doc.data();
        final serviceRecord = ServiceRecordModel.fromMap(doc.id, serviceData);
        
        // Check if the service date falls within our time window
        if (serviceRecord.date.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
            serviceRecord.date.isBefore(endOfDay)) {
          matchingRecord = serviceRecord;
          break;
        }
      }
      
      // If no record found in time window, use the first one
      if (matchingRecord == null) {
        final firstDoc = serviceSnapshot.docs.first;
        matchingRecord = ServiceRecordModel.fromMap(firstDoc.id, firstDoc.data());
      }

      // Navigate to ViewService with the found service record
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewService(
            vehicleId: schedule.vehicleId!,
            record: matchingRecord!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load service details: $e'),
          backgroundColor: _kError,
        ),
      );
    }
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

  Future<bool> _showStatusConfirmation(String status) async {
    final bool isCompleted = status == 'completed';
    final String title = isCompleted ? 'Complete Schedule?' : 'Cancel Schedule?';
    final String message = isCompleted 
        ? 'This will mark the schedule as completed. This action cannot be undone.'
        : 'This will mark the schedule as cancelled. This action cannot be undone.';
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? _kSuccess : _kError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isCompleted ? 'Complete' : 'Cancel Schedule'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showStatusEditDialog(ScheduleModel schedule) {
    final List<String> allowedStatuses = ['scheduled', 'in_progress', 'cancelled'];
    String selectedStatus = schedule.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: allowedStatuses.map((status) {
                  return RadioListTile<String>(
                    title: Text(_getStatusText(status)),
                    value: status,
                    groupValue: selectedStatus,
                    activeColor: _kPrimary,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    // Show confirmation for final statuses
                    if (selectedStatus == 'completed' || selectedStatus == 'cancelled') {
                      final confirmed = await _showStatusConfirmation(selectedStatus);
                      if (confirmed) {
                        await _updateScheduleStatus(schedule.id, selectedStatus);
                      }
                    } else {
                      await _updateScheduleStatus(schedule.id, selectedStatus);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess
                  ? Icons.check_circle_rounded
                  : color == _kError
                      ? Icons.error_rounded
                      : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _updateScheduleStatus(String scheduleId, String newStatus) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get the schedule to sync with service records
      final scheduleDoc = await _firestore.collection('schedules').doc(scheduleId).get();
      if (scheduleDoc.exists) {
        final schedule = ScheduleModel.fromFirestore(
          scheduleDoc.data() as Map<String, dynamic>,
          scheduleDoc.id,
        );
        await _syncServiceRecordStatus(schedule, newStatus);
      }
      
      _showSnackBar('Status updated to ${_getStatusText(newStatus)}', _kSuccess);
    } catch (e) {
      _showSnackBar('Failed to update status: $e', _kError);
    }
  }

  Future<void> _updateScheduleStatusSilently(String scheduleId, String newStatus) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get the schedule to sync with service records
      final scheduleDoc = await _firestore.collection('schedules').doc(scheduleId).get();
      if (scheduleDoc.exists) {
        final schedule = ScheduleModel.fromFirestore(
          scheduleDoc.data() as Map<String, dynamic>,
          scheduleDoc.id,
        );
        await _syncServiceRecordStatus(schedule, newStatus);
      }
    } catch (e) {
      _showSnackBar('Failed to update status: $e', _kError);
    }
  }

  Future<bool> _hasServiceRecords(ScheduleModel schedule) async {
    if (schedule.vehicleId == null) return false;
    
    try {
      final serviceSnapshot = await _firestore
          .collection('vehicles')
          .doc(schedule.vehicleId!)
          .collection('service_records')
          .where('description', isEqualTo: schedule.serviceType)
          .limit(1)
          .get();
      
      return serviceSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncServiceRecordStatus(ScheduleModel schedule, String newStatus) async {
    if (schedule.vehicleId == null) return;
    
    try {
      // Convert schedule status to service status
      String serviceStatus;
      switch (newStatus.toLowerCase()) {
        case 'scheduled':
          serviceStatus = 'scheduled';
          break;
        case 'in_progress':
          serviceStatus = 'in progress';
          break;
        case 'completed':
          serviceStatus = 'completed';
          break;
        case 'cancelled':
          serviceStatus = 'cancelled';
          break;
        default:
          serviceStatus = newStatus;
      }

      // Find and update matching service records
      final serviceSnapshot = await _firestore
          .collection('vehicles')
          .doc(schedule.vehicleId!)
          .collection('service_records')
          .where('description', isEqualTo: schedule.serviceType)
          .get();

      // Update all matching service records
      for (final doc in serviceSnapshot.docs) {
        await doc.reference.update({
          'status': serviceStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail - don't disrupt the main operation
      debugPrint('Failed to sync service record status: $e');
    }
  }
}