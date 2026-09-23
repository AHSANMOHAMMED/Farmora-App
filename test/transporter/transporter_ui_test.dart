import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/features/transporter/application/transporter_controller.dart';
import 'package:farmora/features/transporter/data/mock_collection_job_repository.dart';
import 'package:farmora/features/transporter/domain/collection_job.dart';
import 'package:farmora/features/transporter/presentation/logistics_available_jobs_screen.dart';

void main() {
  testWidgets('job can be accepted, collected and completed through the UI',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TransporterController(
      repository: MockCollectionJobRepository(),
      providerId: 'ui-provider',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: LogisticsAvailableJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available Jobs'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final detailsButton = find.text('View details').first;
    await tester.ensureVisible(detailsButton);
    await tester.tap(detailsButton);
    await tester.pumpAndSettle();

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
}
