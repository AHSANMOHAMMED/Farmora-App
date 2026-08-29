class MonthlyBar {
  final double amount;
  final double heightRatio;
  final String month;
  final bool isHighlighted;

  const MonthlyBar({
    required this.amount,
    required this.heightRatio,
    required this.month,
    this.isHighlighted = false,
  });
}
