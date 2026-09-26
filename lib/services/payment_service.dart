import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_backend.dart';
import '../core/localization/l10n.dart';
import '../models/bank_details.dart';
import '../models/order.dart';
import 'service_errors.dart';
import 'spark_backend.dart';

/// Farmer-direct payments (Cash on Delivery / Bank Deposit).
///
/// Every transition runs in a transaction that re-checks who the caller is and
/// what state the order is in; `firestore.rules` enforces the same constraints
/// server-side. Notifications for payment changes are written by the
/// `onOrderPaymentStatusChanged` Cloud Function trigger in Cloud Functions
/// mode; on the Spark plan the acting client writes them (best effort).
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

  /// Checkout: whether [farmerId] accepts bank deposits. Spark reads
  /// `bank_details` directly (readable by signed-in users: deposit
  /// instructions); Cloud Functions mode asks `getFarmerBankDetails`.
  Future<bool> farmerAcceptsBankDeposit(String farmerId) async {
    if (!kUseCloudFunctions) {
      final snap = await _bankRef(farmerId).get();
      return SparkBackend.usableBank(snap.data()) != null;
    }
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
    if (!kUseCloudFunctions) {
      if (order.farmerId.isEmpty) return BankDetails.empty;
      final bank = SparkBackend.usableBank((await _bankRef(order.farmerId).get()).data());
      return bank == null ? BankDetails.empty : BankDetails.fromMap(bank);
    }
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
      return order;
    }).then((order) => _notifySpark(
          order.farmerId,
          'Payment proof submitted',
          'The buyer uploaded a bank deposit slip. Please verify it.',
          orderId,
        ));
  }

  /// Spark only: the other party's in-app payment notification (the
  /// `onOrderPaymentStatusChanged` trigger does this with Cloud Functions).
  Future<void> _notifySpark(
      String userId, String title, String body, String orderId) async {
    if (kUseCloudFunctions || userId.isEmpty) return;
    try {
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
    } catch (_) {
      // Best effort: the payment change itself already succeeded.
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
    final rejected = update['paymentStatus'] == 'rejected';
    await _notifySpark(
      order.buyerId,
      rejected ? 'Payment proof rejected' : 'Payment confirmed',
      rejected
          ? 'The farmer rejected your deposit slip: ${update['rejectionReason']}. '
              'Please upload a new slip.'
          : 'Your payment for ${order.title.isEmpty ? 'your order' : order.title} was confirmed.',
      orderId,
    );
  }
}
