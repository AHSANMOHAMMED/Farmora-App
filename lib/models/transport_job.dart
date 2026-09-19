import 'package:cloud_firestore/cloud_firestore.dart';

enum TransportJobStatus {
  pending,
  accepted,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case TransportJobStatus.pending:
        return 'Pending';
      case TransportJobStatus.accepted:
        return 'Accepted';
      case TransportJobStatus.inTransit:
        return 'In Transit';
      case TransportJobStatus.delivered:
        return 'Delivered';
      case TransportJobStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TransportJobStatus fromString(String value) {
    return TransportJobStatus.values.firstWhere(
      (e) => e.name == value || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => TransportJobStatus.pending,
    );
  }

  bool get isActive =>
      this == TransportJobStatus.pending ||
      this == TransportJobStatus.accepted ||
      this == TransportJobStatus.inTransit;

  bool get canTransitionToDelivered =>
      this == TransportJobStatus.inTransit || this == TransportJobStatus.accepted;
}

class TransportJob {
  final String id;
  final String title;
  final String route;
  final String detail;
  final String fee;
  final bool accepted;
  final TransportJobStatus status;
  final String? createdBy;
  final String? transporterId;
  final String? orderId;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? cargoWeightKg;
  final DateTime? pickupTime;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const TransportJob({
    required this.id,
    required this.title,
    required this.route,
    required this.detail,
    required this.fee,
    this.accepted = false,
    this.status = TransportJobStatus.pending,
    this.createdBy,
    this.transporterId,
    this.orderId,
    this.pickupAddress,
    this.dropoffAddress,
    this.cargoWeightKg,
    this.pickupTime,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  TransportJob copyWith({
    String? id,
    String? title,
    String? route,
    String? detail,
    String? fee,
    bool? accepted,
    TransportJobStatus? status,
    String? createdBy,
    String? transporterId,
    String? orderId,
    String? pickupAddress,
    String? dropoffAddress,
    double? cargoWeightKg,
    DateTime? pickupTime,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return TransportJob(
      id: id ?? this.id,
      title: title ?? this.title,
      route: route ?? this.route,
      detail: detail ?? this.detail,
      fee: fee ?? this.fee,
      accepted: accepted ?? this.accepted,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      transporterId: transporterId ?? this.transporterId,
      orderId: orderId ?? this.orderId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      cargoWeightKg: cargoWeightKg ?? this.cargoWeightKg,
      pickupTime: pickupTime ?? this.pickupTime,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'route': route,
      'detail': detail,
      'fee': fee,
      'accepted': accepted,
      'status': status.name,
      'createdBy': createdBy,
      'transporterId': transporterId,
      'orderId': orderId,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'cargoWeightKg': cargoWeightKg,
      'pickupTime': pickupTime?.toIso8601String(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  /// Deserialize from Firestore Map
  factory TransportJob.fromMap(String id, Map<String, dynamic> data) {
    return TransportJob(
      id: id,
      title: data['title'] ?? '',
      route: data['route'] ?? '',
      detail: data['detail'] ?? '',
      fee: data['fee'] ?? '',
      accepted: data['accepted'] ?? false,
      status: TransportJobStatus.fromString(data['status'] ?? 'pending'),
      createdBy: data['createdBy'] as String?,
      transporterId: data['transporterId'] as String?,
      orderId: data['orderId'] as String?,
      pickupAddress: data['pickupAddress'] as String?,
      dropoffAddress: data['dropoffAddress'] as String?,
      cargoWeightKg: (data['cargoWeightKg'] as num?)?.toDouble(),
      pickupTime: data['pickupTime'] != null
          ? DateTime.tryParse(data['pickupTime'] as String)
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      acceptedAt: data['acceptedAt'] != null
          ? DateTime.tryParse(data['acceptedAt'] as String)
          : null,
      pickedUpAt: data['pickedUpAt'] != null
          ? DateTime.tryParse(data['pickedUpAt'] as String)
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? DateTime.tryParse(data['deliveredAt'] as String)
          : null,
    );
  }

  /// Check if a status transition is valid
  bool canTransitionTo(TransportJobStatus newStatus) {
    return switch (status) {
      TransportJobStatus.pending =>
        newStatus == TransportJobStatus.accepted ||
            newStatus == TransportJobStatus.cancelled,
      TransportJobStatus.accepted =>
        newStatus == TransportJobStatus.inTransit ||
            newStatus == TransportJobStatus.cancelled,
      TransportJobStatus.inTransit =>
        newStatus == TransportJobStatus.delivered ||
            newStatus == TransportJobStatus.cancelled,
      TransportJobStatus.delivered => false,
      TransportJobStatus.cancelled => false,
    };
  }

  /// Get the next valid status for a step-based workflow
  TransportJobStatus? get nextStatus {
    return switch (status) {
      TransportJobStatus.pending => TransportJobStatus.accepted,
      TransportJobStatus.accepted => TransportJobStatus.inTransit,
      TransportJobStatus.inTransit => TransportJobStatus.delivered,
      TransportJobStatus.delivered => null,
      TransportJobStatus.cancelled => null,
    };
  }
}
