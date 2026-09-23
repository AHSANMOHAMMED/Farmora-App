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

  test('open jobs get a suitability score in the valid range', () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
    );
    await _waitForLoad(controller);
    expect(controller.availableJobs, isNotEmpty);

    final first = controller.availableJobs.first;
    final suitability = controller.suitabilityFor(first);
    expect(suitability.score, inInclusiveRange(0, 100));
    expect(suitability.capacityFit, isTrue);
  });

  test('reported issue persists in the repository', () async {
    final repository = MockCollectionJobRepository();
    final controller = TransporterController(
      repository: repository,
      providerId: 'demo-transporter',
    );
    await _waitForLoad(controller);

    final result = await controller.reportIssue(
      jobId: '090',
      reason: 'Vehicle Problem',
      description: 'Flat tyre on the way to pickup.',
    );
    expect(result.success, isTrue);
    expect(controller.hasReportedIssue('090'), isTrue);

    final persisted = await repository.getIssueReport('090');
    expect(persisted, isNotNull);
    expect(persisted!.reason, 'Vehicle Problem');
    expect(persisted.description, 'Flat tyre on the way to pickup.');
  });

  test('delivery rating persists in the repository', () async {
    final repository = MockCollectionJobRepository();
    final controller = TransporterController(
      repository: repository,
      providerId: 'demo-transporter',
    );
    await _waitForLoad(controller);

    final result = await controller.rateDelivery(
      jobId: '075',
      stars: 4,
      comment: 'Smooth delivery',
    );
    expect(result.success, isTrue);
    expect(controller.ratingFor('075')?.stars, 4);

    final persisted = await repository.getDeliveryRating('075');
    expect(persisted, isNotNull);
    expect(persisted!.stars, 4);
    expect(persisted.comment, 'Smooth delivery');
  });

  test('timeline reflects status history for a completed job', () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'demo-transporter',
    );
    await _waitForLoad(controller);

    final completed = controller.jobById('075')!;
    final steps = completed.timeline;
    expect(steps.length, 5);
    expect(steps.map((entry) => entry.step.name), [
      'created',
      'accepted',
      'collected',
      'inTransit',
      'delivered',
    ]);
    expect(
      steps.every((entry) => entry.at != null),
      isTrue,
      reason: 'Completed jobs have every step timestamped',
    );

    // An open job has only the creation step timestamped.
    final open = controller.jobById('101')!;
    expect(
      open.timeline.where((entry) => entry.at != null).length,
      1,
    );
  });

  test('timeline advances when a job transitions through statuses', () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'demo-transporter',
    );
    await _waitForLoad(controller);

    await controller.acceptJob('101');
    final accepted = controller.jobById('101')!;
    expect(accepted.acceptedAt, isNotNull);
    expect(
      accepted.timeline.where((entry) => entry.at != null).length,
      2,
    );

    await controller.markCollected('101');
    await controller.startDelivery('101');
    await controller.completeDelivery('101');
    final completed = controller.jobById('101')!;
    expect(completed.timeline.every((entry) => entry.at != null), isTrue);
  });

  test('search, location, produce and date filters combine', () async {
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
    );
    await _waitForLoad(controller);

    controller.updateSearch('tomato');
    controller.updateLocation('Dambulla');
    controller.updateProduce('Ceylon Tomatoes');

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
