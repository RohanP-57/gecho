import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../utils/helpers.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommentService _commentService = CommentService();
  final UserService _userService = UserService();
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    final error = await _commentService.addComment(
      postAuthorId: widget.post.authorId,
      postId: widget.post.id,
      content: _commentController.text.trim(),
      author: currentUser,
    );

    if (error == null) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.post.authorUsername}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
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
                  ),

                  // Image
                  if (widget.post.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error)),
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

                        // Title/Caption
                        Text(
                          widget.post.caption,
                          style: TextStyle(
                            fontSize: widget.post.isBlog ? 24 : 16,
                            fontWeight: widget.post.isBlog ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),

                        // Blog content
                        if (widget.post.isBlog && widget.post.blogContent != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.post.blogContent!,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],

                        // Tags
                        if (widget.post.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: widget.post.tags.map((tag) {
                              return Chip(
                                label: Text('#$tag'),
                                backgroundColor: Colors.blue[50],
                                labelStyle: const TextStyle(color: Colors.blue),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Stats
                        Row(
                          children: [
                            Text(
                              '${widget.post.likes.length} likes',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${widget.post.commentCount} comments',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

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

                  const Divider(),

                  // Comments section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  StreamBuilder<List<Comment>>(
                    stream: _commentService.getComments(widget.post.authorId, widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: comment.authorProfileImage != null
                                  ? CachedNetworkImageProvider(comment.authorProfileImage!)
                                  : null,
                              child: comment.authorProfileImage == null
                                  ? Text(
                                      comment.authorDisplayName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: comment.authorDisplayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' ${comment.content}'),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              Helpers.formatTimestamp(comment.createdAt.millisecondsSinceEpoch),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}