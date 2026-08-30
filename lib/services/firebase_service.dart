import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/verification_model.dart';

// ============================================================
// Firebase Authentication Service
// ============================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _functions.httpsCallable('registerDeviceToken').call({
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _functions
        .httpsCallable('unregisterDeviceToken')
        .call({'token': token});
  }

  // ── Users ─────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> usersStream({int limit = 100}) {
    return _db.collection('users').limit(limit).snapshots().map((snap) =>
        snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> notificationsStream(String userId,
      {int limit = 50}) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> updateUserLanguage(String languageCode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    await _db.collection('users').doc(uid).update({
      'languageCode': languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Products ──────────────────────────────────────────────

  /// Add a new product to Firestore
  Future<void> addProduct(Product p, String farmerId) async {
    await _db.collection('products').add({
      ...p.toMap(),
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  /// Real-time stream of all products
  Stream<List<Product>> productsStream({int limit = 50}) {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Products stream filtered by farmer
  Stream<List<Product>> productsByFarmerStream(String farmerId,
      {int limit = 50}) {
    return _db
        .collection('products')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Orders ────────────────────────────────────────────────

  /// Add a new order
  Future<void> addOrder(FarmoraOrder o) async {
    await _db.collection('orders').add({
      ...o.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createSecureOrder({
    required String productId,
    required int quantity,
    int deliveryFeeMinor = 0,
  }) async {
    final result = await _functions.httpsCallable('createOrder').call({
      'productId': productId,
      'quantity': quantity,
      'deliveryFeeMinor': deliveryFeeMinor,
    });
    return result.data['orderId'] as String;
  }

  Future<String> createSecureProduct(Product product) async {
    final result = await _functions.httpsCallable('createProduct').call({
      'name': product.name,
      'category': product.category,
      'description': product.description,
      'unit': product.unit,
      'location': product.location,
      'priceMinor': product.pricePerUnit.round() * 100,
      'quantityAvailable': int.tryParse(product.quantity) ?? 0,
      'media': product.images,
    });
    return result.data['productId'] as String;
  }

  Future<void> transitionOrder(String orderId, String status) async {
    await _functions.httpsCallable('transitionOrder').call({
      'orderId': orderId,
      'status': status,
    });
  }

  Future<void> transitionTransport(String jobId, String status) async {
    await _functions.httpsCallable('transitionTransport').call({
      'jobId': jobId,
      'status': status,
    });
  }

  Future<String> submitVerification({
    required String documentType,
    required String storagePath,
  }) async {
    final result = await _functions.httpsCallable('submitVerification').call({
      'documentType': documentType,
      'storagePath': storagePath,
    });
    return result.data['documentId'] as String;
  }

  Future<String> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('File must be smaller than 5 MB.');
    }
    final path =
        'verification/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return path;
  }

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Profile photo must be smaller than 5 MB.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = _storage.ref('users/$uid/profile_$safeName');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  Future<String> sendEncryptedMessage({
    required String orderId,
    required String recipientId,
    required String ciphertext,
  }) async {
    final result = await _functions.httpsCallable('sendMessage').call({
      'orderId': orderId,
      'recipientId': recipientId,
      'ciphertext': ciphertext,
    });
    return result.data['messageId'] as String;
  }

  Future<Map<String, dynamic>> verifyProductBarcode({
    required String barcodeId,
    required String signature,
  }) async {
    final result = await _functions.httpsCallable('verifyBarcode').call({
      'barcodeId': barcodeId,
      'signature': signature,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    await _functions.httpsCallable('submitReview').call({
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<String> openDispute({
    required String orderId,
    required String reason,
  }) async {
    final result = await _functions.httpsCallable('openDispute').call({
      'orderId': orderId,
      'reason': reason,
    });
    return result.data['disputeId'] as String;
  }

  /// Update order status
  Future<void> updateOrderStatus(
      String id, String status, double progress) async {
    final normalized = switch (status.toLowerCase()) {
      'accepted' => 'confirmed',
      'declined' => 'rejected',
      'cancelled' => 'cancelled',
      _ => status.toLowerCase(),
    };
    await transitionOrder(id, normalized);
  }

  /// Real-time stream of all orders
  Stream<List<FarmoraOrder>> ordersStream({int limit = 50}) {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Orders stream filtered by farmer
  Stream<List<FarmoraOrder>> ordersByFarmerStream(String farmerId,
      {int limit = 50}) {
    return _db
        .collection('orders')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Orders stream filtered by buyer
  Stream<List<FarmoraOrder>> ordersByBuyerStream(String buyerId,
      {int limit = 50}) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<FarmoraOrder>> ordersByTransporterStream(String transporterId,
      {int limit = 50}) {
    return _db
        .collection('orders')
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Transport Jobs ────────────────────────────────────────

  /// Add a new transport job
  Future<void> addTransportJob(TransportJob j) async {
    await _db.collection('transport_jobs').add({
      ...j.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of transport jobs
  Stream<List<TransportJob>> jobsStream({int limit = 50}) {
    return _db
        .collection('transport_jobs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Streams only requested jobs or jobs already assigned to this provider.
  Stream<List<TransportJob>> jobsForTransporterStream(String transporterId,
      {int limit = 50}) {
    return _db
        .collection('transport_jobs')
        .where(Filter.or(
          Filter('status', isEqualTo: 'requested'),
          Filter('transporterId', isEqualTo: transporterId),
        ))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Verification Documents ────────────────────────────────

  Stream<List<TransportJob>> jobsByCreatorStream(String uid) {
    return _db
        .collection('transport_jobs')
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<TransportJob>> jobsByTransporterStream(String uid) {
    return _db
        .collection('transport_jobs')
        .where('transporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add a verification document
  Future<void> addVerificationDoc(VerificationDoc d, String farmerId) async {
    await _db.collection('verification_docs').add({
      ...d.toMap(),
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update verification document
  Future<void> updateVerificationDoc(
      String id, Map<String, dynamic> data) async {
    await _db.collection('verification_docs').doc(id).update(data);
  }

  /// Verification docs stream for a farmer
  Stream<List<VerificationDoc>> verificationDocsStream(String farmerId) {
    return _db
        .collection('verification_docs')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VerificationDoc.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Database Seeding ──────────────────────────────────────

  /// Seeds the database with mock Sri Lankan data for testing
  Future<void> seedDatabase() async {
    // 1. Seed Products
    final products = [
      {
        'name': 'Ceylon Cinnamon',
        'category': 'Spices',
        'location': 'Kandy',
        'quantity': '10 kg available',
        'unit': 'kg',
        'price': 'LKR 4,500 / kg',
        'pricePerUnit': 4500.0,
        'emoji': '🍂',
        'color': 0xFFFFE1DA,
        'imagePath': 'assets/images/placeholder.png',
        'status': 'Active',
        'isOrganic': true,
        'description':
            'Premium grade Ceylon Cinnamon sticks, freshly harvested.',
        'farmerId': 'mock-farmer-id',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Nuwara Eliya Carrots',
        'category': 'Vegetables',
        'location': 'Nuwara Eliya',
        'quantity': '50 kg available',
        'unit': 'kg',
        'price': 'LKR 350 / kg',
        'pricePerUnit': 350.0,
        'emoji': '🥕',
        'color': 0xFFFFF3E0,
        'imagePath': 'assets/images/nantes_carrots.png',
        'status': 'Active',
        'isOrganic': true,
        'description': 'Fresh, crisp carrots from the hills of Nuwara Eliya.',
        'farmerId': 'mock-farmer-id',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'King Coconut (Thambili)',
        'category': 'Fruits',
        'location': 'Kurunegala',
        'quantity': '100 nuts',
        'unit': 'nuts',
        'price': 'LKR 120 / ea',
        'pricePerUnit': 120.0,
        'emoji': '🥥',
        'color': 0xFFE8F5E9,
        'imagePath': 'assets/images/placeholder.png',
        'status': 'Active',
        'isOrganic': true,
        'description':
            'Sweet and refreshing King Coconuts, rich in electrolytes.',
        'farmerId': 'mock-farmer-id',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var p in products) {
      await _db.collection('products').add(p);
    }

    // 2. Seed Orders
    final orders = [
      {
        'orderNumber': '#1042-SL',
        'title': '20 kg Nuwara Eliya Carrots',
        'productName': 'Nuwara Eliya Carrots',
        'quantity': '20 kg',
        'grade': 'Grade A Premium',
        'unitPrice': 'LKR 350.00',
        'totalAmount': 'LKR 7,000.00',
        'totalAmountNumber': 7000.0,
        'buyerName': 'Sunil Perera',
        'buyerCompany': 'Sunil Fresh Veg',
        'buyerAvatar': 'assets/images/placeholder.png',
        'deliveryAddress': '12 Galle Road,\nColombo 03',
        'detail': '20 kg · LKR 7,000.00 · Requested for Today',
        'status': 'Pending',
        'progress': 0.25,
        'color': 0xFF3478C5,
        'timestamp': 'Today, 09:15 AM',
        'requestedDate': 'Today',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'orderNumber': '#1043-SL',
        'title': '5 kg Ceylon Cinnamon',
        'productName': 'Ceylon Cinnamon',
        'quantity': '5 kg',
        'grade': 'Organic',
        'unitPrice': 'LKR 4,500.00',
        'totalAmount': 'LKR 22,500.00',
        'totalAmountNumber': 22500.0,
        'buyerName': 'Nimal Traders',
        'buyerCompany': 'Nimal Exports',
        'buyerAvatar': 'assets/images/placeholder.png',
        'deliveryAddress': '45 Kandy Road,\nPeradeniya',
        'detail': '5 kg · LKR 22,500.00 · Requested for Tomorrow',
        'status': 'Accepted',
        'progress': 0.6,
        'color': 0xFF1F7A4D,
        'timestamp': 'Yesterday, 14:20 PM',
        'requestedDate': 'Tomorrow',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var o in orders) {
      await _db.collection('orders').add(o);
    }

    // 3. Seed Transport Jobs
    final jobs = [
      {
        'title': 'Carrot Transport',
        'route': 'Nuwara Eliya → Colombo',
        'detail': '20 kg · Pickup today, 10:30 AM',
        'fee': 'LKR 3,500',
        'accepted': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Coconut Transport',
        'route': 'Kurunegala → Kandy',
        'detail': '100 nuts · Pickup tomorrow, 7:00 AM',
        'fee': 'LKR 2,200',
        'accepted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var j in jobs) {
      await _db.collection('transport_jobs').add(j);
    }
  }
}
