import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transport_job.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/async_state_handler.dart';
import '../../../core/repositories/transport_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/jobs_provider.dart';

class AvailableJobsScreen extends ConsumerWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available jobs'),
      ),
      body: AsyncStateHandler(
        value: jobsAsync,
        dataBuilder: (context, jobs) {
          if (jobs.isEmpty) {
            return const EmptyStateWidget(
               icon: Icons.local_shipping_outlined,
               title: 'No jobs available',
               subtitle: 'Check back later for new delivery opportunities.',
             );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Choose a delivery that fits your route.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ...jobs.map(
                (j) => JobCard(
                  title: j.cargoSummary,
                  route: j.displayRoute,
                  detail: '${j.weightKg} kg',
                  fee: j.displayFee,
                  accepted: j.status != TransportJobStatus.requested,
                  onAccept: () async {
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      await ref.read(transportRepositoryProvider).acceptJob(j.id, user.id);
                      ref.invalidate(availableJobsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job accepted!')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Jobs = AvailableJobsScreen;
