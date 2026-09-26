import '../core/localization/app_format.dart';
import '../core/localization/l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import '../core/utils/firebase_values.dart';

import 'bank_details.dart';

/// How the buyer pays the farmer.
class PaymentMethod {
  static const cod = 'cod';
  static const bankDeposit = 'bank_deposit';

  /// Methods a buyer may choose at checkout.
  static const checkoutMethods = [cod, bankDeposit];

  static const payHere = 'payhere';

  static String label(String method) => switch (method) {
        bankDeposit => L10n.current.payMethodBankDeposit,
        payHere => L10n.current.payMethodOnline,
        _ => L10n.current.payMethodCod,
      };
}

/// Normalised payment lifecycle. Legacy escrow/PayHere values stored in
/// `paymentStatus` are mapped onto these so old orders still count correctly.
enum PaymentState { pending, proofSubmitted, paid, rejected, refunded, disputed }

/// Parses Firestore Timestamps, ISO strings and epoch millis.
DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}

class FarmoraOrder {
  final String id;
  final String orderNumber;
  final String title;
  final String productName;
  final String quantity;
  final String grade;
  final String unitPrice;
  final String totalAmount;
  final double totalAmountNumber;
  final String buyerName;
  final String buyerCompany;
  final String buyerAvatar;

  /// Always empty in marketplace data. Contact is handled by in-app messaging.
  final String buyerPhone;
  final String deliveryAddress;
  final String detail;
  final String
      status; // 'Pending', 'Accepted', 'In transit', 'Delivered', 'Declined'
  final double progress;
  final Color color;
  final String timestamp;
  final String requestedDate;
  final IconData buyerIcon;
  final DateTime createdAt;
  // Backend (Cloud Functions) schema fields.
  final String buyerId;
  final String farmerId;
  final String transporterId;

  /// Product linked to this order. Used to clean up the harvest video on
  /// delivery (videos are auto-deleted once an order completes).
  final String productId;
  final List<Map<String, dynamic>> items;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int totalMinor;
  final String currency;
  final String paymentStatus;
  final String escrowStatus;
  final String deliveryStatus;
  final String? disputeId;
  // Farmer-direct payment (COD / bank deposit) fields.
  final String paymentMethod;
  final DateTime? paidAt;
  final String? proofImageUrl;
  final String? rejectionReason;
  final BankDetails? bankDetailsSnapshot;

