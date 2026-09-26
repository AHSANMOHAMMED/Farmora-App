import '../core/utils/firebase_values.dart';

class FarmoraOffer {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String farmerId;
  final int proposedQuantity;
  final double proposedPrice;
  final String status; // 'pending', 'accepted', 'rejected', 'countered'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String buyerName;
  final String farmerName;

  /// Unit the per-unit [proposedPrice] refers to (e.g. 'kg').
  final String unit;

  /// Order created when the offer was accepted (if any).
  final String? orderId;

  /// Price per unit in minor units (LKR cents). Offers are always per unit.
  int get proposedPriceMinor => (proposedPrice * 100).round();

  /// Offer value: per-unit price × quantity (LKR major units).
  double get totalPrice => proposedPrice * proposedQuantity;

  bool get isPending => status == 'pending';
  bool get isCountered => status == 'countered';

  FarmoraOffer({
    required this.id,
    required this.productId,
    this.productName = '',
    required this.buyerId,
    required this.farmerId,
    required this.proposedQuantity,
    required this.proposedPrice,
    this.status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.buyerName = '',
    this.farmerName = '',
    this.unit = 'kg',
    this.orderId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  FarmoraOffer copyWith({
    String? id,
    String? productId,
    String? productName,
    String? buyerId,
    String? farmerId,
    int? proposedQuantity,
    double? proposedPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? buyerName,
    String? farmerName,
    String? unit,
    String? orderId,
  }) {
    return FarmoraOffer(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      proposedQuantity: proposedQuantity ?? this.proposedQuantity,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerName: buyerName ?? this.buyerName,
      farmerName: farmerName ?? this.farmerName,
      unit: unit ?? this.unit,
      orderId: orderId ?? this.orderId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'farmerId': farmerId,
      'proposedQuantity': proposedQuantity,
      'proposedPrice': proposedPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'buyerName': buyerName,
      'farmerName': farmerName,
      'unit': unit,
      if (orderId != null) 'orderId': orderId,
    };
  }

  factory FarmoraOffer.fromMap(String id, Map<String, dynamic> data) {
    final priceMinor = firebaseInt(data['proposedPriceMinor']);
    final proposedPrice = priceMinor != null
        ? priceMinor / 100.0
        : firebaseDouble(data['proposedPrice']) ?? 0.0;
    return FarmoraOffer(
      id: id,
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      buyerId: (data['buyerId'] ?? '').toString(),
      farmerId: (data['farmerId'] ?? '').toString(),
      proposedQuantity: firebaseInt(data['proposedQuantity']) ?? 0,
      proposedPrice: proposedPrice,
      status: (data['status'] ?? 'pending').toString(),
      createdAt: firebaseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: firebaseDate(data['updatedAt']) ?? DateTime.now(),
      buyerName: (data['buyerName'] ?? '').toString(),
      farmerName: (data['farmerName'] ?? '').toString(),
      unit: (data['unit'] ?? 'kg').toString(),
      orderId: data['orderId']?.toString(),
    );
  }
}
