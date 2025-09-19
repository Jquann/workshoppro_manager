import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_account.dart';
import 'user_details.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'All'; // Filter state

  // Helper method to truncate text with ellipsis
  String _truncateText(String text, {int maxLength = 15}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Helper method to get role priority for sorting
  int _getRolePriority(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 1;
      case 'manager':
        return 2;
      case 'mechanic':
        return 3;
      default:
        return 4;
    }
  }

  // Helper method to filter and sort users
  List<QueryDocumentSnapshot> _filterAndSortUsers(List<QueryDocumentSnapshot> users) {
    // Filter users based on selected filter
    List<QueryDocumentSnapshot> filteredUsers = users;
    if (_selectedFilter != 'All') {
      filteredUsers = users.where((user) {
        final userData = user.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'manager';
        return role.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    // Sort by role priority (admin -> manager -> mechanic)
    filteredUsers.sort((a, b) {
      final roleA = (a.data() as Map<String, dynamic>)['role'] ?? 'manager';
      final roleB = (b.data() as Map<String, dynamic>)['role'] ?? 'manager';
      return _getRolePriority(roleA).compareTo(_getRolePriority(roleB));
    });

    return filteredUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manage Users',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Color(0xFF007AFF)),
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'All',
                child: Row(
                  children: [
                    Icon(_selectedFilter == 'All' ? Icons.check : Icons.circle_outlined, 
                         color: Color(0xFF007AFF), size: 20),
                    SizedBox(width: 8),
                    Text('All Users'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Admin',
                child: Row(
                  children: [
                    Icon(_selectedFilter == 'Admin' ? Icons.check : Icons.circle_outlined, 
                         color: Color(0xFFFF3B30), size: 20),
                    SizedBox(width: 8),
                    Text('Admin Only'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Manager',
                child: Row(
                  children: [
                    Icon(_selectedFilter == 'Manager' ? Icons.check : Icons.circle_outlined, 
                         color: Color(0xFF007AFF), size: 20),
                    SizedBox(width: 8),
                    Text('Manager Only'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Mechanic',
                child: Row(
                  children: [
                    Icon(_selectedFilter == 'Mechanic' ? Icons.check : Icons.circle_outlined, 
                         color: Color(0xFF34C759), size: 20),
                    SizedBox(width: 8),
                    Text('Mechanic Only'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 16), // Add some right padding to move icon left
            child: IconButton(
              icon: Icon(Icons.person_add, color: Color(0xFF007AFF)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAccountPage()),
                );
              },
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007AFF),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFFF3B30),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
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
                    size: 64,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some users to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            );
          }

          final allUsers = snapshot.data!.docs;
          final filteredAndSortedUsers = _filterAndSortUsers(allUsers);

          if (filteredAndSortedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All' ? 'No users found' : 'No $_selectedFilter users found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'All' 
                        ? 'Add some users to get started'
                        : 'Try a different filter or add $_selectedFilter users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter status indicator
              if (_selectedFilter != 'All')
                Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 16, color: Color(0xFF007AFF)),
                      SizedBox(width: 8),
                      Text(
                        'Showing $_selectedFilter users only',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                        child: Icon(Icons.close, size: 16, color: Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredAndSortedUsers.length,
                  itemBuilder: (context, index) {
                    final userData = filteredAndSortedUsers[index].data() as Map<String, dynamic>;
                    final userId = filteredAndSortedUsers[index].id;
              final name = userData['name'] ?? 'Unknown';
              final email = userData['email'] ?? 'No email';
              final role = userData['role'] ?? 'manager';
              final isCurrentUser = userId == _auth.currentUser?.uid;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
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
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFF007AFF),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _truncateText(name, maxLength: 20),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        _truncateText(email, maxLength: 20),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: role == 'admin' 
                              ? Color(0xFFFF3B30).withOpacity(0.1)
                              : role == 'mechanic'
                                  ? Color(0xFF34C759).withOpacity(0.1)
                                  : Color(0xFF007AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: role == 'admin' 
                                ? Color(0xFFFF3B30)
                                : role == 'mechanic'
                                    ? Color(0xFF34C759)
                                    : Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: isCurrentUser 
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF8E8E93).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF8E8E93),
                          size: 16,
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsPage(
                          userId: userId,
                          userData: userData,
                          isCurrentUser: isCurrentUser,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
              ),
            ],
          );
        },
      ),
    );
  }
}