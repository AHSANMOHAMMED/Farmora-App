import '../domain/collection_job.dart';

class CollectionJobException implements Exception {
  final String message;
  const CollectionJobException(this.message);

  @override
  String toString() => message;
}

/// An issue reported by a transporter for an active job.
class JobIssueReport {
  final String jobId;
  final String logisticsProviderId;
  final String reason;
  final String description;
  final DateTime reportedAt;

  const JobIssueReport({
    required this.jobId,
    required this.logisticsProviderId,
    required this.reason,
    this.description = '',
    required this.reportedAt,
  });
}

/// A transporter's rating for a completed delivery.
class JobDeliveryRating {
  final String jobId;
  final String logisticsProviderId;
  final int stars;
  final String comment;
  final DateTime ratedAt;

  const JobDeliveryRating({
    required this.jobId,
    required this.logisticsProviderId,
    required this.stars,
    this.comment = '',
    required this.ratedAt,
  });
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

  /// Persists an issue report for [jobId] so it survives app restarts.
  Future<void> reportIssue({
    required String jobId,
    required String logisticsProviderId,
    required String reason,
    String description = '',
  });

  /// Persists a delivery rating for [jobId] so it survives app restarts.
  Future<void> rateDelivery({
    required String jobId,
    required String logisticsProviderId,
    required int stars,
    String comment = '',
  });

  /// Returns the persisted issue report for [jobId], if any.
  Future<JobIssueReport?> getIssueReport(String jobId);

  /// Returns the persisted delivery rating for [jobId], if any.
  Future<JobDeliveryRating?> getDeliveryRating(String jobId);
}
