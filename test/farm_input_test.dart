import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/farm_input.dart';

void main() {
  group('Input orders', () {
    test('sales and rentals advance through their own steps', () {
      expect(InputOrderStatus.nextFor('confirmed', rental: false), 'dispatched');
      expect(InputOrderStatus.nextFor('dispatched', rental: false), 'delivered');
      expect(InputOrderStatus.nextFor('confirmed', rental: true), 'inUse');
      expect(InputOrderStatus.nextFor('inUse', rental: true), 'returned');
      expect(InputOrderStatus.nextFor('pending', rental: false), isNull);
      expect(InputOrderStatus.nextFor('delivered', rental: false), isNull);
    });

    test('closed statuses', () {
      for (final s in ['delivered', 'returned', 'rejected', 'cancelled']) {
        expect(InputOrderStatus.isClosed(s), isTrue, reason: s);
      }
      expect(InputOrderStatus.isClosed('pending'), isFalse);
    });

    test('listings parse type, price and visibility', () {
      final rental = FarmInput.fromMap('t1', {
        'supplierId': 's', 'supplierName': 'Agro Lanka', 'name': 'Tractor',
        'category': 'machinery', 'listingType': 'rental', 'priceMinor': 800000,
        'unit': 'day', 'stock': 2, 'status': 'Active', 'isDeleted': false,
        'imageUrl': '',
      });
      expect(rental.isRental, isTrue);
      expect(rental.category, InputCategory.machinery);
      expect(rental.price, 8000);
      expect(rental.active, isTrue);
      expect(rental.imageUrl, isNull);
      final deleted = FarmInput.fromMap('x', {
        'status': 'Active', 'isDeleted': true, 'category': 'unknown',
      });
      expect(deleted.active, isFalse);
      expect(deleted.category, InputCategory.tools);
      expect(deleted.inStock, isFalse);
    });

    test('orders parse rental fields', () {
      final o = InputOrder.fromMap('o', {
        'listingType': 'rental', 'quantity': 1, 'days': 3,
        'unitPriceMinor': 800000, 'totalMinor': 2400000, 'status': 'pending',
      });
      expect(o.isRental, isTrue);
      expect(o.days, 3);
      expect(o.total, 24000);
    });
  });
}
