import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingVerificationService {
  ReadingVerificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> pendingReadings() {
    final controller =
        StreamController<
          List<QueryDocumentSnapshot<Map<String, dynamic>>>
        >.broadcast();
    var rootDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var nestedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    void emitMerged() {
      final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      for (final doc in rootDocs) {
        if (doc.data()['verificationStatus']?.toString() == 'pending') {
          merged[doc.reference.path] = doc;
        }
      }

      for (final doc in nestedDocs) {
        if (doc.data()['verificationStatus']?.toString() == 'pending') {
          merged[doc.reference.path] = doc;
        }
      }

      if (!controller.isClosed) {
        controller.add(merged.values.toList());
      }
    }

    final rootSub = _firestore
        .collection('water_quality_readings')
        .snapshots()
        .listen((snapshot) {
          rootDocs = snapshot.docs;
          emitMerged();
        }, onError: controller.addError);

    final nestedSub = _firestore
        .collectionGroup('water_quality_readings')
        .snapshots()
        .listen((snapshot) {
          nestedDocs = snapshot.docs;
          emitMerged();
        }, onError: controller.addError);

    controller.onCancel = () async {
      await rootSub.cancel();
      await nestedSub.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Future<void> approveReading({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? verifierUid,
    String? verifierName,
    String? verifierEmail,
  }) {
    return _moveToVerifiedAndDeletePending(
      reference: reference,
      verifiedBy: verifiedBy,
      verifierUid: verifierUid,
      verifierName: verifierName,
      verifierEmail: verifierEmail,
    );
  }

  Future<void> rejectReading({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? reason,
  }) {
    return _deletePendingReading(reference: reference);
  }

  Future<void> _moveToVerifiedAndDeletePending({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? verifierUid,
    String? verifierName,
    String? verifierEmail,
  }) async {
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final userId = data['userId']?.toString();

    final verifiedPayload = <String, dynamic>{
      ...data,
      'verificationStatus': 'approved',
      'verifiedBy': verifiedBy,
      'verifiedByUid': verifierUid,
      'verifiedByName': verifierName,
      'verifiedByEmail': verifierEmail,
      'verifiedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
    };

    final verifiedRef = _firestore
        .collection('verified_water_quality_readings')
        .doc(reference.id);

    final batch = _firestore.batch();
    batch.set(verifiedRef, verifiedPayload);

    final refsToDelete = <String, DocumentReference<Map<String, dynamic>>>{
      reference.path: reference,
      _firestore.collection('water_quality_readings').doc(reference.id).path:
          _firestore.collection('water_quality_readings').doc(reference.id),
    };

    if (userId != null && userId.isNotEmpty) {
      final userRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('water_quality_readings')
          .doc(reference.id);
      refsToDelete[userRef.path] = userRef;
    }

    for (final ref in refsToDelete.values) {
      batch.delete(ref);
    }

    await batch.commit();
  }

  Future<void> _deletePendingReading({
    required DocumentReference<Map<String, dynamic>> reference,
  }) async {
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final userId = data['userId']?.toString();

    final refsToDelete = <String, DocumentReference<Map<String, dynamic>>>{
      reference.path: reference,
      _firestore.collection('water_quality_readings').doc(reference.id).path:
          _firestore.collection('water_quality_readings').doc(reference.id),
    };

    if (userId != null && userId.isNotEmpty) {
      final userRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('water_quality_readings')
          .doc(reference.id);
      refsToDelete[userRef.path] = userRef;
    }

    final batch = _firestore.batch();
    for (final ref in refsToDelete.values) {
      batch.delete(ref);
    }

    await batch.commit();
  }
}
