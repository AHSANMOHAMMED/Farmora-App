import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/hub_cold_storage_log.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';

void main() {
  group('HubColdStorageLog Domain Model', () {
    test('accurately identifies temperature breach and safe ranges', () {
      final normalLog = HubColdStorageLog(
        id: 'cs_1',
        branchId: 'branch_dambulla',
        branchName: 'Dambulla Central Hub',
        roomName: 'Chamber A - Leafy Greens',
        currentTempC: 4.2,
        targetTempC: 4.0,
        minSafeTempC: 2.0,
        maxSafeTempC: 6.0,
        relativeHumidityPercent: 88.0,
        recordedAt: DateTime.now(),
        isBreached: false,
      );

      expect(normalLog.isTempNormal, isTrue);
      expect(normalLog.isBreached, isFalse);

      final map = normalLog.toMap();
      expect(map['currentTempC'], 4.2);
      expect(map['relativeHumidityPercent'], 88.0);

      // Deserializing with breach temp
      final breachMap = Map<String, dynamic>.from(map);
      breachMap['currentTempC'] = 9.5;
      final breachLog = HubColdStorageLog.fromMap('cs_2', breachMap);
      expect(breachLog.isTempNormal, isFalse);
      expect(breachLog.isBreached, isTrue);
    });

    test('default cold storage telemetry provided by service layer', () {
      final logs = LogisticsFleetService.defaultColdStorageLogs('branch_dambulla');
      expect(logs, isNotEmpty);
      expect(logs.first.roomName, isNotEmpty);
      expect(logs.first.currentTempC, greaterThan(0));
    });
  });
}
