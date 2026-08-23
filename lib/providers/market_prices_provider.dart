import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/market_price.dart';

/// Demo market prices for Dambulla and Manning Market
final marketPricesProvider = Provider<List<MarketPrice>>((ref) {
  final now = DateTime.now();
  return [
    MarketPrice(id: 'mp-1', cropName: 'Tomato', pricePerKg: 95, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-2', cropName: 'Green Chilli', pricePerKg: 220, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-3', cropName: 'Carrot', pricePerKg: 145, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-4', cropName: 'Leeks', pricePerKg: 180, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-5', cropName: 'Capsicum', pricePerKg: 260, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-6', cropName: 'Brinjal', pricePerKg: 75, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-7', cropName: 'Beans', pricePerKg: 130, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-8', cropName: 'Potato', pricePerKg: 105, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-9', cropName: 'Cabbage', pricePerKg: 60, marketName: 'Dambulla', recordedDate: now),
    MarketPrice(id: 'mp-10', cropName: 'Banana', pricePerKg: 85, marketName: 'Manning Market', recordedDate: now),
    MarketPrice(id: 'mp-11', cropName: 'Mango', pricePerKg: 195, marketName: 'Manning Market', recordedDate: now),
    MarketPrice(id: 'mp-12', cropName: 'Papaya', pricePerKg: 65, marketName: 'Manning Market', recordedDate: now),
  ];
});
