import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterReadingService {
  WaterReadingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveReading({
    required double ph,
    required double tds,
    required double ec,
    required double salinity,
    required double temperature,
    required double latitude,
    required double longitude,
    required List<String> phImagePaths,
    required List<String> tdsImagePaths,
    required List<String> ecImagePaths,
    required List<String> salinityImagePaths,
    String? overallQuality,
    int? overallScore,
    String? overallSummary,
    List<Map<String, dynamic>>? parameterResults,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in before submitting data.',
      );
    }

    final payload = <String, dynamic>{
      'ph': ph,
      'tds': tds,
      'ec': ec,
      'salinity': salinity,
      'temperature': temperature,
      'latitude': latitude,
      'longitude': longitude,
      'userId': user.uid,
      'userEmail': user.email,
      'userName': user.displayName,
      'phImagePaths': phImagePaths,
      'tdsImagePaths': tdsImagePaths,
      'ecImagePaths': ecImagePaths,
      'salinityImagePaths': salinityImagePaths,
      'submittedAt': FieldValue.serverTimestamp(),
    };

    if (overallQuality != null) {
      payload['overallQuality'] = overallQuality;
    }
    if (overallScore != null) {
      payload['overallScore'] = overallScore;
    }
    if (overallSummary != null) {
      payload['overallSummary'] = overallSummary;
    }
    if (parameterResults != null) {
      payload['parameterResults'] = parameterResults;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('water_quality_readings')
        .add(payload);
  }
}
