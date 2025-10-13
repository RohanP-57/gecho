class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorProfileImage;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorProfileImage,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorDisplayName: map['authorDisplayName'] ?? '',
      authorProfileImage: map['authorProfileImage'],
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}