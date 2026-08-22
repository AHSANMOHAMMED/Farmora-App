import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transport_job.dart';

class DemoJobsNotifier extends StateNotifier<List<TransportJobModel>> {
  DemoJobsNotifier() : super(_demoJobs);

  void acceptJob(String jobId, String transporterId) {
    state = state.map((j) {
      if (j.id == jobId) {
        return TransportJobModel(
          id: j.id,
          orderId: j.orderId,
          pickupAddress: j.pickupAddress,
          dropoffAddress: j.dropoffAddress,
          cargoSummary: j.cargoSummary,
          weightKg: j.weightKg,
          offeredFeeMinor: j.offeredFeeMinor,
          currency: j.currency,
          status: TransportJobStatus.accepted,
          transporterId: transporterId,
          requestedAt: j.requestedAt,
          acceptedAt: DateTime.now(),
        );
      }
      return j;
    }).toList();
  }
}

final demoJobsProvider =
    StateNotifierProvider<DemoJobsNotifier, List<TransportJobModel>>((ref) {
  return DemoJobsNotifier();
});

final _demoJobs = <TransportJobModel>[
  const TransportJobModel(
    id: 'job-1',
    orderId: 'ord-3',
    pickupAddress: 'Kaduwela',
    dropoffAddress: 'Colombo',
    cargoSummary: 'Coconut harvest',
    weightKg: 250,
    offeredFeeMinor: 3500,
    currency: 'LKR',
    status: TransportJobStatus.requested,
  ),
  const TransportJobModel(
    id: 'job-2',
    orderId: 'ord-4',
    pickupAddress: 'Nuwara Eliya',
    dropoffAddress: 'Kandy',
    cargoSummary: 'Fresh vegetables',
    weightKg: 80,
    offeredFeeMinor: 5200,
    currency: 'LKR',
    status: TransportJobStatus.requested,
  ),
];
