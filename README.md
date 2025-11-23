# 🎓 University Portal - Student & Club Platform

A comprehensive Flutter-based social platform designed specifically for university students and clubs, featuring Google Authentication, domain validation, and a web-based admin panel.

## 🌟 Features

### 📱 **Mobile App (Students & Clubs)**
- 🔐 **Google Authentication** - Secure login with university Google accounts
- 📸 **Photo Sharing** - Upload and share photos with captions and tags
- ✍️ **Blog Posts** - Write and publish blog posts with optional cover images
- 🏠 **Feed** - Browse posts from students and clubs
- 🔍 **Explore** - Discover content in a grid layout
- 👤 **Profile** - Student/club profiles with verification badges
- ❤️ **Interactions** - Like and comment on posts
- 🏷️ **Tags** - Organize content with hashtags
- 🎯 **Domain Validation** - Students must use @gla.ac.in emails

### 🌐 **Web Admin Panel**
- 👨‍💼 **Admin Dashboard** - Web-based administration interface
- ✅ **User Approval** - Approve student and club registrations
- 📋 **Registration Management** - Review pending access requests
- 🔍 **User Monitoring** - View approved users and their details
- 🚀 **Firebase Hosting** - Deployed admin panel for easy access

## Screenshots

*Coming soon...*

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point with routing
├── firebase_options.dart        # Firebase configuration
├── models/
│   ├── user_model.dart         # University user data model
│   ├── post_model.dart         # Post data model
│   └── comment_model.dart      # Comment data model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart   # Google Auth login
│   │   ├── register_screen.dart # Registration request
│   │   └── registration_screen.dart # User registration
│   ├── admin/
│   │   ├── admin_login_screen.dart # Web admin login
│   │   └── admin_panel.dart    # Admin dashboard
│   ├── home/
│   │   └── home_screen.dart    # Main navigation
│   ├── feed/
│   │   └── feed_screen.dart    # Posts feed
│   ├── explore/
│   │   └── explore_screen.dart # Explore posts
│   ├── create/
│   │   └── create_post_screen.dart # Create posts
│   └── profile/
│       └── profile_screen.dart # User profiles
├── services/
│   ├── auth_service.dart       # Google Auth & domain validation
│   ├── registration_service.dart # Registration management
│   ├── user_service.dart       # User data management
│   ├── post_service.dart       # Post data management
│   ├── comment_service.dart    # Comment management
│   └── image_service.dart      # Image handling
├── utils/
│   └── helpers.dart           # Utility functions
└── widgets/
    ├── post_card.dart         # Post display widget
    ├── post_grid_item.dart    # Grid post item
    └── post_detail_screen.dart # Full post view

web/
├── index.html                  # Web app entry point
└── favicon.png                 # Web app icon

deploy_admin.sh                 # Web deployment script
firebase.json                   # Firebase hosting config
firestore.rules                 # Database security rules
storage.rules                   # Storage security rules
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8+)
- Firebase project with:
  - Firestore Database
  - Firebase Storage
  - Firebase Authentication
  - Firebase Hosting (for admin panel)
- Google Cloud Console project for OAuth
- Node.js & Firebase CLI (for web deployment)

### 📱 Mobile App Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd university-portal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your config

4. **Configure Google Sign-In**
   - Enable Google Sign-In in Firebase Console
   - Add your SHA-1 fingerprint for Android
   - Configure OAuth consent screen in Google Cloud Console

5. **Run the mobile app**
   ```bash
   flutter run
   ```

### 🌐 Web Admin Panel Setup

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase Hosting**
   ```bash
   firebase init hosting
   ```

4. **Configure Google Sign-In for Web**
   - Add your domain to authorized domains in Firebase Console
   - Update web OAuth client ID in Google Cloud Console

5. **Deploy Admin Panel**
   ```bash
   chmod +x deploy_admin.sh
   ./deploy_admin.sh
   ```

### 🔧 Environment Configuration

Create a `.env` file (optional) for environment-specific settings:
```env
FIREBASE_PROJECT_ID=your-project-id
ADMIN_EMAIL_DOMAIN=@gla.ac.in
STUDENT_EMAIL_DOMAIN=@gla.ac.in
```

## 🔥 Firebase Setup

### 📊 Firestore Collections

The app uses these Firestore collections:

- **users** - University user profiles and metadata
- **approved_users** - Pre-approved students and clubs
- **registration_requests** - Pending access requests
- **posts** - Photo and blog posts
- **comments** - Post comments

### 📁 Storage Structure

Firebase Storage is organized as:
- `posts/` - Photo post images
- `blog_covers/` - Blog post cover images
- `profiles/` - User profile pictures


## 🎯 Features in Detail

