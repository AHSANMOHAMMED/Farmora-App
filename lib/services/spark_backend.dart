import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/localization/l10n.dart';
import '../models/order.dart' show PaymentMethod;
import '../models/product.dart';
import 'service_errors.dart';

/// Firestore-only backend for the free Firebase Spark plan (no Cloud
/// Functions). Each method ports the matching callable in
/// `functions/src/index.ts` to direct client writes; `firestore.rules`
/// validates every write (ownership, money fields, stock and the order /
/// transport / payment state machines).
///
/// Notifications and audit logs that a function would write server-side are
/// written here by the acting client (best effort: they never fail the
/// action they describe).
class SparkBackend {
  SparkBackend(this._db, {String Function()? currentUid})
      : _currentUid = currentUid;
  final FirebaseFirestore _db;
  final String Function()? _currentUid;

  /// Single platform settings document (also used by the Cloud Functions).
  static const settingsCollection = 'platform_settings';
  static const settingsDocId = 'global';

  static const _openJobStatuses = ['requested', 'accepted', 'pickedUp', 'inTransit'];
  static const _earningPaymentStatuses = ['paid', 'released', 'settled_split'];
  static const _marketUnits = [
    'kg', 'g', 'ton', 'piece', 'pcs', 'box', 'crate', 'bunch', 'bag', 'liter',
  ];
  static const _harvestStatuses = [
    'growing', 'harvested', 'packed', 'inTransit', 'delivered',
  ];

