import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Farmer Core Features Integration Tests', () {
    late FarmoraState state;

    setUp(() {
      state = FarmoraState();
    });

    test('1. Farmer can list produce optimistically with district and pricing',
        () {
      final initialProductCount = state.products.length;

      const newProduct = Product(
        id: 'prod-test-kandy',
        name: 'Kandy Red Bell Peppers',
        category: 'Vegetables',
        price: 'LKR 450.00 / kg',
        location: 'Kandy',
        quantity: '300 kg',
        pricePerUnit: 450.0,
        unit: 'kg',
        farmerId: 'farmer_demo_1',
      );

      state.addProduct(newProduct);

      expect(state.products.length, initialProductCount + 1);
      final added = state.products.firstWhere((p) => p.id == 'prod-test-kandy');
      expect(added.name, 'Kandy Red Bell Peppers');
      expect(added.location, 'Kandy');
      expect(added.pricePerUnit, 450.0);
    });

    test('2. Farmer can receive, counter, and accept buyer offers', () async {
      // Create initial offer from buyer
      await state.makeOffer(
        productId: 'prod-1',
        productName: 'Organic Red Tomatoes',
        farmerId: 'farmer_demo_1',
        quantity: 100,
        price: 220.0,
      );

      expect(state.farmerOffers.isNotEmpty, isTrue);
      final createdOffer = state.farmerOffers.first;
      expect(createdOffer.status, 'pending');
      expect(createdOffer.proposedPrice, 220.0);

      // Farmer counters offer to 240 LKR
      await state.counterOffer(createdOffer.id, 240.0);
      final counteredOffer =
          state.farmerOffers.firstWhere((o) => o.id == createdOffer.id);
      expect(counteredOffer.status, 'countered');
      expect(counteredOffer.proposedPrice, 240.0);

      // Accept offer -> creates confirmed order
      final initialOrderCount = state.orders.length;
      await state.acceptOffer(counteredOffer.id);

      final acceptedOffer =
          state.farmerOffers.firstWhere((o) => o.id == createdOffer.id);
      expect(acceptedOffer.status, 'accepted');
      expect(state.orders.length, initialOrderCount + 1);

      final newOrder = state.orders.first;
      expect(newOrder.productName, 'Organic Red Tomatoes');
      expect(newOrder.status, 'Accepted');
    });

    test('3. Farmer can reject buyer offers', () async {
      await state.makeOffer(
        productId: 'prod-2',
        productName: 'Sweet Carrots',
        farmerId: 'farmer_demo_1',
        quantity: 50,
        price: 150.0,
      );

      final offer = state.farmerOffers.first;
      await state.rejectOffer(offer.id);

      final rejected = state.farmerOffers.firstWhere((o) => o.id == offer.id);
      expect(rejected.status, 'rejected');
    });

    test('4. Farmer can request transport logistics for accepted order',
        () async {
      // Find an order without an existing transport job
      final order = state.orders.firstWhere((o) => o.id == 'ORD-1003');
      final initialJobsCount = state.jobs.length;

      await state.requestTransportForOrder(order.id);

      expect(state.jobs.length, initialJobsCount + 1);
      final createdJob = state.jobs.firstWhere((j) => j.orderId == order.id);
      expect(createdJob.status, 'requested');
      expect(createdJob.orderId, order.id);

      // The order delivery status should now be updated
      final updatedOrder = state.orders.firstWhere((o) => o.id == order.id);
      expect(updatedOrder.deliveryStatus, 'requested');
    });

    test('5. Farmer can request bank withdrawal / payout', () async {
      final initialEarnings = state.totalEarnings;
      expect(initialEarnings > 0, isTrue);

      const withdrawalAmount = 5000.0;
      await state.requestFarmerWithdrawal(
        amount: withdrawalAmount,
        bankName: 'Bank of Ceylon (BOC)',
        accountNumber: '8401293810',
        payoutMethod: 'CEFT',
      );

      expect(state.totalEarnings, initialEarnings - withdrawalAmount);

      // Verify settlement record exists
      expect(state.settlements.isNotEmpty, isTrue);
      final settlement = state.settlements.first;
      expect(settlement.bankName, 'Bank of Ceylon (BOC)');
      expect(settlement.grossAmount, withdrawalAmount);
      expect(settlement.status, 'pending');

      // Verify transaction list contains withdrawal entry
      final tx = state.transactions.first;
      expect(tx.amount, -withdrawalAmount);
    });

    test('6. Payout request rejects invalid amounts exceeding total balance',
        () async {
      await expectLater(
        state.requestFarmerWithdrawal(
          amount: 999999999.0,
          bankName: 'Sampath Bank',
          accountNumber: '12345678',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
