import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> items;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int totalMinor;
  final String currency;
  final String paymentStatus;
  final String escrowStatus;
  final String deliveryStatus;
  final String? disputeId;

  FarmoraOrder({
    required this.id,
    this.orderNumber = '#1042-B',
    required this.title,
    this.productName = '',
    this.quantity = '',
    this.grade = 'Grade A',
    this.unitPrice = '',
    this.totalAmount = 'LKR 22,500.00',
    this.totalAmountNumber = 22500.0,
    this.buyerName = 'Local Fresh Market',
    this.buyerCompany = 'Fresh Market Co.',
    this.buyerAvatar = 'assets/images/buyer_sarah.png',
    this.buyerPhone = '',
    this.deliveryAddress = 'No. 42, Galle Road, Colombo 03',
    required this.detail,
    required this.status,
    required this.progress,
    required this.color,
    this.timestamp = 'Today, 08:45 AM',
    this.requestedDate = 'Oct 24, 2024',
    this.buyerIcon = Icons.storefront_rounded,
    DateTime? createdAt,
    this.buyerId = '',
    this.farmerId = '',
    this.transporterId = '',
    this.items = const [],
    this.subtotalMinor = 0,
    this.deliveryFeeMinor = 0,
    this.totalMinor = 0,
    this.currency = 'LKR',
    this.paymentStatus = 'payment_required',
    this.escrowStatus = 'not_funded',
    this.deliveryStatus = '',
    this.disputeId,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  static const activeStatuses = {
    'accepted',
    'confirmed',
    'assigned',
    'pickedup',
    'intransit',
    'in transit',
  };

  String get _norm => status.toLowerCase().replaceAll(' ', '').replaceAll('_', '');

  bool get isPending => _norm == 'pending';
  bool get isAccepted => activeStatuses.contains(_norm);
  bool get isCompleted => _norm == 'delivered' || _norm == 'completed';
  bool get isDeclined =>
      status.toLowerCase() == 'declined' || status.toLowerCase() == 'rejected';

  double get total =>
      totalMinor > 0 ? totalMinor / 100.0 : totalAmountNumber;

  String get displayTotal {
    if (totalMinor > 0) {
      return '$currency ${(totalMinor / 100).toStringAsFixed(2)}';
    }
    return totalAmount;
  }

  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'released';
  bool get isDisputed => disputeId != null && disputeId!.isNotEmpty || paymentStatus == 'disputed';
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
    List<Map<String, dynamic>>? items,
    int? subtotalMinor,
    int? deliveryFeeMinor,
    int? totalMinor,
    String? currency,
    String? paymentStatus,
    String? escrowStatus,
    String? deliveryStatus,
    String? disputeId,
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
      items: items ?? this.items,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor ?? this.deliveryFeeMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      disputeId: disputeId ?? this.disputeId,
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
      'items': items,
      'subtotalMinor': subtotalMinor,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': totalMinor,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'escrowStatus': escrowStatus,
      'deliveryStatus': deliveryStatus,
      'disputeId': disputeId,
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
      buyerAvatar: data['buyerAvatar'] ?? 'assets/images/buyer_sarah.png',
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
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
