import '../core/utils/firebase_values.dart';

class FarmoraConversation {
  final String id;
  final String orderId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final String lastSenderId;

  /// False for a conversation that has not been created on the server yet
  /// (the first `sendMessage` creates it).
  final bool exists;

  const FarmoraConversation({
    required this.id,
    required this.orderId,
    required this.participantIds,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
    this.lastSenderId = '',
    this.exists = true,
  });

  /// The other participant for [uid] (empty when unknown).
  String peerOf(String uid) => participantIds.firstWhere(
        (id) => id != uid,
        orElse: () => '',
      );

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  factory FarmoraConversation.fromMap(String id, Map<String, dynamic> data) {
    return FarmoraConversation(
      id: id,
      orderId: (data['orderId'] ?? '').toString(),
      participantIds: (data['participantIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageAt: firebaseDate(data['lastMessageAt']),
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
        ),
      ),
      lastSenderId: (data['lastSenderId'] ?? '').toString(),
    );
  }
}

/// What a chat photo is for. Payment proofs are also linked to the order.
class ChatAttachmentKind {
  static const photo = 'photo';
  static const paymentProof = 'payment_proof';
}

/// An image stored in Firebase Storage and referenced by a chat message.
class ChatAttachment {
  const ChatAttachment({
    required this.url,
    required this.path,
    this.kind = ChatAttachmentKind.photo,
  });

  final String url;
  final String path;
  final String kind;

  bool get isPaymentProof => kind == ChatAttachmentKind.paymentProof;
}

class FarmoraMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;

  /// Encrypted text (`farmora3:` ciphertext). Empty for photo-only messages.
  final String body;
  final String? attachmentUrl;
  final String? attachmentPath;
  final String attachmentKind;
  final DateTime? readAt;
  final DateTime createdAt;

  const FarmoraMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.body,
    this.attachmentUrl,
    this.attachmentPath,
    this.attachmentKind = ChatAttachmentKind.photo,
    this.readAt,
    required this.createdAt,
  });

  bool get hasImage => (attachmentUrl ?? '').isNotEmpty;
  bool get isPaymentProof =>
      hasImage && attachmentKind == ChatAttachmentKind.paymentProof;

  factory FarmoraMessage.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseTs(dynamic v) =>
        firebaseDate(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return FarmoraMessage(
      id: id,
      conversationId: (data['conversationId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      recipientId:
          (data['recipientId'] ?? data['receiverId'] ?? '').toString(),
      body: (data['ciphertext'] ?? data['body'] ?? '').toString(),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentPath: data['attachmentPath'] as String?,
      attachmentKind:
          (data['attachmentKind'] ?? ChatAttachmentKind.photo).toString(),
      readAt: firebaseDate(data['readAt']),
      createdAt: parseTs(data['createdAt']),
    );
  }
}
