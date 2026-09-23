import 'package:farmora/models/dispute_model.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/models/transport_job.dart';
import 'package:farmora/features/messaging/presentation/chat_screen.dart';
import 'package:farmora/core/widgets/route_progress_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backend order schema compat', () {
    test('total prefers totalMinor, displayTotal uses currency', () {
      final o = FarmoraOrder(
        id: 'o1',
        title: 't',
        detail: 'd',
        status: 'pending',
        progress: 0.1,
        color: const Color(0xFF000000),
        totalAmountNumber: 5.0,
        totalMinor: 75000,
        currency: 'LKR',
        paymentStatus: 'paid',
      );
      expect(o.total, 750.0);
      expect(o.displayTotal, 'LKR 750.00');
      expect(o.isPaid, isTrue);
      expect(o.canReview, isFalse);
    });

    test('canReview only when delivered and undisputed', () {
      FarmoraOrder base(String status, {String? disputeId}) => FarmoraOrder(
            id: 'o',
            title: 't',
            detail: 'd',
            status: status,
            progress: 1,
            color: const Color(0xFF000000),
            disputeId: disputeId,
          );
      expect(base('delivered').canReview, isTrue);
      expect(base('pending').canReview, isFalse);
      expect(base('delivered', disputeId: 'd1').canReview, isFalse);
    });

    test('fromMap reads backend fields', () {
      final o = FarmoraOrder.fromMap('id1', {
        'title': 't',
        'status': 'delivered',
        'totalMinor': 10000,
        'paymentStatus': 'paid',
        'escrowStatus': 'released',
        'buyerId': 'b',
        'items': [
          {'productId': 'p', 'quantity': 2}
        ],
      });
      expect(o.totalMinor, 10000);
      expect(o.items.length, 1);
      expect(o.isPaid, isTrue);
    });
  });

  group('Backend product schema compat', () {
    test('price falls back to priceMinor, images merge', () {
      final p = Product.fromMap('p1', {
        'name': 'Carrot',
        'priceMinor': 35000,
        'quantityAvailable': 20,
        'media': ['m1'],
        'imageUrls': ['u1'],
        'images': ['i1'],
      });
      expect(p.priceMinor, 35000);
      expect(p.effectivePricePerUnit, 350.0);
      expect(p.allImages.toSet(), {'m1', 'u1', 'i1'});
    });
  });

  group('Backend order lifecycle statuses', () {
    test('confirmed/assigned/pickedUp/inTransit count as accepted', () {
      FarmoraOrder s(String status) => FarmoraOrder(
          id: 'o', title: 't', detail: 'd', status: status, progress: 0.5, color: const Color(0xFF000000));
      for (final st in ['accepted', 'confirmed', 'assigned', 'pickedUp', 'inTransit', 'In transit', 'Accepted']) {
        expect(s(st).isAccepted, isTrue, reason: st);
      }
      expect(s('pending').isAccepted, isFalse);
      expect(s('delivered').isCompleted, isTrue);
    });
  });

  group('Transport state machine', () {
    test('valid transitions match backend', () {
      expect(TransportJob.validTransitions['requested'], ['accepted']);
      expect(TransportJob.validTransitions['accepted'], ['pickedUp', 'cancelled']);
      expect(TransportJob.validTransitions['pickedUp'], ['inTransit']);
      expect(TransportJob.validTransitions['inTransit'], ['delivered']);
      const j = TransportJob(id: 'j', title: 't', route: 'r', detail: 'd', fee: 'f', status: 'accepted');
      expect(j.nextStatuses, ['pickedUp', 'cancelled']);
      expect(j.canTransition, isTrue);
    });
  });

  group('Dispute reason round-trip with description suffix', () {
    test('parses reason prefix, keeps evidence images', () {
      final d = Dispute.fromMap('d1', {
        'orderId': 'o1',
        'reason': 'damagedGoods: box was crushed on arrival',
        'description': 'box was crushed',
        'status': 'open',
        'evidenceImages': ['https://x/y.jpg'],
      });
      expect(d.reason, DisputeReason.damagedGoods);
      expect(d.evidenceImages, ['https://x/y.jpg']);
    });
  });

  group('Route progress mapping', () {
    test('order and job statuses map to increasing progress', () {
      expect(RouteProgressMap.progressForOrderStatus('pending'), 0.0);
      expect(
        RouteProgressMap.progressForOrderStatus('inTransit'),
        greaterThan(RouteProgressMap.progressForOrderStatus('confirmed')),
      );
      expect(RouteProgressMap.progressForOrderStatus('delivered'), 1.0);
      expect(RouteProgressMap.progressForJobStatus('requested'), lessThan(0.1));
      expect(RouteProgressMap.progressForJobStatus('delivered'), 1.0);
    });
  });

  group('Chat codec meets 16-char backend minimum', () {
    test('short messages padded, round-trip decode', () {
      final enc = encodeChatOutgoing('hi');
      expect(enc.length, greaterThanOrEqualTo(16));
      expect(decodeChatIncoming(enc), 'hi');
      expect(decodeChatIncoming('plain legacy text'), 'plain legacy text');
    });
  });
}
