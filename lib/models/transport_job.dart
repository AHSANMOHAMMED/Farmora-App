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
  });

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

  /// Deserialize from Firestore Map
  factory TransportJob.fromMap(String id, Map<String, dynamic> data) {
    final status = (data['status'] ?? (data['accepted'] == true ? 'accepted' : 'requested')).toString();
    return TransportJob(
      id: id,
      title: data['title'] ?? '',
      route: data['route'] ?? '',
      detail: data['detail'] ?? '',
      fee: data['fee'] ?? '',
      accepted: data['accepted'] ?? status != 'requested',
      status: status,
      orderId: data['orderId'] as String?,
      transporterId: data['transporterId'] as String?,
      pickup: data['pickup'] as String?,
      dropoff: data['dropoff'] as String?,
      buyerId: data['buyerId'] as String?,
      farmerId: data['farmerId'] as String?,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
      district: (data['district'] ?? data['serviceDistrict'])?.toString(),
      capacityKg: (data['capacityKg'] as num?)?.toInt(),
      weightKg: (data['weightKg'] as num?)?.toInt() ??
          (data['capacityKg'] as num?)?.toInt(),
      courierLat: firebaseDouble(data['courierLat']),
      courierLng: firebaseDouble(data['courierLng']),
      locationUpdatedAt: firebaseDate(data['locationUpdatedAt']),
      pickupLat: firebaseDouble(data['pickupLat']),
      pickupLng: firebaseDouble(data['pickupLng']),
      dropoffLat: firebaseDouble(data['dropoffLat']),
      dropoffLng: firebaseDouble(data['dropoffLng']),
    );
  }
}
