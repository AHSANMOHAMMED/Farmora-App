import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/core/utils/geo.dart';

void main() {
  group('distanceKm (haversine)', () {
    test('zero distance for identical points', () {
      final d = distanceKm(
        lat1: 7.2906,
        lng1: 80.6337,
        lat2: 7.2906,
        lng2: 80.6337,
      );
      expect(d, closeTo(0, 0.0001));
    });

    test('Colombo to Kandy is roughly 100 km', () {
      // Colombo: 6.9271, 79.8612 — Kandy: 7.2906, 80.6337
      final d = distanceKm(
        lat1: 6.9271,
        lng1: 79.8612,
        lat2: 7.2906,
        lng2: 80.6337,
      );
      expect(d, greaterThan(85));
      expect(d, lessThan(115));
    });

    test('symmetric', () {
      final a = distanceKm(
          lat1: 6.9271, lng1: 79.8612, lat2: 9.6615, lng2: 80.0255);
      final b = distanceKm(
          lat1: 9.6615, lng1: 80.0255, lat2: 6.9271, lng2: 79.8612);
      expect(a, closeTo(b, 0.001));
    });

    test('handles antimeridian-spanning pairs without crashing', () {
      final d = distanceKm(lat1: 0, lng1: 179.5, lat2: 0, lng2: -179.5);
      expect(d, greaterThan(0));
      expect(d, lessThan(200));
    });
  });

  group('distanceLabel', () {
    test('meters under 1 km', () {
      expect(distanceLabel(0.85), '850 m');
    });

    test('one decimal under 10 km', () {
      expect(distanceLabel(7.44), '7.4 km');
    });

    test('rounded over 10 km', () {
      expect(distanceLabel(29.6), '30 km');
    });
  });

  group('GeoPoint', () {
    test('parses lat/lng map', () {
      final p = GeoPoint.fromMap({'lat': 7.1, 'lng': 80.2});
      expect(p.latitude, 7.1);
      expect(p.longitude, 80.2);
    });

    test('parses latitude/longitude aliases', () {
      final p = GeoPoint.fromMap({'latitude': 1.0, 'longitude': 2.0});
      expect(p.latitude, 1.0);
      expect(p.longitude, 2.0);
    });

    test('invalid map yields zero point', () {
      final p = GeoPoint.fromMap(null);
      expect(p.isValid, isFalse);
    });

    test('validates ranges', () {
      expect(
        const GeoPoint(latitude: 91, longitude: 0).isValid,
        isFalse,
      );
      expect(
        const GeoPoint(latitude: 7, longitude: 181).isValid,
        isFalse,
      );
      expect(
        const GeoPoint(latitude: 7, longitude: 80).isValid,
        isTrue,
      );
    });

    test('round-trips through map', () {
      const p = GeoPoint(latitude: 7.5, longitude: 80.5);
      final q = GeoPoint.fromMap(p.toMap());
      expect(q, p);
    });
  });
}
