import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../providers/farmora_state.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final strings = FarmoraStrings.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.t('earningsDashboard'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  _buildProfileAvatar(),
                ],
              ),
              const SizedBox(height: 20),

              // ── Total Earnings Hero Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('totalEarnings'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(state.totalEarnings),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '+15.2% vs last month',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── This Month & This Week Cards ──
              Row(
                children: [
                  Expanded(child: _buildMetricCard(strings.t('thisMonth'), currencyFormat.format(state.thisMonth), Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(strings.t('thisWeek'), currencyFormat.format(state.thisWeek), Icons.calendar_view_week)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Pending Payments ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 18, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            Text(
                              strings.t('pendingPayments'),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(state.pendingPayments),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(strings.t('viewAll'), style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const Icon(Icons.chevron_right, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Monthly Revenue Chart ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.t('monthlyRevenue'),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text('2024', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                              Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: state.monthlyBars.map((bar) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height:
                                        100 * bar.heightRatio.clamp(0.1, 1.0),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: bar.isHighlighted
                                          ? AppColors.primary
                                          : const Color(0xFFC8E6C9),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bar.month,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: bar.isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                      color: bar.isHighlighted ? AppColors.primary : AppColors.onSurfaceVariant,
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
              const SizedBox(height: 20),

              // ── Recent Earnings ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.t('recentEarnings'),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune, size: 20, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...state.transactions.take(4).map((tx) => _buildEarningItem(tx, currencyFormat)),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Load More History',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildMetricCard(String title, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(dynamic tx, NumberFormat currencyFormat) {
    final isPending = tx.status == 'Pending' || tx.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? Icons.schedule : Icons.check_circle_outline,
              size: 20,
              color: isPending ? const Color(0xFFE65100) : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ${tx.orderNumber}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.date,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormat.format(tx.amount)}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Completed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
