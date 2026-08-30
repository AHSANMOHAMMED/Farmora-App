import 'dart:async';

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
  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  PhoneAuthCredential? _automaticCredential;

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
    final profile = _firestore.collection('users').doc(user.uid);
    await profile.set({
      'id': user.uid,
      'name': name,
      'displayName': name,
      'phone': phone,
      'authUid': user.uid,
      'email': user.email,
      'photoUrl': user.photoURL,
      'role': role.name,
      'district': district,
      'authProvider': provider,
      'isVerified': false,
      'isSuspended': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
      final snapshot =
          await _firestore.collection('users').doc(credential.user!.uid).get();
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
      final profile = await _firestore.collection('users').doc(user.uid).get();
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
      final existingProfile =
          await _firestore.collection('users').doc(user.uid).get();
      if (existingProfile.exists) {
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

  String _phoneInE164(String value) {
    final phone = _normalizePhone(value);
    if (RegExp(r'^\+[1-9]\d{8,14}$').hasMatch(phone)) return phone;
    if (RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return '+94${phone.substring(1)}';
    }
    throw const FarmoraAuthException(
      'Enter a valid phone number, for example +94771234567.',
    );
  }

  Future<void> sendPhoneOtp(String phone) async {
    final normalizedPhone = _phoneInE164(phone);
    _webConfirmation = null;
    _verificationId = null;
    _automaticCredential = null;
    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(normalizedPhone);
        return;
      }
      final completer = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) {
          _automaticCredential = credential;
          if (!completer.isCompleted) completer.complete();
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(FarmoraAuthException(_authMessage(error)));
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
      await completer.future;
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
  }

  Future<UserCredential> _confirmPhoneOtp(String code) async {
    final trimmedCode = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw const FarmoraAuthException('Enter the 6-digit verification code.');
    }
    try {
      if (kIsWeb) {
        final confirmation = _webConfirmation;
        if (confirmation == null) {
          throw const FarmoraAuthException('Request a new OTP first.');
        }
        return await confirmation.confirm(trimmedCode);
      }
      final credential = _automaticCredential ??
          PhoneAuthProvider.credential(
            verificationId: _verificationId ?? '',
            smsCode: trimmedCode,
          );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
  }

  Future<FarmoraAuthResult> loginWithPhoneOtp(String code) async {
    final credential = await _confirmPhoneOtp(code);
    final profile =
        await _firestore.collection('users').doc(credential.user!.uid).get();
    final data = profile.data();
    if (data == null) {
      await _auth.signOut();
      throw const FarmoraAuthException(
        'No Farmora profile found. Register this phone number first.',
      );
    }
    return FarmoraAuthResult(_parseRole(data['role']));
  }

  Future<FarmoraAuthResult> registerWithPhoneOtp({
    required String code,
    required String name,
    required String phone,
    required Role role,
    String? district,
  }) async {
    final credential = await _confirmPhoneOtp(code);
    final uid = credential.user!.uid;
    final existing = await _firestore.collection('users').doc(uid).get();
    if (existing.exists) {
      return FarmoraAuthResult(_parseRole(existing.data()?['role']));
    }
    await _createMobileProfile(
      user: credential.user!,
      phone: _phoneInE164(phone),
      name: name.trim(),
      role: role,
      provider: 'phone',
      district: district,
    );
    return FarmoraAuthResult(role);
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
      case 'invalid-phone-number':
        return 'Enter a valid phone number with country code.';
      case 'invalid-verification-code':
        return 'The OTP is incorrect. Please try again.';
      case 'session-expired':
        return 'The OTP expired. Request a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Use a Firebase test phone number.';
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
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
