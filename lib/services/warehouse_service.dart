import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import 'service_errors.dart';

/// A stored produce lot (`warehouse_lots`).
class WarehouseLot {
  const WarehouseLot({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.lotCode,
    required this.productName,
    required this.ownerName,
    required this.quantity,
    required this.quantityRemaining,
    required this.unit,
    required this.grade,
    required this.cold,
    required this.status,
    this.district = '',
    this.notes = '',
    this.receivedAt,
    this.expiresAt,
  });

  final String id;
  final String warehouseId;
  final String warehouseName;
  final String lotCode;
  final String productName;
  final String ownerName;
  final double quantity;
  final double quantityRemaining;
  final String unit;
  final String grade;
  final bool cold;

  /// in_stock, dispatched or spoiled.
  final String status;
  final String district;
  final String notes;
  final DateTime? receivedAt;
  final DateTime? expiresAt;

  /// Expired, or expiring within three days.
  bool get expiringSoon =>
      status == 'in_stock' &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now().add(const Duration(days: 3)));

  factory WarehouseLot.fromMap(String id, Map<String, dynamic> d) =>
      WarehouseLot(
        id: id,
        warehouseId: (d['warehouseId'] ?? '').toString(),
        warehouseName: (d['warehouseName'] ?? '').toString(),
        lotCode: (d['lotCode'] ?? '').toString(),
        productName: (d['productName'] ?? '').toString(),
        ownerName: (d['ownerName'] ?? '').toString(),
        quantity: firebaseDouble(d['quantity']) ?? 0,
        quantityRemaining: firebaseDouble(d['quantityRemaining']) ?? 0,
        unit: (d['unit'] ?? 'kg').toString(),
        grade: (d['grade'] ?? 'ungraded').toString(),
        cold: d['storageType'] == 'cold',
        status: (d['status'] ?? 'in_stock').toString(),
        district: (d['district'] ?? '').toString(),
        notes: (d['notes'] ?? '').toString(),
        receivedAt: firebaseDate(d['receivedAt']),
        expiresAt: firebaseDate(d['expiresAt']),
      );
}

class LotMove {
  const LotMove({
    required this.type,
    required this.quantity,
    this.note = '',
    this.createdAt,
  });

  final String type;
  final double quantity;
  final String note;
  final DateTime? createdAt;

  factory LotMove.fromMap(Map<String, dynamic> d) => LotMove(
        type: (d['type'] ?? '').toString(),
        quantity: firebaseDouble(d['quantity']) ?? 0,
        note: (d['note'] ?? '').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Lot-level warehouse inventory: inward, outward (dispatch), spoilage,
/// each logged as a move. Buyers can browse in-stock lots.
class WarehouseService {
  WarehouseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _lots =>
      _db.collection('warehouse_lots');

  Stream<List<WarehouseLot>> myLots({int limit = 100}) => _lots
      .where('warehouseId', isEqualTo: _uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('receivedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => WarehouseLot.fromMap(d.id, d.data())).toList());

  /// In-stock lots across warehouses, for buyers.
  Stream<List<WarehouseLot>> availableStock({int limit = 50}) => _lots
      .where('status', isEqualTo: 'in_stock')
      .where('isDeleted', isEqualTo: false)
      .orderBy('receivedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => WarehouseLot.fromMap(d.id, d.data())).toList());

  Stream<List<LotMove>> moves(String lotId) => _lots
      .doc(lotId)
      .collection('moves')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => LotMove.fromMap(d.data())).toList());

  Future<void> receiveLot({
    required String productName,
    required String ownerName,
    required double quantity,
    required String unit,
    required String grade,
    required bool cold,
    DateTime? expiresAt,
    String district = '',
    String notes = '',
  }) async {
    if (productName.trim().isEmpty || quantity <= 0) {
      throw UserArgumentError('Enter the produce and a quantity.');
    }
    final uid = _uid;
    final me = (await _db.collection('users').doc(uid).get()).data() ?? {};
    final name = (me['displayName'] ?? me['name'] ?? 'Warehouse').toString();
    final ref = _lots.doc();
    final now = DateTime.now();
    final code =
        'LOT-${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${ref.id.substring(0, 4).toUpperCase()}';
    final batch = _db.batch()
      ..set(ref, {
        'warehouseId': uid,
        'warehouseName': name,
        'lotCode': code,
        'productName': productName.trim(),
        'ownerName': ownerName.trim(),
        'quantity': quantity,
        'quantityRemaining': quantity,
        'unit': unit,
        'grade': grade,
        'storageType': cold ? 'cold' : 'ambient',
        'district': district.trim(),
        'notes': notes.trim(),
        'status': 'in_stock',
        'receivedAt': FieldValue.serverTimestamp(),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'updatedBy': uid,
      })
      ..set(ref.collection('moves').doc(), {
        'type': 'inward',
        'quantity': quantity,
        'note': ownerName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
    await batch.commit();
  }

  /// Takes [quantity] out of a lot, as a dispatch or as spoilage.
  Future<void> takeOut(WarehouseLot lot, double quantity,
      {required bool spoiled, String note = ''}) async {
    if (quantity <= 0 || quantity > lot.quantityRemaining) {
      throw UserArgumentError(
          'Enter up to ${lot.quantityRemaining} ${lot.unit}.');
    }
    final uid = _uid;
    final remaining = lot.quantityRemaining - quantity;
    final ref = _lots.doc(lot.id);
    final batch = _db.batch()
      ..update(ref, {
        'quantityRemaining': remaining,
        if (remaining == 0) 'status': spoiled ? 'spoiled' : 'dispatched',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      })
      ..set(ref.collection('moves').doc(), {
        'type': spoiled ? 'spoilage' : 'outward',
        'quantity': quantity,
        'note': note.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
    await batch.commit();
  }

  Future<void> deleteLot(String id) => _lots.doc(id).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid,
      });
}
