import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear saved credentials when signing out
      await StorageService.clearCredentials();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        } else {
          // If user document doesn't exist, create one with basic info
          Map<String, dynamic> userData = {
            'email': currentUser!.email,
            'name': currentUser!.displayName ?? 'Admin User',
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'admin',
          };
          
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .set(userData);
          
          return userData;
        }
      }
      return null;
    } catch (e) {
      throw 'Error fetching user data. Please try again.';
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(userData);
      } else {
        throw 'No user is currently signed in.';
      }
    } catch (e) {
      throw 'Error updating user data: ${e.toString()}';
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error sending reset email. Please try again.';
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
}