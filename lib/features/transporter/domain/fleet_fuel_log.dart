class FleetFuelLog {
  final String id;
  final String vehicleId;
  final String vehicleReg;
  final String driverId;
  final String driverName;
  final DateTime fueledAt;
  final double litersFilled;
  final double costPerLiterLkr;
  final double totalCostLkr;
  final String fuelStationName; // 'Ceypetco', 'LIOC', 'Sinopec', 'Private Depot'
  final double odometerKm;
  final double? previousOdometerKm;

  const FleetFuelLog({
    required this.id,
    required this.vehicleId,
    required this.vehicleReg,
    required this.driverId,
    required this.driverName,
    required this.fueledAt,
    required this.litersFilled,
    required this.costPerLiterLkr,
    required this.totalCostLkr,
    required this.fuelStationName,
    required this.odometerKm,
    this.previousOdometerKm,
  });

  /// Computed fuel economy in km/L if previous odometer is recorded.
  double? get fuelEfficiencyKmL {
    if (previousOdometerKm == null || litersFilled <= 0) return null;
    final dist = odometerKm - previousOdometerKm!;
    if (dist <= 0) return null;
    return dist / litersFilled;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleReg': vehicleReg,
      'driverId': driverId,
      'driverName': driverName,
      'fueledAt': fueledAt.toIso8601String(),
      'litersFilled': litersFilled,
      'costPerLiterLkr': costPerLiterLkr,
      'totalCostLkr': totalCostLkr,
      'fuelStationName': fuelStationName,
      'odometerKm': odometerKm,
      if (previousOdometerKm != null) 'previousOdometerKm': previousOdometerKm,
    };
  }

  factory FleetFuelLog.fromMap(String id, Map<String, dynamic> data) {
    return FleetFuelLog(
      id: id,
      vehicleId: data['vehicleId']?.toString() ?? '',
      vehicleReg: data['vehicleReg']?.toString() ?? '',
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? '',
      fueledAt: DateTime.tryParse(data['fueledAt']?.toString() ?? '') ??
          DateTime.now(),
      litersFilled: (data['litersFilled'] as num?)?.toDouble() ?? 0.0,
      costPerLiterLkr: (data['costPerLiterLkr'] as num?)?.toDouble() ?? 350.0,
      totalCostLkr: (data['totalCostLkr'] as num?)?.toDouble() ?? 0.0,
      fuelStationName: data['fuelStationName']?.toString() ?? 'Ceypetco Depot',
      odometerKm: (data['odometerKm'] as num?)?.toDouble() ?? 0.0,
      previousOdometerKm: (data['previousOdometerKm'] as num?)?.toDouble(),
    );
  }
}
