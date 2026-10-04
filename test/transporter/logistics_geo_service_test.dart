import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:farmora/features/transporter/data/logistics_geo_service.dart';

void main() {
  group('LogisticsGeoService', () {
    test('calculates Haversine distance between Dambulla and Pettah accurately', () {
      final dambulla = LogisticsGeoService.agroMarketHubs['dambulla']!;
      final pettah = LogisticsGeoService.agroMarketHubs['pettah']!;

      final distanceKm = LogisticsGeoService.calculateDistanceKm(
        dambulla.latitude,
        dambulla.longitude,
        pettah.latitude,
        pettah.longitude,
      );

      // Great circle distance between Dambulla and Colombo is roughly 130-140 km
      expect(distanceKm, greaterThan(125.0));
      expect(distanceKm, lessThan(150.0));

      final estimatedRoadKm = LogisticsGeoService.estimateRoadDistanceKm(dambulla, pettah);
      expect(estimatedRoadKm, greaterThan(distanceKm));
    });

    test('calculates transit duration based on cargo payload weight', () {
      final lightTripHours = LogisticsGeoService.estimateTransitHours(
        distanceKm: 180.0,
        cargoWeightKg: 1500.0,
      );
      final heavyTripHours = LogisticsGeoService.estimateTransitHours(
        distanceKm: 180.0,
        cargoWeightKg: 8000.0,
      );

      expect(heavyTripHours, greaterThan(lightTripHours));
    });

    test('validates geofence proximity detection within depot bounds', () {
      const dambullaCenter = LatLng(7.8742, 80.6511);
      const closeLocation = LatLng(7.8750, 80.6515); // ~100m away
      const farLocation = LatLng(7.9500, 80.7000); // Several km away

      expect(
        LogisticsGeoService.isWithinGeofence(
          vehiclePos: closeLocation,
          hubPos: dambullaCenter,
          radiusMeters: 500.0,
        ),
        isTrue,
      );

      expect(
        LogisticsGeoService.isWithinGeofence(
          vehiclePos: farLocation,
          hubPos: dambullaCenter,
          radiusMeters: 500.0,
        ),
        isFalse,
      );
    });
  });
}
