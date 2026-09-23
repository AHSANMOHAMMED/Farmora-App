import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/features/transporter/application/transporter_controller.dart';
import 'package:farmora/features/transporter/data/mock_collection_job_repository.dart';
import 'package:farmora/features/transporter/domain/collection_job.dart';
import 'package:farmora/features/transporter/presentation/collection_job_details_screen.dart';

void main() {
  Future<void> pumpDetails(
    WidgetTester tester,
    TransporterController controller,
    String jobId,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(home: CollectionJobDetailsScreen(jobId: jobId)),
      ),
    );
    // Advance past the mock repository's simulated network delay; no frames
    // are scheduled while waiting, so pumpAndSettle alone would return early.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  testWidgets('job can be accepted, collected and completed through the UI',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'ui-provider',
    );

    await pumpDetails(tester, controller, '101');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Accept Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept job'));
    await tester.pumpAndSettle();
    expect(controller.jobById('101')?.status, CollectionJobStatus.accepted);

    await tester.tap(find.text('Mark as Collected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark collected'));
    await tester.pumpAndSettle();
    expect(controller.jobById('101')?.status, CollectionJobStatus.collected);

    await tester.tap(find.text('Complete Delivery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete delivery'));
    await tester.pumpAndSettle();

    expect(controller.jobById('101')?.status, CollectionJobStatus.completed);
    expect(controller.completedJobs.any((job) => job.id == '101'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job details screen renders the status timeline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'demo-transporter',
    );

    // An accepted job shows the timeline up to the accepted step.
    await pumpDetails(tester, controller, '090');
    expect(find.text('Job timeline'), findsOneWidget);
    expect(find.text('Job created'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
