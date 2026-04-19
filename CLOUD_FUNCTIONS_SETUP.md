# FCM Notification System & Cloud Functions Deployment Guide

This guide explains how to set up and deploy the Firebase Cloud Functions for the AquaWatch notification system.

## Overview

When a user submits water quality data, the Cloud Function:

1. Retrieves all authorities in the system
2. Calculates the distance between the submission location and each authority's location
3. Sends FCM notifications to all authorities within a 50 km radius

## Prerequisites

- Node.js 18+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project created
- Admin access to your Firebase project

## Setup Steps

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Initialize Firebase Project (if not already done)

Navigate to your project root:

```bash
firebase init functions
```

This should detect your existing Firebase configuration.

### 4. Install Dependencies

Navigate to the functions directory and install dependencies:

```bash
cd functions
npm install
```

### 5. Deploy Cloud Functions

From the project root directory, run:

```bash
firebase deploy --only functions
```

Or deploy a specific function:

```bash
firebase deploy --only functions:notifyNearbyAuthorities
```

### 6. Verify Deployment

Check the Firebase Console → Cloud Functions to confirm deployment.

## Cloud Functions Explained

### `notifyNearbyAuthorities`

**Trigger:** Firestore collection `water_quality_readings` → onCreate event

**What it does:**

- Listens for new water quality reading submissions
- Gets the submission location (latitude/longitude)
- Fetches all authorities with valid locations and FCM tokens
- Calculates distance using Haversine formula
- Sends notifications to authorities within 50 km radius
- Logs notification attempts to `notification_logs` collection

**Data saved in notification_logs:**

```
{
  readingId: string,
  submittedBy: string,
  submitterName: string,
  submissionLocation: { latitude, longitude },
  radiusKm: 50,
  authoritiesNotified: number,
  successfulNotifications: number,
  failedNotifications: number,
  createdAt: timestamp
}
```

### `testNotification` (Optional)

**Type:** Callable HTTPS function

**Purpose:** Test notification delivery

**Parameters:**

```
{
  fcmToken: string,
  testMessage: string (optional)
}
```

### `updateFCMToken` (Optional)

**Type:** Callable HTTPS function

**Purpose:** Update user's FCM token (called from app)

**Parameters:**

```
{
  token: string
}
```

## Important Notes

### Location Data Requirements

For authorities to receive notifications, they must have:

1. **Location data** in their user document:

   ```
   location: {
     latitude: number,
     longitude: number,
     address: string,
     city: string,
     country: string
   }
   ```

2. **FCM Token** in their user document:
   ```
   fcmToken: string,
   fcmTokenUpdatedAt: timestamp
   ```

Both are automatically saved when an authority:

- Creates their account (location selection)
- Opens the app (FCM token initialization)

### Distance Calculation

Uses the **Haversine formula** to calculate great-circle distances between coordinates.

Default radius: **50 km** (can be modified in the Cloud Function)

### Notification Limits

- Firebase allows up to 500 recipients per `sendMulticast` call
- Function automatically batches notifications if more than 500 authorities are nearby

## Testing

### 1. Test in Firebase Emulator

```bash
firebase emulators:start --only functions
```

### 2. Monitor Logs

```bash
firebase functions:log
```

### 3. Manual Test

Create a test data submission:

```bash
curl -X POST \
  https://your-firebase-region-projectid.cloudfunctions.net/testNotification \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "user-fcm-token",
    "testMessage": "Test notification"
  }'
```

## Troubleshooting

### Function not triggering?

1. Check Firestore trigger is configured: `water_quality_readings` → `onCreate`
2. Verify user document has both `location` and `fcmToken`
3. Check Cloud Functions logs: `firebase functions:log`

### No notifications sent?

1. Verify authorities have valid `location` data
2. Check if `fcmToken` is present and valid
3. Check if authorities are within 50 km radius
4. Review notification logs collection

### Notifications not reaching device?

1. Verify app has Firebase Messaging permissions
2. Check `initializeNotifications()` is called in app
3. Verify app's `google-services.json` or `GoogleService-Info.plist` is correct
4. Check notification handling in `notification_service.dart`

## Firestore Security Rules

Add these rules to allow Cloud Functions to access user documents:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Allow Cloud Functions to read all users (internal access)
    match /users/{document=**} {
      allow read, write: if request.auth != null &&
        (request.auth.uid == document ||
         resource.data.get('role') != null);
    }

    // Water quality readings
    match /water_quality_readings/{document=**} {
      allow read, write: if request.auth != null;
    }

    // Notification logs (read-only for debugging)
    match /notification_logs/{document=**} {
      allow read: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Authority';
      allow write: if false; // Only Cloud Functions write
    }
  }
}
```

## Next Steps

1. Deploy the Cloud Functions
2. Update your app's AndroidManifest.xml and Info.plist (if not already done)
3. Test by submitting water quality data as a regular user
4. Check if authorities receive notifications
5. Review notification logs in Firebase Console

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Haversine Formula](https://en.wikipedia.org/wiki/Haversine_formula)
