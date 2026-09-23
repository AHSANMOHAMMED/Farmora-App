import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/providers/farmora_state.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/models/user_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Buyer Cart CRUD & Calculations', () {
    test('Add, update, remove, and clear cart items', () {
      final state = FarmoraState();
      state.setRole(Role.buyer);

      const productA = Product(
        id: 'p-1',
        name: 'Organic Carrots',
        price: 'LKR 200/kg',
        category: 'Vegetables',
        location: 'Nuwara Eliya',
        quantity: '100 kg',
        pricePerUnit: 200.0,
        unit: 'kg',
      );

      const productB = Product(
        id: 'p-2',
        name: 'Red Onions',
        price: 'LKR 350/kg',
        category: 'Vegetables',
        location: 'Jaffna',
        quantity: '50 kg',
        pricePerUnit: 350.0,
        unit: 'kg',
      );

      // 1. Initial cart should be empty
      state.clearCart();
      expect(state.cartItems.isEmpty, isTrue);
      expect(state.cartItemCount, 0);
      expect(state.cartTotal, 0.0);

      // 2. Add productA
      state.addToCart(productA);
      expect(state.cartItems.length, 1);
      expect(state.cartItems.first.product.id, 'p-1');
      expect(state.cartItems.first.quantity, 1);
      expect(state.cartTotal, 200.0);

      // 3. Add productA again (increment count)
      state.addToCart(productA);
      expect(state.cartItems.first.quantity, 2);
      expect(state.cartTotal, 400.0);

      // 4. Add productB
      state.addToCart(productB);
      expect(state.cartItems.length, 2);
      expect(state.cartItemCount, 3);
      expect(state.cartTotal, 750.0);

      // 5. Update quantity of productA
      state.updateCartQuantity('p-1', 1);
      expect(state.cartItems.firstWhere((c) => c.product.id == 'p-1').quantity, 1);
      expect(state.cartTotal, 550.0);

      // 6. Remove productA completely
      state.removeFromCart('p-1');
      expect(state.cartItems.any((c) => c.product.id == 'p-1'), isFalse);
      expect(state.cartItems.length, 1);
      expect(state.cartTotal, 350.0);

      // 7. Clear cart
      state.clearCart();
      expect(state.cartItems.isEmpty, isTrue);
      expect(state.cartTotal, 0.0);
    });
  });

  group('Buyer Order CRUD & Cross-Role Propagation', () {
    test('placeOrder creates FarmoraOrder, clears cart, and creates matching TransportJob', () async {
      final state = FarmoraState();
      state.setRole(Role.buyer);
      state.clearCart();

      const item = Product(
        id: 'item-10',
        name: 'Keeri Samba Rice',
        price: 'LKR 300/kg',
        category: 'Grains',
        location: 'Polonnaruwa',
        quantity: '200 kg',
        pricePerUnit: 300.0,
        unit: 'kg',
      );

      state.addToCart(item);
      state.addToCart(item); // 2 kg @ 300 = 600

      final initialOrderCount = state.orders.length;
      final initialJobCount = state.jobs.length;

      final success = await state.placeOrder(
        deliveryAddress: '42 Lotus Road, Colombo 03',
      );

      expect(success, isTrue);
      expect(state.cartItems.isEmpty, isTrue, reason: 'Cart should be cleared after order');
      expect(state.orders.length, initialOrderCount + 1, reason: 'New order should be added');
      expect(state.jobs.length, initialJobCount + 1, reason: 'Transport job should be created');

      final placedOrder = state.orders.first;
      expect(placedOrder.productName, contains('Keeri Samba Rice'));
      expect(placedOrder.deliveryAddress, '42 Lotus Road, Colombo 03');
      expect(placedOrder.status.toLowerCase(), 'pending');

      final linkedJob = state.jobs.firstWhere((j) => j.orderId == placedOrder.id);
      expect(linkedJob.orderId, placedOrder.id);
      expect(linkedJob.status.toLowerCase(), 'requested');
      expect(linkedJob.title, contains('Delivery'));
    });

    test('cancelOrder updates order status to cancelled', () async {
      final state = FarmoraState();
      state.setRole(Role.buyer);

      // Pick any active/pending order from demo data
      final targetOrder = state.orders.first;
      final targetId = targetOrder.id;

      state.cancelOrder(targetId);

      final updatedOrder = state.orders.firstWhere((o) => o.id == targetId);
      expect(updatedOrder.status.toLowerCase(), 'cancelled');
    });
  });

  group('Buyer Offers & Price Negotiation CRUD', () {
    test('makeOffer adds offer with pending status', () async {
      final state = FarmoraState();
      state.setRole(Role.buyer);

      final initialOfferCount = state.offers.length;

      await state.makeOffer(
        productId: 'prod-negotiate-1',
        productName: 'Ceylon Cinnamon',
        farmerId: 'farmer-1',
        price: 1050.0,
        quantity: 25,
      );

      expect(state.offers.length, initialOfferCount + 1);

      final newOffer = state.offers.firstWhere((o) => o.productId == 'prod-negotiate-1');
      expect(newOffer.productName, 'Ceylon Cinnamon');
      expect(newOffer.proposedPrice, 1050.0);
      expect(newOffer.proposedQuantity, 25);
      expect(newOffer.status.toLowerCase(), 'pending');
    });

    test('counterOffer updates offer with counter price and status', () async {
      final state = FarmoraState();
      final targetOffer = state.offers.first;

      await state.counterOffer(
        targetOffer.id,
        1100.0,
      );

      final updated = state.offers.firstWhere((o) => o.id == targetOffer.id);
      expect(updated.status.toLowerCase(), 'countered');
      expect(updated.proposedPrice, 1100.0);
    });

    test('acceptOffer updates status and creates confirmed FarmoraOrder', () async {
      final state = FarmoraState();
      state.setRole(Role.buyer);

      // Create a specific offer to test acceptance
      await state.makeOffer(
        productId: 'prod-accept-test',
        productName: 'Sweet Pineapples',
        farmerId: 'farmer-2',
        price: 350.0,
        quantity: 40,
      );

      final createdOffer = state.offers.firstWhere((o) => o.productId == 'prod-accept-test');
      final initialOrderCount = state.orders.length;

      await state.acceptOffer(createdOffer.id);

      final acceptedOffer = state.offers.firstWhere((o) => o.id == createdOffer.id);
      expect(acceptedOffer.status.toLowerCase(), 'accepted');

      expect(state.orders.length, initialOrderCount + 1, reason: 'Accepted offer creates confirmed order');

      final autoOrder = state.orders.first;
      expect(autoOrder.productName, contains('Sweet Pineapples'));
      expect(autoOrder.status.toLowerCase(), 'accepted');
    });

    test('cancelOffer marks offer as cancelled', () async {
      final state = FarmoraState();
      final targetOffer = state.offers.first;

      await state.cancelOffer(targetOffer.id);

      final cancelledOffer = state.offers.firstWhere((o) => o.id == targetOffer.id);
      expect(cancelledOffer.status.toLowerCase(), 'cancelled');
    });
  });
}
