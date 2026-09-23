import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/services/delivery_location_service.dart';

void main() {
  group('DeliveryLocationService', () {
    test('starts idle and not sharing', () {
      final service = DeliveryLocationService.instance;
      service.stopAll();
      expect(service.isSharing, isFalse);
      expect(service.activeJobId, isNull);
    });

    test('stopSharing with wrong jobId is a no-op', () {
      final service = DeliveryLocationService.instance;
      service.stopAll();
      service.stopSharing(jobId: 'other-job');
      expect(service.isSharing, isFalse);
    });

    test('isLocationFresh true within 2 minutes', () {
      expect(
        DeliveryLocationService.isLocationFresh(
          DateTime.now().subtract(const Duration(seconds: 30)),
        ),
        isTrue,
      );
    });

    test('isLocationFresh false beyond 2 minutes', () {
      expect(
        DeliveryLocationService.isLocationFresh(
          DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        isFalse,
      );
    });

    test('isLocationFresh false for null timestamp', () {
      expect(DeliveryLocationService.isLocationFresh(null), isFalse);
    });

    test('onJobStatusChanged stops on delivered', () {
      final service = DeliveryLocationService.instance;
      service.stopAll();
      // Simulate an active session (bypassing permission prompts).
      service.debugStartForTest('job-1');
      service.onJobStatusChanged('job-1', 'delivered');
      expect(service.isSharing, isFalse);
    });

    test('onJobStatusChanged stops on cancelled', () {
      final service = DeliveryLocationService.instance;
      service.stopAll();
      service.debugStartForTest('job-2');
      service.onJobStatusChanged('job-2', 'cancelled');
      expect(service.isSharing, isFalse);
    });

    test('onJobStatusChanged keeps sharing on intermediate states', () {
      final service = DeliveryLocationService.instance;
      service.stopAll();
      service.debugStartForTest('job-3');
      service.onJobStatusChanged('job-3', 'pickedUp');
      expect(service.isSharing, isTrue);
      service.onJobStatusChanged('job-3', 'inTransit');
      expect(service.isSharing, isTrue);
      service.stopAll();
    });
  });

  group('distanceKmBetween', () {
    test('Colombo → Kandy in plausible range', () {
      final d = distanceKmBetween(6.9271, 79.8612, 7.2906, 80.6337);
      expect(d, greaterThan(85));
      expect(d, lessThan(115));
    });

    test('zero for same point', () {
      expect(distanceKmBetween(7.0, 80.0, 7.0, 80.0), closeTo(0, 0.0001));
    });
  });
}
