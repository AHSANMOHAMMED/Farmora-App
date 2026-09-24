import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingMessage {
  final String orderId;
  final String recipientId;
  final String ciphertext;

  PendingMessage({
    required this.orderId,
    required this.recipientId,
    required this.ciphertext,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'recipientId': recipientId,
        'ciphertext': ciphertext,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) {
    return PendingMessage(
      orderId: json['orderId'],
      recipientId: json['recipientId'],
      ciphertext: json['ciphertext'],
    );
  }
}

class ChatOutboxService {
  static const _key = 'chat_outbox';
  
  static Future<void> enqueue(PendingMessage msg) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getPending(prefs);
    list.add(msg.toJson());
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<PendingMessage>> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getPending(prefs);
    return list.map((e) => PendingMessage.fromJson(e)).toList();
  }
  
  static Future<void> remove(PendingMessage msg) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getPending(prefs);
    list.removeWhere((e) => 
      e['orderId'] == msg.orderId && 
      e['ciphertext'] == msg.ciphertext
    );
    await prefs.setString(_key, jsonEncode(list));
  }

  static List<Map<String, dynamic>> _getPending(SharedPreferences prefs) {
    final str = prefs.getString(_key);
    if (str == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(str));
    } catch (_) {
      return [];
    }
  }
}
