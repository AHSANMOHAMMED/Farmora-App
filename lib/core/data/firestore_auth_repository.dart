import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';

/// Firebase Auth + Firestore implementation of [AuthRepository].
class FirestoreAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirestoreAuthRepository(this._auth, this._db);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fb.User? firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid);
    });
  }

  @override
  AppUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    // Synchronous read from last known state; callers should prefer authStateChanges stream
    return AppUser(
      id: fbUser.uid,
      role: Role.buyer, // default; overridden by Firestore profile
      displayName: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      phone: fbUser.phoneNumber ?? '',
    );
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);

    // Create Firestore profile
    final appUser = AppUser(
      id: cred.user!.uid,
      role: Role.buyer,
      displayName: displayName,
      email: email,
      isOnboardingComplete: false,
    );
    await _createFirestoreProfile(appUser);
    return appUser;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = await _getUserFromFirestore(cred.user!.uid);
    if (user == null) {
      // First time sign-in, create profile
      final appUser = AppUser(
        id: cred.user!.uid,
        role: Role.buyer,
        displayName: cred.user!.displayName ?? email.split('@').first,
        email: email,
        isOnboardingComplete: false,
      );
      await _createFirestoreProfile(appUser);
      return appUser;
    }
    return user;
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-retrieval on Android — sign in directly
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        onError(e.message ?? 'Phone verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op
      },
    );
  }

  @override
  Future<AppUser> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = await _getUserFromFirestore(cred.user!.uid);
    if (user == null) {
      final appUser = AppUser(
        id: cred.user!.uid,
        role: Role.buyer,
        phone: cred.user!.phoneNumber ?? '',
        isOnboardingComplete: false,
      );
      await _createFirestoreProfile(appUser);
      return appUser;
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).delete();
    await user.delete();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    if (_auth.currentUser != null) {
      await _users.doc(_auth.currentUser!.uid).update({'displayName': name});
    }
  }

  // ─── Private helpers ───────────────────────────────────────

  Future<AppUser?> _getUserFromFirestore(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return AppUser.fromJson(data);
  }

  Future<void> _createFirestoreProfile(AppUser user) async {
    final data = user.toJson();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.id).set(data);
  }
}
