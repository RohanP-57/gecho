import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'image_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  final Uuid _uuid = const Uuid();

  // Get all posts from all users (for feed)
  Stream<List<Post>> getPosts() {
    // Get posts from all known users
    return _getAllPostsFromKnownUsers();
  }

  // Get posts from all known users
  Stream<List<Post>> _getAllPostsFromKnownUsers() async* {
    final knownUsers = ['current_user', 'user_2', 'user_3']; // Add more user IDs as needed
    
    // Create a list to hold all posts
    List<Post> allPosts = [];
    
    // Get posts from each user
    for (String userId in knownUsers) {
      try {
        final userPosts = await _firestore
            .collection('users')
            .doc(userId)
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .get();
        
        final posts = userPosts.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList();
        
        allPosts.addAll(posts);
      } catch (e) {
        print('Error getting posts for user $userId: $e');
      }
    }
    
    // Sort all posts by creation date
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    yield allPosts;
    
    // Set up real-time updates by listening to each user's posts
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      allPosts.clear();
      
      for (String userId in knownUsers) {
        try {
          final userPosts = await _firestore
              .collection('users')
              .doc(userId)
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .get();
          
          final posts = userPosts.docs
              .map((doc) => Post.fromMap(doc.data(), doc.id))
              .toList();
          
          allPosts.addAll(posts);
        } catch (e) {
          print('Error getting posts for user $userId: $e');
        }
      }
      
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield allPosts;
    }
  }

  // Alternative method for when index is ready
  Stream<List<Post>> getAllPostsWithIndex() {
    return _firestore
        .collectionGroup('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get posts by specific user
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single post
  Future<Post?> getPost(String userId, String postId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists) {
        return Post.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  // Create photo post
  Future<String?> createPhotoPost({
    required File imageFile,
    required String caption,
    required User author,
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      String? imageUrl;
      
      // Upload image to Cloudinary
      imageUrl = await _imageService.uploadImage(
        imageFile: imageFile,
        userId: author.id,
        postId: postId,
        folder: 'posts',
      );
      
      if (imageUrl != null) {
        print('Image uploaded successfully to Cloudinary: $imageUrl');
      } else {
        print('Cloudinary upload failed');
        return 'Failed to upload image. Please check your internet connection and try again.';
      }

      // Create post in user's posts collection
      final post = Post(
        id: postId,
        authorId: author.id,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImage: author.profileImageUrl,
        type: PostType.photo,
        imageUrl: imageUrl,
        caption: caption,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Save to user's posts collection
      await _firestore
          .collection('users')
          .doc(author.id)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCount(author.id);

      return null; // Success
    } catch (e) {
      print('Error creating photo post: $e');
      return 'Failed to create photo post: ${e.toString()}';
    }
  }

  // Create blog post (text-only, no images)
  Future<String?> createBlogPost({
    required String title,
    required String content,
    required User author,
    File? coverImage, // This parameter is kept for compatibility but ignored
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      
      // Blog posts are text-only - no images allowed
      print('Creating text-only blog post');

      // Create blog post
      final post = Post(
        id: postId,
        authorId: author.id,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImage: author.profileImageUrl,
        type: PostType.blog,
        imageUrl: null, // Blog posts have no images
        caption: title,
        blogContent: content,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // Save to user's posts collection
      await _firestore
          .collection('users')
          .doc(author.id)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      // Update user's post count
      await _updateUserPostCount(author.id);

      return null; // Success
    } catch (e) {
      return 'Failed to create blog post: ${e.toString()}';
    }
  }

  // Delete post (only by post owner)
  Future<String?> deletePost(String userId, String postId, String? imageUrl) async {
    try {
      // Delete from user's posts collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .delete();
      
      // Delete image from Cloudinary if exists
      if (imageUrl != null && imageUrl.contains('cloudinary.com')) {
        try {
          // Extract public_id from Cloudinary URL for deletion
          final publicId = 'posts/$userId/$postId';
          await _imageService.deleteImage(publicId);
          print('Image deleted from Cloudinary');
        } catch (e) {
          print('Error deleting image from Cloudinary: $e');
        }
      }

      // Delete all comments for this post
      final commentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Update user's post count
      await _updateUserPostCount(userId);
      
      return null; // Success
    } catch (e) {
      return 'Failed to delete post: ${e.toString()}';
    }
  }

  // Toggle like on post
  Future<void> toggleLike(String userId, String postId, String currentUserId) async {
    final postRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('posts')
        .doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;
      
      final post = Post.fromMap(postDoc.data()!, postId);
      List<String> likes = List.from(post.likes);
      
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }
      
      transaction.update(postRef, {'likes': likes});
    });
  }

  // Update user's post count
  Future<void> _updateUserPostCount(String userId) async {
    final postsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('posts')
        .get();
    
    await _firestore.collection('users').doc(userId).update({
      'postsCount': postsSnapshot.docs.length,
    });
  }

  // Update existing posts with image URLs
  Future<void> updateExistingPostsWithImages() async {
    try {
      final postsSnapshot = await _firestore
          .collection('users')
          .doc('current_user')
          .collection('posts')
          .get();

      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'photo' && data['imageUrl'] == null) {
          await doc.reference.update({
            'imageUrl': 'https://picsum.photos/400/600?random=${doc.id.hashCode}',
          });
        }
      }
      print('Updated existing posts with image URLs');
    } catch (e) {
      print('Error updating posts: $e');
    }
  }

  // Create dummy posts for testing
  Future<void> createDummyPosts() async {
    try {
      // Check if posts already exist for current user
      final existingPosts = await _firestore
          .collection('users')
          .doc('current_user')
          .collection('posts')
          .limit(1)
          .get();
      
      if (existingPosts.docs.isNotEmpty) {
        return; // Posts already exist
      }

      final posts = [
        {
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
          'authorProfileImage': null,
          'type': 'photo',
          'imageUrl': 'https://picsum.photos/400/600?random=1',
          'caption': 'Beautiful sunset from my evening walk 🌅 #photography #nature',
          'blogContent': null,
          'likes': ['user_2', 'user_3'],
          'commentCount': 5,
          'tags': ['photography', 'nature', 'sunset'],
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'authorId': 'current_user',
          'authorUsername': 'john_doe',
          'authorDisplayName': 'John Doe',
          'authorProfileImage': null,
          'type': 'blog',
          'imageUrl': null,
          'caption': 'My Journey into Photography',
          'blogContent': '''
Photography has been my passion for over 5 years now. It all started with a simple smartphone camera, but the desire to capture the perfect moment drove me to learn more about composition, lighting, and storytelling through images.

**The Beginning**
I remember my first "real" photo - a candid shot of my friend laughing at a coffee shop. The natural light streaming through the window, the genuine expression, the way everything just came together perfectly. That's when I knew I wanted to pursue photography seriously.

**Learning the Craft**
I spent countless hours watching YouTube tutorials, reading photography blogs, and most importantly, practicing. Every day I would challenge myself to take at least one photo that told a story or captured an emotion.

**Equipment Evolution**
While gear doesn't make the photographer, having the right tools certainly helps. I started with a basic DSLR and gradually upgraded my lenses and equipment as I learned what type of photography I was most passionate about.

**Finding My Style**
After experimenting with various genres - portraits, landscapes, street photography, macro - I discovered that I love capturing candid moments and natural emotions. There's something magical about freezing a genuine smile or a thoughtful expression.

**The Future**
Photography continues to challenge and inspire me every day. Each shoot teaches me something new, and I'm constantly amazed by the stories that can be told through a single frame.

What started as a hobby has become a way of seeing the world differently. Through the lens, I've learned to notice the extraordinary in the ordinary, and that perspective has enriched my life in countless ways.

Keep shooting, keep learning, and most importantly, keep having fun with it! 📸
          ''',
          'likes': ['user_2'],
          'commentCount': 8,
          'tags': ['photography', 'journey', 'passion', 'blog'],
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
        },
      ];

      // Create posts for current user
      for (final postData in posts) {
        final postId = _uuid.v4();
        await _firestore
            .collection('users')
            .doc('current_user')
            .collection('posts')
            .doc(postId)
            .set(postData);
      }

      // Create posts for other users
      final otherUserPosts = [
        {
          'userId': 'user_2',
          'postData': {
            'authorId': 'user_2',
            'authorUsername': 'sarah_wilson',
            'authorDisplayName': 'Sarah Wilson',
            'authorProfileImage': null,
            'type': 'blog',
            'imageUrl': null,
            'caption': '10 Tips for Better Travel Photography',
            'blogContent': '''
Travel photography is an art that combines technical skill with creative vision. Here are my top 10 tips for capturing amazing photos on your next adventure:

1. **Golden Hour Magic**: Shoot during the golden hour (just after sunrise or before sunset) for warm, soft lighting that makes everything look magical.

2. **Tell a Story**: Don't just capture landmarks. Include people, local culture, and candid moments that tell the story of your journey.

3. **Pack Light**: Bring only essential gear. A heavy camera bag will slow you down and make you less likely to take spontaneous shots.

4. **Research Locations**: Scout locations online before you arrive. Apps like PhotoPills can help you plan the perfect shot.

5. **Interact with Locals**: Some of the best travel photos come from genuine interactions with local people. Always ask permission before photographing someone.

6. **Capture Details**: Don't forget the small details - local food, architecture details, street signs, and textures that make each place unique.

7. **Use Leading Lines**: Look for natural lines in the landscape or architecture that draw the viewer's eye into the photo.

8. **Weather is Your Friend**: Don't pack up when the weather gets interesting. Storm clouds, rain, and fog can create dramatic and memorable images.

9. **Backup Everything**: Always have multiple backup solutions for your photos. Memory cards fail, and losing travel photos is heartbreaking.

10. **Edit Thoughtfully**: Post-processing can enhance your photos, but don't overdo it. Keep the natural beauty of the places you visit.

Remember, the best camera is the one you have with you. Sometimes the most memorable shots come from unexpected moments, so always be ready!

Happy travels and happy shooting! 📸✈️
            ''',
            'likes': ['current_user', 'user_3'],
            'commentCount': 12,
            'tags': ['travel', 'photography', 'tips', 'blog'],
            'createdAt': DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch,
          }
        },
        {
          'userId': 'user_3',
          'postData': {
            'authorId': 'user_3',
            'authorUsername': 'mike_photo',
            'authorDisplayName': 'Mike Photography',
            'authorProfileImage': null,
            'type': 'photo',
            'imageUrl': null,
            'caption': 'Morning coffee and planning the next shoot ☕📷 #photographer #coffee #workflow',
            'blogContent': null,
            'likes': ['current_user'],
            'commentCount': 3,
            'tags': ['photographer', 'coffee', 'workflow'],
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          }
        }
      ];

      // Create posts for other users
      for (final userPost in otherUserPosts) {
        final postId = _uuid.v4();
        await _firestore
            .collection('users')
            .doc(userPost['userId'] as String)
            .collection('posts')
            .doc(postId)
            .set(userPost['postData'] as Map<String, dynamic>);
      }

      // Update post counts for all users
      await _updateUserPostCount('current_user');
      await _updateUserPostCount('user_2');
      await _updateUserPostCount('user_3');

    } catch (e) {
      print('Error creating dummy posts: $e');
    }
  }
}