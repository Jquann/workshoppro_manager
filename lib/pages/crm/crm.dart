import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';
import 'add_customer.dart';
import 'customer_profile.dart';
import '../vehicles/view_vehicle.dart';

class CRMPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CRMPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _CRMPageState createState() => _CRMPageState();
}

class _CRMPageState extends State<CRMPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text('Customer Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _navigateToAddCustomer(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Color(0xFF8E8E93),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search customers...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 17,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Icon(
                                Icons.clear,
                                color: Color(0xFF8E8E93),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customer List from Firestore
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('customers').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading customers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild to retry
                            },
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
                          Text(
                            'Loading customers...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No customers found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first customer to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddCustomer,
                            icon: Icon(Icons.add),
                            label: Text('Add Customer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter customers based on search query
                  List<DocumentSnapshot> filteredCustomers = snapshot.data!.docs.where((doc) {
                    if (_searchQuery.isEmpty) return true;

                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String customerName = (data['customerName'] ?? '').toString().toLowerCase();
                    String phoneNumber = (data['phoneNumber'] ?? '').toString().toLowerCase();
                    String email = (data['emailAddress'] ?? '').toString().toLowerCase();
                    String vehicleMake = (data['vehicleMake'] ?? '').toString().toLowerCase();
                    String vehicleModel = (data['vehicleModel'] ?? '').toString().toLowerCase();

                    return customerName.contains(_searchQuery) ||
                        phoneNumber.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        vehicleMake.contains(_searchQuery) ||
                        vehicleModel.contains(_searchQuery);
                  }).toList();

                  if (filteredCustomers.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No customers found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = filteredCustomers[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                      return _buildCustomerItem(
                        doc.id,
                        data,
                        isFirst: index == 0,
                        isLast: index == filteredCustomers.length - 1,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(String docId, Map<String, dynamic> customerData, {bool isFirst = false, bool isLast = false}) {
    String customerName = customerData['customerName'] ?? 'Unknown Customer';
    String phoneNumber = customerData['phoneNumber'] ?? '';
    String email = customerData['emailAddress'] ?? '';
    List<String> vehicleIds = List<String>.from(customerData['vehicleIds'] ?? []);

    // Create display info from contact details
    String displayInfo = '';
    if (phoneNumber.isNotEmpty) {
      displayInfo = phoneNumber;
    } else if (email.isNotEmpty) {
      displayInfo = email;
    }
    if (vehicleIds.isNotEmpty) {
      displayInfo += vehicleIds.length == 1 
          ? ' · 1 Vehicle'
          : ' · ${vehicleIds.length} Vehicles';
    }

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
          _navigateToCustomerProfile(docId, customerData);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(customerName),
                child: Text(
                  customerName.isNotEmpty ? customerName.substring(0, 1).toUpperCase() : '?',
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
                      customerName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (displayInfo.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        displayInfo,
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  GestureDetector(
                    onTap: () {
                      _navigateToEditCustomer(docId, customerData);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmation(docId, customerName);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                ],
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
      Color(0xFFAF52DE),
      Color(0xFFFF2D92),
      Color(0xFF5AC8FA),
    ];
    return colors[name.hashCode % colors.length];
  }

  void _navigateToCustomerProfile(String docId, Map<String, dynamic> customerData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerProfilePage(
          customerId: docId,
        ),
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

    // The StreamBuilder will automatically update the list when new data is added to Firestore
    if (result != null) {
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

  void _navigateToEditCustomer(String docId, Map<String, dynamic> customerData) async {
    // Create Customer object from the data
    Customer customer = Customer(
      id: docId,
      customerName: customerData['customerName'] ?? '',
      phoneNumber: customerData['phoneNumber'] ?? '',
      emailAddress: customerData['emailAddress'] ?? '',
      vehicleIds: List<String>.from(customerData['vehicleIds'] ?? []),
      createdAt: (customerData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (customerData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerPage(
          customer: customer,
          documentId: docId,
        ),
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer updated successfully!'),
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

  void _showDeleteConfirmation(String docId, String customerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Customer'),
          content: Text('Are you sure you want to delete $customerName? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCustomer(docId, customerName);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(String docId, String customerName) async {
    try {
      await _firestore.collection('customers').doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$customerName deleted successfully'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting customer: $e'),
          backgroundColor: Colors.red,
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