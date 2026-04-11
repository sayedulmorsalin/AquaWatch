# AquaWatch - Water Quality Monitoring System

A community-driven mobile platform for real-time water quality monitoring with AI-powered analysis and government authority verification.

## 📱 Project Overview

AquaWatch democratizes water quality monitoring by enabling citizens to easily report water quality readings through their smartphones. The platform combines real-time geolocation-based mapping, AI-powered water parameter detection, and authority verification to create a comprehensive water quality monitoring system.

**Key Features:**

- User registration and authentication
- Real-time water quality submission with photo capture
- AI-powered water parameter analysis (pH, TDS, EC, Salinity, Temperature)
- Geolocation-based interactive map visualization
- Admin dashboard for verification and analytics
- Push notifications for status updates
- Offline data submission with automatic sync

---

## 📋 System Requirements

### Minimum Requirements

**For Development:**

- **OS**: Windows 10+, macOS 10.14+, or Linux (Ubuntu 18.04+)
- **RAM**: 8 GB minimum (16 GB recommended)
- **Storage**: 5 GB free space
- **Internet**: Stable connection (for Firebase setup)

**For Running on Device/Emulator:**

- **Android**: Android 7.0 (API 24) or higher
- **iOS**: iOS 11.0 or higher
- **Device Storage**: 300 MB minimum

### Required Software

1. **Flutter SDK** (v3.10.1 or higher)
2. **Dart SDK** (v3.10.1 or higher) - included with Flutter
3. **Git** (v2.0 or higher)
4. **Android Emulator/Physical Device** OR **iOS Simulator/Physical Device**
5. **Firebase Account** (free tier available)
6. **Visual Studio Code** or **Android Studio**

---

## 🚀 Installation Instructions

### Step 1: Install Flutter & Dart

#### **On Windows:**

1. **Download Flutter SDK**

   ```bash
   # Using Git (recommended)
   git clone https://github.com/flutter/flutter.git -b stable
   ```

   OR download from: https://flutter.dev/docs/get-started/install/windows

2. **Add Flutter to PATH**
   - Go to `Control Panel` → `System and Security` → `System` → `Advanced system settings`
   - Click `Environment Variables` → `New` (under System variables)
   - Variable name: `FLUTTER_HOME`
   - Variable value: `C:\path\to\flutter` (your Flutter installation directory)
   - Add `%FLUTTER_HOME%\bin` to the PATH variable

3. **Verify Installation**
   ```bash
   flutter --version
   dart --version
   ```

#### **On macOS:**

1. **Using Homebrew (easiest)**

   ```bash
   brew install flutter
   ```

2. **Or manually download**

   ```bash
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

3. **Verify Installation**
   ```bash
   flutter --version
   dart --version
   ```

#### **On Linux (Ubuntu):**

1. **Install Flutter**

   ```bash
   sudo apt-get update
   sudo apt-get install git curl
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:$HOME/flutter/bin"
   ```

2. **Add to ~/.bashrc or ~/.zshrc**

   ```bash
   export PATH="$PATH:$HOME/flutter/bin"
   ```

3. **Verify Installation**
   ```bash
   flutter --version
   dart --version
   ```

---

### Step 2: Install Required Development Tools

#### **Android Setup** (for Android device/emulator)

1. **Install Android Studio**
   - Download from: https://developer.android.com/studio
   - Follow the installation wizard

2. **Install Android SDK**

   ```bash
   flutter config --android-sdk /path/to/android-sdk
   ```

3. **Accept Android Licenses**
   ```bash
   flutter doctor --android-licenses
   # Type 'y' to accept all licenses
   ```

#### **iOS Setup** (for iOS device/simulator - macOS only)

1. **Install Xcode**

   ```bash
   sudo xcode-select --install
   ```

2. **Install CocoaPods**

   ```bash
   sudo gem install cocoapods
   ```

3. **Accept Xcode License**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

#### **Verify Setup**

```bash
flutter doctor
```

This command checks your setup. Ensure all required items show a checkmark ✓.

---

### Step 3: Clone the AquaWatch Repository

```bash
# Option 1: Using Git
git clone https://github.com/your-organization/aquawatch.git
cd aquawatch

# Option 2: Extract from ZIP (if downloaded as ZIP)
# Extract and navigate to the folder
cd aquawatch
```

---

### Step 4: Install Project Dependencies

```bash
# Get all Flutter packages
flutter pub get

# Ensure packages are updated to latest compatible versions
flutter pub upgrade

