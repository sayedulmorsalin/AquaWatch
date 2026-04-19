import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  const AuthFailure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(message: readableAuthError(e), code: e.code);
    }
  }

  Future<UserCredential> registerWithProfile({
    required String name,
    required String phone,
    required String address,
    required String email,
    required String password,
    required String userRole,
    Map<String, dynamic>? location,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());

        final userData = {
          'name': name.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'email': email.trim(),
          'role': userRole,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add location data if provided
        if (location != null) {
          userData['location'] = location;
        }

        await _firestore.collection('users').doc(user.uid).set(userData);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(message: readableAuthError(e), code: e.code);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(message: readableAuthError(e), code: e.code);
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    data['email'] = data['email'] ?? user.email ?? '';
    data['name'] = data['name'] ?? user.displayName ?? '';
    return data;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  String readableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