  FarmoraOrder({
    required this.id,
    this.orderNumber = '',
    required this.title,
    this.productName = '',
    this.quantity = '',
    this.grade = '',
    this.unitPrice = '',
    this.totalAmount = '',
    this.totalAmountNumber = 0.0,
    this.buyerName = '',
    this.buyerCompany = '',
    this.buyerAvatar = '',
    this.buyerPhone = '',
    this.deliveryAddress = '',
    required this.detail,
    required this.status,
    required this.progress,
    required this.color,
    this.timestamp = '',
    this.requestedDate = '',
    this.buyerIcon = Icons.storefront_rounded,
    DateTime? createdAt,
    this.buyerId = '',
    this.farmerId = '',
    this.transporterId = '',
    this.productId = '',
    this.items = const [],
    this.subtotalMinor = 0,
    this.deliveryFeeMinor = 0,
    this.totalMinor = 0,
    this.currency = 'LKR',
    this.paymentStatus = 'payment_required',
    this.escrowStatus = 'not_funded',
    this.deliveryStatus = '',
    this.disputeId,
    this.paymentMethod = PaymentMethod.cod,
    this.paidAt,
    this.proofImageUrl,
    this.rejectionReason,
    this.bankDetailsSnapshot,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  static const activeStatuses = {
    'accepted',
    'confirmed',
    'assigned',
    'pickedup',
    'intransit',
    'in transit',
  };

  String get _norm =>
      status.toLowerCase().replaceAll(' ', '').replaceAll('_', '');

  bool get isPending => _norm == 'pending';
  bool get isAccepted => activeStatuses.contains(_norm);
  bool get isCompleted => _norm == 'delivered' || _norm == 'completed';
  bool get isDeclined =>
      status.toLowerCase() == 'declined' || status.toLowerCase() == 'rejected';
  bool get isCancelled => isDeclined || _norm == 'cancelled' || _norm == 'canceled';

  double get total => totalMinor > 0 ? totalMinor / 100.0 : totalAmountNumber;

  String get displayTotal {
    if (totalMinor > 0) {
      final amount = totalMinor / 100;
      return currency == 'LKR'
          ? AppFormat.lkr(amount, decimals: 2)
          : '$currency ${amount.toStringAsFixed(2)}';
    }
    return totalAmount;
  }

  PaymentState get paymentState {
    switch (paymentStatus.toLowerCase().trim()) {
      case 'proof_submitted':
        return PaymentState.proofSubmitted;
      case 'paid':
      case 'released':
      case 'paid (escrow)':
      case 'settled_split':
        return PaymentState.paid;
      case 'rejected':
        return PaymentState.rejected;
      case 'refunded':
        return PaymentState.refunded;
      case 'disputed':
        return PaymentState.disputed;
      default: // pending, payment_required, unpaid, payment_failed
        return PaymentState.pending;
    }
  }

  bool get isBankDeposit => paymentMethod == PaymentMethod.bankDeposit;

  /// Money still owed to the farmer: unpaid, not cancelled/refunded/disputed.
  bool get isAwaitingPayment =>
      !isCancelled &&
      (paymentState == PaymentState.pending ||
          paymentState == PaymentState.proofSubmitted ||
          paymentState == PaymentState.rejected);

  /// Farmer can confirm cash once the goods reached the buyer.
  bool get canMarkCashReceived =>
      !isBankDeposit && isCompleted && isAwaitingPayment;

  /// Farmer can confirm/reject only when a deposit slip is waiting.
  bool get canReviewProof =>
      isBankDeposit && paymentState == PaymentState.proofSubmitted;

  /// Buyer can (re)upload a slip until the farmer confirms.
  bool get canSubmitProof =>
      isBankDeposit && !isCancelled &&
      (paymentState == PaymentState.pending ||
          paymentState == PaymentState.proofSubmitted ||
          paymentState == PaymentState.rejected);

  String get paymentStatusLabel => switch (paymentState) {
        PaymentState.pending => isBankDeposit
            ? L10n.current.paymentAwaitingDeposit
            : L10n.current.paymentCashDue,
        PaymentState.proofSubmitted => L10n.current.paymentReceiptSubmitted,
        PaymentState.paid => L10n.current.statusPaid,
        PaymentState.rejected => L10n.current.paymentReceiptRejected,
        PaymentState.refunded => L10n.current.statusRefunded,
        PaymentState.disputed => L10n.current.statusDisputed,
      };
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'released';
  bool get isDisputed =>
      disputeId != null && disputeId!.isNotEmpty || paymentStatus == 'disputed';
  bool get canReview => isCompleted && !isDisputed;

  FarmoraOrder copyWith({
    String? id,
    String? orderNumber,
    String? title,
    String? productName,
    String? quantity,
    String? grade,
    String? unitPrice,
    String? totalAmount,
    double? totalAmountNumber,
    String? buyerName,
    String? buyerCompany,
    String? buyerAvatar,
    String? buyerPhone,
    String? deliveryAddress,
    String? detail,
    String? status,
    double? progress,
    Color? color,
    String? timestamp,
    String? requestedDate,
    IconData? buyerIcon,
    DateTime? createdAt,
    String? buyerId,
    String? farmerId,
    String? transporterId,
    String? productId,
    List<Map<String, dynamic>>? items,
    int? subtotalMinor,
    int? deliveryFeeMinor,
    int? totalMinor,
    String? currency,
    String? paymentStatus,
    String? escrowStatus,
    String? deliveryStatus,
    String? disputeId,
    String? paymentMethod,
    DateTime? paidAt,
    String? proofImageUrl,
    String? rejectionReason,
    BankDetails? bankDetailsSnapshot,
  }) {
    return FarmoraOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      title: title ?? this.title,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      grade: grade ?? this.grade,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      totalAmountNumber: totalAmountNumber ?? this.totalAmountNumber,
      buyerName: buyerName ?? this.buyerName,
      buyerCompany: buyerCompany ?? this.buyerCompany,
      buyerAvatar: buyerAvatar ?? this.buyerAvatar,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
      requestedDate: requestedDate ?? this.requestedDate,
      buyerIcon: buyerIcon ?? this.buyerIcon,
      createdAt: createdAt ?? this.createdAt,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      transporterId: transporterId ?? this.transporterId,
      productId: productId ?? this.productId,
      items: items ?? this.items,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor ?? this.deliveryFeeMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      disputeId: disputeId ?? this.disputeId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      bankDetailsSnapshot: bankDetailsSnapshot ?? this.bankDetailsSnapshot,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    // Map common IconData to a string key for Firestore
    String iconKey = 'storefront';
    if (buyerIcon == Icons.restaurant_rounded) {
      iconKey = 'restaurant';
    }
    return {
      'orderNumber': orderNumber,
      'title': title,
      'productName': productName,
      'quantity': quantity,
      'grade': grade,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'totalAmountNumber': totalAmountNumber,
      'buyerName': buyerName,
      'buyerCompany': buyerCompany,
      'buyerAvatar': buyerAvatar,
      // Never persist or expose personal contact information in an order.
      'deliveryAddress': deliveryAddress,
      'detail': detail,
      'status': status,
      'progress': progress,
      'color': color.toARGB32(),
      'timestamp': timestamp,
      'requestedDate': requestedDate,
      'buyerIcon': iconKey,
      'createdAt': createdAt.toIso8601String(),
      'buyerId': buyerId,
      'farmerId': farmerId,
      'transporterId': transporterId,
      'productId': productId,
      'items': items,
      'subtotalMinor': subtotalMinor,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': totalMinor,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'escrowStatus': escrowStatus,
      'deliveryStatus': deliveryStatus,
      'disputeId': disputeId,
      'paymentMethod': paymentMethod,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (bankDetailsSnapshot != null)
        'bankDetailsSnapshot': bankDetailsSnapshot!.toMap(),
    };
  }

  /// Deserialize from Firestore Map
  factory FarmoraOrder.fromMap(String id, Map<String, dynamic> data) {
    // Map string key back to IconData
    IconData iconData = Icons.storefront_rounded;
    if (data['buyerIcon'] == 'restaurant') {
      iconData = Icons.restaurant_rounded;
    }

    return FarmoraOrder(
      id: id,
      orderNumber: data['orderNumber'] ?? '',
      title: data['title'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? '',
      grade: data['grade'] ?? '',
      unitPrice: data['unitPrice'] ?? '',
      totalAmount: data['totalAmount'] ?? '',
      totalAmountNumber: (data['totalAmountNumber'] as num?)?.toDouble() ?? 0.0,
      buyerName: data['buyerName'] ?? '',
      buyerCompany: data['buyerCompany'] ?? '',
      buyerAvatar: data['buyerAvatar'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      detail: data['detail'] ?? '',
      status: data['status'] ?? 'Pending',
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      color: Color(data['color'] as int? ?? 0xFF3478C5),
      timestamp: data['timestamp'] ?? '',
      requestedDate: data['requestedDate'] ?? '',
      buyerIcon: iconData,
      buyerId: (data['buyerId'] ?? '').toString(),
      farmerId: (data['farmerId'] ?? '').toString(),
      transporterId: (data['transporterId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      items: (data['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      subtotalMinor: (data['subtotalMinor'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (data['deliveryFeeMinor'] as num?)?.toInt() ?? 0,
      totalMinor: (data['totalMinor'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'LKR').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'payment_required').toString(),
      escrowStatus: (data['escrowStatus'] ?? 'not_funded').toString(),
      deliveryStatus: (data['deliveryStatus'] ?? '').toString(),
      disputeId: data['disputeId'] as String?,
      createdAt: firebaseDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paymentMethod: (data['paymentMethod'] ?? PaymentMethod.cod).toString(),
      paidAt: firebaseDate(data['paidAt']),
      proofImageUrl: data['proofImageUrl'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      bankDetailsSnapshot: data['bankDetailsSnapshot'] is Map
          ? BankDetails.fromMap(
              Map<String, dynamic>.from(data['bankDetailsSnapshot'] as Map))
          : null,
    );
  }
}
