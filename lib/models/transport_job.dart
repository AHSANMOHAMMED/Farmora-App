class TransportJob {
  final String id;
  final String title;
  final String route;
  final String detail;
  final String fee;
  final bool accepted;

  const TransportJob({
    required this.id,
    required this.title,
    required this.route,
    required this.detail,
    required this.fee,
    this.accepted = false,
  });

  TransportJob copyWith({
    String? id,
    String? title,
    String? route,
    String? detail,
    String? fee,
    bool? accepted,
  }) {
    return TransportJob(
      id: id ?? this.id,
      title: title ?? this.title,
      route: route ?? this.route,
      detail: detail ?? this.detail,
      fee: fee ?? this.fee,
      accepted: accepted ?? this.accepted,
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
    );
  }
}
