/// Abstract interface for push notification operations.
abstract class NotificationRepository {
  /// Request notification permissions
  Future<bool> requestPermission();

  /// Get FCM token
  Future<String?> getToken();

  /// Save FCM token to user document
  Future<void> saveToken(String userId, String token);

  /// Delete FCM token on sign-out
  Future<void> deleteToken(String userId);

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);
}
