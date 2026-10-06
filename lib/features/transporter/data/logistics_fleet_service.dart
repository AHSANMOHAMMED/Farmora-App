import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../domain/logistics_vehicle.dart';
import '../domain/logistics_branch.dart';
import '../domain/fleet_driver_info.dart';
import '../domain/vehicle_maintenance_record.dart';
import '../domain/fleet_fuel_log.dart';
import '../domain/driver_shift_record.dart';
import '../domain/hub_cold_storage_log.dart';
import '../domain/fleet_breakdown_request.dart';

class LogisticsFleetService {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;

  LogisticsFleetService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _explicitFirestore = firestore,
        _explicitAuth = auth;

  bool get _hasFirebase =>
      _explicitFirestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore =>
      _explicitFirestore ?? (_hasFirebase ? FirebaseFirestore.instance : null);

  FirebaseAuth? get _auth =>
      _explicitAuth ?? (_hasFirebase ? FirebaseAuth.instance : null);

  String? get currentTransporterId => _auth?.currentUser?.uid;

  // ─── SEED DATA FOR DEMO & INSTANT USABILITY ──────────────────────────

  static List<LogisticsBranch> defaultBranches(String transporterId) => [
        LogisticsBranch(
          id: 'br_colombo_central',
          transporterId: transporterId,
          name: 'Colombo Central Logistics Depot',
          district: 'Colombo',
          address: '142 Baseline Road, Orugodawatta, Colombo 09',
          latitude: 6.9407,
          longitude: 79.8828,
          managerName: 'Sunil Weerasinghe',
          managerPhone: '0771234567',
          hasColdStorage: true,
          storageCapacityTons: 120.0,
          vehicleCount: 4,
          driverCount: 4,
          updatedAt: DateTime.now(),
        ),
        LogisticsBranch(
          id: 'br_dambulla_hub',
          transporterId: transporterId,
          name: 'Dambulla Agro Exchange Hub',
          district: 'Matale',
          address: 'Dedicated Economic Center Road, Dambulla',
          latitude: 7.8683,
          longitude: 80.6528,
          managerName: 'Kamal Bandara',
          managerPhone: '0719876543',
          hasColdStorage: true,
          storageCapacityTons: 250.0,
          vehicleCount: 6,
          driverCount: 5,
          updatedAt: DateTime.now(),
        ),
        LogisticsBranch(
          id: 'br_kandy_station',
          transporterId: transporterId,
          name: 'Kandy Hill Country Transit Station',
          district: 'Kandy',
          address: '58 William Gopallawa Mawatha, Kandy',
          latitude: 7.2885,
          longitude: 80.6278,
          managerName: 'Nimal Perera',
          managerPhone: '0764567890',
          hasColdStorage: false,
          storageCapacityTons: 60.0,
          vehicleCount: 3,
          driverCount: 3,
          updatedAt: DateTime.now(),
        ),
        LogisticsBranch(
          id: 'br_jaffna_depot',
          transporterId: transporterId,
          name: 'Jaffna Northern Freight Depot',
          district: 'Jaffna',
          address: '88 Kandy Road, Chunnakam, Jaffna',
          latitude: 9.6842,
          longitude: 80.0234,
          managerName: 'S. Thevarajah',
          managerPhone: '0753344556',
          hasColdStorage: true,
          storageCapacityTons: 90.0,
          vehicleCount: 2,
          driverCount: 2,
          updatedAt: DateTime.now(),
        ),
        LogisticsBranch(
          id: 'br_puttalam_hub',
          transporterId: transporterId,
          name: 'Puttalam Coastal Logistics Hub',
          district: 'Puttalam',
          address: 'Kurunegala Road, Puttalam',
          latitude: 8.0333,
          longitude: 79.8333,
          managerName: 'R. Mohamed Farook',
          managerPhone: '0778899001',
          hasColdStorage: false,
          storageCapacityTons: 80.0,
          vehicleCount: 3,
          driverCount: 3,
          updatedAt: DateTime.now(),
        ),
      ];

