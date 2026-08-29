import 'package:flutter/material.dart';

class FarmoraOrder {
  final String id;
  final String title;
  final String detail;
  final String status;
  final double progress;
  final Color color;
  final String productName;
  final String buyerName;
  final String buyerCompany;
  final String buyerAvatar;
  final String buyerIcon;
  final String orderNumber;
  final String quantity;
  final String requestedDate;
  final String deliveryAddress;
  final String grade;
  final bool isPending;
  final bool isAccepted;
  final bool isCompleted;
  final String unitPrice;
  final String totalAmount;
  final String timestamp;

  const FarmoraOrder({
    required this.id,
    required this.title,
    this.detail = '',
    required this.status,
    this.progress = 0.0,
    this.color = const Color(0xff3478c5),
    this.productName = '',
    this.buyerName = '',
    this.buyerCompany = '',
    this.buyerAvatar = '',
    this.buyerIcon = '👤',
    this.orderNumber = '',
    this.quantity = '',
    this.requestedDate = '',
    this.deliveryAddress = '',
    this.grade = '',
    this.isPending = false,
    this.isAccepted = false,
    this.isCompleted = false,
    this.unitPrice = '',
    this.totalAmount = '',
    this.timestamp = '',
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'detail': detail,
    'status': status,
    'progress': progress,
    'color': color.value,
    'productName': productName,
    'buyerName': buyerName,
    'buyerCompany': buyerCompany,
    'buyerAvatar': buyerAvatar,
    'buyerIcon': buyerIcon,
    'orderNumber': orderNumber,
    'quantity': quantity,
    'requestedDate': requestedDate,
    'deliveryAddress': deliveryAddress,
    'grade': grade,
    'isPending': isPending,
    'isAccepted': isAccepted,
    'isCompleted': isCompleted,
    'unitPrice': unitPrice,
    'totalAmount': totalAmount,
    'timestamp': timestamp,
  };

  factory FarmoraOrder.fromMap(String id, Map<String, dynamic> m) => FarmoraOrder(
    id: id,
    title: m['title'] ?? '',
    detail: m['detail'] ?? '',
    status: m['status'] ?? '',
    progress: (m['progress'] ?? 0.0).toDouble(),
    color: Color(m['color'] ?? 0xff3478c5),
    productName: m['productName'] ?? '',
    buyerName: m['buyerName'] ?? '',
    buyerCompany: m['buyerCompany'] ?? '',
    buyerAvatar: m['buyerAvatar'] ?? '',
    buyerIcon: m['buyerIcon'] ?? '👤',
    orderNumber: m['orderNumber'] ?? '',
    quantity: m['quantity'] ?? '',
    requestedDate: m['requestedDate'] ?? '',
    deliveryAddress: m['deliveryAddress'] ?? '',
    grade: m['grade'] ?? '',
    isPending: m['isPending'] ?? false,
    isAccepted: m['isAccepted'] ?? false,
    isCompleted: m['isCompleted'] ?? false,
    unitPrice: m['unitPrice'] ?? '',
    totalAmount: m['totalAmount'] ?? '',
    timestamp: m['timestamp'] ?? '',
  );
}
