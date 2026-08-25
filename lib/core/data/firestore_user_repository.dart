import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Firestore-backed user profile operations.
class FirestoreUserRepository {
  final FirebaseFirestore _db;

  FirestoreUserRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return AppUser.fromJson(data);
  }

  /// Create user profile after sign-up/onboarding
  Future<void> createUserProfile(AppUser user) async {
    final data = user.toJson();
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.id).set(data);
  }

  /// Update user profile
  Future<void> updateUserProfile(AppUser user) async {
    final data = user.toJson();
    data.remove('id');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.id).update(data);
  }

  /// Stream user profile changes
  Stream<AppUser?> watchUserProfile(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return AppUser.fromJson(data);
    });
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding(String userId) async {
    await _users.doc(userId).update({
      'isOnboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend/unsuspend user (admin)
  Future<void> setUserSuspended(String userId, bool suspended) async {
    await _users.doc(userId).update({
      'isSuspended': suspended,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
