import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/logistics_branch.dart';
import 'package:farmora/features/transporter/domain/logistics_vehicle.dart';
import 'package:farmora/features/transporter/domain/fleet_driver_info.dart';
import 'package:farmora/features/transporter/presentation/widgets/hub_cold_storage_card.dart';
import 'package:farmora/features/transporter/presentation/widgets/vehicle_maintenance_sheet.dart';
import 'package:farmora/features/transporter/presentation/widgets/driver_shift_log_sheet.dart';
import 'package:farmora/features/transporter/presentation/widgets/emergency_breakdown_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBranch = LogisticsBranch(
    id: 'br_test_01',
    transporterId: 'tr_01',
    name: 'Dambulla Test Hub',
    district: 'Matale',
    address: 'A9 Highway Junction',
    latitude: 7.8742,
    longitude: 80.6511,
    managerName: 'Sunil Perera',
    managerPhone: '0771234567',
    hasColdStorage: true,
    storageCapacityTons: 120.0,
  );

  final testVehicle = LogisticsVehicle(
    id: 'veh_test_01',
    transporterId: 'tr_01',
    registrationNumber: 'WP-NC-9988',
    vehicleType: 'refrigerated_truck',
    modelName: 'Isuzu Elf Cold Box',
    capacityKg: 4500.0,
    isRefrigerated: true,
  );

  final testDriver = FleetDriverInfo(
    id: 'drv_test_01',
    transporterId: 'tr_01',
    name: 'Kasun Test Driver',
    phone: '0712345678',
    licenseNumber: 'B-1234567',
  );

  group('Logistics Fleet Hub Widgets', () {
    testWidgets('HubColdStorageCard renders chamber telemetry correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HubColdStorageCard(branch: testBranch),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Depot Cold Storage Telemetry'), findsOneWidget);
      expect(find.textContaining('120T Cap'), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);
    });

    testWidgets('VehicleMaintenanceSheet shows vehicle details and log button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleMaintenanceSheet(vehicle: testVehicle),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fleet Maintenance Logs'), findsOneWidget);
      expect(find.textContaining('WP-NC-9988'), findsOneWidget);
      expect(find.text('Log Maintenance Event'), findsOneWidget);
    });

    testWidgets('DriverShiftLogSheet displays driver duty hours and check-in',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverShiftLogSheet(driver: testDriver),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Driver Shifts & Duty Hours'), findsOneWidget);
      expect(find.textContaining('Kasun Test Driver'), findsOneWidget);
      expect(find.text('Start / Check-in New Shift'), findsOneWidget);
    });

    testWidgets('EmergencyBreakdownDialog renders roadside alert and dispatch button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyBreakdownDialog(
              transporterId: 'tr_01',
              vehicles: [testVehicle],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Roadside Breakdown Alert'), findsOneWidget);
      expect(find.text('Stranded Vehicle'), findsOneWidget);
      expect(find.text('Broadcast Alert'), findsOneWidget);
    });
  });
}
