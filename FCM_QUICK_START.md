# Quick Start: FCM Notifications

## What was implemented?

When a user submits water quality data, all authorities within 50 km automatically receive a notification.

## Files Added/Modified

### New Files

- `lib/services/notification_service.dart` - FCM management
- `functions/src/index.ts` - Cloud Function with distance calculation
- `functions/package.json` - Node dependencies
- `functions/tsconfig.json` - TypeScript config

### Modified Files

- `pubspec.yaml` - Added firebase_messaging
- `lib/main.dart` - Background message handler
- `lib/home/home.dart` - Initialize notifications

## Quick Deploy

### Step 1: Install Dependencies

```bash
cd functions
npm install
cd ..
```

### Step 2: Deploy Cloud Function

```bash
firebase deploy --only functions
```

### Step 3: Rebuild App

```bash
flutter clean
flutter pub get
flutter run
```

## How It Works

1. User submits water quality reading
2. Data saved to `water_quality_readings` collection
3. Cloud Function triggers automatically
4. Function finds all authorities with location data
5. Calculates distance (Haversine formula)
6. Sends FCM notification to authorities within 50 km
7. Logs notification in `notification_logs` collection

## Testing

### Prerequisites

- Authority account with location set
- Regular user account
- Both logged in to devices
- Location services enabled

### Test Steps

1. Log in as regular user
2. Go to "Water Quality Detection"
3. Enter test data and submit
4. Check authority device for notification
5. Should see: "New Water Quality Reading - {Username} submitted a reading in your area"

## Troubleshooting

| Issue                   | Solution                                               |
| ----------------------- | ------------------------------------------------------ |
| Function not triggering | Check `water_quality_readings` collection has new data |
| No notifications        | Verify authority has location + fcmToken in Firestore  |
| Notifications delayed   | Check Cloud Functions logs: `firebase functions:log`   |
| App crashes             | Run `flutter clean && flutter pub get`                 |

## Configuration

**Notification Radius**: 50 km (modify in `functions/src/index.ts` line 46: `const RADIUS_KM = 50;`)

**Batch Size**: 500 devices (auto-batched by Firebase Messaging)

## Monitoring

View notifications sent:

1. Firebase Console → Cloud Functions → Logs
2. Check `notification_logs` collection for history
3. Monitor `firebase functions:log` in terminal

## Important Notes

- Location data must be set during account creation
- FCM token auto-saved when app opens
- Tokens refresh automatically (handled by Firebase)
- Distance calculated server-side (accurate & efficient)
- Notifications work in foreground and background

## Next Steps

1. Deploy functions
2. Test with multiple users
3. Monitor Cloud Functions logs
4. Adjust radius if needed
5. Configure Firestore security rules (see CLOUD_FUNCTIONS_SETUP.md)
