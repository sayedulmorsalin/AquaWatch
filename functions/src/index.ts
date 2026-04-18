import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Haversine formula to calculate distance between two coordinates (in km)
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Cloud Function triggered on new water quality reading submission
export const notifyNearbyAuthorities = functions.firestore
  .document('water_quality_readings/{readingId}')
  .onCreate(async (snap, context) => {
    const readingData = snap.data();
    const submissionLat = readingData.latitude;
    const submissionLon = readingData.longitude;
    const userId = readingData.userId;
    const RADIUS_KM = 50;

    console.log(
      `New water quality reading submitted at ${submissionLat}, ${submissionLon}`
    );

    try {
      // Get the submitting user's name
      const userDoc = await db.collection('users').doc(userId).get();
      const userName = userDoc.data()?.name || 'A user';

      // Get all authorities
      const authoritiesSnapshot = await db
        .collection('users')
        .where('role', '==', 'Authority')
        .get();

      if (authoritiesSnapshot.empty) {
        console.log('No authorities found in the system');
        return;
      }

      const nearbyAuthorities: string[] = [];

      // Check each authority's location
      for (const authorityDoc of authoritiesSnapshot.docs) {
        const authorityData = authorityDoc.data();
        const authorityLat = authorityData.location?.latitude;
        const authorityLon = authorityData.location?.longitude;
        const fcmToken = authorityData.fcmToken;

        // If authority doesn't have location or FCM token, skip
        if (!authorityLat || !authorityLon || !fcmToken) {
          console.log(
            `Authority ${authorityDoc.id} missing location or FCM token`
          );
          continue;
        }

        // Calculate distance
        const distance = calculateDistance(
          submissionLat,
          submissionLon,
          authorityLat,
          authorityLon
        );

        console.log(
          `Distance to authority ${authorityDoc.id}: ${distance.toFixed(2)} km`
        );

        // If within 50km radius, add to notification list
        if (distance <= RADIUS_KM) {
          nearbyAuthorities.push(fcmToken);
          console.log(
            `Authority ${authorityDoc.id} is within ${RADIUS_KM}km radius`
          );
        }
      }

      if (nearbyAuthorities.length === 0) {
        console.log(`No authorities within ${RADIUS_KM}km radius`);
        return;
      }

      // Send notifications to nearby authorities
      const message = {
        notification: {
          title: 'New Water Quality Reading',
          body: `${userName} submitted a reading in your area`,
        },
        data: {
          readingId: context.params.readingId,
          latitude: submissionLat.toString(),
          longitude: submissionLon.toString(),
          userName: userName,
          timestamp: new Date().toISOString(),
        },
      };

      // Send to multiple devices (max 500 per batch)
      const batches = [];
      for (let i = 0; i < nearbyAuthorities.length; i += 500) {
        const batch = nearbyAuthorities.slice(i, i + 500);
        batches.push(
          messaging.sendMulticast({
            tokens: batch,
            notification: message.notification,
            data: message.data,
          })
        );
      }

      const results = await Promise.all(batches);

      let successCount = 0;
      let failureCount = 0;

      for (const result of results) {
        successCount += result.successCount;
        failureCount += result.failureCount;
      }

      console.log(
        `Notifications sent: ${successCount} successful, ${failureCount} failed`
      );

      // Save notification log
      await db.collection('notification_logs').add({
        readingId: context.params.readingId,
        submittedBy: userId,
        submitterName: userName,
        submissionLocation: {
          latitude: submissionLat,
          longitude: submissionLon,
        },
        radiusKm: RADIUS_KM,
        authoritiesNotified: nearbyAuthorities.length,
        successfulNotifications: successCount,
        failedNotifications: failureCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `Notification log saved for reading ${context.params.readingId}`
      );
    } catch (error) {
      console.error('Error in notifyNearbyAuthorities:', error);
      throw error;
    }
  });

// Optional: Cloud Function to test sending notifications
export const testNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { fcmToken, testMessage } = data;

  try {
    const messageData = {
      notification: {
        title: 'Test Notification',
        body: testMessage || 'This is a test notification from AquaWatch',
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
      },
    };

    await messaging.send({
      token: fcmToken,
      notification: messageData.notification,
      data: messageData.data,
    });

    return { success: true, message: 'Test notification sent successfully' };
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send test notification'
    );
  }
});

// Optional: Cloud Function to refresh FCM token
export const updateFCMToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { token } = data;
  const uid = context.auth.uid;

  try {
    await db.collection('users').doc(uid).update({
      fcmToken: token,
      fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'FCM token updated successfully' };
  } catch (error) {
    console.error('Error updating FCM token:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update FCM token'
    );
  }
});
