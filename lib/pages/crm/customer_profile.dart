import 'package:flutter/material.dart';

class CustomerProfilePage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerProfilePage({Key? key, required this.customer}) : super(key: key);

  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Customer Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () {
              // TODO: Navigate to edit customer page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit customer functionality')),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Customer Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: _getAvatarColor(widget.customer['name']),
                  child: Text(
                    widget.customer['name'].substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  widget.customer['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.customer['address'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          // Tab Buttons
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Service History', 0),
                ),
                Expanded(
                  child: _buildTabButton('Communication History', 1),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0 ? _buildServiceHistoryTab() : _buildCommunicationHistoryTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Color(0xFF007AFF) : Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information Card
          _buildInfoCard(
            title: 'Contact Information',
            children: [
              _buildInfoRow(Icons.phone_outlined, 'Phone', widget.customer['phone'] ?? '(60+) 12-3456 789'),
              _buildInfoRow(Icons.email_outlined, 'Email', widget.customer['email'] ?? 'customer@email.com'),
              _buildInfoRow(Icons.location_on_outlined, 'Address', widget.customer['address']),
              _buildInfoRow(Icons.access_time_outlined, 'Last Contact', '2 days ago'),
            ],
          ),

          SizedBox(height: 16),

          // Vehicle Information Card
          _buildInfoCard(
            title: 'Vehicle Owned',
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2018 Toyota Camry',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Color(0xFF8E8E93),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Service History Card
          _buildInfoCard(
            title: 'Recent Services',
            children: [
              _buildServiceItem(
                'Oil Change & Filter',
                'Jan 15, 2024',
                '\$89.99',
                'Completed',
                Colors.green,
              ),
              _buildServiceItem(
                'Brake Inspection',
                'Dec 22, 2023',
                '\$150.00',
                'Completed',
                Colors.green,
              ),
              _buildServiceItem(
                'Tire Rotation',
                'Nov 10, 2023',
                '\$45.00',
                'Completed',
                Colors.green,
              ),
            ],
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCommunicationHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Recent Communications',
            children: [
              _buildCommunicationItem(
                Icons.phone,
                'Phone Call',
                'Discussed upcoming service appointment',
                '2 days ago',
                Color(0xFF007AFF),
              ),
              _buildCommunicationItem(
                Icons.email,
                'Email Sent',
                'Service reminder for oil change',
                '1 week ago',
                Color(0xFF34C759),
              ),
              _buildCommunicationItem(
                Icons.sms,
                'SMS Sent',
                'Appointment confirmation',
                '2 weeks ago',
                Color(0xFFFF9500),
              ),
              _buildCommunicationItem(
                Icons.phone,
                'Phone Call',
                'Initial service inquiry',
                '3 weeks ago',
                Color(0xFF007AFF),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Quick Actions
          _buildInfoCard(
            title: 'Quick Actions',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.phone,
                      'Call',
                      Color(0xFF007AFF),
                          () => _makeCall(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      Icons.email,
                      'Email',
                      Color(0xFF34C759),
                          () => _sendEmail(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      Icons.sms,
                      'SMS',
                      Color(0xFFFF9500),
                          () => _sendSMS(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Color(0xFF8E8E93),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String service, String date, String amount, String status, Color statusColor) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationItem(IconData icon, String type, String message, String time, Color iconColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFF007AFF),
      Color(0xFFFF3B30),
      Color(0xFF5856D6),
    ];
    return colors[name.hashCode % colors.length];
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${widget.customer['phone'] ?? 'customer'}')),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email to ${widget.customer['email'] ?? 'customer'}')),
    );
  }

  void _sendSMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening SMS to ${widget.customer['phone'] ?? 'customer'}')),
    );
  }
}