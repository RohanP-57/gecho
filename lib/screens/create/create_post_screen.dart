import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  final _captionController = TextEditingController();
  final _blogContentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isPhoto = true;
  bool _isLoading = false;
  bool _isPriority = false; // For admin priority posts
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userData = await _authService.getUserData(firebaseUser.uid);
        if (userData != null) {
          setState(() {
            _currentUser = userData;
          });
        } else {
          // Create a basic user model from Firebase user for demo
          setState(() {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? 'User',
              displayName: firebaseUser.displayName ?? 'User',
              userType: 'club', // Default for create screen access
              createdAt: DateTime.now(),
              isActive: true,
            );
          });
        }
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    if (_isPhoto && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isPhoto ? 'Please add a caption' : 'Please add a title')),
      );
      return;
    }

    if (!_isPhoto && _blogContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add blog content')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      String? error = await _postService.createPost(
        caption: _captionController.text.trim(),
        author: _currentUser!,
        type: _isPhoto ? PostType.photo : PostType.blog,
        imageFile: _isPhoto ? _selectedImage : null,
        blogContent: !_isPhoto ? _blogContentController.text.trim() : null,
        tags: tags,
        isPriority: _isPriority,
      );

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
        }
        _resetForm();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _captionController.clear();
      _blogContentController.clear();
      _tagsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Share'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Post type selector
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPhoto = true;
                      });
                    },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoto ? Colors.blue : Colors.grey[300],
                      foregroundColor: _isPhoto ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPhoto = false;
                        _selectedImage = null; // Clear image when switching to blog mode
                      });
                    },
                    icon: const Icon(Icons.article),
                    label: const Text('Blog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isPhoto ? Colors.blue : Colors.grey[300],
                      foregroundColor: !_isPhoto ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Image picker (only for photo posts)
            if (_isPhoto) ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
            ] else ...[
              // Blog post info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.article, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Blog posts are text-only. Focus on your writing!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Caption/Title
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: _isPhoto ? 'Caption' : 'Title',
                border: const OutlineInputBorder(),
                hintText: _isPhoto ? 'Write a caption...' : 'Enter blog title...',
              ),
              maxLines: _isPhoto ? 3 : 1,
            ),
            
            const SizedBox(height: 16),
            
            // Blog content (only for blog posts)
            if (!_isPhoto) ...[
              TextField(
                controller: _blogContentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  hintText: 'Write your blog content...',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 16),
            ],
            
            // Tags
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                border: OutlineInputBorder(),
                hintText: 'photography, travel, nature (comma separated)',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Priority option (only for admins)
            if (_currentUser?.userType == 'admin') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isPriority,
                      onChanged: (value) {
                        setState(() {
                          _isPriority = value ?? false;
                        });
                      },
                      activeColor: Colors.orange[600],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority Post',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            'Pin this post to the top of the feed for 2 days',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.push_pin,
                      color: Colors.orange[600],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _blogContentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}