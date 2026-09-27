import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import 'service_errors.dart';
import 'push_relay.dart';

/// A transporter's bid on an open delivery (`transport_jobs/{id}/bids/{uid}`,
/// one per transporter).
class TransportBid {
  const TransportBid({
    required this.transporterId,
    required this.transporterName,
    required this.amountMinor,
    required this.etaHours,
    this.note = '',
    this.vehicleType = '',
    this.createdAt,
  });

  final String transporterId;
  final String transporterName;
  final int amountMinor;
  final int etaHours;
  final String note;
  final String vehicleType;
  final DateTime? createdAt;

  double get amount => amountMinor / 100.0;

  factory TransportBid.fromMap(String id, Map<String, dynamic> d) =>
      TransportBid(
        transporterId: id,
        transporterName: (d['transporterName'] ?? '').toString(),
        amountMinor: firebaseInt(d['amountMinor']) ?? 0,
        etaHours: firebaseInt(d['etaHours']) ?? 0,
        note: (d['note'] ?? '').toString(),
        vehicleType: (d['vehicleType'] ?? '').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Reverse auction on open delivery jobs. Transporters bid at or below the
/// farmer's offered fee; the farmer awards one bid, which turns the job into
/// a request for that transporter at the bid price (they then accept it the
/// usual way). Enforced by `firestore.rules`.
class BiddingService {
  BiddingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _job(String jobId) =>
      _db.collection('transport_jobs').doc(jobId);

  Stream<List<TransportBid>> bids(String jobId) => _job(jobId)
      .collection('bids')
      .orderBy('amountMinor')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => TransportBid.fromMap(d.id, d.data())).toList());

  Stream<TransportBid?> myBid(String jobId) => _job(jobId)
      .collection('bids')
      .doc(_uid)
      .snapshots()
      .map((d) => d.exists ? TransportBid.fromMap(d.id, d.data()!) : null);

  /// The farmer's offered fee (the ceiling for bids), in minor units.
  Future<int> maxFeeMinor(String jobId) async =>
      firebaseInt((await _job(jobId).get()).data()?['offeredFeeMinor']) ?? 0;

  Future<void> placeBid({
    required String jobId,
    required int amountMinor,
    required int etaHours,
    String note = '',
  }) async {
    final uid = _uid;
    final max = await maxFeeMinor(jobId);
    if (amountMinor <= 0 || (max > 0 && amountMinor > max)) {
      throw UserArgumentError(
          'Bid between LKR 1 and LKR ${(max / 100).toStringAsFixed(0)}.');
    }
    if (etaHours < 1 || etaHours > 240) {
      throw UserArgumentError('Enter a pickup-to-delivery time of 1–240 hours.');
    }
    final me = (await _db.collection('users').doc(uid).get()).data() ?? {};
    final ref = _job(jobId).collection('bids').doc(uid);
    final existing = await ref.get();
    await ref.set({
      'transporterId': uid,
      'transporterName':
          (me['displayName'] ?? me['name'] ?? 'Transporter').toString(),
      'vehicleType': (me['vehicleType'] ?? '').toString(),
      'amountMinor': amountMinor,
      'etaHours': etaHours,
      'note': note.trim(),
      'createdAt': existing.exists
          ? existing.data()!['createdAt']
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final job = (await _job(jobId).get()).data();
    await _notify(job?['farmerId']?.toString(), 'New delivery bid',
        '${me['displayName'] ?? 'A transporter'} bid LKR ${(amountMinor / 100).toStringAsFixed(0)} for ${job?['productName'] ?? 'your delivery'}.',
        jobId);
  }

  Future<void> withdrawBid(String jobId) =>
      _job(jobId).collection('bids').doc(_uid).delete();

  /// Farmer awards [bid]: the job becomes a request for that transporter at
  /// the bid price.
  Future<void> award(String jobId, TransportBid bid,
      {List<TransportBid> others = const []}) async {
    await _job(jobId).update({
      'transporterId': bid.transporterId,
      'requestedTransporterId': bid.transporterId,
      'offeredFeeMinor': bid.amountMinor,
      'deliveryFeeMinor': bid.amountMinor,
      'fee': 'LKR ${bid.amount.toStringAsFixed(2)}',
      'awardedBidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(bid.transporterId, 'Your bid won',
        'Your bid of LKR ${bid.amount.toStringAsFixed(0)} was accepted. Accept the delivery to start.',
        jobId);
    for (final o in others) {
      if (o.transporterId == bid.transporterId) continue;
      await _notify(o.transporterId, 'Bid not selected',
          'The farmer chose another transporter for this delivery.', jobId);
    }
  }

  Future<void> _notify(
      String? userId, String title, String body, String jobId) async {
    if (userId == null || userId.isEmpty || userId == _auth.currentUser?.uid) {
      return;
    }
    try {
      await sendNotification(_db, {
        'userId': userId,
        'title': title,
        'body': body.length > 500 ? body.substring(0, 500) : body,
        'type': 'logistics',
        'jobId': jobId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
