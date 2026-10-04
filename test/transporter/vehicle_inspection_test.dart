import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/vehicle_inspection_log.dart';

void main() {
  group('VehicleInspectionLog Domain Model', () {
    test('serialization and check passes work as expected', () {
      final now = DateTime(2026, 9, 29, 6, 0);
      final log = VehicleInspectionLog(
        id: 'insp_01',
        vehicleId: 'veh_01',
        vehicleReg: 'WP-NC-1234',
        inspectorId: 'drv_01',
        inspectorName: 'Kasun Rajapaksha',
        inspectionDate: now,
        tireConditionPassed: true,
        brakesPassed: true,
        engineOilPassed: true,
        reeferCoolingPassed: true,
        lightingPassed: true,
        emergencyKitPresent: true,
        passedAllChecks: true,
        notes: 'Vehicle ready for long distance trip to Jaffna',
      );

      final map = log.toMap();
      expect(map['vehicleReg'], 'WP-NC-1234');
      expect(map['passedAllChecks'], isTrue);
      expect(map['reeferCoolingPassed'], isTrue);

      final restored = VehicleInspectionLog.fromMap('insp_01', map);
      expect(restored.inspectorName, 'Kasun Rajapaksha');
      expect(restored.tireConditionPassed, isTrue);
      expect(restored.brakesPassed, isTrue);
      expect(restored.notes, contains('Jaffna'));
    });
  });
}
