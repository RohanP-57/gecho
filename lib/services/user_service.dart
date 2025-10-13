import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Current user (simplified - in real app this would come from auth)
  static const String currentUserId = 'current_user';

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  // Create dummy users for testing
  Future<void> createDummyUsers() async {
    // Check if users already exist
    final existingUsers = await _firestore.collection('users').limit(1).get();
    if (existingUsers.docs.isNotEmpty) {
      return; // Users already exist
    }

    final users = [
      User(
        id: currentUserId,
        username: 'john_doe',
        email: 'john@example.com',
        displayName: 'John Doe',
        bio: 'Photography enthusiast and blogger 📸✍️',
        followersCount: 1250,
        followingCount: 340,
        postsCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      User(
        id: 'user_2',
        username: 'sarah_wilson',
        email: 'sarah@example.com',
        displayName: 'Sarah Wilson',
        bio: 'Travel blogger | Coffee lover ☕ | Exploring the world 🌍',
        followersCount: 2100,
        followingCount: 180,
        postsCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      User(
        id: 'user_3',
        username: 'mike_photo',
        email: 'mike@example.com',
        displayName: 'Mike Photography',
        bio: 'Professional photographer | Nature lover 🌲',
        followersCount: 5600,
        followingCount: 120,
        postsCount: 234,
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
      ),
    ];

    for (final user in users) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    }
  }
}