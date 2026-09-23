class TransporterProfile {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final bool isAvailable;
  final String vehicleType;
  final String vehicleRegistration;
  final double? vehicleCapacity;
  final String vehicleCapacityUnit;
  final String vehicleDescription;

  const TransporterProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.isAvailable,
    required this.vehicleType,
    required this.vehicleRegistration,
    this.vehicleCapacity,
    this.vehicleCapacityUnit = 'kg',
    this.vehicleDescription = '',
  });

  factory TransporterProfile.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return TransporterProfile(
      id: id,
      name: (data['displayName'] ?? data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      photoUrl: data['photoUrl']?.toString(),
      isAvailable: data['availabilityStatus'] != 'unavailable',
      vehicleType: (data['vehicleType'] ?? '').toString(),
      vehicleRegistration: (data['vehicleRegistration'] ?? '').toString(),
      vehicleCapacity: (data['vehicleCapacity'] as num?)?.toDouble(),
      vehicleCapacityUnit: (data['vehicleCapacityUnit'] ?? 'kg').toString(),
      vehicleDescription: (data['vehicleDescription'] ?? '').toString(),
    );
  }
}
