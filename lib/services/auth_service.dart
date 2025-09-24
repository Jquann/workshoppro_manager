import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Sign out from any previous sessions to ensure clean state
      await _googleSignIn.signOut();
      
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('User cancelled Google Sign-In');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Google authentication tokens obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase credential created');

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      print('Firebase sign-in successful for: ${result.user?.email}');
      
      // Check if user is authorized (exists in Firestore with admin/manager role)
      if (result.user != null) {
        print('Checking user authorization...');
        bool isAuthorized = await _checkUserAuthorization(result.user!.email!);
        
        if (!isAuthorized) {
          print('User not authorized: ${result.user!.email}');
          // Sign out and throw error if not authorized
          await signOut();
          throw 'Access denied. Only registered admin and manager accounts can sign in with Google.';
        }
        
        print('User authorized, updating document...');
        // Update or create user document in Firestore
        await _updateOrCreateUserDocument(result.user!);
        print('User document updated successfully');
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      
      // Special handling for configuration issues
      if (e.code == 'operation-not-allowed') {
        throw 'Google Sign-In is not enabled. Please check Firebase Console configuration.';
      }
      
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign-In Error: $e');
      
      // Check for common configuration errors
      if (e.toString().contains('Access denied')) {
        throw e.toString();
      } else if (e.toString().contains('PlatformException') || 
                 e.toString().contains('sign_in_failed') ||
                 e.toString().contains('network_error')) {
        throw 'Google Sign-In configuration error. Please ensure:\n'
               '1. Google Sign-In is enabled in Firebase Console\n'
               '2. SHA-1 fingerprint is added to Firebase\n'
               '3. google-services.json is updated\n\n'
               'See GOOGLE_SIGNIN_SETUP.md for detailed instructions.';
      }
      
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Check if user is authorized to sign in (exists in Firestore with admin/manager role)
  Future<bool> _checkUserAuthorization(String email) async {
    try {
      print('Checking authorization for: $email');
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      print('Found ${query.docs.length} documents for email: $email');
      
      if (query.docs.isNotEmpty) {
        Map<String, dynamic> userData = query.docs.first.data() as Map<String, dynamic>;
        String role = userData['role'] ?? '';
        
        print('User role: $role');
        
        // Only allow admin and manager roles
        bool authorized = role == 'admin' || role == 'manager';
        print('Authorization result: $authorized');
        return authorized;
      }
      
      print('No user document found for email: $email');
      return false;
    } catch (e) {
      print('Error checking user authorization: $e');
      return false;
    }
  }

  // Update or create user document for Google sign-in users
  Future<void> _updateOrCreateUserDocument(User user) async {
    try {
      // Check if user document already exists
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      
      if (query.docs.isNotEmpty) {
        // Update existing document with latest info
        String docId = query.docs.first.id;
        await _firestore.collection('users').doc(docId).update({
          'name': user.displayName ?? 'Google User',
          'lastSignIn': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      // Note: We don't create new documents for Google sign-in users
      // They must already exist in Firestore to be authorized
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
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
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'network-request-failed':
        return 'Network error occurred. Please check your internet connection.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
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