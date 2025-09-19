import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _emailKey = 'remembered_email';
  static const String _passwordKey = 'remembered_password';
  static const String _rememberMeKey = 'remember_me';

  // Save login credentials
  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      await clearCredentials();
    }
  }

  // Get saved credentials
  static Future<Map<String, dynamic>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    
    if (!rememberMe) {
      return null;
    }

    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);

    if (email != null && password != null) {
      return {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      };
    }

    return null;
  }

  // Clear saved credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.setBool(_rememberMeKey, false);
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }
}