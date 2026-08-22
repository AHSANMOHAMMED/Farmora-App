import '../models/user.dart';

/// Abstract interface for authentication operations.
/// Firebase implementation will be in features/auth/data/.
abstract class AuthRepository {
  /// Stream of auth state changes (null when signed out)
  Stream<AppUser?> get authStateChanges;

  /// Get currently signed-in user (or null)
  AppUser? get currentUser;

  /// Sign up with email and password
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with email and password
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with phone number (sends verification code)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  });

  /// Complete phone sign-in with verification code
  Future<AppUser> signInWithPhone({
    required String verificationId,
    required String smsCode,
  });

  /// Sign out
  Future<void> signOut();

  /// Delete account
  Future<void> deleteAccount();

  /// Reset password
  Future<void> resetPassword(String email);

  /// Update display name
  Future<void> updateDisplayName(String name);
}
