import '../core/utils/firebase_values.dart';

class TransportJob {
  final String id;
  final String title;
  final String route;
  final String detail;
  final String fee;
  final bool accepted;
  final String status;
  final String? orderId;
  final String? transporterId;
  final String? pickup;
  final String? dropoff;
  final String? buyerId;
  final String? farmerId;
  final DateTime? updatedAt;
  final String? district;
  final int? capacityKg;
  final int? weightKg;

  /// Live courier coordinates while the delivery is active.
  /// Cleared by the backend on delivery and on cancellation.
  final double? courierLat;
  final double? courierLng;
  final DateTime? locationUpdatedAt;

  /// Optional pickup/dropoff coordinates captured at order time.
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  /// Backend fee in minor units (`deliveryFeeMinor`, else `offeredFeeMinor`).
  final int? deliveryFeeMinor;
  final double? quantityValue;
  final String? unit;
  final String? productName;
  final String? farmerName;
  final String? buyerName;
  final String? orderNumber;

  /// Transporter the buyer asked for (targeted request, not yet accepted).
  final String? requestedTransporterId;
  final DateTime? createdAt;

  const TransportJob({
    required this.id,
    required this.title,
    required this.route,
    required this.detail,
    required this.fee,
    this.accepted = false,
    this.status = 'requested',
    this.orderId,
    this.transporterId,
    this.pickup,
    this.dropoff,
    this.buyerId,
    this.farmerId,
    this.updatedAt,
    this.district,
    this.capacityKg,
    this.weightKg,
    this.courierLat,
    this.courierLng,
    this.locationUpdatedAt,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.deliveryFeeMinor,
    this.quantityValue,
    this.unit,
    this.productName,
    this.farmerName,
    this.buyerName,
    this.orderNumber,
    this.requestedTransporterId,
    this.createdAt,
  });

  /// True while the job waits for a transporter.
  bool get isRequested => status == 'requested';

  bool get hasCourierLocation =>
      courierLat != null && courierLng != null;

  bool get hasRouteCoordinates =>
      pickupLat != null &&
      pickupLng != null &&
      dropoffLat != null &&
      dropoffLng != null;

  static const validTransitions = {
    'requested': ['accepted'],
    'accepted': ['pickedUp', 'cancelled'],
    'pickedUp': ['inTransit'],
    'inTransit': ['delivered'],
    'delivered': <String>[],
    'cancelled': <String>[],
  };

  List<String> get nextStatuses => validTransitions[status] ?? const [];
  bool get canTransition => nextStatuses.isNotEmpty;
  bool get isActive =>
      status == 'accepted' || status == 'pickedUp' || status == 'inTransit';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  TransportJob copyWith({
    String? id,
    String? title,
    String? route,
    String? detail,
    String? fee,
    bool? accepted,
    String? status,
    String? orderId,
    String? transporterId,
    String? pickup,
    String? dropoff,
    String? buyerId,
    String? farmerId,
    DateTime? updatedAt,
    String? district,
    int? capacityKg,
    int? weightKg,
    double? courierLat,
    double? courierLng,
    DateTime? locationUpdatedAt,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? deliveryFeeMinor,
    double? quantityValue,
    String? unit,
    String? productName,
    String? farmerName,
    String? buyerName,
    String? orderNumber,
    String? requestedTransporterId,
    DateTime? createdAt,
  }) {
    return TransportJob(
      id: id ?? this.id,
      title: title ?? this.title,
      route: route ?? this.route,
      detail: detail ?? this.detail,
      fee: fee ?? this.fee,
      accepted: accepted ?? this.accepted,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      transporterId: transporterId ?? this.transporterId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      updatedAt: updatedAt ?? this.updatedAt,
      district: district ?? this.district,
      capacityKg: capacityKg ?? this.capacityKg,
      weightKg: weightKg ?? this.weightKg,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      deliveryFeeMinor: deliveryFeeMinor ?? this.deliveryFeeMinor,
      quantityValue: quantityValue ?? this.quantityValue,
      unit: unit ?? this.unit,
      productName: productName ?? this.productName,
      farmerName: farmerName ?? this.farmerName,
      buyerName: buyerName ?? this.buyerName,
      orderNumber: orderNumber ?? this.orderNumber,
      requestedTransporterId:
          requestedTransporterId ?? this.requestedTransporterId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'route': route,
      'detail': detail,
      'fee': fee,
      'accepted': accepted || status != 'requested',
      'status': status,
      'orderId': orderId,
      'transporterId': transporterId,
      'pickup': pickup,
      'dropoff': dropoff,
      'buyerId': buyerId,
      'farmerId': farmerId,
      'district': district,
      'capacityKg': capacityKg,
      'weightKg': weightKg,
      if (courierLat != null) 'courierLat': courierLat,
      if (courierLng != null) 'courierLng': courierLng,
      if (locationUpdatedAt != null)
        'locationUpdatedAt': locationUpdatedAt!.toIso8601String(),
      if (pickupLat != null) 'pickupLat': pickupLat,
      if (pickupLng != null) 'pickupLng': pickupLng,
      if (dropoffLat != null) 'dropoffLat': dropoffLat,
      if (dropoffLng != null) 'dropoffLng': dropoffLng,
    };
  }

