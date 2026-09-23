enum TransporterNotificationType {
  newJob,
  accepted,
  reminder,
  cancelled,
  completed,
}

class TransporterNotification {
  final String id;
  final TransporterNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? jobId;
  final bool isRead;

  const TransporterNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.jobId,
    this.isRead = false,
  });

  TransporterNotification copyWith({bool? isRead}) => TransporterNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        createdAt: createdAt,
        jobId: jobId,
        isRead: isRead ?? this.isRead,
      );
}
