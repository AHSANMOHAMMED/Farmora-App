import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/transport_job.dart';

void main() {
  group('TransportJob live-location fields', () {
    test('parses courier coordinates from Firestore map', () {
      final job = TransportJob.fromMap('job1', {
        'title': 'Delivery for Tomatoes',
        'route': 'Farm → Buyer',
        'detail': '28 kg',
        'fee': 'LKR 350',
        'status': 'inTransit',
        'courierLat': 7.2906,
        'courierLng': 80.6337,
        'locationUpdatedAt': '2026-09-23T10:00:00.000',
      });
      expect(job.hasCourierLocation, isTrue);
      expect(job.courierLat, 7.2906);
      expect(job.courierLng, 80.6337);
      expect(job.locationUpdatedAt, isNotNull);
    });

    test('hasCourierLocation false when coordinates missing', () {
      final job = TransportJob.fromMap('job2', {
        'title': 'x',
        'route': 'y',
        'status': 'requested',
      });
      expect(job.hasCourierLocation, isFalse);
    });

    test('pickup/dropoff coordinates parsed', () {
      final job = TransportJob.fromMap('job3', {
        'pickupLat': 6.9,
        'pickupLng': 79.8,
        'dropoffLat': 7.2,
        'dropoffLng': 80.6,
      });
      expect(job.hasRouteCoordinates, isTrue);
      expect(job.pickupLat, 6.9);
      expect(job.dropoffLng, 80.6);
    });

    test('copyWith preserves and overrides courier location', () {
      const base = TransportJob(
        id: 'j',
        title: 't',
        route: 'r',
        detail: 'd',
        fee: 'f',
        courierLat: 1.0,
        courierLng: 2.0,
      );
      final moved = base.copyWith(courierLat: 3.0, courierLng: 4.0);
      expect(moved.courierLat, 3.0);
      expect(moved.courierLng, 4.0);
      // Keeping defaults works too.
      final same = base.copyWith(status: 'delivered');
      expect(same.hasCourierLocation, isTrue);
      expect(same.courierLat, 1.0);
    });

    test('toMap includes courier coordinates when present', () {
      const job = TransportJob(
        id: 'j',
        title: 't',
        route: 'r',
        detail: 'd',
        fee: 'f',
        courierLat: 1.5,
        courierLng: 2.5,
      );
      final map = job.toMap();
      expect(map['courierLat'], 1.5);
      expect(map['courierLng'], 2.5);
    });

    test('delivery state machine still enforced', () {
      expect(
        const TransportJob(id: 'a', title: 't', route: 'r', detail: 'd', fee: 'f', status: 'requested').nextStatuses,
        ['accepted'],
      );
      expect(
        const TransportJob(id: 'a', title: 't', route: 'r', detail: 'd', fee: 'f', status: 'inTransit').nextStatuses,
        ['delivered'],
      );
      expect(
        const TransportJob(id: 'a', title: 't', route: 'r', detail: 'd', fee: 'f', status: 'delivered').canTransition,
        isFalse,
      );
    });
  });
}
