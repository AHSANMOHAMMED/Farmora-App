import 'dart:math' as math;

/// A lightweight geographic coordinate used across live-location features.
class GeoPoint {
  final double latitude;
  final double longitude;

  /// False when constructed from missing/unparseable data.
  final bool resolved;

  const GeoPoint(
      {required this.latitude, required this.longitude, this.resolved = true});

  const GeoPoint._unresolvedPoint()
      : latitude = 0,
        longitude = 0,
        resolved = false;

  factory GeoPoint.fromMap(Map<String, dynamic>? data) {
    final lat = (data?['lat'] ?? data?['latitude']) as num?;
    final lng = (data?['lng'] ?? data?['longitude']) as num?;
    if (lat == null || lng == null) return const GeoPoint._unresolvedPoint();
    return GeoPoint(
        latitude: lat.toDouble(), longitude: lng.toDouble());
  }

  Map<String, dynamic> toMap() => {'lat': latitude, 'lng': longitude};

  bool get isValid =>
      resolved &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

/// Earth radius in kilometers (mean radius).
const double earthRadiusKm = 6371.0;

/// Great-circle distance between two coordinates using the haversine formula.
/// Returns kilometers. Returns 0 when either point is invalid.
double distanceKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  final phi1 = _degToRad(lat1);
  final phi2 = _degToRad(lat2);
  final dPhi = _degToRad(lat2 - lat1);
  final dLambda = _degToRad(lng2 - lng1);

  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Human-readable distance label, e.g. "850 m" or "12.4 km".
String distanceLabel(double km) {
  if (km < 1.0) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

double _degToRad(double deg) => deg * math.pi / 180.0;
