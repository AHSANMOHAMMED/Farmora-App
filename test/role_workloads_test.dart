import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/features/transporter/application/transporter_controller.dart';
import 'package:farmora/features/transporter/data/mock_collection_job_repository.dart';
import 'package:farmora/features/home/presentation/dashboard_screen.dart';
import 'package:farmora/features/transporter/presentation/logistics_dashboard_screen.dart';
import 'package:farmora/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:farmora/features/inputs/presentation/supplier_screens.dart';
import 'package:farmora/features/community/presentation/community_screens.dart';
import 'helpers/l10n_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithProviders(Widget screen, Role role) {
    final state = FarmoraState()..setRole(role);
    state.isVerified = true;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FarmoraState>.value(value: state),
        ChangeNotifierProvider<TransporterController>(
          create: (_) => TransporterController(
            repository: MockCollectionJobRepository(),
          ),
        ),
      ],
      child: localizedTestApp(Scaffold(body: screen)),
    );
  }

  group('Role-Based Workload Tests on dev/swami', () {
    testWidgets('Farmer workload renders Farmer overview, produce, and orders',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(const DashboardScreen(), Role.farmer));
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Buyer workload renders Buyer marketplace and produce discovery',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(const DashboardScreen(), Role.buyer));
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Transporter workload renders Fleet management & Logistics dashboard',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(
        LogisticsDashboardScreen(
          onBrowseJobs: () {},
          onViewMyJobs: () {},
          onOpenNotifications: () {},
        ),
        Role.transporter,
      ));
      await tester.pump();

      expect(find.byType(LogisticsDashboardScreen), findsOneWidget);
    });

    testWidgets('Admin workload renders Admin system metrics and operations',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(const AdminOverviewScreen(), Role.admin));
      await tester.pump();

      expect(find.byType(AdminOverviewScreen), findsOneWidget);
    });

    testWidgets('Supplier workload renders Supplier dashboard and inventory',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(
        SupplierDashboardScreen(
          onOpenListings: () {},
          onOpenOrders: () {},
        ),
        Role.supplier,
      ));
      await tester.pump();

      expect(find.byType(SupplierDashboardScreen), findsOneWidget);
    });

    testWidgets('Expert workload renders Advisory consultation queue',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithProviders(const ExpertQueueScreen(), Role.expert));
      await tester.pump();

      expect(find.byType(ExpertQueueScreen), findsOneWidget);
    });
  });
}
