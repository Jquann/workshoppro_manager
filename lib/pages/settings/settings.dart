import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isGoogleLinked = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      final prefs = await SharedPreferences.getInstance();
      final isLinked = prefs.getBool('google_account_linked_${_authService.currentUser?.uid}') ?? false;
      
      if (mounted) {
        setState(() {
          _userData = userData;
          _isGoogleLinked = isLinked;
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF007AFF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _buildAccountSection(),
                  const SizedBox(height: 24),
                  
                  // Google Account Section
                  _buildGoogleAccountSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Profile Picture
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF007AFF),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // User Info
          _buildInfoItem('Name', _userData?['name'] ?? 'Loading...'),
          const SizedBox(height: 12),
          _buildInfoItem('Email', _userData?['email'] ?? (_authService.currentUser?.email ?? 'Loading...')),
          const SizedBox(height: 12),
          _buildInfoItem('Role', _userData?['role']?.toString().toUpperCase() ?? 'USER'),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Google Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Link your account with Google for enhanced security and easier sign-in.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          
          // Link Google Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGoogleLinked ? null : () => _showLinkGoogleAccountDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGoogleLinked ? const Color(0xFF00CED1) : Colors.white,
                foregroundColor: _isGoogleLinked ? Colors.white : Colors.black,
                elevation: 0,
                side: BorderSide(color: _isGoogleLinked ? const Color(0xFF00CED1) : const Color(0xFFE5E5EA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(52),
                disabledBackgroundColor: const Color(0xFF00CED1), // 强制设置禁用状态的背景色
                disabledForegroundColor: Colors.white, // 强制设置禁用状态的文字颜色
              ),
              icon: _isGoogleLinked 
                ? const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.white,
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              label: Text(
                _isGoogleLinked ? 'Successfully Linked' : 'Link Google Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isGoogleLinked ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Debug button to test Google link status
          if (!_isGoogleLinked)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _resetGoogleLinkStatus(),
                child: Text(
                  'Debug: Set as Linked (Test)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          
          // Benefits (only show if not linked)
          if (!_isGoogleLinked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildBenefitItem(Icons.speed, 'Faster sign-in process'),
                  const SizedBox(height: 8),
                  _buildBenefitItem(Icons.security, 'Enhanced account security'),
                  const SizedBox(height: 8),
                  _buildBenefitItem(Icons.sync, 'Seamless synchronization'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showLinkGoogleAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Link Google Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect your current account with Google for:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              // Benefits list
              _buildBenefitItem(Icons.login, 'Faster sign-in with Google'),
              const SizedBox(height: 8),
              _buildBenefitItem(Icons.security, 'Enhanced account security'),
              const SizedBox(height: 8),
              _buildBenefitItem(Icons.sync, 'Seamless account synchronization'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your current email and password will remain the same.',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _linkGoogleAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Link Account'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _linkGoogleAccount() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF007AFF)),
                    SizedBox(height: 16),
                    Text(
                      'Linking Google Account...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Here you would implement the actual Google account linking logic
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.of(context).pop();

      // Save linked status to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_account_linked_${_authService.currentUser?.uid}', true);

      // Update state to show linked status
      setState(() {
        _isGoogleLinked = true;
      });

      // Show success dialog
      _showSuccessDialog();

    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      _showSnackBar('Failed to link Google account: ${e.toString()}', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34C759),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Linked!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your account has been successfully linked with Google. You can now sign in using either your email/password or Google account.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to toggle Google link status (for testing)
  Future<void> _resetGoogleLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isGoogleLinked) {
      await prefs.remove('google_account_linked_${_authService.currentUser?.uid}');
      setState(() {
        _isGoogleLinked = false;
      });
      _showSnackBar('Google account link has been reset', isError: false);
    } else {
      await prefs.setBool('google_account_linked_${_authService.currentUser?.uid}', true);
      setState(() {
        _isGoogleLinked = true;
      });
      _showSnackBar('Google account has been set as linked (test)', isError: false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}