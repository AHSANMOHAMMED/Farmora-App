import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/fleet_breakdown_request.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';

void main() {
  group('FleetBreakdownRequest Domain Model', () {
    test('serializes and deserializes emergency roadside breakdown requests', () {
      final now = DateTime.now();
      final breakdown = FleetBreakdownRequest(
        id: 'bd_101',
        vehicleId: 'veh_01',
        vehicleReg: 'WP-NC-1234',
        driverId: 'drv_01',
        driverName: 'Kasun Bandara',
        driverPhone: '0771234567',
        latitude: 7.5500,
        longitude: 80.4000,
        locationDescription: 'Near Kurunegala Bypass on A6',
        failureType: 'cooling_failure',
        severity: 'critical_cargo_rescue',
        status: 'reported',
        reportedAt: now,
        notes: 'Chilled tomato load at risk of spoilage',
      );

      expect(breakdown.isCritical, isTrue);
      expect(breakdown.isResolved, isFalse);

      final map = breakdown.toMap();
      expect(map['failureType'], 'cooling_failure');
      expect(map['severity'], 'critical_cargo_rescue');
      expect(map['locationDescription'], 'Near Kurunegala Bypass on A6');

      final restored = FleetBreakdownRequest.fromMap('bd_101', map);
      expect(restored.vehicleReg, 'WP-NC-1234');
      expect(restored.isCritical, isTrue);
      expect(restored.driverPhone, '0771234567');
    });

    test('retrieves default breakdown reports from fleet service layer', () {
      final breakdowns = LogisticsFleetService.defaultBreakdownRequests('transporter_01');
      expect(breakdowns, isNotEmpty);
      expect(breakdowns.first.locationDescription, isNotEmpty);
      expect(breakdowns.first.driverName, isNotEmpty);
    });
  });
}
