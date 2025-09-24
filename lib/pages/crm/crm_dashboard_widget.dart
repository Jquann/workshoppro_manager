import 'package:flutter/material.dart';
import '../../models/communication_model.dart';
import '../../services/communication_service.dart';
import 'communication_history.dart';
import 'customer_interactions.dart';

class CRMDashboardWidget extends StatefulWidget {
  const CRMDashboardWidget({Key? key}) : super(key: key);

  @override
  _CRMDashboardWidgetState createState() => _CRMDashboardWidgetState();
}

class _CRMDashboardWidgetState extends State<CRMDashboardWidget> with SingleTickerProviderStateMixin {
  final CommunicationService _communicationService = CommunicationService();
  bool _isExpanded = false;
  late AnimationController _animationController;
  
  // UI Colors
  static const _kPrimary = Color(0xFF007AFF);
  static const _kWarning = Color(0xFFFF9500);
  static const _kError = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return StreamBuilder<List<CommunicationModel>>(
      stream: _communicationService.getAllCommunications(),
      builder: (context, snapshot) {
        Map<String, int> stats = {
          'total': 0,
          'pending': 0,
          'followUp': 0,
        };

        if (snapshot.hasData) {
          final communications = snapshot.data!;
          stats['total'] = communications.length;
          
          for (var comm in communications) {
            if (comm.status == CommunicationStatus.pending) {
              stats['pending'] = stats['pending']! + 1;
            }
            if (comm.status == CommunicationStatus.followUp) {
              stats['followUp'] = stats['followUp']! + 1;
            }
          }
        }

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Header with collapse/expand button
                  Row(
                    children: [
                      Icon(Icons.headset_mic, color: _kPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CRM Communications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Compact stats
                  Row(
                    children: [
                      _buildCompactStatCard(
                        title: 'Total',
                        value: '${stats['total']}',
                        icon: Icons.chat_bubble_outline,
                        color: _kPrimary,
                        onTap: () => _navigateToInteractions(),
                      ),
                      const SizedBox(width: 6),
                      _buildCompactStatCard(
                        title: 'Pending',
                        value: '${stats['pending']}',
                        icon: Icons.schedule,
                        color: _kWarning,
                        onTap: () => _navigateToInteractions(),
                      ),
                      const SizedBox(width: 6),
                      _buildCompactStatCard(
                        title: 'Follow-ups',
                        value: '${stats['followUp']}',
                        icon: Icons.follow_the_signs,
                        color: _kError,
                        onTap: () => _navigateToInteractions(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToInteractions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerInteractionsPage(),
      ),
    );
  }

  Widget _buildCompactRecentCommunications() {
    return StreamBuilder<List<CommunicationModel>>(
      stream: _communicationService.getRecentCommunications(days: 3),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Error loading communications',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Loading...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.chat_outlined, color: Colors.grey[400], size: 16),
                const SizedBox(width: 8),
                Text(
                  'No recent communications',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final recentCommunications = snapshot.data!.take(2).toList();

        return Column(
          children: [
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600], size: 14),
                const SizedBox(width: 6),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _navigateToInteractions(),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentCommunications.map((comm) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunicationHistoryPage(
                        customerId: comm.customerId,
                        customerName: comm.customerName,
                        customerPhone: comm.phoneNumber,
                        customerEmail: comm.emailAddress,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getTypeColor(comm.type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getTypeIcon(comm.type),
                          color: _getTypeColor(comm.type),
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comm.subject,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Text(
                                  comm.customerName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  comm.getFormattedDate(includeTime: false),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Color _getTypeColor(CommunicationType type) {
    switch (type) {
      case CommunicationType.phone:
        return Colors.green;
      case CommunicationType.email:
        return Colors.blue;
      case CommunicationType.sms:
        return Colors.purple;
      case CommunicationType.meeting:
        return Colors.orange;
      case CommunicationType.note:
        return Colors.grey;
      case CommunicationType.followUp:
        return _kWarning;
      case CommunicationType.complaint:
        return _kError;
      case CommunicationType.inquiry:
        return _kPrimary;
      case CommunicationType.other:
        return Colors.brown;
    }
  }

  IconData _getTypeIcon(CommunicationType type) {
    switch (type) {
      case CommunicationType.phone:
        return Icons.phone;
      case CommunicationType.email:
        return Icons.email;
      case CommunicationType.sms:
        return Icons.sms;
      case CommunicationType.meeting:
        return Icons.meeting_room;
      case CommunicationType.note:
        return Icons.note;
      case CommunicationType.followUp:
        return Icons.follow_the_signs;
      case CommunicationType.complaint:
        return Icons.report_problem;
      case CommunicationType.inquiry:
        return Icons.help;
      case CommunicationType.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsed header (always visible)
        _buildCollapsedHeader(),
        
        // Expanded content (only visible when expanded)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded 
            ? Container(
                margin: const EdgeInsets.only(top: 8),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildCompactRecentCommunications(),
                  ),
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }
}