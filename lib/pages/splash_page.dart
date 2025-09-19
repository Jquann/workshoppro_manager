import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'auth/login.dart';
import 'navigations/drawer.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Check if user is already authenticated with Firebase
      if (_authService.currentUser != null) {
        // User is already logged in, go to main app
        _navigateToMain();
        return;
      }

      // Check for saved credentials
      final savedCredentials = await StorageService.getSavedCredentials();
      
      if (savedCredentials != null) {
        // Try auto login with saved credentials
        await _attemptAutoLogin(
          savedCredentials['email']!,
          savedCredentials['password']!,
        );
      } else {
        // No saved credentials, go to login
        _navigateToLogin();
      }
    } catch (e) {
      // If anything goes wrong, go to login
      _navigateToLogin();
    }
  }

  Future<void> _attemptAutoLogin(String email, String password) async {
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Auto login successful, go to main app
      _navigateToMain();
    } catch (e) {
      // Auto login failed, clear credentials and go to login
      await StorageService.clearCredentials();
      _navigateToLogin();
    }
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainAppWithDrawer(),
        ),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Login(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              'WorkshopPro Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading Indicator
            const CircularProgressIndicator(
              color: Color(0xFF007AFF),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Loading Text
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}