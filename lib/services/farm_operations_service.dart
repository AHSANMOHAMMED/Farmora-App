import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_backend.dart';
import 'spark_backend.dart';

class FarmOperationsService {
  FarmOperationsService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  late final SparkBackend _spark = SparkBackend(_db);

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to manage farm operations.');
    return uid;
  }

  Stream<List<Map<String, dynamic>>> watchCrops() => _db
      .collection('crop_plans')
      .where('farmerId', isEqualTo: _uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchTasks() => _db
      .collection('farm_tasks')
      .where('farmerId', isEqualTo: _uid)
      .orderBy('dueAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> createCrop({required String cropName, required double area,
    required String areaUnit, required DateTime plantedAt,
    required DateTime harvestAt, String notes = ''}) async {
    if (!kUseCloudFunctions) {
      await _spark.createCropPlan(
        cropName: cropName, area: area, areaUnit: areaUnit,
        plantedAt: plantedAt, expectedHarvestAt: harvestAt, notes: notes,
      );
      return;
    }
    await _functions.httpsCallable('createCropPlan').call({
      'cropName': cropName, 'area': area, 'areaUnit': areaUnit,
      'plantedAt': plantedAt.toIso8601String(),
      'expectedHarvestAt': harvestAt.toIso8601String(), 'notes': notes,
    });
  }

  Future<void> updateCrop(String id, Map<String, dynamic> updates) async {
    if (!kUseCloudFunctions) {
      await _spark.updateCropPlan(id, updates);
      return;
    }
    await _functions.httpsCallable('updateCropPlan').call({'cropId': id, ...updates});
  }

  Future<void> createTask({required String title, required DateTime dueAt,
      required String priority, String description = '', String cropId = '',
      String cropName = ''}) async {
    if (!kUseCloudFunctions) {
      await _spark.createFarmTask(
        title: title, dueAt: dueAt, priority: priority,
        description: description, cropId: cropId, cropName: cropName,
      );
      return;
    }
    await _functions.httpsCallable('createFarmTask').call({
      'title': title, 'dueAt': dueAt.toIso8601String(), 'priority': priority,
      'description': description, 'cropId': cropId, 'cropName': cropName,
    });
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    if (!kUseCloudFunctions) {
      await _spark.updateFarmTask(id, updates);
      return;
    }
    await _functions.httpsCallable('updateFarmTask').call({'taskId': id, ...updates});
  }

  /// Spark computes reminders on the client (self-notifications).
  Future<int> checkTaskReminders() async {
    if (!kUseCloudFunctions) return _spark.checkFarmTaskReminders();
    final result = await _functions.httpsCallable('checkFarmTaskReminders').call();
    return (result.data['reminders'] as num?)?.toInt() ?? 0;
  }
}
