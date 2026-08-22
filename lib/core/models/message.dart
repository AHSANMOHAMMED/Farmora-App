import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final String orderId;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.orderId,
    required this.participantIds,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCounts = const {},
    this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        participantIds: (json['participantIds'] as List).cast<String>(),
        lastMessage: json['lastMessage'] as String? ?? '',
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'] as String)
            : null,
        unreadCounts: (json['unreadCounts'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'unreadCounts': unreadCounts,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, orderId, participantIds, lastMessage,
        lastMessageAt, unreadCounts, createdAt,
      ];
}

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String body;
  final String attachmentUrl;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    this.body = '',
    this.attachmentUrl = '',
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        recipientId: json['recipientId'] as String,
        body: json['body'] as String? ?? '',
        attachmentUrl: json['attachmentUrl'] as String? ?? '',
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'recipientId': recipientId,
        'body': body,
        'attachmentUrl': attachmentUrl,
        'readAt': readAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, conversationId, senderId, recipientId,
        body, attachmentUrl, readAt, createdAt,
      ];
}
