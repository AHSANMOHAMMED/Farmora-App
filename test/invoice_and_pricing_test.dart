import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:farmora/core/utils/invoice_pdf.dart';
import 'package:farmora/features/farmer/presentation/listing_assist.dart';
import 'package:farmora/models/market_price_index.dart';
import 'package:farmora/models/order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  test('invoice PDFs are generated for buyer and farmer copies', () async {
    final order = FarmoraOrder(
      id: 'o1',
      orderNumber: 'FM-TEST01',
      title: 'Carrots',
      productName: 'Carrots',
      quantity: '2 kg',
      unitPrice: 'LKR 350',
      totalAmount: 'LKR 1,050',
      totalAmountNumber: 1050,
      buyerName: 'Test Buyer',
      deliveryAddress: '12 Galle Road, Colombo',
      detail: '',
      status: 'Delivered',
      progress: 1,
      color: const Color(0xFFE8F5E9),
      subtotalMinor: 70000,
      deliveryFeeMinor: 35000,
      totalMinor: 105000,
      platformFeeMinor: 1750,
      farmerName: 'Test Farmer',
      items: const [
        {'productId': 'p', 'quantity': 2, 'pricePerUnitMinor': 35000},
      ],
    );
    for (final farmer in [false, true]) {
      final bytes = await buildInvoicePdf(order, farmerCopy: farmer);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    }
  });

  test('market price matching prefers the same district', () {
    MarketPriceIndex p(String crop, String district) => MarketPriceIndex(
          id: '$crop$district',
          cropName: crop,
          category: 'Vegetables',
          district: district,
          marketName: 'Dambulla',
          unit: 'kg',
          reportCount: 3,
          minPricePerKg: 100,
          maxPricePerKg: 200,
          averagePricePerKg: 150,
          trend: 'up',
          updatedAt: DateTime(2026, 9, 1),
        );
    final prices = [p('Carrot', 'Colombo'), p('Carrot', 'Nuwara Eliya'), p('Beans', 'Kandy')];
    expect(matchPrice(prices, 'Fresh carrot', 'Nuwara Eliya')?.district, 'Nuwara Eliya');
    expect(matchPrice(prices, 'carrot', 'Galle')?.cropName, 'Carrot');
    expect(matchPrice(prices, 'Mango', 'Kandy'), isNull);
    expect(matchPrice(prices, 'ca', 'Kandy'), isNull);
  });
}
