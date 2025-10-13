import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';

class PostGridItem extends StatelessWidget {
  final Post post;

  const PostGridItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            if (post.imageUrl != null)
              CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.error)),
                ),
              )
            else
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    post.isBlog ? Icons.article : Icons.photo,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            // Post type indicator
            if (post.isBlog)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // Multiple images indicator (if needed in future)
            // Positioned(
            //   top: 8,
            //   right: 8,
            //   child: Icon(Icons.collections, color: Colors.white, size: 16),
            // ),
          ],
        ),
      ),
    );
  }
}