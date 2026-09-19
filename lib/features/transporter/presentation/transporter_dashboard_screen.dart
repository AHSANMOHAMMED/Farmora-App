import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
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
          'Farmora',
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hi, Sureka!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Text(
                    state.currentUserId.isEmpty ? 'S' : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Keep the supply chain moving 🚚',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 18),
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
                    'Rs. ${state.totalEarnings.toStringAsFixed(2)}',
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
            Row(
              children: [
                Expanded(child: _DashboardStat(
                  label: 'Completed',
                  value: '${state.completedJobs.length}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(child: _DashboardStat(
                  label: 'Pending',
                  value: '${state.availableJobs.length}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                )),
                const SizedBox(width: 10),
                Expanded(child: _DashboardStat(
                  label: 'Ongoing',
                  value: '${state.activeJobs.length}',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.blue,
                )),
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

class _DashboardStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
