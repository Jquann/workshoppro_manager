import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';
import 'customer_profile.dart';
import 'add_customer.dart';

class CRMUI extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const CRMUI({super.key, this.scaffoldKey});

  @override
  State<CRMUI> createState() => _CRMUIState();
}

class _CRMUIState extends State<CRMUI> {
  // inline tokens (matching vehicle_ui.dart)
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  final _firestore = FirebaseFirestore.instance;
  String _q = '';

  InputDecoration _search() => InputDecoration(
    hintText: 'Search',
    hintStyle: const TextStyle(fontSize: 14, color: _kGrey),
    prefixIcon: const Icon(Icons.search, size: 20, color: _kGrey),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBlue),
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: const Text('Customer',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerPage()),
              );
              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Customer added successfully!'),
                    backgroundColor: const Color(0xFF34C759),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: _search(),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('customers').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter customers based on search
                final customers = snap.data!.docs.where((doc) {
                  if (_q.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['customerName']?.toString().toLowerCase() ?? '',
                    data['phoneNumber']?.toString().toLowerCase() ?? '',
                    data['emailAddress']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any((field) => field.contains(_q.toLowerCase()));
                }).toList();

                if (customers.isEmpty) {
                  return const Center(child: Text('No customers'));
                }

                return ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kDivider),
                  itemBuilder: (_, i) {
                    final doc = customers[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final customerName = data['customerName'] ?? 'Unknown Customer';
                    final phoneNumber = data['phoneNumber'] ?? '';
                    final email = data['emailAddress'] ?? '';
                    final vehicleIds = List<String>.from(data['vehicleIds'] ?? []);

                    // Build subtitle text
                    String subtitle = '';
                    if (phoneNumber.isNotEmpty) {
                      subtitle = phoneNumber;
                    } else if (email.isNotEmpty) {
                      subtitle = email;
                    }
                    if (vehicleIds.isNotEmpty) {
                      if (subtitle.isNotEmpty) subtitle += ' · ';
                      subtitle += vehicleIds.length == 1 
                          ? '1 Vehicle'
                          : '${vehicleIds.length} Vehicles';
                    }

                    return ListTile(
                      minVerticalPadding: 10,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: _getAvatarColor(customerName),
                        child: Text(
                          customerName.isNotEmpty
                              ? customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      title: Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: const TextStyle(
                          color: _kGrey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: _kGrey, size: 20),
                            onPressed: () {
                              _navigateToEditCustomer(doc.id, data);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: _kGrey, size: 20),
                            onPressed: () {
                              _showDeleteConfirmation(doc.id, customerName);
                            },
                          ),
                          const Icon(Icons.chevron_right, color: _kGrey),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerProfilePage(
                            customerId: doc.id,
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
    );
  }

  void _navigateToEditCustomer(String docId, Map<String, dynamic> customerData) async {
    final customer = Customer(
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
          content: const Text('Customer updated successfully!'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeleteConfirmation(String docId, String customerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text(
            'Are you sure you want to delete $customerName? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCustomer(docId, customerName);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(String docId, String customerName) async {
    try {
      await _firestore.collection('customers').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$customerName deleted successfully'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}