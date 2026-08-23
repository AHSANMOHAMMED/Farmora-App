import 'package:equatable/equatable.dart';

class MarketPrice extends Equatable {
  final String id;
  final String cropName;
  final double pricePerKg;
  final String marketName;
  final DateTime recordedDate;

  const MarketPrice({
    required this.id,
    required this.cropName,
    required this.pricePerKg,
    this.marketName = 'Dambulla',
    required this.recordedDate,
  });

  String get displayPrice => 'LKR ${pricePerKg.toStringAsFixed(0)}/kg';

  factory MarketPrice.fromJson(Map<String, dynamic> json) => MarketPrice(
        id: json['id'] as String,
        cropName: json['crop_name'] as String,
        pricePerKg: (json['price_per_kg'] as num).toDouble(),
        marketName: json['market_name'] as String? ?? 'Dambulla',
        recordedDate: DateTime.parse(json['recorded_date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_name': cropName,
        'price_per_kg': pricePerKg,
        'market_name': marketName,
        'recorded_date': recordedDate.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, cropName, pricePerKg, marketName, recordedDate];
}
