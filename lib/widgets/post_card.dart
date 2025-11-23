import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _checkIfLiked();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userData = await _authService.getUserData(firebaseUser.uid);
        setState(() {
          _currentUser = userData;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  void _checkIfLiked() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _isLiked = widget.post.likes.contains(currentUserId);
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });

    // TODO: Implement like functionality with new post service
    // await _postService.toggleLike(widget.post.id, currentUserId);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postService.deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: $e')),
          );
        }
      }
    }
  }

  bool get _canDeletePost {
    if (_currentUser == null) return false;
    
    // Admins can delete club and student posts, but not other admin posts
    if (_currentUser!.userType == 'admin') {
      return widget.post.authorType != 'admin';
    }
    
    // Users can delete their own posts
    return _currentUser!.uid == widget.post.authorId;
  }

  bool get _isPriorityActive {
    if (!widget.post.isPriority) return false;
    if (widget.post.priorityExpiresAt == null) return true;
    return widget.post.priorityExpiresAt!.isAfter(DateTime.now());
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Colors.red[600]!;
      case 'club':
        return Colors.blue[600]!;
      case 'student':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator
          if (_isPriorityActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Priority Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Expires ${_formatTimestamp(widget.post.priorityExpiresAt!.millisecondsSinceEpoch)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorProfileImage != null
                  ? CachedNetworkImageProvider(widget.post.authorProfileImage!)
                  : null,
              child: widget.post.authorProfileImage == null
                  ? Text(widget.post.authorDisplayName[0].toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Text(
                  widget.post.authorDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                // User type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(widget.post.authorType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.post.authorType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text('@${widget.post.authorUsername}'),
            trailing: _canDeletePost
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No actions available')),
                      );
                    },
                  ),
          ),

          // Image (for photo posts or blog cover)
          if (widget.post.imageUrl != null)
            GestureDetector(
              onTap: () {
                // Navigate to post detail (placeholder)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post detail view coming soon!')),
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrl!,
                width: double.infinity,
                height: widget.post.isPhoto ? 300 : 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: widget.post.isPhoto ? 300 : 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: widget.post.isPhoto ? 300 : 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.error)),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post type indicator
                if (widget.post.isBlog)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Blog Post',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (widget.post.isBlog) const SizedBox(height: 8),

                // Caption/Title
                Text(
                  widget.post.caption,
                  style: TextStyle(
                    fontSize: widget.post.isBlog ? 18 : 14,
                    fontWeight: widget.post.isBlog ? FontWeight.bold : FontWeight.normal,
                  ),
                ),

                // Blog preview
                if (widget.post.isBlog && widget.post.blogContent != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.blogContent!.length > 150
                        ? '${widget.post.blogContent!.substring(0, 150)}...'
                        : widget.post.blogContent!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to post detail (placeholder)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Read more coming soon!')),
                      );
                    },
                    child: const Text('Read more'),
                  ),
                ],

                // Tags
                if (widget.post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.post.tags.map((tag) {
                      return Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // Timestamp
                Text(
                  _formatTimestamp(widget.post.createdAt.millisecondsSinceEpoch),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('${widget.post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // Navigate to post detail (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comments coming soon!')),
                    );
                  },
                ),
                Text('${widget.post.commentCount}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    // Share functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}