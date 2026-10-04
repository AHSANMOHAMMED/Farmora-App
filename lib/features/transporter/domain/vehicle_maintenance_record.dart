class VehicleMaintenanceRecord {
  final String id;
  final String vehicleId;
  final String vehicleReg;
  final String serviceType; // 'oil_change', 'tire_rotation', 'brake_service', 'engine_tuneup', 'reefer_maintenance', 'general_inspection'
  final String garageName;
  final double costLkr;
  final DateTime serviceDate;
  final double odometerKm;
  final DateTime? nextServiceDueDate;
  final double? nextServiceOdometerKm;
  final String notes;
  final bool isCompleted;

  const VehicleMaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleReg,
    required this.serviceType,
    required this.garageName,
    required this.costLkr,
    required this.serviceDate,
    required this.odometerKm,
    this.nextServiceDueDate,
    this.nextServiceOdometerKm,
    this.notes = '',
    this.isCompleted = true,
  });

  String get serviceTypeDisplayName => switch (serviceType) {
        'oil_change' => 'Engine Oil & Filter Change',
        'tire_rotation' => 'Tire Rotation & Wheel Alignment',
        'brake_service' => 'Brake Pad & Fluid Replacement',
        'engine_tuneup' => 'Engine Diagnostics & Tune-up',
        'reefer_maintenance' => 'Reefer Cooling Unit Servicing',
        'general_inspection' => 'Full Fleet Fitness Inspection',
        _ => serviceType,
      };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleReg': vehicleReg,
      'serviceType': serviceType,
      'garageName': garageName,
      'costLkr': costLkr,
      'serviceDate': serviceDate.toIso8601String(),
      'odometerKm': odometerKm,
      if (nextServiceDueDate != null)
        'nextServiceDueDate': nextServiceDueDate!.toIso8601String(),
      if (nextServiceOdometerKm != null)
        'nextServiceOdometerKm': nextServiceOdometerKm,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory VehicleMaintenanceRecord.fromMap(String id, Map<String, dynamic> data) {
    return VehicleMaintenanceRecord(
      id: id,
      vehicleId: data['vehicleId']?.toString() ?? '',
      vehicleReg: data['vehicleReg']?.toString() ?? '',
      serviceType: data['serviceType']?.toString() ?? 'general_inspection',
      garageName: data['garageName']?.toString() ?? 'Authorized Workshop',
      costLkr: (data['costLkr'] as num?)?.toDouble() ?? 0.0,
      serviceDate: DateTime.tryParse(data['serviceDate']?.toString() ?? '') ??
          DateTime.now(),
      odometerKm: (data['odometerKm'] as num?)?.toDouble() ?? 0.0,
      nextServiceDueDate: data['nextServiceDueDate'] != null
          ? DateTime.tryParse(data['nextServiceDueDate'].toString())
          : null,
      nextServiceOdometerKm:
          (data['nextServiceOdometerKm'] as num?)?.toDouble(),
      notes: data['notes']?.toString() ?? '',
      isCompleted: data['isCompleted'] != false,
    );
  }
}
