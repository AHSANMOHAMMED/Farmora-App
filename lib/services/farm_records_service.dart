import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import 'service_errors.dart';

/// A field or plot on the farm (`farm_plots`).
class FarmPlot {
  const FarmPlot({
    required this.id,
    required this.name,
    required this.area,
    required this.areaUnit,
    this.soilType = '',
    this.irrigation = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final double area;
  final String areaUnit;
  final String soilType;
  final String irrigation;
  final String notes;

  factory FarmPlot.fromMap(String id, Map<String, dynamic> d) => FarmPlot(
        id: id,
        name: (d['name'] ?? '').toString(),
        area: firebaseDouble(d['area']) ?? 0,
        areaUnit: (d['areaUnit'] ?? 'acres').toString(),
        soilType: (d['soilType'] ?? '').toString(),
        irrigation: (d['irrigation'] ?? '').toString(),
        notes: (d['notes'] ?? '').toString(),
      );
}

/// One income or expense line in the farm ledger (`farm_ledger`).
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.isExpense,
    required this.category,
    required this.amountMinor,
    required this.date,
    this.cropId = '',
    this.cropName = '',
    this.note = '',
    this.sourceId = '',
  });

  final String id;
  final bool isExpense;
  final String category;
  final int amountMinor;
  final DateTime date;
  final String cropId;
  final String cropName;
  final String note;

  /// Input order this expense was created from (avoids double entry).
  final String sourceId;

  double get amount => amountMinor / 100.0;

  factory LedgerEntry.fromMap(String id, Map<String, dynamic> d) =>
      LedgerEntry(
        id: id,
        isExpense: d['type'] == 'expense',
        category: (d['category'] ?? 'other').toString(),
        amountMinor: firebaseInt(d['amountMinor']) ?? 0,
        date: firebaseDate(d['date']) ?? DateTime.now(),
        cropId: (d['cropId'] ?? '').toString(),
        cropName: (d['cropName'] ?? '').toString(),
        note: (d['note'] ?? '').toString(),
        sourceId: (d['sourceId'] ?? '').toString(),
      );
}

/// Ledger categories allowed by the rules.
const kExpenseCategories = [
  'seed', 'fertilizer', 'pesticide', 'labour', 'water', 'fuel',
  'machinery', 'transport', 'land', 'other',
];
const kIncomeCategories = ['produce_sale', 'subsidy', 'other'];

/// An admin broadcast shown in the farmer's advice feed (`advisories`).
class Advisory {
  const Advisory({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String audience;
  final DateTime? createdAt;

  factory Advisory.fromMap(String id, Map<String, dynamic> d) => Advisory(
        id: id,
        title: (d['title'] ?? '').toString(),
        body: (d['body'] ?? '').toString(),
        audience: (d['audience'] ?? 'all').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Farm plots, the income / expense ledger and the advisory feed. Plain
/// client writes (Spark); `firestore.rules` restricts each farmer to their
/// own records and checks every field.
class FarmRecordsService {
  FarmRecordsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  Map<String, dynamic> _created(String uid) => {
        'farmerId': uid,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'updatedBy': uid,
      };

  Map<String, dynamic> _updated() => {
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid,
      };

  // ── Plots ───────────────────────────────────────────────────

  Stream<List<FarmPlot>> watchPlots() => _db
      .collection('farm_plots')
      .where('farmerId', isEqualTo: _uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => FarmPlot.fromMap(d.id, d.data())).toList());

  Map<String, dynamic> _plotFields(String name, double area, String areaUnit,
      String soilType, String irrigation, String notes) {
    if (name.trim().isEmpty || area <= 0 || area > 100000) {
      throw UserArgumentError('Enter a plot name and a valid area.');
    }
    return {
      'name': name.trim(),
      'area': area,
      'areaUnit': areaUnit,
      'soilType': soilType.trim(),
      'irrigation': irrigation.trim(),
      'notes': notes.trim(),
    };
  }

  Future<void> savePlot({
    String? id,
    required String name,
    required double area,
    required String areaUnit,
    String soilType = '',
    String irrigation = '',
    String notes = '',
  }) async {
    final fields =
        _plotFields(name, area, areaUnit, soilType, irrigation, notes);
    final col = _db.collection('farm_plots');
    if (id == null) {
      await col.add({...fields, ..._created(_uid)});
    } else {
      await col.doc(id).update({...fields, ..._updated()});
    }
  }

  Future<void> deletePlot(String id) => _db
      .collection('farm_plots')
      .doc(id)
      .update({'isDeleted': true, ..._updated()});

  // ── Ledger ──────────────────────────────────────────────────

  Stream<List<LedgerEntry>> watchLedger({int limit = 200}) => _db
      .collection('farm_ledger')
      .where('farmerId', isEqualTo: _uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('date', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => LedgerEntry.fromMap(d.id, d.data())).toList());

  Future<void> addEntry({
    required bool isExpense,
    required String category,
    required int amountMinor,
    required DateTime date,
    String cropId = '',
    String cropName = '',
    String note = '',
    String sourceId = '',
  }) async {
    final allowed = isExpense ? kExpenseCategories : kIncomeCategories;
    if (!allowed.contains(category) || amountMinor <= 0) {
      throw UserArgumentError('Enter a valid amount and category.');
    }
    final data = {
      'type': isExpense ? 'expense' : 'income',
      'category': category,
      'amountMinor': amountMinor,
      'date': Timestamp.fromDate(date),
      'cropId': cropId,
      'cropName': cropName,
      'note': note.trim(),
      'sourceId': sourceId,
      ..._created(_uid),
    };
    final col = _db.collection('farm_ledger');
    if (sourceId.isEmpty) {
      await col.add(data);
      return;
    }
    // One ledger line per input order: the id is derived from it, and a
    // deleted line is restored rather than duplicated.
    final ref = col.doc('io_$sourceId');
    if ((await ref.get()).exists) {
      await ref.update({'isDeleted': false, ..._updated()});
    } else {
      await ref.set(data);
    }
  }

  Future<bool> hasEntryFor(String sourceId) async {
    final doc =
        await _db.collection('farm_ledger').doc('io_$sourceId').get();
    return doc.exists && doc.data()?['isDeleted'] != true;
  }

  Future<void> deleteEntry(String id) => _db
      .collection('farm_ledger')
      .doc(id)
      .update({'isDeleted': true, ..._updated()});

  // ── Advisories ──────────────────────────────────────────────

  /// Latest admin advice for [role] (or everyone).
  Stream<List<Advisory>> watchAdvisories(String role, {int limit = 30}) => _db
      .collection('advisories')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Advisory.fromMap(d.id, d.data()))
          .where((a) => a.audience == 'all' || a.audience == role)
          .toList());
}
