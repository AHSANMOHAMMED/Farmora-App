import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/job_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';
import 'transport_request_detail_screen.dart';

class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  List<TransportJob> _eligibleJobs(FarmoraState state) {
    if (!state.isVerified) return const [];

    final districts = state.serviceDistricts
        .map((e) => e.toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final capacity = state.capacityKg > 0 ? state.capacityKg : null;

    final requested =
        state.jobs.where((j) => j.status == 'requested').toList();

    int score(TransportJob j) {
      var s = 0;
      final d = (j.district ?? '').toLowerCase();
      if (districts.isNotEmpty && d.isNotEmpty && districts.contains(d)) {
        s += 2;
      }
      final load = j.weightKg ?? j.capacityKg;
      if (capacity != null && load != null && load <= capacity) s += 1;
      return s;
    }

    final filtered = requested.where((j) {
      final d = (j.district ?? '').toLowerCase();
      if (districts.isNotEmpty && d.isNotEmpty && !districts.contains(d)) {
        return false;
      }
      final load = j.weightKg ?? j.capacityKg;
      if (capacity != null && load != null && load > capacity) return false;
      return true;
    }).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    final jobs = _eligibleJobs(state);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.jobs,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: !state.isVerified
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Verify your transporter account to see available jobs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          : AsyncStateView(
              isLoading: false,
              isEmpty: jobs.isEmpty,
              emptyMessage: l10n.noJobs,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.jobAvailable,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final j = jobs[index - 1];
                  return JobCard(
                    title: j.title,
                    route: j.route,
                    detail: j.detail,
                    fee: j.fee,
                    accepted: j.accepted,
                    onAccept: () =>
                        context.read<FarmoraState>().acceptJob(j.id),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TransportRequestDetailScreen(job: j),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

/// Alias for backward compatibility
typedef Jobs = AvailableJobsScreen;
