class DriverShiftRecord {
  final String id;
  final String driverId;
  final String driverName;
  final String branchId;
  final String branchName;
  final String? assignedVehicleId;
  final String? assignedVehicleReg;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double drivingHours;
  final double restHours;
  final int completedTripsCount;
  final String status; // 'active', 'completed', 'on_break'
  final String notes;

  const DriverShiftRecord({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.branchId,
    required this.branchName,
    this.assignedVehicleId,
    this.assignedVehicleReg,
    required this.checkInTime,
    this.checkOutTime,
    this.drivingHours = 0.0,
    this.restHours = 0.0,
    this.completedTripsCount = 0,
    this.status = 'active',
    this.notes = '',
  });

  bool get isActive => status == 'active';
  bool get isOnBreak => status == 'on_break';
  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'branchId': branchId,
      'branchName': branchName,
      if (assignedVehicleId != null) 'assignedVehicleId': assignedVehicleId,
      if (assignedVehicleReg != null) 'assignedVehicleReg': assignedVehicleReg,
      'checkInTime': checkInTime.toIso8601String(),
      if (checkOutTime != null) 'checkOutTime': checkOutTime!.toIso8601String(),
      'drivingHours': drivingHours,
      'restHours': restHours,
      'completedTripsCount': completedTripsCount,
      'status': status,
      'notes': notes,
    };
  }

  factory DriverShiftRecord.fromMap(String id, Map<String, dynamic> data) {
    return DriverShiftRecord(
      id: id,
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? '',
      branchId: data['branchId']?.toString() ?? '',
      branchName: data['branchName']?.toString() ?? '',
      assignedVehicleId: data['assignedVehicleId']?.toString(),
      assignedVehicleReg: data['assignedVehicleReg']?.toString(),
      checkInTime: DateTime.tryParse(data['checkInTime']?.toString() ?? '') ??
          DateTime.now(),
      checkOutTime: data['checkOutTime'] != null
          ? DateTime.tryParse(data['checkOutTime'].toString())
          : null,
      drivingHours: (data['drivingHours'] as num?)?.toDouble() ?? 0.0,
      restHours: (data['restHours'] as num?)?.toDouble() ?? 0.0,
      completedTripsCount: (data['completedTripsCount'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'active',
      notes: data['notes']?.toString() ?? '',
    );
  }
}
