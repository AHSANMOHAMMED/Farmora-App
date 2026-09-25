import '../core/utils/firebase_values.dart';

class FarmoraConversation {
  final String id;
  final String orderId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;

  const FarmoraConversation({
    required this.id,
    required this.orderId,
    required this.participantIds,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  factory FarmoraConversation.fromMap(String id, Map<String, dynamic> data) {
    return FarmoraConversation(
      id: id,
      orderId: (data['orderId'] ?? '').toString(),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageAt: firebaseDate(data['lastMessageAt']),
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
        ),
      ),
    );
  }
}

class FarmoraMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String body;
  final String? attachmentUrl;
  final DateTime? readAt;
  final DateTime createdAt;

  const FarmoraMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.body,
    this.attachmentUrl,
    this.readAt,
    required this.createdAt,
  });

  factory FarmoraMessage.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseTs(dynamic v) =>
        firebaseDate(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return FarmoraMessage(
      id: id,
      conversationId: (data['conversationId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      body: (data['body'] ?? data['ciphertext'] ?? '').toString(),
      attachmentUrl: data['attachmentUrl'] as String?,
      readAt: firebaseDate(data['readAt']),
      createdAt: parseTs(data['createdAt']),
    );
  }
}
