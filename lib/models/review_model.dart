import 'package:flutter/material.dart';

enum ReviewStatus {
  pending,
  approved,
  rejected,
}

class Review {
  final String id;
  final String orderId;
  final String orderNumber;
  final String reviewerId;
  final String reviewerName;
  final String subjectId;
  final String subjectName;
  final int rating;
  final String comment;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? moderatedAt;
  final String? moderationNote;

  const Review({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.reviewerId,
    required this.reviewerName,
    required this.subjectId,
    required this.subjectName,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
    this.moderatedAt,
    this.moderationNote,
  });

  Review copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? reviewerId,
    String? reviewerName,
    String? subjectId,
    String? subjectName,
    int? rating,
    String? comment,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? moderatedAt,
    String? moderationNote,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderationNote: moderationNote ?? this.moderationNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'rating': rating,
      'comment': comment,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'moderatedAt': moderatedAt?.toIso8601String(),
      'moderationNote': moderationNote,
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    ReviewStatus statusValue = ReviewStatus.pending;
    // `status` is the canonical field; fall back to legacy `moderationStatus`
    // written by submitReview / older clients.
    final rawStatus = (data['status'] ?? data['moderationStatus'])?.toString();
    if (rawStatus != null) {
      try {
        statusValue = ReviewStatus.values.firstWhere(
          (e) => e.name == rawStatus,
        );
      } catch (e) {
        statusValue = ReviewStatus.pending;
      }
    }

    return Review(
      id: id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment'] ?? '',
      status: statusValue,
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      moderatedAt: data['moderatedAt'] != null
          ? DateTime.parse(data['moderatedAt'])
          : null,
      moderationNote: data['moderationNote'] as String?,
    );
  }

  String getStatusDisplayName() {
    switch (status) {
      case ReviewStatus.pending:
        return 'Pending';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case ReviewStatus.pending:
        return Colors.orange;
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
    }
  }

  List<Widget> buildStars() {
    return List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      );
    });
  }

  String getRatingText() {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Terrible';
      default:
        return 'No rating';
    }
  }
}
