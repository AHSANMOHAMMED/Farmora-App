class EarningsSummary {
  final double totalEarnings;
  final double thisMonth;
  final double thisWeek;
  final double pendingPayments;

  const EarningsSummary({
    required this.totalEarnings,
    required this.thisMonth,
    required this.thisWeek,
    required this.pendingPayments,
  });
}

class MonthlyBarData {
  final String month;
  final double amount;
  final double heightRatio; // 0.0 to 1.0
  final bool isHighlighted;

  const MonthlyBarData({
    required this.month,
    required this.amount,
    required this.heightRatio,
    this.isHighlighted = false,
  });
}

class EarningsTransaction {
  final String id;
  final String orderNumber;
  final String date;
  final double amount;
  final bool isCredit;

  const EarningsTransaction({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.amount,
    this.isCredit = true,
  });
}
