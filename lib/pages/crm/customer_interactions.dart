import 'package:flutter/material.dart';
import '../../models/communication_model.dart';
import '../../services/communication_service.dart';
import 'communication_history.dart';
import 'customer_profile.dart';

class CustomerInteractionsPage extends StatefulWidget {
  const CustomerInteractionsPage({Key? key}) : super(key: key);

  @override
  _CustomerInteractionsPageState createState() => _CustomerInteractionsPageState();
}

class _CustomerInteractionsPageState extends State<CustomerInteractionsPage> {
  final CommunicationService _communicationService = CommunicationService();
  String _searchQuery = '';
  CommunicationStatus? _filterStatus;
  
  // UI Colors
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kWarning = Color(0xFFFF9500);

  Color _getStatusColor(CommunicationStatus status) {
    switch (status) {
      case CommunicationStatus.pending:
        return _kWarning;
      case CommunicationStatus.completed:
        return _kSuccess;
      case CommunicationStatus.cancelled:
        return _kError;
      case CommunicationStatus.followUp:
        return Colors.purple;
    }
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

  Widget _buildStatusFilterChips() {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: Text('All'),
            selected: _filterStatus == null,
            onSelected: (selected) => setState(() => _filterStatus = null),
          ),
          const SizedBox(width: 8),
          ...CommunicationStatus.values.map((status) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status.name.toUpperCase()),
              selected: _filterStatus == status,
              selectedColor: _getStatusColor(status).withOpacity(0.2),
              onSelected: (selected) => setState(() => _filterStatus = selected ? status : null),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInteractionCard(CommunicationModel communication) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunicationHistoryPage(
                customerId: communication.customerId,
                customerName: communication.customerName,
                customerPhone: communication.phoneNumber,
                customerEmail: communication.emailAddress,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(communication.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getTypeIcon(communication.type),
                      color: _getTypeColor(communication.type),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          communication.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerProfilePage(
                                      customerId: communication.customerId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                communication.customerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('•', style: TextStyle(color: Colors.grey[400])),
                            SizedBox(width: 8),
                            Text(
                              communication.typeDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(communication.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(communication.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(communication.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      communication.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(communication.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Description
              Text(
                communication.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Footer Row
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    communication.getFormattedDate(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  if (communication.status == CommunicationStatus.followUp && communication.scheduledDate != null)
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Follow up: ${communication.scheduledDate!.day}/${communication.scheduledDate!.month}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Interactions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search interactions...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Status Filter Chips
          Container(
            color: Colors.white,
            child: _buildStatusFilterChips(),
          ),
          
          // Interactions List
          Expanded(
            child: StreamBuilder<List<CommunicationModel>>(
              stream: _communicationService.getAllCommunications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading interactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading interactions...'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No interactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Interactions will appear here as customers communicate',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Filter interactions
                List<CommunicationModel> filteredInteractions = snapshot.data!.where((interaction) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    String searchText = '${interaction.subject} ${interaction.description} ${interaction.customerName}'.toLowerCase();
                    if (!searchText.contains(_searchQuery.toLowerCase())) {
                      return false;
                    }
                  }
                  
                  // Status filter
                  if (_filterStatus != null && interaction.status != _filterStatus) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                if (filteredInteractions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No interactions found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: filteredInteractions.length,
                  itemBuilder: (context, index) {
                    return _buildInteractionCard(filteredInteractions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}