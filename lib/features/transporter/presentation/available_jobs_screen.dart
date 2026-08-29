import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/job_card.dart';

class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available jobs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose a delivery that fits your route.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...state.jobs.map(
            (j) => JobCard(
              title: j.title,
              route: j.route,
              detail: j.detail,
              fee: j.fee,
              accepted: j.accepted,
              onAccept: () => context.read<FarmoraState>().acceptJob(j.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Jobs = AvailableJobsScreen;
