import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/farm_input.dart';
import 'service_errors.dart';

/// Input marketplace (seeds, fertilizer, pesticides, tools) and machinery
/// rental. Plain client writes on the Spark plan; `firestore.rules`
/// validates ownership, prices, totals and the order state machine.
class InputMarketService {
  InputMarketService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _inputs =>
      _db.collection('inputs');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('input_orders');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  Future<Map<String, dynamic>> _me() async =>
      (await _db.collection('users').doc(_uid).get()).data() ?? const {};

  String _nameOf(Map<String, dynamic> user, String fallback) {
    final name = (user['displayName'] ?? user['name'] ?? '').toString().trim();
    return name.isEmpty ? fallback : name;
  }

  // ── Listings ────────────────────────────────────────────────

  /// Active listings for farmers, newest first (optionally one category).
  Stream<List<FarmInput>> catalog({InputCategory? category, int limit = 50}) {
    Query<Map<String, dynamic>> q = _inputs
        .where('status', isEqualTo: 'Active')
        .where('isDeleted', isEqualTo: false);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => FarmInput.fromMap(d.id, d.data())).toList());
  }

  /// The signed-in supplier's own listings (active and inactive).
  Stream<List<FarmInput>> myListings({int limit = 100}) => _inputs
      .where('supplierId', isEqualTo: _uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => FarmInput.fromMap(d.id, d.data())).toList());

  Map<String, dynamic> _listingFields({
    required String name,
    required InputCategory category,
    required bool isRental,
    required int priceMinor,
    required String unit,
    required int stock,
    required String description,
    required String district,
    String? imageUrl,
    required bool active,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 120) {
      throw UserArgumentError('Enter a name (up to 120 characters).');
    }
    if (priceMinor <= 0 || stock < 0) {
      throw UserArgumentError('Enter a valid price and stock.');
    }
    return {
      'name': cleanName,
      'category': category.name,
      'listingType': isRental ? 'rental' : 'sale',
      'priceMinor': priceMinor,
      'unit': isRental ? 'day' : unit.trim(),
      'stock': stock,
      'description': description.trim(),
      'district': district.trim(),
      'imageUrl': imageUrl,
      'status': active ? 'Active' : 'Inactive',
    };
  }

  Future<String> createListing({
    required String name,
    required InputCategory category,
    required bool isRental,
    required int priceMinor,
    required String unit,
    required int stock,
    String description = '',
    String district = '',
    String? imageUrl,
  }) async {
    final uid = _uid;
    final me = await _me();
    if (me['role'] != 'supplier') {
      throw UserStateError('Only input suppliers can list inputs.');
    }
    if (me['isVerified'] != true) {
      throw UserStateError(
          'Account verification is required before listing inputs.');
    }
    final ref = _inputs.doc();
    await ref.set({
      ..._listingFields(
        name: name,
        category: category,
        isRental: isRental,
        priceMinor: priceMinor,
        unit: unit,
        stock: stock,
        description: description,
        district: district,
        imageUrl: imageUrl,
        active: true,
      ),
      'supplierId': uid,
      'supplierName': _nameOf(me, 'Supplier'),
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    });
    return ref.id;
  }

  Future<void> updateListing(
    String id, {
    required String name,
    required InputCategory category,
    required bool isRental,
    required int priceMinor,
    required String unit,
    required int stock,
    String description = '',
    String district = '',
    String? imageUrl,
    bool active = true,
  }) async {
    await _inputs.doc(id).update({
      ..._listingFields(
        name: name,
        category: category,
        isRental: isRental,
        priceMinor: priceMinor,
        unit: unit,
        stock: stock,
        description: description,
        district: district,
        imageUrl: imageUrl,
        active: active,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _uid,
    });
  }

  /// Soft delete: hidden everywhere, kept for past orders.
  Future<void> deleteListing(String id) => _inputs.doc(id).update({
        'isDeleted': true,
        'status': 'Inactive',
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid,
      });

  // ── Orders and rental bookings ──────────────────────────────

  Stream<List<InputOrder>> farmerOrders({int limit = 50}) => _orders
      .where('farmerId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => InputOrder.fromMap(d.id, d.data())).toList());

  Stream<List<InputOrder>> supplierOrders({int limit = 50}) => _orders
      .where('supplierId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => InputOrder.fromMap(d.id, d.data())).toList());

  /// Farmer buys [quantity] of a sale listing, or books a machine for
  /// [days] from [startDate]. Cash on delivery.
  Future<String> placeOrder({
    required FarmInput input,
    required int quantity,
    required String deliveryAddress,
    int? days,
    DateTime? startDate,
  }) async {
    final uid = _uid;
    final me = await _me();
    if (me['role'] != 'farmer') {
      throw UserStateError('Only farmers can order farm inputs.');
    }
    final address = deliveryAddress.trim();
    if (address.length < 5) {
      throw UserArgumentError('Enter a complete delivery address.');
    }
    if (quantity < 1 || (!input.isRental && quantity > input.stock)) {
      throw UserArgumentError('Only ${input.stock} ${input.unit} in stock.');
    }
    if (input.isRental &&
        (days == null || days < 1 || days > 60 || startDate == null)) {
      throw UserArgumentError('Choose a start date and 1–60 days.');
    }
    // Re-read the listing so the price is the supplier's current one.
    final fresh = (await _inputs.doc(input.id).get()).data();
    if (fresh == null || fresh['status'] != 'Active' || fresh['isDeleted'] == true) {
      throw UserStateError('This listing is no longer available.');
    }
    final unitPrice = (fresh['priceMinor'] as num).toInt();
    final total = unitPrice * quantity * (input.isRental ? days! : 1);
    final ref = _orders.doc();
    await ref.set({
      'farmerId': uid,
      'farmerName': _nameOf(me, 'Farmer'),
      'supplierId': input.supplierId,
      'supplierName': input.supplierName,
      'inputId': input.id,
      'inputName': input.name,
      'category': input.category.name,
      'listingType': input.isRental ? 'rental' : 'sale',
      'unit': input.unit,
      'quantity': quantity,
      if (input.isRental) 'days': days,
      if (input.isRental) 'startDate': Timestamp.fromDate(startDate!),
      'unitPriceMinor': unitPrice,
      'totalMinor': total,
      'deliveryAddress': address,
      'paymentMethod': 'cod',
      'status': InputOrderStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(input.supplierId,
        input.isRental ? 'New rental booking' : 'New input order',
        '${_nameOf(me, 'A farmer')} ${input.isRental ? 'booked' : 'ordered'} '
            '${input.name}.',
        ref.id);
    return ref.id;
  }

  /// Moves [order] to [next]. Suppliers confirm (a sale takes stock in the
  /// same write), reject and advance; farmers cancel while pending.
  Future<void> transition(InputOrder order, String next) async {
    final uid = _uid;
    final ref = _orders.doc(order.id);
    final patch = <String, dynamic>{
      'status': next,
      '${next}At': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (next == InputOrderStatus.confirmed && !order.isRental) {
      final inputRef = _inputs.doc(order.inputId);
      await _db.runTransaction((tx) async {
        final input = (await tx.get(inputRef)).data();
        final stock = (input?['stock'] as num?)?.toInt() ?? 0;
        if (stock < order.quantity) {
          throw UserStateError('Not enough stock to confirm this order.');
        }
        tx.update(inputRef, {
          'stock': stock - order.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        });
        tx.update(ref, patch);
      });
    } else {
      await ref.update(patch);
    }
    final toFarmer = uid == order.supplierId;
    await _notify(
      toFarmer ? order.farmerId : order.supplierId,
      'Input order update',
      '${order.inputName}: ${_statusWord(next)}.',
      order.id,
    );
  }

  static String _statusWord(String status) => switch (status) {
        InputOrderStatus.inUse => 'in use',
        _ => status,
      };

  Future<void> _notify(
      String userId, String title, String body, String orderId) async {
    if (userId.isEmpty || userId == _auth.currentUser?.uid) return;
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body.length > 500 ? body.substring(0, 500) : body,
        'type': 'input_order',
        'referenceId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Input order notification skipped: $e');
    }
  }
}
