import '../core/utils/firebase_values.dart';

class MarketPriceIndex {
  final String id;
  final String cropName;
  final String category;
  final String district;
  final String marketName;
  final String unit;
  final int reportCount;
  final double minPricePerKg;
  final double maxPricePerKg;
  final double averagePricePerKg;
  final String trend; // 'up', 'down', 'stable'
  final DateTime updatedAt;

  const MarketPriceIndex({
    required this.id,
    required this.cropName,
    required this.category,
    required this.district,
    this.marketName = '',
    this.unit = 'kg',
    this.reportCount = 0,
    required this.minPricePerKg,
    required this.maxPricePerKg,
    required this.averagePricePerKg,
    this.trend = 'stable',
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropName': cropName,
      'category': category,
      'district': district,
      'marketName': marketName,
      'unit': unit,
      'reportCount': reportCount,
      'minPricePerKg': minPricePerKg,
      'maxPricePerKg': maxPricePerKg,
      'averagePricePerKg': averagePricePerKg,
      'trend': trend,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MarketPriceIndex.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MarketPriceIndex(
      id: docId ?? map['id']?.toString() ?? '',
      cropName: map['cropName']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Vegetables',
      district: map['district']?.toString() ?? 'Dambulla',
      marketName: map['marketName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'kg',
      reportCount: firebaseInt(map['reportCount']) ?? 0,
      minPricePerKg: firebaseDouble(map['minPricePerKg']) ?? 0.0,
      maxPricePerKg: firebaseDouble(map['maxPricePerKg']) ?? 0.0,
      averagePricePerKg: firebaseDouble(map['averagePricePerKg']) ?? 0.0,
      trend: map['trend']?.toString() ?? 'stable',
      updatedAt: firebaseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  MarketPriceIndex copyWith({
    String? id,
    String? cropName,
    String? category,
    String? district,
    String? marketName,
    String? unit,
    int? reportCount,
    double? minPricePerKg,
    double? maxPricePerKg,
    double? averagePricePerKg,
    String? trend,
    DateTime? updatedAt,
  }) {
    return MarketPriceIndex(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      category: category ?? this.category,
      district: district ?? this.district,
      marketName: marketName ?? this.marketName,
      unit: unit ?? this.unit,
      reportCount: reportCount ?? this.reportCount,
      minPricePerKg: minPricePerKg ?? this.minPricePerKg,
      maxPricePerKg: maxPricePerKg ?? this.maxPricePerKg,
      averagePricePerKg: averagePricePerKg ?? this.averagePricePerKg,
      trend: trend ?? this.trend,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
