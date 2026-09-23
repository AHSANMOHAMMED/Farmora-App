import 'package:flutter/material.dart';

enum DisputeStatus {
  open,
  underReview,
  resolved,
  rejected,
}

enum DisputeReason {
  damagedGoods,
  wrongItems,
  lateDelivery,
  qualityIssues,
  pricingDiscrepancy,
  other,
}

class Dispute {
  final String id;
  final String orderId;
  final String orderNumber;
  final String userId;
  final String userName;
  final DisputeReason reason;
  final String description;
  final DisputeStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<String>? evidenceImages;

  const Dispute({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.reason,
    required this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.resolvedAt,
    this.evidenceImages,
  });

  Dispute copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? userId,
    String? userName,
    DisputeReason? reason,
    String? description,
    DisputeStatus? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? resolvedAt,
    List<String>? evidenceImages,
  }) {
    return Dispute(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      evidenceImages: evidenceImages ?? this.evidenceImages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'userId': userId,
      'userName': userName,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'evidenceImages': evidenceImages,
    };
  }

  factory Dispute.fromMap(String id, Map<String, dynamic> data) {
    return Dispute(
      id: id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      reason: DisputeReason.values.firstWhere(
        (e) => e.name == (data['reason']?.toString().split(':').first.trim() ?? ''),
        orElse: () => DisputeReason.other,
      ),
      description: data['description'] ?? '',
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DisputeStatus.open,
      ),
      adminResponse: data['adminResponse'] as String?,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: data['resolvedAt'] != null 
          ? DateTime.parse(data['resolvedAt']) 
          : null,
      evidenceImages: data['evidenceImages'] != null 
          ? List<String>.from(data['evidenceImages']) 
          : null,
    );
  }

  String getReasonDisplayName() {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return 'Damaged Goods';
      case DisputeReason.wrongItems:
        return 'Wrong Items';
      case DisputeReason.lateDelivery:
        return 'Late Delivery';
      case DisputeReason.qualityIssues:
        return 'Quality Issues';
      case DisputeReason.pricingDiscrepancy:
        return 'Pricing Discrepancy';
      case DisputeReason.other:
        return 'Other';
    }
  }

  IconData getReasonIcon() {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return Icons.broken_image;
      case DisputeReason.wrongItems:
        return Icons.remove_shopping_cart;
      case DisputeReason.lateDelivery:
        return Icons.access_time;
      case DisputeReason.qualityIssues:
        return Icons.star_half;
      case DisputeReason.pricingDiscrepancy:
        return Icons.attach_money;
      case DisputeReason.other:
        return Icons.report;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case DisputeStatus.open:
        return Colors.orange;
      case DisputeStatus.underReview:
        return Colors.blue;
      case DisputeStatus.resolved:
        return Colors.green;
      case DisputeStatus.rejected:
        return Colors.red;
    }
  }

  String getStatusDisplayName() {
    switch (status) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.underReview:
        return 'Under Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.rejected:
        return 'Rejected';
    }
  }
}