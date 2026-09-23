import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmer_header.dart';
import '../../../providers/farmora_state.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FarmerHeader(title: 'Earnings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card: Total Earnings
            // Stitch: bg-primary-container text-on-primary-container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer, // #4caf50
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
                  // Cross-hatch pattern overlay (Stitch uses SVG pattern)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Opacity(
                        opacity: 0.10,
                        child: CustomPaint(painter: _CrossHatchPainter()),
                      ),
                    ),
                  ),
                  // Wallet icon in bottom-right
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
                      // Stitch: text-label-md opacity-80 uppercase tracking-wider
                      Text(
                        'TOTAL EARNINGS',
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
                        currencyFormat.format(state.totalEarnings),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showWithdrawalDialog(context, state),
                          icon: const Icon(Icons.account_balance_rounded,
                              size: 16),
                          label: const Text(
                            'Request Payout',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onPrimaryContainer,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Summary Cards Grid — Stitch: grid-cols-2 gap-sm
            // This Month + This Week in a row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'This Month',
                    amount: currencyFormat.format(state.thisMonth),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'This Week',
                    amount: currencyFormat.format(state.thisWeek),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Pending Payments — Stitch: col-span-2 bg-secondary-container text-on-secondary-container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Payments',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.onSecondaryContainer.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(state.pendingPayments),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.pending_actions_rounded,
                    size: 32,
                    color: AppColors.secondary.withValues(alpha: 0.50),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Monthly Earnings Bar Chart Card
            // Stitch: bg-surface-container-lowest p-md rounded-xl
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stitch: h3 text-headline-md
                  const Text(
                    'Monthly Earnings',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stitch: w-full h-48 flex items-end justify-between gap-1 mt-4 px-2
                  SizedBox(
                    height: 192, // h-48
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: state.monthlyBars.map((bar) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tooltip on top of highlighted bar
                                if (bar.isHighlighted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.inverseSurface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'LKR ${bar.amount.toInt()}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inverseOnSurface,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 24),
                                // Bar itself
                                // Stitch: highlighted bar = bg-primary (not bg-primary-container)
                                Container(
                                  height:
                                      100 * bar.heightRatio.clamp(0.1, 1.0),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: bar.isHighlighted
                                        ? AppColors.primary // bg-primary = #006e1c
                                        : AppColors.surfaceContainerHigh, // other bars
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    boxShadow: bar.isHighlighted
                                        ? [
                                            BoxShadow(
                                              // Stitch: shadow-[0_4px_12px_rgba(76,175,80,0.3)]
                                              color: const Color(0xFF4CAF50).withValues(alpha: 0.30),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Label
                                Text(
                                  bar.month,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: bar.isHighlighted
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: bar.isHighlighted
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Earnings History List
            // Stitch: bg-surface-container-lowest p-md rounded-xl
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings History',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      final isLast = index == state.transactions.length - 1;
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                // Stitch: w-10 h-10 rounded-full bg-surface-container-high
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sell_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ${tx.orderNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.date,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${currencyFormat.format(tx.amount)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stitch: absolute bottom-0 left-16 right-0 h-[1px] bg-outline-variant opacity-30
                          if (!isLast)
                            Positioned(
                              bottom: 0,
                              left: 54,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: AppColors.outlineVariant.withValues(alpha: 0.30),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  // Stitch: button w-full h-touch-target text-primary font-button-text
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => _showAllTransactionsModal(context, state),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'View All Transactions',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stitch: bg-surface-container-high text-on-surface p-md rounded-xl shadow-sm
  Widget _buildMetricCard({
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllTransactionsModal(BuildContext context, FarmoraState state) {
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Transactions',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final tx = state.transactions[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Icon(Icons.sell, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        'Order ${tx.orderNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(tx.date),
                      trailing: Text(
                        '+${currencyFormat.format(tx.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawalDialog(BuildContext context, FarmoraState state) {
    if (state.totalEarnings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No earnings available for payout.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amountController = TextEditingController(
      text: state.totalEarnings.toStringAsFixed(0),
    );
    final accountController = TextEditingController();
    String selectedBank = 'Bank of Ceylon (BOC)';
    const payoutMethod = 'CEFT (Fast Transfer)';

    final banks = [
      'Bank of Ceylon (BOC)',
      'Commercial Bank of Ceylon',
      'Sampath Bank',
      'Hatton National Bank (HNB)',
      'People\'s Bank',
      'Nations Trust Bank',
      'eZ Cash (Dialog)',
      'mCash (Mobitel)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final amt = double.tryParse(amountController.text) ?? 0.0;
          final fee = amt * (state.commissionRate / 100.0);
          final net = (amt - fee).clamp(0.0, double.infinity);

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.account_balance_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Request Payout',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Balance:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'LKR ${state.totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Bank / Wallet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBank,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: banks
                        .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedBank = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Account / Phone Number',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter bank account or wallet number',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Withdrawal Amount (LKR)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: 'LKR ',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPresetChip(
                          '25%',
                          (state.totalEarnings * 0.25),
                          amountController,
                          setModalState),
                      _buildPresetChip(
                          '50%',
                          (state.totalEarnings * 0.50),
                          amountController,
                          setModalState),
                      _buildPresetChip(
                          '75%',
                          (state.totalEarnings * 0.75),
                          amountController,
                          setModalState),
                      _buildPresetChip(
                          '100%',
                          state.totalEarnings,
                          amountController,
                          setModalState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Platform Fee (${state.commissionRate}%):',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'LKR ${fee.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Payout:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LKR ${net.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final enteredAmount =
                      double.tryParse(amountController.text) ?? 0.0;
                  final accountNum = accountController.text.trim();
                  if (enteredAmount <= 0 ||
                      enteredAmount > state.totalEarnings) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid payout amount'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (accountNum.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter account number'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  try {
                    await state.requestFarmerWithdrawal(
                      amount: enteredAmount,
                      bankName: selectedBank,
                      accountNumber: accountNum,
                      payoutMethod: payoutMethod,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payout of LKR ${enteredAmount.toStringAsFixed(2)} submitted successfully!',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error submitting payout: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Confirm Payout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double value,
    TextEditingController controller,
    void Function(void Function()) setModalState,
  ) {
    return InkWell(
      onTap: () {
        setModalState(() {
          controller.text = value.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// Custom painter for crosshatch pattern matching Stitch SVG
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
