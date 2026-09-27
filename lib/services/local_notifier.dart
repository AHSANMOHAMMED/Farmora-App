import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';

/// Shows system notifications for new in-app notifications while the app is
/// running (foreground or background), and for FCM messages received in the
/// foreground. Works on the Spark plan without any server (on web through
/// the browser Notification API; permission comes from the FCM prompt).
class LocalNotifier {
  LocalNotifier._();
  static final LocalNotifier instance = LocalNotifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Ids already seen this session (the first snapshot is not announced).
  final Set<String> _seen = {};
  bool _primed = false;

  static const _channel = AndroidNotificationDetails(
    'farmora_updates',
    'Farmora updates',
    channelDescription: 'Orders, deliveries, messages and advice',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          web: WebInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
    }
  }

  /// Forget the session (sign-out / account switch).
  void reset() {
    _seen.clear();
    _primed = false;
  }

  Future<void> show(String title, String body, {int? id}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          web: WebNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Local notification skipped: $e');
    }
  }

  /// Announces notifications that arrived since the last snapshot, subject
  /// to the user's preferences and quiet hours.
  void onSnapshot(List<FarmoraNotification> items, Map<String, dynamic> prefs) {
    if (!_primed) {
      _seen.addAll(items.map((n) => n.id));
      _primed = true;
      return;
    }
    for (final n in items) {
      if (!_seen.add(n.id) || n.read) continue;
      if (DateTime.now().difference(n.createdAt).inMinutes > 10) continue;
      if (!allowed(n.type, prefs, DateTime.now())) continue;
      show(n.title, n.body, id: n.id.hashCode & 0x3fffffff);
    }
  }

  /// Preference category of a notification type (mirrors the Cloud
  /// Functions' notificationCategory).
  static String categoryOf(String type) => switch (type) {
        'message' => 'messages',
        'general' || 'market_price' => 'promos',
        _ => 'orderUpdates',
      };

  /// Whether [type] may be shown now under [prefs].
  static bool allowed(String type, Map<String, dynamic> prefs, DateTime now) {
    if (prefs[categoryOf(type)] == false) return false;
    final start = prefs['quietHoursStart'];
    final end = prefs['quietHoursEnd'];
    if (start is int && end is int && start != end) {
      final h = now.hour;
      final quiet = start < end ? h >= start && h < end : h >= start || h < end;
      if (quiet) return false;
    }
    return true;
  }
}
