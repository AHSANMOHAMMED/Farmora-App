import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/application/transporter_controller.dart';
import 'package:farmora/features/transporter/data/mock_collection_job_repository.dart';
import 'package:farmora/features/transporter/domain/collection_job.dart';

void main() {
  test('accepted job moves through active jobs into completed history',
      () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'test-provider',
    );
    await _waitForLoad(controller);
    final initialAvailableCount = controller.unfilteredAvailableJobs.length;

    final accepted = await controller.acceptJob('101');
    expect(accepted.success, isTrue);
    expect(
        controller.unfilteredAvailableJobs.length, initialAvailableCount - 1);
    expect(controller.jobById('101')?.status, CollectionJobStatus.accepted);
    expect(controller.activeJobs.any((job) => job.id == '101'), isTrue);

    final collected = await controller.markCollected('101');
    expect(collected.success, isTrue);
    expect(controller.jobById('101')?.status, CollectionJobStatus.collected);

    final completed = await controller.completeDelivery('101');
    expect(completed.success, isTrue);
    expect(controller.activeJobs.any((job) => job.id == '101'), isFalse);
    expect(controller.completedJobs.any((job) => job.id == '101'), isTrue);
    expect(controller.notifications.first.jobId, '101');
  });

  test('search, location, produce and date filters combine', () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
    );
    await _waitForLoad(controller);
    final target = controller.jobById('101')!;

    controller.updateSearch('tomato');
    controller.updateLocation('Dambulla');
    controller.updateProduce('Ceylon Tomatoes');
    controller.updateDate(target.collectionDate);

    expect(controller.availableJobs.map((job) => job.id), ['101']);
    controller.updateSearch('onion');
    expect(controller.availableJobs, isEmpty);
  });
}

Future<void> _waitForLoad(TransporterController controller) async {
  for (var attempt = 0; attempt < 20 && controller.isLoading; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  expect(controller.isLoading, isFalse);
  expect(controller.loadError, isNull);
}
