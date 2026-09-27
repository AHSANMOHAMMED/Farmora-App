import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// URL of the optional push relay (push_relay/ — a free Cloudflare Worker).
/// On the Spark plan nothing else can send FCM push to a closed app; with
/// the relay deployed, every in-app notification is also pushed. Set with
/// `--dart-define=PUSH_RELAY_URL=https://farmora-push.<you>.workers.dev`.
const String kPushRelayUrl = String.fromEnvironment('PUSH_RELAY_URL');

/// Writes an in-app notification and asks the relay (if configured) to push
/// it to the recipient's devices. Returns the notification id.
Future<String> sendNotification(
    FirebaseFirestore db, Map<String, dynamic> data) async {
  final ref = await db.collection('notifications').add(data);
  triggerPush(ref.id);
  return ref.id;
}

/// Fire-and-forget push for an existing notification document. The relay
/// verifies the caller's Firebase ID token and only pushes recent,
/// not-yet-pushed notifications, so this can't be abused to spam.
void triggerPush(String notificationId) {
  if (kPushRelayUrl.isEmpty) return;
  () async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      await http
          .post(
            Uri.parse('$kPushRelayUrl/notify'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'notificationId': notificationId}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Push relay skipped: $e');
    }
  }();
}
