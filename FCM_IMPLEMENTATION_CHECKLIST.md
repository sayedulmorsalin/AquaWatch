# FCM Implementation Checklist

## App-Side Setup

### Dependencies

- [ ] `firebase_messaging: ^14.8.0` added to pubspec.yaml
- [ ] `flutter pub get` run successfully

### Code Changes

- [ ] `notification_service.dart` created
- [ ] `lib/main.dart` updated with background handler
- [ ] `lib/home/home.dart` updated to initialize notifications
- [ ] App compiles without errors

### Permissions

#### Android

- [ ] `android/app/src/main/AndroidManifest.xml` has:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```
- [ ] `google-services.json` is in `android/app/`
- [ ] Build gradle files have Google Services plugin

#### iOS

- [ ] `ios/Runner/Info.plist` has location descriptions
- [ ] Push Notifications capability enabled in Xcode
- [ ] APNs certificate configured in Firebase

### Testing

- [ ] App runs on Android device/emulator
- [ ] App runs on iOS device/simulator
- [ ] No permission errors on launch
- [ ] FCM token successfully retrieved (check logs)

## Cloud Side Setup

### Cloud Functions

#### Project Structure

- [ ] `functions/package.json` created
- [ ] `functions/tsconfig.json` created
- [ ] `functions/src/index.ts` created with:
  - [ ] `notifyNearbyAuthorities` function
  - [ ] `testNotification` function (optional)
  - [ ] `updateFCMToken` function (optional)
- [ ] `functions/.gitignore` created

#### Dependencies

- [ ] Ran `cd functions && npm install`
- [ ] `node_modules` folder created
- [ ] Firebase Admin SDK installed

#### Deployment

- [ ] `firebase deploy --only functions` successful
- [ ] Function appears in Firebase Console
- [ ] Trigger set to `water_quality_readings` → `onCreate`

### Firestore Configuration

#### Collections

- [ ] `users` collection has documents with:
  - [ ] `location` object (latitude, longitude, address, city, country)
  - [ ] `fcmToken` string
  - [ ] `role` string ("User" or "Authority")

- [ ] `water_quality_readings` collection has:
  - [ ] `latitude` number
  - [ ] `longitude` number
  - [ ] `userId` string
  - [ ] Other reading data

#### Security Rules

- [ ] Updated Firestore rules to allow Cloud Functions access
- [ ] Rules allow users to read own data
- [ ] Rules allow reading public locations for distance calculation

### Notification Logs

- [ ] `notification_logs` collection created (auto by function)
- [ ] Logs contain:
  - [ ] readingId
  - [ ] submittedBy
  - [ ] authoritiesNotified count
  - [ ] successfulNotifications count
  - [ ] failedNotifications count

## Integration Testing

### Data Submission

- [ ] Regular user can submit water quality data
- [ ] Data saved to `water_quality_readings` with location
- [ ] Cloud Function triggers (check logs)

### Notification Sending

- [ ] Cloud Function finds nearby authorities
- [ ] Distance calculation works correctly
- [ ] Authorities within 50 km identified
- [ ] FCM tokens retrieved successfully
- [ ] Notifications queued for delivery

### Notification Receipt

- [ ] Authority receives notification on device
- [ ] Notification shows correct title and body
- [ ] Notification contains correct data (readingId, location)
- [ ] Notification works in foreground
- [ ] Notification works in background
- [ ] Tapping notification opens app

### Logging & Monitoring

- [ ] Cloud Functions logs show execution details
- [ ] No errors in function execution
- [ ] `notification_logs` collection has entries
- [ ] Successful/failed counts are accurate

## Specific Scenarios

### Scenario 1: Single Authority Within Range

- [ ] Create 1 authority with location within 50 km
- [ ] Submit water quality reading
- [ ] Authority receives 1 notification
- [ ] Log shows 1 authority notified, 1 successful

### Scenario 2: Multiple Authorities Within Range

- [ ] Create 3 authorities with locations (within 50 km)
- [ ] Create 1 authority outside 50 km
- [ ] Submit water quality reading
- [ ] Only 3 authorities receive notification
- [ ] Log shows 3 notified, 4 in system

### Scenario 3: No Authorities in Range

- [ ] No authorities created or all outside 50 km
- [ ] Submit water quality reading
- [ ] No notifications sent
- [ ] Log shows 0 authorities notified

### Scenario 4: Authority Without Location

- [ ] Create authority without location data
- [ ] Create authority with location
- [ ] Submit water quality reading
- [ ] Only authority with location receives notification

### Scenario 5: Authority Without FCM Token

- [ ] Create authority with location but no fcmToken
- [ ] Create authority with location and token
- [ ] Submit water quality reading
- [ ] Only authority with token receives notification

## Performance Checks

- [ ] Cloud Function executes within 60 seconds
- [ ] No timeout errors in logs
- [ ] Haversine distance calculation is accurate
- [ ] Batch processing works (>500 authorities)
- [ ] Memory usage is acceptable

## Security Verification

- [ ] FCM tokens not exposed to other users
- [ ] Only authenticated users can submit readings
- [ ] Cloud Functions only accessible internally
- [ ] Firestore rules prevent unauthorized access
- [ ] User data properly isolated

## Documentation

- [ ] `CLOUD_FUNCTIONS_SETUP.md` reviewed
- [ ] `FCM_SETUP_GUIDE.md` reviewed
- [ ] `FCM_QUICK_START.md` reviewed
- [ ] All code commented and documented
- [ ] README updated with notification info

## Troubleshooting Checks

### If Notifications Not Arriving

1. [ ] Check authority has valid location in Firestore
2. [ ] Check authority has valid fcmToken
3. [ ] Check Cloud Functions logs for errors
4. [ ] Check distance calculation (50 km range)
5. [ ] Verify notification permissions granted
6. [ ] Check device FCM registration

### If Cloud Function Not Triggering

1. [ ] Verify function deployed successfully
2. [ ] Check `water_quality_readings` collection
3. [ ] Verify trigger is on `onCreate` event
4. [ ] Check function exists in Firebase Console
5. [ ] Review function logs

### If Build Issues

1. [ ] Run `flutter clean`
2. [ ] Run `flutter pub get`
3. [ ] Check Android/iOS specific configurations
4. [ ] Verify all dependencies installed
5. [ ] Check for TypeScript compilation errors

## Final Sign-Off

- [ ] All checklist items completed
- [ ] App tested on real devices
- [ ] Cloud Functions tested in production
- [ ] Documentation complete
- [ ] Team trained on system
- [ ] Ready for production deployment
