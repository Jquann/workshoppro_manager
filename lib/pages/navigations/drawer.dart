import 'package:flutter/material.dart';
import 'navigation.dart';
import '../../services/auth_service.dart';
import '../auth/login.dart';
import '../admin/manage_users.dart';

class MainAppWithDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(),
      body: GestureDetector(
        onPanUpdate: (details) {
          // Check if the gesture is a swipe from left to right (anywhere on screen)
          if (details.delta.dx > 0) {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        child: MainNavigationPage(scaffoldKey: _scaffoldKey),
      ),
    );
  }
}

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF007AFF),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _userData?['name'] ?? 'Loading...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _userData?['email'] ?? (_authService.currentUser?.email ?? 'Loading...'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    if (_userData?['role'] != null) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF007AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _userData!['role'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Divider(
                color: Color(0xFFE5E5EA),
                height: 1,
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/view_profile');
                      },
                    ),
                    // Admin-only features
                    if (_userData?['role'] == 'admin') ...[
                      _buildDrawerItem(
                        icon: Icons.people,
                        title: 'Manage Users',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageUsersPage(),
                            ),
                          );
                        },
                      ),
                    ],
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showHelpDialog(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              // Logout Section
              Divider(
                color: Color(0xFFE5E5EA),
                height: 1,
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                isLogout: true,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: isLogout ? Color(0xFFFF3B30) : Color(0xFF8E8E93),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isLogout ? Color(0xFFFF3B30) : Colors.black,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.grey.withOpacity(0.1),
      hoverColor: Colors.grey.withOpacity(0.05),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Help & Support',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help with WorkshopPro Manager?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              _buildHelpItem(Icons.email, 'Email Support', 'support@workshoppro.com'),
              SizedBox(height: 12),
              _buildHelpItem(Icons.phone, 'Phone Support', '+1 (555) 123-4567'),
              SizedBox(height: 12),
              _buildHelpItem(Icons.schedule, 'Business Hours', 'Mon-Fri, 9AM-5PM'),
              SizedBox(height: 16),
              Text(
                'Or visit our documentation for common questions and tutorials.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(0xFF007AFF),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About WorkshopPro Manager',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 32,
                    color: Color(0xFF007AFF),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WorkshopPro Manager',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'A comprehensive workshop management solution for automotive service centers.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Features:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Customer Management\n• Vehicle Tracking\n• Service Scheduling\n• Inventory Management\n• Reporting & Analytics',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '© 2024 WorkshopPro Inc. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFFFF3B30),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout? You will need to sign in again to access the app.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context);
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF007AFF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Signing out...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Sign out
      await _authService.signOut();

      // Navigate to login page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSnackBar(context, 'Error signing out: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFFF3B30) : Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}