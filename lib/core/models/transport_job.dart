import 'package:equatable/equatable.dart';

enum TransportJobStatus {
  requested,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case TransportJobStatus.requested:
        return 'Requested';
      case TransportJobStatus.accepted:
        return 'Accepted';
      case TransportJobStatus.pickedUp:
        return 'Picked up';
      case TransportJobStatus.inTransit:
        return 'In transit';
      case TransportJobStatus.delivered:
        return 'Delivered';
      case TransportJobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class TransportJobModel extends Equatable {
  final String id;
  final String orderId;
  final String pickupAddress;
  final String dropoffAddress;
  final String cargoSummary;
  final double weightKg;
  final int offeredFeeMinor;
  final String currency;
  final TransportJobStatus status;
  final String? transporterId;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  const TransportJobModel({
    required this.id,
    required this.orderId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.cargoSummary = '',
    this.weightKg = 0.0,
    required this.offeredFeeMinor,
    this.currency = 'LKR',
    required this.status,
    this.transporterId,
    this.requestedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  String get displayFee => '$currency $offeredFeeMinor';
  String get displayRoute => '$pickupAddress → $dropoffAddress';

  /// Valid transitions from current status
  List<TransportJobStatus> get validTransitions {
    switch (status) {
      case TransportJobStatus.requested:
        return [TransportJobStatus.accepted, TransportJobStatus.cancelled];
      case TransportJobStatus.accepted:
        return [TransportJobStatus.pickedUp, TransportJobStatus.cancelled];
      case TransportJobStatus.pickedUp:
        return [TransportJobStatus.inTransit, TransportJobStatus.cancelled];
      case TransportJobStatus.inTransit:
        return [TransportJobStatus.delivered];
      case TransportJobStatus.delivered:
        return [];
      case TransportJobStatus.cancelled:
        return [];
    }
  }

  bool canTransitionTo(TransportJobStatus target) =>
      validTransitions.contains(target);

  factory TransportJobModel.fromJson(Map<String, dynamic> json) =>
      TransportJobModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        pickupAddress: json['pickupAddress'] as String,
        dropoffAddress: json['dropoffAddress'] as String,
        cargoSummary: json['cargoSummary'] as String? ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
        offeredFeeMinor: json['offeredFeeMinor'] as int,
        currency: json['currency'] as String? ?? 'LKR',
        status: TransportJobStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TransportJobStatus.requested,
        ),
        transporterId: json['transporterId'] as String?,
        requestedAt: json['requestedAt'] != null
            ? DateTime.parse(json['requestedAt'] as String)
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'] as String)
            : null,
        pickedUpAt: json['pickedUpAt'] != null
            ? DateTime.parse(json['pickedUpAt'] as String)
            : null,
        inTransitAt: json['inTransitAt'] != null
            ? DateTime.parse(json['inTransitAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'] as String)
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'cargoSummary': cargoSummary,
        'weightKg': weightKg,
        'offeredFeeMinor': offeredFeeMinor,
        'currency': currency,
        'status': status.name,
        'transporterId': transporterId,
        'requestedAt': requestedAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'pickedUpAt': pickedUpAt?.toIso8601String(),
        'inTransitAt': inTransitAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, orderId, pickupAddress, dropoffAddress, cargoSummary,
        weightKg, offeredFeeMinor, currency, status, transporterId,
        requestedAt, acceptedAt, pickedUpAt, inTransitAt,
        deliveredAt, cancelledAt,
      ];
}
