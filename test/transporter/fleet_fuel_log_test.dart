import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/fleet_fuel_log.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';

void main() {
  group('FleetFuelLog Domain Model', () {
    test('calculates fuel efficiency km/L accurately from odometers', () {
      final log = FleetFuelLog(
        id: 'f1',
        vehicleId: 'veh_01',
        vehicleReg: 'WP-NC-1234',
        driverId: 'drv_01',
        driverName: 'Kasun',
        fueledAt: DateTime.now(),
        litersFilled: 80.0,
        costPerLiterLkr: 340.0,
        totalCostLkr: 27200.0,
        fuelStationName: 'Ceypetco Dambulla',
        odometerKm: 50400.0,
        previousOdometerKm: 50000.0,
      );

      // 400 km / 80 L = 5.0 km/L
      expect(log.fuelEfficiencyKmL, 5.0);

      final map = log.toMap();
      expect(map['litersFilled'], 80.0);
      expect(map['costPerLiterLkr'], 340.0);

      final restored = FleetFuelLog.fromMap('f1', map);
      expect(restored.vehicleReg, 'WP-NC-1234');
      expect(restored.fuelEfficiencyKmL, 5.0);
    });

    test('default fuel logs in service layer provide realistic entries', () {
      final logs = LogisticsFleetService.defaultFuelLogs('veh_01');
      expect(logs, isNotEmpty);
      expect(logs.first.litersFilled, greaterThan(0));
      expect(logs.first.totalCostLkr, greaterThan(0));
    });
  });
}
