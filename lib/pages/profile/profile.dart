import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/cached_profile_image.dart';
import 'profile_edit.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic>? currentUserData;

  const Profile({Key? key, this.currentUserData}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

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
        _showSnackBar('Error loading profile data: $e', isError: true);
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEdit(currentUserData: _userData),
      ),
    );
    
    // If edit was successful, refresh the profile data
    if (result == true) {
      await _loadUserData();
    }
  }

  // Format phone number for display
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digits = phoneNumber.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present
    if (digits.isNotEmpty && !digits.startsWith('0')) {
      digits = '0$digits';
    }
    
    // Format based on length
    if (digits.length == 10) {
      // Format: 012-345 6789
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 11) {
      // Format: 012-3456 7890
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    
    return digits.isNotEmpty ? digits : 'Not provided'; // Return digits if format doesn't match
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return whether any changes were made
        Navigator.pop(context, _userData != widget.currentUserData);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, _userData != widget.currentUserData),
          ),
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF007AFF),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E5EA),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: ProfileImageWidget(
                                    imagePath: _userData?['profileImagePath'],
                                    size: 120,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _userData?['name'] ?? 'User Name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData?['role'] ?? 'admin',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Personal Information Section
                        _buildSectionHeader('Personal Information'),
                        const SizedBox(height: 16),
                        
                        _buildReadOnlyField(
                          label: 'Full Name',
                          value: _userData?['name'] ?? 'Not provided',
                          icon: Icons.person_outline,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildReadOnlyField(
                          label: 'Phone Number',
                          value: _formatPhoneNumber(_userData?['phone'] ?? ''),
                          icon: Icons.phone_outlined,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildReadOnlyField(
                          label: 'Gender',
                          value: _userData?['gender'] ?? 'Not provided',
                          icon: Icons.person_outline,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Work Information Section
                        _buildSectionHeader('Work Information'),
                        const SizedBox(height: 16),
                        
                        _buildReadOnlyField(
                          label: 'Role',
                          value: _userData?['role'] ?? 'admin',
                          icon: Icons.work_outline,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        
                        // Edit Profile Button
                        _buildEditProfileButton(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF8E8E93),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _navigateToEditProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}