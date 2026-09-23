import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/data/collection_job_repository.dart';
import 'package:farmora/features/transporter/data/mock_collection_job_repository.dart';
import 'package:farmora/features/transporter/domain/collection_job.dart';

void main() {
  group('MockCollectionJobRepository', () {
    test('accepts an open job only once', () async {
      final repository = MockCollectionJobRepository();

      final accepted = await repository.acceptJob(
        jobId: '101',
        logisticsProviderId: 'provider-a',
      );

      expect(accepted.status, CollectionJobStatus.accepted);
      expect(accepted.logisticsProviderId, 'provider-a');
      expect(
        () => repository.acceptJob(
          jobId: '101',
          logisticsProviderId: 'provider-b',
        ),
        throwsA(isA<CollectionJobException>()),
      );
    });

    test('enforces accepted to collected to completed sequence', () async {
      final repository = MockCollectionJobRepository();
      await repository.acceptJob(
        jobId: '102',
        logisticsProviderId: 'provider-a',
      );

      expect(
        () => repository.updateStatus(
          jobId: '102',
          logisticsProviderId: 'provider-a',
          status: CollectionJobStatus.completed,
        ),
        throwsA(isA<CollectionJobException>()),
      );

      final collected = await repository.updateStatus(
        jobId: '102',
        logisticsProviderId: 'provider-a',
        status: CollectionJobStatus.collected,
      );
      final completed = await repository.updateStatus(
        jobId: '102',
        logisticsProviderId: 'provider-a',
        status: CollectionJobStatus.completed,
      );

      expect(collected.status, CollectionJobStatus.collected);
      expect(completed.status, CollectionJobStatus.completed);
      expect(completed.completedAt, isNotNull);
    });
  });
}
