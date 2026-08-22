import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  rejected,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.inTransit:
        return 'In transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Progress from 0.0 to 1.0
  double get progress {
    switch (this) {
      case OrderStatus.pending:
        return 0.0;
      case OrderStatus.confirmed:
        return 0.2;
      case OrderStatus.rejected:
        return 0.0;
      case OrderStatus.assigned:
        return 0.4;
      case OrderStatus.pickedUp:
        return 0.6;
      case OrderStatus.inTransit:
        return 0.8;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }
}

enum PaymentStatus {
  unpaid,
  pending,
  paid,
  refunded,
  failed;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final int pricePerUnitMinor;
  final int subtotalMinor;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnitMinor,
    required this.subtotalMinor,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        pricePerUnitMinor: json['pricePerUnitMinor'] as int,
        subtotalMinor: json['subtotalMinor'] as int,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unit': unit,
        'pricePerUnitMinor': pricePerUnitMinor,
        'subtotalMinor': subtotalMinor,
      };

  @override
  List<Object?> get props => [
        productId, productName, quantity, unit,
        pricePerUnitMinor, subtotalMinor,
      ];
}

class OrderModel extends Equatable {
  final String id;
  final String buyerId;
  final String farmerId;
  final String? transporterId;
  final List<OrderItem> items;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int totalMinor;
  final String currency;
  final String? deliveryAddress;
  final String? pickupAddress;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    this.transporterId,
    this.items = const [],
    required this.subtotalMinor,
    this.deliveryFeeMinor = 0,
    required this.totalMinor,
    this.currency = 'LKR',
    this.deliveryAddress,
    this.pickupAddress,
    required this.status,
    this.paymentStatus = PaymentStatus.unpaid,
    this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  String get displayTotal => '$currency $totalMinor';
  String get displaySubtotal => '$currency $subtotalMinor';
  String get displayDeliveryFee => '$currency $deliveryFeeMinor';

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        buyerId: json['buyerId'] as String,
        farmerId: json['farmerId'] as String,
        transporterId: json['transporterId'] as String?,
        items: (json['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotalMinor: json['subtotalMinor'] as int,
        deliveryFeeMinor: json['deliveryFeeMinor'] as int? ?? 0,
        totalMinor: json['totalMinor'] as int,
        currency: json['currency'] as String? ?? 'LKR',
        deliveryAddress: json['deliveryAddress'] as String?,
        pickupAddress: json['pickupAddress'] as String?,
        status: OrderStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => OrderStatus.pending,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (p) => p.name == json['paymentStatus'],
          orElse: () => PaymentStatus.unpaid,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyerId': buyerId,
        'farmerId': farmerId,
        'transporterId': transporterId,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotalMinor': subtotalMinor,
        'deliveryFeeMinor': deliveryFeeMinor,
        'totalMinor': totalMinor,
        'currency': currency,
        'deliveryAddress': deliveryAddress,
        'pickupAddress': pickupAddress,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, buyerId, farmerId, transporterId, items,
        subtotalMinor, deliveryFeeMinor, totalMinor, currency,
        deliveryAddress, pickupAddress, status, paymentStatus,
        createdAt, updatedAt, deliveredAt,
      ];
}
