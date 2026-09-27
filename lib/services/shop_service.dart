import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import '../models/product.dart';
import 'service_errors.dart';
import 'push_relay.dart';

/// A farmer's public shop page (`farm_stores/{farmerId}`).
class FarmStore {
  const FarmStore({
    required this.farmerId,
    required this.farmName,
    this.story = '',
    this.district = '',
    this.coverImageUrl,
    this.certifications = const [],
  });

  final String farmerId;
  final String farmName;
  final String story;
  final String district;
  final String? coverImageUrl;
  final List<String> certifications;

  factory FarmStore.fromMap(String id, Map<String, dynamic> d) => FarmStore(
        farmerId: id,
        farmName: (d['farmName'] ?? '').toString(),
        story: (d['story'] ?? '').toString(),
        district: (d['district'] ?? '').toString(),
        coverImageUrl: (d['coverImageUrl'] ?? '').toString().isEmpty
            ? null
            : d['coverImageUrl'].toString(),
        certifications: (d['certifications'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// How often a subscription box is delivered.
enum BoxFrequency { weekly, biweekly, monthly }

BoxFrequency boxFrequencyFrom(Object? v) => BoxFrequency.values
    .firstWhere((f) => f.name == v, orElse: () => BoxFrequency.weekly);

extension BoxFrequencyDays on BoxFrequency {
  int get days => switch (this) {
        BoxFrequency.weekly => 7,
        BoxFrequency.biweekly => 14,
        BoxFrequency.monthly => 30,
      };
}

/// A recurring produce box a farmer offers (`subscription_boxes`).
class SubscriptionBox {
  const SubscriptionBox({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.title,
    required this.contents,
    required this.priceMinor,
    required this.frequency,
    this.active = true,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String title;
  final String contents;
  final int priceMinor;
  final BoxFrequency frequency;
  final bool active;

  double get price => priceMinor / 100.0;

  factory SubscriptionBox.fromMap(String id, Map<String, dynamic> d) =>
      SubscriptionBox(
        id: id,
        farmerId: (d['farmerId'] ?? '').toString(),
        farmerName: (d['farmerName'] ?? '').toString(),
        title: (d['title'] ?? '').toString(),
        contents: (d['contents'] ?? '').toString(),
        priceMinor: firebaseInt(d['priceMinor']) ?? 0,
        frequency: boxFrequencyFrom(d['frequency']),
        active: d['status'] == 'Active' && d['isDeleted'] != true,
      );
}

/// A buyer's subscription to a box (`box_subscriptions`).
class BoxSubscription {
  const BoxSubscription({
    required this.id,
    required this.boxId,
    required this.boxTitle,
    required this.farmerId,
    required this.farmerName,
    required this.buyerId,
    required this.buyerName,
    required this.priceMinor,
    required this.frequency,
    required this.deliveryAddress,
    required this.status,
    this.nextDeliveryAt,
    this.deliveriesCount = 0,
  });

  final String id;
  final String boxId;
  final String boxTitle;
  final String farmerId;
  final String farmerName;
  final String buyerId;
  final String buyerName;
  final int priceMinor;
  final BoxFrequency frequency;
  final String deliveryAddress;

  /// active, paused or cancelled.
  final String status;
  final DateTime? nextDeliveryAt;
  final int deliveriesCount;

  factory BoxSubscription.fromMap(String id, Map<String, dynamic> d) =>
      BoxSubscription(
        id: id,
        boxId: (d['boxId'] ?? '').toString(),
        boxTitle: (d['boxTitle'] ?? '').toString(),
        farmerId: (d['farmerId'] ?? '').toString(),
        farmerName: (d['farmerName'] ?? '').toString(),
        buyerId: (d['buyerId'] ?? '').toString(),
        buyerName: (d['buyerName'] ?? '').toString(),
        priceMinor: firebaseInt(d['priceMinor']) ?? 0,
        frequency: boxFrequencyFrom(d['frequency']),
        deliveryAddress: (d['deliveryAddress'] ?? '').toString(),
        status: (d['status'] ?? 'active').toString(),
        nextDeliveryAt: firebaseDate(d['nextDeliveryAt']),
        deliveriesCount: firebaseInt(d['deliveriesCount']) ?? 0,
      );
}

/// Direct-to-consumer shop features: wishlist, farm store pages and
/// subscription boxes. Plain client writes validated by `firestore.rules`.
class ShopService {
  ShopService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  Future<String> _myName(String fallback) async {
    final me = (await _db.collection('users').doc(_uid).get()).data() ?? {};
    final name = (me['displayName'] ?? me['name'] ?? '').toString().trim();
    return name.isEmpty ? fallback : name;
  }

  // ── Wishlist ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _wishlist =>
      _db.collection('users').doc(_uid).collection('wishlist');

  Stream<Set<String>> watchWishlistIds() => _wishlist
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> toggleWishlist(String productId, bool add) => add
      ? _wishlist.doc(productId).set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        })
      : _wishlist.doc(productId).delete();

  /// Wishlisted products that still exist (up to 30, newest first).
  Future<List<Product>> wishlistProducts(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final snap = await _db
        .collection('products')
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .get();
    return snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
  }

  // ── Farm store ──────────────────────────────────────────────

  Stream<FarmStore?> watchStore(String farmerId) => _db
      .collection('farm_stores')
      .doc(farmerId)
      .snapshots()
      .map((d) => d.exists ? FarmStore.fromMap(d.id, d.data()!) : null);

  /// A farmer's active listings for their public store page.
  Stream<List<Product>> storeProducts(String farmerId, {int limit = 50}) => _db
      .collection('products')
      .where('farmerId', isEqualTo: farmerId)
      .where('status', isEqualTo: 'Active')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  Future<void> saveStore({
    required String farmName,
    required String story,
    required String district,
    required List<String> certifications,
    String? coverImageUrl,
  }) async {
    final name = farmName.trim();
    if (name.isEmpty || name.length > 80) {
      throw UserArgumentError('Enter your farm name (up to 80 characters).');
    }
    await _db.collection('farm_stores').doc(_uid).set({
      'farmerId': _uid,
      'farmName': name,
      'story': story.trim(),
      'district': district.trim(),
      'certifications': certifications
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .take(10)
          .toList(),
      'coverImageUrl': coverImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Subscription boxes ──────────────────────────────────────

  Stream<List<SubscriptionBox>> farmerBoxes(String farmerId,
          {bool activeOnly = true}) {
    Query<Map<String, dynamic>> q = _db
        .collection('subscription_boxes')
        .where('farmerId', isEqualTo: farmerId)
        .where('isDeleted', isEqualTo: false);
    if (activeOnly) q = q.where('status', isEqualTo: 'Active');
    return q.snapshots().map((s) =>
        s.docs.map((d) => SubscriptionBox.fromMap(d.id, d.data())).toList());
  }

  Future<void> saveBox({
    String? id,
    required String title,
    required String contents,
    required int priceMinor,
    required BoxFrequency frequency,
    bool active = true,
  }) async {
    final uid = _uid;
    if (title.trim().isEmpty || priceMinor <= 0) {
      throw UserArgumentError('Enter a box name and price.');
    }
    final fields = {
      'title': title.trim(),
      'contents': contents.trim(),
      'priceMinor': priceMinor,
      'frequency': frequency.name,
      'status': active ? 'Active' : 'Inactive',
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };
    final col = _db.collection('subscription_boxes');
    if (id == null) {
      await col.add({
        ...fields,
        'farmerId': uid,
        'farmerName': await _myName('Farmer'),
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
    } else {
      await col.doc(id).update(fields);
    }
  }

  Future<void> deleteBox(String id) =>
      _db.collection('subscription_boxes').doc(id).update({
        'isDeleted': true,
        'status': 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid,
      });

  Future<void> subscribe(SubscriptionBox box, String deliveryAddress,
      DateTime firstDelivery) async {
    final address = deliveryAddress.trim();
    if (address.length < 5) {
      throw UserArgumentError('Enter a complete delivery address.');
    }
    final ref = _db.collection('box_subscriptions').doc();
    await ref.set({
      'boxId': box.id,
      'boxTitle': box.title,
      'farmerId': box.farmerId,
      'farmerName': box.farmerName,
      'buyerId': _uid,
      'buyerName': await _myName('Buyer'),
      'priceMinor': box.priceMinor,
      'frequency': box.frequency.name,
      'deliveryAddress': address,
      'paymentMethod': 'cod',
      'status': 'active',
      'nextDeliveryAt': Timestamp.fromDate(firstDelivery),
      'deliveriesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(box.farmerId, 'New box subscriber',
        '${await _myName('A buyer')} subscribed to ${box.title}.', ref.id);
  }

  Stream<List<BoxSubscription>> mySubscriptions() => _db
      .collection('box_subscriptions')
      .where('buyerId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BoxSubscription.fromMap(d.id, d.data())).toList());

  Stream<List<BoxSubscription>> subscribers() => _db
      .collection('box_subscriptions')
      .where('farmerId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BoxSubscription.fromMap(d.id, d.data())).toList());

  /// Buyer pauses, resumes or cancels.
  Future<void> setSubscriptionStatus(BoxSubscription sub, String status) async {
    await _db.collection('box_subscriptions').doc(sub.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(sub.farmerId, 'Subscription $status',
        '${sub.buyerName}: ${sub.boxTitle} is now $status.', sub.id);
  }

  /// Farmer records this cycle's delivery; the next one is scheduled.
  Future<void> markBoxDelivered(BoxSubscription sub) async {
    final base = sub.nextDeliveryAt ?? DateTime.now();
    await _db.collection('box_subscriptions').doc(sub.id).update({
      'deliveriesCount': FieldValue.increment(1),
      'lastDeliveredAt': FieldValue.serverTimestamp(),
      'nextDeliveryAt':
          Timestamp.fromDate(base.add(Duration(days: sub.frequency.days))),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(sub.buyerId, 'Box delivered',
        '${sub.boxTitle} was delivered. Pay the farmer on delivery.', sub.id);
  }

  Future<void> _notify(
      String userId, String title, String body, String refId) async {
    if (userId.isEmpty || userId == _auth.currentUser?.uid) return;
    try {
      await sendNotification(_db, {
        'userId': userId,
        'title': title,
        'body': body.length > 500 ? body.substring(0, 500) : body,
        'type': 'subscription',
        'referenceId': refId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notifications are best-effort.
    }
  }
}
