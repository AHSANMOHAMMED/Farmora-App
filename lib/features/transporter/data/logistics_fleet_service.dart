import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../domain/logistics_vehicle.dart';
import '../domain/logistics_branch.dart';
import '../domain/fleet_driver_info.dart';

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

  String? get currentTransporterId => _auth?.currentUser?.uid ?? 'demo';

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
        return defaultVehicles(tid);
      }
      return snap.docs
          .map((d) => LogisticsVehicle.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultVehicles(tid));
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
    try {
      await col.doc(v.id).set(v.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveVehicle offline or Firestore fallback: $e');
    }
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
        return defaultBranches(tid);
      }
      return snap.docs
          .map((d) => LogisticsBranch.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultBranches(tid));
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
    try {
      await col.doc(b.id).set(b.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveBranch offline or Firestore fallback: $e');
    }
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
        return defaultDrivers(tid);
      }
      return snap.docs
          .map((d) => FleetDriverInfo.fromMap(d.id, d.data()))
          .toList();
    }).handleError((_) => defaultDrivers(tid));
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
    try {
      await col.doc(d.id).set(d.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveDriver offline or Firestore fallback: $e');
    }
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
}
