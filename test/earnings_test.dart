import 'package:farmora/models/order.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/services/earnings_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _needsDemoData =
    'Relies on local demo data / local-only state updates that dev/swami '
    'removed (writes now go through Cloud Functions). Rewrite with '
    'fake_cloud_firestore.';

FarmoraOrder _o(
  String id, {
  double amount = 1000,
  String farmerId = 'f1',
  String status = 'delivered',
  String payment = 'paid',
  String method = PaymentMethod.cod,
  DateTime? createdAt,
  DateTime? paidAt,
}) =>
    FarmoraOrder(
      id: id,
      title: id,
      detail: '',
      status: status,
      progress: 1,
      color: Colors.green,
      farmerId: farmerId,
      totalMinor: (amount * 100).round(),
      paymentStatus: payment,
      paymentMethod: method,
      createdAt: createdAt,
      paidAt: paidAt,
    );

void main() {
  // Wednesday 16 Sep 2026; week runs Mon 14 – Sun 20.
  final now = DateTime(2026, 9, 16, 12);

  group('EarningsCalculator', () {
    test('counts only paid, non-cancelled orders of this farmer by paidAt', () {
      final calc = EarningsCalculator([
        _o('a', amount: 1000, paidAt: DateTime(2026, 9, 15)), // this week
        _o('b', amount: 2000, paidAt: DateTime(2026, 9, 2)), // this month
        _o('c', amount: 4000, paidAt: DateTime(2026, 8, 30)), // last month
        _o('d', amount: 8000, payment: 'pending'),
        _o('e', amount: 16000, farmerId: 'other', paidAt: DateTime(2026, 9, 15)),
        _o('f', amount: 32000, status: 'Cancelled', paidAt: DateTime(2026, 9, 15)),
      ], farmerId: 'f1', now: now);

      expect(calc.totalEarnings, 7000);
      expect(calc.thisMonth, 3000);
      expect(calc.thisWeek, 1000);
      expect(calc.pendingPayments, 8000);
    });

    test('uses paidAt, not createdAt, to place earnings in a month', () {
      final calc = EarningsCalculator([
        _o('a',
            createdAt: DateTime(2026, 8, 28), paidAt: DateTime(2026, 9, 3)),
      ], now: now);
      expect(calc.thisMonth, 1000);
      expect(calc.summaryFor(DateTime(2026, 8)).total, 0);
    });

    test('week boundaries are Monday 00:00 to Sunday 23:59', () {
      final calc = EarningsCalculator([
        _o('sun-before', paidAt: DateTime(2026, 9, 13, 23, 59)),
        _o('mon', paidAt: DateTime(2026, 9, 14)),
        _o('sun', paidAt: DateTime(2026, 9, 20, 23, 59)),
      ], now: now);
      expect(calc.thisWeek, 2000);
    });

    test('pending includes submitted and rejected receipts, not cancelled', () {
      final calc = EarningsCalculator([
        _o('a', payment: 'pending'),
        _o('b', payment: 'proof_submitted', method: PaymentMethod.bankDeposit),
        _o('c', payment: 'rejected', method: PaymentMethod.bankDeposit),
        _o('d', payment: 'pending', status: 'Declined'),
        _o('e', payment: 'refunded'),
      ], now: now);
      expect(calc.pendingPayments, 3000);
    });

    test('monthly buckets keep the year apart and end at current month', () {
      final calc = EarningsCalculator([
        _o('a', paidAt: DateTime(2026, 9, 1)),
        _o('b', paidAt: DateTime(2025, 9, 1)), // same month name, last year
      ], now: now);
      final six = calc.monthly(months: 6);
      expect(six, hasLength(6));
      expect(six.first.month, DateTime(2026, 4));
      expect(six.last.month, DateTime(2026, 9));
      expect(six.last.amount, 1000);
      final twelve = calc.monthly(months: 12);
      expect(twelve.first.month, DateTime(2025, 10));
      expect(twelve.fold<double>(0, (s, m) => s + m.amount), 1000);
    });

    test('month summary splits COD and bank and compares to last month', () {
      final calc = EarningsCalculator([
        _o('a', amount: 3000, paidAt: DateTime(2026, 9, 2)),
        _o('b',
            amount: 1500,
            method: PaymentMethod.bankDeposit,
            paidAt: DateTime(2026, 9, 5)),
        _o('c', amount: 3000, paidAt: DateTime(2026, 8, 5)),
        _o('d',
            amount: 700, payment: 'pending', createdAt: DateTime(2026, 9, 10)),
      ], now: now);
      final s = calc.summaryFor(DateTime(2026, 9));
      expect(s.total, 4500);
      expect(s.paidOrders, 2);
      expect(s.codTotal, 3000);
      expect(s.bankTotal, 1500);
      expect(s.pending, 700);
      expect(s.previousTotal, 3000);
      expect(s.changePercent, closeTo(50, 0.001));
      expect(calc.summaryFor(DateTime(2026, 7)).changePercent, isNull);
    });

    test('transactions filter by method and pending, newest first', () {
      final calc = EarningsCalculator([
        _o('cod', paidAt: DateTime(2026, 9, 2)),
        _o('bank',
            method: PaymentMethod.bankDeposit, paidAt: DateTime(2026, 9, 8)),
        _o('due', payment: 'pending', createdAt: DateTime(2026, 9, 5)),
        _o('old', paidAt: DateTime(2026, 8, 2)),
      ], now: now);
      final sept = DateTime(2026, 9);
      expect(calc.transactionsFor(sept).map((o) => o.id),
          ['bank', 'due', 'cod']);
      expect(calc.transactionsFor(sept, filter: EarningsFilter.cod)
          .map((o) => o.id), ['due', 'cod']);
      expect(calc.transactionsFor(sept, filter: EarningsFilter.bankDeposit)
          .map((o) => o.id), ['bank']);
      expect(calc.transactionsFor(sept, filter: EarningsFilter.pending)
          .map((o) => o.id), ['due']);
    });

    test('legacy paid orders without dates count in total only', () {
      final calc = EarningsCalculator([_o('legacy', payment: 'released')],
          now: now);
      expect(calc.totalEarnings, 1000);
      expect(calc.thisMonth, 0);
      expect(calc.undatedPaidOrders, hasLength(1));
    });

    test('formats LKR with thousands separators', () {
      expect(lkrFormat.format(12500), 'LKR 12,500.00');
    });
  });

  group('FarmoraState earnings (demo farmer)', skip: _needsDemoData, () {
    test('shows the demo farmer\'s real totals, not other farmers', () {
      final state = FarmoraState()..setRole(Role.farmer);
      final calc = state.earnings;
      expect(state.totalEarnings, greaterThan(0));
      expect(state.thisMonth, calc.thisMonth);
      expect(state.pendingPayments, greaterThan(0));
      // ORD-1003 belongs to farmer_demo_2 and must not be counted.
      expect(calc.paidOrders.any((o) => o.id == 'ORD-1003'), isFalse);
      expect(state.monthlyBars, hasLength(6));
      expect(state.monthlyBars.where((b) => b.amount > 0).length,
          greaterThan(1));
    });

    test('marking cash received moves money from pending to earned', () {
      final state = FarmoraState()..setRole(Role.farmer);
      state.completeOrder('ORD-1002'); // COD, awaiting payment
      final pendingBefore = state.pendingPayments;
      final totalBefore = state.totalEarnings;
      return state.markCashReceived('ORD-1002').then((_) {
        expect(state.totalEarnings, closeTo(totalBefore + 12350, 0.01));
        expect(state.pendingPayments, closeTo(pendingBefore - 12350, 0.01));
        expect(state.thisWeek, greaterThanOrEqualTo(12350));
      });
    });
  });
}