### 🔐 Authentication & Access Control
- **Google Sign-In Integration** - Seamless authentication with university accounts
- **Domain Validation** - Students must use @gla.ac.in email addresses
- **Club Flexibility** - Clubs can use any university email domain
- **Admin Approval System** - All users must be pre-approved by university administration
- **Registration Requests** - Students and clubs can request access through the app

### 📸 Photo Posts
- Upload images from gallery with university content guidelines
- Add captions and tags relevant to university life
- Automatic image optimization for mobile and web
- Grid and feed display optimized for student engagement

### ✍️ Blog Posts
- Rich text content for academic and club announcements
- Optional cover images for enhanced visual appeal
- Tag support for categorizing university content
- Full-screen reading view optimized for mobile devices

### 👤 User Profiles
- **Student Profiles** - Display student ID, department, and year
- **Club Profiles** - Show club name, type, and member count
- University verification badges for authenticated users
- Post grid view with engagement statistics
- Profile statistics including followers and university role

### ❤️ Interactions
- Like/unlike posts with university community engagement
- Comment system with moderation capabilities
- Share functionality for university events and announcements
- Tag system for organizing university content

### 🌐 Web Admin Panel
- **User Management** - Approve/reject student and club registrations
- **Content Moderation** - Monitor posts and comments for university guidelines
- **Analytics Dashboard** - View platform usage and engagement metrics
- **Bulk Operations** - Manage multiple users and content efficiently

## 📦 Dependencies

### Core Dependencies
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication with Google Sign-In
- `cloud_firestore` - Firestore database
- `firebase_storage` - File storage
- `google_sign_in` - Google authentication integration

### UI & Media
- `image_picker` - Image selection from gallery/camera
- `cached_network_image` - Optimized image caching and display
- `cupertino_icons` - iOS-style icons

### Utilities
- `intl` - Date formatting and internationalization
- `uuid` - Unique ID generation for posts and comments
- `http` - HTTP requests for API calls
- `crypto` - Cryptographic functions for security

### Development
- `flutter_lints` - Code analysis and linting
- `flutter_test` - Testing framework

## 🛠️ Development

### Adding New Features

1. **Models** - Create data models in `lib/models/` for new entities
2. **Services** - Add business logic in `lib/services/` for data management
3. **Screens** - Build UI screens in `lib/screens/` following the existing structure
4. **Widgets** - Create reusable components in `lib/widgets/`
5. **Authentication** - Ensure new features respect university domain validation

### 🧪 Testing

The app includes comprehensive testing setup:
- **Unit Tests** - Test business logic and services
- **Widget Tests** - Test UI components and screens
- **Integration Tests** - Test complete user flows
- **Sample Data** - Demo users and content for development

### 🔧 Development Workflow

1. **Mobile Development**
   ```bash
   flutter run --debug
   flutter test
   flutter analyze
   ```

2. **Web Admin Development**
   ```bash
   flutter run -d chrome --web-port 8080
   flutter build web --release
   ```

3. **Firebase Emulator (Optional)**
   ```bash
   firebase emulators:start
   ```

## 🚀 Deployment

### 📱 Mobile App Deployment

1. **Android**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

2. **iOS**
   ```bash
   flutter build ios --release
   ```

### 🌐 Web Admin Panel Deployment

1. **Automatic Deployment**
   ```bash
   ./deploy_admin.sh
   ```

2. **Manual Deployment**
   ```bash
   flutter build web --release --base-href "/admin/"
   firebase deploy --only hosting
   ```

### 🔗 Access URLs

After deployment:
- **Mobile App**: Available through app stores or direct APK
- **Admin Panel**: `https://your-project-id.web.app/admin`
- **Main Web App**: `https://your-project-id.web.app/`

## 🎯 University-Specific Configuration

### Domain Settings
- **Student Domain**: `@gla.ac.in` (enforced)
- **Club Domains**: Any university email (flexible)
- **Admin Access**: Configurable in `main.dart`

### Content Guidelines
- University-appropriate content only
- Academic and club-focused posts
- Moderated comment system
- Tag-based content organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow university coding standards
4. Test with university email domains
5. Submit a pull request with detailed description

### Code Standards
- Follow Flutter/Dart conventions
- Maintain university domain validation
- Ensure web admin panel compatibility
- Test on both mobile and web platforms

## 📄 License

This project is developed for educational purposes and university use.

## 🆘 Support

### For Students & Clubs
- Contact university IT support
- Submit registration requests through the app
- Check with student services for account activation

### For Developers
- Create issues in the repository
- Follow the contribution guidelines
- Test with university email domains

### For Administrators
- Access the web admin panel at `/admin`
- Use Google Sign-In with admin credentials
- Contact IT support for deployment assistance

---

**🎓 Built for GLA University - Connecting Students & Clubs**