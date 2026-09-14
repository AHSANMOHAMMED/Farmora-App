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
  final DateTime? updatedAt;

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
    this.updatedAt,
  });

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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
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
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
    );
  }
}
