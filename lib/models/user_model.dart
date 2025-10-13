class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}