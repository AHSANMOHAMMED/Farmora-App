import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/driver_shift_record.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';

void main() {
  group('DriverShiftRecord Domain Model', () {
    test('serializes and deserializes driver shift records correctly', () {
      final now = DateTime.now();
      final shift = DriverShiftRecord(
        id: 'shift_101',
        driverId: 'drv_01',
        driverName: 'Kasun Bandara',
        branchId: 'branch_dambulla',
        branchName: 'Dambulla Hub',
        assignedVehicleId: 'veh_01',
        assignedVehicleReg: 'WP-NC-1234',
        checkInTime: now,
        drivingHours: 4.5,
        restHours: 1.0,
        completedTripsCount: 2,
        status: 'active',
        notes: 'Shift running smoothly on A9 corridor',
      );

      expect(shift.isActive, isTrue);
      expect(shift.isOnBreak, isFalse);
      expect(shift.isCompleted, isFalse);

      final map = shift.toMap();
      expect(map['driverName'], 'Kasun Bandara');
      expect(map['drivingHours'], 4.5);
      expect(map['status'], 'active');

      final restored = DriverShiftRecord.fromMap('shift_101', map);
      expect(restored.driverId, 'drv_01');
      expect(restored.branchName, 'Dambulla Hub');
      expect(restored.drivingHours, 4.5);
      expect(restored.isActive, isTrue);
    });

    test('verifies default driver shifts from service layer', () {
      final shifts = LogisticsFleetService.defaultDriverShifts('drv_01');
      expect(shifts, isNotEmpty);
      expect(shifts.any((s) => s.isActive), isTrue);
      expect(shifts.first.driverName, isNotEmpty);
    });
  });
}
