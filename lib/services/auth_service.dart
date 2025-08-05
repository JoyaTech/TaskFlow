import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mindflow/services/validation_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Rate limiting for security
  static final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // Session management
  static DateTime? _lastActivity;
  static const Duration _sessionTimeout = Duration(hours: 24);

  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Get user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _updateUserLastSeen(credential.user!.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) print('Unexpected sign in error: $e');
      throw AuthException('שגיאה בהתחברות: $e');
    }
  }

  /// Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        
        // Create user profile in Firestore
        await _createUserProfile(credential.user!, displayName);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) print('Unexpected sign up error: $e');
      throw AuthException('שגיאה ברישום: $e');
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) print('Sign out error: $e');
      throw AuthException('שגיאה ביציאה: $e');
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If the user is new, create a profile
          await _createUserProfile(user, user.displayName ?? 'משתמש גוגל');
        } else {
          // If user exists, update last seen
          await _updateUserLastSeen(user.uid);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Google sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) print('Unexpected Google sign in error: $e');
      throw AuthException('שגיאה בהתחברות עם גוגל: $e');
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _deleteUserData(user.uid);
        
        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      if (kDebugMode) print('Delete account error: $e');
      throw AuthException('שגיאה במחיקת החשבון: $e');
    }
  }

  /// Create user profile in Firestore
  static Future<void> _createUserProfile(User user, String displayName) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'settings': {
        'voiceEnabled': true,
        'notificationsEnabled': true,
        'wakeWord': 'היי מטלות',
        'theme': 'system',
        'language': 'he',
      },
      'stats': {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalBrainDumps': 0,
        'streak': 0,
        'lastActiveDate': null,
      },
    });
  }

  /// Update user last seen timestamp
  static Future<void> _updateUserLastSeen(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error updating last seen: $e');
    }
  }

  /// Delete all user data
  static Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();
    
    // Delete user tasks
    final tasks = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .get();
    
    for (var doc in tasks.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete user brain dumps
    final brainDumps = await _firestore
        .collection('brain_dumps')
        .where('userId', isEqualTo: uid)
        .get();
    
    for (var doc in brainDumps.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete user profile
    batch.delete(_firestore.collection('users').doc(uid));
    
    await batch.commit();
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('משתמש לא מחובר');
      
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      if (kDebugMode) print('Error updating user profile: $e');
      throw AuthException('שגיאה בעדכון פרופיל: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  static AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('המשתמש לא נמצא');
      case 'wrong-password':
        return AuthException('סיסמה שגויה');
      case 'email-already-in-use':
        return AuthException('כתובת האימייל כבר בשימוש');
      case 'weak-password':
        return AuthException('הסיסמה חלשה מדי');
      case 'invalid-email':
        return AuthException('כתובת אימייל לא תקינה');
      case 'user-disabled':
        return AuthException('החשבון הושבת');
      case 'too-many-requests':
        return AuthException('יותר מדי נסיונות. נסה שוב מאוחר יותר');
      case 'network-request-failed':
        return AuthException('בעיה בחיבור לאינטרנט');
      default:
        return AuthException('שגיאה: ${e.message}');
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 6 characters
    return password.length >= 6;
  }

  /// Get password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    return score;
  }

  /// Get password strength text in Hebrew
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'חלשה';
      case 2:
        return 'בינונית';
      case 3:
        return 'חזקה';
      case 4:
        return 'מאוד חזקה';
      default:
        return 'חלשה';
    }
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
