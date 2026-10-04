class FleetDriverInfo {
  final String id;
  final String transporterId;
  final String name;
  final String phone;
  final String licenseNumber;
  final String licenseClass;
  final String status; // 'available', 'on_trip', 'off_duty'
  final String? assignedVehicleId;
  final String? assignedVehicleReg;
  final String? stationedBranchId;
  final String? stationedBranchName;
  final double? currentLat;
  final double? currentLng;
  final double rating;
  final DateTime? updatedAt;

  const FleetDriverInfo({
    required this.id,
    required this.transporterId,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    this.licenseClass = 'Heavy Vehicle (Class C/C1)',
    this.status = 'available',
    this.assignedVehicleId,
    this.assignedVehicleReg,
    this.stationedBranchId,
    this.stationedBranchName,
    this.currentLat,
    this.currentLng,
    this.rating = 4.8,
    this.updatedAt,
  });

  bool get isAvailable => status == 'available';
  bool get isOnTrip => status == 'on_trip';
  bool get isOffDuty => status == 'off_duty';
  String get branchName => stationedBranchName ?? 'Main Depot';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporterId': transporterId,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'licenseClass': licenseClass,
      'status': status,
      if (assignedVehicleId != null) 'assignedVehicleId': assignedVehicleId,
      if (assignedVehicleReg != null) 'assignedVehicleReg': assignedVehicleReg,
      if (stationedBranchId != null) 'stationedBranchId': stationedBranchId,
      if (stationedBranchName != null) 'stationedBranchName': stationedBranchName,
      if (currentLat != null) 'currentLat': currentLat,
      if (currentLng != null) 'currentLng': currentLng,
      'rating': rating,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FleetDriverInfo.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedUpdated;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
    }
    return FleetDriverInfo(
      id: id,
      transporterId: (data['transporterId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      licenseNumber: (data['licenseNumber'] ?? '').toString(),
      licenseClass: (data['licenseClass'] ?? 'Heavy Vehicle (Class C/C1)').toString(),
      status: (data['status'] ?? 'available').toString(),
      assignedVehicleId: data['assignedVehicleId']?.toString(),
      assignedVehicleReg: data['assignedVehicleReg']?.toString(),
      stationedBranchId: data['stationedBranchId']?.toString(),
      stationedBranchName: data['stationedBranchName']?.toString(),
      currentLat: (data['currentLat'] as num?)?.toDouble(),
      currentLng: (data['currentLng'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      updatedAt: parsedUpdated,
    );
  }

  FleetDriverInfo copyWith({
    String? id,
    String? transporterId,
    String? name,
    String? phone,
    String? licenseNumber,
    String? licenseClass,
    String? status,
    String? assignedVehicleId,
    String? assignedVehicleReg,
    String? stationedBranchId,
    String? stationedBranchName,
    double? currentLat,
    double? currentLng,
    double? rating,
    DateTime? updatedAt,
  }) {
    return FleetDriverInfo(
      id: id ?? this.id,
      transporterId: transporterId ?? this.transporterId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseClass: licenseClass ?? this.licenseClass,
      status: status ?? this.status,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      assignedVehicleReg: assignedVehicleReg ?? this.assignedVehicleReg,
      stationedBranchId: stationedBranchId ?? this.stationedBranchId,
      stationedBranchName: stationedBranchName ?? this.stationedBranchName,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      rating: rating ?? this.rating,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
