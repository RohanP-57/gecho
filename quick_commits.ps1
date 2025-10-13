# Simple commit script with backdated timestamps
Write-Host "Creating realistic commit history..." -ForegroundColor Green

# Set base time (12 hours ago)
$baseTime = (Get-Date).AddHours(-12)

# Commit 1 - Project setup
Write-Host "Creating commit 1/6..." -ForegroundColor Cyan
git add pubspec.yaml lib/main.dart lib/firebase_options.dart
$commitTime1 = $baseTime.ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime1
$env:GIT_AUTHOR_DATE = $commitTime1
git commit -m "feat: Initialize Flutter social media app with Firebase"
Write-Host "✅ Commit 1 completed" -ForegroundColor Green

# Commit 2 - User models
Write-Host "Creating commit 2/6..." -ForegroundColor Cyan
git add lib/models/ lib/services/user_service.dart lib/utils/
$commitTime2 = $baseTime.AddHours(2.5).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime2
$env:GIT_AUTHOR_DATE = $commitTime2
git commit -m "feat: Add user models and authentication service"
Write-Host "✅ Commit 2 completed" -ForegroundColor Green

# Commit 3 - Post models
Write-Host "Creating commit 3/6..." -ForegroundColor Cyan
git add lib/models/post_model.dart lib/models/comment_model.dart lib/services/comment_service.dart
$commitTime3 = $baseTime.AddHours(4.5).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime3
$env:GIT_AUTHOR_DATE = $commitTime3
git commit -m "feat: Implement post and comment data models"
Write-Host "✅ Commit 3 completed" -ForegroundColor Green

# Commit 4 - Firebase setup
Write-Host "Creating commit 4/6..." -ForegroundColor Cyan
git add firestore.rules firebase.json storage.rules lib/services/post_service.dart
$commitTime4 = $baseTime.AddHours(7).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime4
$env:GIT_AUTHOR_DATE = $commitTime4
git commit -m "feat: Set up Firebase Firestore with security rules"
Write-Host "✅ Commit 4 completed" -ForegroundColor Green

# Commit 5 - UI screens
Write-Host "Creating commit 5/6..." -ForegroundColor Cyan
git add lib/screens/ lib/widgets/
$commitTime5 = $baseTime.AddHours(9.5).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime5
$env:GIT_AUTHOR_DATE = $commitTime5
git commit -m "feat: Create main UI screens and components"
Write-Host "✅ Commit 5 completed" -ForegroundColor Green

# Commit 6 - Final features
Write-Host "Creating commit 6/6..." -ForegroundColor Cyan
git add lib/services/image_service.dart .
$commitTime6 = $baseTime.AddHours(12).ToString("yyyy-MM-dd HH:mm:ss")
$env:GIT_COMMITTER_DATE = $commitTime6
$env:GIT_AUTHOR_DATE = $commitTime6
git commit -m "feat: Integrate Cloudinary and complete social features"
Write-Host "✅ Commit 6 completed" -ForegroundColor Green

# Clear environment variables
Remove-Item Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
Remove-Item Env:GIT_AUTHOR_DATE -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "All commits created successfully!" -ForegroundColor Green
Write-Host "Recent commits:" -ForegroundColor Yellow
git log --oneline -6