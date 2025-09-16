import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../vehicles/view_vehicle.dart';
import '../vehicles/add_vehicle.dart';
import 'add_customer.dart';

class CustomerProfilePage extends StatefulWidget {
  final String customerId;

  const CustomerProfilePage({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Copy to clipboard and show feedback
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show action dialog for phone number
  void _showPhoneActions(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Call $phoneNumber'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(phoneNumber, 'Phone number');
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.blue),
                title: Text('Copy Phone Number'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(phoneNumber, 'Phone number');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show action dialog for email
  void _showEmailActions(String email) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text('Send Email'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(email, 'Email address');
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.blue),
                title: Text('Copy Email'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(email, 'Email address');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(String customerName) {
    final TextEditingController _confirmController = TextEditingController();
    bool _isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Delete Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action cannot be undone. The customer will be moved to deleted customers.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'To confirm, please type the customer name:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    decoration: InputDecoration(
                      hintText: 'Type customer name here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isDeleting ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isDeleting ? null : () async {
                    if (_confirmController.text.trim() == customerName.trim()) {
                      setState(() {
                        _isDeleting = true;
                      });
                      
                      await _softDeleteCustomer();
                      
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Customer name does not match!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: _isDeleting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Soft delete customer
  Future<void> _softDeleteCustomer() async {
    try {
      await _firestore.collection('customers').doc(widget.customerId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Customer deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting customer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Color methods to match CRM page
  Color _getAvatarBgColor(String name) {
    const swatches = [
      Color(0xFFE3F2FD), // Light Blue
      Color(0xFFE8F5E9), // Light Green
      Color(0xFFFFF3E0), // Light Orange
      Color(0xFFEDE7F6), // Light Purple
      Color(0xFFFFEBEE), // Light Pink
      Color(0xFFE0F7FA), // Light Cyan
      Color(0xFFFFF8E1), // Light Yellow
      Color(0xFFEFEBE9), // Light Brown
    ];
    return swatches[name.hashCode % swatches.length];
  }

  Color _getAvatarIconColor(String name) {
    const iconColors = [
      Color(0xFF1976D2), // Blue
      Color(0xFF388E3C), // Green
      Color(0xFFEF6C00), // Orange
      Color(0xFF7B1FA2), // Purple
      Color(0xFFE91E63), // Pink
      Color(0xFF00ACC1), // Cyan
      Color(0xFFFFB300), // Yellow
      Color(0xFF5D4037), // Brown
    ];
    return iconColors[name.hashCode % iconColors.length];
  }

  Widget _buildAddVehicleButton({String? customerName}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVehicle(
                customerId: widget.customerId,
                customerName: customerName,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Vehicle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to add a new vehicle',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection(Map<String, dynamic> customerData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              InkWell(
                onTap: () => _showPhoneActions(customerData['phoneNumber'] ?? ''),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        customerData['phoneNumber'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black45,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Color(0xFFEEEEEE),
              ),
              InkWell(
                onTap: () => _showEmailActions(customerData['emailAddress'] ?? ''),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          customerData['emailAddress'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black45,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection(List<String> vehicleIds, String customerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Vehicle Owned',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          color: Colors.white,
          child: vehicleIds.isEmpty
              ? _buildAddVehicleButton(customerName: customerName)
              : FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('vehicles')
                      .where(FieldPath.documentId, whereIn: vehicleIds)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildAddVehicleButton(customerName: customerName);
                    }

                    final vehicles = snapshot.data!.docs;
                    
                    if (vehicles.isEmpty) {
                      return _buildAddVehicleButton(customerName: customerName);
                    }

              return Column(
                children: vehicles.map((doc) {
                  final vehicleData = doc.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewVehicle(
                                vehicleId: doc.id,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(0xFF007AFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Color(0xFF007AFF),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${vehicleData['year']?.toString() ?? ''} ${vehicleData['make'] ?? ''} ${vehicleData['model'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${vehicleData['carPlate'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ], 
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (doc.id != vehicles.last.id)
                        Container(
                          height: 1,
                          color: Color(0xFFEEEEEE),
                        ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
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
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.blue,
              size: 22,
            ),
            onPressed: () async {
              // Get current customer data
              DocumentSnapshot customerDoc = await _firestore
                  .collection('customers')
                  .doc(widget.customerId)
                  .get();
              
              if (customerDoc.exists) {
                Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
                Customer customer = Customer(
                  id: customerDoc.id,
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
                      documentId: widget.customerId,
                    ),
                  ),
                );
                
                // Refresh data if customer was updated
                if (result == true) {
                  setState(() {});
                }
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String value) async {
              if (value == 'delete') {
                // Get customer data for confirmation
                DocumentSnapshot customerDoc = await _firestore
                    .collection('customers')
                    .doc(widget.customerId)
                    .get();
                
                if (customerDoc.exists) {
                  Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
                  String customerName = customerData['customerName'] ?? '';
                  _showDeleteConfirmation(customerName);
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Delete Customer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('customers').doc(widget.customerId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Customer not found'));
          }

          Map<String, dynamic> customerData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Check if customer is deleted
          if (customerData['isDeleted'] == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Customer Deleted',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This customer has been deleted',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          List<String> vehicleIds = List<String>.from(customerData['vehicleIds'] ?? []);

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.only(top: 20, bottom: 30),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getAvatarBgColor(customerData['customerName'] ?? 'A'),
                        ),
                        child: Center(
                          child: Text(
                            (customerData['customerName'] ?? 'A')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: _getAvatarIconColor(customerData['customerName'] ?? 'A'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        customerData['customerName'] ?? 'Customer Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildContactSection(customerData),
                SizedBox(height: 20),
                _buildVehicleSection(vehicleIds, customerData['customerName'] ?? 'Unknown'),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}