import '../core/utils/firebase_values.dart';

class FarmoraNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'offer', 'order', 'logistics', 'general'
  final bool read;
  final DateTime createdAt;
  final String? referenceId;

  /// Optional deep-link context written by backend triggers.
  final String? conversationId;
  final String? senderId;
  final String? orderId;
  final String? jobId;

  FarmoraNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.read = false,
    DateTime? createdAt,
    this.referenceId,
    this.conversationId,
    this.senderId,
    this.orderId,
    this.jobId,
  }) : createdAt = createdAt ?? DateTime.now();

  FarmoraNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? read,
    DateTime? createdAt,
    String? referenceId,
    String? conversationId,
    String? senderId,
    String? orderId,
    String? jobId,
  }) {
    return FarmoraNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      orderId: orderId ?? this.orderId,
      jobId: jobId ?? this.jobId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'referenceId': referenceId,
      if (conversationId != null) 'conversationId': conversationId,
      if (senderId != null) 'senderId': senderId,
      if (orderId != null) 'orderId': orderId,
      if (jobId != null) 'jobId': jobId,
    };
  }

  factory FarmoraNotification.fromMap(String id, Map<String, dynamic> data) {
    return FarmoraNotification(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      read: data['read'] == true,
      // Tolerates Firestore Timestamp (serverTimestamp) and ISO strings.
      createdAt: firebaseDate(data['createdAt']) ?? DateTime.now(),
      referenceId: _optString(data['referenceId']),
      conversationId: _optString(data['conversationId']),
      senderId: _optString(data['senderId']),
      orderId: _optString(data['orderId']),
      jobId: _optString(data['jobId']),
    );
  }

  static String? _optString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }
}
