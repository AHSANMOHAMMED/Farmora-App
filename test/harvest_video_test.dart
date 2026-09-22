import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/product.dart';
import 'package:flutter/material.dart';

void main() {
  group('Harvest video product model', () {
    test('hasVideo true when url or path set', () {
      const withUrl = Product(
        id: 'p1',
        name: 'Carrots',
        category: 'Vegetables',
        location: 'Nuwara Eliya',
        quantity: '10 kg',
        unit: 'kg',
        price: 'LKR 100',
        pricePerUnit: 100,
        emoji: '🥕',
        color: Color(0xFFFFF3E0),
        status: 'Active',
        isOrganic: true,
        trustLevel: 'Medium',
        description: '',
        videoUrl: 'https://example.com/v.mp4',
        harvestStatus: HarvestStatus.harvested,
      );
      expect(withUrl.hasVideo, isTrue);
      expect(withUrl.harvestStatus, HarvestStatus.harvested);

      final withPath = withUrl.copyWith(
        videoUrl: '',
        videoPath: 'product_videos/u/p1.mp4',
      );
      expect(withPath.hasVideo, isTrue);

      withUrl.copyWith(videoUrl: '', videoPath: '');
      const none = Product(
        id: 'p2',
        name: 'Tea',
        category: 'Spices',
        location: 'Kandy',
        quantity: '5 kg',
        unit: 'kg',
        price: 'LKR 500',
        pricePerUnit: 500,
        emoji: '🍃',
        color: Color(0xFFE8F5E9),
        status: 'Active',
        isOrganic: true,
        trustLevel: 'Low',
        description: '',
      );
      expect(none.hasVideo, isFalse);
      expect(none.harvestStatus, HarvestStatus.growing);
    });

    test('fromMap restores video + harvest fields', () {
      final p = Product.fromMap('px', {
        'name': 'Cinnamon',
        'category': 'Spices',
        'location': 'Kandy',
        'quantity': '2 kg',
        'unit': 'kg',
        'price': 'LKR 4500',
        'pricePerUnit': 4500,
        'emoji': '🍂',
        'color': 0xFFFFE1DA,
        'status': 'Active',
        'isOrganic': true,
        'trustLevel': 'Medium',
        'description': '',
        'videoUrl': 'https://cdn/video.mp4',
        'videoPath': 'product_videos/a/b.mp4',
        'harvestStatus': 'packed',
        'qrCode': 'FARMORA:px:farmer:1',
      });
      expect(p.hasVideo, isTrue);
      expect(p.hasQrCode, isTrue);
      expect(p.harvestStatus, HarvestStatus.packed);
    });
  });
}
