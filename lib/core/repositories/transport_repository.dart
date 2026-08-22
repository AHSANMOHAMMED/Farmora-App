import '../models/transport_job.dart';

/// Abstract interface for transport job operations.
abstract class TransportRepository {
  /// Get transport job by ID
  Future<TransportJobModel?> getJobById(String jobId);

  /// Create transport job request
  Future<TransportJobModel> createJob(TransportJobModel job);

  /// Accept a transport job
  Future<void> acceptJob(String jobId, String transporterId);

  /// Update job status with valid transition
  Future<void> updateJobStatus(String jobId, TransportJobStatus newStatus);

  /// Get available jobs for a transporter's region
  Future<List<TransportJobModel>> getAvailableJobs({
    String? region,
    double? maxWeightKg,
    int limit = 20,
    String? lastDocumentId,
  });

  /// Get jobs assigned to a transporter
  Future<List<TransportJobModel>> getJobsByTransporter(String transporterId);

  /// Stream available jobs for real-time updates
  Stream<List<TransportJobModel>> watchAvailableJobs({String? region});

  /// Stream assigned jobs for real-time updates
  Stream<List<TransportJobModel>> watchJobsByTransporter(String transporterId);

  /// Cancel a job
  Future<void> cancelJob(String jobId);

  /// Validate if a transition is allowed (used for client-side checks;
  /// server-side validation happens in Cloud Functions)
  bool isValidTransition(
      TransportJobStatus current, TransportJobStatus target);
}
