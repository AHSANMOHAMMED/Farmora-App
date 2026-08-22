import 'package:equatable/equatable.dart';
import 'user_role.dart';

class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String district;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.city = '',
    this.district = '',
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        district: json['district'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'district': district,
      };

  @override
  List<Object?> get props => [latitude, longitude, address, city, district];
}

class AppUser extends Equatable {
  final String id;
  final Role role;
  final String displayName;
  final String phone;
  final String email;
  final String photoUrl;
  final String languageCode;
  final String address;
  final GeoLocation? location;
  final bool isVerified;
  final bool isSuspended;
  final bool isOnboardingComplete;
  // Transport provider fields
  final String? vehicleType;
  final String? vehicleRegistration;
  final String? capacityKg;
  final String? verificationDocUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.role,
    this.displayName = '',
    this.phone = '',
    this.email = '',
    this.photoUrl = '',
    this.languageCode = 'en',
    this.address = '',
    this.location,
    this.isVerified = false,
    this.isSuspended = false,
    this.isOnboardingComplete = false,
    this.vehicleType,
    this.vehicleRegistration,
    this.capacityKg,
    this.verificationDocUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: Role.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => Role.buyer,
        ),
        displayName: json['displayName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
        languageCode: json['languageCode'] as String? ?? 'en',
        address: json['address'] as String? ?? '',
        location: json['location'] != null
            ? GeoLocation.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        isVerified: json['isVerified'] as bool? ?? false,
        isSuspended: json['isSuspended'] as bool? ?? false,
        isOnboardingComplete: json['isOnboardingComplete'] as bool? ?? false,
        vehicleType: json['vehicleType'] as String?,
        vehicleRegistration: json['vehicleRegistration'] as String?,
        capacityKg: json['capacityKg'] as String?,
        verificationDocUrl: json['verificationDocUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'displayName': displayName,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'languageCode': languageCode,
        'address': address,
        'location': location?.toJson(),
        'isVerified': isVerified,
        'isSuspended': isSuspended,
        'isOnboardingComplete': isOnboardingComplete,
        'vehicleType': vehicleType,
        'vehicleRegistration': vehicleRegistration,
        'capacityKg': capacityKg,
        'verificationDocUrl': verificationDocUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  AppUser copyWith({
    String? id,
    Role? role,
    String? displayName,
    String? phone,
    String? email,
    String? photoUrl,
    String? languageCode,
    String? address,
    GeoLocation? location,
    bool? isVerified,
    bool? isSuspended,
    bool? isOnboardingComplete,
    String? vehicleType,
    String? vehicleRegistration,
    String? capacityKg,
    String? verificationDocUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        languageCode: languageCode ?? this.languageCode,
        address: address ?? this.address,
        location: location ?? this.location,
        isVerified: isVerified ?? this.isVerified,
        isSuspended: isSuspended ?? this.isSuspended,
        isOnboardingComplete:
            isOnboardingComplete ?? this.isOnboardingComplete,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
        capacityKg: capacityKg ?? this.capacityKg,
        verificationDocUrl: verificationDocUrl ?? this.verificationDocUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, role, displayName, phone, email, photoUrl, languageCode,
        address, location, isVerified, isSuspended, isOnboardingComplete,
        vehicleType, vehicleRegistration, capacityKg, verificationDocUrl,
        createdAt, updatedAt,
      ];
}
