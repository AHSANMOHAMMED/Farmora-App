import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/market_price_index.dart';
import 'package:farmora/models/review_model.dart';
import 'package:farmora/models/audit_log_model.dart';
import 'package:farmora/models/settlement_model.dart';
import 'package:farmora/providers/farmora_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarketPriceIndex Model Tests', () {
    test('MarketPriceIndex fromMap and toMap round-trip', () {
      final now = DateTime.now();
      final index = MarketPriceIndex(
        id: 'mpi-test-1',
        cropName: 'Red Dambulla Onions',
        category: 'Vegetables',
        district: 'Dambulla',
        minPricePerKg: 280.0,
        maxPricePerKg: 340.0,
        averagePricePerKg: 310.0,
        trend: 'up',
        updatedAt: now,
      );

      final map = index.toMap();
      expect(map['cropName'], 'Red Dambulla Onions');
      expect(map['district'], 'Dambulla');
      expect(map['minPricePerKg'], 280.0);
      expect(map['maxPricePerKg'], 340.0);
      expect(map['trend'], 'up');

      final restored = MarketPriceIndex.fromMap(map, 'mpi-test-1');
      expect(restored.cropName, 'Red Dambulla Onions');
      expect(restored.minPricePerKg, 280.0);
      expect(restored.maxPricePerKg, 340.0);
      expect(restored.averagePricePerKg, 310.0);
      expect(restored.trend, 'up');
    });

    test('MarketPriceIndex copyWith updates target fields', () {
      final index = MarketPriceIndex(
        id: 'mpi-test-2',
        cropName: 'Highland Carrots',
        category: 'Vegetables',
        district: 'Nuwara Eliya',
        minPricePerKg: 200.0,
        maxPricePerKg: 250.0,
        averagePricePerKg: 225.0,
        trend: 'stable',
        updatedAt: DateTime.now(),
      );

      final updated = index.copyWith(
        minPricePerKg: 220.0,
        maxPricePerKg: 270.0,
        trend: 'up',
      );

      expect(updated.minPricePerKg, 220.0);
      expect(updated.maxPricePerKg, 270.0);
      expect(updated.trend, 'up');
      expect(updated.cropName, 'Highland Carrots');
    });
  });

  group('FarmoraState Admin Features Tests', () {
    test('FarmoraState initializes Sri Lankan Pola commodity rates', () {
      final state = FarmoraState();
      expect(state.marketPrices.isNotEmpty, isTrue);

      final tomato = state.getMarketPriceForCrop('Organic Red Tomatoes');
      expect(tomato, isNotNull);
      expect(tomato!.district, 'Dambulla');
      expect(tomato.minPricePerKg, 150.0);
    });

    test('FarmoraState updates commodity rate and recalculates average', () {
      final state = FarmoraState();
      final first = state.marketPrices.first;

      state.updateMarketPrice(
        first.id,
        minPrice: 300.0,
        maxPrice: 400.0,
        trend: 'down',
      );

      final updated = state.marketPrices.firstWhere((p) => p.id == first.id);
      expect(updated.minPricePerKg, 300.0);
      expect(updated.maxPricePerKg, 400.0);
      expect(updated.averagePricePerKg, 350.0);
      expect(updated.trend, 'down');
    });

    test('FarmoraState adds new commodity rate', () {
      final state = FarmoraState();
      final initialCount = state.marketPrices.length;

      state.addMarketPrice(
        MarketPriceIndex(
          id: 'mpi-new-1',
          cropName: 'Jaffna Red Onion',
          category: 'Vegetables',
          district: 'Jaffna',
          minPricePerKg: 320.0,
          maxPricePerKg: 390.0,
          averagePricePerKg: 355.0,
          trend: 'up',
          updatedAt: DateTime.now(),
        ),
      );

      expect(state.marketPrices.length, initialCount + 1);
      final lookup = state.getMarketPriceForCrop('Jaffna Red Onion');
      expect(lookup, isNotNull);
      expect(lookup!.district, 'Jaffna');
    });

    test('FarmoraState removes commodity rate and logs audit event', () {
      final state = FarmoraState();
      final initialCount = state.marketPrices.length;
      state.addMarketPrice(
        MarketPriceIndex(
          id: 'mpi-del-1',
          cropName: 'Test Pumpkin',
          category: 'Vegetables',
          district: 'Kandy',
          minPricePerKg: 60.0,
          maxPricePerKg: 90.0,
          averagePricePerKg: 75.0,
          trend: 'stable',
          updatedAt: DateTime.now(),
        ),
      );
      expect(state.marketPrices.length, initialCount + 1);

      state.removeMarketPrice('mpi-del-1');

      expect(state.marketPrices.length, initialCount);
      expect(state.getMarketPriceForCrop('Test Pumpkin'), isNull);
      // Deletion is audit-logged.
      expect(
        state.auditLogs.any((log) =>
            log.actionType == 'MARKET_PRICE_DELETE' &&
            log.targetId == 'mpi-del-1'),
        isTrue,
      );
    });

    test('FarmoraState arbitrates dispute with refund_buyer outcome', () async {
      final state = FarmoraState();
      expect(state.orders.isNotEmpty, isTrue);

      final order = state.orders.first;
      await state.resolveDisputeArbitration(
        orderId: order.id,
        resolution: 'refund_buyer',
        adminNotes: 'Damaged during transit; full refund approved.',
      );

      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.status, 'cancelled');
      expect(updated.paymentStatus, 'refunded');
    });

    test('FarmoraState arbitrates dispute with release_farmer outcome',
        () async {
      final state = FarmoraState();
      expect(state.orders.isNotEmpty, isTrue);

      final order = state.orders.first;
      await state.resolveDisputeArbitration(
        orderId: order.id,
        resolution: 'release_farmer',
        adminNotes: 'Produce confirmed fresh upon delivery; releasing escrow.',
      );

      final updated = state.orders.firstWhere((o) => o.id == order.id);
      expect(updated.status, 'completed');
      expect(updated.paymentStatus, 'released');
    });

    test('FarmoraState broadcasts platform advisory alert', () async {
      final state = FarmoraState();
      final initialNotifs = state.notifications.length;

      await state.broadcastPlatformAdvisory(
        title: 'Severe Weather Warning',
        message: 'High winds expected in Nuwara Eliya district.',
        targetRole: 'all',
        priority: 'emergency',
      );

      expect(state.notifications.length, initialNotifs + 1);
      expect(state.notifications.first.title.contains('Severe Weather Warning'),
          isTrue);
    });

    test('FarmoraState moderates and deletes reviews', () async {
      final state = FarmoraState();
      expect(state.reviews.isNotEmpty, isTrue);

      final rev = state.reviews.first;
      await state.moderateReview(
        reviewId: rev.id,
        status: ReviewStatus.rejected,
        note: 'Flagged for moderation audit',
      );

      final updated = state.reviews.firstWhere((r) => r.id == rev.id);
      expect(updated.status, ReviewStatus.rejected);
      expect(updated.moderationNote, 'Flagged for moderation audit');

      final countBeforeDelete = state.reviews.length;
      await state.deleteReview(reviewId: rev.id);
      expect(state.reviews.length, countBeforeDelete - 1);
    });

    test(
        'FarmoraState executes user management actions (verify, role, suspend)',
        () async {
      final state = FarmoraState();
      expect(state.users.isNotEmpty, isTrue);

      final user = state.users.first;
      final uid = (user['uid'] ?? user['id']).toString();

      await state.setUserVerified(userId: uid, verified: true);
      var updatedUser =
          state.users.firstWhere((u) => (u['uid'] ?? u['id']) == uid);
      expect(updatedUser['isVerified'], isTrue);

      await state.updateUserRole(userId: uid, role: 'transporter');
      updatedUser = state.users.firstWhere((u) => (u['uid'] ?? u['id']) == uid);
      expect(updatedUser['role'], 'transporter');

      await state.setUserSuspended(uid, true);
      updatedUser = state.users.firstWhere((u) => (u['uid'] ?? u['id']) == uid);
      expect(updatedUser['isSuspended'], isTrue);
    });

    test('FarmoraState manages server maintenance and platform economics', () {
      final state = FarmoraState();

      expect(state.maintenanceMode, isFalse);
      state.setMaintenanceMode(
          enabled: true, notice: 'Upgrading database servers');
      expect(state.maintenanceMode, isTrue);
      expect(state.maintenanceNotice, 'Upgrading database servers');

      state.setCommissionRate(6.5);
      expect(state.commissionRate, 6.5);

      state.setEscrowReleaseHours(72);
      expect(state.escrowReleaseHours, 72);

      state.setMinAppVersion('1.3.0');
      expect(state.minAppVersion, '1.3.0');
    });

    test('AuditLog Model round-trip and copyWith', () {
      final now = DateTime.now();
      final log = AuditLog(
        id: 'aud-test-1',
        actorId: 'usr-admin-1',
        actorName: 'Admin Super',
        actorRole: 'admin',
        actionType: 'ESCROW_RELEASE',
        targetEntity: 'Order',
        targetId: 'ord-100',
        details: 'Escrow released upon inspection',
        severity: 'info',
        timestamp: now,
      );

      final map = log.toMap();
      expect(map['actionType'], 'ESCROW_RELEASE');
      expect(map['severity'], 'info');

      final restored = AuditLog.fromMap(map, 'aud-test-1');
      expect(restored.id, 'aud-test-1');
      expect(restored.actorName, 'Admin Super');
      expect(restored.targetEntity, 'Order');

      final copied =
          log.copyWith(severity: 'critical', details: 'Updated detail');
      expect(copied.severity, 'critical');
      expect(copied.details, 'Updated detail');
      expect(copied.actorId, 'usr-admin-1');
    });

    test('SettlementPayout Model round-trip and copyWith', () {
      final now = DateTime.now();
      final payout = SettlementPayout(
        id: 'stl-test-1',
        orderId: 'ord-101',
        orderNumber: 'ORD-101',
        recipientId: 'usr-farmer-1',
        recipientName: 'Sunil Bandara',
        recipientRole: 'farmer',
        bankName: 'Commercial Bank of Ceylon',
        accountNumber: '8102-3948-2910',
        grossAmount: 10000.0,
        platformFee: 500.0,
        netAmount: 9500.0,
        payoutMethod: 'CEFT',
        status: 'pending',
        createdAt: now,
      );

      final map = payout.toMap();
      expect(map['grossAmount'], 10000.0);
      expect(map['platformFee'], 500.0);
      expect(map['netAmount'], 9500.0);
      expect(map['status'], 'pending');

      final restored = SettlementPayout.fromMap(map, 'stl-test-1');
      expect(restored.id, 'stl-test-1');
      expect(restored.bankName, 'Commercial Bank of Ceylon');
      expect(restored.netAmount, 9500.0);

      final settled =
          payout.copyWith(status: 'settled', transactionReference: 'CEFT-999');
      expect(settled.status, 'settled');
      expect(settled.transactionReference, 'CEFT-999');
    });

    test('FarmoraState manages audit logs and auto-instruments admin actions',
        () async {
      final state = FarmoraState();
      expect(state.auditLogs.isNotEmpty, isTrue);

      final initialLogsCount = state.auditLogs.length;
      await state.setUserVerified(userId: 'usr-farmer-1', verified: true);

      expect(state.auditLogs.length, initialLogsCount + 1);
      final latest = state.auditLogs.first;
      expect(latest.actionType, 'USER_VERIFY');
      expect(latest.targetId, 'usr-farmer-1');
    });

    test(
        'FarmoraState manages treasury escrow settlements (approve, hold, retry)',
        () async {
      final state = FarmoraState();
      expect(state.settlements.isNotEmpty, isTrue);

      final pending =
          state.settlements.firstWhere((s) => s.status == 'pending');
      await state.approveSettlement(pending.id);

      final updatedSettled =
          state.settlements.firstWhere((s) => s.id == pending.id);
      expect(updatedSettled.status, 'settled');
      expect(updatedSettled.transactionReference, isNotNull);

      // Hold test
      await state.holdSettlement(updatedSettled.id, 'Bank account discrepancy');
      final updatedHeld =
          state.settlements.firstWhere((s) => s.id == pending.id);
      expect(updatedHeld.status, 'on_hold');
      expect(updatedHeld.holdReason, 'Bank account discrepancy');

      // Retry test
      await state.retrySettlement(updatedHeld.id);
      final updatedRetried =
          state.settlements.firstWhere((s) => s.id == pending.id);
      expect(updatedRetried.status, 'processing');
      expect(updatedRetried.holdReason, isNull);
    });
  });
}
