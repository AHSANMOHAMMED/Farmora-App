import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/providers/farmora_state.dart';

void main() {
  group('Harvest video delivery cleanup flow', () {
    test('FarmoraOrder carries productId through toMap/fromMap', () {
      final order = FarmoraOrder(
        id: 'ORD-1',
        title: 'Carrot Delivery',
        productName: 'Nantes Carrots',
        detail: 'Direct order placed via Farmora Marketplace',
        status: 'Pending',
        progress: 0.2,
        color: const Color(0xFFE8F5E9),
        buyerId: 'buyer_1',
        farmerId: 'farmer_1',
        productId: 'prod-carrot-9',
      );

      final map = order.toMap();
      expect(map['productId'], 'prod-carrot-9');

      final restored = FarmoraOrder.fromMap('ORD-1', map);
      expect(restored.productId, 'prod-carrot-9');
      expect(restored.buyerId, 'buyer_1');
      expect(restored.farmerId, 'farmer_1');
    });

    test('copyWith preserves productId', () {
      final order = FarmoraOrder(
        id: 'ORD-2',
        title: 'Tea Delivery',
        detail: 'x',
        status: 'Accepted',
        progress: 0.6,
        color: const Color(0xFFE8F5E9),
        productId: 'prod-tea-3',
      );

      final delivered = order.copyWith(status: 'Delivered', progress: 1.0);
      expect(delivered.productId, 'prod-tea-3');
      expect(delivered.status, 'Delivered');
    });

    test('legacy orders without productId deserialize to empty string', () {
      final legacy = FarmoraOrder.fromMap('ORD-3', {
        'title': 'Old Order',
        'detail': 'x',
        'status': 'Delivered',
        'progress': 1.0,
        'color': 0xFFE8F5E9,
      });
      expect(legacy.productId, '');
    });

    test('Product video fields round-trip for cleanup targeting', () {
      const withVideo = Product(
        id: 'prod-v',
        name: 'Cherry Tomatoes',
        category: 'Vegetables',
        location: 'Nuwara Eliya',
        quantity: '10 kg',
        unit: 'kg',
        price: 'LKR 300',
        pricePerUnit: 300,
        emoji: '🍅',
        color: Color(0xFFFFE1DA),
        status: 'Active',
        isOrganic: true,
        trustLevel: 'Medium',
        description: '',
        videoUrl: 'https://storage.googleapis.com/farmora/v.mp4',
        videoPath: 'product_videos/farmer_1/prod-v_123_video.mp4',
        harvestStatus: HarvestStatus.harvested,
      );

      expect(withVideo.hasVideo, isTrue);
      expect(withVideo.videoPath, isNotEmpty);

      // Simulate cleanup: clear video fields and mark delivered.
      final cleaned = withVideo.copyWith(
        videoUrl: '',
        videoPath: '',
        harvestStatus: HarvestStatus.delivered,
      );
      expect(cleaned.hasVideo, isFalse);
      expect(cleaned.harvestStatus, HarvestStatus.delivered);
      // Trust level upgrades to High once delivered.
      expect(
        FarmoraState().trustLevelForProduct(cleaned),
        'High',
        reason: 'delivered harvest status must map to High trust',
      );
    });
  });
}
