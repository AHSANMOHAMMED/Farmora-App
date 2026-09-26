import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/user_role.dart';
import 'package:farmora/providers/farmora_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Farmora production state', () {
    late FarmoraState state;

    setUp(() => state = FarmoraState());
    tearDown(() => state.dispose());

    test('starts initialized with catalog demo data', () {
      expect(state.products, isNotEmpty);
      expect(state.orders, isNotEmpty);
      expect(state.jobs, isNotEmpty);
      expect(state.users, isEmpty);
      expect(state.signedIn, isFalse);
      expect(state.isVerified, isFalse);
    });

    test('cannot create offers without a Firebase account', () async {
      await expectLater(
        state.makeOffer(
          productId: 'missing',
          productName: 'Missing product',
          farmerId: 'missing-farmer',
          quantity: 1,
          price: 1,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('role selection does not authenticate users', () {
      state.setRole(Role.buyer);
      expect(state.role, Role.buyer);
      expect(state.signedIn, isFalse);
      expect(state.currentUserId, isEmpty);
    });
  });
}
