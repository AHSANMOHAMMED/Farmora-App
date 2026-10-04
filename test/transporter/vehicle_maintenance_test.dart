import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/vehicle_maintenance_record.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';

void main() {
  group('VehicleMaintenanceRecord Domain Model', () {
    test('serialization round-trip preserves all service data', () {
      final now = DateTime(2026, 9, 28, 9, 30);
      final record = VehicleMaintenanceRecord(
        id: 'rec_01',
        vehicleId: 'veh_01',
        vehicleReg: 'WP-NC-1234',
        serviceType: 'oil_change',
        garageName: 'Dimo Lanka Commercial Workshop',
        costLkr: 32000.0,
        serviceDate: now,
        odometerKm: 45000.0,
        nextServiceDueDate: now.add(const Duration(days: 90)),
        nextServiceOdometerKm: 50000.0,
        notes: 'Full synthetic 15W-40, new oil & fuel filters',
        isCompleted: true,
      );

      final map = record.toMap();
      expect(map['serviceType'], 'oil_change');
      expect(map['costLkr'], 32000.0);
      expect(map['odometerKm'], 45000.0);

      final restored = VehicleMaintenanceRecord.fromMap('rec_01', map);
      expect(restored.id, 'rec_01');
      expect(restored.vehicleReg, 'WP-NC-1234');
      expect(restored.serviceTypeDisplayName, 'Engine Oil & Filter Change');
      expect(restored.nextServiceOdometerKm, 50000.0);
      expect(restored.isCompleted, isTrue);
    });

    test('default maintenance records seed valid data for vehicles', () {
      final records = LogisticsFleetService.defaultMaintenanceRecords('veh_test');
      expect(records, isNotEmpty);
      expect(records.every((r) => r.costLkr > 0), isTrue);
      expect(records.any((r) => r.serviceType == 'oil_change'), isTrue);
    });
  });
}
