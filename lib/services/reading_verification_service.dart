import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingVerificationService {
  ReadingVerificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pendingReadings() {
    return _firestore
        .collection('water_quality_readings')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> approveReading({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? verifierUid,
    String? verifierName,
    String? verifierEmail,
  }) async {
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final userId = data['userId']?.toString();

    final batch = _firestore.batch();

    // Update the reading's verification status
    batch.update(reference, {
      'verificationStatus': 'approved',
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    // Create verification action record
    final actionRef = _firestore.collection('verification_actions').doc();
    batch.set(actionRef, {
      'submissionId': reference.id,
      'userId': userId,
      'verifierUid': verifierUid,
      'verifierName': verifierName,
      'verifierEmail': verifierEmail,
      'action': 'approved',
      'actionDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectReading({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? reason,
  }) async {
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final userId = data['userId']?.toString();

    final batch = _firestore.batch();

    // Update the reading's verification status
    batch.update(reference, {
      'verificationStatus': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // Create verification action record
    final actionRef = _firestore.collection('verification_actions').doc();
    batch.set(actionRef, {
      'submissionId': reference.id,
      'userId': userId,
      'verifierUid': verifiedBy,
      'action': 'rejected',
      'reason': reason,
      'actionDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
