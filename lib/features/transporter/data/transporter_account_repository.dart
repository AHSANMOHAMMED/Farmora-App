import '../domain/transporter_notification.dart';
import '../domain/transporter_profile.dart';

abstract interface class TransporterAccountRepository {
  Stream<TransporterProfile> watchProfile(String providerId);

  Stream<List<TransporterNotification>> watchNotifications(String providerId);

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllNotificationsRead(String providerId);

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleRegistration,
    required double? vehicleCapacity,
    required String vehicleCapacityUnit,
    required String vehicleDescription,
    required bool isAvailable,
  });
}
