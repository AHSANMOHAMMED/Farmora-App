import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/widgets/farmer_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/earnings_calculator.dart';
import '../../payments/presentation/order_payment_card.dart'
    show paymentChipType, paymentMethodIcon;
import 'order_detail_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late DateTime _selectedMonth;
  EarningsFilter _filter = EarningsFilter.all;
  int _chartMonths = 6;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _refresh() async {
    try {
      await context.read<FarmoraState>().refreshOrders();
    } catch (e) {
      debugPrint('Earnings refresh failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(context.l10n.farmerEarningsRefreshFailed(describeError(e))),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    if (next.isAfter(_currentMonth)) return;
    setState(() => _selectedMonth = next);
  }

  Future<void> _pickMonth(EarningsCalculator calc) async {
    final months = [
      for (var i = 0; i < 24; i++)
        DateTime(_currentMonth.year, _currentMonth.month - i),
    ];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                ctx.l10n.farmerEarningsSelectMonth,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final m in months)
              ListTile(
                selected: m == _selectedMonth,
                selectedColor: AppColors.primary,
                title: Text(AppFormat.monthYear(m)),
                trailing: Text(lkrFormat.format(calc.summaryFor(m).total)),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final calc = state.earnings;
    final summary = calc.summaryFor(_selectedMonth);
    final transactions = calc.transactionsFor(_selectedMonth, filter: _filter);
    final undated = calc.undatedPaidOrders.length;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: FarmerHeader(title: l.earnings),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _TotalCard(amount: calc.totalEarnings),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                      title: l.farmerEarningsThisMonth, amount: calc.thisMonth),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                      title: l.farmerEarningsThisWeek, amount: calc.thisWeek),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PendingCard(amount: calc.pendingPayments),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.farmerEarningsMonthly,
                          style: _titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SegmentedButton<int>(
                        segments: [
                          ButtonSegment(
                              value: 6,
                              label: Text(l.farmerEarningsMonthsShort(6))),
                          ButtonSegment(
                              value: 12,
                              label: Text(l.farmerEarningsMonthsShort(12))),
                        ],
                        selected: {_chartMonths},
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (s) =>
                            setState(() => _chartMonths = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _EarningsChart(
                    data: calc.monthly(months: _chartMonths),
                    selectedMonth: _selectedMonth,
                    onMonthTap: (m) => setState(() => _selectedMonth = m),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MonthHeader(
              month: _selectedMonth,
              canGoForward: _selectedMonth.isBefore(_currentMonth),
              onPrevious: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onPick: () => _pickMonth(calc),
            ),
            const SizedBox(height: 8),
            _MonthSummaryCard(summary: summary),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.farmerEarningsTransactions, style: _titleStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final f in EarningsFilter.values)
                        ChoiceChip(
                          label: Text(_filterLabel(l, f)),
                          selected: _filter == f,
                          selectedColor: AppColors.primaryLight,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          _filter == EarningsFilter.all
                              ? l.farmerEarningsNoTransactions(
                                  AppFormat.monthYear(_selectedMonth))
                              : l.farmerEarningsNoFilteredTransactions(
                                  _filterLabel(l, _filter),
                                  AppFormat.monthYear(_selectedMonth)),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < transactions.length; i++) ...[
                      _TransactionTile(order: transactions[i]),
                      if (i < transactions.length - 1)
                        Divider(
                          height: 1,
                          indent: 54,
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                    ],
                ],
              ),
            ),
            if (undated > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l.farmerEarningsUndatedNote(undated),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _filterLabel(AppLocalizations l, EarningsFilter f) =>
      switch (f) {
        EarningsFilter.all => l.commonAll,
        EarningsFilter.cod => l.farmerEarningsFilterCod,
        EarningsFilter.bankDeposit => l.farmerBankDeposit,
        EarningsFilter.pending => l.statusPending,
      };
}

const _titleStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.onSurface,
);

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

