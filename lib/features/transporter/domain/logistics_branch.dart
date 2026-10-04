class LogisticsBranch {
  final String id;
  final String transporterId;
  final String name;
  final String district;
  final String address;
  final double latitude;
  final double longitude;
  final String managerName;
  final String managerPhone;
  final bool hasColdStorage;
  final double storageCapacityTons;
  final int vehicleCount;
  final int driverCount;
  final DateTime? updatedAt;

  const LogisticsBranch({
    required this.id,
    required this.transporterId,
    required this.name,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.managerName,
    required this.managerPhone,
    this.hasColdStorage = false,
    this.storageCapacityTons = 50.0,
    this.vehicleCount = 0,
    this.driverCount = 0,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporterId': transporterId,
      'name': name,
      'district': district,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'hasColdStorage': hasColdStorage,
      'storageCapacityTons': storageCapacityTons,
      'vehicleCount': vehicleCount,
      'driverCount': driverCount,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LogisticsBranch.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedUpdated;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
    }
    return LogisticsBranch(
      id: id,
      transporterId: (data['transporterId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      district: (data['district'] ?? 'Colombo').toString(),
      address: (data['address'] ?? '').toString(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 79.8612,
      managerName: (data['managerName'] ?? '').toString(),
      managerPhone: (data['managerPhone'] ?? '').toString(),
      hasColdStorage: data['hasColdStorage'] == true,
      storageCapacityTons: (data['storageCapacityTons'] as num?)?.toDouble() ?? 50.0,
      vehicleCount: (data['vehicleCount'] as num?)?.toInt() ?? 0,
      driverCount: (data['driverCount'] as num?)?.toInt() ?? 0,
      updatedAt: parsedUpdated,
    );
  }

  LogisticsBranch copyWith({
    String? id,
    String? transporterId,
    String? name,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? managerName,
    String? managerPhone,
    bool? hasColdStorage,
    double? storageCapacityTons,
    int? vehicleCount,
    int? driverCount,
    DateTime? updatedAt,
  }) {
    return LogisticsBranch(
      id: id ?? this.id,
      transporterId: transporterId ?? this.transporterId,
      name: name ?? this.name,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      hasColdStorage: hasColdStorage ?? this.hasColdStorage,
      storageCapacityTons: storageCapacityTons ?? this.storageCapacityTons,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      driverCount: driverCount ?? this.driverCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
