import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with university credentials (email/password)
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      // Check if user is pre-approved in university database
      final userDoc = await _firestore.collection('approved_users').doc(email).get();
      
      if (!userDoc.exists) {
        throw Exception('Access denied. Contact university administration.');
      }

      // Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user data from Firestore
        return await getUserData(result.user!.uid);
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Check if user is approved by university
  Future<bool> isUserApproved(String email) async {
    try {
      final doc = await _firestore.collection('approved_users').doc(email).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user approval: $e');
      return false;
    }
  }

  // Admin function: Add approved user (only for university admin)
  Future<void> addApprovedUser({
    required String email,
    required String userType, // 'student' or 'club'
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Add to approved users collection
      await _firestore.collection('approved_users').doc(email).set({
        'email': email,
        'userType': userType,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser?.email ?? 'admin',
        ...userData,
      });

      print('User $email approved successfully');
    } catch (e) {
      print('Error adding approved user: $e');
      rethrow;
    }
  }

  // Create user account after approval (called during first login)
  Future<UserModel?> createUserAccount({
    required String email,
    required String password,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Check if user is approved
      if (!await isUserApproved(email)) {
        throw Exception('User not approved by university administration');
      }

      // Create Firebase Auth account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          userType: userType,
          createdAt: DateTime.now(),
          isActive: true,
          ...userData,
        );

        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toFirestore());
        
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error creating user account: $e');
      rethrow;
    }
  }

  // Reset password (for approved users only)
  Future<void> resetPassword(String email) async {
    try {
      // Check if user is approved
      if (!await isUserApproved(email)) {
        throw Exception('Email not found in university system');
      }

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }
}