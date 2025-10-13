import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../widgets/post_grid_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  User? _currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser!.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Settings menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _currentUser!.profileImageUrl != null
                          ? NetworkImage(_currentUser!.profileImageUrl!)
                          : null,
                      child: _currentUser!.profileImageUrl == null
                          ? Text(
                              _currentUser!.displayName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Stats
                    Expanded(
                      child: Center(
                        child: _buildStatColumn('Posts', _currentUser!.postsCount),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Name and bio
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser!.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_currentUser!.bio != null) ...[
                        const SizedBox(height: 4),
                        Text(_currentUser!.bio!),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Edit profile button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Edit profile
                    },
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.photo_library),
                text: 'Photos',
              ),
              Tab(
                icon: Icon(Icons.article),
                text: 'Blogs',
              ),
            ],
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Photos tab
                _buildPostsGrid(PostType.photo),
                // Blogs tab
                _buildPostsGrid(PostType.blog),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(PostType postType) {
    return StreamBuilder<List<Post>>(
      stream: _postService.getUserPosts(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPosts = snapshot.data ?? [];
        final filteredPosts = allPosts.where((post) => post.type == postType).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  postType == PostType.photo ? Icons.photo_library : Icons.article,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  postType == PostType.photo ? 'No photos yet' : 'No blogs yet',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  postType == PostType.photo 
                      ? 'Share your first photo!' 
                      : 'Write your first blog post!',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (postType == PostType.photo) {
          // Grid view for photos
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              return PostGridItem(post: filteredPosts[index]);
            },
          );
        } else {
          // List view for blogs
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: post.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.article),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.article, color: Colors.blue),
                        ),
                  title: Text(
                    post.caption,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.blogContent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          post.blogContent!.length > 100
                              ? '${post.blogContent!.substring(0, 100)}...'
                              : post.blogContent!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.likes.length}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to post detail
                    Navigator.pushNamed(context, '/post_detail', arguments: post);
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}