# If there are any conflicts
flutter pub resolve
```

---

### Step 5: Firebase Configuration

#### **Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create Project" or "Add Project"
3. Enter project name: `aquawatch`
4. Enable Google Analytics (optional)
5. Select regions and click "Create Project"

#### **Configure for Android**

1. In Firebase Console, click "Add app" → Select **Android**
2. Register app:
   - **Package name**: `com.aquawatch.app`
   - Download `google-services.json`
3. Place `google-services.json` in `android/app/` directory

#### **Configure for iOS**

1. In Firebase Console, click "Add app" → Select **iOS**
2. Register app:
   - **Bundle ID**: `com.aquawatch.app`
   - Download `GoogleService-Info.plist`
3. In Xcode:
   - Open `ios/Runner.xcworkspace`
   - Add `GoogleService-Info.plist` to Runner target

#### **Enable Required Firebase Services**

In Firebase Console, enable these services:

- ✅ Authentication (Email/Password + Google Sign-in)
- ✅ Cloud Firestore (Database)
- ✅ Storage (for image uploads)
- ✅ Cloud Messaging (for notifications)

---

### Step 6: Configure Environment Variables (Optional)

Create a `.env` file in the project root (if using `flutter_dotenv`):

```env
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_MAPS_API_KEY=your-google-maps-key
```

---

### Step 7: Run the Application

#### **On Android Emulator**

```bash
# Start Android Emulator first (from Android Studio)
# Then run:
flutter run

# Or specify device:
flutter run -d emulator-5554
```

#### **On Android Physical Device**

```bash
# Enable USB Debugging on your Android device
# Connect device via USB
flutter devices  # List connected devices

# Run on device:
flutter run -d <device-id>
```

#### **On iOS Simulator**

```bash
# Start iOS Simulator first
open -a Simulator

# Then run:
flutter run

# Or specify device:
flutter run -d "iPhone 15"
```

#### **On iOS Physical Device**

```bash
# Open iOS workspace
cd ios
open Runner.xcworkspace

# In Xcode:
# 1. Select your physical device from the device selector
# 2. Build and run (⌘R)

# Or from command line:
cd ..
flutter run -d ios
```

---

### Step 8: Build for Release

#### **Android Release Build**

```bash
# Generate release APK
flutter build apk

# APK location: build/app/outputs/apk/release/app-release.apk

# Generate Android App Bundle (for Google Play)
flutter build appbundle

# AAB location: build/app/outputs/bundle/release/app-release.aab
```

#### **iOS Release Build**

```bash
# Generate iOS release build
flutter build ios

# Archive for App Store:
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
cd ..
```

---

## 🔧 Project Structure

```
aquawatch/
├── android/                    # Android platform-specific code
├── ios/                        # iOS platform-specific code
├── lib/
│   ├── main.dart              # App entry point
│   ├── authentication/        # Auth screens & logic
│   ├── authority/             # Admin dashboard
│   ├── home/                  # Home/map screens
│   ├── profile/               # User profile
│   ├── services/              # Firebase & API services
│   ├── water_quality_detection/ # Image analysis & parameters
│   └── visualize_data/        # Data visualization
├── test/                       # Test files
├── pubspec.yaml               # Project dependencies
└── analysis_options.yaml      # Linting rules
```

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.13.0        # Firebase initialization
  firebase_auth: ^5.5.0         # Authentication
  cloud_firestore: ^5.6.4       # Database
  flutter_map: ^4.0.0           # Map visualization
  geolocator: ^10.1.0           # Location services
  geocoding: ^3.0.0             # Reverse geocoding
  image_picker: ^1.0.4          # Camera/gallery
  flutter_image_compress: ^2.3.0 # Image optimization
  http: ^0.13.6                 # HTTP requests
```

---

## 🧪 Testing

### Run Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Generate Coverage Report

```bash
# On Windows (using lcov)
# Install lcov first, then:
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🐛 Troubleshooting

### **Issue: "Flutter command not found"**

**Solution:**

```bash
# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"  # Linux/macOS
# OR restart terminal/IDE
```

### **Issue: "Android Gradle build failed"**

**Solution:**

```bash
# Clean build cache
flutter clean
flutter pub get
flutter run
```

### **Issue: "Firebase initialization error"**

**Solution:**

- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in correct location
- Verify Firebase project settings match app package name
- Check internet connection

### **Issue: "Image picker not working"**

**Solution:**

- **Android**: Add permissions in `android/app/src/main/AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  ```
- **iOS**: Add permissions in `ios/Runner/Info.plist`
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need access to your camera for water quality detection</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need access to your photos</string>
  ```

### **Issue: "Geolocation not working"**

**Solution:**

- Enable location services on device
- **Android**: Add permission in `AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
- **iOS**: Update location permissions in Info.plist

### **Issue: "Hot reload not working"**

**Solution:**

```bash
# Kill all Dart processes
# For Windows:
taskkill /F /IM dart.exe

# For macOS/Linux:
pkill -f dart

# Restart flutter run
flutter run
```

---

## 📚 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **Firebase Documentation**: https://firebase.google.com/docs
- **AquaWatch Presentation**: See `PRESENTATION.md` for project details

---

## 👥 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -m 'Add your feature'`
3. Push to branch: `git push origin feature/your-feature`
4. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📧 Support & Contact

For questions or issues, please contact:

- **Project Manager**: [Contact Info]
- **Technical Lead**: [Contact Info]
- **GitHub Issues**: [Project Repository]

---

**Last Updated**: April 11, 2026  
**Version**: 1.0.0
