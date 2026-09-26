import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingMessage {
  final String orderId;
  final String recipientId;
  final String ciphertext;

  /// Conversation the message belongs to (null for legacy queued entries).
  final String? conversationId;

  PendingMessage({
    required this.orderId,
    required this.recipientId,
    required this.ciphertext,
    this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'recipientId': recipientId,
        'ciphertext': ciphertext,
        if (conversationId != null) 'conversationId': conversationId,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) {
    return PendingMessage(
      orderId: (json['orderId'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? '').toString(),
      ciphertext: (json['ciphertext'] ?? '').toString(),
      conversationId: json['conversationId']?.toString(),
    );
  }
}

/// Encrypted chat messages that could not be delivered because the device
/// was offline. Stored per account (`chat_outbox_<uid>`) so a different
/// account on the same device never sends someone else's queued messages.
///
/// Only connectivity failures belong here ([shouldQueue]); a rejected
/// message (permission, validation, maintenance) must be shown as failed.
class ChatOutboxService {
  static const _legacyKey = 'chat_outbox';

  static String _keyFor(String uid) => 'chat_outbox_$uid';

  static String _currentUid() {
    try {
      if (Firebase.apps.isEmpty) return '';
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// True when [error] means "offline / server unreachable" and the message
  /// should be retried later rather than reported as rejected.
  static bool shouldQueue(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseFunctionsException) {
      final message = (error.message ?? '').toLowerCase();
      if (error.code == 'unavailable') {
        // Maintenance mode is also `unavailable` but is a server decision.
        return !message.contains('maintenance');
      }
      return error.code == 'deadline-exceeded' ||
          (error.code == 'internal' &&
              (message.isEmpty || message == 'internal'));
    }
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'network-request-failed' ||
          error.code == 'deadline-exceeded';
    }
    return false;
  }

  static Future<void> enqueue(PendingMessage msg, {String? uid}) async {
    final owner = uid ?? _currentUid();
    if (owner.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = _getPending(prefs, owner);
    list.add(msg.toJson());
    await prefs.setString(_keyFor(owner), jsonEncode(list));
  }

  static Future<List<PendingMessage>> getPending({String? uid}) async {
    final owner = uid ?? _currentUid();
    if (owner.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    // The pre-per-account queue cannot be attributed to an account safely.
    if (prefs.containsKey(_legacyKey)) await prefs.remove(_legacyKey);
    final list = _getPending(prefs, owner);
    return list.map((e) => PendingMessage.fromJson(e)).toList();
  }

  static Future<void> remove(PendingMessage msg, {String? uid}) async {
    final owner = uid ?? _currentUid();
    if (owner.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = _getPending(prefs, owner);
    list.removeWhere(
        (e) => e['orderId'] == msg.orderId && e['ciphertext'] == msg.ciphertext);
    await prefs.setString(_keyFor(owner), jsonEncode(list));
  }

  /// Drops every queued message for [uid] (sign-out).
  static Future<void> clear(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(uid));
  }

  static List<Map<String, dynamic>> _getPending(
      SharedPreferences prefs, String uid) {
    final str = prefs.getString(_keyFor(uid));
    if (str == null) return [];
    try {
      return (jsonDecode(str) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
