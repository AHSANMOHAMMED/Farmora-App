import '../domain/transporter_notification.dart';
import '../domain/transporter_profile.dart';

abstract interface class TransporterAccountRepository {
  Stream<TransporterProfile> watchProfile(String providerId);

  Stream<List<TransporterNotification>> watchNotifications(String providerId);

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllNotificationsRead(String providerId);

  /// Districts the transporter serves (`serviceDistricts` on the profile).
  Stream<List<String>> watchServiceDistricts(String providerId);

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleRegistration,
    required double? vehicleCapacity,
    required String vehicleCapacityUnit,
    required String vehicleDescription,
    required bool isAvailable,
    List<String>? serviceDistricts,
  });

  /// Availability-only update (`{availabilityStatus}`), so toggling
  /// availability never re-validates or overwrites the rest of the profile.
  Future<void> updateAvailability(bool isAvailable);
}
