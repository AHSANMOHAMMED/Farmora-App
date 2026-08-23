import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transport_job.dart';
import '../../../core/repositories/transport_repository.dart';

final availableJobsProvider = FutureProvider<List<TransportJobModel>>((ref) async {
  final repository = ref.watch(transportRepositoryProvider);
  return await repository.getAvailableJobs();
});
