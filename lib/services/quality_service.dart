import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import '../models/product.dart';
import 'service_errors.dart';
import 'push_relay.dart';

const kQualityGrades = ['A', 'B', 'C', 'Reject'];

/// A farmer's request to have a product inspected (`quality_requests`,
/// one per product, keyed by product id).
class QualityRequest {
  const QualityRequest({
    required this.productId,
    required this.productName,
    required this.farmerId,
    required this.farmerName,
    required this.district,
    required this.status,
    this.createdAt,
  });

  final String productId;
  final String productName;
  final String farmerId;
  final String farmerName;
  final String district;
  final String status;
  final DateTime? createdAt;

  factory QualityRequest.fromMap(String id, Map<String, dynamic> d) =>
      QualityRequest(
        productId: id,
        productName: (d['productName'] ?? '').toString(),
        farmerId: (d['farmerId'] ?? '').toString(),
        farmerName: (d['farmerName'] ?? '').toString(),
        district: (d['district'] ?? '').toString(),
        status: (d['status'] ?? 'open').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

class QualityInspection {
  const QualityInspection({
    required this.id,
    required this.productName,
    required this.grade,
    this.moisturePct,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String productName;
  final String grade;
  final double? moisturePct;
  final String notes;
  final DateTime? createdAt;

  factory QualityInspection.fromMap(String id, Map<String, dynamic> d) =>
      QualityInspection(
        id: id,
        productName: (d['productName'] ?? '').toString(),
        grade: (d['grade'] ?? '').toString(),
        moisturePct: firebaseDouble(d['moisturePct']),
        notes: (d['notes'] ?? '').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Quality inspection requests and grading. The grade lands on the product
/// only together with the inspection record (enforced by the rules).
class QualityService {
  QualityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  Future<String> _myName(String fallback) async {
    final me = (await _db.collection('users').doc(_uid).get()).data() ?? {};
    final n = (me['displayName'] ?? me['name'] ?? '').toString().trim();
    return n.isEmpty ? fallback : n;
  }

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('quality_requests');

  // ── Farmer ──────────────────────────────────────────────────

  Stream<QualityRequest?> watchRequest(String productId) => _requests
      .doc(productId)
      .snapshots()
      .map((d) => d.exists ? QualityRequest.fromMap(d.id, d.data()!) : null)
      // A missing request is unreadable for non-owners; treat as none.
      .handleError((Object _) {});

  Future<void> requestInspection(Product product) async {
    final ref = _requests.doc(product.id);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.update(
          {'status': 'open', 'updatedAt': FieldValue.serverTimestamp()});
      return;
    }
    await ref.set({
      'productId': product.id,
      'productName': product.name,
      'farmerId': _uid,
      'farmerName': await _myName('Farmer'),
      'district': product.location,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Inspector ───────────────────────────────────────────────

  Stream<List<QualityRequest>> openRequests() => _requests
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt')
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => QualityRequest.fromMap(d.id, d.data())).toList());

  Stream<List<QualityInspection>> myInspections() => _db
      .collection('quality_inspections')
      .where('inspectorId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => QualityInspection.fromMap(d.id, d.data()))
          .toList());

  /// Records the grade: inspection doc + product grade + request closed,
  /// in one batch.
  Future<void> grade(
    QualityRequest request, {
    required String grade,
    double? moisturePct,
    String notes = '',
  }) async {
    if (!kQualityGrades.contains(grade)) {
      throw UserArgumentError('Choose a grade.');
    }
    if (moisturePct != null && (moisturePct < 0 || moisturePct > 100)) {
      throw UserArgumentError('Moisture must be 0–100%.');
    }
    final uid = _uid;
    final name = await _myName('Inspector');
    final inspection = _db.collection('quality_inspections').doc();
    final batch = _db.batch()
      ..set(inspection, {
        'productId': request.productId,
        'productName': request.productName,
        'farmerId': request.farmerId,
        'inspectorId': uid,
        'inspectorName': name,
        'grade': grade,
        'moisturePct': moisturePct,
        'notes': notes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(_db.collection('products').doc(request.productId), {
        'qualityGrade': grade,
        'qualityInspectedAt': FieldValue.serverTimestamp(),
        'qualityInspectionId': inspection.id,
        'qualityInspectorName': name,
      })
      ..update(_requests.doc(request.productId), {
        'status': 'done',
        'inspectorId': uid,
        'doneAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    try {
      await sendNotification(_db, {
        'userId': request.farmerId,
        'title': 'Quality inspection done',
        'body': '${request.productName} was graded $grade by $name.',
        'type': 'quality',
        'referenceId': request.productId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best effort.
    }
  }
}
