import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_role.dart';
import '../utils/app_errors.dart';

/// Auth failure with a user-facing (English) message. Extends
/// [AppException] so `userMessage(e)` shows it as-is.
class FarmoraAuthException extends AppException {
  const FarmoraAuthException(super.message);
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

  /// Sign-in e-mails to try for [phone], newest scheme first: the E.164
  /// form, then the number exactly as typed and the local 0-prefixed form
  /// (accounts registered before phone numbers were normalised).
  List<String> _loginEmailCandidates(String phone) {
    final candidates = <String>[];
    void add(String value) {
      final email = _emailForPhone(value);
      if (!candidates.contains(email)) candidates.add(email);
    }

    String? e164;
    try {
      e164 = _phoneInE164(phone);
      add(e164);
    } on FarmoraAuthException {
      // Not a normalisable number: fall back to the legacy form only.
    }
    add(_normalizePhone(phone));
    if (e164 != null && e164.startsWith('+94')) add('0${e164.substring(3)}');
    return candidates;
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
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'privacyAcceptedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Password registration. The phone is stored in E.164 form. When the
  /// caller verified the number with [sendPhoneOtp] first, pass the SMS
  /// [phoneOtpCode]: the phone credential is then linked to the account so
  /// the password can later be reset by OTP ([resetPasswordWithOtp]).
  Future<FarmoraAuthResult> register({
    required String name,
    required String phone,
    required String password,
    required Role role,
    String? district,
    String? phoneOtpCode,
  }) async {
    UserCredential? credential;
    try {
      final normalizedPhone = _phoneInE164(phone);
      credential = await _auth.createUserWithEmailAndPassword(
        email: _emailForPhone(normalizedPhone),
        password: password,
      );
      if (phoneOtpCode != null && phoneOtpCode.trim().isNotEmpty) {
        await _tryLinkPhone(credential.user!, phoneOtpCode);
      }
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
      final credential = await _signInWithPhonePassword(phone, password);
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

  Future<UserCredential> _signInWithPhonePassword(
      String phone, String password) async {
    FirebaseAuthException? firstError;
    for (final email in _loginEmailCandidates(phone)) {
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        const retryable = {
          'user-not-found',
          'invalid-credential',
          'invalid-email',
          'wrong-password',
        };
        firstError ??= error;
        if (!retryable.contains(error.code)) rethrow;
      }
    }
    throw firstError ??
        FirebaseAuthException(code: 'invalid-credential');
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
      final String normalizedPhone;
      try {
        normalizedPhone = _phoneInE164(phone);
      } on FarmoraAuthException {
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
    var phone = _normalizePhone(value);
    if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
    if (RegExp(r'^\+[1-9]\d{8,14}$').hasMatch(phone)) return phone;
    if (RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return '+94${phone.substring(1)}';
    }
    if (RegExp(r'^94\d{9}$').hasMatch(phone)) return '+$phone';
    if (RegExp(r'^[1-9]\d{8}$').hasMatch(phone)) return '+94$phone';
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

  Future<void> signOut() => _auth.signOut();

  /// Phone credential for the last OTP requested with [sendPhoneOtp] /
  /// [sendPasswordResetOtp] (mobile platforms).
  PhoneAuthCredential _phoneCredential(String code,
      {String? verificationId}) {
    final trimmedCode = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw const FarmoraAuthException('Enter the 6-digit verification code.');
    }
    final id = verificationId ?? _verificationId;
    if ((id == null || id.isEmpty) && _automaticCredential != null) {
      return _automaticCredential!;
    }
    if (id == null || id.isEmpty) {
      throw const FarmoraAuthException('Request a new OTP first.');
    }
    return PhoneAuthProvider.credential(verificationId: id, smsCode: trimmedCode);
  }

  /// Best-effort: link the verified phone number to a new password account.
  /// Registration must not fail because linking did (e.g. web, or the phone
  /// already belongs to another sign-in).
  Future<void> _tryLinkPhone(User user, String code) async {
    try {
      await user.linkWithCredential(_phoneCredential(code));
    } catch (error) {
      debugPrint('Phone link at registration skipped: $error');
    }
  }

  /// Links the phone number verified with [sendPhoneOtp] to the signed-in
  /// account (enables OTP password reset for older accounts).
  Future<void> linkPhoneWithOtp(String code) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FarmoraAuthException('Please sign in again.');
    }
    try {
      await user.linkWithCredential(_phoneCredential(code));
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') return;
      if (error.code == 'credential-already-in-use') {
        throw const FarmoraAuthException(
          'This mobile number is already registered to another account.',
        );
      }
      throw FarmoraAuthException(_authMessage(error));
    }
  }

  /// Step 1 of "forgot password": sends an SMS code to [phone] and returns
  /// the verification id to pass to [resetPasswordWithOtp]. On Android the
  /// code may be verified automatically; the id is still returned.
  Future<String> sendPasswordResetOtp(String phone) async {
    await sendPhoneOtp(phone);
    if (kIsWeb) return _webConfirmation?.verificationId ?? '';
    return _verificationId ?? '';
  }

  /// Step 2 of "forgot password": signs in with the SMS code and, when that
  /// phone number is linked to a password account, sets [newPassword].
  /// Signs out afterwards so the user logs in with the new password.
  Future<void> resetPasswordWithOtp({
    required String verificationId,
    required String code,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const FarmoraAuthException(
          'Password must contain at least 6 characters.');
    }
    UserCredential credential;
    try {
      if (kIsWeb && _webConfirmation != null) {
        credential = await _webConfirmation!.confirm(code.trim());
      } else {
        credential = await _auth.signInWithCredential(
          _phoneCredential(code, verificationId: verificationId),
        );
      }
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
    final user = credential.user!;
    final hasPassword =
        user.providerData.any((info) => info.providerId == 'password');
    if (!hasPassword) {
      // The phone is not linked to a password account: undo a brand-new
      // phone-only user created by this sign-in and explain.
      if (credential.additionalUserInfo?.isNewUser == true) {
        try {
          await user.delete();
        } catch (_) {}
      }
      await _auth.signOut();
      throw const FarmoraAuthException(
        'This mobile number is not linked to a password account. '
        'Sign in with your password or contact support.',
      );
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    } finally {
      await _auth.signOut();
    }
  }

  /// Changes the signed-in user's password after re-authenticating with
  /// [currentPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const FarmoraAuthException(
          'Password sign-in is not enabled for this account.');
    }
    if (newPassword.length < 6) {
      throw const FarmoraAuthException(
          'Password must contain at least 6 characters.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw FarmoraAuthException(_authMessage(error));
    }
  }

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
      case 'requires-recent-login':
        return 'Please sign in again, then retry.';
      case 'user-disabled':
        return 'This account has been suspended.';
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
