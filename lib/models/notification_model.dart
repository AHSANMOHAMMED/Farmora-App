class FarmoraNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'offer', 'order', 'logistics', 'general'
  final bool read;
  final DateTime createdAt;
  final String? referenceId;

  FarmoraNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.read = false,
    DateTime? createdAt,
    this.referenceId,
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
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is String
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now(),
      referenceId: data['referenceId'] as String?,
    );
  }
}
