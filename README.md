# Social Media Platform

A modern Flutter social media app where users can share photos and write blog posts.

## Features

- 📸 **Photo Sharing** - Upload and share photos with captions and tags
- ✍️ **Blog Posts** - Write and publish blog posts with optional cover images
- 🏠 **Feed** - Browse posts from all users in chronological order
- 🔍 **Explore** - Discover posts in a grid layout
- 👤 **Profile** - View user profiles with post grids and stats
- ❤️ **Interactions** - Like and comment on posts
- 🏷️ **Tags** - Organize content with hashtags

## Screenshots

*Coming soon...*

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/
│   ├── user_model.dart         # User data model
│   ├── post_model.dart         # Post data model
│   └── comment_model.dart      # Comment data model
├── screens/
│   ├── home/
│   │   └── home_screen.dart    # Main navigation screen
│   ├── feed/
│   │   └── feed_screen.dart    # Posts feed
│   ├── explore/
│   │   └── explore_screen.dart # Explore posts grid
│   ├── create/
│   │   └── create_post_screen.dart # Create photo/blog posts
│   └── profile/
│       └── profile_screen.dart # User profile
├── services/
│   ├── user_service.dart       # User data management
│   ├── post_service.dart       # Post data management
│   └── comment_service.dart    # Comment management
├── utils/
│   └── helpers.dart           # Utility functions
└── widgets/
    ├── post_card.dart         # Post display widget
    ├── post_grid_item.dart    # Grid post item
    └── post_detail_screen.dart # Full post view
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Firebase project with:
  - Firestore Database
  - Firebase Storage
  - Firebase Authentication (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd social-media-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Update `lib/firebase_options.dart` with your config

4. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Setup

### Firestore Collections

The app uses these Firestore collections:

- **users** - User profiles and metadata
- **posts** - Photo and blog posts
- **comments** - Post comments

### Storage Structure

Firebase Storage is organized as:
- `posts/` - Photo post images
- `blog_covers/` - Blog post cover images

### Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read all posts and comments
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /comments/{commentId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Features in Detail

### Photo Posts
- Upload images from gallery
- Add captions and tags
- Automatic image optimization
- Grid and feed display

### Blog Posts
- Rich text content
- Optional cover images
- Tag support
- Full-screen reading view

### User Profiles
- Display name and bio
- Follower/following counts
- Post grid view
- Profile statistics

### Interactions
- Like/unlike posts
- Comment on posts
- Share functionality (coming soon)

## Dependencies

- `firebase_core` - Firebase initialization
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `intl` - Date formatting
- `uuid` - Unique ID generation

## Development

### Adding New Features

1. Create models in `lib/models/`
2. Add services in `lib/services/`
3. Build screens in `lib/screens/`
4. Create reusable widgets in `lib/widgets/`

### Testing

Sample data is automatically created when the app first runs, including:
- 3 demo users
- Sample photo and blog posts
- Test comments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes.

## Support

For issues and questions, please create an issue in the repository.