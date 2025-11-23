#!/bin/bash

# University Portal - Admin Panel Web Deployment Script
# This script builds and deploys the admin panel to Firebase Hosting

echo "🎓 University Portal - Admin Panel Deployment"
echo "=============================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo "🔧 Building web app for production..."
flutter build web --release --web-renderer html --base-href "/admin/"

echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Deployment complete!"
echo ""
echo "🌐 Your admin panel is now available at:"
echo "   https://your-project-id.web.app/admin"
echo ""
echo "📱 Mobile app users can access the regular portal at:"
echo "   https://your-project-id.web.app/"
echo ""
echo "🔐 Admin Access:"
echo "   - Use Google Sign-In with your admin account"
echo "   - Ensure your email is configured as admin in the system"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure your domain in Firebase Console"
echo "   2. Set up Google OAuth credentials for web"
echo "   3. Update Firestore security rules for admin access"
echo "   4. Test the admin panel functionality"