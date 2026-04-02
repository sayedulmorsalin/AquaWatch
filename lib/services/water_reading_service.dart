import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class WaterReadingService {
  WaterReadingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<File> _prepareCompressedImage(File sourceFile) async {
    try {
      final length = await sourceFile.length();
      if (length <= 250 * 1024) {
        return sourceFile;
      }

      final extension = sourceFile.path.toLowerCase().endsWith('.png')
          ? '.png'
          : '.jpg';
      final targetPath = sourceFile.path.replaceFirst(
        RegExp(r'(\.[^.]+)?$'),
        '_compressed$extension',
      );

      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        quality: 50,
        minWidth: 1280,
        minHeight: 1280,
        keepExif: false,
        format: extension == '.png' ? CompressFormat.png : CompressFormat.jpeg,
      );

      if (compressed == null) {
        return sourceFile;
      }

      return File(compressed.path);
    } on UnimplementedError {
      // Some platform/plugin builds don't implement compression.
      return sourceFile;
    } catch (_) {
      return sourceFile;
    }
  }

  Future<String> _uploadToFreeImageHost(String imagePath) async {
    final originalFile = File(imagePath);
    if (!await originalFile.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    final uploadFile = await _prepareCompressedImage(originalFile);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );

      request.fields['reqtype'] = 'fileupload';
      request.headers['User-Agent'] = 'AquaWatch/1.0';

      request.files.add(
        await http.MultipartFile.fromPath('fileToUpload', uploadFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Catbox upload failed (${response.statusCode}): ${responseBody.trim()}',
        );
      }

      final url = responseBody.trim();
      if (url.isEmpty) {
        throw Exception('Catbox returned an empty URL.');
      }

      return url;
    } finally {
      if (uploadFile.path != originalFile.path && await uploadFile.exists()) {
        await uploadFile.delete();
      }
    }
  }

  Future<void> saveReading({
    required double ph,
    required double tds,
    required double ec,
    required double salinity,
    required double temperature,
    required double latitude,
    required double longitude,
    required String phImagePath,
    required String tdsImagePath,
    required String ecImagePath,
    required String salinityImagePath,
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

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('water_quality_readings')
        .doc();
    final rootRef = _firestore
        .collection('water_quality_readings')
        .doc(docRef.id);

    final phImageUrl = await _uploadToFreeImageHost(phImagePath);
    final tdsImageUrl = await _uploadToFreeImageHost(tdsImagePath);
    final ecImageUrl = await _uploadToFreeImageHost(ecImagePath);
    final salinityImageUrl = await _uploadToFreeImageHost(salinityImagePath);

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
      'phImageUrls': [phImageUrl],
      'tdsImageUrls': [tdsImageUrl],
      'ecImageUrls': [ecImageUrl],
      'salinityImageUrls': [salinityImageUrl],
      'verificationStatus': 'pending',
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

    await rootRef.set(payload);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('water_quality_readings')
        .doc(docRef.id)
        .set(payload);
  }
}
