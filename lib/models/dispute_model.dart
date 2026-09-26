import '../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import '../core/utils/firebase_values.dart';

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

  /// Tolerates both the callable-written schema (`openedBy`, `reason` text,
  /// `adminNotes`, Timestamp dates) and the legacy ISO-string shape.
  factory Dispute.fromMap(String id, Map<String, dynamic> data) {
    final rawReason = (data['reason'] ?? '').toString();
    final evidence = data['evidenceImages'] ?? data['evidenceUrls'];
    final rawStatus = (data['status'] ?? 'open')
        .toString()
        .replaceAll('_', '')
        .toLowerCase();
    return Dispute(
      id: id,
      orderId: (data['orderId'] ?? '').toString(),
      orderNumber: (data['orderNumber'] ?? '').toString(),
      userId: (data['userId'] ?? data['openedBy'] ?? '').toString(),
      userName: (data['userName'] ?? data['openedByName'] ?? '').toString(),
      reason: DisputeReason.values.firstWhere(
        (e) => e.name == rawReason.split(':').first.trim(),
        orElse: () => DisputeReason.other,
      ),
      description: (data['description'] ?? rawReason).toString(),
      status: DisputeStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawStatus,
        orElse: () => DisputeStatus.open,
      ),
      adminResponse:
          (data['adminResponse'] ?? data['adminNotes'])?.toString(),
      createdAt: firebaseDate(data['createdAt']) ?? DateTime.now(),
      resolvedAt: firebaseDate(data['resolvedAt']),
      evidenceImages: evidence is List
          ? evidence.map((e) => e.toString()).toList()
          : null,
    );
  }

  String getReasonDisplayName() {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return L10n.current.disputeReasonDamaged;
      case DisputeReason.wrongItems:
        return L10n.current.disputeReasonWrongItems;
      case DisputeReason.lateDelivery:
        return L10n.current.disputeReasonLate;
      case DisputeReason.qualityIssues:
        return L10n.current.disputeReasonQuality;
      case DisputeReason.pricingDiscrepancy:
        return L10n.current.disputeReasonPricing;
      case DisputeReason.other:
        return L10n.current.disputeReasonOther;
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
        return L10n.current.statusOpen;
      case DisputeStatus.underReview:
        return L10n.current.statusUnderReview;
      case DisputeStatus.resolved:
        return L10n.current.statusResolved;
      case DisputeStatus.rejected:
        return L10n.current.statusRejected;
    }
  }
}