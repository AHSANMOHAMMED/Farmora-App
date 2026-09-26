import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Buyer cart state', () {
    late FarmoraState state;
    setUp(() => state = FarmoraState());
    tearDown(() => state.dispose());

    const carrots = Product(
      id: 'p-1',
      name: 'Organic Carrots',
      price: 'LKR 200/kg',
      category: 'Vegetables',
      location: 'Nuwara Eliya',
      quantity: '100 kg',
      pricePerUnit: 200,
      unit: 'kg',
    );

    test('cart totals update when items are added and removed', () {
      state.setRole(Role.buyer);
      state.addToCart(carrots);
      state.addToCart(carrots);
      expect(state.cartTotal, 400);
      expect(state.cartItemCount, 2);

      state.updateCartQuantity('p-1', 3);
      expect(state.cartTotal, 600);
      state.removeFromCart('p-1');
      expect(state.cartItems, isEmpty);
    });

    test('order placement cannot succeed without authenticated backend',
        () async {
      state.addToCart(carrots);
      final placed = await state.placeOrder(
        deliveryAddress: 'Colombo, Sri Lanka',
        transporterId: 'untrusted-id',
      );
      expect(placed, isFalse);
      expect(state.orders, isEmpty);
      expect(state.cartItems, hasLength(1));
    });

    test('offer creation requires authentication', () async {
      await expectLater(
        state.makeOffer(
          productId: carrots.id,
          productName: carrots.name,
          farmerId: 'farmer-id',
          quantity: 5,
          price: 180,
        ),
        throwsA(isA<StateError>()),
      );
      expect(state.offers, isEmpty);
    });
  });
}
