import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../feed/feed_screen.dart';
import '../create/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../explore/explore_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userType = 'student'; // Default to student
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userData = await _authService.getUserData(currentUser.uid);
        if (userData != null) {
          setState(() {
            _userType = userData.userType;
            _isLoading = false;
          });
        } else {
          // Fallback: determine user type from email for demo
          final email = currentUser.email?.toLowerCase() ?? '';
          if (email.contains('admin')) {
            _userType = 'admin';
          } else if (email.contains('club')) {
            _userType = 'club';
          } else {
            _userType = 'student';
          }
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // For demo purposes, determine from stored login
        _userType = 'student'; // Default
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        _userType = 'student';
        _isLoading = false;
      });
    }
  }

  List<Widget> get _screens {
    if (_userType == 'student') {
      // Students only see Feed, Explore, and Profile
      return [
        const FeedScreen(),
        const ExploreScreen(),
        ProfileScreen(onLogout: widget.onLogout),
      ];
    } else {
      // Clubs and Admins see all screens including Create
      return [
        const FeedScreen(),
        const ExploreScreen(),
        const CreatePostScreen(),
        ProfileScreen(onLogout: widget.onLogout),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_userType == 'student') {
      // Students only see Feed, Explore, and Profile
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Feed',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Clubs and Admins see all tabs including Create
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Feed',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}