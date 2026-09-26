import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/localization/l10n.dart';
import '../models/bank_details.dart';
import '../models/order.dart';
import 'service_errors.dart';

/// Farmer-direct payments (Cash on Delivery / Bank Deposit).
///
/// Every transition runs in a transaction that re-checks who the caller is and
/// what state the order is in; `firestore.rules` enforces the same constraints
/// server-side. Notifications for payment changes are written by the
/// `onOrderPaymentStatusChanged` Cloud Function trigger, not by the client.
class PaymentService {
  PaymentService({
    FirebaseFirestore? db,
    String Function()? currentUid,
    FirebaseFunctions? functions,
  })  : _db = db ?? FirebaseFirestore.instance,
        _currentUid = currentUid,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final String Function()? _currentUid;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

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

  /// The signed-in farmer's own bank details (rules: owner/admin only).
  Future<BankDetails> getBankDetails(String farmerId) async {
    final snap = await _bankRef(farmerId).get();
    return BankDetails.fromMap(snap.data());
  }

  /// Checkout: whether [farmerId] accepts bank deposits. Buyers cannot read
  /// `bank_details`, so this goes through `getFarmerBankDetails {farmerId}`.
  Future<bool> farmerAcceptsBankDeposit(String farmerId) async {
    final result = await _functions
        .httpsCallable('getFarmerBankDetails')
        .call({'farmerId': farmerId});
    final data = result.data;
    return data is Map && data['available'] == true;
  }

  /// Bank account to pay for [order]. Prefers the snapshot taken when the
  /// order was created; otherwise asks `getFarmerBankDetails {orderId}`
  /// (allowed for the buyer of a bank-deposit order).
  Future<BankDetails> bankDetailsForOrder(FarmoraOrder order) async {
    final snapshot = order.bankDetailsSnapshot;
    if (snapshot != null && snapshot.isComplete) return snapshot;
    final result = await _functions
        .httpsCallable('getFarmerBankDetails')
        .call({'orderId': order.id});
    final data = result.data;
    if (data is! Map) return BankDetails.empty;
    final details = data['details'] ?? data['bankDetails'] ?? data;
    return details is Map
        ? BankDetails.fromMap(Map<String, dynamic>.from(details))
        : BankDetails.empty;
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
    await _db.runTransaction((tx) async {
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
    });
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
    );
  }

  Future<void> _farmerTransition(
    String orderId, {
    required void Function(FarmoraOrder order) check,
    required Map<String, dynamic> update,
  }) async {
    final uid = _uid;
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
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
    });
  }
}
