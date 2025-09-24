import 'package:flutter/material.dart';
import '../../models/communication_model.dart';
import '../../services/communication_service.dart';
import '../../services/communication_debug_service.dart';
import 'add_communication.dart';

class CommunicationHistoryPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;

  const CommunicationHistoryPage({
    Key? key,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
  }) : super(key: key);

  @override
  _CommunicationHistoryPageState createState() => _CommunicationHistoryPageState();
}

class _CommunicationHistoryPageState extends State<CommunicationHistoryPage> {
  final CommunicationService _communicationService = CommunicationService();
  final CommunicationDebugService _debugService = CommunicationDebugService();
  String _searchQuery = '';
  CommunicationType? _filterType;
  CommunicationStatus? _filterStatus;
  bool _debugMode = false;
  String _debugInfo = '';

  // UI Colors
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSuccess = Color(0xFF34C759);
  static const _kError = Color(0xFFFF3B30);
  static const _kWarning = Color(0xFFFF9500);
  static const _kGrey = Color(0xFF8E8E93);

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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Communications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _filterType = null;
                        _filterStatus = null;
                      });
                      Navigator.pop(context);
                    },
                    icon: Text(
                      'Clear',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Type Filter
              Text('Communication Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('All'),
                    selected: _filterType == null,
                    onSelected: (selected) => setModalState(() => _filterType = null),
                  ),
                  ...CommunicationType.values.map((type) => FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: _filterType == type,
                    onSelected: (selected) => setModalState(() => _filterType = selected ? type : null),
                  )),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Status Filter
              Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text('All'),
                    selected: _filterStatus == null,
                    onSelected: (selected) => setModalState(() => _filterStatus = null),
                  ),
                  ...CommunicationStatus.values.map((status) => FilterChip(
                    label: Text(status.name.toUpperCase()),
                    selected: _filterStatus == status,
                    onSelected: (selected) => setModalState(() => _filterStatus = selected ? status : null),
                  )),
                ],
              ),
              
              SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild with filters
                        Navigator.pop(context);
                      },
                      child: Text('Apply'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommunicationDetails(CommunicationModel communication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          communication.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          communication.typeDisplayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddCommunicationPage(
                              customerId: widget.customerId,
                              customerName: widget.customerName,
                              customerPhone: widget.customerPhone,
                              customerEmail: widget.customerEmail,
                              communication: communication,
                            ),
                          ),
                        );
                        if (result == true) {
                          Navigator.pop(context); // Close details sheet
                        }
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(communication);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(communication.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(communication.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  communication.statusDisplayName,
                  style: TextStyle(
                    color: _getStatusColor(communication.status),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Description
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        communication.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Contact Info
                      if (communication.phoneNumber != null || communication.emailAddress != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (communication.phoneNumber != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(communication.phoneNumber!),
                                  ],
                                ),
                              ),
                            if (communication.emailAddress != null)
                              Row(
                                children: [
                                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(communication.emailAddress!)),
                                ],
                              ),
                          ],
                        ),
                      
                      SizedBox(height: 20),
                      
                      // Dates
                      Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text(
                            'Created: ${communication.getFormattedDate()}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (communication.scheduledDate != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Scheduled: ${communication.scheduledDate!.day}/${communication.scheduledDate!.month}/${communication.scheduledDate!.year}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(CommunicationModel communication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: _kError),
            SizedBox(width: 8),
            Text('Delete Communication'),
          ],
        ),
        content: Text('Are you sure you want to delete this communication? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _communicationService.deleteCommunication(communication.id);
                Navigator.pop(context); // Close confirmation
                Navigator.pop(context); // Close details sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Communication deleted successfully'),
                    backgroundColor: _kSuccess,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting communication'),
                    backgroundColor: _kError,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: _kError)),
          ),
        ],
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
          'Communication History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Info Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(Icons.person, color: _kPrimary, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.customerPhone != null || widget.customerEmail != null)
                        Text(
                          widget.customerPhone ?? widget.customerEmail ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search communications...',
                prefixIcon: Icon(Icons.search, color: _kGrey),
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
          
          // Communications List
          Expanded(
            child: StreamBuilder<List<CommunicationModel>>(
              stream: _communicationService.getCustomerCommunications(widget.customerId),
              builder: (context, snapshot) {
                // Handle different connection states
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading communication history...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Handle errors
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Unable to load communications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please check your internet connection and try again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error.toString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Handle no data or empty list
                if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No communications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No communication history found for ${widget.customerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          margin: EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                              SizedBox(height: 8),
                              Text(
                                'Communications will appear here once they are created',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter communications
                List<CommunicationModel> filteredCommunications = snapshot.data!.where((comm) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    String searchText = '${comm.subject} ${comm.description}'.toLowerCase();
                    if (!searchText.contains(_searchQuery.toLowerCase())) {
                      return false;
                    }
                  }
                  
                  // Type filter
                  if (_filterType != null && comm.type != _filterType) {
                    return false;
                  }
                  
                  // Status filter
                  if (_filterStatus != null && comm.status != _filterStatus) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                // Handle empty filtered results
                if (filteredCommunications.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No matching communications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No communications found for "${_searchQuery}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterType = null;
                              _filterStatus = null;
                            });
                          },
                          icon: Icon(Icons.clear_all),
                          label: Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredCommunications.isEmpty && (_filterType != null || _filterStatus != null)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No communications match filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters to see more results',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _filterType = null;
                              _filterStatus = null;
                            });
                          },
                          icon: Icon(Icons.clear_all),
                          label: Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredCommunications.length,
                  itemBuilder: (context, index) {
                    final communication = filteredCommunications[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showCommunicationDetails(communication),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            communication.subject,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(communication.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
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
                                    SizedBox(height: 4),
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
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          communication.getFormattedDate(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        SizedBox(width: 12),
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCommunicationPage(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerPhone: widget.customerPhone,
                customerEmail: widget.customerEmail,
              ),
            ),
          );
          // The StreamBuilder will automatically refresh the list
        },
        icon: Icon(Icons.add),
        label: Text('New Communication'),
        backgroundColor: _kPrimary, 
        foregroundColor: Colors.white,
      ),
    );
  }
}