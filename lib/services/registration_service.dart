import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit registration request
  Future<void> submitRegistrationRequest(Map<String, dynamic> requestData) async {
    try {
      final email = requestData['email'];
      final userType = requestData['userType'];
      
      // Domain validation: Students must have @gla.ac.in domain
      if (userType == 'student' && !email.toLowerCase().endsWith('@gla.ac.in')) {
        throw Exception('Students must use their @gla.ac.in email address.');
      }
      
      // Check if request already exists
      final existingRequest = await _firestore
          .collection('registration_requests')
          .doc(email)
          .get();
      
      if (existingRequest.exists) {
        final data = existingRequest.data()!;
        final status = data['status'];
        
        if (status == 'pending') {
          throw Exception('A pending request already exists for this email');
        } else if (status == 'approved') {
          throw Exception('This email is already approved. Please try logging in.');
        }
      }

      // Check if user is already approved
      final approvedUser = await _firestore
          .collection('approved_users')
          .doc(email)
          .get();
      
      if (approvedUser.exists) {
        throw Exception('This email is already approved. Please try logging in.');
      }

      // Create registration request
      final requestId = email; // Use email as document ID for easy lookup
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 3)); // 3 days expiry

      await _firestore.collection('registration_requests').doc(requestId).set({
        'email': email,
        'name': requestData['name'],
        'password': requestData['password'], // Store password for approval process
        'userType': requestData['userType'],
        'reason': requestData['reason'],
        'status': 'pending', // pending, approved, rejected, expired
        'submittedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiryDate),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
        
        // Student-specific fields
        if (requestData['userType'] == 'student') ...{
          'studentId': requestData['studentId'],
          'department': requestData['department'],
        },
        
        // Club-specific fields
        if (requestData['userType'] == 'club') ...{
          'clubName': requestData['clubName'],
          'clubType': requestData['clubType'],
        },
      });

      print('Registration request submitted successfully for $email');
    } catch (e) {
      print('Error submitting registration request: $e');
      rethrow;
    }
  }

  // Get registration request by email
  Future<Map<String, dynamic>?> getRegistrationRequest(String email) async {
    try {
      final doc = await _firestore
          .collection('registration_requests')
          .doc(email)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting registration request: $e');
      return null;
    }
  }

  // Check request status
  Future<String?> checkRequestStatus(String email) async {
    try {
      final request = await getRegistrationRequest(email);
      if (request != null) {
        // Check if expired
        final expiresAt = (request['expiresAt'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiresAt) && request['status'] == 'pending') {
          // Mark as expired
          await _firestore
              .collection('registration_requests')
              .doc(email)
              .update({'status': 'expired'});
          return 'expired';
        }
        return request['status'];
      }
      return null;
    } catch (e) {
      print('Error checking request status: $e');
      return null;
    }
  }

  // Admin: Approve registration request
  Future<void> approveRegistrationRequest(String email, String adminEmail) async {
    try {
      final requestDoc = await _firestore
          .collection('registration_requests')
          .doc(email)
          .get();
      
      if (!requestDoc.exists) {
        throw Exception('Registration request not found');
      }

      final requestData = requestDoc.data()!;
      
      // Check if request is still pending and not expired
      if (requestData['status'] != 'pending') {
        throw Exception('Request is no longer pending');
      }

      final expiresAt = (requestData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Request has expired');
      }

      // Determine the correct collection based on user type
      String userCollection;
      switch (requestData['userType'].toLowerCase()) {
        case 'admin':
          userCollection = 'admin_users';
          break;
        case 'student':
          userCollection = 'student_users';
          break;
        case 'club':
          userCollection = 'club_users';
          break;
        default:
          throw Exception('Invalid user type: ${requestData['userType']}');
      }

      // Create user data for the specific collection
      Map<String, dynamic> userData = {
        'email': email.toLowerCase(),
        'name': requestData['name'],
        'displayName': requestData['name'],
        'password': requestData['password'], // Store the password from registration
        'userType': requestData['userType'].toLowerCase(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminEmail,
      };

      // Add type-specific data
      if (requestData['userType'] == 'student') {
        userData['studentId'] = requestData['studentId'];
        userData['department'] = requestData['department'];
      } else if (requestData['userType'] == 'club') {
        userData['clubName'] = requestData['clubName'];
        userData['clubType'] = requestData['clubType'];
      }

      // Batch write: create user in correct collection and update request status
      final batch = _firestore.batch();
      
      // Add user to the specific collection (admin_users, student_users, or club_users)
      batch.set(
        _firestore.collection(userCollection).doc(),
        userData,
      );
      
      // Update request status
      batch.update(
        _firestore.collection('registration_requests').doc(email),
        {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminEmail,
        },
      );

      await batch.commit();
      
      print('Registration request approved for $email');
    } catch (e) {
      print('Error approving registration request: $e');
      rethrow;
    }
  }

  // Admin: Reject registration request
  Future<void> rejectRegistrationRequest(String email, String adminEmail, String reason) async {
    try {
      await _firestore
          .collection('registration_requests')
          .doc(email)
          .update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminEmail,
        'rejectionReason': reason,
      });
      
      print('Registration request rejected for $email');
    } catch (e) {
      print('Error rejecting registration request: $e');
      rethrow;
    }
  }

  // Get all pending registration requests for admin
  Stream<QuerySnapshot> getPendingRegistrationRequests() {
    return _firestore
        .collection('registration_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Get all registration requests for admin (with filters)
  Stream<QuerySnapshot> getAllRegistrationRequests({String? status}) {
    Query query = _firestore
        .collection('registration_requests')
        .orderBy('submittedAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots();
  }

  // Clean up expired requests (can be called periodically)
  Future<void> cleanupExpiredRequests() async {
    try {
      final now = Timestamp.now();
      final expiredRequests = await _firestore
          .collection('registration_requests')
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredRequests.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      if (expiredRequests.docs.isNotEmpty) {
        await batch.commit();
        print('Marked ${expiredRequests.docs.length} requests as expired');
      }
    } catch (e) {
      print('Error cleaning up expired requests: $e');
    }
  }

  // Get request statistics for admin dashboard
  Future<Map<String, int>> getRequestStatistics() async {
    try {
      final allRequests = await _firestore
          .collection('registration_requests')
          .get();

      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
      };

      for (final doc in allRequests.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'unknown';
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting request statistics: $e');
      return {};
    }
  }
}