class LogisticsVehicle {
  final String id;
  final String transporterId;
  final String registrationNumber;
  final String vehicleType;
  final String modelName;
  final double capacityKg;
  final bool isRefrigerated;
  final String status; // 'available', 'on_trip', 'maintenance', 'idle'
  final String? stationedBranchId;
  final String? stationedBranchName;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final double? currentLat;
  final double? currentLng;
  final DateTime? updatedAt;

  const LogisticsVehicle({
    required this.id,
    required this.transporterId,
    required this.registrationNumber,
    required this.vehicleType,
    required this.modelName,
    required this.capacityKg,
    this.isRefrigerated = false,
    this.status = 'available',
    this.stationedBranchId,
    this.stationedBranchName,
    this.assignedDriverId,
    this.assignedDriverName,
    this.currentLat,
    this.currentLng,
    this.updatedAt,
  });

  bool get isAvailable => status == 'available';
  bool get isOnTrip => status == 'on_trip';
  bool get isUnderMaintenance => status == 'maintenance';
  double get capacityTons => capacityKg / 1000.0;
  String get branchName => stationedBranchName ?? 'Main Depot';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporterId': transporterId,
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'modelName': modelName,
      'capacityKg': capacityKg,
      'isRefrigerated': isRefrigerated,
      'status': status,
      if (stationedBranchId != null) 'stationedBranchId': stationedBranchId,
      if (stationedBranchName != null) 'stationedBranchName': stationedBranchName,
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
      if (assignedDriverName != null) 'assignedDriverName': assignedDriverName,
      if (currentLat != null) 'currentLat': currentLat,
      if (currentLng != null) 'currentLng': currentLng,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LogisticsVehicle.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedUpdated;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
    }
    return LogisticsVehicle(
      id: id,
      transporterId: (data['transporterId'] ?? '').toString(),
      registrationNumber: (data['registrationNumber'] ?? '').toString(),
      vehicleType: (data['vehicleType'] ?? 'mini_truck').toString(),
      modelName: (data['modelName'] ?? '').toString(),
      capacityKg: (data['capacityKg'] as num?)?.toDouble() ?? 1000.0,
      isRefrigerated: data['isRefrigerated'] == true,
      status: (data['status'] ?? 'available').toString(),
      stationedBranchId: data['stationedBranchId']?.toString(),
      stationedBranchName: data['stationedBranchName']?.toString(),
      assignedDriverId: data['assignedDriverId']?.toString(),
      assignedDriverName: data['assignedDriverName']?.toString(),
      currentLat: (data['currentLat'] as num?)?.toDouble(),
      currentLng: (data['currentLng'] as num?)?.toDouble(),
      updatedAt: parsedUpdated,
    );
  }

  LogisticsVehicle copyWith({
    String? id,
    String? transporterId,
    String? registrationNumber,
    String? vehicleType,
    String? modelName,
    double? capacityKg,
    bool? isRefrigerated,
    String? status,
    String? stationedBranchId,
    String? stationedBranchName,
    String? assignedDriverId,
    String? assignedDriverName,
    double? currentLat,
    double? currentLng,
    DateTime? updatedAt,
  }) {
    return LogisticsVehicle(
      id: id ?? this.id,
      transporterId: transporterId ?? this.transporterId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      modelName: modelName ?? this.modelName,
      capacityKg: capacityKg ?? this.capacityKg,
      isRefrigerated: isRefrigerated ?? this.isRefrigerated,
      status: status ?? this.status,
      stationedBranchId: stationedBranchId ?? this.stationedBranchId,
      stationedBranchName: stationedBranchName ?? this.stationedBranchName,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
