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
  }) {
    return _updateVerificationState(
      reference: reference,
      verifiedBy: verifiedBy,
      status: 'approved',
    );
  }

  Future<void> rejectReading({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    String? reason,
  }) {
    return _updateVerificationState(
      reference: reference,
      verifiedBy: verifiedBy,
      status: 'rejected',
      note: reason,
    );
  }

  Future<void> _updateVerificationState({
    required DocumentReference<Map<String, dynamic>> reference,
    required String verifiedBy,
    required String status,
    String? note,
  }) async {
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final userId = data['userId']?.toString();

    final updates = <String, dynamic>{
      'verificationStatus': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': FieldValue.serverTimestamp(),
    };
    if (note != null && note.isNotEmpty) {
      updates['verificationNote'] = note;
    }

    final batch = _firestore.batch();
    batch.update(reference, updates);

    if (userId != null && userId.isNotEmpty) {
      final userRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('water_quality_readings')
          .doc(reference.id);
      batch.update(userRef, updates);
    }

    await batch.commit();
  }
}
