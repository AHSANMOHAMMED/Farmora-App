enum CollectionJobStatus {
  open,
  accepted,
  collected,
  inTransit,
  completed,
  cancelled;

  String get label => switch (this) {
        CollectionJobStatus.open => 'Open',
        CollectionJobStatus.accepted => 'Accepted',
        CollectionJobStatus.collected => 'Collected',
        CollectionJobStatus.inTransit => 'In transit',
        CollectionJobStatus.completed => 'Completed',
        CollectionJobStatus.cancelled => 'Cancelled',
      };

  String get apiValue => switch (this) {
        CollectionJobStatus.open => 'OPEN',
        CollectionJobStatus.accepted => 'ACCEPTED',
        CollectionJobStatus.collected => 'COLLECTED',
        CollectionJobStatus.inTransit => 'IN_TRANSIT',
        CollectionJobStatus.completed => 'COMPLETED',
        CollectionJobStatus.cancelled => 'CANCELLED',
      };

  bool get isActive =>
      this == CollectionJobStatus.accepted ||
      this == CollectionJobStatus.collected ||
      this == CollectionJobStatus.inTransit;

  static CollectionJobStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase().replaceAll(' ', '_');
    return CollectionJobStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => CollectionJobStatus.open,
    );
  }
}

/// One entry in a job's status history.
///
/// [label] is human readable, [at] is when the step happened and [isDone]
/// marks completed steps. Pending steps are rendered greyed out.
enum CollectionJobTimelineStep {
  created('Job created', null),
  accepted('Accepted', CollectionJobStatus.accepted),
  collected('Collected', CollectionJobStatus.collected),
  inTransit('In Transit', CollectionJobStatus.inTransit),
  delivered('Delivered', CollectionJobStatus.completed);

  const CollectionJobTimelineStep(this.label, this.status);

  final String label;

  /// The job status that completes this step, or null for [created].
  final CollectionJobStatus? status;
}

class CollectionJob {
  final String id;
  final String? producePostId;
  final String? orderId;
  final String farmerId;
  final String buyerId;
  final String? logisticsProviderId;
  final String produceName;
  final double quantity;
  final String unit;
  final String pickupLocation;
  final String deliveryLocation;
  final DateTime collectionDate;
  final String? notes;
  final String farmerName;
  final String farmerPhone;
  final String buyerName;
  final String buyerPhone;
  final CollectionJobStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? collectedAt;
  final DateTime? inTransitAt;
  final int? deliveryFeeMinor;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;

  const CollectionJob({
    required this.id,
    this.producePostId,
    this.orderId,
    required this.farmerId,
    required this.buyerId,
    this.logisticsProviderId,
    required this.produceName,
    required this.quantity,
    required this.unit,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.collectionDate,
    this.notes,
    required this.farmerName,
    required this.farmerPhone,
    required this.buyerName,
    required this.buyerPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.collectedAt,
    this.inTransitAt,
    this.deliveryFeeMinor,
    this.acceptedAt,
    this.cancelledAt,
  });

  String get quantityLabel {
    final value = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);
    return '$value $unit';
  }

  CollectionJob copyWith({
    String? logisticsProviderId,
    CollectionJobStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? collectedAt,
    DateTime? inTransitAt,
    int? deliveryFeeMinor,
    DateTime? acceptedAt,
    DateTime? cancelledAt,
  }) {
    return CollectionJob(
      id: id,
      producePostId: producePostId,
      orderId: orderId,
      farmerId: farmerId,
      buyerId: buyerId,
      logisticsProviderId: logisticsProviderId ?? this.logisticsProviderId,
      produceName: produceName,
      quantity: quantity,
      unit: unit,
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      collectionDate: collectionDate,
      notes: notes,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveryFeeMinor: deliveryFeeMinor ?? this.deliveryFeeMinor,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'producePostId': producePostId,
        'orderId': orderId,
        'farmerId': farmerId,
        'buyerId': buyerId,
        'logisticsProviderId': logisticsProviderId,
        'produceName': produceName,
        'quantity': quantity,
        'unit': unit,
        'pickupLocation': pickupLocation,
        'deliveryLocation': deliveryLocation,
        'collectionDate': collectionDate.toIso8601String(),
        'notes': notes,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'status': status.apiValue,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'collectedAt': collectedAt?.toIso8601String(),
        'inTransitAt': inTransitAt?.toIso8601String(),
        'deliveryFeeMinor': deliveryFeeMinor,
        'acceptedAt': acceptedAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
      };

  factory CollectionJob.fromMap(Map<String, Object?> map) {
    DateTime readDate(String key) =>
        DateTime.tryParse(map[key]?.toString() ?? '') ?? DateTime.now();

    return CollectionJob(
      id: map['id']?.toString() ?? '',
      producePostId: map['producePostId']?.toString(),
      orderId: map['orderId']?.toString(),
      farmerId: map['farmerId']?.toString() ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      logisticsProviderId: map['logisticsProviderId']?.toString(),
      produceName: map['produceName']?.toString() ?? 'Unknown produce',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? 'kg',
      pickupLocation: map['pickupLocation']?.toString() ?? 'Not provided',
      deliveryLocation: map['deliveryLocation']?.toString() ?? 'Not provided',
      collectionDate: readDate('collectionDate'),
      notes: map['notes']?.toString(),
      farmerName: map['farmerName']?.toString() ?? 'Farmer',
      farmerPhone: map['farmerPhone']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? 'Buyer',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      status: CollectionJobStatus.fromValue(map['status']?.toString()),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.tryParse(map['completedAt'].toString()),
      collectedAt: map['collectedAt'] == null
          ? null
          : DateTime.tryParse(map['collectedAt'].toString()),
      inTransitAt: map['inTransitAt'] == null
          ? null
          : DateTime.tryParse(map['inTransitAt'].toString()),
      deliveryFeeMinor: (map['deliveryFeeMinor'] as num?)?.toInt(),
      acceptedAt: map['acceptedAt'] == null
          ? null
          : DateTime.tryParse(map['acceptedAt'].toString()),
      cancelledAt: map['cancelledAt'] == null
          ? null
          : DateTime.tryParse(map['cancelledAt'].toString()),
    );
  }

  /// Ordered status history with timestamps for the job timeline.
  List<({CollectionJobTimelineStep step, DateTime? at})> get timeline {
    DateTime? at(CollectionJobTimelineStep step) => switch (step) {
          CollectionJobTimelineStep.created => createdAt,
          CollectionJobTimelineStep.accepted => acceptedAt ??
              (status == CollectionJobStatus.accepted || status.isActive
                  ? updatedAt
                  : null),
          CollectionJobTimelineStep.collected => collectedAt,
          CollectionJobTimelineStep.inTransit => inTransitAt,
          CollectionJobTimelineStep.delivered => completedAt,
        };

    return [
      for (final step in CollectionJobTimelineStep.values)
        (step: step, at: at(step)),
    ];
  }
}
