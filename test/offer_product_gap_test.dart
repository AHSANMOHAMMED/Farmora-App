import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/offer.dart';
import 'package:farmora/models/product.dart';

void main() {
  group('FarmoraOffer', () {
    test('fromMap prefers proposedPriceMinor when present', () {
      final offer = FarmoraOffer.fromMap('off-1', {
        'productId': 'prod-1',
        'productName': 'Tomatoes',
        'buyerId': 'buyer-1',
        'farmerId': 'farmer-1',
        'proposedQuantity': 5,
        'proposedPrice': 999,
        'proposedPriceMinor': 25000,
        'status': 'pending',
      });

      expect(offer.farmerId, 'farmer-1');
      expect(offer.buyerId, 'buyer-1');
      expect(offer.proposedQuantity, 5);
      expect(offer.proposedPriceMinor, 25000);
      expect(offer.proposedPrice, 250.0);
    });

    test('toMap includes farmer and buyer ids for routing', () {
      final offer = FarmoraOffer(
        id: 'off-2',
        productId: 'prod-2',
        productName: 'Carrots',
        buyerId: 'buyer-2',
        farmerId: 'farmer-2',
        proposedQuantity: 3,
        proposedPrice: 120,
      );

      final map = offer.toMap();
      expect(map['farmerId'], 'farmer-2');
      expect(map['buyerId'], 'buyer-2');
      expect(map['productId'], 'prod-2');
      expect(map['status'], 'pending');
    });
  });

  group('Product create payload fields', () {
    test('quantityAvailable and media urls are available for secure create',
        () {
      const product = Product(
        name: 'Beans',
        category: 'Vegetables',
        location: 'Local Farm',
        quantity: '20 kg available',
        unit: 'kg',
        price: 'LKR 150.00 / kg',
        pricePerUnit: 150,
        priceMinor: 15000,
        quantityAvailable: 20,
        media: ['https://example.com/a.jpg'],
        imageUrls: ['https://example.com/a.jpg'],
        images: ['https://example.com/a.jpg'],
        farmerId: 'farmer-9',
      );

      expect(product.quantityAvailable, 20);
      expect(product.media.first.startsWith('http'), isTrue);
      expect(product.farmerId, 'farmer-9');
      expect(
          int.tryParse(RegExp(r'\d+').firstMatch(product.quantity)!.group(0)!),
          20);
    });
  });
}
