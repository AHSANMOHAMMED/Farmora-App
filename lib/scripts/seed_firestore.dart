// To run: flutter run -d chrome lib/scripts/seed_firestore.dart
// Or use: dart run lib/scripts/seed_firestore.dart
//
// Prerequisites:
// 1. Run `flutterfire configure` to generate firebase_options.dart
// 2. Make sure Firestore is enabled in your Firebase project
// 3. Run this script to populate demo data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/config/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  print('Seeding Farmora Firestore database...\n');

  // Market Prices
  print('Seeding market prices...');
  final now = DateTime.now();
  final marketPrices = [
    {'crop_name': 'Tomato', 'price_per_kg': 95.0, 'market_name': 'Dambulla', 'emoji': '🍅', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Green Chilli', 'price_per_kg': 220.0, 'market_name': 'Dambulla', 'emoji': '🌶️', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Carrot', 'price_per_kg': 145.0, 'market_name': 'Dambulla', 'emoji': '🥕', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Leeks', 'price_per_kg': 180.0, 'market_name': 'Dambulla', 'emoji': '🥬', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Capsicum', 'price_per_kg': 260.0, 'market_name': 'Dambulla', 'emoji': '🫑', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Brinjal', 'price_per_kg': 75.0, 'market_name': 'Dambulla', 'emoji': '🍆', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Beans', 'price_per_kg': 130.0, 'market_name': 'Dambulla', 'emoji': '🫘', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Cabbage', 'price_per_kg': 60.0, 'market_name': 'Dambulla', 'emoji': '🥬', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Potato', 'price_per_kg': 105.0, 'market_name': 'Dambulla', 'emoji': '🥔', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Banana', 'price_per_kg': 85.0, 'market_name': 'Manning Market', 'emoji': '🍌', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Mango', 'price_per_kg': 195.0, 'market_name': 'Manning Market', 'emoji': '🥭', 'recorded_date': now.toIso8601String()},
    {'crop_name': 'Papaya', 'price_per_kg': 65.0, 'market_name': 'Manning Market', 'emoji': '🍈', 'recorded_date': now.toIso8601String()},
  ];
  final priceBatch = db.batch();
  for (int i = 0; i < marketPrices.length; i++) {
    final ref = db.collection('market_prices').doc('mp-\${i + 1}');
    priceBatch.set(ref, marketPrices[i]);
  }
  await priceBatch.commit();
  print('  Added \${marketPrices.length} market prices');

  // Products
  print('Seeding products...');
  final products = <Map<String, dynamic>>[
    _product('prod-001', 'farmer-001', 'Organic Tomatoes', 'vegetables', 'Fresh organic tomatoes from Nuwara Eliya highlands', 200, 'kg', 420, 'Nuwara Eliya'),
    _product('prod-002', 'farmer-001', 'Green Chilli', 'vegetables', 'Hot and fresh green chillies', 150, 'kg', 520, 'Nuwara Eliya'),
    _product('prod-003', 'farmer-002', 'Fresh Carrots', 'vegetables', 'Sweet carrots from Kandy gardens', 300, 'kg', 340, 'Kandy'),
    _product('prod-004', 'farmer-002', 'Cabbage Heads', 'vegetables', 'Crisp cabbage heads, perfect for cooking', 500, 'kg', 150, 'Kandy'),
    _product('prod-005', 'farmer-003', 'Brinjal (Eggplant)', 'vegetables', 'Fresh brinjals from Badulla farms', 250, 'kg', 280, 'Badulla'),
    _product('prod-006', 'farmer-003', 'Green Beans', 'vegetables', 'Tender green beans, hand-picked', 180, 'kg', 320, 'Badulla'),
    _product('prod-007', 'farmer-004', 'Jaffna Brinjal', 'vegetables', 'Special Jaffna variety brinjal', 200, 'kg', 300, 'Jaffna'),
    _product('prod-008', 'farmer-004', 'Drumstick', 'vegetables', 'Fresh drumstick pods', 100, 'kg', 250, 'Jaffna'),
    _product('prod-009', 'farmer-005', 'Curry Leaves', 'herbs', 'Fresh curry leaves, aromatic', 200, 'bunch', 40, 'Matale'),
    _product('prod-010', 'farmer-005', 'Gotukola Bunches', 'herbs', 'Fresh gotukola for salads and juices', 300, 'bunch', 90, 'Matale'),
    _product('prod-011', 'farmer-006', 'King Coconut', 'fruits', 'Fresh king coconuts, sweet water', 100, 'unit', 50, 'Gampaha'),
    _product('prod-012', 'farmer-006', 'Cavendish Bananas', 'fruits', 'Ripe Cavendish bananas', 450, 'kg', 280, 'Gampaha'),
    _product('prod-013', 'farmer-007', 'Pumpkin', 'vegetables', 'Large pumpkins for curries', 400, 'kg', 85, 'Kilinochchi'),
    _product('prod-014', 'farmer-007', 'Bitter Gourd', 'vegetables', 'Fresh bitter gourds', 150, 'kg', 120, 'Kilinochchi'),
    _product('prod-015', 'farmer-008', 'Capsicum', 'vegetables', 'Colorful capsicums', 200, 'kg', 260, 'Batticaloa'),
    _product('prod-016', 'farmer-008', 'Leeks', 'vegetables', 'Fresh leeks for cooking', 180, 'kg', 180, 'Batticaloa'),
    _product('prod-017', 'farmer-009', 'Beetroot', 'vegetables', 'Fresh beetroot for juices and cooking', 250, 'kg', 100, 'Monaragala'),
    _product('prod-018', 'farmer-009', 'Lettuce', 'vegetables', 'Crisp lettuce leaves for salads', 120, 'kg', 90, 'Monaragala'),
    _product('prod-019', 'farmer-010', 'Rambutan', 'fruits', 'Fresh rambutan in season', 80, 'kg', 600, 'Ratnapura'),
    _product('prod-020', 'farmer-010', 'Mangosteen', 'fruits', 'Sweet mangosteens', 60, 'kg', 800, 'Ratnapura'),
  ];
  final productBatch = db.batch();
  for (final p in products) {
    final id = p['id'] as String;
    final data = Map<String, dynamic>.from(p)..remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    productBatch.set(db.collection('products').doc(id), data);
  }
  await productBatch.commit();
  print('  Added \${products.length} products');

  // Transport Jobs
  print('Seeding transport jobs...');
  final jobs = [
    _job('job-001', 'Coconut harvest', 'Kaduwela', 'Colombo', 250, 3500, 'requested'),
    _job('job-002', 'Fresh vegetables', 'Nuwara Eliya', 'Kandy', 80, 5200, 'requested'),
    _job('job-003', 'Brinjal shipment', 'Badulla', 'Colombo', 120, 4800, 'requested'),
    _job('job-004', 'Herb bundle delivery', 'Matale', 'Kandy', 40, 2000, 'accepted'),
    _job('job-005', 'Fruit crate transport', 'Ratnapura', 'Colombo', 200, 6500, 'requested'),
  ];
  final jobBatch = db.batch();
  for (final j in jobs) {
    final id = j['id'] as String;
    final data = Map<String, dynamic>.from(j)..remove('id');
    data['requestedAt'] = FieldValue.serverTimestamp();
    jobBatch.set(db.collection('transport_jobs').doc(id), data);
  }
  await jobBatch.commit();
  print('  Added \${jobs.length} transport jobs');

  print('\nSeeding complete!');
  print('Collections seeded: market_prices, products, transport_jobs');
  print('Users are created automatically via Firebase Auth sign-up.');
  print('Orders are created when buyers place orders in the app.');
}

Map<String, dynamic> _product(
  String id, String farmerId, String name, String category,
  String description, double qty, String unit, int priceMinor, String location,
) => {
  'id': id, 'farmerId': farmerId, 'name': name, 'category': category,
  'description': description, 'quantityAvailable': qty, 'unit': unit,
  'priceMinor': priceMinor, 'currency': 'LKR', 'location': location,
  'availability': 'available', 'imageUrls': <String>[],
  'searchTokens': name.toLowerCase().split(' '),
};

Map<String, dynamic> _job(
  String id, String title, String pickup, String dropoff,
  double weightKg, int feeMinor, String status,
) => {
  'id': id, 'orderId': '', 'pickupAddress': pickup, 'dropoffAddress': dropoff,
  'cargoSummary': title, 'weightKg': weightKg, 'offeredFeeMinor': feeMinor,
  'currency': 'LKR', 'status': status,
};