  /// Deserialize from Firestore Map. Tolerates the callable-written schema
  /// (`pickupAddress`/`dropoffAddress`, numeric fees, Timestamp dates) and
  /// the legacy string shape.
  factory TransportJob.fromMap(String id, Map<String, dynamic> data) {
    String? text(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value == null) continue;
        final str = value.toString().trim();
        if (str.isNotEmpty) return str;
      }
      return null;
    }

    final status = (data['status'] ??
            (data['accepted'] == true ? 'accepted' : 'requested'))
        .toString();
    final feeMinor = firebaseInt(data['deliveryFeeMinor']) ??
        firebaseInt(data['offeredFeeMinor']);
    final rawFee = data['fee'];
    final fee = rawFee is String && rawFee.trim().isNotEmpty
        ? rawFee
        : rawFee is num
            ? 'LKR ${rawFee.toStringAsFixed(2)}'
            : feeMinor != null
                ? 'LKR ${(feeMinor / 100).toStringAsFixed(2)}'
                : '';
    final productName = text(['productName', 'produceName']);
    final quantityValue = firebaseDouble(data['quantityValue']) ??
        (data['quantity'] is num ? (data['quantity'] as num).toDouble() : null);
    final capacityKg = firebaseInt(data['capacityKg']);
    return TransportJob(
      id: id,
      title: text(['title']) ?? productName ?? '',
      route: text(['route']) ?? '',
      detail: text(['detail', 'notes']) ?? '',
      fee: fee,
      accepted: data['accepted'] is bool
          ? data['accepted'] as bool
          : status != 'requested',
      status: status,
      orderId: text(['orderId']),
      transporterId: text(['transporterId']),
      pickup: text(['pickup', 'pickupAddress', 'pickupLocation']),
      dropoff: text(['dropoff', 'dropoffAddress', 'deliveryLocation']),
      buyerId: text(['buyerId']),
      farmerId: text(['farmerId']),
      updatedAt: firebaseDate(data['updatedAt']),
      district: text(['district', 'serviceDistrict']),
      capacityKg: capacityKg,
      weightKg: firebaseInt(data['weightKg']) ?? capacityKg,
      courierLat: firebaseDouble(data['courierLat']),
      courierLng: firebaseDouble(data['courierLng']),
      locationUpdatedAt: firebaseDate(data['locationUpdatedAt']),
      pickupLat: firebaseDouble(data['pickupLat']),
      pickupLng: firebaseDouble(data['pickupLng']),
      dropoffLat: firebaseDouble(data['dropoffLat']),
      dropoffLng: firebaseDouble(data['dropoffLng']),
      deliveryFeeMinor: feeMinor,
      quantityValue: quantityValue,
      unit: text(['unit']),
      productName: productName,
      farmerName: text(['farmerName']),
      buyerName: text(['buyerName']),
      orderNumber: text(['orderNumber']),
      requestedTransporterId: text(['requestedTransporterId']),
      createdAt: firebaseDate(data['createdAt']),
    );
  }
}
