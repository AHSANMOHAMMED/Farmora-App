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

  int get proposedPriceMinor => (proposedPrice * 100).round();

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
    };
  }

  factory FarmoraOffer.fromMap(String id, Map<String, dynamic> data) {
    final priceMinor = (data['proposedPriceMinor'] as num?)?.toInt();
    final proposedPrice = priceMinor != null
        ? priceMinor / 100.0
        : (data['proposedPrice'] as num?)?.toDouble() ?? 0.0;
    return FarmoraOffer(
      id: id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      buyerId: data['buyerId'] ?? '',
      farmerId: data['farmerId'] ?? '',
      proposedQuantity: (data['proposedQuantity'] as num?)?.toInt() ?? 0,
      proposedPrice: proposedPrice,
      status: data['status'] ?? 'pending',
      createdAt: firebaseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: firebaseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }
}
