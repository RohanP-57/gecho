import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Get comments for a specific post
  Stream<List<Comment>> getComments(String postAuthorId, String postId) {
    return _firestore
        .collection('users')
        .doc(postAuthorId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add comment to a post
  Future<String?> addComment({
    required String postAuthorId,
    required String postId,
    required String content,
    required User author,
  }) async {
    try {
      final commentId = _uuid.v4();
      final comment = Comment(
        id: commentId,
        postId: postId,
        authorId: author.id,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImage: author.profileImageUrl,
        content: content,
        createdAt: DateTime.now(),
      );

      // Add comment to the post's comments subcollection
      await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());
      
      // Update comment count in the post
      await _updateCommentCount(postAuthorId, postId);
      
      return null; // Success
    } catch (e) {
      return 'Failed to add comment: ${e.toString()}';
    }
  }

  // Delete comment (only by comment author)
  Future<String?> deleteComment({
    required String postAuthorId,
    required String postId,
    required String commentId,
    required String commentAuthorId,
  }) async {
    try {
      // Verify the user is deleting their own comment
      final commentDoc = await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return 'Comment not found';
      }

      final comment = Comment.fromMap(commentDoc.data()!, commentId);
      if (comment.authorId != commentAuthorId) {
        return 'You can only delete your own comments';
      }

      // Delete the comment
      await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count
      await _updateCommentCount(postAuthorId, postId);
      
      return null; // Success
    } catch (e) {
      return 'Failed to delete comment: ${e.toString()}';
    }
  }

  // Update comment count in post
  Future<void> _updateCommentCount(String postAuthorId, String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();
      
      await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .update({
        'commentCount': commentsSnapshot.docs.length,
      });
    } catch (e) {
      print('Error updating comment count: $e');
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postAuthorId, String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();
      
      return commentsSnapshot.docs.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  // Create dummy comments for testing
  Future<void> createDummyComments() async {
    try {
      // Add some comments to the first post
      final dummyComments = [
        {
          'postAuthorId': 'current_user',
          'content': 'Amazing shot! The lighting is perfect 📸',
          'authorId': 'user_2',
          'authorUsername': 'sarah_wilson',
          'authorDisplayName': 'Sarah Wilson',
        },
        {
          'postAuthorId': 'current_user',
          'content': 'Love this! Where was this taken?',
          'authorId': 'user_3',
          'authorUsername': 'mike_photo',
          'authorDisplayName': 'Mike Photography',
        },
        {
          'postAuthorId': 'user_2',
          'content': 'Great tips! Especially the golden hour advice 🌅',
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
        },
      ];

      // Get the first post from current_user to add comments
      final postsSnapshot = await _firestore
          .collection('users')
          .doc('current_user')
          .collection('posts')
          .limit(1)
          .get();

      if (postsSnapshot.docs.isNotEmpty) {
        final postId = postsSnapshot.docs.first.id;
        
        for (final commentData in dummyComments.take(2)) {
          final commentId = _uuid.v4();
          final comment = {
            'postId': postId,
            'authorId': commentData['authorId'],
            'authorUsername': commentData['authorUsername'],
            'authorDisplayName': commentData['authorDisplayName'],
            'authorProfileImage': null,
            'content': commentData['content'],
            'createdAt': DateTime.now().subtract(
              Duration(hours: dummyComments.indexOf(commentData) + 1)
            ).millisecondsSinceEpoch,
          };

          await _firestore
              .collection('users')
              .doc('current_user')
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .doc(commentId)
              .set(comment);
        }

        // Update comment count
        await _updateCommentCount('current_user', postId);
      }

      // Add comment to user_2's post
      final user2PostsSnapshot = await _firestore
          .collection('users')
          .doc('user_2')
          .collection('posts')
          .limit(1)
          .get();

      if (user2PostsSnapshot.docs.isNotEmpty) {
        final postId = user2PostsSnapshot.docs.first.id;
        final commentId = _uuid.v4();
        final comment = {
          'postId': postId,
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
          'authorProfileImage': null,
          'content': 'Great tips! Especially the golden hour advice 🌅',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        };

        await _firestore
            .collection('users')
            .doc('user_2')
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set(comment);

        await _updateCommentCount('user_2', postId);
      }

    } catch (e) {
      print('Error creating dummy comments: $e');
    }
  }
}