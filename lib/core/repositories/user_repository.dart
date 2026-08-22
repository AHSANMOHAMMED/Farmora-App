import '../models/user.dart';

/// Abstract interface for user profile operations.
abstract class UserRepository {
  /// Get user by ID
  Future<AppUser?> getUserById(String userId);

  /// Get current user's profile
  Future<AppUser?> getCurrentUserProfile();

  /// Create user profile after sign-up/onboarding
  Future<void> createUserProfile(AppUser user);

  /// Update user profile
  Future<void> updateUserProfile(AppUser user);

  /// Stream user profile changes
  Stream<AppUser?> watchUserProfile(String userId);

  /// Mark onboarding as complete
  Future<void> completeOnboarding(String userId);

  /// Suspend/unsuspend user (admin)
  Future<void> setUserSuspended(String userId, bool suspended);
}
