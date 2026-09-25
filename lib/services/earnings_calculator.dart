import 'package:intl/intl.dart';

import '../models/order.dart';

/// Formats LKR amounts as "LKR 12,500.00".
final NumberFormat lkrFormat =
    NumberFormat.currency(locale: 'en_US', symbol: 'LKR ', decimalDigits: 2);

enum EarningsFilter { all, cod, bankDeposit, pending }

class MonthlyEarning {
  final DateTime month;
  final double amount;

  const MonthlyEarning({required this.month, required this.amount});
}

class MonthSummary {
  final DateTime month;
  final double total;
  final int paidOrders;
  final double codTotal;
  final double bankTotal;
  final double pending;
  final double previousTotal;

  const MonthSummary({
    required this.month,
    required this.total,
    required this.paidOrders,
    required this.codTotal,
    required this.bankTotal,
    required this.pending,
    required this.previousTotal,
  });

  /// % change vs the previous month; null when there is nothing to compare.
  double? get changePercent => previousTotal == 0
      ? null
      : (total - previousTotal) / previousTotal * 100;
}

/// Farmer earnings derived from orders.
///
/// Money counts as earned only once the farmer confirms payment
/// (`paymentStatus` paid), dated by `paidAt`. Cancelled orders are ignored.
class EarningsCalculator {
  EarningsCalculator(
    Iterable<FarmoraOrder> orders, {
    String? farmerId,
    DateTime? now,
  })  : _orders = orders
            .where((o) => farmerId == null || o.farmerId == farmerId)
            .where((o) => !o.isCancelled)
            .toList(),
        now = now ?? DateTime.now();

  final List<FarmoraOrder> _orders;
  final DateTime now;

  Iterable<FarmoraOrder> get paidOrders => _orders.where((o) => o.isPaid);
  Iterable<FarmoraOrder> get awaitingOrders =>
      _orders.where((o) => o.isAwaitingPayment);

  /// When the money arrived. Legacy paid orders without `paidAt` fall back to
  /// `createdAt`; null when neither is known.
  static DateTime? earnedAt(FarmoraOrder o) {
    if (o.paidAt != null) return o.paidAt;
    return o.createdAt.millisecondsSinceEpoch > 0 ? o.createdAt : null;
  }

  static DateTime? _createdAt(FarmoraOrder o) =>
      o.createdAt.millisecondsSinceEpoch > 0 ? o.createdAt : null;

  /// Date shown for a transaction: payment date if paid, else order date.
  static DateTime? transactionDate(FarmoraOrder o) =>
      o.isPaid ? earnedAt(o) : _createdAt(o);

  static bool _sameMonth(DateTime? d, DateTime month) =>
      d != null && d.year == month.year && d.month == month.month;

  static double _sum(Iterable<FarmoraOrder> orders) =>
      orders.fold(0.0, (sum, o) => sum + o.total);

  double get totalEarnings => _sum(paidOrders);

  double get thisMonth =>
      _sum(paidOrders.where((o) => _sameMonth(earnedAt(o), now)));

  /// Current week, Monday 00:00 to Sunday 23:59.
  double get thisWeek {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _sum(paidOrders.where((o) {
      final d = earnedAt(o);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }));
  }

  double get pendingPayments => _sum(awaitingOrders);

  /// Earnings per calendar month, oldest first, ending with the current month.
  List<MonthlyEarning> monthly({int months = 6}) => [
        for (var i = months - 1; i >= 0; i--)
          () {
            final month = DateTime(now.year, now.month - i);
            return MonthlyEarning(
              month: month,
              amount: _sum(
                  paidOrders.where((o) => _sameMonth(earnedAt(o), month))),
            );
          }(),
      ];

  MonthSummary summaryFor(DateTime month) {
    final paid =
        paidOrders.where((o) => _sameMonth(earnedAt(o), month)).toList();
    final previous = DateTime(month.year, month.month - 1);
    return MonthSummary(
      month: DateTime(month.year, month.month),
      total: _sum(paid),
      paidOrders: paid.length,
      codTotal: _sum(paid.where((o) => !o.isBankDeposit)),
      bankTotal: _sum(paid.where((o) => o.isBankDeposit)),
      pending: _sum(
          awaitingOrders.where((o) => _sameMonth(_createdAt(o), month))),
      previousTotal:
          _sum(paidOrders.where((o) => _sameMonth(earnedAt(o), previous))),
    );
  }

  /// Paid orders dated in [month] plus unpaid orders placed in [month],
  /// newest first.
  List<FarmoraOrder> transactionsFor(
    DateTime month, {
    EarningsFilter filter = EarningsFilter.all,
  }) {
    final list = _orders
        .where((o) =>
            (o.isPaid && _sameMonth(earnedAt(o), month)) ||
            (o.isAwaitingPayment && _sameMonth(_createdAt(o), month)))
        .where((o) => switch (filter) {
              EarningsFilter.all => true,
              EarningsFilter.cod => !o.isBankDeposit,
              EarningsFilter.bankDeposit => o.isBankDeposit,
              EarningsFilter.pending => o.isAwaitingPayment,
            })
        .toList();
    list.sort((a, b) => (transactionDate(b) ?? DateTime(0))
        .compareTo(transactionDate(a) ?? DateTime(0)));
    return list;
  }

  /// Paid orders with no known date (can't be placed in a month).
  Iterable<FarmoraOrder> get undatedPaidOrders =>
      paidOrders.where((o) => earnedAt(o) == null);
}
