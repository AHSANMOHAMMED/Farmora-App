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

  /// Farmer display name snapshotted on the order by the backend.
  final String farmerName;

  /// Unit of [quantity] (e.g. 'kg').
  final String unit;

  /// Platform commission (minor units) deducted from the farmer payout.
  final int platformFeeMinor;

  /// Transporter the buyer picked at checkout (before they accept the job).
  final String requestedTransporterId;

  /// When the farmer confirmed handing the goods to the transporter.
  final DateTime? farmerHandedOverAt;
  final DateTime? updatedAt;

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
    this.farmerName = '',
    this.unit = '',
    this.platformFeeMinor = 0,
    this.requestedTransporterId = '',
    this.farmerHandedOverAt,
    this.updatedAt,
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

  /// Farmer's share after the platform fee (LKR major units).
  double get farmerNet => (totalMinor - platformFeeMinor) / 100.0;

  /// Platform fee in LKR major units.
  double get platformFee => platformFeeMinor / 100.0;

  /// Human order reference: backend `orderNumber`, else a short id.
  String get displayNumber => orderNumber.isNotEmpty
      ? orderNumber
      : 'FM-${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';

  /// Canonical lifecycle key for any stored status spelling. One of:
  /// pending, confirmed, assigned, pickedUp, inTransit, delivered,
  /// completed, cancelled, rejected.
  String get statusKey => normalizeStatus(status);

  /// Timeline step for progress UIs: 0 placed/pending, 1 confirmed/assigned,
  /// 2 picked up/in transit, 3 delivered/completed. Cancelled and rejected
  /// orders report 0 — check [isCancelled] first.
  int get statusStep => switch (statusKey) {
        'confirmed' || 'assigned' => 1,
        'pickedUp' || 'inTransit' => 2,
        'delivered' || 'completed' => 3,
        _ => 0,
      };

  /// Maps legacy/display status spellings ('Accepted', 'In transit',
  /// 'picked_up', 'Declined', ...) onto the backend lifecycle keys.
  static String normalizeStatus(String raw) {
    final n = raw.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (n) {
      '' || 'pending' || 'placed' || 'new' => 'pending',
      'accepted' || 'confirmed' => 'confirmed',
      'assigned' => 'assigned',
      'pickedup' || 'collected' => 'pickedUp',
      'intransit' => 'inTransit',
      'delivered' => 'delivered',
      'completed' => 'completed',
      'cancelled' || 'canceled' => 'cancelled',
      'declined' || 'rejected' => 'rejected',
      _ => raw,
    };
  }

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
    String? farmerName,
    String? unit,
    int? platformFeeMinor,
    String? requestedTransporterId,
    DateTime? farmerHandedOverAt,
    DateTime? updatedAt,
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
      farmerName: farmerName ?? this.farmerName,
      unit: unit ?? this.unit,
      platformFeeMinor: platformFeeMinor ?? this.platformFeeMinor,
      requestedTransporterId:
          requestedTransporterId ?? this.requestedTransporterId,
      farmerHandedOverAt: farmerHandedOverAt ?? this.farmerHandedOverAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'farmerName': farmerName,
      'unit': unit,
      'platformFeeMinor': platformFeeMinor,
    };
  }

  /// Deserialize from Firestore Map
  factory FarmoraOrder.fromMap(String id, Map<String, dynamic> data) {
    // Map string key back to IconData
    IconData iconData = Icons.storefront_rounded;
    if (data['buyerIcon'] == 'restaurant') {
      iconData = Icons.restaurant_rounded;
    }

    String str(Object? v) => v == null ? '' : v.toString();
    final items = (data['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final firstItem =
        items.isNotEmpty ? items.first : const <String, dynamic>{};
    final unit = str(data['unit'] ?? firstItem['unit']);
    final rawQuantity =
        data['quantity'] ?? data['quantityValue'] ?? firstItem['quantity'];
    final quantity = rawQuantity is num
        ? '${rawQuantity % 1 == 0 ? rawQuantity.toInt() : rawQuantity}'
            '${unit.isNotEmpty ? ' $unit' : ''}'
        : str(rawQuantity);

    return FarmoraOrder(
      id: id,
      orderNumber: str(data['orderNumber']),
      title: str(data['title']),
      productName: str(data['productName'] ??
          firstItem['productName'] ??
          firstItem['name']),
      quantity: quantity,
      grade: str(data['grade']),
      unitPrice: str(data['unitPrice']),
      totalAmount: str(data['totalAmount']),
      totalAmountNumber: firebaseDouble(data['totalAmountNumber']) ?? 0.0,
      buyerName: str(data['buyerName']),
      buyerCompany: str(data['buyerCompany']),
      buyerAvatar: str(data['buyerAvatar']),
      buyerPhone: str(data['buyerPhone']),
      deliveryAddress: str(data['deliveryAddress']),
      detail: str(data['detail']),
      status: data['status'] == null ? 'Pending' : str(data['status']),
      progress: firebaseDouble(data['progress']) ?? 0.0,
      color: Color(firebaseInt(data['color']) ?? 0xFF3478C5),
      timestamp: str(data['timestamp']),
      requestedDate: str(data['requestedDate']),
      buyerIcon: iconData,
      buyerId: str(data['buyerId']),
      farmerId: str(data['farmerId']),
      transporterId: str(data['transporterId']),
      productId: str(data['productId'] ?? firstItem['productId']),
      items: items,
      subtotalMinor: firebaseInt(data['subtotalMinor']) ?? 0,
      deliveryFeeMinor: firebaseInt(data['deliveryFeeMinor']) ?? 0,
      totalMinor: firebaseInt(data['totalMinor']) ?? 0,
      currency: str(data['currency'] ?? 'LKR'),
      paymentStatus: str(data['paymentStatus'] ?? 'payment_required'),
      escrowStatus: str(data['escrowStatus'] ?? 'not_funded'),
      deliveryStatus: str(data['deliveryStatus']),
      disputeId: data['disputeId']?.toString(),
      createdAt: firebaseDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paymentMethod: str(data['paymentMethod'] ?? PaymentMethod.cod),
      paidAt: firebaseDate(data['paidAt']),
      proofImageUrl: data['proofImageUrl']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
      bankDetailsSnapshot: data['bankDetailsSnapshot'] is Map
          ? BankDetails.fromMap(
              Map<String, dynamic>.from(data['bankDetailsSnapshot'] as Map))
          : null,
      farmerName: str(data['farmerName']),
      unit: unit,
      platformFeeMinor: firebaseInt(data['platformFeeMinor']) ?? 0,
      requestedTransporterId: str(data['requestedTransporterId']),
      farmerHandedOverAt: firebaseDate(data['farmerHandedOverAt']),
      updatedAt: firebaseDate(data['updatedAt']),
    );
  }
}
