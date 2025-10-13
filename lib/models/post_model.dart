enum PostType { photo, blog }

class Post {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorProfileImage;
  final PostType type;
  final String? imageUrl;
  final String caption;
  final String? blogContent; // For blog posts
  final List<String> likes;
  final int commentCount;
  final List<String> tags;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorProfileImage,
    required this.type,
    this.imageUrl,
    required this.caption,
    this.blogContent,
    this.likes = const [],
    this.commentCount = 0,
    this.tags = const [],
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    return Post(
      id: id,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorDisplayName: map['authorDisplayName'] ?? '',
      authorProfileImage: map['authorProfileImage'],
      type: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${map['type']}',
        orElse: () => PostType.photo,
      ),
      imageUrl: map['imageUrl'],
      caption: map['caption'] ?? '',
      blogContent: map['blogContent'],
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorProfileImage': authorProfileImage,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'caption': caption,
      'blogContent': blogContent,
      'likes': likes,
      'commentCount': commentCount,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  bool get isPhoto => type == PostType.photo;
  bool get isBlog => type == PostType.blog;
}