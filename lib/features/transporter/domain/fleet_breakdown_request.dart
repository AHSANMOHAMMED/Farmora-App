class FleetBreakdownRequest {
  final String id;
  final String vehicleId;
  final String vehicleReg;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double latitude;
  final double longitude;
  final String locationDescription;
  final String failureType; // 'engine', 'flat_tire', 'transmission', 'cooling_failure', 'accident'
  final String severity; // 'minor', 'towing_required', 'critical_cargo_rescue'
  final String status; // 'reported', 'assigned', 'relief_en_route', 'resolved'
  final String? reliefVehicleId;
  final String? reliefVehicleReg;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String notes;

  const FleetBreakdownRequest({
    required this.id,
    required this.vehicleId,
    required this.vehicleReg,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.latitude,
    required this.longitude,
    required this.locationDescription,
    required this.failureType,
    this.severity = 'towing_required',
    this.status = 'reported',
    this.reliefVehicleId,
    this.reliefVehicleReg,
    required this.reportedAt,
    this.resolvedAt,
    this.notes = '',
  });

  bool get isCritical => severity == 'critical_cargo_rescue';
  bool get isResolved => status == 'resolved';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleReg': vehicleReg,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'latitude': latitude,
      'longitude': longitude,
      'locationDescription': locationDescription,
      'failureType': failureType,
      'severity': severity,
      'status': status,
      if (reliefVehicleId != null) 'reliefVehicleId': reliefVehicleId,
      if (reliefVehicleReg != null) 'reliefVehicleReg': reliefVehicleReg,
      'reportedAt': reportedAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      'notes': notes,
    };
  }

  factory FleetBreakdownRequest.fromMap(String id, Map<String, dynamic> data) {
    return FleetBreakdownRequest(
      id: id,
      vehicleId: data['vehicleId']?.toString() ?? '',
      vehicleReg: data['vehicleReg']?.toString() ?? '',
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? '',
      driverPhone: data['driverPhone']?.toString() ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      locationDescription: data['locationDescription']?.toString() ?? 'On highway',
      failureType: data['failureType']?.toString() ?? 'engine',
      severity: data['severity']?.toString() ?? 'towing_required',
      status: data['status']?.toString() ?? 'reported',
      reliefVehicleId: data['reliefVehicleId']?.toString(),
      reliefVehicleReg: data['reliefVehicleReg']?.toString(),
      reportedAt: DateTime.tryParse(data['reportedAt']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.tryParse(data['resolvedAt'].toString())
          : null,
      notes: data['notes']?.toString() ?? '',
    );
  }
}
