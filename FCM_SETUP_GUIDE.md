# Firebase Cloud Messaging (FCM) Setup Guide for AquaWatch

This guide covers setting up Firebase Cloud Messaging for push notifications in the AquaWatch app.

## What's New

The app now includes automatic push notifications:

- When a user submits water quality data, all authorities within 50 km receive a notification
- Notifications are handled both in foreground and background
- FCM tokens are automatically managed and stored in Firebase

## Android Setup

### 1. Verify `android/app/google-services.json`

Ensure you have the latest `google-services.json` from Firebase Console.

### 2. Check `build.gradle` files

Your `android/build.gradle.kts` should have:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:...")
        classpath("com.google.gms:google-services:4.3.15")
    }
}
```

And `android/app/build.gradle.kts` should have:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
}
```

### 3. Update `android/app/src/main/AndroidManifest.xml`

Ensure these permissions are present:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 4. Build and Test

```bash
flutter clean
flutter pub get
flutter run
```

## iOS Setup

### 1. Update `ios/Runner/Info.plist`

Add notification descriptions (already configured):

```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>
```

### 2. Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" → Select "Push Notifications"

### 3. Configure APNs Certificate

1. Go to [Apple Developer Console](https://developer.apple.com/account)
2. Create an APNs certificate
3. Add it to your Firebase Project:
   - Firebase Console → Project Settings → Cloud Messaging tab
   - Upload your APNs certificate

### 4. Build and Test

```bash
flutter clean
flutter pub get
flutter run -t lib/main.dart
```

## Verify Setup

### 1. Check Notifications Initialization

Notifications are automatically initialized when the app loads. Check logs for:

```
✓ Notifications initialized
✓ FCM Token saved
```

### 2. Test Notification Receipt

After logging in, submit water quality data as a regular user:

1. Go to "Water Quality Detection" → "Data Entry"
2. Fill in all required data and submit

Authorities within 50 km should receive:

```
Title: "New Water Quality Reading"
Body: "{User Name} submitted a reading in your area"
```

### 3. Check Firebase Console

1. Firebase Console → Cloud Messaging
2. You can send test notifications from here
3. Check Cloud Functions logs for issues

## App Integration

### Automatic Features

The app automatically handles:

- ✅ Requesting notification permissions
- ✅ Getting and storing FCM tokens
- ✅ Listening to foreground messages
- ✅ Handling background messages
- ✅ Refreshing tokens when needed

### Configuration Location

**Files modified:**

1. **pubspec.yaml**
   - Added: `firebase_messaging: ^14.8.0`

2. **lib/main.dart**
   - Added: Firebase Messaging background handler
   - Added: Message handler initialization

3. **lib/services/notification_service.dart** (NEW)
   - Handles all FCM operations
   - Manages token storage
   - Listens to incoming messages

4. **lib/home/home.dart**
   - Calls `initializeNotifications()` on app launch

## Notification Handling

### Foreground Messages

When user receives a notification while app is open:

- Notification is logged to console
- Can be handled with custom logic

### Background Messages

Background messages are handled automatically:

- User sees native notification
- Tapping notification opens app

### Handling Notification Taps

To handle what happens when user taps a notification, modify `_handleNotificationTap()` in `notification_service.dart`:

```dart
void _handleNotificationTap(RemoteMessage message) {
  print('Message clicked!');
  // Navigate to specific screen based on message data
  if (message.data['type'] == 'water_reading') {
    // Navigate to reading details
  }
}
```

## Permissions

### Android

- `POST_NOTIFICATIONS` - Required for Android 13+

### iOS

- Notification permissions are requested automatically
- User can enable/disable in Settings

## Troubleshooting

### Notifications Not Arriving

**Checklist:**

1. ✓ `firebase_messaging` dependency added to pubspec.yaml
2. ✓ `initializeNotifications()` called in HomePage
3. ✓ Permissions granted (check app Settings)
4. ✓ Location services enabled
5. ✓ User has valid FCM token (check Firebase Console)
6. ✓ Authority is within 50 km radius

### Check Logs

View FCM logs:

```bash
firebase functions:log
```

Check detailed logs:

```bash
flutter run -v
```

### Manual Token Check

In `notification_service.dart`, add logging:

```dart
final token = await _messaging.getToken();
print('FCM Token: $token');
```

### Test Notification

Use Firebase Console:

1. Cloud Messaging → Send your first message
2. Select Android/iOS app
3. Create test notification
4. Add test device token
5. Send and verify

## Security Considerations

### FCM Tokens

- Tokens are device-specific
- Stored in Firestore in user documents
- Not exposed to other users
- Automatically refreshed when needed

### Message Data

Notification data includes:

- Reading ID
- Location (latitude/longitude)
- User name
- Timestamp

All data is verified server-side by Cloud Functions.

## Performance

### FCM Token Storage

- Tokens stored securely in Firebase
- Updated automatically when needed
- Tokens expire if not refreshed (Android: ~30 days)

### Notification Batching

- Functions batch notifications (max 500 per request)
- Handles large numbers of authorities efficiently

### Distance Calculation

- Uses Haversine formula for accuracy
- Calculated server-side (not on device)
- Prevents calculation errors

## Next Steps

1. Deploy Cloud Functions (see `CLOUD_FUNCTIONS_SETUP.md`)
2. Test with multiple users
3. Monitor notification logs
4. Adjust radius in Cloud Function if needed

## Support

For issues:

1. Check logs: `firebase functions:log`
2. Verify Firestore data: `notification_logs` collection
3. Review Cloud Function code: `functions/src/index.ts`
4. Check app logs: `flutter run -v`
