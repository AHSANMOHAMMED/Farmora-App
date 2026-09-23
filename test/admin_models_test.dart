import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/review_model.dart';
import 'package:farmora/models/settlement_model.dart';
import 'package:farmora/models/audit_log_model.dart';
import 'package:farmora/models/market_price_index.dart';

void main() {
  group('Review model (admin moderation round-trip)', () {
    test('parses legacy moderationStatus field into status', () {
      final review = Review.fromMap('rev1', {
        'orderId': 'o1',
        'orderNumber': 'ORD-1',
        'reviewerId': 'buyer1',
        'reviewerName': 'Buyer One',
        'subjectId': 'farmer1',
        'subjectName': 'Farmer One',
        'rating': 4,
        'comment': 'Great produce',
        'moderationStatus': 'approved',
        'createdAt': '2026-09-01T10:00:00.000',
      });
      expect(review.status, ReviewStatus.approved);
    });

    test('parses status field and defaults to pending', () {
      expect(
        Review.fromMap('r2', {'status': 'rejected'}).status,
        ReviewStatus.rejected,
      );
      expect(Review.fromMap('r3', {}).status, ReviewStatus.pending);
    });

    test('copyWith moderation fields update', () {
      final base = Review(
        id: 'r',
        orderId: 'o',
        orderNumber: 'n',
        reviewerId: 'b',
        reviewerName: 'B',
        subjectId: 'f',
        subjectName: 'F',
        rating: 2,
        comment: 'bad',
        status: ReviewStatus.pending,
        createdAt: DateTime(2026, 9, 1),
      );
      final moderated = base.copyWith(
        status: ReviewStatus.rejected,
        moderatedAt: DateTime(2026, 9, 23),
        moderationNote: 'abusive language',
      );
      expect(moderated.status, ReviewStatus.rejected);
      expect(moderated.moderationNote, 'abusive language');
      expect(moderated.moderatedAt, DateTime(2026, 9, 23));
    });
  });

  group('SettlementPayout model', () {
    test('parses Firestore map with defaults', () {
      final s = SettlementPayout.fromMap({
        'grossAmount': 10000,
        'platformFee': 500,
        'netAmount': 9500,
        'status': 'pending',
        'createdAt': '2026-09-20T08:00:00.000',
      }, 'STL-1');
      expect(s.id, 'STL-1');
      expect(s.netAmount, 9500);
      expect(s.payoutMethod, 'CEFT');
      expect(s.holdReason, isNull);
    });

    test('hold reason and transaction reference survive round-trip', () {
      final s = SettlementPayout.fromMap({
        'status': 'on_hold',
        'holdReason': 'bank mismatch',
        'transactionReference': 'CEFT-TX-123',
      }, 'STL-2');
      final map = s.toMap();
      expect(map['holdReason'], 'bank mismatch');
      expect(map['transactionReference'], 'CEFT-TX-123');
      expect(map['status'], 'on_hold');
    });
  });

  group('AuditLog model', () {
    test('fromMap defaults and timestamp parsing', () {
      final log = AuditLog.fromMap({
        'actionType': 'USER_SUSPENDED',
        'severity': 'critical',
        'timestamp': '2026-09-22T12:00:00.000',
      }, 'aud-1');
      expect(log.id, 'aud-1');
      expect(log.actionType, 'USER_SUSPENDED');
      expect(log.severity, 'critical');
      expect(log.timestamp.year, 2026);
    });

    test('toMap serializes all required fields', () {
      final log = AuditLog(
        id: 'a',
        actorId: 'u',
        actorName: 'Admin',
        actorRole: 'admin',
        actionType: 'X',
        targetEntity: 'User',
        targetId: 't',
        details: 'd',
        severity: 'info',
        timestamp: DateTime(2026, 9, 23),
      );
      final map = log.toMap();
      expect(map['actionType'], 'X');
      expect(map['severity'], 'info');
      expect(map['timestamp'], '2026-09-23T00:00:00.000');
    });
  });

  group('MarketPriceIndex model', () {
    test('parses numeric fields safely', () {
      final p = MarketPriceIndex.fromMap({
        'cropName': 'Tomato',
        'minPricePerKg': 120,
        'maxPricePerKg': 200,
        'averagePricePerKg': 160,
        'trend': 'up',
      }, 'mp-1');
      expect(p.cropName, 'Tomato');
      expect(p.minPricePerKg, 120);
      expect(p.trend, 'up');
    });

    test('round-trips through toMap/fromMap', () {
      final p = MarketPriceIndex.fromMap({
        'cropName': 'Carrot',
        'minPricePerKg': 90,
        'maxPricePerKg': 150,
        'averagePricePerKg': 120,
      }, 'mp-2');
      final q = MarketPriceIndex.fromMap(p.toMap(), p.id);
      expect(q.cropName, p.cropName);
      expect(q.id, p.id);
      expect(q.averagePricePerKg, p.averagePricePerKg);
    });
  });
}