  String get _uid {
    final uid = _currentUid?.call() ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw UserStateError(L10n.current.errorSignInAgain);
    }
    return uid;
  }

  FieldValue get _now => FieldValue.serverTimestamp();

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  /// Reads a users document. Rules only allow the caller's own document
  /// (or any document for admins), so never call this for another user
  /// from a non-admin flow.
  Future<Map<String, dynamic>> userDoc(String uid) async {
    final snap = await _col('users').doc(uid).get();
    return snap.data() ?? {};
  }

  Future<Map<String, dynamic>> _me() => userDoc(_uid);

  static String _nameOf(Map<String, dynamic>? user, String fallback) {
    final name = (user?['displayName'] ?? user?['name'] ?? '').toString();
    return name.trim().isEmpty ? fallback : name;
  }

  static String orderNumberFor(String id) =>
      'FM-${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';

  static int _int(Object? v, [int fallback = 0]) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? fallback;

  Future<Map<String, dynamic>> _requireRole(List<String> roles) async {
    final me = await _me();
    if (!roles.contains(me['role']) ||
        me['isSuspended'] == true ||
        me['isDeleted'] == true) {
      throw UserStateError(L10n.current.errorNoPermission);
    }
    return me;
  }

  Future<Map<String, dynamic>> _requireVerifiedRole(List<String> roles) async {
    final me = await _requireRole(roles);
    if (me['isVerified'] != true) {
      throw UserStateError(
          'Account verification is required for this action.');
    }
    return me;
  }

  /// Admin check mirrored from `requireAdmin` (rules enforce it too).
  Future<Map<String, dynamic>> _requireAdmin() async {
    final me = await _me();
    if (me['role'] != 'admin' ||
        me['isVerified'] != true ||
        me['isSuspended'] == true ||
        me['isDeleted'] == true) {
      throw UserStateError(L10n.current.errorNoPermission);
    }
    return me;
  }

  /// Best-effort in-app notification for another user (rules: whitelisted
  /// keys/types, `userId != uid` except farm-task reminders).
  Future<void> _notify(
    String? userId,
    String title,
    String body,
    String type,
    String? referenceId, {
    Map<String, String> extra = const {},
  }) async {
    if (userId == null || userId.isEmpty) return;
    String? me;
    try {
      me = _uid;
    } catch (_) {}
    if (userId == me && type != 'farm_task') return;
    try {
      await _col('notifications').add({
        'userId': userId,
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'body': body.length > 500 ? body.substring(0, 500) : body,
        'type': type,
        if (referenceId != null) 'referenceId': referenceId,
        if (referenceId != null && type != 'farm_task') 'orderId': referenceId,
        ...extra,
        'read': false,
        'createdAt': _now,
      });
    } catch (e) {
      debugPrint('Notification to $userId skipped: $e');
    }
  }

  /// Admin audit entry with the Functions' AuditLog schema. Best effort.
  Future<void> _audit({
    required String actionType,
    required String targetEntity,
    required String targetId,
    String details = '',
    String severity = 'info',
    Map<String, dynamic>? actor,
  }) async {
    try {
      final uid = _uid;
      final me = actor ?? await _me();
      await _col('audit_logs').add({
        'actorId': uid,
        'actorName': _nameOf(me, uid),
        'actorRole': (me['role'] ?? 'admin').toString(),
        'actionType': actionType,
        'targetEntity': targetEntity,
        'targetId': targetId,
        'details': details,
        'severity': severity,
        'timestamp': _now,
        'createdAt': _now,
      });
    } catch (e) {
      debugPrint('Audit log skipped: $e');
    }
  }

  // ── Device tokens ─────────────────────────────────────────

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final uid = _uid;
    await _col('users')
        .doc(uid)
        .collection('device_tokens')
        .doc(token.hashCode.toString())
        .set({
      'token': token,
      'platform': platform,
      'enabled': true,
      'updatedAt': _now,
    }, SetOptions(merge: true));
  }

  Future<void> unregisterDeviceToken(String token) async {
    final uid = _uid;
    final snap = await _col('users')
        .doc(uid)
        .collection('device_tokens')
        .where('token', isEqualTo: token)
        .get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  // ── Platform settings (platform_settings/global) ──────────

  static const Map<String, dynamic> settingsDefaults = {
    'maintenanceMode': false,
    'maintenanceNotice': '',
    'platformFeeBps': 250,
    'sessionTimeoutMinutes': 60,
    'defaultDeliveryFeeMinor': 35000,
    'escrowReleaseHours': 72,
    'minAppVersion': '',
    'currency': 'LKR',
  };

  /// Public settings subset, sanitised like `loadPlatformSettings`.
  static Map<String, dynamic> sanitizeSettings(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    int intOr(String key) {
      final v = d[key];
      return v is num ? v.toInt() : settingsDefaults[key] as int;
    }

    return {
      'maintenanceMode': d['maintenanceMode'] == true,
      'maintenanceNotice': d['maintenanceNotice'] is String
          ? d['maintenanceNotice']
          : settingsDefaults['maintenanceNotice'],
      'platformFeeBps': intOr('platformFeeBps'),
      'sessionTimeoutMinutes': intOr('sessionTimeoutMinutes'),
      'defaultDeliveryFeeMinor': intOr('defaultDeliveryFeeMinor'),
      'escrowReleaseHours': intOr('escrowReleaseHours'),
      'minAppVersion': d['minAppVersion'] is String
          ? d['minAppVersion']
          : settingsDefaults['minAppVersion'],
      'currency': 'LKR',
    };
  }

  Future<Map<String, dynamic>> getPlatformSettings() async {
    try {
      final snap =
          await _col(settingsCollection).doc(settingsDocId).get();
      return sanitizeSettings(snap.data());
    } catch (e) {
      debugPrint('Platform settings unavailable ($e); using defaults');
      return sanitizeSettings(null);
    }
  }

  /// Validates like `updatePlatformSettings` and writes as the admin.
  static Map<String, dynamic> validateSettingsUpdate(
      Map<String, dynamic> data) {
    final updates = <String, dynamic>{};
    int checkedInt(String key, int min, int max) {
      final v = data[key];
      if (v is! num || v != v.roundToDouble() || v < min || v > max) {
        throw UserArgumentError('Invalid $key.');
      }
      return v.toInt();
    }

    if (data['maintenanceMode'] is bool) {
      updates['maintenanceMode'] = data['maintenanceMode'];
    }
    if (data.containsKey('maintenanceNotice')) {
      final notice = data['maintenanceNotice'];
      if (notice is! String || notice.length > 300) {
        throw UserArgumentError('Invalid maintenance notice.');
      }
      updates['maintenanceNotice'] = notice.trim();
    }
    if (data.containsKey('escrowReleaseHours')) {
      updates['escrowReleaseHours'] = checkedInt('escrowReleaseHours', 1, 720);
    }
    if (data.containsKey('minAppVersion')) {
      final v = data['minAppVersion'];
      if (v is! String ||
          v.length > 20 ||
          !RegExp(r'^[0-9A-Za-z.+-]*$').hasMatch(v)) {
        throw UserArgumentError('Invalid minimum app version.');
      }
      updates['minAppVersion'] = v.trim();
    }
    if (data.containsKey('defaultDeliveryFeeMinor')) {
      updates['defaultDeliveryFeeMinor'] =
          checkedInt('defaultDeliveryFeeMinor', 0, 10000000);
    }
    if (data.containsKey('platformFeeBps')) {
      updates['platformFeeBps'] = checkedInt('platformFeeBps', 0, 10000);
    }
    if (data.containsKey('sessionTimeoutMinutes')) {
      // 0 disables the inactivity timeout in the app.
      updates['sessionTimeoutMinutes'] =
          checkedInt('sessionTimeoutMinutes', 0, 1440);
    }
    if (updates.isEmpty) throw UserArgumentError('No settings supplied.');
    return updates;
  }

  Future<void> updatePlatformSettings(Map<String, dynamic> settings) async {
    final admin = await _requireAdmin();
    final updates = validateSettingsUpdate(settings);
    final before = await getPlatformSettings();
    await _col(settingsCollection).doc(settingsDocId).set({
      ...updates,
      'updatedBy': _uid,
      'updatedAt': _now,
    }, SetOptions(merge: true));
    final toggled = updates['maintenanceMode'] is bool &&
        updates['maintenanceMode'] != before['maintenanceMode'];
    await _audit(
      actor: admin,
      actionType:
          toggled ? 'MAINTENANCE_TOGGLE' : 'PLATFORM_SETTINGS_UPDATED',
      targetEntity: settingsCollection,
      targetId: settingsDocId,
      details:
          'Updated ${updates.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      severity: toggled || updates.containsKey('platformFeeBps')
          ? 'warning'
          : 'info',
    );
  }

  // ── Products ──────────────────────────────────────────────

  static List<String> _mediaOf(Object? raw) => raw is List
      ? raw
          .whereType<String>()
          .where((u) => u.startsWith('https://') && u.length < 2048)
          .take(5)
          .toList()
      : <String>[];

  static String? _isoOrNull(Object? v) {
    if (v == null || v == '') return null;
    if (v is DateTime) return v.toIso8601String();
    if (v is Timestamp) return v.toDate().toIso8601String();
    final parsed = DateTime.tryParse(v.toString());
    if (parsed == null) throw UserArgumentError('Invalid date.');
    return parsed.toIso8601String();
  }

  Future<String> createProduct(Product product) async {
    final uid = _uid;
    final me = await _requireRole(['farmer']);
    if (me['isVerified'] != true) {
      throw UserStateError(
          'Account verification is required before publishing products.');
    }
    final quantityAvailable = product.quantityAvailable > 0
        ? product.quantityAvailable
        : int.tryParse(
              RegExp(r'\d+').firstMatch(product.quantity)?.group(0) ?? '',
            ) ??
            0;
    final media = _mediaOf(product.media.isNotEmpty
        ? product.media
        : (product.imageUrls.isNotEmpty ? product.imageUrls : product.images));
    final priceMinor = product.priceMinor > 0
        ? product.priceMinor
        : (product.pricePerUnit * 100).round();
    final name = product.name.trim();
    if (name.isEmpty || name.length > 120 || priceMinor < 0) {
      throw UserArgumentError('Invalid product details.');
    }
    final ref = _col('products').doc();
    await ref.set({
      'farmerId': uid,
      'farmerName': _nameOf(me, 'Farmer'),
      'name': name,
      'category': product.category,
      'description': product.description.length > 4000
          ? product.description.substring(0, 4000)
          : product.description,
      'unit': product.unit,
      'location': product.location,
      'priceMinor': priceMinor,
      'price': 'LKR ${(priceMinor / 100).toStringAsFixed(2)} / ${product.unit}',
      'pricePerUnit': priceMinor / 100.0,
      'currency': 'LKR',
      'quantityAvailable': quantityAvailable,
      'quantity': '$quantityAvailable ${product.unit} available',
      'status': quantityAvailable > 0 ? 'Active' : 'Empty',
      'isOrganic': product.isOrganic,
      'media': media,
      'imageUrls': media,
      'images': media,
      if (media.isNotEmpty) 'imagePath': media.first,
      'availabilityDate': product.availabilityDate?.toIso8601String(),
      'harvestStatus': 'growing',
      'listingVersion': 1,
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  /// Port of `updateProduct` (owner farmer).
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final ref = _col('products').doc(productId);
    final existing = (await ref.get()).data();
    if (existing == null || existing['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    String str(String key) => data[key] is String
        ? (data[key] as String).trim()
        : (existing[key] ?? '').toString();
    final name = str('name');
    final category = str('category');
    final unit = data['unit'] is String
        ? (data['unit'] as String).trim()
        : (existing['unit'] ?? 'unit').toString();
    final location = str('location');
    final priceMinor = data['priceMinor'] == null
        ? _int(existing['priceMinor'])
        : _int(data['priceMinor'], -1);
    final quantityAvailable = data['quantityAvailable'] == null
        ? _int(existing['quantityAvailable'])
        : _int(data['quantityAvailable'], -1);
    final requestedStatus = data['status'] == 'Empty' ? 'Empty' : 'Active';
    if (name.isEmpty ||
        name.length > 120 ||
        category.isEmpty ||
        unit.isEmpty ||
        location.isEmpty ||
        priceMinor < 0 ||
        quantityAvailable < 0) {
      throw UserArgumentError('Invalid product details.');
    }
    final media =
        data['media'] is List ? _mediaOf(data['media']) : _mediaOf(existing['media']);
    final availabilityDate = data.containsKey('availabilityDate')
        ? _isoOrNull(data['availabilityDate'])
        : (existing['availabilityDate'] is String
            ? existing['availabilityDate']
            : null);
    final description = data['description'] is String
        ? (data['description'] as String).trim()
        : (existing['description'] ?? '').toString();
    await ref.update({
      'availabilityDate': availabilityDate,
      'name': name,
      'category': category,
      'description':
          description.length > 4000 ? description.substring(0, 4000) : description,
      'unit': unit,
      'location': location,
      'priceMinor': priceMinor,
      'price': 'LKR ${(priceMinor / 100).toStringAsFixed(2)} / $unit',
      'pricePerUnit': priceMinor / 100,
      'quantityAvailable': quantityAvailable,
      'quantity': '$quantityAvailable $unit available',
      'status': quantityAvailable > 0 ? requestedStatus : 'Empty',
      'isOrganic': data['isOrganic'] == null
          ? existing['isOrganic'] == true
          : data['isOrganic'] == true,
      'media': media,
      'imageUrls': media,
      'images': media,
      'updatedAt': _now,
      'listingVersion': _int(existing['listingVersion'], 1) + 1,
    });
  }

  /// Port of `deleteProduct`: refuses while the product has active orders.
  Future<void> deleteProduct(String productId) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final ref = _col('products').doc(productId);
    final existing = (await ref.get()).data();
    if (existing == null || existing['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    final active = await _col('orders')
        .where('farmerId', isEqualTo: uid)
        .where('productId', isEqualTo: productId)
        .where('status', whereIn: [
          'pending', 'confirmed', 'assigned', 'pickedUp', 'inTransit',
        ])
        .limit(1)
        .get();
    if (active.docs.isNotEmpty) {
      throw UserStateError(
          'Product has active orders and cannot be removed.');
    }
    await ref.delete();
  }

  /// Port of `generateProductQr`.
  Future<String> generateProductQr(String productId) async {
    final uid = _uid;
    await _requireRole(['farmer']);
    final ref = _col('products').doc(productId);
    final product = (await ref.get()).data();
    if (product == null || product['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    final qrCode = 'farmora://product/$productId';
    await ref.update({
      'qrCode': qrCode,
      if (product['packingDate'] == null)
        'packingDate': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': _now,
    });
    return qrCode;
  }

  /// Port of `setProductMedia` (owner farmer). Old video files are deleted by
  /// the caller (FirestoreService) since only the owner may delete them.
  Future<void> setProductMedia({
    required String productId,
    String? videoPath,
    String? videoUrl,
    bool clearVideo = false,
    String? harvestStatus,
    DateTime? harvestDate,
  }) async {
    final uid = _uid;
    await _requireRole(['farmer']);
    final ref = _col('products').doc(productId);
    final product = (await ref.get()).data();
    if (product == null || product['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    final updates = <String, dynamic>{};
    if (clearVideo) {
      updates['videoPath'] = FieldValue.delete();
      updates['videoUrl'] = FieldValue.delete();
    } else {
      if (videoPath != null) {
        if (videoPath.contains('..') ||
            !(videoPath.startsWith('product_videos/$uid/') ||
                videoPath.startsWith('products/$productId/'))) {
          throw UserArgumentError('Invalid video path.');
        }
        updates['videoPath'] = videoPath;
      }
      if (videoUrl != null) {
        if (!videoUrl.startsWith('https://') && !videoUrl.startsWith('http://')) {
          throw UserArgumentError('Invalid video URL.');
        }
        updates['videoUrl'] = videoUrl;
      }
    }
    if (harvestStatus != null) {
      if (!_harvestStatuses.contains(harvestStatus)) {
        throw UserArgumentError('Invalid harvest status.');
      }
      updates['harvestStatus'] = harvestStatus;
    }
    if (harvestDate != null) {
      updates['harvestDate'] = harvestDate.toUtc().toIso8601String();
    }
    if (updates.isEmpty) throw UserArgumentError('No media changes supplied.');
    await ref.update({...updates, 'updatedAt': _now});
  }

  // ── Orders ────────────────────────────────────────────────

  static Map<String, String>? usableBank(Map<String, dynamic>? bank) {
    if (bank == null) return null;
    final number = (bank['accountNumber'] ?? '').toString();
    if ((bank['bankName'] ?? '').toString().isEmpty ||
        (bank['branch'] ?? '').toString().isEmpty ||
        (bank['accountHolderName'] ?? '').toString().isEmpty ||
        !RegExp(r'^[0-9]{6,18}$').hasMatch(number)) {
      return null;
    }
    return {
      'bankName': bank['bankName'].toString(),
      'branch': bank['branch'].toString(),
      'accountHolderName': bank['accountHolderName'].toString(),
      'accountNumber': number,
    };
  }

  /// Checkout retries reuse the same order document (idempotency).
  static String idempotentOrderId(String idempotencyKey) {
    final safe = idempotencyKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final trimmed = safe.length > 200 ? safe.substring(0, 200) : safe;
    return 'ck_$trimmed';
  }

  /// Order document shape validated by `orderMoneyShapeOk` in the rules.
  Map<String, dynamic> _orderData({
    required String orderId,
    required String buyerId,
    required String farmerId,
    required String productId,
    required Map<String, dynamic> product,
    required int quantity,
    required int unitPriceMinor,
    required int deliveryFeeMinor,
    required String deliveryAddress,
    required String paymentMethod,
    required String buyerName,
    required String farmerName,
    required int platformFeeBps,
    Map<String, String>? bankSnapshot,
    String? requestedTransporterId,
    String? offerId,
    String? sourceRequestId,
  }) {
    final unit = (product['unit'] ?? 'unit').toString();
    final productName = (product['name'] ?? 'Produce').toString();
    final subtotal = unitPriceMinor * quantity;
    final fee = (subtotal * platformFeeBps / 10000).round();
    return {
      'orderNumber': orderNumberFor(orderId),
      'buyerId': buyerId,
      'farmerId': farmerId,
      'productId': productId,
      'productName': productName,
      'title': productName,
      'quantity': '$quantity $unit',
      'unit': unit,
      'listingVersion': _int(product['listingVersion'], 1),
      'items': [
        {
          'productId': productId,
          'quantity': quantity,
          'pricePerUnitMinor': unitPriceMinor,
          'lineTotalMinor': subtotal,
        }
      ],
      'requestedQuantity': quantity,
      'subtotalMinor': subtotal,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': subtotal + deliveryFeeMinor,
      'platformFeeMinor': fee.clamp(0, subtotal),
      'currency': 'LKR',
      'deliveryAddress': deliveryAddress,
      'pickupAddress': (product['location'] ?? 'Farm pickup').toString(),
      'location': (product['location'] ?? '').toString(),
      'buyerName': buyerName,
      'farmerName': farmerName,
      'status': 'pending',
      if (requestedTransporterId != null && requestedTransporterId.isNotEmpty)
        'requestedTransporterId': requestedTransporterId,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'payment_required',
      if (bankSnapshot != null) 'bankDetailsSnapshot': bankSnapshot,
      'escrowStatus': 'not_funded',
      if (offerId != null) 'offerId': offerId,
      if (sourceRequestId != null) 'sourceRequestId': sourceRequestId,
      'createdAt': _now,
      'updatedAt': _now,
    };
  }

  /// Stock change bound to [orderId] (`lastOrderId`, checked by the rules).
  Map<String, dynamic> _stockUpdate(
      Map<String, dynamic> product, int newQuantity, String orderId) {
    final unit = (product['unit'] ?? 'unit').toString();
    return {
      'quantityAvailable': newQuantity,
      'quantity': '$newQuantity $unit available',
      'status': newQuantity > 0 ? 'Active' : 'Empty',
      'updatedAt': _now,
      'lastOrderId': orderId,
    };
  }

  Future<Map<String, String>> _bankSnapshotIn(
      Transaction tx, String farmerId) async {
    final bank =
        usableBank((await tx.get(_col('bank_details').doc(farmerId))).data());
    if (bank == null) throw UserStateError(L10n.current.svcFarmerNoBankDeposit);
    return bank;
  }

  /// Buyer checkout (port of `createOrder`). The order, the stock
  /// reservation and (for bank deposit) the account snapshot are written in
  /// one transaction; retries with the same [idempotencyKey] return the
  /// existing order. A chosen transporter is stored as
  /// `requestedTransporterId`; the targeted transport job is created when the
  /// farmer confirms.
  Future<String> createOrder({
    required String productId,
    required int quantity,
    int deliveryFeeMinor = 0,
    String? transporterId,
    required String deliveryAddress,
    required String idempotencyKey,
    String paymentMethod = PaymentMethod.cod,
  }) async {
    final uid = _uid;
    final address = deliveryAddress.trim();
    if (quantity < 1 || deliveryFeeMinor < 0 || deliveryFeeMinor > 10000000) {
      throw UserArgumentError('Invalid order details.');
    }
    if (address.length < 5 || address.length > 500) {
      throw UserArgumentError('Delivery address is required.');
    }
    final method = paymentMethod == PaymentMethod.bankDeposit
        ? PaymentMethod.bankDeposit
        : PaymentMethod.cod;
    final me = await _requireRole(['buyer']);
    final settings = await getPlatformSettings();
    final orderRef = _col('orders').doc(idempotentOrderId(idempotencyKey));
    final productRef = _col('products').doc(productId);
    String? farmerId;
    String productName = '';
    final created = await _db.runTransaction<bool>((tx) async {
      final previous = await tx.get(orderRef);
      if (previous.exists) {
        final data = previous.data() ?? const {};
        if (data['buyerId'] == uid && data['productId'] == productId) {
          return false;
        }
        throw UserStateError(
            'This checkout was already submitted with different details.');
      }
      final productSnap = await tx.get(productRef);
      final product = productSnap.data();
      if (product == null || product['status'] != 'Active') {
        throw UserStateError(L10n.current.svcProductNotFound);
      }
      final available = _int(product['quantityAvailable']);
      if (available < quantity) {
        throw UserStateError(L10n.current.svcNotEnoughStock);
      }
      farmerId = product['farmerId']?.toString();
      if (farmerId == null || farmerId!.isEmpty || farmerId == uid) {
        throw UserStateError(L10n.current.svcProductNotFound);
      }
      productName = (product['name'] ?? '').toString();
      final bank = method == PaymentMethod.bankDeposit
          ? await _bankSnapshotIn(tx, farmerId!)
          : null;
      tx.set(
        orderRef,
        _orderData(
          orderId: orderRef.id,
          buyerId: uid,
          farmerId: farmerId!,
          productId: productId,
          product: product,
          quantity: quantity,
          unitPriceMinor: _int(product['priceMinor']),
          deliveryFeeMinor: deliveryFeeMinor,
          deliveryAddress: address,
          paymentMethod: method,
          bankSnapshot: bank,
          buyerName: _nameOf(me, 'Buyer'),
          farmerName: (product['farmerName'] ?? 'Farmer').toString(),
          platformFeeBps: _int(settings['platformFeeBps']),
          requestedTransporterId:
              (transporterId?.isNotEmpty ?? false) ? transporterId : null,
        ),
      );
      tx.update(productRef, _stockUpdate(product, available - quantity, orderRef.id));
      return true;
    });
    if (created) {
      await _notify(
        farmerId,
        'New order received',
        'A buyer ordered ${productName.isEmpty ? 'your produce' : productName}.',
        'order',
        orderRef.id,
      );
    }
    return orderRef.id;
  }

  /// Transport job document for a confirmed order (port of
  /// `createTransportJobForOrder`). `transporterId` is explicitly null for
  /// open jobs so transporters can query `transporterId == null`.
  Map<String, dynamic> newJobData(
    String orderId,
    Map<String, dynamic> order, {
    int? deliveryFeeMinor,
  }) {
    final fee = deliveryFeeMinor ?? _int(order['deliveryFeeMinor']);
    final productName =
        (order['productName'] ?? order['title'] ?? 'Produce').toString();
    final pickup =
        (order['pickupAddress'] ?? order['location'] ?? 'Farm pickup').toString();
    final dropoff =
        (order['deliveryAddress'] ?? 'Buyer delivery point').toString();
    final unit = (order['unit'] ?? 'units').toString();
    final items = order['items'];
    final quantityValue = items is List && items.isNotEmpty && items.first is Map
        ? _int((items.first as Map)['quantity'])
        : 0;
    final qtyLabel = (order['quantity'] ?? '$quantityValue $unit').toString();
    final requested = (order['requestedTransporterId'] ?? '').toString();
    return {
      'orderId': orderId,
      'orderNumber': (order['orderNumber'] ?? orderNumberFor(orderId)).toString(),
      'farmerId': order['farmerId'],
      'buyerId': order['buyerId'],
      'farmerName': (order['farmerName'] ?? 'Farmer').toString(),
      'buyerName': (order['buyerName'] ?? 'Buyer').toString(),
      'title': 'Delivery for $productName',
      'route': '$pickup → $dropoff',
      'detail': '$qtyLabel · Ready for pickup',
      'fee': 'LKR ${(fee / 100).toStringAsFixed(2)}',
      'offeredFeeMinor': fee,
      'deliveryFeeMinor': fee,
      'pickupAddress': pickup,
      'dropoffAddress': dropoff,
      'pickup': pickup,
      'dropoff': dropoff,
      'productName': productName,
      if (order['productId'] != null) 'productId': order['productId'],
      'quantity': qtyLabel,
      'quantityValue': quantityValue,
      'unit': unit,
      'district': (order['location'] ?? '').toString(),
      'status': 'requested',
      'accepted': false,
      'transporterId': requested.isEmpty ? null : requested,
      if (requested.isNotEmpty) 'requestedTransporterId': requested,
      'createdAt': _now,
      'updatedAt': _now,
    };
  }

  /// Port of `transitionOrder` for the farmer (confirm / reject / cancel a
  /// confirmed order) and the buyer (cancel a pending order).
  Future<void> transitionOrder(String orderId, String status) async {
    final uid = _uid;
    final ref = _col('orders').doc(orderId);
    final snap = await ref.get();
    final order = snap.data();
    if (order == null) throw UserStateError(L10n.current.svcOrderNotFound);
    final me = await _requireRole(['farmer', 'buyer']);
    final isFarmer = me['role'] == 'farmer' && order['farmerId'] == uid;
    final isBuyer = me['role'] == 'buyer' && order['buyerId'] == uid;
    final current = (order['status'] ?? '').toString();
    final allowed = <String, List<String>>{
      'pending': isFarmer ? ['confirmed', 'rejected'] : ['cancelled'],
      'confirmed': isFarmer ? ['cancelled'] : const [],
    };
    if ((!isFarmer && !isBuyer) ||
        !(allowed[current]?.contains(status) ?? false)) {
      throw UserStateError('This order can no longer be changed to $status.');
    }
    final productName = (order['productName'] ?? 'produce').toString();

    if (status == 'confirmed') {
      if (me['isVerified'] != true) {
        throw UserStateError(
            'Account verification is required for this action.');
      }
      final jobRef = _col('transport_jobs').doc();
      final batch = _db.batch()
        ..update(ref, {
          'status': 'confirmed',
          'confirmedAt': _now,
          'updatedAt': _now,
        })
        ..set(jobRef, newJobData(orderId, order));
      await batch.commit();
      final selected = (order['requestedTransporterId'] ?? '').toString();
      if (selected.isNotEmpty) {
        await _notify(selected, 'Delivery request',
            'A confirmed order for $productName is ready for delivery.',
            'logistics', orderId, extra: {'jobId': jobRef.id});
      }
      await _notify(order['buyerId']?.toString(), 'Order Confirmed',
          'Your order for $productName was confirmed. Transport is being arranged.',
          'order', orderId);
      return;
    }

    // rejected / cancelled: close the order and restore stock once.
    await _db.runTransaction((tx) async {
      final latest = await tx.get(ref);
      final data = latest.data();
      if (data == null || data['status'] != current) {
        throw UserStateError('Order changed. Refresh and retry.');
      }
      final restore = data['stockRestored'] != true;
      final items = data['items'];
      final qty = items is List && items.isNotEmpty && items.first is Map
          ? _int((items.first as Map)['quantity'])
          : 0;
      final productId = (data['productId'] ??
              (items is List && items.isNotEmpty && items.first is Map
                  ? (items.first as Map)['productId']
                  : null) ??
              '')
          .toString();
      DocumentSnapshot<Map<String, dynamic>>? productSnap;
      if (restore && qty > 0 && productId.isNotEmpty) {
        productSnap = await tx.get(_col('products').doc(productId));
      }
      tx.update(ref, {
        'status': status,
        'stockRestored': true,
        if (status == 'cancelled') 'cancelledAt': _now,
        if (status == 'cancelled') 'cancelledBy': uid,
        if (status == 'rejected') 'rejectedAt': _now,
        'updatedAt': _now,
      });
      final product = productSnap?.data();
      if (productSnap != null && product != null) {
        tx.update(
          productSnap.reference,
          _stockUpdate(
              product, _int(product['quantityAvailable']) + qty, orderId),
        );
      }
    });
    if (isFarmer && current == 'confirmed') {
      // Close the still-open transport request of the cancelled order.
      final jobs = await _col('transport_jobs')
          .where('orderId', isEqualTo: orderId)
          .where('farmerId', isEqualTo: uid)
          .where('status', isEqualTo: 'requested')
          .get();
      for (final job in jobs.docs) {
        try {
          await job.reference.update({
            'status': 'cancelled',
            'cancelledBy': uid,
            'cancelledAt': _now,
            'updatedAt': _now,
          });
        } catch (e) {
          debugPrint('Transport request cancel skipped: $e');
        }
      }
    }
    await _notify(
      (isFarmer ? order['buyerId'] : order['farmerId'])?.toString(),
      status == 'rejected' ? 'Order Declined' : 'Order Cancelled',
      'Order for $productName was $status.',
      'order',
      orderId,
    );
  }

  /// Port of `requestTransport` (farmer): reuses an open request (updating
  /// its fee) or opens a new one for a confirmed order.
  Future<void> requestTransport({
    required String orderId,
    int? deliveryFeeMinor,
  }) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final orderSnap = await _col('orders').doc(orderId).get();
    final order = orderSnap.data();
    if (order == null || order['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcOrderNotFound);
    }
    if (!['confirmed', 'assigned'].contains(order['status'])) {
      throw UserStateError(
          'Order must be confirmed before requesting transport.');
    }
    final fee = deliveryFeeMinor != null &&
            deliveryFeeMinor >= 0 &&
            deliveryFeeMinor <= 10000000
        ? deliveryFeeMinor
        : null;
    // Scoped to this farmer so firestore.rules can authorise the query.
    final existing = await _col('transport_jobs')
        .where('orderId', isEqualTo: orderId)
        .where('farmerId', isEqualTo: uid)
        .where('status', whereIn: _openJobStatuses)
        .get();
    final open = existing.docs
        .where((d) => d.data()['status'] == 'requested')
        .toList();
    if (open.isNotEmpty) {
      if (fee != null) {
        await open.first.reference.update({
          'offeredFeeMinor': fee,
          'deliveryFeeMinor': fee,
          'fee': 'LKR ${(fee / 100).toStringAsFixed(2)}',
          'updatedAt': _now,
        });
      }
      return;
    }
    if (existing.docs.isNotEmpty) return; // already assigned / moving
    await _col('transport_jobs')
        .add(newJobData(orderId, order, deliveryFeeMinor: fee));
  }

  static String normalizeJobStatus(String value) {
    switch (value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '_')) {
      case 'OPEN':
      case 'REQUESTED':
      case 'PENDING':
        return 'requested';
      case 'ACCEPTED':
        return 'accepted';
      case 'COLLECTED':
      case 'PICKEDUP':
      case 'PICKED_UP':
        return 'pickedUp';
      case 'IN_TRANSIT':
      case 'INTRANSIT':
        return 'inTransit';
      case 'COMPLETED':
      case 'DELIVERED':
        return 'delivered';
      case 'CANCELLED':
        return 'cancelled';
      case 'DECLINED':
      case 'DECLINE':
        return 'declined';
      default:
        return value;
    }
  }

  /// Port of `transitionTransport` + `onTransportTransition` (transporter).
  ///
  /// * `accepted` — claims an open job (or one targeted to the caller); the
  ///   order becomes `assigned` in the same batch.
  /// * `pickedUp` / `inTransit` / `delivered` — advance in order; the order
  ///   mirrors the status.
  /// * `declined` — a targeted transporter releases the request to everyone.
  /// * `cancelled` — dropping an accepted job before pickup reopens it: the
  ///   job goes back to `requested` (no transporter) and the order back to
  ///   `confirmed`.
  Future<void> transitionTransport(String jobId, String status,
      {String? reason}) async {
    final uid = _uid;
    final me = await _requireRole(['transporter']);
    final ref = _col('transport_jobs').doc(jobId);
    final job = (await ref.get()).data();
    if (job == null) throw UserStateError(L10n.current.svcJobNotFound);
    final current = normalizeJobStatus((job['status'] ?? '').toString());
    final next = normalizeJobStatus(status);
    final note = (reason ?? '').trim();
    final trimmedReason = note.length > 500 ? note.substring(0, 500) : note;
    final orderId = (job['orderId'] ?? '').toString();
    final orderRef = orderId.isEmpty ? null : _col('orders').doc(orderId);
    final assignedTo = job['transporterId']?.toString();
    final requestedFor = job['requestedTransporterId']?.toString();
    final productLabel = (job['productName'] ?? 'your order').toString();

    Future<void> notifyParties(String title, String body) async {
      await _notify(job['buyerId']?.toString(), title, body, 'logistics',
          orderId.isEmpty ? null : orderId, extra: {'jobId': jobId});
      await _notify(job['farmerId']?.toString(), title, body, 'logistics',
          orderId.isEmpty ? null : orderId, extra: {'jobId': jobId});
    }

    if (next == 'declined') {
      if (current != 'requested' ||
          (requestedFor != uid && assignedTo != uid)) {
        throw UserStateError('This request cannot be declined.');
      }
      final batch = _db.batch()
        ..update(ref, {
          'transporterId': null,
          'requestedTransporterId': FieldValue.delete(),
          'declinedBy': FieldValue.arrayUnion([uid]),
          if (trimmedReason.isNotEmpty) 'declineReason': trimmedReason,
          'declinedAt': _now,
          'updatedAt': _now,
        });
      if (orderRef != null && requestedFor == uid) {
        batch.update(orderRef, {
          'requestedTransporterId': FieldValue.delete(),
          'updatedAt': _now,
        });
      }
      await batch.commit();
      await _notify(
        job['farmerId']?.toString(),
        'Delivery request declined',
        'The selected transporter declined the delivery for $productLabel. '
            'It is now open to other transporters.',
        'logistics',
        orderId.isEmpty ? null : orderId,
        extra: {'jobId': jobId},
      );
      return;
    }

    if (next == 'accepted') {
      if (current != 'requested' ||
          (assignedTo != null && assignedTo.isNotEmpty && assignedTo != uid) ||
          (requestedFor != null && requestedFor.isNotEmpty && requestedFor != uid)) {
        throw UserStateError(
            'This delivery request is assigned to another transporter.');
      }
      if (me['isVerified'] != true) {
        throw UserStateError(
            'Account verification is required for this action.');
      }
      if (orderRef == null) throw UserStateError(L10n.current.svcOrderNotFound);
      final batch = _db.batch()
        ..update(ref, {
          'status': 'accepted',
          'transporterId': uid,
          'accepted': true,
          'acceptedAt': _now,
          'updatedAt': _now,
        })
        ..update(orderRef, {
          'status': 'assigned',
          'transporterId': uid,
          'transportJobId': jobId,
          'assignedAt': _now,
          'updatedAt': _now,
        });
      try {
        await batch.commit();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw UserStateError(
              'Delivery was claimed or updated. Refresh and retry.');
        }
        rethrow;
      }
      await notifyParties(
          'Delivery update', 'Delivery for $productLabel is now accepted.');
      return;
    }

    if (next == 'cancelled') {
      if (current != 'accepted' || assignedTo != uid) {
        throw UserStateError(
            'Only an accepted delivery can be cancelled before pickup.');
      }
      final batch = _db.batch()
        ..update(ref, {
          'status': 'requested',
          'transporterId': null,
          'requestedTransporterId': FieldValue.delete(),
          'accepted': false,
          'acceptedAt': FieldValue.delete(),
          'declinedBy': FieldValue.arrayUnion([uid]),
          if (trimmedReason.isNotEmpty) 'cancellationReason': trimmedReason,
          'droppedAt': _now,
          'updatedAt': _now,
          'courierLat': FieldValue.delete(),
          'courierLng': FieldValue.delete(),
          'locationUpdatedAt': FieldValue.delete(),
        });
      if (orderRef != null) {
        batch.update(orderRef, {
          'status': 'confirmed',
          'transporterId': FieldValue.delete(),
          'requestedTransporterId': FieldValue.delete(),
          'transportJobId': FieldValue.delete(),
          'updatedAt': _now,
        });
      }
      await batch.commit();
      await notifyParties(
        'Delivery update',
        'The transporter cancelled the delivery for $productLabel. '
            'It has been re-opened for other transporters.',
      );
      return;
    }

    const order = ['accepted', 'pickedUp', 'inTransit', 'delivered'];
    final from = order.indexOf(current);
    if (assignedTo != uid ||
        from < 0 ||
        from + 1 >= order.length ||
        order[from + 1] != next) {
      throw UserStateError('Invalid transport transition.');
    }
    final delivered = next == 'delivered';
    final batch = _db.batch()
      ..update(ref, {
        'status': next,
        '${next}At': _now,
        'updatedAt': _now,
        // Privacy: never keep the last courier position after delivery.
        if (delivered) 'courierLat': FieldValue.delete(),
        if (delivered) 'courierLng': FieldValue.delete(),
        if (delivered) 'locationUpdatedAt': FieldValue.delete(),
      });
    if (orderRef != null) {
      batch.update(orderRef, {
        'status': next,
        '${next}At': _now,
        'updatedAt': _now,
      });
    }
    await batch.commit();
    await notifyParties(
        'Delivery update', 'Delivery for $productLabel is now $next.');
    if (delivered && orderRef != null) {
      await _cleanupVideoForOrder(orderId, job['productId']?.toString());
    }
  }

  Future<void> updateTransportLocation({
    required String jobId,
    required double lat,
    required double lng,
  }) async {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw UserArgumentError('Invalid coordinates.');
    }
    await _col('transport_jobs').doc(jobId).update({
      'courierLat': lat,
      'courierLng': lng,
      'locationUpdatedAt': _now,
      'updatedAt': _now,
    });
  }

  /// Port of `cancelTransportRequest` (farmer, `requested` jobs only).
  Future<void> cancelTransportRequest(String jobId) async {
    final uid = _uid;
    await _requireRole(['farmer']);
    final ref = _col('transport_jobs').doc(jobId);
    final job = await _db.runTransaction((tx) async {
      final current = (await tx.get(ref)).data();
      if (current == null || current['farmerId'] != uid) {
        throw UserStateError(L10n.current.svcJobNotFound);
      }
      if (current['status'] != 'requested') {
        throw UserStateError('Only open transport requests can be cancelled.');
      }
      tx.update(ref, {
        'status': 'cancelled',
        'cancelledBy': uid,
        'cancelledAt': _now,
        'updatedAt': _now,
      });
      return current;
    });
    final targeted =
        (job['transporterId'] ?? job['requestedTransporterId'] ?? '').toString();
    await _notify(
      targeted,
      'Delivery request cancelled',
      'The farmer cancelled the delivery request for ${job['productName'] ?? 'an order'}.',
      'logistics',
      job['orderId']?.toString(),
      extra: {'jobId': jobId},
    );
  }

  /// Port of `confirmHandover` (farmer).
  Future<void> confirmHandover(String orderId) async {
    final uid = _uid;
    await _requireRole(['farmer']);
    final ref = _col('orders').doc(orderId);
    final order = (await ref.get()).data();
    if (order == null || order['farmerId'] != uid) {
      throw UserStateError(L10n.current.svcOrderNotFound);
    }
    if (!['assigned', 'pickedUp'].contains(order['status'])) {
      throw UserStateError(
          'Handover is available once a transporter is assigned.');
    }
    await ref.update({'farmerHandedOverAt': _now, 'updatedAt': _now});
    await _notify(
      order['buyerId']?.toString(),
      'Order handed over',
      'The farmer handed over ${order['productName'] ?? 'your order'} to the transporter.',
      'order',
      orderId,
    );
  }

  Future<void> updateOrderAddress({
    required String orderId,
    required String deliveryAddress,
  }) async {
    final uid = _uid;
    final address = deliveryAddress.trim();
    if (address.length < 5 || address.length > 500) {
      throw UserArgumentError('Valid address required.');
    }
    final snap = await _col('orders').doc(orderId).get();
    final order = snap.data();
    if (order == null || order['buyerId'] != uid) {
      throw UserStateError(L10n.current.svcOrderNotFound);
    }
    if (order['status'] != 'pending') {
      throw UserStateError(L10n.current.svcAddressLocked);
    }
    await snap.reference.update({
      'deliveryAddress': address,
      'updatedAt': _now,
    });
  }

  /// Farmer confirms payment (COD after delivery, or a submitted slip).
  Future<void> markPaymentReceived({
    required String orderId,
    String method = 'cod',
  }) async {
    final uid = _uid;
    final snap = await _col('orders').doc(orderId).get();
    final order = snap.data();
    if (order == null) throw UserStateError(L10n.current.svcOrderNotFound);
    if (order['farmerId'] != uid) {
      throw UserStateError(L10n.current.errorNoPermission);
    }
    await snap.reference.update({
      'paymentStatus': 'paid',
      'paidAt': _now,
      'paymentConfirmedBy': uid,
      'updatedAt': _now,
    });
    await _notify(order['buyerId']?.toString(), 'Payment confirmed',
        'The farmer confirmed your $method payment.', 'payment', orderId);
  }

  /// Port of `getFarmerBankDetails`. `bank_details` is readable by signed-in
  /// users in Spark mode (deposit instructions for buyers).
  Future<Map<String, dynamic>> getFarmerBankDetails({
    String? farmerId,
    String? orderId,
  }) async {
    _uid;
    if (orderId != null && orderId.isNotEmpty) {
      final order = (await _col('orders').doc(orderId).get()).data();
      if (order == null) throw UserStateError(L10n.current.svcOrderNotFound);
      if (order['paymentMethod'] != PaymentMethod.bankDeposit) {
        throw UserStateError(L10n.current.svcReceiptBankOnly);
      }
      final snapshot = order['bankDetailsSnapshot'];
      final bank = snapshot is Map && snapshot['accountNumber'] != null
          ? usableBank(Map<String, dynamic>.from(snapshot))
          : usableBank((await _col('bank_details')
                  .doc(order['farmerId'].toString())
                  .get())
              .data());
      if (bank == null) return {'available': false};
      return {'available': true, ...bank};
    }
    if (farmerId == null || farmerId.isEmpty) {
      throw UserArgumentError('farmerId or orderId is required.');
    }
    final bank = usableBank((await _col('bank_details').doc(farmerId).get()).data());
    return {'available': bank != null};
  }

  // ── Offers ────────────────────────────────────────────────

  Future<String> createOffer({
    required String productId,
    required int proposedQuantity,
    required double proposedPrice,
  }) async {
    final uid = _uid;
    final buyer = await _requireRole(['buyer']);
    if (proposedQuantity < 1 ||
        !proposedPrice.isFinite ||
        proposedPrice <= 0 ||
        proposedPrice > 100000000) {
      throw UserArgumentError('Invalid offer details.');
    }
    final priceMinor = (proposedPrice * 100).round();
    final product = (await _col('products').doc(productId).get()).data();
    if (product == null || product['status'] != 'Active') {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    if (_int(product['quantityAvailable']) < proposedQuantity) {
      throw UserStateError(L10n.current.svcNotEnoughStock);
    }
    final farmerId = (product['farmerId'] ?? '').toString();
    if (farmerId.isEmpty || farmerId == uid) {
      throw UserStateError(L10n.current.svcProductNotFound);
    }
    final unit = (product['unit'] ?? 'unit').toString();
    final ref = _col('offers').doc();
    await ref.set({
      'productId': productId,
      'productName': (product['name'] ?? '').toString(),
      'unit': unit,
      'buyerId': uid,
      'buyerName': _nameOf(buyer, 'Buyer'),
      'farmerId': farmerId,
      'farmerName': (product['farmerName'] ?? 'Farmer').toString(),
      'proposedQuantity': proposedQuantity,
      'proposedPrice': priceMinor / 100,
      'proposedPriceMinor': priceMinor,
      'status': 'pending',
      'createdAt': _now,
      'updatedAt': _now,
    });
    await _notify(
      farmerId,
      'New Price Offer',
      'You received an offer of LKR ${(priceMinor / 100).toStringAsFixed(2)} '
          'per $unit for $proposedQuantity $unit.',
      'offer',
      ref.id,
      extra: {'offerId': ref.id},
    );
    return ref.id;
  }

  /// Farmer accepts a `pending` offer, or the buyer accepts a `countered`
  /// one. One transaction creates the pending order, reserves stock and
  /// marks the offer accepted.
  Future<String> acceptOffer({
    required String offerId,
    int deliveryFeeMinor = 35000,
    String? deliveryAddress,
    String? paymentMethod,
    String? transporterId,
  }) async {
    final uid = _uid;
    final me = await _requireRole(['farmer', 'buyer']);
    final isFarmer = me['role'] == 'farmer';
    if (isFarmer && me['isVerified'] != true) {
      throw UserStateError('Account verification is required for this action.');
    }
    final address = (deliveryAddress ?? '').trim();
    if (deliveryFeeMinor < 0 ||
        deliveryFeeMinor > 10000000 ||
        (address.isNotEmpty && address.length < 5)) {
      throw UserArgumentError('Invalid offer accept request.');
    }
    final method = !isFarmer && paymentMethod == PaymentMethod.bankDeposit
        ? PaymentMethod.bankDeposit
        : PaymentMethod.cod;
    final settings = await getPlatformSettings();
    final offerRef = _col('offers').doc(offerId);
    final orderRef = _col('orders').doc();
    final offer = await _db.runTransaction((tx) async {
      final offer = (await tx.get(offerRef)).data();
      final farmerAccepting = isFarmer &&
          offer?['farmerId'] == uid &&
          offer?['status'] == 'pending';
      final buyerAccepting = !isFarmer &&
          offer?['buyerId'] == uid &&
          offer?['status'] == 'countered';
      if (offer == null || (!farmerAccepting && !buyerAccepting)) {
        throw UserStateError(L10n.current.svcOfferNotPending);
      }
      final productId = (offer['productId'] ?? '').toString();
      final quantity = _int(offer['proposedQuantity']);
      final priceMinor = offer['proposedPriceMinor'] is num
          ? _int(offer['proposedPriceMinor'])
          : (((offer['proposedPrice'] as num?)?.toDouble() ?? 0) * 100).round();
      if (productId.isEmpty || quantity < 1 || priceMinor < 0) {
        throw UserStateError('Offer pricing is invalid.');
      }
      final farmerId = offer['farmerId'].toString();
      final productRef = _col('products').doc(productId);
      final product = (await tx.get(productRef)).data();
      final bank = method == PaymentMethod.bankDeposit
          ? await _bankSnapshotIn(tx, farmerId)
          : null;
      final available = _int(product?['quantityAvailable']);
      if (product == null ||
          product['farmerId'] != farmerId ||
          product['status'] != 'Active' ||
          available < quantity) {
        throw UserStateError(L10n.current.svcNotEnoughStock);
      }
      final requested = !isFarmer && (transporterId?.isNotEmpty ?? false)
          ? transporterId
          : null;
      tx.set(
        orderRef,
        _orderData(
          orderId: orderRef.id,
          buyerId: offer['buyerId'].toString(),
          farmerId: farmerId,
          productId: productId,
          product: product,
          quantity: quantity,
          unitPriceMinor: priceMinor,
          deliveryFeeMinor: deliveryFeeMinor,
          deliveryAddress: address.isNotEmpty
              ? address
              : (offer['deliveryAddress'] ?? 'To be confirmed with buyer')
                  .toString(),
          paymentMethod: method,
          bankSnapshot: bank,
          buyerName: isFarmer
              ? (offer['buyerName'] ?? 'Buyer').toString()
              : _nameOf(me, 'Buyer'),
          farmerName: isFarmer
              ? _nameOf(me, 'Farmer')
              : (offer['farmerName'] ?? product['farmerName'] ?? 'Farmer')
                  .toString(),
          platformFeeBps: _int(settings['platformFeeBps']),
          requestedTransporterId: requested,
          offerId: offerId,
        ),
      );
      tx.update(productRef, _stockUpdate(product, available - quantity, orderRef.id));
      tx.update(offerRef, {
        'status': 'accepted',
        'orderId': orderRef.id,
        'acceptedBy': uid,
        'updatedAt': _now,
      });
      return offer;
    });
    await _notify(
      (isFarmer ? offer['buyerId'] : offer['farmerId'])?.toString(),
      isFarmer ? 'Offer Accepted' : 'Counter-offer Accepted',
      isFarmer
          ? 'Your offer was accepted and an order was created.'
          : 'The buyer accepted your counter-offer and an order was created.',
      'offer',
      orderRef.id,
      extra: {'offerId': offerId},
    );
    return orderRef.id;
  }

  /// Farmer rejects; buyer withdraws (`cancelled`).
  Future<void> rejectOffer(String offerId) async {
    final uid = _uid;
    final me = await _requireRole(['farmer', 'buyer']);
    final isBuyer = me['role'] == 'buyer';
    final snap = await _col('offers').doc(offerId).get();
    final offer = snap.data();
    final owner = isBuyer ? (offer?['buyerId']) : (offer?['farmerId']);
    if (offer == null ||
        owner != uid ||
        !['pending', 'countered'].contains(offer['status'])) {
      throw UserStateError(L10n.current.svcOfferCannotChange);
    }
    await snap.reference.update({
      'status': isBuyer ? 'cancelled' : 'rejected',
      'updatedAt': _now,
    });
    await _notify(
      (isBuyer ? offer['farmerId'] : offer['buyerId'])?.toString(),
      isBuyer ? 'Offer Withdrawn' : 'Offer Rejected',
      isBuyer
          ? 'The buyer withdrew their offer.'
          : 'Your offer was rejected by the farmer.',
      'offer',
      offerId,
      extra: {'offerId': offerId},
    );
  }

  Future<void> counterOffer({
    required String offerId,
    required double proposedPrice,
  }) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final priceMinor = (proposedPrice * 100).round();
    if (priceMinor < 1 || proposedPrice > 100000000) {
      throw UserArgumentError(L10n.current.svcCounterPriceRequired);
    }
    final ref = _col('offers').doc(offerId);
    final offer = await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final offer = snapshot.data();
      if (offer == null ||
          offer['farmerId'] != uid ||
          offer['status'] != 'pending') {
        throw UserStateError(L10n.current.svcOfferCannotCounter);
      }
      transaction.update(ref, {
        'status': 'countered',
        'originalPriceMinor': _int(offer['proposedPriceMinor']),
        'proposedPriceMinor': priceMinor,
        'proposedPrice': priceMinor / 100,
        'counteredAt': _now,
        'updatedAt': _now,
      });
      return offer;
    });
    await _notify(
      offer['buyerId']?.toString(),
      'Farmer sent a counter-offer',
      'The farmer countered at LKR ${(priceMinor / 100).toStringAsFixed(2)} '
          'per ${offer['unit'] ?? 'unit'}.',
      'offer',
      offerId,
      extra: {'offerId': offerId},
    );
  }

  // ── Verification ──────────────────────────────────────────

  Future<String> submitVerification({
    required String documentType,
    required String storagePath,
  }) async {
    final uid = _uid;
    final type = documentType.trim();
    if (type.isEmpty ||
        type.length > 80 ||
        storagePath.length > 1024 ||
        storagePath.contains('..') ||
        !storagePath.startsWith('verification/$uid/')) {
      throw UserArgumentError('Invalid verification document.');
    }
    final ref = _col('verification_docs').doc();
    await ref.set({
      'ownerId': uid,
      'farmerId': uid,
      'documentType': type,
      'storagePath': storagePath,
      'status': 'pending',
      'createdAt': _now,
    });
    return ref.id;
  }

  /// Port of `reviewVerification` (admin).
  Future<void> reviewVerification({
    required String documentId,
    required String status,
    String? reason,
  }) async {
    final admin = await _requireAdmin();
    final uid = _uid;
    if (status != 'approved' && status != 'rejected') {
      throw UserArgumentError('Invalid verification decision.');
    }
    final note = (reason ?? '').trim();
    if (note.length > 300) throw UserArgumentError('Reason is too long.');
    final ref = _col('verification_docs').doc(documentId);
    final doc = (await ref.get()).data();
    if (doc == null) throw UserStateError(L10n.current.errorNotFound);
    if (doc['status'] != 'pending') {
      throw UserStateError('Document is not pending.');
    }
    await ref.update({
      'status': status,
      'reviewedBy': uid,
      'reviewedAt': _now,
      'rejectionReason': status == 'rejected'
          ? (note.isEmpty ? 'Document rejected by admin.' : note)
          : FieldValue.delete(),
    });
    final ownerId = (doc['ownerId'] ?? doc['farmerId'] ?? '').toString();
    if (ownerId.isNotEmpty) {
      if (status == 'approved') {
        await _col('users').doc(ownerId).update({
          'isVerified': true,
          'updatedAt': _now,
        });
        await syncTransporterProfileAsAdmin(ownerId);
      }
      final label = (doc['documentType'] ?? 'verification document').toString();
      await _notify(
        ownerId,
        status == 'approved' ? 'Verification approved' : 'Verification rejected',
        status == 'approved'
            ? 'Your $label was approved. Your account is now verified.'
            : 'Your $label was rejected${note.isEmpty ? '.' : ': $note'} '
                'Please upload a new document.',
        'verification',
        null,
        extra: {'documentId': documentId},
      );
    }
    await _audit(
      actor: admin,
      actionType:
          status == 'approved' ? 'VERIFICATION_APPROVED' : 'VERIFICATION_REJECTED',
      targetEntity: 'verification_docs',
      targetId: documentId,
      details: '${doc['documentType'] ?? 'Document'} of '
          '${ownerId.isEmpty ? 'unknown user' : ownerId}'
          '${note.isEmpty ? '' : ' — $note'}',
    );
  }

  // ── Transporter public profile ────────────────────────────

  /// Public, non-sensitive projection (see `transporterProjection`).
  static Map<String, dynamic> transporterProjection(
      String uid, Map<String, dynamic> user) {
    final rawCapacity = user['vehicleCapacity'] ?? user['capacityKg'];
    final capacity = rawCapacity is num ? rawCapacity : num.tryParse('$rawCapacity');
    return {
      'id': uid,
      'uid': uid,
      'displayName': _nameOf(user, 'Transporter'),
      'photoUrl': user['photoUrl'] is String ? user['photoUrl'] : null,
      'district': user['district'] is String ? user['district'] : '',
      'vehicleType': user['vehicleType'] is String ? user['vehicleType'] : '',
      'vehicleRegistration': user['vehicleRegistration'] is String
          ? user['vehicleRegistration']
          : '',
      'vehicleCapacity': capacity != null && capacity > 0 ? capacity : null,
      'vehicleCapacityUnit': user['vehicleCapacity'] != null &&
              user['vehicleCapacityUnit'] == 'tons'
          ? 'tons'
          : 'kg',
      'serviceDistricts': (user['serviceDistricts'] is List
              ? (user['serviceDistricts'] as List).whereType<String>()
              : const <String>[])
          .take(25)
          .toList(),
      'availabilityStatus':
          user['availabilityStatus'] == 'unavailable' ? 'unavailable' : 'available',
      'isVerified': user['isVerified'] == true,
    };
  }

  /// Transporter: (re)writes the caller's own public card from their users
  /// doc. Merge keeps an admin-set `rating`; stale Functions-era keys are
  /// removed.
  Future<void> syncMyTransporterProfile() async {
    final uid = _uid;
    final me = await _me();
    if (me['role'] != 'transporter' ||
        me['isSuspended'] == true ||
        me['isDeleted'] == true) {
      return;
    }
    await _col('transporter_profiles').doc(uid).set({
      ...transporterProjection(uid, me),
      'isSuspended': FieldValue.delete(),
      'updatedAt': _now,
    }, SetOptions(merge: true));
  }

  /// Admin: re-derives (or removes) [uid]'s public card. Best effort.
  Future<void> syncTransporterProfileAsAdmin(String uid) async {
    try {
      final user = await userDoc(uid);
      final ref = _col('transporter_profiles').doc(uid);
      if (user['role'] != 'transporter' ||
          user['isDeleted'] == true ||
          user['isSuspended'] == true) {
        await ref.delete();
        return;
      }
      await ref.set({
        ...transporterProjection(uid, user),
        'isSuspended': FieldValue.delete(),
        'updatedAt': _now,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Transporter profile sync skipped: $e');
    }
  }

  /// Port of `updateTransporterProfile`: full profile or availability only.
  Future<void> updateTransporterProfile(Map<String, dynamic> data) async {
    final uid = _uid;
    await _requireRole(['transporter']);
    final availability = data['availabilityStatus'] == 'available'
        ? 'available'
        : data['availabilityStatus'] == 'unavailable'
            ? 'unavailable'
            : '';
    const profileKeys = [
      'displayName', 'phone', 'vehicleType', 'vehicleRegistration',
      'vehicleCapacity', 'vehicleCapacityUnit', 'vehicleDescription',
      'serviceDistricts',
    ];
    final availabilityOnly = !profileKeys.any((k) => data[k] != null);
    final userRef = _col('users').doc(uid);
    if (availabilityOnly) {
      if (availability.isEmpty) {
        throw UserArgumentError('Invalid availability status.');
      }
      await userRef.update({'availabilityStatus': availability, 'updatedAt': _now});
      await syncMyTransporterProfile();
      return;
    }
    String text(String key) =>
        data[key] is String ? (data[key] as String).trim() : '';
    final displayName = text('displayName');
    final phone = text('phone');
    final vehicleType = text('vehicleType');
    final registration = text('vehicleRegistration').toUpperCase();
    final capacityRaw = data['vehicleCapacity'];
    final capacity = capacityRaw == null
        ? null
        : (capacityRaw is num ? capacityRaw : num.tryParse('$capacityRaw'));
    final unit = data['vehicleCapacityUnit'] == 'tons' ? 'tons' : 'kg';
    final description = text('vehicleDescription');
    List<String>? districts;
    if (data['serviceDistricts'] != null) {
      final raw = data['serviceDistricts'];
      if (raw is! List ||
          raw.length > 25 ||
          raw.any((d) => d is! String || d.trim().isEmpty || d.length > 80)) {
        throw UserArgumentError('Invalid service districts.');
      }
      districts = raw.map((d) => (d as String).trim()).toSet().toList();
    }
    if (displayName.length < 2 ||
        displayName.length > 120 ||
        phone.length < 7 ||
        phone.length > 30 ||
        vehicleType.isEmpty ||
        vehicleType.length > 60 ||
        registration.isEmpty ||
        registration.length > 20 ||
        availability.isEmpty ||
        (capacityRaw != null &&
            (capacity == null || capacity <= 0 || capacity > 1000000))) {
      throw UserArgumentError(
          'Name, phone, vehicle details, and availability are required.');
    }
    await userRef.update({
      'displayName': displayName,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleRegistration': registration,
      'vehicleCapacity': capacity,
      'vehicleCapacityUnit': unit,
      'vehicleDescription':
          description.length > 500 ? description.substring(0, 500) : description,
      'availabilityStatus': availability,
      if (districts != null) 'serviceDistricts': districts,
      'updatedAt': _now,
    });
    await syncMyTransporterProfile();
  }

  /// Verified, available transporters from `transporter_profiles`
  /// (optionally serving [district]).
  Future<List<Map<String, dynamic>>> listAvailableTransporters({
    String? district,
  }) async {
    _uid;
    final wanted = (district ?? '').trim().toLowerCase();
    final snap = await _col('transporter_profiles')
        .where('isVerified', isEqualTo: true)
        .limit(100)
        .get();
    final results = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['isSuspended'] == true || d['availabilityStatus'] == 'unavailable') {
        continue;
      }
      if (wanted.isNotEmpty) {
        final home = (d['district'] ?? '').toString().toLowerCase();
        final served = (d['serviceDistricts'] is List
                ? d['serviceDistricts'] as List
                : const [])
            .map((e) => e.toString().toLowerCase());
        if (home != wanted && !served.contains(wanted)) continue;
      }
      results.add({...d, 'uid': doc.id, 'id': doc.id});
    }
    return results;
  }

  // ── Admin actions ─────────────────────────────────────────

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    final admin = await _requireAdmin();
    if (userId == _uid) {
      throw UserStateError('You cannot suspend your own account.');
    }
    final ref = _col('users').doc(userId);
    final user = (await ref.get()).data();
    if (user == null) throw UserStateError(L10n.current.errorNotFound);
    if (!suspended && user['isDeleted'] == true) {
      throw UserStateError('Deleted accounts cannot be reactivated.');
    }
    await ref.update({'isSuspended': suspended, 'updatedAt': _now});
    if (user['role'] == 'transporter') {
      await syncTransporterProfileAsAdmin(userId);
    }
    await _audit(
      actor: admin,
      actionType: suspended ? 'USER_SUSPENDED' : 'USER_UNSUSPENDED',
      targetEntity: 'users',
      targetId: userId,
      details: '${suspended ? 'Suspended' : 'Reinstated'} ${_nameOf(user, userId)}',
      severity: suspended ? 'warning' : 'info',
    );
  }

  Future<void> adminSetUserRole({
    required String uid,
    required String role,
  }) async {
    final admin = await _requireAdmin();
    if (!['farmer', 'buyer', 'transporter', 'admin'].contains(role)) {
      throw UserArgumentError('Invalid user or role.');
    }
    if (uid == _uid) throw UserStateError('You cannot change your own role.');
    final ref = _col('users').doc(uid);
    final user = (await ref.get()).data();
    if (user == null || user['isDeleted'] == true) {
      throw UserStateError(L10n.current.errorNotFound);
    }
    final previous = (user['role'] ?? '').toString();
    await ref.update({'role': role, 'updatedAt': _now});
    if (previous == 'transporter' || role == 'transporter') {
      await syncTransporterProfileAsAdmin(uid);
    }
    await _audit(
      actor: admin,
      actionType: 'USER_ROLE_CHANGED',
      targetEntity: 'users',
      targetId: uid,
      details: '${_nameOf(user, uid)}: ${previous.isEmpty ? 'none' : previous} → $role',
      severity: role == 'admin' || previous == 'admin' ? 'critical' : 'warning',
    );
  }

  Future<void> adminDeleteUser(String uid) async {
    final admin = await _requireAdmin();
    if (uid == _uid) throw UserStateError('You cannot delete your own account.');
    final ref = _col('users').doc(uid);
    final user = (await ref.get()).data();
    if (user == null) throw UserStateError(L10n.current.errorNotFound);
    await ref.update({
      'isDeleted': true,
      'isSuspended': true,
      'deletedAt': _now,
      'deletedBy': _uid,
      'updatedAt': _now,
    });
    try {
      await _col('transporter_profiles').doc(uid).delete();
    } catch (e) {
      debugPrint('Transporter profile delete skipped: $e');
    }
    await _audit(
      actor: admin,
      actionType: 'USER_DELETED',
      targetEntity: 'users',
      targetId: uid,
      details: 'Soft-deleted ${_nameOf(user, uid)}',
      severity: 'critical',
    );
  }

  Future<void> releaseEscrow({required String orderId}) async {
    final admin = await _requireAdmin();
    final ref = _col('orders').doc(orderId);
    final order = (await ref.get()).data();
    if (order == null ||
        order['status'] != 'delivered' ||
        order['paymentStatus'] != 'paid' ||
        order['disputeId'] != null) {
      throw UserStateError('Order is not eligible for payout.');
    }
    await ref.update({
      'escrowStatus': 'released',
      'paymentStatus': 'released',
      'releasedAt': _now,
      'releasedBy': _uid,
      'updatedAt': _now,
    });
    await _audit(
      actor: admin,
      actionType: 'ESCROW_RELEASE',
      targetEntity: 'orders',
      targetId: orderId,
      details: 'Released ${order['orderNumber'] ?? orderId} '
          '(LKR ${(_int(order['totalMinor']) / 100).toStringAsFixed(2)})',
      severity: 'warning',
    );
  }

  static const disputeRefundPercent = {
    'refund_buyer': 100,
    'release_farmer': 0,
    'split_settlement': 50,
  };

  /// Port of `resolveDispute` (admin).
  Future<Map<String, dynamic>> resolveDispute({
    required String orderId,
    required String resolution,
    required String adminNotes,
  }) async {
    final admin = await _requireAdmin();
    final uid = _uid;
    final refundPercent = disputeRefundPercent[resolution];
    final notes = adminNotes.trim();
    if (refundPercent == null || notes.isEmpty || notes.length > 2000) {
      throw UserArgumentError('A valid decision and audit note are required.');
    }
    final orderRef = _col('orders').doc(orderId);
    final result = await _db.runTransaction((tx) async {
      final order = (await tx.get(orderRef)).data();
      if (order == null || order['paymentStatus'] != 'disputed') {
        throw UserStateError(L10n.current.svcDisputeNotOpen);
      }
      final disputeId = (order['disputeId'] ?? '').toString();
      if (disputeId.isEmpty) throw UserStateError(L10n.current.svcDisputeNotOpen);
      final disputeRef = _col('disputes').doc(disputeId);
      final dispute = (await tx.get(disputeRef)).data();
      if (dispute == null || dispute['status'] != 'open') {
        throw UserStateError(L10n.current.svcDisputeClosed);
      }
      final total = _int(order['totalMinor']);
      final refund = (total * refundPercent / 100).round();
      final settlement = total - refund;
      final paymentStatus = refundPercent == 100
          ? 'refund_pending'
          : refundPercent == 0
              ? 'settlement_pending'
              : 'split_settlement_pending';
      tx.update(orderRef, {
        'status': resolution == 'refund_buyer' ? 'cancelled' : 'completed',
        'disputeStatus': 'resolved',
        'disputeResolution': resolution,
        'disputeAdminNotes': notes,
        'disputeResolvedBy': uid,
        'disputeResolvedAt': _now,
        'refundPercent': refundPercent,
        'refundMinor': refund,
        'settlementMinor': settlement,
        'paymentStatus': paymentStatus,
        'updatedAt': _now,
      });
      tx.update(disputeRef, {
        'status': 'resolved',
        'resolution': resolution,
        'adminNotes': notes,
        'resolvedBy': uid,
        'resolvedAt': _now,
        'refundPercent': refundPercent,
        'refundMinor': refund,
        'settlementMinor': settlement,
      });
      return {
        'disputeId': disputeId,
        'refundMinor': refund,
        'settlementMinor': settlement,
        'paymentStatus': paymentStatus,
        'buyerId': (order['buyerId'] ?? '').toString(),
        'farmerId': (order['farmerId'] ?? '').toString(),
        'orderNumber': (order['orderNumber'] ?? orderNumberFor(orderId)).toString(),
      };
    });
    final label = resolution == 'refund_buyer'
        ? 'a full refund to the buyer'
        : resolution == 'release_farmer'
            ? 'payment released to the farmer'
            : 'a 50/50 split settlement';
    final body =
        'The dispute on order ${result['orderNumber']} was resolved with $label.';
    for (final party in [result['buyerId'], result['farmerId']]) {
      await _notify(party as String?, 'Dispute resolved', body, 'dispute', orderId);
    }
    await _audit(
      actor: admin,
      actionType: 'DISPUTE_RESOLVED',
      targetEntity: 'disputes',
      targetId: result['disputeId'] as String,
      details: '${result['orderNumber']}: $resolution (refund $refundPercent%). $notes',
      severity: 'critical',
    );
    return {'success': true, 'refundPercent': refundPercent, ...result};
  }

  /// Port of `broadcastAdvisory` (admin): notifications are batch-written in
  /// chunks of ≤400, then the advisory record.
  Future<int> broadcastAdvisory({
    required String title,
    required String body,
    required String audience,
  }) async {
    final admin = await _requireAdmin();
    final t = title.trim();
    final b = body.trim();
    if (t.isEmpty || t.length > 120 || b.isEmpty || b.length > 2000) {
      throw UserArgumentError('Title and message are required.');
    }
    if (!['all', 'farmer', 'buyer', 'transporter'].contains(audience)) {
      throw UserArgumentError('Invalid audience.');
    }
    Query<Map<String, dynamic>> query = _col('users');
    if (audience != 'all') query = query.where('role', isEqualTo: audience);
    final users = await query.get();
    final recipients = users.docs
        .where((d) =>
            d.data()['isSuspended'] != true && d.data()['isDeleted'] != true)
        .toList();
    final advisoryRef = _col('advisories').doc();
    for (var i = 0; i < recipients.length; i += 400) {
      final batch = _db.batch();
      for (final doc in recipients.skip(i).take(400)) {
        batch.set(_col('notifications').doc(), {
          'userId': doc.id,
          'title': t,
          'body': b,
          'type': 'general',
          'referenceId': advisoryRef.id,
          'advisoryId': advisoryRef.id,
          'read': false,
          'createdAt': _now,
        });
      }
      await batch.commit();
    }
    await advisoryRef.set({
      'title': t,
      'body': b,
      'audience': audience,
      'recipients': recipients.length,
      'createdBy': _uid,
      'createdAt': _now,
    });
    await _audit(
      actor: admin,
      actionType: 'ADVISORY_BROADCAST',
      targetEntity: 'advisories',
      targetId: advisoryRef.id,
      details: '"$t" sent to $audience (${recipients.length} recipients)',
    );
    return recipients.length;
  }

  /// Port of `updateSettlementStatus` (admin).
  Future<void> updateSettlementStatus(
    String settlementId, {
    required String status,
    String? transactionReference,
    String? holdReason,
  }) async {
    final admin = await _requireAdmin();
    if (!['settled', 'on_hold', 'processing', 'rejected'].contains(status)) {
      throw UserArgumentError('Invalid settlement update.');
    }
    final reference = (transactionReference ?? '').trim();
    if (reference.isNotEmpty && (reference.length < 4 || reference.length > 100)) {
      throw UserArgumentError(L10n.current.stateSettlementReferenceRequired);
    }
    if (status == 'settled' && reference.isEmpty) {
      throw UserArgumentError(L10n.current.stateSettlementReferenceRequired);
    }
    final hold = (holdReason ?? '').trim();
    if (hold.length > 300) throw UserArgumentError('Hold reason is too long.');
    final ref = _col('settlements').doc(settlementId);
    final settlement = await _db.runTransaction((tx) async {
      final current = (await tx.get(ref)).data();
      if (current == null) throw UserStateError(L10n.current.errorNotFound);
      if (['settled', 'rejected'].contains(current['status'])) {
        throw UserStateError('This payout is already closed.');
      }
      tx.update(ref, {
        'status': status,
        if (reference.isNotEmpty) 'transactionReference': reference,
        'holdReason': (status == 'on_hold' || status == 'rejected') && hold.isNotEmpty
            ? hold
            : FieldValue.delete(),
        if (status == 'settled') 'settledAt': _now,
        'reviewedBy': _uid,
        'updatedAt': _now,
      });
      return current;
    });
    final amount =
        'LKR ${((settlement['netAmount'] as num?) ?? 0).toDouble().toStringAsFixed(2)}';
    const titles = {
      'settled': 'Payout sent',
      'processing': 'Payout processing',
      'on_hold': 'Payout on hold',
      'rejected': 'Payout rejected',
    };
    final bodies = {
      'settled': 'Your payout of $amount was sent (ref $reference).',
      'processing': 'Your payout of $amount is being processed.',
      'on_hold': 'Your payout of $amount is on hold${hold.isEmpty ? '.' : ': $hold'}',
      'rejected':
          'Your payout of $amount was rejected${hold.isEmpty ? '.' : ': $hold'}',
    };
    await _notify(settlement['recipientId']?.toString(), titles[status]!,
        bodies[status]!, 'payment', null,
        extra: {'settlementId': settlementId});
    await _audit(
      actor: admin,
      actionType: 'SETTLEMENT_${status.toUpperCase()}',
      targetEntity: 'settlements',
      targetId: settlementId,
      details: '${settlement['orderNumber'] ?? settlementId} $amount → $status'
          '${reference.isEmpty ? '' : ' (ref $reference)'}'
          '${hold.isEmpty ? '' : ' — $hold'}',
      severity: status == 'settled' || status == 'rejected' ? 'warning' : 'info',
    );
  }

  // ── Withdrawals ───────────────────────────────────────────

  /// Available payout balance in minor units, computed like
  /// `requestWithdrawal` from the caller's readable orders / jobs /
  /// settlements.
  Future<int> availableBalanceMinor() async {
    final uid = _uid;
    final me = await _me();
    var earned = 0;
    if (me['role'] == 'farmer') {
      final orders =
          await _col('orders').where('farmerId', isEqualTo: uid).get();
      for (final doc in orders.docs) {
        final o = doc.data();
        if (!_earningPaymentStatuses.contains(o['paymentStatus']) ||
            o['status'] == 'cancelled') {
          continue;
        }
        final delivery =
            (o['transporterId'] ?? '').toString().isNotEmpty ? _int(o['deliveryFeeMinor']) : 0;
        earned += max(0, _int(o['totalMinor']) - _int(o['platformFeeMinor']) - delivery);
      }
    } else {
      final jobs = await _col('transport_jobs')
          .where('transporterId', isEqualTo: uid)
          .get();
      for (final doc in jobs.docs) {
        final j = doc.data();
        if (j['status'] != 'delivered') continue;
        earned += max(0, _int(j['deliveryFeeMinor'] ?? j['offeredFeeMinor']));
      }
    }
    final previous =
        await _col('settlements').where('recipientId', isEqualTo: uid).get();
    var withdrawn = 0;
    for (final doc in previous.docs) {
      final s = doc.data();
      if (s['status'] == 'rejected') continue;
      withdrawn += (((s['netAmount'] as num?) ?? 0) * 100).round();
    }
    return earned - withdrawn;
  }

  /// Port of `requestWithdrawal`. The balance check runs on the client (no
  /// server-side proof on Spark); rules bound the request's shape.
  Future<String> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    String payoutMethod = 'CEFT',
  }) async {
    final uid = _uid;
    final me = await _requireRole(['farmer', 'transporter']);
    final amountMinor = (amount * 100).round();
    if (!amount.isFinite ||
        amount <= 0 ||
        amount > 10000000 ||
        (amount * 100 - amountMinor).abs() > 1e-6) {
      throw UserArgumentError('Enter a valid withdrawal amount.');
    }
    final bank = bankName.trim();
    final account = accountNumber.trim();
    if (bank.isEmpty || bank.length > 100) {
      throw UserArgumentError('Invalid bank name.');
    }
    if (account.length < 4 ||
        account.length > 40 ||
        !RegExp(r'^[0-9A-Za-z -]+$').hasMatch(account)) {
      throw UserArgumentError('Invalid account number.');
    }
    if (!['CEFT', 'SLIP', 'Mobile Wallet'].contains(payoutMethod)) {
      throw UserArgumentError('Invalid payout method.');
    }
    final available = await availableBalanceMinor();
    if (amountMinor > available) {
      throw UserStateError('Amount exceeds your available balance '
          '(LKR ${(max(0, available) / 100).toStringAsFixed(2)}).');
    }
    final role = me['role'].toString();
    final ref = _col('settlements').doc();
    await ref.set({
      'orderId': '',
      'orderNumber': 'WD-${ref.id.substring(0, 8).toUpperCase()}',
      'recipientId': uid,
      'recipientName': _nameOf(me, role == 'farmer' ? 'Farmer' : 'Transporter'),
      'recipientRole': role,
      'grossAmount': amountMinor / 100,
      'platformFee': 0,
      'netAmount': amountMinor / 100,
      'bankName': bank,
      'accountNumber': account,
      'payoutMethod': payoutMethod,
      'status': 'pending',
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  // ── Account ───────────────────────────────────────────────

  Future<Map<String, dynamic>> exportUserData() async {
    final uid = _uid;
    Future<List<Map<String, dynamic>>> q(Query<Map<String, dynamic>> query) async {
      try {
        final snap = await query.limit(200).get();
        return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      } catch (e) {
        debugPrint('Export query skipped: $e');
        return const [];
      }
    }

    Object? serialize(Object? v) {
      if (v is Timestamp) return v.toDate().toIso8601String();
      if (v is List) return v.map(serialize).toList();
      if (v is Map) {
        return v.map((k, value) => MapEntry(k.toString(), serialize(value)));
      }
      return v;
    }

    final profile = await _me();
    Map<String, dynamic>? bank;
    try {
      bank = (await _col('bank_details').doc(uid).get()).data();
    } catch (_) {}
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': uid,
      'profile': {'id': uid, ...profile},
      'ordersAsBuyer': await q(_col('orders').where('buyerId', isEqualTo: uid)),
      'ordersAsFarmer': await q(_col('orders').where('farmerId', isEqualTo: uid)),
      'ordersAsTransporter':
          await q(_col('orders').where('transporterId', isEqualTo: uid)),
      'products': await q(_col('products').where('farmerId', isEqualTo: uid)),
      'verificationDocs':
          await q(_col('verification_docs').where('farmerId', isEqualTo: uid)),
      'offers': [
        ...await q(_col('offers').where('buyerId', isEqualTo: uid)),
        ...await q(_col('offers').where('farmerId', isEqualTo: uid)),
      ],
      'reviews': await q(_col('reviews').where('reviewerId', isEqualTo: uid)),
      'disputes': await q(_col('disputes').where('openedBy', isEqualTo: uid)),
      'notifications':
          await q(_col('notifications').where('userId', isEqualTo: uid)),
      'bankDetails': bank,
      'settlements':
          await q(_col('settlements').where('recipientId', isEqualTo: uid)),
    };
    return Map<String, dynamic>.from(serialize(data) as Map);
  }

  /// Anonymises the profile (rules: owner self-deletion), removes owned
  /// ancillary docs, then deletes the Auth user.
  Future<void> deleteAccount() async {
    final uid = _uid;
    await _col('users').doc(uid).set({
      'displayName': 'Deleted User',
      'name': 'Deleted User',
      'phone': '',
      'photoUrl': FieldValue.delete(),
      'email': FieldValue.delete(),
      'address': FieldValue.delete(),
      'location': FieldValue.delete(),
      'notificationPreferences': FieldValue.delete(),
      'notificationPrefs': FieldValue.delete(),
      'chatPublicKey': FieldValue.delete(),
      'isSuspended': true,
      'isDeleted': true,
      'deletedAt': _now,
      'updatedAt': _now,
    }, SetOptions(merge: true));
    Future<void> tryRun(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        debugPrint('Account cleanup step skipped: $e');
      }
    }

    await tryRun(() => _col('chat_keys').doc(uid).delete());
    await tryRun(() => _col('bank_details').doc(uid).delete());
    await tryRun(() => _col('transporter_profiles').doc(uid).delete());
    await tryRun(() async {
      final tokens = await _col('users').doc(uid).collection('device_tokens').get();
      for (final d in tokens.docs) {
        await d.reference.delete();
      }
    });
    await tryRun(() async {
      final notes = await _col('notifications')
          .where('userId', isEqualTo: uid)
          .limit(400)
          .get();
      final batch = _db.batch();
      for (final d in notes.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    });
    await FirebaseAuth.instance.currentUser?.delete();
  }

  Future<Map<String, dynamic>> createPayHereCheckout({
    required String orderId,
  }) async {
    return {'enabled': false, 'useCod': true};
  }

  // ── Chat ──────────────────────────────────────────────────

  /// Deterministic id so both participants resolve the same conversation
  /// without a (rules-unfriendly) query, and creation can't race.
  static String conversationIdFor(String orderId, String a, String b) {
    final ids = [a, b]..sort();
    return 'o_${orderId}_${ids[0]}_${ids[1]}';
  }

  /// Returns the order conversation between the caller and [peerId],
  /// creating it on first use. Rules require both to be order participants.
  Future<String> ensureConversation({
    required String orderId,
    required String peerId,
  }) async {
    final uid = _uid;
    if (peerId.isEmpty || peerId == uid) {
      throw UserStateError(L10n.current.svcNoChatPeer);
    }
    final ref = _col('conversations').doc(conversationIdFor(orderId, uid, peerId));
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'orderId': orderId,
        'orderNumber': orderNumberFor(orderId),
        'participantIds': [uid, peerId]..sort(),
        'lastMessage': '',
        'lastMessageAt': _now,
        'unreadCounts': {uid: 0, peerId: 0},
        'createdAt': _now,
      });
    }
    return ref.id;
  }

  /// Port of `sendMessage`: writes the message and the conversation preview
  /// (creating the conversation on the first message) in one batch and
  /// bumps the recipient's unread counter.
  Future<String> sendChatMessage({
    required String conversationId,
    required String orderId,
    required String recipientId,
    String? ciphertext,
    String? attachmentUrl,
    String? attachmentPath,
    String? attachmentKind,
  }) async {
    final uid = _uid;
    final hasText = ciphertext != null && ciphertext.isNotEmpty;
    final hasImage = attachmentUrl != null &&
        attachmentUrl.isNotEmpty &&
        attachmentPath != null;
    if (recipientId.isEmpty || recipientId == uid) {
      throw UserStateError(L10n.current.svcNoChatPeer);
    }
    if (!hasText && !hasImage) {
      throw UserArgumentError('Message is empty.');
    }
    if (hasText && (ciphertext.length < 16 || ciphertext.length > 20000)) {
      throw UserArgumentError('Invalid message.');
    }
    final kind = attachmentKind == 'payment_proof' ? 'payment_proof' : 'photo';
    final participants = [uid, recipientId]..sort();
    final convoId = conversationIdFor(orderId, uid, recipientId);
    final convoRef = _col('conversations').doc(convoId);
    final preview = hasImage
        ? (kind == 'payment_proof' ? 'Payment receipt' : 'Photo')
        : (ciphertext!.length > 140 ? ciphertext.substring(0, 140) : ciphertext);
    final msgRef = _col('messages').doc();

    Future<void> write(bool exists) async {
      final batch = _db.batch();
      if (exists) {
        batch.update(convoRef, {
          'lastMessage': preview,
          'lastMessageAt': _now,
          'lastSenderId': uid,
          'unreadCounts.$recipientId': FieldValue.increment(1),
        });
      } else {
        batch.set(convoRef, {
          'orderId': orderId,
          'orderNumber': orderNumberFor(orderId),
          'participantIds': participants,
          'lastMessage': preview,
          'lastMessageAt': _now,
          'lastSenderId': uid,
          'unreadCounts': {recipientId: 1, uid: 0},
          'createdAt': _now,
        });
      }
      batch.set(msgRef, {
        'orderId': orderId,
        'conversationId': convoId,
        'participantIds': participants,
        'senderId': uid,
        'receiverId': recipientId,
        'recipientId': recipientId,
        'type': hasImage ? 'image' : 'text',
        if (hasText) 'ciphertext': ciphertext,
        if (hasImage) 'attachmentUrl': attachmentUrl,
        if (hasImage) 'attachmentPath': attachmentPath,
        if (hasImage) 'attachmentKind': kind,
        'createdAt': _now,
      });
      await batch.commit();
    }

    final exists = (await convoRef.get()).exists;
    try {
      await write(exists);
    } on FirebaseException catch (e) {
      // The peer created the conversation at the same moment: retry as an
      // update.
      if (exists || e.code != 'permission-denied') rethrow;
      await write(true);
    }
    await _notify(
      recipientId,
      hasImage && kind == 'payment_proof' ? 'Payment receipt received' : 'New message',
      hasImage
          ? 'You received a photo in your order chat.'
          : 'You have a new encrypted order message.',
      'message',
      orderId,
      extra: {'conversationId': convoId, 'senderId': uid},
    );
    if (conversationId != convoId) {
      debugPrint('sendChatMessage: conversation id normalised to $convoId');
    }
    return msgRef.id;
  }

  /// Legacy entry point (offline outbox): text to the order conversation.
  Future<String> sendEncryptedMessage({
    required String orderId,
    required String recipientId,
    required String ciphertext,
  }) {
    return sendChatMessage(
      conversationId: conversationIdFor(orderId, _uid, recipientId),
      orderId: orderId,
      recipientId: recipientId,
      ciphertext: ciphertext,
    );
  }

  // ── Barcodes / reviews / disputes ─────────────────────────

  Future<Map<String, String>> issueOrderBarcode(String orderId) async {
    final uid = _uid;
    await _requireRole(['farmer']);
    final order = (await _col('orders').doc(orderId).get()).data();
    if (order == null ||
        order['farmerId'] != uid ||
        ['cancelled', 'rejected'].contains(order['status'])) {
      throw UserStateError(L10n.current.svcOrderNotFound);
    }
    final barcodeId = _col('barcodes').doc().id;
    final signature = _randomToken();
    await _col('barcodes').doc(barcodeId).set({
      'orderId': orderId,
      'farmerId': uid,
      'signature': signature,
      'status': 'issued',
      'scanCount': 0,
      'payload': '{"barcodeId":"$barcodeId","orderId":"$orderId"}',
      'createdAt': _now,
    });
    return {'barcodeId': barcodeId, 'signature': signature};
  }

  Future<Map<String, dynamic>> verifyProductBarcode({
    required String barcodeId,
    required String signature,
  }) async {
    final uid = _uid;
    final snap = await _col('barcodes').doc(barcodeId).get();
    final barcode = snap.data();
    if (barcode == null ||
        barcode['signature'] != signature ||
        barcode['status'] != 'issued') {
      throw UserStateError(L10n.current.barcodeInvalid);
    }
    final order =
        (await _col('orders').doc(barcode['orderId'] as String).get()).data();
    if (order == null || order['buyerId'] != uid) {
      throw UserStateError(L10n.current.svcBarcodeWrongBuyer);
    }
    await snap.reference.update({
      'status': 'verified',
      'verifiedBy': uid,
      'verifiedAt': _now,
      'scanCount': FieldValue.increment(1),
    });
    return {'valid': true, 'orderId': barcode['orderId']};
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    final uid = _uid;
    final me = await _requireRole(['buyer']);
    final text = comment.trim();
    if (rating < 1 || rating > 5 || text.length > 2000) {
      throw UserArgumentError('Invalid review.');
    }
    final order = (await _col('orders').doc(orderId).get()).data();
    if (order == null || order['buyerId'] != uid) {
      throw UserStateError(L10n.current.svcOrderNotFound);
    }
    if (order['status'] != 'delivered') {
      throw UserStateError('Only delivered orders can be reviewed.');
    }
    await _col('reviews').doc('${orderId}_$uid').set({
      'orderId': orderId,
      'orderNumber': (order['orderNumber'] ?? orderNumberFor(orderId)).toString(),
      'reviewerId': uid,
      'reviewerName': _nameOf(me, (order['buyerName'] ?? 'Buyer').toString()),
      'subjectId': order['farmerId'],
      'subjectName': (order['farmerName'] ?? 'Farmer').toString(),
      'productId': order['productId'],
      'productName': (order['productName'] ?? '').toString(),
      'rating': rating,
      'comment': text,
      'moderationStatus': 'pending',
      'createdAt': _now,
    });
  }

  Future<String> openDispute({
    required String orderId,
    required String reason,
    List<String> evidenceUrls = const [],
  }) async {
    final uid = _uid;
    final text = reason.trim();
    if (text.isEmpty || text.length > 2000) {
      throw UserArgumentError('A dispute reason is required.');
    }
    final orderRef = _col('orders').doc(orderId);
    final order = (await orderRef.get()).data();
    if (order == null ||
        ![order['buyerId'], order['farmerId'], order['transporterId']]
            .contains(uid)) {
      throw UserStateError(L10n.current.errorNoPermission);
    }
    final disputeRef = _col('disputes').doc();
    final batch = _db.batch()
      ..set(disputeRef, {
        'orderId': orderId,
        'openedBy': uid,
        'reason': text,
        'status': 'open',
        'evidenceImages':
            evidenceUrls.where((u) => u.length <= 2000).take(5).toList(),
        'createdAt': _now,
      });
    if (order['disputeId'] == null) {
      batch.update(orderRef, {
        'paymentStatus': 'disputed',
        'disputeId': disputeRef.id,
        'updatedAt': _now,
      });
    }
    await batch.commit();
    return disputeRef.id;
  }

  /// The delivering transporter clears the product's harvest-video link.
  /// (The Storage object itself can only be deleted by the owner farmer.)
  Future<void> _cleanupVideoForOrder(String orderId, String? productId) async {
    try {
      var id = productId ?? '';
      if (id.isEmpty) {
        final order = (await _col('orders').doc(orderId).get()).data();
        id = (order?['productId'] ?? '').toString();
      }
      if (id.isEmpty) return;
      await _col('products').doc(id).update({
        'videoPath': FieldValue.delete(),
        'videoUrl': FieldValue.delete(),
        'harvestStatus': 'delivered',
        'deliveredOrderId': orderId,
        'updatedAt': _now,
      });
    } catch (e) {
      debugPrint('Harvest video cleanup skipped: $e');
    }
  }

  // ── Farm workspace ────────────────────────────────────────

  Future<String> createCropPlan({
    required String cropName,
    required double area,
    required String areaUnit,
    required DateTime plantedAt,
    required DateTime expectedHarvestAt,
    double expectedYield = 0,
    String yieldUnit = 'kg',
    String notes = '',
  }) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final name = cropName.trim();
    if (name.isEmpty ||
        name.length > 100 ||
        !area.isFinite ||
        area <= 0 ||
        area > 100000 ||
        !['acres', 'hectares', 'perches'].contains(areaUnit) ||
        !expectedHarvestAt.isAfter(plantedAt)) {
      throw UserArgumentError(
          'Enter a crop, valid farm area, planting date, and later harvest date.');
    }
    final text = notes.trim();
    final ref = _col('crop_plans').doc();
    await ref.set({
      'farmerId': uid,
      'cropName': name,
      'area': area,
      'areaUnit': areaUnit,
      'plantedAt': Timestamp.fromDate(plantedAt),
      'expectedHarvestAt': Timestamp.fromDate(expectedHarvestAt),
      'expectedYield': max(0.0, expectedYield),
      'yieldUnit': yieldUnit.length > 20 ? yieldUnit.substring(0, 20) : yieldUnit,
      'status': 'planned',
      'notes': text.length > 1000 ? text.substring(0, 1000) : text,
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  Future<void> updateCropPlan(String cropId, Map<String, dynamic> data) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final ref = _col('crop_plans').doc(cropId);
    final crop = (await ref.get()).data();
    if (crop == null || crop['farmerId'] != uid) {
      throw UserStateError(L10n.current.errorNotFound);
    }
    final updates = <String, dynamic>{'updatedAt': _now};
    final status = data['status'];
    if (status is String) {
      if (!['planned', 'planted', 'growing', 'harvested', 'cancelled']
          .contains(status)) {
        throw UserArgumentError('Invalid crop status.');
      }
      updates['status'] = status;
      if (status == 'harvested') updates['harvestedAt'] = _now;
    }
    if (data['notes'] is String) {
      final notes = (data['notes'] as String).trim();
      updates['notes'] = notes.length > 1000 ? notes.substring(0, 1000) : notes;
    }
    final yieldValue = data['expectedYield'];
    if (yieldValue is num && yieldValue.isFinite && yieldValue >= 0) {
      updates['expectedYield'] = yieldValue;
    }
    await ref.update(updates);
  }

  Future<String> createFarmTask({
    required String title,
    required DateTime dueAt,
    String priority = 'normal',
    String description = '',
    String cropId = '',
    String cropName = '',
  }) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final t = title.trim();
    if (t.isEmpty) {
      throw UserArgumentError('Task title and due date are required.');
    }
    final desc = description.trim();
    final ref = _col('farm_tasks').doc();
    await ref.set({
      'farmerId': uid,
      'title': t.length > 120 ? t.substring(0, 120) : t,
      'description': desc.length > 1000 ? desc.substring(0, 1000) : desc,
      'cropId': cropId,
      'cropName': cropName.length > 100 ? cropName.substring(0, 100) : cropName,
      'dueAt': Timestamp.fromDate(dueAt),
      'priority': ['low', 'normal', 'high'].contains(priority) ? priority : 'normal',
      'status': 'pending',
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  Future<void> updateFarmTask(String taskId, Map<String, dynamic> data) async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final ref = _col('farm_tasks').doc(taskId);
    final task = (await ref.get()).data();
    if (task == null || task['farmerId'] != uid) {
      throw UserStateError(L10n.current.errorNotFound);
    }
    final updates = <String, dynamic>{'updatedAt': _now};
    final status = data['status'];
    if (status is String) {
      if (!['pending', 'inProgress', 'completed', 'cancelled'].contains(status)) {
        throw UserArgumentError('Invalid task status.');
      }
      updates['status'] = status;
      if (status == 'completed') updates['completedAt'] = _now;
    }
    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) {
      final t = title.trim();
      updates['title'] = t.length > 120 ? t.substring(0, 120) : t;
    }
    final due = data['dueAt'];
    if (due != null) {
      final parsed = due is DateTime ? due : DateTime.tryParse(due.toString());
      if (parsed == null) throw UserArgumentError('Invalid due date.');
      updates['dueAt'] = Timestamp.fromDate(parsed);
      updates['reminderDate'] = FieldValue.delete();
    }
    await ref.update(updates);
  }

  /// Port of `checkFarmTaskReminders`, computed on the client: one
  /// self-notification per open task due within 24h (at most once a day).
  Future<int> checkFarmTaskReminders() async {
    final uid = _uid;
    await _requireVerifiedRole(['farmer']);
    final now = DateTime.now();
    final today = now.toUtc().toIso8601String().substring(0, 10);
    final tomorrow = now.add(const Duration(hours: 24));
    final tasks = await _col('farm_tasks')
        .where('farmerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'inProgress'])
        .limit(100)
        .get();
    var reminders = 0;
    for (final doc in tasks.docs) {
      final task = doc.data();
      final dueAt = task['dueAt'] is Timestamp
          ? (task['dueAt'] as Timestamp).toDate()
          : null;
      if (dueAt == null || dueAt.isAfter(tomorrow) || task['reminderDate'] == today) {
        continue;
      }
      final overdue = dueAt.isBefore(now);
      final batch = _db.batch()
        ..update(doc.reference, {'reminderDate': today})
        ..set(_col('notifications').doc(), {
          'userId': uid,
          'title': overdue ? 'Farm task overdue' : 'Farm task due soon',
          'body': '${task['title']} is due ${overdue ? 'now' : 'within 24 hours'}.',
          'type': 'farm_task',
          'referenceId': doc.id,
          'read': false,
          'createdAt': _now,
        });
      try {
        await batch.commit();
        reminders++;
      } catch (e) {
        debugPrint('Farm task reminder skipped: $e');
      }
    }
    return reminders;
  }

  // ── Community market ──────────────────────────────────────

  Future<String> createProduceRequest({
    required String produceName,
    required String category,
    required int quantity,
    required String unit,
    required String district,
    required String deliveryAddress,
    required DateTime deliveryDate,
    int maxUnitPriceMinor = 0,
    String notes = '',
  }) async {
    final uid = _uid;
    final buyer = await _requireRole(['buyer']);
    final name = produceName.trim();
    final u = unit.trim().toLowerCase();
    final address = deliveryAddress.trim();
    if (name.isEmpty ||
        name.length > 100 ||
        quantity < 1 ||
        !_marketUnits.contains(u) ||
        address.length < 5 ||
        address.length > 500) {
      throw UserArgumentError(
          'Produce, whole quantity/unit, delivery address, and required date are needed.');
    }
    String cut(String s, int n) => s.length > n ? s.substring(0, n) : s;
    final ref = _col('produce_requests').doc();
    await ref.set({
      'buyerId': uid,
      'buyerName': _nameOf(buyer, 'Buyer'),
      'produceName': name,
      'category': cut(category.isEmpty ? 'Other' : category, 50),
      'quantity': quantity,
      'unit': u,
      'maxUnitPriceMinor': max(0, maxUnitPriceMinor),
      'district': cut(district.trim(), 80),
      'deliveryAddress': address,
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'notes': cut(notes.trim(), 1000),
      'status': 'open',
      'quoteCount': 0,
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  Future<void> cancelProduceRequest(String requestId) async {
    final uid = _uid;
    await _requireRole(['buyer']);
    final ref = _col('produce_requests').doc(requestId);
    final req = (await ref.get()).data();
    if (req == null || req['buyerId'] != uid || req['status'] != 'open') {
      throw UserStateError('Only your open requests can be cancelled.');
    }
    await ref.update({'status': 'cancelled', 'updatedAt': _now});
  }

  Future<void> submitProduceRequestQuote({
    required String requestId,
    required String productId,
    required int unitPriceMinor,
    required int deliveryFeeMinor,
    String message = '',
  }) async {
    final uid = _uid;
    final farmer = await _requireVerifiedRole(['farmer']);
    if (unitPriceMinor < 1 ||
        unitPriceMinor > 100000000 ||
        deliveryFeeMinor < 0 ||
        deliveryFeeMinor > 10000000) {
      throw UserArgumentError('Invalid quote.');
    }
    final requestRef = _col('produce_requests').doc(requestId);
    final quoteRef = requestRef.collection('quotes').doc(uid);
    final productRef = _col('products').doc(productId);
    final text = message.trim();
    final request = await _db.runTransaction((tx) async {
      final request = (await tx.get(requestRef)).data();
      final existing = await tx.get(quoteRef);
      final product = (await tx.get(productRef)).data();
      if (request == null ||
          request['status'] != 'open' ||
          product == null ||
          product['farmerId'] != uid ||
          product['status'] != 'Active' ||
          _int(product['quantityAvailable']) < _int(request['quantity']) ||
          product['unit'].toString().toLowerCase() !=
              request['unit'].toString().toLowerCase()) {
        throw UserStateError(
            'Your active listing must match the requested unit and have enough stock.');
      }
      if (existing.exists && existing.data()?['status'] != 'pending') {
        throw UserStateError('This quote can no longer be changed.');
      }
      tx.set(quoteRef, {
        'farmerId': uid,
        'farmerName': _nameOf(farmer, 'Farmer'),
        'productId': productId,
        'productName': (product['name'] ?? request['produceName']).toString(),
        'unitPriceMinor': unitPriceMinor,
        'deliveryFeeMinor': deliveryFeeMinor,
        'message': text.length > 500 ? text.substring(0, 500) : text,
        'status': 'pending',
        'createdAt': existing.data()?['createdAt'] ?? _now,
        'updatedAt': _now,
      });
      if (!existing.exists) {
        tx.update(requestRef, {
          'quoteCount': FieldValue.increment(1),
          'updatedAt': _now,
        });
      }
      return request;
    });
    await _notify(
      request['buyerId']?.toString(),
      'New produce quote',
      '${_nameOf(farmer, 'A farmer')} sent a quote for ${request['produceName']}.',
      'produce_request',
      requestId,
    );
  }

  Future<String> acceptProduceRequestQuote(
      String requestId, String farmerId) async {
    final uid = _uid;
    await _requireRole(['buyer']);
    final settings = await getPlatformSettings();
    final requestRef = _col('produce_requests').doc(requestId);
    final quoteRef = requestRef.collection('quotes').doc(farmerId);
    final orderRef = _col('orders').doc();
    await _db.runTransaction((tx) async {
      final request = (await tx.get(requestRef)).data();
      final quote = (await tx.get(quoteRef)).data();
      if (request == null ||
          request['buyerId'] != uid ||
          request['status'] != 'open' ||
          quote == null ||
          quote['status'] != 'pending') {
        throw UserStateError('Request or quote is no longer available.');
      }
      final productRef = _col('products').doc(quote['productId'].toString());
      final product = (await tx.get(productRef)).data();
      final available = _int(product?['quantityAvailable']);
      final quantity = _int(request['quantity']);
      final price = _int(quote['unitPriceMinor']);
      if (product == null ||
          product['farmerId'] != farmerId ||
          product['status'] != 'Active' ||
          available < quantity ||
          price < 1) {
        throw UserStateError('Farmer stock or quote is no longer valid.');
      }
      tx.set(
        orderRef,
        _orderData(
          orderId: orderRef.id,
          buyerId: uid,
          farmerId: farmerId,
          productId: quote['productId'].toString(),
          product: product,
          quantity: quantity,
          unitPriceMinor: price,
          deliveryFeeMinor: _int(quote['deliveryFeeMinor']),
          deliveryAddress: request['deliveryAddress'].toString(),
          paymentMethod: PaymentMethod.cod,
          buyerName: (request['buyerName'] ?? 'Buyer').toString(),
          farmerName: (quote['farmerName'] ?? 'Farmer').toString(),
          platformFeeBps: _int(settings['platformFeeBps']),
          sourceRequestId: requestId,
        ),
      );
      tx.update(productRef, _stockUpdate(product, available - quantity, orderRef.id));
      tx.update(quoteRef, {
        'status': 'accepted',
        'orderId': orderRef.id,
        'updatedAt': _now,
      });
      tx.update(requestRef, {
        'status': 'matched',
        'acceptedFarmerId': farmerId,
        'orderId': orderRef.id,
        'updatedAt': _now,
      });
    });
    await _notify(farmerId, 'Quote accepted',
        'The buyer accepted your quote and an order was created.',
        'produce_request', orderRef.id);
    return orderRef.id;
  }

  Future<String> submitMarketPriceReport({
    required String cropName,
    required String category,
    required String marketName,
    required String district,
    required String unit,
    required int priceMinor,
  }) async {
    final uid = _uid;
    final me = await _requireRole(['buyer', 'farmer']);
    final crop = cropName.trim();
    final dist = district.trim();
    final market = marketName.trim();
    final u = unit.trim().toLowerCase();
    if (crop.isEmpty ||
        crop.length > 100 ||
        dist.isEmpty ||
        dist.length > 80 ||
        market.isEmpty ||
        market.length > 100 ||
        !_marketUnits.contains(u) ||
        priceMinor < 1 ||
        priceMinor > 100000000) {
      throw UserArgumentError(
          'Enter valid produce, market, location, unit, and price.');
    }
    final ref = _col('market_price_reports').doc();
    await ref.set({
      'reporterId': uid,
      'reporterRole': me['role'],
      'cropName': crop,
      'category': category.length > 50 ? category.substring(0, 50) : category,
      'district': dist,
      'marketName': market,
      'unit': u,
      'priceMinor': priceMinor,
      'status': 'pending',
      'reportedAt': _now,
      'createdAt': _now,
    });
    return ref.id;
  }

  /// Port of `reviewMarketPriceReport` (admin): approval folds the price into
  /// the `market_prices` benchmark.
  Future<void> reviewMarketPriceReport(String reportId, String decision) async {
    final admin = await _requireAdmin();
    final uid = _uid;
    if (!['approve', 'reject'].contains(decision)) {
      throw UserArgumentError('Invalid price report review.');
    }
    final reportRef = _col('market_price_reports').doc(reportId);
    final report = await _db.runTransaction((tx) async {
      final report = (await tx.get(reportRef)).data();
      if (report == null || report['status'] != 'pending') {
        throw UserStateError('Price report already reviewed.');
      }
      DocumentReference<Map<String, dynamic>>? priceRef;
      Map<String, dynamic>? benchmark;
      if (decision == 'approve') {
        String slug(Object? v) => v
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        priceRef = _col('market_prices')
            .doc('${slug(report['cropName'])}-${slug(report['district'])}-${report['unit']}');
        final existing = (await tx.get(priceRef)).data();
        final oldCount = _int(existing?['reportCount']);
        final oldAvg = (existing?['averagePricePerKg'] as num?)?.toDouble() ?? 0;
        final price = _int(report['priceMinor']) / 100;
        final count = oldCount + 1;
        benchmark = {
          'cropName': report['cropName'],
          'category': report['category'],
          'district': report['district'],
          'marketName': report['marketName'],
          'unit': report['unit'],
          'minPricePerKg': existing == null
              ? price
              : min((existing['minPricePerKg'] as num?)?.toDouble() ?? price, price),
          'maxPricePerKg': existing == null
              ? price
              : max((existing['maxPricePerKg'] as num?)?.toDouble() ?? price, price),
          'averagePricePerKg': (oldAvg * oldCount + price) / count,
          'trend': existing == null
              ? 'stable'
              : (price > oldAvg ? 'up' : (price < oldAvg ? 'down' : 'stable')),
          'reportCount': count,
          'updatedAt': _now,
        };
      }
      tx.update(reportRef, {
        'status': decision == 'approve' ? 'approved' : 'rejected',
        'reviewedBy': uid,
        'reviewedAt': _now,
      });
      if (priceRef != null && benchmark != null) {
        tx.set(priceRef, benchmark, SetOptions(merge: true));
      }
      return report;
    });
    await _notify(
      report['reporterId']?.toString(),
      'Market price report ${decision == 'approve' ? 'approved' : 'reviewed'}',
      decision == 'approve'
          ? 'Your market price report is now included in the benchmark.'
          : 'Your market price report was not approved.',
      'market_price',
      reportId,
    );
    await _audit(
      actor: admin,
      actionType:
          decision == 'approve' ? 'MARKET_PRICE_APPROVED' : 'MARKET_PRICE_REJECTED',
      targetEntity: 'market_price_reports',
      targetId: reportId,
      details: '${report['cropName'] ?? 'Report'} (${report['district'] ?? '-'})',
    );
  }

  /// Random 24-hex-char barcode tag. Spark has no server secret to sign with;
  /// the tag is only readable by the order's parties (rules).
  String _randomToken() {
    final rnd = Random.secure();
    return List.generate(24, (_) => rnd.nextInt(16).toRadixString(16)).join();
  }
}

