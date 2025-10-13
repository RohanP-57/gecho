import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Helpers {
  // Date formatting
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Format timestamp from Firestore
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // Format like count
  static String formatLikeCount(int count) {
    if (count == 0) return 'No likes';
    if (count == 1) return '1 like';
    if (count < 1000) return '$count likes';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K likes';
    return '${(count / 1000000).toStringAsFixed(1)}M likes';
  }

  // Format comment count
  static String formatCommentCount(int count) {
    if (count == 0) return 'No comments';
    if (count == 1) return '1 comment';
    if (count < 1000) return '$count comments';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K comments';
    return '${(count / 1000000).toStringAsFixed(1)}M comments';
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Get initials from name
  static String getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    
    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    
    return initials.isEmpty ? 'U' : initials;
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}