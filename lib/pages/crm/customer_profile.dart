import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../vehicles/vehicle_model.dart';
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

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Color(0xFF007AFF),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF8E8E93),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleItem(VehicleModel vehicle) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewVehicle(
              vehicleId: vehicle.id,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car,
                color: Color(0xFF007AFF),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Customer A',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
              semanticLabel: 'View vehicle details',
            ),
          ],
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
              _navigateToEditCustomer();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 24,
            ),
            onPressed: () {
              _showDeleteConfirmation();
            },
          ),
        ],
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('customers').doc(widget.customerId).snapshots(),
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
                    'Error loading customer',
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
                    'Loading customer details...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: Colors.grey[400],
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Customer not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This customer may have been deleted',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          Map<String, dynamic> customerData = snapshot.data!.data() as Map<String, dynamic>;
          List<String> vehicleIds = List<String>.from(customerData['vehicleIds'] ?? []);

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getAvatarColor(customerData['customerName'] ?? ''),
                        ),
                        child: customerData['customerName'] != null && customerData['customerName'].isNotEmpty
                            ? Center(
                                child: Text(
                                  customerData['customerName'].substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white.withOpacity(0.8),
                              ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        customerData['customerName'] ?? 'Unknown Customer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (customerData['emailAddress'] != null && customerData['emailAddress'].isNotEmpty)
                        Text(
                          customerData['emailAddress'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (customerData['phoneNumber'] != null && customerData['phoneNumber'].isNotEmpty) ...[
                        _buildContactItem(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: customerData['phoneNumber'],
                          onTap: () {
                            // Add phone call functionality here
                          },
                        ),
                        SizedBox(height: 12),
                      ],
                      if (customerData['emailAddress'] != null && customerData['emailAddress'].isNotEmpty)
                        _buildContactItem(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: customerData['emailAddress'],
                          onTap: () {
                            // Add email functionality here
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vehicle Owned',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVehicle(
                                    customerId: widget.customerId,
                                    customerName: customerData['customerName'],
                                  ),
                                ),
                              );
                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vehicle added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.add, size: 20),
                            label: Text('Add Vehicle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (vehicleIds.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              Text(
                                'No vehicles registered',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('vehicles')
                              .where(FieldPath.documentId, whereIn: vehicleIds)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error loading vehicles'));
                            }

                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final vehicles = snapshot.data!.docs
                                .map((doc) => VehicleModel.fromMap(
                                      doc.id,
                                      doc.data() as Map<String, dynamic>,
                                    ))
                                .toList();

                            if (vehicles.isEmpty) {
                              return Center(
                                child: Column(
                                  children: [
                                    SizedBox(height: 20),
                                    Text(
                                      'No vehicles registered',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: vehicles.map(_buildVehicleItem).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToEditCustomer() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('customers').doc(widget.customerId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> customerData = doc.data() as Map<String, dynamic>;

      Customer customer = Customer(
        id: doc.id,
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

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer updated successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error editing customer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Customer'),
          content: Text('Are you sure you want to delete this customer? This action cannot be undone.'),
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
                _deleteCustomer();
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

  Future<void> _deleteCustomer() async {
    try {
      await _firestore.collection('customers').doc(widget.customerId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer deleted successfully'),
          backgroundColor: Color(0xFF34C759),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting customer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}