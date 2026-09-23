import '../domain/collection_job.dart';

class CollectionJobException implements Exception {
  final String message;
  const CollectionJobException(this.message);

  @override
  String toString() => message;
}

abstract interface class CollectionJobRepository {
  Stream<List<CollectionJob>> watchJobs(String logisticsProviderId);

  Future<List<CollectionJob>> getJobs(String logisticsProviderId);

  Future<CollectionJob> getJob(String id);

  Future<CollectionJob> acceptJob({
    required String jobId,
    required String logisticsProviderId,
  });

  Future<CollectionJob> updateStatus({
    required String jobId,
    required String logisticsProviderId,
    required CollectionJobStatus status,
    String? reason,
  });
}
