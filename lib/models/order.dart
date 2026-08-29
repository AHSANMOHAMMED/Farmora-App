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
  final String buyerPhone;
  final String deliveryAddress;
  final String detail;
  final String status; // 'Pending', 'Accepted', 'In transit', 'Delivered', 'Declined'
  final double progress;
  final Color color;
  final String timestamp;
  final String requestedDate;
  final IconData buyerIcon;

  const FarmoraOrder({
    required this.id,
    this.orderNumber = '#1042-B',
    required this.title,
    this.productName = '',
    this.quantity = '',
    this.grade = 'Grade A',
    this.unitPrice = '',
    this.totalAmount = '\$125.00',
    this.totalAmountNumber = 125.0,
    this.buyerName = 'Local Fresh Market',
    this.buyerCompany = 'Fresh Market Co.',
    this.buyerAvatar = 'assets/images/buyer_sarah.png',
    this.buyerPhone = '+1 (555) 234-5678',
    this.deliveryAddress = '450 West End Ave, Distribution Center Bay 4',
    required this.detail,
    required this.status,
    required this.progress,
    required this.color,
    this.timestamp = 'Today, 08:45 AM',
    this.requestedDate = 'Oct 24, 2024',
    this.buyerIcon = Icons.storefront_rounded,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isCompleted => status.toLowerCase() == 'delivered' || status.toLowerCase() == 'completed';
  bool get isDeclined => status.toLowerCase() == 'declined' || status.toLowerCase() == 'rejected';

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
      'buyerPhone': buyerPhone,
      'deliveryAddress': deliveryAddress,
      'detail': detail,
      'status': status,
      'progress': progress,
      'color': color.toARGB32(),
      'timestamp': timestamp,
      'requestedDate': requestedDate,
      'buyerIcon': iconKey,
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
    );
  }
}