  static List<LogisticsVehicle> defaultVehicles(String transporterId) => [
        LogisticsVehicle(
          id: 'veh_01',
          transporterId: transporterId,
          registrationNumber: 'WP-NA-4512',
          vehicleType: 'refrigerated_truck',
          modelName: 'Isuzu Elf Cold Box 4.2T',
          capacityKg: 4200,
          isRefrigerated: true,
          status: 'available',
          stationedBranchId: 'br_dambulla_hub',
          stationedBranchName: 'Dambulla Agro Exchange Hub',
          assignedDriverId: 'drv_01',
          assignedDriverName: 'Kasun Rajapaksha',
          currentLat: 7.8742,
          currentLng: 80.6511,
          updatedAt: DateTime.now(),
        ),
        LogisticsVehicle(
          id: 'veh_02',
          transporterId: transporterId,
          registrationNumber: 'CP-LG-8890',
          vehicleType: 'heavy_lorry',
          modelName: 'Mitsubishi Fuso Canter 6.5T',
          capacityKg: 6500,
          isRefrigerated: false,
          status: 'on_trip',
          stationedBranchId: 'br_kandy_station',
          stationedBranchName: 'Kandy Hill Country Transit Station',
          assignedDriverId: 'drv_02',
          assignedDriverName: 'Ruwan Wijesinghe',
          currentLat: 7.2906,
          currentLng: 80.6337,
          updatedAt: DateTime.now(),
        ),
        LogisticsVehicle(
          id: 'veh_03',
          transporterId: transporterId,
          registrationNumber: 'WP-DA-3201',
          vehicleType: 'mini_truck',
          modelName: 'Tata Ace Super Power 1.5T',
          capacityKg: 1500,
          isRefrigerated: false,
          status: 'available',
          stationedBranchId: 'br_colombo_central',
          stationedBranchName: 'Colombo Central Logistics Depot',
          assignedDriverId: 'drv_03',
          assignedDriverName: 'Dilshan Silva',
          currentLat: 6.9271,
          currentLng: 79.8612,
          updatedAt: DateTime.now(),
        ),
        LogisticsVehicle(
          id: 'veh_04',
          transporterId: transporterId,
          registrationNumber: 'NP-QA-7721',
          vehicleType: 'refrigerated_truck',
          modelName: 'Hino 300 Reefer 5.0T',
          capacityKg: 5000,
          isRefrigerated: true,
          status: 'available',
          stationedBranchId: 'br_jaffna_depot',
          stationedBranchName: 'Jaffna Northern Freight Depot',
          assignedDriverId: 'drv_04',
          assignedDriverName: 'V. Sivakumar',
          currentLat: 9.6615,
          currentLng: 80.0255,
          updatedAt: DateTime.now(),
        ),
        LogisticsVehicle(
          id: 'veh_05',
          transporterId: transporterId,
          registrationNumber: 'NW-LB-6119',
          vehicleType: 'pickup_van',
          modelName: 'Mahindra Bolero Maxi Truck',
          capacityKg: 1800,
          isRefrigerated: false,
          status: 'available',
          stationedBranchId: 'br_puttalam_hub',
          stationedBranchName: 'Puttalam Coastal Logistics Hub',
          assignedDriverId: 'drv_05',
          assignedDriverName: 'A. R. M. Nifras',
          currentLat: 8.0333,
          currentLng: 79.8333,
          updatedAt: DateTime.now(),
        ),
      ];

