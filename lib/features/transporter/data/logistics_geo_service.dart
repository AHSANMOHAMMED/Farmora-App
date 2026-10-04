import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LogisticsGeoService {
  /// Major Sri Lankan agricultural trade hub coordinates
  static const Map<String, LatLng> agroMarketHubs = {
    'dambulla': LatLng(7.8742, 80.6511), // Central dedicated economic center
    'pettah': LatLng(6.9366, 79.8530), // Colombo wholesale market
    'keppetipola': LatLng(6.8833, 80.8667), // Uva vegetable exchange center
    'nuwara_eliya': LatLng(6.9497, 80.7891), // Upcountry vegetable depot
    'norochcholai': LatLng(8.1333, 79.7333), // Coastal vegetable produce
    'thambuthegama': LatLng(8.1450, 80.2880), // North-Central grain & veg
    'jaffna': LatLng(9.6615, 80.0255), // Northern peninsula market
    'kandy': LatLng(7.2906, 80.6337), // Central hill hub
    'embilipitiya': LatLng(6.3400, 80.8500), // Southern banana & fruit depot
    'puttalam': LatLng(8.0333, 79.8333), // Salt & coastal transit
  };

  /// Road distance matrix (km) between principal logistics nodes in Sri Lanka
  static const Map<String, Map<String, double>> roadDistanceMatrix = {
    'dambulla': {
      'pettah': 165.0,
      'kandy': 72.0,
      'keppetipola': 140.0,
      'nuwara_eliya': 135.0,
      'jaffna': 235.0,
      'thambuthegama': 58.0,
      'puttalam': 108.0,
    },
    'pettah': {
      'dambulla': 165.0,
      'kandy': 115.0,
      'nuwara_eliya': 170.0,
      'jaffna': 395.0,
      'embilipitiya': 185.0,
      'puttalam': 130.0,
    },
    'kandy': {
      'dambulla': 72.0,
      'pettah': 115.0,
      'nuwara_eliya': 75.0,
      'keppetipola': 92.0,
      'jaffna': 310.0,
    },
    'nuwara_eliya': {
      'pettah': 170.0,
      'dambulla': 135.0,
      'kandy': 75.0,
      'keppetipola': 28.0,
    },
  };

  /// Haversine Great Circle distance in kilometers between two GPS points
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates estimated road distance (multiplying haversine by Sri Lankan terrain detour factor 1.25)
  static double estimateRoadDistanceKm(LatLng origin, LatLng destination) {
    final straightLine = calculateDistanceKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    // Road topology factor in Sri Lanka varies between 1.2 and 1.35
    return (straightLine * 1.28).clamp(5.0, 999.0);
  }

  /// Estimated trip transit duration in hours given road distance and cargo weight
  static double estimateTransitHours({
    required double distanceKm,
    required double cargoWeightKg,
  }) {
    // Average commercial vehicle speed in Sri Lanka: ~38 km/h for heavy, ~45 km/h for mini
    final avgSpeed = cargoWeightKg > 4000 ? 36.0 : 44.0;
    return distanceKm / avgSpeed;
  }

  /// Checks if a vehicle's GPS coordinates fall within a depot's geofence radius (meters)
  static bool isWithinGeofence({
    required LatLng vehiclePos,
    required LatLng hubPos,
    double radiusMeters = 500.0,
  }) {
    final distKm = calculateDistanceKm(
      vehiclePos.latitude,
      vehiclePos.longitude,
      hubPos.latitude,
      hubPos.longitude,
    );
    return (distKm * 1000.0) <= radiusMeters;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
