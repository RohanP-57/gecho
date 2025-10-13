import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../utils/helpers.dart';
import 'post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  void _checkIfLiked() {
    _isLiked = widget.post.likes.contains(UserService.currentUserId);
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });

    await _postService.toggleLike(widget.post.authorId, widget.post.id, UserService.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            title: Text(
              widget.post.authorDisplayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${widget.post.authorUsername}'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options menu
              },
            ),
          ),

          // Image (for photo posts or blog cover)
          if (widget.post.imageUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: widget.post),
                  ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(post: widget.post),
                        ),
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
                  Helpers.formatTimestamp(widget.post.createdAt.millisecondsSinceEpoch),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: widget.post),
                      ),
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