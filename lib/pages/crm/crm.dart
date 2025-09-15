import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_customer.dart';
import 'customer_profile.dart';

class CRMPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CRMPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _CRMPageState createState() => _CRMPageState();
}

class _CRMPageState extends State<CRMPage> {
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kSurface = Color(0xFFF2F2F7);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String q = '';

  InputDecoration _searchInput(double s) => InputDecoration(
    hintText: 'Search',
    hintStyle: TextStyle(color: _kGrey, fontSize: (14 * s).clamp(13, 16)),
    prefixIcon: const Icon(Icons.search, color: _kGrey),
    filled: true,
    fillColor: _kSurface,
    contentPadding:
    EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

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
          'CRM',
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
              icon: const Icon(Icons.person_add, color: Colors.black),
              onPressed: () => _navigateToAddCustomer(),
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 10 * s),
                      child: TextField(
                        decoration: _searchInput(s),
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),
                    Expanded(
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
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                            if (q.isEmpty) return true;

                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            String searchText = [
                              data['customerName'],
                              data['phoneNumber'],
                              data['emailAddress']
                            ].where((text) => text != null)
                                .map((text) => text.toString().toLowerCase())
                                .join(' ');

                            return searchText.contains(q.toLowerCase());
                          }).toList();

                          if (filteredCustomers.isEmpty && q.isNotEmpty) {
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

                          return ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCustomers.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Colors.transparent),
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
                  ],
                );
              },
            ),
          ),
        ),
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _navigateToCustomerProfile(docId, customerData),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Avatar with Vehicle icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getAvatarBgColor(customerName),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_outline,
                    color: _kGrey, size: 26),
              ),
              const SizedBox(width: 12),
              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kGrey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarBgColor(String name) {
    const swatches = [
      Color(0xFFE3F2FD),
      Color(0xFFE8F5E9),
      Color(0xFFFFF3E0),
      Color(0xFFEDE7F6),
      Color(0xFFFFEBEE),
      Color(0xFFE0F7FA),
    ];
    return swatches[name.hashCode % swatches.length];
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
}