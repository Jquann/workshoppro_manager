import 'package:flutter/material.dart';

import 'add_customer.dart';
import 'customer_profile.dart';

class CRMPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CRMPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _CRMPageState createState() => _CRMPageState();
}

class _CRMPageState extends State<CRMPage> {
  // Sample customer data - replace with your actual data source
  List<Map<String, dynamic>> customers = [
    {
      'name': 'Customer Name',
      'address': '123 Main St, Anytown',
      'phone': '(60+) 12-3456 789',
      'email': 'customer@email.com',
    },
    {
      'name': 'Another Customer',
      'address': '456 Oak Ave, Anytown',
      'phone': '(60+) 12-3456 790',
      'email': 'another.customer@email.com',
    },
    {
      'name': 'Third Customer',
      'address': '789 Pine Ln, Anytown',
      'phone': '(60+) 12-3456 791',
      'email': 'third.customer@email.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            widget.scaffoldKey?.currentState?.openDrawer();
          },
        ),
        title: Text(
          'CRM',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () {
              _navigateToAddCustomer();
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Icon(
                    Icons.search,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 17,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return _buildCustomerItem(
                    customer,
                    isFirst: index == 0,
                    isLast: index == customers.length - 1,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(Map<String, dynamic> customer, {bool isFirst = false, bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          _navigateToCustomerProfile(customer);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(customer['name']),
                child: Text(
                  customer['name'].substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      customer['address'],
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
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

  void _navigateToCustomerProfile(Map<String, dynamic> customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerProfilePage(customer: customer),
      ),
    );
  }

  void _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerPage(),
      ),
    );

    // If customer data is returned, add it to the list
    if (result != null) {
      setState(() {
        customers.add({
          'name': result['customerName'] ?? 'New Customer',
          'address': '123 New Address, City',
          'phone': result['phoneNumber'] ?? '(60+) 12-3456 XXX',
          'email': result['emailAddress'] ?? 'customer@email.com',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}