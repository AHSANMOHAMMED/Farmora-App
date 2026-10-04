import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/domain/logistics_vehicle.dart';
import 'package:farmora/features/transporter/domain/logistics_branch.dart';
import 'package:farmora/features/transporter/domain/fleet_driver_info.dart';
import 'package:farmora/features/transporter/data/logistics_fleet_service.dart';
import 'package:farmora/models/transport_job.dart';

void main() {
  group('LogisticsVehicle Domain Model', () {
    test('serialization to and from Map preserves all fields', () {
      final now = DateTime(2026, 9, 30, 10, 0, 0);
      final vehicle = LogisticsVehicle(
        id: 'veh_01',
        transporterId: 'trans_01',
        registrationNumber: 'WP-NC-1234',
        vehicleType: 'Heavy Lorry',
        modelName: 'Isuzu Forward 10T',
        capacityKg: 10000,
        isRefrigerated: true,
        status: 'available',
        stationedBranchId: 'br_colombo',
        stationedBranchName: 'Colombo Central Depot',
        assignedDriverId: 'dr_01',
        assignedDriverName: 'Kamal Perera',
        currentLat: 6.9271,
        currentLng: 79.8612,
        updatedAt: now,
      );

      final map = vehicle.toMap();
      expect(map['registrationNumber'], 'WP-NC-1234');
      expect(map['isRefrigerated'], isTrue);
      expect(map['capacityKg'], 10000.0);

      final deserialized = LogisticsVehicle.fromMap('veh_01', map);
      expect(deserialized.id, 'veh_01');
      expect(deserialized.modelName, 'Isuzu Forward 10T');
      expect(deserialized.capacityTons, 10.0);
      expect(deserialized.branchName, 'Colombo Central Depot');
      expect(deserialized.isAvailable, isTrue);
      expect(deserialized.isOnTrip, isFalse);
    });

    test('copyWith updates state correctly', () {
      const vehicle = LogisticsVehicle(
        id: 'v1',
        transporterId: 't1',
        registrationNumber: 'SP-AB-5678',
        vehicleType: 'Mini Truck',
        modelName: 'Tata Ace',
        capacityKg: 1500,
      );

      final dispatched = vehicle.copyWith(
        status: 'on_trip',
        assignedDriverName: 'Saman Kumara',
      );
      expect(dispatched.isOnTrip, isTrue);
      expect(dispatched.isAvailable, isFalse);
      expect(dispatched.assignedDriverName, 'Saman Kumara');
      expect(dispatched.registrationNumber, 'SP-AB-5678');
    });
  });

  group('LogisticsBranch Domain Model', () {
    test('serialization and getters work properly', () {
      final now = DateTime(2026, 9, 30, 12, 0, 0);
      final branch = LogisticsBranch(
        id: 'br_dambulla',
        transporterId: 't1',
        name: 'Dambulla Agro Exchange Hub',
        district: 'Matale',
        address: 'Economic Center Rd, Dambulla',
        latitude: 7.8683,
        longitude: 80.6528,
        managerName: 'Sunil Silva',
        managerPhone: '0712345678',
        hasColdStorage: true,
        storageCapacityTons: 250.0,
        vehicleCount: 6,
        driverCount: 5,
        updatedAt: now,
      );

      final map = branch.toMap();
      expect(map['name'], 'Dambulla Agro Exchange Hub');
      expect(map['hasColdStorage'], isTrue);

      final restored = LogisticsBranch.fromMap('br_dambulla', map);
      expect(restored.district, 'Matale');
      expect(restored.latitude, 7.8683);
      expect(restored.longitude, 80.6528);
      expect(restored.storageCapacityTons, 250.0);
    });
  });

  group('FleetDriverInfo Domain Model', () {
    test('serialization and getters work properly', () {
      final driver = FleetDriverInfo(
        id: 'dr_01',
        transporterId: 't1',
        name: 'Rohan Jayasuriya',
        phone: '0771234567',
        licenseNumber: 'B-8899221',
        licenseClass: 'Heavy Vehicle (Class C/C1)',
        status: 'available',
        stationedBranchName: 'Colombo Central Depot',
        rating: 4.9,
      );

      final map = driver.toMap();
      expect(map['licenseNumber'], 'B-8899221');
      expect(map['rating'], 4.9);

      final restored = FleetDriverInfo.fromMap('dr_01', map);
      expect(restored.name, 'Rohan Jayasuriya');
      expect(restored.branchName, 'Colombo Central Depot');
      expect(restored.isAvailable, isTrue);
      expect(restored.isOnTrip, isFalse);
    });
  });

  group('LogisticsFleetService Seed Defaults', () {
    test('default branches provide 5 major regional hubs across Sri Lanka', () {
      final branches = LogisticsFleetService.defaultBranches('test_transporter');
      expect(branches.length, 5);
      expect(branches.map((b) => b.district), containsAll(['Colombo', 'Matale', 'Kandy', 'Jaffna', 'Puttalam']));
    });

    test('default vehicles provide diverse fleet with cold chain capability', () {
      final vehicles = LogisticsFleetService.defaultVehicles('test_transporter');
      expect(vehicles.length, 5);
      expect(vehicles.any((v) => v.isRefrigerated), isTrue);
      expect(vehicles.any((v) => v.vehicleType == 'refrigerated_truck'), isTrue);
    });

    test('default drivers provide certified driver roster', () {
      final drivers = LogisticsFleetService.defaultDrivers('test_transporter');
      expect(drivers.length, 5);
      expect(drivers.every((d) => d.phone.isNotEmpty), isTrue);
      expect(drivers.every((d) => d.licenseNumber.isNotEmpty), isTrue);
    });
  });

  group('TransportJob Fleet & Driver Allocation', () {
    test('toMap and fromMap preserve fleet assignment fields', () {
      final job = TransportJob.fromMap('tj_01', {
        'title': 'Carrots Delivery',
        'route': 'Nuwara Eliya -> Colombo',
        'status': 'accepted',
        'vehicleId': 'veh_reefer_01',
        'vehicleReg': 'WP-ND-8921',
        'vehicleType': 'Cold-Chain Reefer Truck',
        'driverId': 'dr_02',
        'driverName': 'Suresh Weerakkody',
      });

      expect(job.vehicleId, 'veh_reefer_01');
      expect(job.vehicleReg, 'WP-ND-8921');
      expect(job.vehicleType, 'Cold-Chain Reefer Truck');
      expect(job.driverId, 'dr_02');
      expect(job.driverName, 'Suresh Weerakkody');

      final map = job.toMap();
      expect(map['vehicleId'], 'veh_reefer_01');
      expect(map['vehicleReg'], 'WP-ND-8921');
      expect(map['vehicleType'], 'Cold-Chain Reefer Truck');
      expect(map['driverId'], 'dr_02');
      expect(map['driverName'], 'Suresh Weerakkody');
    });
  });
}
