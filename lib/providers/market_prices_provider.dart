import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/market_price.dart';

/// Firestore-backed market prices provider.
/// Reads from the 'market_prices' collection in Firestore.
final marketPricesProvider = StreamProvider<List<MarketPrice>>((ref) {
  return FirebaseFirestore.instance
      .collection('market_prices')
      .orderBy('recorded_date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MarketPrice.fromJson(data);
    }).toList();
  });
});

/// Provider that returns market prices as a Future (for one-time reads).
final marketPricesFutureProvider = FutureProvider<List<MarketPrice>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('market_prices')
      .orderBy('recorded_date', descending: true)
      .get();
  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return MarketPrice.fromJson(data);
  }).toList();
});