  static List<FleetDriverInfo> defaultDrivers(String transporterId) => [
        FleetDriverInfo(
          id: 'drv_01',
          transporterId: transporterId,
          name: 'Kasun Rajapaksha',
          phone: '0772345678',
          licenseNumber: 'B-7489123',
          licenseClass: 'Heavy Commercial Vehicle (Class C)',
          status: 'available',
          assignedVehicleId: 'veh_01',
          assignedVehicleReg: 'WP-NA-4512',
          stationedBranchId: 'br_dambulla_hub',
          stationedBranchName: 'Dambulla Agro Exchange Hub',
          currentLat: 7.8742,
          currentLng: 80.6511,
          rating: 4.9,
          updatedAt: DateTime.now(),
        ),
        FleetDriverInfo(
          id: 'drv_02',
          transporterId: transporterId,
          name: 'Ruwan Wijesinghe',
          phone: '0715678901',
          licenseNumber: 'B-8921456',
          licenseClass: 'Heavy Commercial Vehicle (Class C1)',
          status: 'on_trip',
          assignedVehicleId: 'veh_02',
          assignedVehicleReg: 'CP-LG-8890',
          stationedBranchId: 'br_kandy_station',
          stationedBranchName: 'Kandy Hill Country Transit Station',
          currentLat: 7.2906,
          currentLng: 80.6337,
          rating: 4.8,
          updatedAt: DateTime.now(),
        ),
        FleetDriverInfo(
          id: 'drv_03',
          transporterId: transporterId,
          name: 'Dilshan Silva',
          phone: '0761239874',
          licenseNumber: 'B-6192840',
          licenseClass: 'Light Commercial Vehicle (Class B)',
          status: 'available',
          assignedVehicleId: 'veh_03',
          assignedVehicleReg: 'WP-DA-3201',
          stationedBranchId: 'br_colombo_central',
          stationedBranchName: 'Colombo Central Logistics Depot',
          currentLat: 6.9271,
          currentLng: 79.8612,
          rating: 4.7,
          updatedAt: DateTime.now(),
        ),
        FleetDriverInfo(
          id: 'drv_04',
          transporterId: transporterId,
          name: 'V. Sivakumar',
          phone: '0758921345',
          licenseNumber: 'B-5289104',
          licenseClass: 'Heavy Commercial Vehicle (Class C)',
          status: 'available',
          assignedVehicleId: 'veh_04',
          assignedVehicleReg: 'NP-QA-7721',
          stationedBranchId: 'br_jaffna_depot',
          stationedBranchName: 'Jaffna Northern Freight Depot',
          currentLat: 9.6615,
          currentLng: 80.0255,
          rating: 5.0,
          updatedAt: DateTime.now(),
        ),
        FleetDriverInfo(
          id: 'drv_05',
          transporterId: transporterId,
          name: 'A. R. M. Nifras',
          phone: '0776541289',
          licenseNumber: 'B-3498125',
          licenseClass: 'Dual Purpose Commercial (Class B)',
          status: 'available',
          assignedVehicleId: 'veh_05',
          assignedVehicleReg: 'NW-LB-6119',
          stationedBranchId: 'br_puttalam_hub',
          stationedBranchName: 'Puttalam Coastal Logistics Hub',
          currentLat: 8.0333,
          currentLng: 79.8333,
          rating: 4.9,
          updatedAt: DateTime.now(),
        ),
      ];

  // ─── VEHICLE OPERATIONS ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? _vehicleCol(String tid) =>
      _firestore?.collection('transporters').doc(tid).collection('vehicles');

