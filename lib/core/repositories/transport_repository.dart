import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transport_job.dart';

abstract class TransportRepository {
  Future<List<TransportJobModel>> getAvailableJobs();
  Future<List<TransportJobModel>> getTransporterJobs(String transporterId);
  Future<void> acceptJob(String jobId, String transporterId);
  Future<void> updateJobStatus(String jobId, TransportJobStatus status);
}

class MockTransportRepository implements TransportRepository {
  final List<TransportJobModel> _jobs = [];

  MockTransportRepository() {
    _jobs.addAll([
      TransportJobModel(
        id: 'job-1',
        orderId: 'ord-1',
        pickupAddress: 'Nuwara Eliya',
        dropoffAddress: 'Colombo',
        cargoSummary: '50kg Tomatoes',
        weightKg: 50.0,
        offeredFeeMinor: 250000,
        status: TransportJobStatus.requested,
        requestedAt: DateTime.now(),
      ),
      TransportJobModel(
        id: 'job-2',
        orderId: 'ord-2',
        pickupAddress: 'Matale',
        dropoffAddress: 'Kandy',
        cargoSummary: '20kg Carrots',
        weightKg: 20.0,
        offeredFeeMinor: 80000,
        status: TransportJobStatus.requested,
        requestedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<List<TransportJobModel>> getAvailableJobs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _jobs.where((j) => j.status == TransportJobStatus.requested).toList();
  }

  @override
  Future<List<TransportJobModel>> getTransporterJobs(String transporterId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _jobs.where((j) => j.transporterId == transporterId).toList();
  }

  @override
  Future<void> acceptJob(String jobId, String transporterId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final j = _jobs[index];
      _jobs[index] = TransportJobModel(
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
  }

  @override
  Future<void> updateJobStatus(String jobId, TransportJobStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final j = _jobs[index];
      _jobs[index] = TransportJobModel(
        id: j.id,
        orderId: j.orderId,
        pickupAddress: j.pickupAddress,
        dropoffAddress: j.dropoffAddress,
        cargoSummary: j.cargoSummary,
        weightKg: j.weightKg,
        offeredFeeMinor: j.offeredFeeMinor,
        currency: j.currency,
        status: status,
        transporterId: j.transporterId,
        requestedAt: j.requestedAt,
        acceptedAt: j.acceptedAt,
        pickedUpAt: status == TransportJobStatus.pickedUp ? DateTime.now() : j.pickedUpAt,
        inTransitAt: status == TransportJobStatus.inTransit ? DateTime.now() : j.inTransitAt,
        deliveredAt: status == TransportJobStatus.delivered ? DateTime.now() : j.deliveredAt,
        cancelledAt: status == TransportJobStatus.cancelled ? DateTime.now() : j.cancelledAt,
      );
    }
  }
}

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return MockTransportRepository();
});