class _TotalCard extends StatelessWidget {
  final double amount;
  const _TotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(painter: _CrossHatchPainter()),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.farmerEarningsTotalUpper,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.80),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lkrFormat.format(amount),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  const _MetricCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              lkrFormat.format(amount),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final double amount;
  const _PendingCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.pendingPayments,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color:
                        AppColors.onSecondaryContainer.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lkrFormat.format(amount),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.farmerEarningsPendingHint,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color:
                        AppColors.onSecondaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.pending_actions_rounded,
            size: 32,
            color: AppColors.secondary.withValues(alpha: 0.50),
          ),
        ],
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<MonthlyEarning> data;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthTap;

  const _EarningsChart({
    required this.data,
    required this.selectedMonth,
    required this.onMonthTap,
  });

  static String _compact(double v) => AppFormat.compact(v);

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(0, (m, e) => e.amount > m ? e.amount : m);
    if (maxY == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 48, color: AppColors.outlineVariant),
              const SizedBox(height: 8),
              Text(
                context.l10n.farmerEarningsChartEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dense = data.length > 6;
    final localeName = context.l10n.localeName;
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY * 1.2 / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY * 1.2 / 4,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _compact(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  final m = data[i].month;
                  final selected = m == selectedMonth;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dense
                          ? DateFormat('MMMMM', localeName).format(m)
                          : AppFormat.shortMonth(m, locale: localeName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${AppFormat.shortMonthYear(data[group.x].month, locale: localeName)}\n'
                '${lkrFormat.format(rod.toY)}',
                const TextStyle(
                  color: AppColors.inverseOnSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            touchCallback: (event, response) {
              final spot = response?.spot;
              if (event is FlTapUpEvent && spot != null) {
                onMonthTap(data[spot.touchedBarGroupIndex].month);
              }
            },
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].amount,
                    width: dense ? 12 : 22,
                    color: data[i].month == selectedMonth
                        ? AppColors.primary
                        : AppColors.primaryContainer.withValues(alpha: 0.45),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _MonthHeader({
    required this.month,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.farmerEarningsPreviousMonth,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.l10n.farmerEarningsMonthSummary(
                          AppFormat.monthYear(month)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: context.l10n.farmerEarningsNextMonth,
          onPressed: canGoForward ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final MonthSummary summary;
  const _MonthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final change = summary.changePercent;
    final up = (change ?? 0) >= 0;
    final paidTotal = summary.codTotal + summary.bankTotal;
    final l = context.l10n;
    final previousLabel = AppFormat.shortMonth(
        DateTime(summary.month.year, summary.month.month - 1));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.farmerEarningsTotalIncome,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  lkrFormat.format(summary.total),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (change != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color:
                            up ? AppColors.statusApprovedText : AppColors.error,
                      ),
                      Flexible(
                        child: Text(
                          l.farmerEarningsChangeVs(
                              AppFormat.number(change.abs(), decimals: 1),
                              previousLabel),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: up
                                ? AppColors.statusApprovedText
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: Text(
                    summary.total == 0
                        ? ''
                        : l.farmerEarningsNoCompare(previousLabel),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _stat(l.farmerEarningsPaidOrders,
                    AppFormat.number(summary.paidOrders)),
              ),
              Expanded(
                child: _stat(l.farmerEarningsPendingThisMonth,
                    lkrFormat.format(summary.pending)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l.farmerEarningsByMethod,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: paidTotal == 0
                  ? Container(color: AppColors.surfaceContainerHigh)
                  : Row(
                      children: [
                        if (summary.codTotal > 0)
                          Expanded(
                            flex: (summary.codTotal / paidTotal * 1000).round(),
                            child: Container(color: AppColors.primary),
                          ),
                        if (summary.bankTotal > 0)
                          Expanded(
                            flex:
                                (summary.bankTotal / paidTotal * 1000).round(),
                            child: Container(color: AppColors.accentWheat),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _legend(AppColors.primary, l.farmerCashOnDelivery,
                    summary.codTotal),
              ),
              Expanded(
                child: _legend(AppColors.accentWheat, l.farmerBankDeposit,
                    summary.bankTotal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      );

  Widget _legend(Color color, String label, double amount) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3, right: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  lkrFormat.format(amount),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _TransactionTile extends StatelessWidget {
  final FarmoraOrder order;
  const _TransactionTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = EarningsCalculator.transactionDate(order);
    final number = order.orderNumber.isNotEmpty ? order.orderNumber : order.id;
    final buyer =
        order.buyerName.isNotEmpty ? order.buyerName : context.l10n.roleBuyer;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(paymentMethodIcon(order.paymentMethod),
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.farmerOrderNumber(number),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$buyer · ${date != null ? AppFormat.date(date) : '—'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lkrFormat.format(order.total),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: order.isPaid
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: order.paymentStatusLabel,
                  type: paymentChipType(order.paymentState),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CrossHatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    const step = 12.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
