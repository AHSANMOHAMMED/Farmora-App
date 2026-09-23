class MarketPriceIndex {
  final String id;
  final String cropName;
  final String category;
  final String district;
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
      minPricePerKg: (map['minPricePerKg'] as num?)?.toDouble() ?? 0.0,
      maxPricePerKg: (map['maxPricePerKg'] as num?)?.toDouble() ?? 0.0,
      averagePricePerKg: (map['averagePricePerKg'] as num?)?.toDouble() ?? 0.0,
      trend: map['trend']?.toString() ?? 'stable',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  MarketPriceIndex copyWith({
    String? id,
    String? cropName,
    String? category,
    String? district,
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
      minPricePerKg: minPricePerKg ?? this.minPricePerKg,
      maxPricePerKg: maxPricePerKg ?? this.maxPricePerKg,
      averagePricePerKg: averagePricePerKg ?? this.averagePricePerKg,
      trend: trend ?? this.trend,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
