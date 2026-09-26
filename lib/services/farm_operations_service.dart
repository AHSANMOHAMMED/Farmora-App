import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmOperationsService {
  FarmOperationsService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to manage farm operations.');
    return uid;
  }

  // ─── Crops ───────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchCrops() {
    try {
      return _db
          .collection('crop_plans')
          .where('farmerId', isEqualTo: _uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (_) {
      return Stream.value(_demoCrops());
    }
  }

  Future<void> createCrop({required String cropName, required double area,
    required String areaUnit, required DateTime plantedAt,
    required DateTime harvestAt, String notes = ''}) async {
    try {
      await _functions.httpsCallable('createCropPlan').call({
        'cropName': cropName, 'area': area, 'areaUnit': areaUnit,
        'plantedAt': plantedAt.toIso8601String(),
        'expectedHarvestAt': harvestAt.toIso8601String(), 'notes': notes,
      });
    } catch (_) {
      await _db.collection('crop_plans').add({
        'farmerId': _uid, 'cropName': cropName, 'area': area, 'areaUnit': areaUnit,
        'plantedAt': Timestamp.fromDate(plantedAt),
        'expectedHarvestAt': Timestamp.fromDate(harvestAt),
        'notes': notes, 'status': 'planted',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateCrop(String id, Map<String, dynamic> updates) async {
    try {
      await _functions.httpsCallable('updateCropPlan').call({'cropId': id, ...updates});
    } catch (_) {
      await _db.collection('crop_plans').doc(id).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchTasks() {
    try {
      return _db
          .collection('farm_tasks')
          .where('farmerId', isEqualTo: _uid)
          .orderBy('dueAt')
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (_) {
      return Stream.value(_demoTasks());
    }
  }

  Future<void> createTask({required String title, required DateTime dueAt,
      required String priority, String description = '', String cropId = '',
      String cropName = ''}) async {
    try {
      await _functions.httpsCallable('createFarmTask').call({
        'title': title, 'dueAt': dueAt.toIso8601String(), 'priority': priority,
        'description': description, 'cropId': cropId, 'cropName': cropName,
      });
    } catch (_) {
      await _db.collection('farm_tasks').add({
        'farmerId': _uid, 'title': title, 'priority': priority,
        'description': description, 'cropId': cropId, 'cropName': cropName,
        'dueAt': Timestamp.fromDate(dueAt), 'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      await _functions.httpsCallable('updateFarmTask').call({'taskId': id, ...updates});
    } catch (_) {
      await _db.collection('farm_tasks').doc(id).update(updates);
    }
  }

  Future<int> checkTaskReminders() async {
    try {
      final result = await _functions.httpsCallable('checkFarmTaskReminders').call();
      return (result.data['reminders'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Finances: Income ─────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchIncome() {
    try {
      return _db
          .collection('farm_income')
          .where('farmerId', isEqualTo: _uid)
          .orderBy('recordedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (_) {
      return Stream.value(_demoIncome());
    }
  }

  Future<void> createIncome({
    required String description,
    required int amountMinor,
    String source = '',
    String? cropId,
  }) async {
    await _db.collection('farm_income').add({
      'farmerId': _uid,
      'description': description,
      'amountMinor': amountMinor,
      'source': source,
      'cropId': cropId,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteIncome(String id) async {
    await _db.collection('farm_income').doc(id).delete();
  }

  // ─── Finances: Expenses ───────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchExpenses() {
    try {
      return _db
          .collection('farm_expenses')
          .where('farmerId', isEqualTo: _uid)
          .orderBy('recordedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (_) {
      return Stream.value(_demoExpenses());
    }
  }

  Future<void> createExpense({
    required String description,
    required int amountMinor,
    String category = 'Other',
    String? cropId,
  }) async {
    await _db.collection('farm_expenses').add({
      'farmerId': _uid,
      'description': description,
      'amountMinor': amountMinor,
      'category': category,
      'cropId': cropId,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection('farm_expenses').doc(id).delete();
  }

  // ─── Labour ───────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchLabour() {
    try {
      return _db
          .collection('farm_labour')
          .where('farmerId', isEqualTo: _uid)
          .orderBy('recordedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    } catch (_) {
      return Stream.value(_demoLabour());
    }
  }

  Future<void> createLabour({
    required String workerName,
    required String role,
    required int dailyWageMinor,
    int daysWorked = 1,
    String phone = '',
    String? cropId,
  }) async {
    await _db.collection('farm_labour').add({
      'farmerId': _uid,
      'workerName': workerName,
      'role': role,
      'dailyWageMinor': dailyWageMinor,
      'daysWorked': daysWorked,
      'phone': phone,
      'cropId': cropId,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLabour(String id, Map<String, dynamic> updates) async {
    await _db.collection('farm_labour').doc(id).update(updates);
  }

  Future<void> deleteLabour(String id) async {
    await _db.collection('farm_labour').doc(id).delete();
  }

  // ─── Demo data fallbacks ──────────────────────────────────────────────────

  static List<Map<String, dynamic>> _demoCrops() => [
    {'id': 'demo-1', 'cropName': 'Tomato', 'area': 2.5, 'areaUnit': 'acres', 'status': 'growing', 'expectedYield': 5000, 'yieldUnit': 'kg', 'expectedHarvestAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))), 'updatedAt': Timestamp.now()},
    {'id': 'demo-2', 'cropName': 'Carrot', 'area': 1.0, 'areaUnit': 'acres', 'status': 'planted', 'expectedYield': 2000, 'yieldUnit': 'kg', 'expectedHarvestAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 60))), 'updatedAt': Timestamp.now()},
  ];

  static List<Map<String, dynamic>> _demoTasks() => [
    {'id': 'demo-t1', 'title': 'Irrigate tomato field', 'priority': 'high', 'status': 'pending', 'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))), 'cropName': 'Tomato'},
    {'id': 'demo-t2', 'title': 'Apply fertilizer — Carrot row A', 'priority': 'normal', 'status': 'pending', 'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))), 'cropName': 'Carrot'},
    {'id': 'demo-t3', 'title': 'Harvest tomatoes — south section', 'priority': 'normal', 'status': 'pending', 'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))), 'cropName': 'Tomato'},
  ];

  static List<Map<String, dynamic>> _demoIncome() => [
    {'id': 'di-1', 'description': 'Tomato batch sold at Dambulla market', 'amountMinor': 4500000, 'source': 'Market sale', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)))},
    {'id': 'di-2', 'description': 'Carrot sold to Keells buyer', 'amountMinor': 1800000, 'source': 'Direct buyer', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15)))},
  ];

  static List<Map<String, dynamic>> _demoExpenses() => [
    {'id': 'de-1', 'description': 'NPK fertilizer 50kg', 'amountMinor': 350000, 'category': 'Seeds & Inputs', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8)))},
    {'id': 'de-2', 'description': 'Irrigation pump repair', 'amountMinor': 250000, 'category': 'Equipment', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 12)))},
    {'id': 'de-3', 'description': 'Pesticide — Chlorpyrifos', 'amountMinor': 180000, 'category': 'Pesticides', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)))},
  ];

  static List<Map<String, dynamic>> _demoLabour() => [
    {'id': 'dl-1', 'workerName': 'Priya Fernando', 'role': 'Harvesting', 'dailyWageMinor': 80000, 'daysWorked': 3, 'phone': '+94771234567', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
    {'id': 'dl-2', 'workerName': 'Suresh Bandara', 'role': 'General Labour', 'dailyWageMinor': 75000, 'daysWorked': 5, 'phone': '+94712345678', 'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)))},
  ];
}
