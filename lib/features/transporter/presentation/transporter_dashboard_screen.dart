import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/job_card.dart';
import 'active_delivery_screen.dart';

class TransporterDashboardScreen extends StatelessWidget {
  const TransporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        title: const Text(
          'Transporter Dashboard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${state.totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Completed',
                    value: '12',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: '2',
                    icon: Icons.pending_actions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Active Deliveries',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (state.jobs.any((j) => j.accepted))
              ...state.jobs.where((j) => j.accepted).map(
                    (j) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(
                        title: j.title,
                        route: j.route,
                        detail: j.detail,
                        fee: j.fee,
                        accepted: j.accepted,
                        onAccept: () {},
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ActiveDeliveryScreen(job: j),
                            ),
                          );
                        },
                      ),
                    ),
                  )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No active deliveries',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
