import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_role.dart';

class FarmoraAuthException implements Exception {
  final String message;
  const FarmoraAuthException(this.message);
  @override
  String toString() => message;
}

class FarmoraAuthResult {
  final Role role;
  const FarmoraAuthResult(this.role);
}

class FirebaseAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[^0-9+]'), '');

  String _emailForPhone(String phone) {
    final normalized = _normalizePhone(phone).replaceFirst('+', '00');
    return '$normalized@phone.farmora.app';
  }

  Role _parseRole(Object? value) => Role.values.firstWhere(
        (role) => role.name == value,
        orElse: () =>
            throw const FarmoraAuthException('Your account role is invalid.'),
      );

  Future<void> _createMobileProfile({
    required User user,
    required String phone,
    required String name,
    required Role role,
    required String provider,
    String? district,
  }) async {
    final profile = _firestore.collection('users').doc(phone);
    final authIndex = _firestore.collection('authUsers').doc(user.uid);
    final batch = _firestore.batch();
    batch.set(profile, {
      'name': name,
      'phone': phone,
      'authUid': user.uid,
      'email': user.email,
      'photoUrl': user.photoURL,
      'role': role.name,
      'district': district,
      'authProvider': provider,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(authIndex, {
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<FarmoraAuthResult> register({
    required String name,
    required String phone,
    required String password,
    required Role role,
    String? district,
  }) async {
    UserCredential? credential;
    try {
      final normalizedPhone = _normalizePhone(phone);
      credential = await _auth.createUserWithEmailAndPassword(
        email: _emailForPhone(normalizedPhone),
        password: password,
      );
      await _createMobileProfile(
        user: credential.user!,
        phone: normalizedPhone,
        name: name.trim(),
        role: role,
        provider: 'password',
        district: district,
      );
      return FarmoraAuthResult(role);
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    } on FirebaseException catch (error) {
      if (credential?.user != null) await credential!.user!.delete();
      throw FarmoraAuthException(error.code == 'permission-denied'
          ? 'This mobile number is already registered.'
          : (error.message ?? 'Could not save your profile.'));
    }
  }

  Future<FarmoraAuthResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailForPhone(normalizedPhone),
        password: password,
      );
      var snapshot =
          await _firestore.collection('users').doc(normalizedPhone).get();
      if (!snapshot.exists) {
        snapshot = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
      }
      final data = snapshot.data();
      if (data == null) {
        await _auth.signOut();
        throw const FarmoraAuthException('User profile was not found.');
      }
      return FarmoraAuthResult(_parseRole(data['role']));
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
  }

  Future<UserCredential> _signInWithGoogleProvider() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    return kIsWeb
        ? _auth.signInWithPopup(provider)
        : _auth.signInWithProvider(provider);
  }

  Future<FarmoraAuthResult> loginWithGoogle() async {
    try {
      final credential = await _signInWithGoogleProvider();
      final user = credential.user!;
      final index =
          await _firestore.collection('authUsers').doc(user.uid).get();
      DocumentSnapshot<Map<String, dynamic>> profile;
      if (index.exists) {
        profile = await _firestore
            .collection('users')
            .doc(index.data()!['phone'] as String)
            .get();
      } else {
        profile = await _firestore.collection('users').doc(user.uid).get();
      }
      final data = profile.data();
      if (data == null) {
        await _auth.signOut();
        throw const FarmoraAuthException(
          'No Farmora profile found. Register with Google first.',
        );
      }
      return FarmoraAuthResult(_parseRole(data['role']));
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
  }

  Future<FarmoraAuthResult> registerWithGoogle({
    required String name,
    required String phone,
    required Role role,
    String? district,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      if (!RegExp(r'^\+?\d{9,15}$').hasMatch(normalizedPhone)) {
        throw const FarmoraAuthException('Enter a valid mobile number first.');
      }
      final credential = await _signInWithGoogleProvider();
      final user = credential.user!;
      final authIndex = _firestore.collection('authUsers').doc(user.uid);
      final existingIndex = await authIndex.get();
      if (existingIndex.exists) {
        final existingProfile = await _firestore
            .collection('users')
            .doc(existingIndex.data()!['phone'] as String)
            .get();
        return FarmoraAuthResult(_parseRole(existingProfile.data()?['role']));
      }
      await _createMobileProfile(
        user: user,
        phone: normalizedPhone,
        name: name.trim().isEmpty
            ? (user.displayName ?? 'Farmora User')
            : name.trim(),
        role: role,
        provider: 'google',
        district: district,
      );
      return FarmoraAuthResult(role);
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    } on FarmoraAuthException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FarmoraAuthException(error.code == 'permission-denied'
          ? 'This mobile number is already registered to another account.'
          : (error.message ?? 'Could not save your profile.'));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this phone number.';
      case 'weak-password':
        return 'Password must contain at least 6 characters.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Phone number or password is incorrect.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Enable this sign-in provider in Firebase Authentication.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}

// ── Missing methods (used by Kajana's FarmoraState) ────
extension FirebaseAuthServiceExtras on FirebaseAuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    final authIndex = await FirebaseFirestore.instance.collection('authUsers').doc(uid).get();
    if (authIndex.exists) {
      final phone = authIndex.data()?['phone'] as String?;
      if (phone != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
        if (doc.exists) return doc.data();
      }
    }
    // Fallback if saved directly under uid
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
