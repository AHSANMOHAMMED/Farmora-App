import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/transport_job.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/core/widgets/route_progress_map.dart';

void main() {
  group('TransportJob status machine', () {
    test('requested → accepted → pickedUp → inTransit → delivered', () {
      expect(TransportJob.validTransitions['requested'], ['accepted']);
      expect(TransportJob.validTransitions['accepted'],
          containsAll(['pickedUp', 'cancelled']));
      expect(TransportJob.validTransitions['pickedUp'], ['inTransit']);
      expect(TransportJob.validTransitions['inTransit'], ['delivered']);
      expect(TransportJob.validTransitions['delivered'], isEmpty);
    });

    test('progress increases along transit path', () {
      expect(RouteProgressMap.progressForJobStatus('requested'), lessThan(0.1));
      expect(
        RouteProgressMap.progressForJobStatus('accepted'),
        lessThan(RouteProgressMap.progressForJobStatus('pickedUp')),
      );
      expect(
        RouteProgressMap.progressForJobStatus('pickedUp'),
        lessThan(RouteProgressMap.progressForJobStatus('inTransit')),
      );
      expect(RouteProgressMap.progressForJobStatus('delivered'), 1.0);
    });
  });

  group('Order payment / address acceptance', () {
    test('COD-ready order is delivered + unpaid', () {
      final order = FarmoraOrder(
        id: 'o1',
        title: 'Carrots',
        productName: 'Carrots',
        quantity: '10 kg',
        deliveryAddress: '12 Main St, Colombo',
        detail: '10 kg',
        status: 'delivered',
        progress: 1,
        color: const Color(0xFF000000),
        paymentStatus: 'payment_required',
      );
      expect(order.deliveryAddress.length, greaterThanOrEqualTo(5));
      expect(order.isCompleted, isTrue);
      expect(order.isPaid, isFalse);
    });

    test('paid delivered is earnings-eligible', () {
      final order = FarmoraOrder(
        id: 'o2',
        title: 'Tea',
        detail: '5 kg',
        status: 'delivered',
        progress: 1,
        color: const Color(0xFF000000),
        paymentStatus: 'paid',
        totalAmountNumber: 2500,
      );
      expect(order.isCompleted, isTrue);
      expect(order.isPaid, isTrue);
      expect(order.total, 2500);
    });
  });

  group('Maps gate', () {
    test('maps disabled without dart-define key', () {
      expect(RouteProgressMap.mapsEnabled, isFalse);
    });
  });
}