  Stream<List<LogisticsVehicle>> streamVehicles(String transporterId) {
    final tid = transporterId.isEmpty ? 'demo' : transporterId;
    if (!_hasFirebase) {
      return Stream.value(defaultVehicles(tid));
    }
    final col = _vehicleCol(tid);
    if (col == null) {
      return Stream.value(defaultVehicles(tid));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return tid == 'demo' ? defaultVehicles(tid) : const <LogisticsVehicle>[];
      }
      return snap.docs
          .map((d) => LogisticsVehicle.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> saveVehicle(LogisticsVehicle vehicle) async {
    if (!_hasFirebase) return;
    final tid = vehicle.transporterId.isNotEmpty
        ? vehicle.transporterId
        : (currentTransporterId ?? 'demo');
    final col = _vehicleCol(tid);
    if (col == null) return;
    final v = vehicle.copyWith(
      transporterId: tid,
      updatedAt: DateTime.now(),
    );
    await col.doc(v.id).set(v.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteVehicle(String transporterId, String vehicleId) async {
    if (!_hasFirebase) return;
    try {
      await _vehicleCol(transporterId)?.doc(vehicleId).delete();
    } catch (e) {
      debugPrint('deleteVehicle fallback: $e');
    }
  }

  // ─── BRANCH OPERATIONS ───────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? _branchCol(String tid) =>
      _firestore?.collection('transporters').doc(tid).collection('branches');

  Stream<List<LogisticsBranch>> streamBranches(String transporterId) {
    final tid = transporterId.isEmpty ? 'demo' : transporterId;
    if (!_hasFirebase) {
      return Stream.value(defaultBranches(tid));
    }
    final col = _branchCol(tid);
    if (col == null) {
      return Stream.value(defaultBranches(tid));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return tid == 'demo' ? defaultBranches(tid) : const <LogisticsBranch>[];
      }
      return snap.docs
          .map((d) => LogisticsBranch.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> saveBranch(LogisticsBranch branch) async {
    if (!_hasFirebase) return;
    final tid = branch.transporterId.isNotEmpty
        ? branch.transporterId
        : (currentTransporterId ?? 'demo');
    final col = _branchCol(tid);
    if (col == null) return;
    final b = branch.copyWith(
      transporterId: tid,
      updatedAt: DateTime.now(),
    );
    await col.doc(b.id).set(b.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBranch(String transporterId, String branchId) async {
    if (!_hasFirebase) return;
    try {
      await _branchCol(transporterId)?.doc(branchId).delete();
    } catch (e) {
      debugPrint('deleteBranch fallback: $e');
    }
  }

  // ─── DRIVER OPERATIONS ───────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? _driverCol(String tid) =>
      _firestore?.collection('transporters').doc(tid).collection('drivers');

  Stream<List<FleetDriverInfo>> streamDrivers(String transporterId) {
    final tid = transporterId.isEmpty ? 'demo' : transporterId;
    if (!_hasFirebase) {
      return Stream.value(defaultDrivers(tid));
    }
    final col = _driverCol(tid);
    if (col == null) {
      return Stream.value(defaultDrivers(tid));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return tid == 'demo' ? defaultDrivers(tid) : const <FleetDriverInfo>[];
      }
      return snap.docs
          .map((d) => FleetDriverInfo.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> saveDriver(FleetDriverInfo driver) async {
    if (!_hasFirebase) return;
    final tid = driver.transporterId.isNotEmpty
        ? driver.transporterId
        : (currentTransporterId ?? 'demo');
    final col = _driverCol(tid);
    if (col == null) return;
    final d = driver.copyWith(
      transporterId: tid,
      updatedAt: DateTime.now(),
    );
    await col.doc(d.id).set(d.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteDriver(String transporterId, String driverId) async {
    if (!_hasFirebase) return;
    try {
      await _driverCol(transporterId)?.doc(driverId).delete();
    } catch (e) {
      debugPrint('deleteDriver fallback: $e');
    }
  }

  // ─── ASSIGNMENT & DISPATCH ───────────────────────────────────────────

  Future<void> assignDriverAndVehicleToJob({
    required String jobId,
    required LogisticsVehicle vehicle,
    required FleetDriverInfo driver,
  }) async {
    if (!_hasFirebase || _firestore == null) return;
    try {
      await _firestore!.collection('transport_jobs').doc(jobId).update({
        'vehicleId': vehicle.id,
        'vehicleReg': vehicle.registrationNumber,
        'vehicleType': vehicle.vehicleType,
        'driverId': driver.id,
        'driverName': driver.name,
        'driverPhone': driver.phone,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update vehicle and driver status to on_trip
      await saveVehicle(vehicle.copyWith(status: 'on_trip', assignedDriverId: driver.id, assignedDriverName: driver.name));
      await saveDriver(driver.copyWith(status: 'on_trip', assignedVehicleId: vehicle.id, assignedVehicleReg: vehicle.registrationNumber));
    } catch (e) {
      debugPrint('assignDriverAndVehicleToJob fallback: $e');
    }
  }

  // ─── FLEET MAINTENANCE OPERATIONS ────────────────────────────────────

  static List<VehicleMaintenanceRecord> defaultMaintenanceRecords(String vehicleId) => [
        VehicleMaintenanceRecord(
          id: 'maint_01',
          vehicleId: vehicleId,
          vehicleReg: 'WP-NC-1234',
          serviceType: 'oil_change',
          garageName: 'Dimo Lanka Commercial Service Center',
          costLkr: 28500.0,
          serviceDate: DateTime.now().subtract(const Duration(days: 14)),
          odometerKm: 42150.0,
          nextServiceDueDate: DateTime.now().add(const Duration(days: 76)),
          nextServiceOdometerKm: 47150.0,
          notes: 'Mobil Delvac 15W-40 oil and OEM filters replaced',
        ),
        VehicleMaintenanceRecord(
          id: 'maint_02',
          vehicleId: vehicleId,
          vehicleReg: 'WP-NC-1234',
          serviceType: 'reefer_maintenance',
          garageName: 'Thermo King Service Hub, Kelaniya',
          costLkr: 45000.0,
          serviceDate: DateTime.now().subtract(const Duration(days: 30)),
          odometerKm: 39800.0,
          notes: 'Refrigerant pressure tested, evaporator sanitized',
        ),
      ];

  CollectionReference<Map<String, dynamic>>? _maintenanceCol(String vehicleId) =>
      _firestore?.collection('vehicles').doc(vehicleId).collection('maintenance');

  Stream<List<VehicleMaintenanceRecord>> streamMaintenanceRecords(String vehicleId) {
    if (!_hasFirebase || vehicleId.isEmpty) {
      return Stream.value(defaultMaintenanceRecords(vehicleId));
    }
    final col = _maintenanceCol(vehicleId);
    if (col == null) {
      return Stream.value(defaultMaintenanceRecords(vehicleId));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultMaintenanceRecords(vehicleId);
      }
      return snap.docs
          .map((d) => VehicleMaintenanceRecord.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultMaintenanceRecords(vehicleId));
  }

  Future<void> saveMaintenanceRecord(VehicleMaintenanceRecord rec) async {
    if (!_hasFirebase) return;
    final col = _maintenanceCol(rec.vehicleId);
    if (col == null) return;
    try {
      await col.doc(rec.id).set(rec.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveMaintenanceRecord fallback: $e');
    }
  }

  // ─── FLEET FUEL OPERATIONS ───────────────────────────────────────────

  static List<FleetFuelLog> defaultFuelLogs(String vehicleId) => [
        FleetFuelLog(
          id: 'fuel_01',
          vehicleId: vehicleId,
          vehicleReg: 'WP-NC-1234',
          driverId: 'drv_01',
          driverName: 'Kasun Rajapaksha',
          fueledAt: DateTime.now().subtract(const Duration(days: 2)),
          litersFilled: 85.0,
          costPerLiterLkr: 341.0,
          totalCostLkr: 28985.0,
          fuelStationName: 'Ceypetco Dambulla Hub Station',
          odometerKm: 42150.0,
          previousOdometerKm: 41520.0,
        ),
      ];

  CollectionReference<Map<String, dynamic>>? _fuelCol(String vehicleId) =>
      _firestore?.collection('vehicles').doc(vehicleId).collection('fuel_logs');

  Stream<List<FleetFuelLog>> streamFuelLogs(String vehicleId) {
    if (!_hasFirebase || vehicleId.isEmpty) {
      return Stream.value(defaultFuelLogs(vehicleId));
    }
    final col = _fuelCol(vehicleId);
    if (col == null) {
      return Stream.value(defaultFuelLogs(vehicleId));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultFuelLogs(vehicleId);
      }
      return snap.docs
          .map((d) => FleetFuelLog.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultFuelLogs(vehicleId));
  }

  Future<void> saveFuelLog(FleetFuelLog log) async {
    if (!_hasFirebase) return;
    final col = _fuelCol(log.vehicleId);
    if (col == null) return;
    try {
      await col.doc(log.id).set(log.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveFuelLog fallback: $e');
    }
  }

  // ─── DRIVER SHIFTS OPERATIONS ────────────────────────────────────────

  static List<DriverShiftRecord> defaultDriverShifts(String driverId) => [
        DriverShiftRecord(
          id: 'shift_01',
          driverId: driverId,
          driverName: 'Kasun Rajapaksha',
          branchId: 'br_dambulla_hub',
          branchName: 'Dambulla Agro Exchange Hub',
          assignedVehicleId: 'veh_01',
          assignedVehicleReg: 'WP-NA-4512',
          checkInTime: DateTime.now().subtract(const Duration(hours: 6)),
          drivingHours: 4.5,
          restHours: 1.0,
          completedTripsCount: 2,
          status: 'active',
          notes: 'Completed Dambulla to Colombo cold-chain route',
        ),
      ];

  CollectionReference<Map<String, dynamic>>? _shiftCol(String driverId) =>
      _firestore?.collection('drivers').doc(driverId).collection('shifts');

  Stream<List<DriverShiftRecord>> streamDriverShifts(String driverId) {
    if (!_hasFirebase || driverId.isEmpty) {
      return Stream.value(defaultDriverShifts(driverId));
    }
    final col = _shiftCol(driverId);
    if (col == null) {
      return Stream.value(defaultDriverShifts(driverId));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultDriverShifts(driverId);
      }
      return snap.docs
          .map((d) => DriverShiftRecord.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultDriverShifts(driverId));
  }

  Future<void> saveDriverShift(DriverShiftRecord shift) async {
    if (!_hasFirebase) return;
    final col = _shiftCol(shift.driverId);
    if (col == null) return;
    try {
      await col.doc(shift.id).set(shift.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveDriverShift fallback: $e');
    }
  }

  // ─── COLD STORAGE OPERATIONS ─────────────────────────────────────────

  static List<HubColdStorageLog> defaultColdStorageLogs(String branchId) => [
        HubColdStorageLog(
          id: 'csl_01',
          branchId: branchId,
          branchName: 'Dambulla Agro Exchange Hub',
          roomName: 'Chamber A - Upcountry Vegetables',
          currentTempC: 3.8,
          targetTempC: 4.0,
          minSafeTempC: 2.0,
          maxSafeTempC: 7.0,
          relativeHumidityPercent: 88.0,
          recordedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          isBreached: false,
          notes: 'Cooling coils operating normally',
        ),
        HubColdStorageLog(
          id: 'csl_02',
          branchId: branchId,
          branchName: 'Dambulla Agro Exchange Hub',
          roomName: 'Chamber B - Tropical Fruits & Berries',
          currentTempC: 8.5,
          targetTempC: 8.0,
          minSafeTempC: 6.0,
          maxSafeTempC: 12.0,
          relativeHumidityPercent: 82.0,
          recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
          isBreached: false,
          notes: 'Pre-cooling cycle complete',
        ),
      ];

  CollectionReference<Map<String, dynamic>>? _coldStorageCol(String branchId) =>
      _firestore?.collection('branches').doc(branchId).collection('cold_storage_logs');

  Stream<List<HubColdStorageLog>> streamColdStorageLogs(String branchId) {
    if (!_hasFirebase || branchId.isEmpty) {
      return Stream.value(defaultColdStorageLogs(branchId));
    }
    final col = _coldStorageCol(branchId);
    if (col == null) {
      return Stream.value(defaultColdStorageLogs(branchId));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultColdStorageLogs(branchId);
      }
      return snap.docs
          .map((d) => HubColdStorageLog.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultColdStorageLogs(branchId));
  }

  Future<void> saveColdStorageLog(HubColdStorageLog log) async {
    if (!_hasFirebase) return;
    final col = _coldStorageCol(log.branchId);
    if (col == null) return;
    try {
      await col.doc(log.id).set(log.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveColdStorageLog fallback: $e');
    }
  }

  // ─── EMERGENCY BREAKDOWN OPERATIONS ──────────────────────────────────

  static List<FleetBreakdownRequest> defaultBreakdownRequests(String transporterId) => [
        FleetBreakdownRequest(
          id: 'bkd_01',
          vehicleId: 'veh_02',
          vehicleReg: 'CP-LG-8890',
          driverId: 'drv_02',
          driverName: 'Ruwan Wijesinghe',
          driverPhone: '0765544332',
          latitude: 7.2906,
          longitude: 80.6337,
          locationDescription: 'A1 Highway near Kadugannawa Pass',
          failureType: 'cooling_failure',
          severity: 'critical_cargo_rescue',
          status: 'assigned',
          reliefVehicleId: 'veh_01',
          reliefVehicleReg: 'WP-NA-4512',
          reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
          notes: 'Reefer compressor belt snapped. Relief cold truck dispatched.',
        ),
      ];

  CollectionReference<Map<String, dynamic>>? _breakdownCol(String tid) =>
      _firestore?.collection('transporters').doc(tid).collection('breakdowns');

  Stream<List<FleetBreakdownRequest>> streamBreakdownRequests(String transporterId) {
    final tid = transporterId.isEmpty ? 'demo' : transporterId;
    if (!_hasFirebase) {
      return Stream.value(defaultBreakdownRequests(tid));
    }
    final col = _breakdownCol(tid);
    if (col == null) {
      return Stream.value(defaultBreakdownRequests(tid));
    }
    return col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return defaultBreakdownRequests(tid);
      }
      return snap.docs
          .map((d) => FleetBreakdownRequest.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultBreakdownRequests(tid));
  }

  Future<void> reportBreakdown(FleetBreakdownRequest req) async {
    if (!_hasFirebase) return;
    final tid = currentTransporterId ?? 'demo';
    final col = _breakdownCol(tid);
    if (col == null) return;
    try {
      await col.doc(req.id).set(req.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('reportBreakdown fallback: $e');
    }
  }
}
