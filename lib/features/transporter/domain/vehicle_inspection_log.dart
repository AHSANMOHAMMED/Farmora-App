class VehicleInspectionLog {
  final String id;
  final String vehicleId;
  final String vehicleReg;
  final String inspectorId;
  final String inspectorName;
  final DateTime inspectionDate;
  final bool tireConditionPassed;
  final bool brakesPassed;
  final bool engineOilPassed;
  final bool reeferCoolingPassed;
  final bool lightingPassed;
  final bool emergencyKitPresent;
  final bool passedAllChecks;
  final String notes;

  const VehicleInspectionLog({
    required this.id,
    required this.vehicleId,
    required this.vehicleReg,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.tireConditionPassed,
    required this.brakesPassed,
    required this.engineOilPassed,
    this.reeferCoolingPassed = true,
    required this.lightingPassed,
    required this.emergencyKitPresent,
    required this.passedAllChecks,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleReg': vehicleReg,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'inspectionDate': inspectionDate.toIso8601String(),
      'tireConditionPassed': tireConditionPassed,
      'brakesPassed': brakesPassed,
      'engineOilPassed': engineOilPassed,
      'reeferCoolingPassed': reeferCoolingPassed,
      'lightingPassed': lightingPassed,
      'emergencyKitPresent': emergencyKitPresent,
      'passedAllChecks': passedAllChecks,
      'notes': notes,
    };
  }

  factory VehicleInspectionLog.fromMap(String id, Map<String, dynamic> data) {
    return VehicleInspectionLog(
      id: id,
      vehicleId: data['vehicleId']?.toString() ?? '',
      vehicleReg: data['vehicleReg']?.toString() ?? '',
      inspectorId: data['inspectorId']?.toString() ?? '',
      inspectorName: data['inspectorName']?.toString() ?? 'Fleet Inspector',
      inspectionDate: DateTime.tryParse(data['inspectionDate']?.toString() ?? '') ??
          DateTime.now(),
      tireConditionPassed: data['tireConditionPassed'] != false,
      brakesPassed: data['brakesPassed'] != false,
      engineOilPassed: data['engineOilPassed'] != false,
      reeferCoolingPassed: data['reeferCoolingPassed'] != false,
      lightingPassed: data['lightingPassed'] != false,
      emergencyKitPresent: data['emergencyKitPresent'] != false,
      passedAllChecks: data['passedAllChecks'] != false,
      notes: data['notes']?.toString() ?? '',
    );
  }
}
