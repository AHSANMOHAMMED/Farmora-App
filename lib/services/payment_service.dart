import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/localization/l10n.dart';
import '../models/bank_details.dart';
import '../models/order.dart';
import 'service_errors.dart';

/// Farmer-direct payments (Cash on Delivery / Bank Deposit).
///
/// Every transition runs in a transaction that re-checks who the caller is and
/// what state the order is in; `firestore.rules` enforces the same constraints
/// server-side, so this works on the Spark plan without Cloud Functions.
class PaymentService {
  PaymentService({FirebaseFirestore? db, String Function()? currentUid})
      : _db = db ?? FirebaseFirestore.instance,
        _currentUid = currentUid;

  final FirebaseFirestore _db;
  final String Function()? _currentUid;

  String get _uid {
    final uid = _currentUid?.call() ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw UserStateError(L10n.current.errorSignInAgain);
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _bankRef(String farmerId) =>
      _db.collection('bank_details').doc(farmerId);

  // ── Bank details ─────────────────────────────────────────

  Future<BankDetails> getBankDetails(String farmerId) async {
    final snap = await _bankRef(farmerId).get();
    return BankDetails.fromMap(snap.data());
  }

  Stream<BankDetails> bankDetailsStream(String farmerId) => _bankRef(farmerId)
      .snapshots()
      .map((snap) => BankDetails.fromMap(snap.data()));

  Future<void> saveBankDetails(BankDetails details) async {
    if (!details.isComplete) {
      throw UserArgumentError(L10n.current.svcBankFieldsRequired);
    }
    await _bankRef(_uid).set({
      ...details.toMap(),
      'farmerId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Buyer: bank deposit slip ─────────────────────────────

  /// Links an uploaded deposit slip to the order and marks it for the
  /// farmer's review. Allowed until the farmer confirms (re-upload after a
  /// rejection replaces the previous slip).
  Future<void> submitPaymentProof({
    required String orderId,
    required String proofImageUrl,
    required String proofImagePath,
  }) async {
    final uid = _uid;
    if (!proofImagePath.startsWith('payment_slips/$orderId/')) {
      throw ArgumentError('Invalid payment slip.');
    }
    final ref = _db.collection('orders').doc(orderId);
    final order = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw UserStateError(L10n.current.svcOrderNotFound);
      final order = FarmoraOrder.fromMap(snap.id, data);
      if (order.buyerId != uid) throw UserStateError(L10n.current.errorNoPermission);
      if (!order.canSubmitProof) {
        throw UserStateError(order.isBankDeposit
            ? L10n.current.svcReceiptNotNeeded
            : L10n.current.svcReceiptBankOnly);
      }
      tx.update(ref, {
        'paymentStatus': 'proof_submitted',
        'proofImageUrl': proofImageUrl,
        'proofImagePath': proofImagePath,
        'proofSubmittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return order;
    });
    if (order.farmerId.isNotEmpty) {
      await _notify(
        order.farmerId,
        'Payment receipt submitted',
        'The buyer uploaded a deposit slip for ${order.displayTotal}. '
            'Check your account, then confirm or reject it.',
        orderId,
      );
    }
  }

  // ── Farmer confirmations ─────────────────────────────────

  /// COD: farmer confirms the buyer paid cash on delivery.
  Future<void> markCashReceived(String orderId) {
    return _farmerTransition(
      orderId,
      check: (order) {
        if (order.isBankDeposit) {
          throw UserStateError(L10n.current.svcPaidByBank);
        }
        if (!order.canMarkCashReceived) {
          throw UserStateError(L10n.current.svcCashAfterDelivery);
        }
      },
      update: {'paymentStatus': 'paid', 'paidAt': FieldValue.serverTimestamp()},
      notifyTitle: 'Cash received',
      notifyBody: (o) => 'The farmer confirmed your cash payment of '
          '${o.displayTotal}.',
    );
  }

  /// Bank deposit: farmer accepts the latest submitted receipt.
  Future<void> confirmBankPayment(String orderId) {
    return _farmerTransition(
      orderId,
      check: (order) {
        if (!order.canReviewProof) {
          throw UserStateError(L10n.current.svcNoReceiptWaiting);
        }
      },
      update: {
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      },
      notifyTitle: 'Payment confirmed',
      notifyBody: (o) => 'Your bank deposit of ${o.displayTotal} was confirmed.',
    );
  }

  /// Bank deposit: farmer rejects the receipt; buyer may upload a new one.
  Future<void> rejectBankPayment(String orderId, String reason) {
    final trimmed = reason.trim();
    if (trimmed.length < 3) {
      throw UserArgumentError(L10n.current.svcRejectReasonRequired);
    }
    return _farmerTransition(
      orderId,
      check: (order) {
        if (!order.canReviewProof) {
          throw UserStateError(L10n.current.svcNoReceiptWaiting);
        }
      },
      update: {'paymentStatus': 'rejected', 'rejectionReason': trimmed},
      notifyTitle: 'Payment receipt rejected',
      notifyBody: (_) => 'Reason: $trimmed. Please upload a new receipt.',
    );
  }

  Future<void> _farmerTransition(
    String orderId, {
    required void Function(FarmoraOrder order) check,
    required Map<String, dynamic> update,
    required String notifyTitle,
    required String Function(FarmoraOrder order) notifyBody,
  }) async {
    final uid = _uid;
    final ref = _db.collection('orders').doc(orderId);
    final order = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw UserStateError(L10n.current.svcOrderNotFound);
      final order = FarmoraOrder.fromMap(snap.id, data);
      if (order.farmerId != uid) throw UserStateError(L10n.current.errorNoPermission);
      check(order);
      tx.update(ref, {
        ...update,
        'paymentConfirmedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return order;
    });
    if (order.buyerId.isNotEmpty) {
      await _notify(order.buyerId, notifyTitle, notifyBody(order), orderId);
    }
  }

  Future<void> _notify(
      String userId, String title, String body, String orderId) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': 'payment',
      'referenceId': orderId,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
