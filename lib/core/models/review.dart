import 'package:equatable/equatable.dart';

enum ReviewModerationStatus {
  pending,
  approved,
  rejected,
  reported;
}

class ReviewModel extends Equatable {
  final String id;
  final String orderId;
  final String authorId;
  final String subjectId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final ReviewModerationStatus moderationStatus;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.subjectId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
    this.moderationStatus = ReviewModerationStatus.pending,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        authorId: json['authorId'] as String,
        subjectId: json['subjectId'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        moderationStatus: ReviewModerationStatus.values.firstWhere(
          (m) => m.name == json['moderationStatus'],
          orElse: () => ReviewModerationStatus.pending,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'authorId': authorId,
        'subjectId': subjectId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'moderationStatus': moderationStatus.name,
      };

  @override
  List<Object?> get props => [
        id, orderId, authorId, subjectId, rating,
        comment, createdAt, moderationStatus,
      ];
}
