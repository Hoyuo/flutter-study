# Flutter App Store Submission Guide

> **난이도**: 고급 | **카테고리**: infrastructure
> **선행 학습**: 없음
> **예상 학습 시간**: 2h

Production-ready patterns for submitting Flutter apps to Google Play Store and Apple App Store.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Google Play Store와 Apple App Store에 앱을 제출할 수 있다
> - 스토어 심사 기준을 이해하고 리젝 사유를 방지할 수 있다
> - Fastlane을 활용한 자동화된 스토어 배포를 설정할 수 있다

## Table of Contents

1. [Overview](#overview)
2. [Play Store Submission](#play-store-submission)
3. [App Store Submission](#app-store-submission)
4. [Screenshot Preparation](#screenshot-preparation)
5. [Store Descriptions](#store-descriptions)
6. [Review Response Handling](#review-response-handling)
7. [Release Strategy](#release-strategy)
8. [ASO (App Store Optimization)](#aso-app-store-optimization)
9. [Best Practices](#best-practices)

---

## Overview

### Pre-Submission Checklist

Before starting the submission process, ensure your app meets these requirements:

```
[ ] App functionality fully tested on real devices
[ ] All placeholder content replaced with production content
[ ] Analytics and crash reporting configured
[ ] Privacy policy and terms of service URLs ready
[ ] App icons and splash screens finalized
[ ] Performance optimized (startup time < 3 seconds)
[ ] Memory usage within acceptable limits
[ ] No debug code or test credentials in release build
```

### Required Assets Summary

| Asset | Play Store | App Store |
|-------|------------|-----------|
| App Icon | 512x512 PNG | 1024x1024 PNG (no alpha) |
| Feature Graphic | 1024x500 PNG | N/A |
| Screenshots | Min 2, Max 8 per device | Min 1, Max 10 per device |
| Video Preview | Optional (YouTube) | Optional (15-30 sec) |
| Privacy Policy | Required URL | Required URL |

---

## Play Store Submission

### 1. Developer Account Setup

```bash
# Create Google Play Developer account
# One-time fee: $25 USD
# URL: https://play.google.com/console/signup
```

### 2. App Signing Setup

```bash
# Generate upload key (keep this secure!)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Key properties file (android/key.properties)
# DO NOT commit this file to version control
```

```properties
# android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

```kotlin
// android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 3. Build App Bundle

```bash
# Clean and build release App Bundle
flutter clean
flutter pub get
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# Verify the bundle
bundletool build-apks --bundle=app-release.aab \
  --output=app.apks --mode=universal
```

### 4. Play Console Configuration

#### Store Listing Requirements

```yaml
App Details:
  Title: Max 30 characters
  Short Description: Max 80 characters
  Full Description: Max 4000 characters

Graphics:
  App Icon: 512x512 PNG (32-bit with alpha)
  Feature Graphic: 1024x500 PNG/JPG
  Screenshots:
    - Minimum: 2 screenshots
    - Maximum: 8 per device type
    - Size: 320px to 3840px (any side)
    - Aspect ratio: 16:9 or 9:16 recommended
  Video: YouTube URL (optional)

Categorization:
  App Category: Select primary category
  Content Rating: Complete questionnaire
  Target Audience: Select age groups
```

#### Content Rating Questionnaire

```yaml
# Answer these categories honestly
Violence:
  - No violence
  - Cartoon/fantasy violence
  - Realistic violence

Sexual Content:
  - No sexual content
  - Mild suggestive content
  - Sexual content

Language:
  - No profanity
  - Mild language
  - Strong language

Controlled Substances:
  - No references
  - References only
  - Use depicted

User Interaction:
  - No user interaction
  - Users can interact
  - Location sharing
```

#### Data Safety Section

```yaml
# Required since July 2022
Data Collection:
  Personal Info:
    - Name: [Collected/Not Collected]
    - Email: [Collected/Not Collected]
    - Phone: [Collected/Not Collected]

  Location:
    - Approximate: [Collected/Not Collected]
    - Precise: [Collected/Not Collected]

  Financial:
    - Payment info: [Collected/Not Collected]
    - Purchase history: [Collected/Not Collected]

Data Sharing:
  - List all third parties receiving data
  - Explain purpose for each

Security Practices:
  - Data encrypted in transit: [Yes/No]
  - Data deletion available: [Yes/No]
```

### 5. Play Store Complete Checklist

```
Pre-Launch:
[ ] App Bundle uploaded and processed
[ ] Store listing complete (all languages)
[ ] Content rating questionnaire completed
[ ] Data safety section filled
[ ] Pricing and distribution set
[ ] Target countries selected
[ ] Privacy policy URL added

Graphics:
[ ] App icon (512x512)
[ ] Feature graphic (1024x500)
[ ] Phone screenshots (minimum 2)
[ ] Tablet screenshots (if supporting)
[ ] Wear OS screenshots (if applicable)
[ ] TV screenshots (if applicable)

Testing:
[ ] Internal testing track used
[ ] Closed testing with beta users
[ ] Open testing (optional)
[ ] Pre-launch report reviewed
[ ] Crash-free rate acceptable (>99%)

Compliance:
[ ] Google Play policies reviewed
[ ] Ads declaration (if applicable)
[ ] Government apps declaration (if applicable)
[ ] COVID-19 apps declaration (if applicable)
```

---

## App Store Submission

### 1. Developer Account Setup

```bash
# Apple Developer Program
# Annual fee: $99 USD (Individual/Organization)
# URL: https://developer.apple.com/programs/enroll/

# For organizations:
# - D-U-N-S Number required
# - Legal entity verification
# - 2-4 weeks processing time
```

### 2. Certificates and Provisioning

```bash
# Using Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Select Runner target
# 3. Signing & Capabilities tab
# 4. Enable "Automatically manage signing"
# 5. Select your team

# Manual provisioning (if needed):
# 1. Create App ID in Apple Developer Portal
# 2. Create Distribution Certificate
# 3. Create App Store Provisioning Profile
# 4. Download and install in Xcode
```

### 3. Info.plist Configuration

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Display Name -->
    <key>CFBundleDisplayName</key>
    <string>Your App Name</string>

    <!-- Bundle Identifier -->
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

    <!-- Version (visible to users) -->
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>

    <!-- Build Number (internal) -->
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>

    <!-- Required Device Capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>

    <!-- Supported Interface Orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <!-- Privacy Descriptions (add only what you use) -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos for your diary entries.</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select images for your diary entries.</string>

    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>This app needs permission to save photos to your library.</string>

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to add location info to your diary entries.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access for location-based features.</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for voice recordings.</string>

    <key>NSContactsUsageDescription</key>
    <string>This app needs contacts access to share entries with friends.</string>

    <key>NSCalendarsUsageDescription</key>
    <string>This app needs calendar access to add diary reminders.</string>

    <key>NSFaceIDUsageDescription</key>
    <string>This app uses Face ID to securely unlock your diary.</string>

    <key>NSUserTrackingUsageDescription</key>
    <string>This identifier will be used to deliver personalized ads to you.</string>

    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- Background Modes (if needed) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
</dict>
</plist>
```

### 4. Build and Archive

```bash
# Update version and build number
# pubspec.yaml: version: 1.0.0+1 (name+build)

# Clean build
flutter clean
flutter pub get

# Build IPA for App Store
flutter build ipa --release

# With export options (recommended)
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist

# Output: build/ios/ipa/your_app.ipa
```

```xml
<!-- ios/ExportOptions.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### 5. Upload to App Store Connect

```bash
# Option 1: Using Xcode
# 1. Open build/ios/archive/Runner.xcarchive
# 2. Window > Organizer
# 3. Distribute App > App Store Connect > Upload

# Option 2: Using Transporter app (Recommended)
# 1. Download Transporter from Mac App Store
# 2. Sign in with Apple ID
# 3. Drag and drop .ipa file
# 4. Click Deliver

# Option 3: Using App Store Connect API (command line)
# Modern approach for CI/CD automation
# Note: xcrun altool was deprecated in Xcode 13.
# For iOS uploads, use Transporter app or App Store Connect API directly.
# Reference: https://developer.apple.com/documentation/appstoreconnectapi

# Using fastlane for automated uploads (recommended for CI/CD):
# fastlane deliver --ipa build/ios/ipa/your_app.ipa
```

### 6. App Store Connect Configuration

```yaml
App Information:
  Name: Max 30 characters
  Subtitle: Max 30 characters (iOS 11+)
  Primary Language: Select default
  Bundle ID: Must match Xcode
  SKU: Unique identifier (internal)

Version Information:
  Version: 1.0.0
  Copyright: © 2026 Your Company

Age Rating:
  - Complete questionnaire
  - Similar to Play Store content rating

App Privacy:
  Privacy Policy URL: Required
  Data Types:
    - Contact Info
    - Health & Fitness
    - Financial Info
    - Location
    - Sensitive Info
    - Contacts
    - User Content
    - Browsing History
    - Search History
    - Identifiers
    - Usage Data
    - Diagnostics

  For each type:
    - Used for Tracking: Yes/No
    - Linked to User: Yes/No
    - Purpose: Analytics, Personalization, etc.
```

### 7. App Store Complete Checklist

```
Pre-Submission:
[ ] Apple Developer account active
[ ] App ID created
[ ] Provisioning profiles valid
[ ] Build uploaded to App Store Connect
[ ] Build processing completed

App Store Listing:
[ ] App name and subtitle
[ ] Description (4000 chars max)
[ ] Keywords (100 chars total)
[ ] Support URL
[ ] Marketing URL (optional)
[ ] Privacy Policy URL
[ ] Category and secondary category

Screenshots:
[ ] 6.7" display (iPhone 15 Pro Max): 1290x2796
[ ] 6.5" display (iPhone 14 Plus): 1284x2778
[ ] 5.5" display (iPhone 8 Plus): 1242x2208
[ ] 12.9" iPad Pro (if supporting iPad): 2048x2732

Review Information:
[ ] Contact information
[ ] Demo account credentials (if login required)
[ ] Notes for reviewer
[ ] Attachment (if needed for testing)

Release Options:
[ ] Manual release
[ ] Automatic release after approval
[ ] Phased release (recommended)
```

---

## Screenshot Preparation

### Screenshot Dimensions

```yaml
# iOS Screenshot Sizes (Required)
iPhone:
  6.9": 1320 x 2868  # iPhone 16 Pro Max (2024+)
  6.7": 1290 x 2796  # iPhone 15 Pro Max, 14 Pro Max
  6.5": 1284 x 2778  # iPhone 14 Plus, 13 Pro Max
  5.5": 1242 x 2208  # iPhone 8 Plus (legacy)

iPad:
  12.9" Pro: 2048 x 2732
  11" Pro: 1668 x 2388
  10.5": 1668 x 2224 (optional)

# Note: App Store Connect may accept one size and auto-scale

# Android Screenshot Sizes
Phone:
  Minimum: 320px (any side)
  Maximum: 3840px (any side)
  Recommended: 1080 x 1920 (9:16) or 1920 x 1080 (16:9)

Tablet (7-inch):
  Recommended: 1080 x 1920 or 1920 x 1200

Tablet (10-inch):
  Recommended: 1920 x 1200 or 2560 x 1600
```

### Screenshot Automation with Flutter

```dart
// test/screenshot_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture screenshots for store listing', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Screenshot 1: Home screen
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_home_screen');
    // 참고: Flutter 3.17+에서는 convertFlutterSurfaceToImage() 호출이 불필요합니다.

    // Screenshot 2: Navigate to feature
    await tester.tap(find.byKey(const Key('feature_button')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_feature_screen');

    // Screenshot 3: Show dialog
    await tester.tap(find.byKey(const Key('action_button')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_action_dialog');

    // Continue for all screens...
  });
}
```

```bash
# Run screenshot tests
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=test/screenshot_test.dart \
  --device-id=YOUR_DEVICE_ID
```

### Screenshot Design Best Practices

```yaml
Design Guidelines:
  - First 2 screenshots are most important (visible without scrolling)
  - Show app in action, not just static screens
  - Use device frames for professional look
  - Add captions highlighting key features
  - Use consistent color scheme
  - Show real (or realistic) content
  - Avoid text-heavy screenshots

Caption Examples:
  Good:
    - "Track your daily moments"
    - "Organize with smart tags"
    - "Beautiful weather integration"

  Bad:
    - "Login screen"
    - "Settings page"
    - "Our amazing feature #1"

Tools for Screenshot Enhancement:
  - Figma (free tier available)
  - Sketch (macOS)
  - Adobe XD
  - AppLaunchpad.com (online)
  - LaunchKit (screenshots.pro)
  - Hotpot.ai (AI-powered)
```

### Device Frame Integration

```dart
// Using device_frame package for mockups
import 'package:device_frame/device_frame.dart';

Widget buildScreenshotMockup(Widget screenshot) {
  return DeviceFrame(
    device: Devices.ios.iPhone16ProMax,
    screen: screenshot,
  );
}

// For automated screenshot with frames
class ScreenshotWithFrame extends StatelessWidget {
  final Widget child;
  final DeviceInfo device;

  const ScreenshotWithFrame({
    super.key,
    required this.child,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your Feature Title',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          DeviceFrame(
            device: device,
            screen: child,
          ),
        ],
      ),
    );
  }
}
```

---

## Store Descriptions

### Effective Description Structure

```markdown
# Play Store / App Store Description Template

[First line - Most important, visible without expansion]
Transform your daily moments into beautiful memories with PhotoDiary.

[Key Features - Bullet points work well]
KEY FEATURES
- Capture and organize daily moments with photos
- Smart tagging for easy searching
- Weather integration shows conditions when memory was created
- Secure with biometric authentication
- Cloud backup keeps memories safe
- Works offline, syncs when connected

[Detailed Description]
PhotoDiary is your personal visual journal that makes capturing life's moments
effortless and enjoyable. Whether it's a beautiful sunset, a delicious meal,
or a precious moment with loved ones, PhotoDiary helps you preserve and
organize your memories.

[Social Proof - if available]
LOVED BY USERS
"The best diary app I've ever used!" - Featured in App Store
"Finally an app that makes journaling easy" - 50,000+ downloads

[Call to Action]
Download now and start your visual journey today!

[Support Information]
Questions? Contact us at support@yourapp.com
Follow us on Twitter: @yourapp
```

### Localization Strategy

```dart
// Store listing localization
// Create separate files for each language

// metadata/en-US/description.txt
// metadata/ko-KR/description.txt
// metadata/ja-JP/description.txt

// Using fastlane for metadata management
```

```
# Directory structure for fastlane metadata
android/fastlane/metadata/android/
├── en-US/
│   ├── title.txt
│   ├── short_description.txt
│   ├── full_description.txt
│   └── changelogs/
│       ├── 1.txt
│       └── 2.txt
├── ko-KR/
│   ├── title.txt
│   ├── short_description.txt
│   └── full_description.txt
└── ja-JP/
    └── ...

ios/fastlane/metadata/
├── en-US/
│   ├── name.txt
│   ├── subtitle.txt
│   ├── description.txt
│   ├── keywords.txt
│   ├── privacy_url.txt
│   ├── support_url.txt
│   └── release_notes.txt
├── ko/
│   └── ...
└── ja/
    └── ...
```

### Keywords Optimization

```yaml
# iOS Keywords (100 characters total)
keywords: "diary,journal,photo,memory,daily,planner,mood,tracker"

# Strategy:
# - Use comma-separated, no spaces
# - Include variations (photo, photos)
# - Include competitor names (if allowed)
# - Include category terms
# - Analyze competitor keywords

# Play Store Keywords
# No separate field - extracted from title and description
# - Include keywords naturally in first paragraph
# - Repeat important keywords 3-5 times
# - Use long-tail keywords in description
```

---

## Review Response Handling

### Common Rejection Reasons and Solutions

#### iOS Rejection Reasons

```yaml
# Guideline 2.1 - App Completeness
Reason: "App crashed during review"
Solution:
  - Test on oldest supported iOS version
  - Check for device-specific crashes
  - Provide detailed notes for reviewer
  - Include demo account if login required

# Guideline 2.3.3 - Accurate Screenshots
Reason: "Screenshots don't match app functionality"
Solution:
  - Update screenshots to match current UI
  - Remove features shown but not implemented
  - Ensure screenshots are from actual app

# Guideline 3.1.1 - In-App Purchase
Reason: "Digital content must use IAP"
Solution:
  - Remove external payment links
  - Implement StoreKit for digital purchases
  - Physical goods/services can use external payment

# Guideline 4.2.3 - Minimum Functionality
Reason: "App is too simple or web wrapper"
Solution:
  - Add native features (notifications, widgets)
  - Demonstrate unique value
  - Explain use case in review notes

# Guideline 5.1.1 - Data Collection
Reason: "Privacy description missing or inadequate"
Solution:
  - Add detailed NSUsageDescription strings
  - Explain why each permission is needed
  - Update App Privacy in App Store Connect
```

```dart
// Example: Detailed permission descriptions
// ios/Runner/Info.plist

// BAD - Too vague
<key>NSCameraUsageDescription</key>
<string>Camera access needed</string>

// GOOD - Specific and helpful
<key>NSCameraUsageDescription</key>
<string>PhotoDiary needs camera access to let you capture photos
directly into your diary entries. Photos are stored locally and
only uploaded to cloud with your permission.</string>
```

#### Android Rejection Reasons

```yaml
# Policy: Deceptive Behavior
Reason: "App permissions don't match functionality"
Solution:
  - Remove unused permissions from AndroidManifest
  - Justify each permission in Data Safety section
  - Request permissions only when needed

# Policy: User Data
Reason: "Data safety form incomplete"
Solution:
  - Complete all sections honestly
  - Include all third-party SDKs (Analytics, Ads)
  - Describe data retention and deletion

# Policy: Families
Reason: "App targets children but violates policies"
Solution:
  - Remove behavioral advertising
  - Implement parental gates
  - Comply with COPPA requirements

# Policy: Metadata
Reason: "Keywords stuffing in description"
Solution:
  - Remove excessive keyword repetition
  - Write natural, user-focused description
  - Remove competitor names
```

### Appeal Process

```yaml
# iOS Appeal Process
1. Review rejection email carefully
2. Check Resolution Center in App Store Connect
3. If legitimate issue: Fix and resubmit
4. If misunderstanding: Reply in Resolution Center
5. If disagreement: Appeal to App Review Board

Appeal Tips:
  - Be professional and polite
  - Cite specific guidelines
  - Provide evidence (screenshots, videos)
  - Explain use case clearly

# Android Appeal Process
1. Check Policy Status in Play Console
2. Review specific policy violation
3. Fix issue and submit for re-review
4. If disagreement: Submit appeal form
5. Wait 3-5 business days for response
```

### Demo Account Setup

```dart
// Create dedicated review account
class ReviewAccountConfig {
  // For App Store / Play Store review
  static const reviewEmail = 'review@yourapp.com';
  static const reviewPassword = 'ReviewPass123!';

  // Pre-populate with sample data
  static Future<void> setupReviewAccount() async {
    // Create account with sample diary entries
    // Include variety of features
    // Add sample photos
    // Show premium features if applicable
  }
}
```

```yaml
# App Store Connect: App Review Information
Sign-in required: Yes
User name: review@yourapp.com
Password: ReviewPass123!
Notes:
  "Demo account is pre-populated with sample entries.
   To test photo capture: Tap + button > Camera
   To test search: Go to Search tab > Type 'travel'
   Premium features are unlocked for this account."
```

---

## Release Strategy

### Staged Rollout

#### Play Store Staged Rollout

```yaml
# Recommended rollout schedule
Day 1:
  percentage: 1%
  monitor:
    - Crash rate
    - ANR rate
    - User feedback

Day 3:
  percentage: 5%
  criteria: Crash rate < 1%

Day 7:
  percentage: 20%
  criteria: No critical issues

Day 10:
  percentage: 50%
  criteria: Stable metrics

Day 14:
  percentage: 100%
  criteria: All metrics green
```

```bash
# Fastlane staged rollout
# android/fastlane/Fastfile
lane :staged_rollout do |options|
  rollout = options[:rollout] || 0.01

  upload_to_play_store(
    track: 'production',
    rollout: rollout.to_s,
    aab: '../build/app/outputs/bundle/release/app-release.aab'
  )
end

# Usage
fastlane staged_rollout rollout:0.01  # 1%
fastlane staged_rollout rollout:0.1   # 10%
fastlane staged_rollout rollout:1.0   # 100%
```

#### App Store Phased Release

```yaml
# Automatic 7-day phased release
Day 1: 1%
Day 2: 2%
Day 3: 5%
Day 4: 10%
Day 5: 20%
Day 6: 50%
Day 7: 100%

# Can be paused or released immediately at any time
# Available in App Store Connect > App Store > iOS App
```

### Version Management

```yaml
# pubspec.yaml
version: 1.2.3+45
#        │ │ │ │
#        │ │ │ └─ Build number (increments every build)
#        │ │ └─── Patch (bug fixes)
#        │ └───── Minor (new features, backward compatible)
#        └─────── Major (breaking changes)

# Semantic Versioning Rules
Major: Breaking changes, major redesign
Minor: New features, no breaking changes
Patch: Bug fixes, minor improvements
Build: Internal, increment for every submission
```

```bash
# Automate version bumping
# scripts/bump_version.sh

#!/bin/bash
CURRENT=$(grep "version:" pubspec.yaml | sed 's/version: //')
VERSION=$(echo $CURRENT | cut -d'+' -f1)
BUILD=$(echo $CURRENT | cut -d'+' -f2)

NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${VERSION}+${NEW_BUILD}"

sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "Version bumped to $NEW_VERSION"
```

### Release Notes Best Practices

```yaml
# Good release notes
"What's New in Version 2.1:
- Added dark mode support for comfortable nighttime journaling
- New weather widget shows conditions at time of entry
- Fixed issue where photos weren't saving on some devices
- Performance improvements for faster app startup"

# Bad release notes
"Bug fixes and improvements"
"v2.1.0"
"Various updates"
```

---

## ASO (App Store Optimization)

### Keyword Research

```yaml
# Keyword research process
1. Brainstorm seed keywords
2. Use tools:
   - App Annie (data.ai)
   - Sensor Tower
   - Mobile Action
   - AppTweak
3. Analyze competitors
4. Check search volume
5. Assess difficulty
6. Select final keywords

# Keyword placement priority
iOS:
  1. App Name (highest weight)
  2. Subtitle
  3. Keyword field
  4. Description (minimal weight)

Android:
  1. App Title (highest weight)
  2. Short Description
  3. Full Description
  4. Developer Name
```

### Conversion Optimization

```yaml
# Elements affecting conversion rate

Icon:
  - Use distinctive colors
  - Simple, recognizable design
  - Test variations with A/B testing
  - Don't use text (too small to read)

Screenshots:
  - First 2 visible without scrolling
  - Show key features immediately
  - Use captions for clarity
  - Show diverse use cases
  - Update seasonally

Video Preview:
  iOS:
    - 15-30 seconds
    - Show app in action
    - No hands/bezels allowed
    - App footage only

  Android:
    - YouTube video
    - Can include hands/context
    - Recommended: 30-60 seconds

Ratings & Reviews:
  - Respond to all reviews
  - Ask happy users to rate (timing matters)
  - Fix issues mentioned in negative reviews
```

### Rating Prompt Strategy

```dart
// Intelligent rating prompt
import 'dart:convert';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  RatingService(this._prefs);

  // Criteria for showing rating prompt
  static const int _minSessions = 5;
  static const int _minDaysInstalled = 7;
  static const int _minPositiveActions = 10;

  Future<void> checkAndPromptRating() async {
    if (await _shouldPrompt()) {
      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
        await _markPrompted();
      }
    }
  }

  Future<bool> _shouldPrompt() async {
    final data = _getRatingData();

    // Never shown before or enough time passed
    final lastPromptedStr = data['lastPrompted'] as String?;
    if (lastPromptedStr != null) {
      final lastPrompted = DateTime.parse(lastPromptedStr);
      final daysSincePrompt = DateTime.now().difference(lastPrompted).inDays;
      if (daysSincePrompt < 90) return false; // Max 3x per year
    }

    // Check criteria
    final sessionCount = data['sessionCount'] as int? ?? 0;
    final daysInstalled = data['daysInstalled'] as int? ?? 0;
    final positiveActions = data['positiveActions'] as int? ?? 0;

    return sessionCount >= _minSessions &&
           daysInstalled >= _minDaysInstalled &&
           positiveActions >= _minPositiveActions;
  }

  // Track positive actions (completed diary, shared, etc.)
  Future<void> trackPositiveAction() async {
    final data = _getRatingData();
    data['positiveActions'] = (data['positiveActions'] as int? ?? 0) + 1;
    await _saveRatingData(data);
  }

  // Helper methods
  Map<String, dynamic> _getRatingData() {
    final data = _prefs.getString('rating_data');
    return data != null ? jsonDecode(data) as Map<String, dynamic> : {};
  }

  Future<void> _saveRatingData(Map<String, dynamic> data) async {
    await _prefs.setString('rating_data', jsonEncode(data));
  }

  Future<void> _markPrompted() async {
    final data = _getRatingData();
    data['lastPrompted'] = DateTime.now().toIso8601String();
    data['promptCount'] = (data['promptCount'] ?? 0) + 1;
    await _saveRatingData(data);
  }
}
```

### A/B Testing

```yaml
# Play Store Experiments
Available Tests:
  - App icon
  - Feature graphic
  - Screenshots
  - Short description
  - Full description

Setup:
  1. Go to Store presence > Store listing experiments
  2. Create new experiment
  3. Add variant
  4. Set audience percentage (usually 50%)
  5. Run for minimum 7 days
  6. Apply winner

# App Store Product Page Optimization
Available Tests:
  - Icons
  - Screenshots
  - App previews

Setup:
  1. Go to App Store Connect > Product Page Optimization
  2. Create treatment
  3. Add variant assets
  4. Set traffic allocation
  5. Minimum 90-day runtime
  6. Analyze and apply
```

---

## Best Practices

### CI/CD Integration

```yaml
# .github/workflows/release.yml
name: Release to Stores

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Build App Bundle
        run: flutter build appbundle --release
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.yourcompany.yourapp
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Install certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}

      - name: Install provisioning profile
        uses: apple-actions/download-provisioning-profiles@v2
        with:
          bundle-id: com.yourcompany.yourapp
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

      - name: Build IPA
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload to App Store
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/your_app.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

### Fastlane Complete Setup

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    build_app(
      scheme: "Runner",
      export_options: {
        method: "app-store",
        provisioningProfiles: {
          "com.yourcompany.yourapp" => "Your App Store Profile"
        }
      }
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end

  desc "Push a new release to App Store"
  lane :release do
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    build_app(scheme: "Runner")
    upload_to_app_store(
      skip_screenshots: true,
      skip_metadata: false,
      submit_for_review: true,
      automatic_release: false,
      submission_information: {
        add_id_info_uses_idfa: false
      }
    )
  end
end

# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to internal testing track"
  lane :internal do
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Promote internal to production with staged rollout"
  lane :production do |options|
    rollout = options[:rollout] || 0.1
    upload_to_play_store(
      track: 'production',
      rollout: rollout.to_s,
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end

  desc "Complete rollout to 100%"
  lane :complete_rollout do
    upload_to_play_store(
      track: 'production',
      rollout: '1.0',
      skip_upload_aab: true
    )
  end
end
```

### Pre-Release Checklist

```yaml
# Complete pre-release checklist
Code Quality:
  [ ] All tests passing
  [ ] No compiler warnings
  [ ] Static analysis clean (flutter analyze)
  [ ] Code coverage acceptable
  [ ] Security review completed

Performance:
  [ ] App startup < 3 seconds
  [ ] Smooth scrolling (60fps)
  [ ] Memory usage reasonable
  [ ] Battery usage acceptable
  [ ] Network calls optimized

Content:
  [ ] All strings localized
  [ ] No placeholder content
  [ ] Images optimized
  [ ] Legal text reviewed

Compliance:
  [ ] Privacy policy current
  [ ] Terms of service current
  [ ] GDPR compliance (if applicable)
  [ ] CCPA compliance (if applicable)
  [ ] Age rating accurate

Technical:
  [ ] API endpoints pointing to production
  [ ] Analytics configured
  [ ] Crash reporting enabled
  [ ] Deep links working
  [ ] Push notifications tested

Store Assets:
  [ ] Screenshots current
  [ ] App icon final
  [ ] Feature graphic ready
  [ ] Video preview recorded (optional)
  [ ] Description proofread
  [ ] Release notes written
```

### Post-Launch Monitoring

```dart
// Monitor key metrics after launch
class LaunchMetrics {
  // Track critical metrics
  static const metrics = [
    'crash_free_rate',      // Target: > 99.5%
    'anr_rate',             // Target: < 0.5%
    'startup_time',         // Target: < 3s
    'daily_active_users',
    'retention_d1',         // Day 1 retention
    'retention_d7',         // Day 7 retention
    'rating',               // Store rating
    'review_sentiment',
  ];

  // Alert thresholds
  static const alerts = {
    'crash_free_rate': 99.0,  // Alert if below 99%
    'anr_rate': 1.0,          // Alert if above 1%
    'startup_time': 5000,     // Alert if above 5s
  };
}
```

```yaml
# Post-launch monitoring tools
Crash Monitoring:
  - Firebase Crashlytics
  - Sentry
  - Bugsnag

Performance:
  - Firebase Performance
  - New Relic Mobile
  - AppDynamics

Analytics:
  - Firebase Analytics
  - Amplitude
  - Mixpanel

Store Analytics:
  - Play Console (Android Vitals)
  - App Store Connect (App Analytics)

Review Monitoring:
  - AppBot
  - Appfollow
  - data.ai (App Annie)
```

---

## Summary

### Quick Reference

```bash
# Android Release
flutter clean && flutter pub get
flutter build appbundle --release
# Upload to Play Console or use fastlane

# iOS Release
flutter clean && flutter pub get
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
# Upload via Xcode, Transporter, or fastlane
```

### Key Success Factors

1. **Prepare thoroughly** - Complete checklists before submission
2. **Test on real devices** - Emulators miss device-specific issues
3. **Write detailed descriptions** - For permissions and review notes
4. **Provide demo accounts** - Required if login is needed
5. **Use staged rollout** - Catch issues before full release
6. **Monitor post-launch** - React quickly to issues
7. **Respond to reviews** - Shows active development
8. **Iterate on ASO** - Continuous optimization improves visibility

### Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Flutter Deployment Docs](https://docs.flutter.dev/deployment)
- [Fastlane Documentation](https://docs.fastlane.tools/)

---

## 실습 과제

### 과제 1: 스토어 제출 체크리스트 작성
Google Play Store와 Apple App Store 제출에 필요한 스크린샷, 설명, 개인정보처리방침 등을 준비하고 체크리스트를 완성하세요.

### 과제 2: Fastlane 자동 배포
Fastlane으로 Android는 Play Store 내부 테스트 트랙에, iOS는 TestFlight에 자동 업로드하는 lane을 작성하세요.

## Self-Check

- [ ] Android 키스토어 생성 및 서명 설정을 완료할 수 있는가?
- [ ] iOS 인증서와 프로비저닝 프로파일을 관리할 수 있는가?
- [ ] 스토어 심사 가이드라인 위반 항목을 사전에 점검할 수 있는가?
- [ ] 앱 버전 관리(Semantic Versioning)와 빌드 넘버 전략을 설명할 수 있는가?
