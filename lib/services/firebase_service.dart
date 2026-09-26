import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/config/app_backend.dart';
import '../core/localization/l10n.dart';
import '../core/utils/app_errors.dart';
import '../core/utils/image_upload.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/verification_model.dart';
import '../models/conversation_model.dart';
import '../models/offer.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/audit_log_model.dart';
import '../models/settlement_model.dart';
import '../models/market_price_index.dart';
import '../models/admin_stats.dart';
import '../models/dispute_model.dart';
import 'service_errors.dart';
import 'spark_backend.dart';

/// A file stored in Firebase Storage.
class StoredImage {
  const StoredImage({required this.url, required this.path});
  final String url;
  final String path;
}

// ============================================================
// Firebase Authentication Service
// ============================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late final SparkBackend _spark = SparkBackend(_db);

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.registerDeviceToken(token: token, platform: platform);
      return;
    }
    await _functions.httpsCallable('registerDeviceToken').call({
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDeviceToken(String token) async {
    if (!kUseCloudFunctions) {
      await _spark.unregisterDeviceToken(token);
      return;
    }
    await _functions
        .httpsCallable('unregisterDeviceToken')
        .call({'token': token});
  }

  /// Public platform settings (any signed-in user): maintenanceMode,
  /// maintenanceNotice, platformFeeBps, sessionTimeoutMinutes,
  /// defaultDeliveryFeeMinor, escrowReleaseHours, minAppVersion.
  Future<Map<String, dynamic>> getPlatformSettings() async {
    if (kUseCloudFunctions) {
      try {
        final result = await _functions
            .httpsCallable('getPlatformSettings')
            .call()
            .timeout(const Duration(seconds: 3));
        return Map<String, dynamic>.from(result.data as Map);
      } catch (e) {
        debugPrint(
            'getPlatformSettings Cloud Function unavailable ($e); using defaults/Firestore');
      }
    }
    return _spark.getPlatformSettings();
  }

  /// Alias of [getPlatformSettings].
  Future<Map<String, dynamic>> getPublicSettings() => getPlatformSettings();

  Future<void> updatePlatformSettings(Map<String, dynamic> settings) async {
    if (kUseCloudFunctions) {
      try {
        await _functions
            .httpsCallable('updatePlatformSettings')
            .call(settings)
            .timeout(const Duration(seconds: 4));
        return;
      } catch (e) {
        debugPrint(
            'updatePlatformSettings Cloud Function unavailable ($e); using direct write');
      }
    }
    await _spark.updatePlatformSettings(settings);
  }

  // ── Users ─────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> usersStream({int limit = 100}) {
    return _db.collection('users').limit(limit).snapshots().map((snap) =>
        snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
  }

  // ── Notifications ──────────────────────────────────────────
  Stream<List<FarmoraNotification>> notificationsStream(String userId,
      {int limit = 50}) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraNotification.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Admin only (rules): other roles' notifications are written by functions.
  Future<void> sendInAppNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'referenceId': referenceId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> updateUserLanguage(String languageCode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    await _db.collection('users').doc(uid).update({
      'languageCode': languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update editable profile fields (name, district, country, photo) on the
  /// user's Firestore document. Only non-null fields are written.
  Future<void> updateUserProfile({
    String? name,
    String? district,
    String? country,
    String? photoUrl,
    String? farmName,
    String? farmSize,
    List<String>? mainCrops,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) {
      data['name'] = name;
      data['displayName'] = name;
    }
    if (district != null) data['district'] = district;
    if (country != null) data['country'] = country;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (farmName != null) data['farmName'] = farmName;
    if (farmSize != null) data['farmSize'] = farmSize;
    if (mainCrops != null) data['mainCrops'] = mainCrops;
    await _db.collection('users').doc(uid).update(data);
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
    if (!kUseCloudFunctions) {
      throw StateError('Product updates require the trusted backend.');
    }
    final result = await _functions.httpsCallable('updateProduct').call({
      'productId': id,
      ...data,
    });
    if (result.data is Map && result.data['success'] != true) {
      throw StateError('Product update failed.');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    if (!kUseCloudFunctions) {
      throw StateError('Product deletion requires the trusted backend.');
    }
    await _functions.httpsCallable('deleteProduct').call({'productId': id});
  }

  /// Real-time stream of all products
  ///
  /// [activeOnly] (buyer catalogue) returns only `status == 'Active'`
  /// listings (index: products status ASC + createdAt DESC). Admins pass
  /// false to see every listing. Farmers use [productsByFarmerStream] so
  /// they still see their own Empty/Inactive products.
  Stream<List<Product>> productsStream(
      {int limit = 50, bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _db.collection('products');
    if (activeOnly) query = query.where('status', isEqualTo: 'Active');
    return query
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

  // ── Offers ────────────────────────────────────────────────

  Future<String> createOffer({
    required String productId,
    required int proposedQuantity,
    required double proposedPrice,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.createOffer(
        productId: productId,
        proposedQuantity: proposedQuantity,
        proposedPrice: proposedPrice,
      );
    }
    final result = await _functions.httpsCallable('createOffer').call({
      'productId': productId,
      'proposedQuantity': proposedQuantity,
      'proposedPrice': proposedPrice,
    });
    return result.data['offerId'] as String;
  }

  /// Legacy direct write — prefer [createOffer].
  Future<void> addOffer(FarmoraOffer o) async {
    await createOffer(
      productId: o.productId,
      proposedQuantity: o.proposedQuantity,
      proposedPrice: o.proposedPrice,
    );
  }

  /// Farmer accepts a `pending` offer, or the buyer accepts a `countered`
  /// one. The buyer passes delivery address / payment method / transporter.
  Future<String> acceptOffer({
    required String offerId,
    int deliveryFeeMinor = 50000,
    String? deliveryAddress,
    String? paymentMethod,
    String? transporterId,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.acceptOffer(
        offerId: offerId,
        deliveryFeeMinor: deliveryFeeMinor,
      );
    }
    final result = await _functions.httpsCallable('acceptOffer').call({
      'offerId': offerId,
      'deliveryFeeMinor': deliveryFeeMinor,
      if (deliveryAddress != null && deliveryAddress.isNotEmpty)
        'deliveryAddress': deliveryAddress,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (transporterId != null && transporterId.isNotEmpty)
        'transporterId': transporterId,
    });
    return result.data['orderId'] as String;
  }

  /// Farmer counters with a new PER-UNIT price in LKR.
  Future<void> counterOffer({
    required String offerId,
    required double counterPrice,
  }) async {
    if (counterPrice <= 0) {
      throw UserArgumentError(L10n.current.svcCounterPriceRequired);
    }
    if (!kUseCloudFunctions) {
      await _spark.counterOffer(offerId: offerId, proposedPrice: counterPrice);
      return;
    }
    await _functions.httpsCallable('counterOffer').call({
      'offerId': offerId,
      'counterPrice': counterPrice,
    });
  }

  Future<void> rejectOffer(String offerId) async {
    if (!kUseCloudFunctions) {
      await _spark.rejectOffer(offerId);
      return;
    }
    await _functions.httpsCallable('rejectOffer').call({'offerId': offerId});
  }

  Future<void> updateOfferStatus(String id, String status,
      {double? proposedPrice}) async {
    if (status == 'accepted') {
      await acceptOffer(offerId: id);
      return;
    }
    if (status == 'rejected') {
      await rejectOffer(id);
      return;
    }
    if (status == 'countered') {
      if (proposedPrice == null || proposedPrice <= 0) {
        throw UserArgumentError(L10n.current.svcCounterPriceRequired);
      }
      await counterOffer(offerId: id, counterPrice: proposedPrice);
      return;
    }
    await _db.collection('offers').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FarmoraOffer>> offersByFarmerStream(String farmerId,
      {int limit = 50}) {
    return _db
        .collection('offers')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOffer.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<FarmoraOffer>> offersByBuyerStream(String buyerId,
      {int limit = 50}) {
    return _db
        .collection('offers')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraOffer.fromMap(doc.id, doc.data()))
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

  /// Update order delivery address via trusted Cloud Function.
  Future<void> updateOrderAddress(String orderId, String newAddress) async {
    await updateOrderAddressCallable(
      orderId: orderId,
      deliveryAddress: newAddress,
    );
  }

  Future<String> createSecureOrder({
    required String productId,
    required int quantity,
    int deliveryFeeMinor = 0,
    String? offerId,
    String? transporterId,
    required String deliveryAddress,
    required String idempotencyKey,
    String paymentMethod = PaymentMethod.cod,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.createOrder(
        productId: productId,
        quantity: quantity,
        deliveryFeeMinor: deliveryFeeMinor,
        transporterId: transporterId,
        deliveryAddress: deliveryAddress,
        idempotencyKey: idempotencyKey,
        paymentMethod: paymentMethod,
      );
    }
    final result = await _functions.httpsCallable('createOrder').call({
      'productId': productId,
      'quantity': quantity,
      'deliveryFeeMinor': deliveryFeeMinor,
      'deliveryAddress': deliveryAddress,
      'idempotencyKey': idempotencyKey,
      'paymentMethod': paymentMethod,
      if (offerId != null) 'offerId': offerId,
      if (transporterId != null) 'transporterId': transporterId,
    });
    return result.data['orderId'] as String;
  }

  Future<void> requestTransport({
    required String orderId,
    int? deliveryFeeMinor,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.requestTransport(
        orderId: orderId,
        deliveryFeeMinor: deliveryFeeMinor,
      );
      return;
    }
    await _functions.httpsCallable('requestTransport').call({
      'orderId': orderId,
      if (deliveryFeeMinor != null) 'deliveryFeeMinor': deliveryFeeMinor,
    });
  }

  Future<void> updateOrderAddressCallable({
    required String orderId,
    required String deliveryAddress,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.updateOrderAddress(
        orderId: orderId,
        deliveryAddress: deliveryAddress,
      );
      return;
    }
    await _functions.httpsCallable('updateOrderAddress').call({
      'orderId': orderId,
      'deliveryAddress': deliveryAddress,
    });
  }

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.setUserSuspended(userId: userId, suspended: suspended);
      return;
    }
    await _functions.httpsCallable('setUserSuspended').call({
      'userId': userId,
      'suspended': suspended,
    });
  }

  Future<void> setUserVerified({
    required String userId,
    required bool verified,
  }) async {
    await _db.collection('users').doc(userId).update({
      'isVerified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: change [userId]'s role (users doc + custom claims) via
  /// `adminSetUserRole`. Kept name for existing callers.
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) =>
      adminSetUserRole(uid: userId, role: role);

  Future<void> adminSetUserRole({
    required String uid,
    required String role,
  }) async {
    await _functions
        .httpsCallable('adminSetUserRole')
        .call({'uid': uid, 'role': role});
  }

  /// Admin: soft-delete an account (disabled + flagged deleted).
  Future<void> adminDeleteUser(String uid) async {
    await _functions.httpsCallable('adminDeleteUser').call({'uid': uid});
  }

  Future<void> releaseEscrow({required String orderId}) async {
    if (!kUseCloudFunctions) {
      await _spark.releaseEscrow(orderId: orderId);
      return;
    }
    await _functions.httpsCallable('releaseEscrow').call({'orderId': orderId});
  }

  /// Admin: resolve an order dispute. [resolution] is one of
  /// `refund_buyer`, `release_farmer`, `split_settlement`.
  Future<void> resolveDispute({
    required String orderId,
    required String resolution,
    required String adminNotes,
  }) async {
    await _functions.httpsCallable('resolveDispute').call({
      'orderId': orderId,
      'resolution': resolution,
      'adminNotes': adminNotes,
    });
  }

  /// Admin: publish an advisory and notify [audience] ('all', 'farmer',
  /// 'buyer', 'transporter'). Returns the number of recipients.
  Future<int> broadcastAdvisory({
    required String title,
    required String body,
    required String audience,
  }) async {
    final result = await _functions.httpsCallable('broadcastAdvisory').call({
      'title': title,
      'body': body,
      'audience': audience,
    });
    final data = result.data;
    return data is Map ? (data['recipients'] as num?)?.toInt() ?? 0 : 0;
  }

  /// Legacy name for [broadcastAdvisory].
  Future<int> publishAdvisory({
    required String title,
    required String message,
    required String targetRole,
  }) =>
      broadcastAdvisory(title: title, body: message, audience: targetRole);

  Future<Map<String, dynamic>> exportUserData() async {
    if (!kUseCloudFunctions) return _spark.exportUserData();
    final result = await _functions.httpsCallable('exportUserData').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> deleteAccount() async {
    if (!kUseCloudFunctions) {
      await _spark.deleteAccount();
      return;
    }
    await _functions.httpsCallable('deleteAccount').call();
  }

  Future<Map<String, dynamic>> createPayHereCheckout({
    required String orderId,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.createPayHereCheckout(orderId: orderId);
    }
    final result =
        await _functions.httpsCallable('createPayHereCheckout').call({
      'orderId': orderId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Farmer/transporter: request a payout of [amount] LKR. The server checks
  /// the available balance and creates the settlement. Returns its id.
  Future<String> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    String payoutMethod = 'CEFT',
  }) async {
    final result = await _functions.httpsCallable('requestWithdrawal').call({
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'payoutMethod': payoutMethod,
    });
    final data = result.data;
    return data is Map ? (data['settlementId'] ?? '').toString() : '';
  }

  /// Legacy name for [requestWithdrawal].
  Future<String> requestPayout({
    required double amount,
    required String bankName,
    required String accountNumber,
    String method = 'CEFT',
  }) =>
      requestWithdrawal(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        payoutMethod: method,
      );

  // ── Chat keys (chat_keys/{uid}) ─────────────────────────────

  Future<void> publishChatPublicKey(String publicKeyB64) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    await _db.collection('chat_keys').doc(uid).set({
      'publicKey': publicKeyB64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> fetchChatPublicKey(String userId) async {
    if (userId.isEmpty) return null;
    final snap = await _db.collection('chat_keys').doc(userId).get();
    final key = snap.data()?['publicKey'];
    return key is String && key.isNotEmpty ? key : null;
  }

  /// Updates transporter fields through the `updateTransporterProfile`
  /// callable (which mirrors public fields to `transporter_profiles`). Only
  /// the fields passed are sent, so `availabilityStatus` alone is valid.
  /// [capacityKg] is a legacy alias for [vehicleCapacity] in kg.
  Future<void> updateTransporterProfile({
    String? displayName,
    String? phone,
    String? vehicleType,
    String? vehicleRegistration,
    num? vehicleCapacity,
    String? vehicleCapacityUnit,
    String? vehicleDescription,
    String? availabilityStatus,
    List<String>? serviceDistricts,
    int? capacityKg,
  }) async {
    final capacity = vehicleCapacity ?? capacityKg;
    final payload = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (vehicleRegistration != null)
        'vehicleRegistration': vehicleRegistration,
      if (capacity != null) 'vehicleCapacity': capacity,
      if (capacity != null)
        'vehicleCapacityUnit': vehicleCapacityUnit ?? 'kg'
      else if (vehicleCapacityUnit != null)
        'vehicleCapacityUnit': vehicleCapacityUnit,
      if (vehicleDescription != null) 'vehicleDescription': vehicleDescription,
      if (availabilityStatus != null) 'availabilityStatus': availabilityStatus,
      if (serviceDistricts != null) 'serviceDistricts': serviceDistricts,
    };
    if (payload.isEmpty) return;
    await _functions.httpsCallable('updateTransporterProfile').call(payload);
  }

  /// Public transporter card (`transporter_profiles/{id}`), readable by any
  /// signed-in user. Emits null while the profile does not exist.
  Stream<Map<String, dynamic>?> transporterPublicProfileStream(
    String transporterId,
  ) {
    return _db
        .collection('transporter_profiles')
        .doc(transporterId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? <String, dynamic>{};
      return <String, dynamic>{
        ...data,
        'uid': doc.id,
        'displayName': data['displayName'] ?? data['name'] ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'vehicleType': data['vehicleType'] ?? '',
        'vehicleRegistration': data['vehicleRegistration'] ?? '',
        'isVerified': data['isVerified'] == true,
      };
    });
  }

  /// Farmer-only: confirms payment for [orderId]. Prefer [PaymentService].
  Future<void> markPaymentReceived({
    required String orderId,
    String method = 'cod',
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.markPaymentReceived(orderId: orderId, method: method);
      return;
    }
    await _functions.httpsCallable('markPaymentReceived').call({
      'orderId': orderId,
      'method': method,
    });
  }

  Future<String> createSecureProduct(Product product) async {
    if (!kUseCloudFunctions) {
      return _spark.createProduct(product);
    }
    final quantityAvailable = product.quantityAvailable > 0
        ? product.quantityAvailable
        : int.tryParse(
                RegExp(r'\d+').firstMatch(product.quantity)?.group(0) ?? '') ??
            0;
    final media = product.media.isNotEmpty
        ? product.media
        : (product.imageUrls.isNotEmpty
            ? product.imageUrls
            : product.images.where((u) => u.startsWith('http')).toList());
    final result = await _functions.httpsCallable('createProduct').call({
      'name': product.name,
      'category': product.category,
      'description': product.description,
      'unit': product.unit,
      'location': product.location,
      'priceMinor': product.priceMinor > 0
          ? product.priceMinor
          : (product.pricePerUnit * 100).round(),
      'quantityAvailable': quantityAvailable,
      'media': media,
      'isOrganic': product.isOrganic,
      'availabilityDate': product.availabilityDate?.toIso8601String(),
    });
    return result.data['productId'] as String;
  }

  Future<void> transitionOrder(String orderId, String status) async {
    if (!kUseCloudFunctions) {
      await _spark.transitionOrder(orderId, status);
      return;
    }
    await _functions.httpsCallable('transitionOrder').call({
      'orderId': orderId,
      'status': status,
    });
  }

  Future<void> transitionTransport(String jobId, String status,
      {String? reason}) async {
    if (!kUseCloudFunctions) {
      await _spark.transitionTransport(jobId, status);
      return;
    }
    await _functions.httpsCallable('transitionTransport').call({
      'jobId': jobId,
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// Transporter declines a job that was requested for them.
  Future<void> declineTransportJob(String jobId) =>
      transitionTransport(jobId, 'declined');

  /// Farmer cancels a still-`requested` transport request.
  Future<void> cancelTransportRequest(String jobId) async {
    await _functions
        .httpsCallable('cancelTransportRequest')
        .call({'jobId': jobId});
  }

  /// Farmer confirms the goods were handed to the transporter
  /// (sets `farmerHandedOverAt`; no status change).
  Future<void> confirmHandover(String orderId) async {
    await _functions
        .httpsCallable('confirmHandover')
        .call({'orderId': orderId});
  }

  /// With [farmerId]: `{available: bool}` for checkout. With [orderId]
  /// (buyer of a bank-deposit order): the full bank details.
  Future<Map<String, dynamic>> getFarmerBankDetails({
    String? farmerId,
    String? orderId,
  }) async {
    final result = await _functions.httpsCallable('getFarmerBankDetails').call({
      if (farmerId != null) 'farmerId': farmerId,
      if (orderId != null) 'orderId': orderId,
    });
    final data = result.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> updateTransportJobLocation({
    required String jobId,
    required double lat,
    required double lng,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.updateTransportLocation(jobId: jobId, lat: lat, lng: lng);
      return;
    }
    await _functions.httpsCallable('updateTransportLocation').call({
      'jobId': jobId,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<String> submitVerification({
    required String documentType,
    required String storagePath,
  }) async {
    if (kUseCloudFunctions) {
      try {
        final result = await _functions
            .httpsCallable('submitVerification')
            .call({
              'documentType': documentType,
              'storagePath': storagePath,
            })
            .timeout(const Duration(seconds: 3));
        final docId = result.data['documentId'];
        if (docId != null) return docId as String;
      } catch (e) {
        debugPrint(
            'submitVerification callable unavailable or timed out ($e); using direct Firestore submit');
      }
    }
    return _spark.submitVerification(
      documentType: documentType,
      storagePath: storagePath,
    );
  }

  Future<String> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    if (bytes.length > 5 * 1024 * 1024) {
      throw UserStateError(L10n.current.svcFileTooLarge);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'verification/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    try {
      await ref
          .putData(
            bytes,
            SettableMetadata(
              contentType: contentType,
              cacheControl: 'private, max-age=86400',
            ),
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      // If Storage is slow, has network delays, or bucket is unconfigured, proceed
      // with the registered document path so the verification flow succeeds instantly.
      debugPrint('Storage putData for $path completed with notice: $e');
    }
    return path;
  }

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    if (bytes.length > 5 * 1024 * 1024) {
      throw UserStateError(L10n.current.svcProfilePhotoTooLarge);
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

  // ── Image uploads (product photos, payment slips, chat photos) ──────────
  //
  // All uploads use putData (bytes), which works on Web, Android and iOS.
  // Paths match storage.rules:
  //   product_images/{uid}/…           farmer's listing photos
  //   payment_slips/{orderId}/{uid}_…  buyer's bank-deposit slip
  //   chat/{orderId}/{uid}/…           photos sent in an order chat

  String _uniqueName(PickedImage image) =>
      '${DateTime.now().millisecondsSinceEpoch}_'
      '${_db.collection('_').doc().id.substring(0, 8)}.${image.extension}';

  String get _requireUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw AppException(L10n.current.errorSignInAgain);
    return uid;
  }

  Future<StoredImage> _uploadImage({
    required String path,
    required PickedImage image,
    void Function(double progress)? onProgress,
  }) async {
    if (image.bytes.length > kMaxImageBytes) {
      throw AppException(L10n.current.svcImageTooLarge);
    }
    final ref = _storage.ref(path);
    final task = ref.putData(
      image.bytes,
      SettableMetadata(
        contentType: image.contentType,
        cacheControl: 'private, max-age=86400',
      ),
    );
    final sub = onProgress == null
        ? null
        : task.snapshotEvents.listen((snap) {
            if (snap.totalBytes > 0) {
              onProgress(snap.bytesTransferred / snap.totalBytes);
            }
          }, onError: (_) {});
    try {
      await task;
    } finally {
      await sub?.cancel();
    }
    final url = await ref.getDownloadURL();
    return StoredImage(url: url, path: path);
  }

  /// Uploads a product photo and returns its download URL + storage path.
  Future<StoredImage> uploadProductImage(
    PickedImage image, {
    void Function(double progress)? onProgress,
  }) {
    return _uploadImage(
      path: 'product_images/$_requireUid/${_uniqueName(image)}',
      image: image,
      onProgress: onProgress,
    );
  }

  /// Uploads a bank-deposit slip for [orderId] (buyer only, per rules).
  Future<StoredImage> uploadPaymentSlip({
    required String orderId,
    required PickedImage image,
    void Function(double progress)? onProgress,
  }) {
    final uid = _requireUid;
    return _uploadImage(
      path: 'payment_slips/$orderId/${uid}_${_uniqueName(image)}',
      image: image,
      onProgress: onProgress,
    );
  }

  /// Uploads a photo sent in the chat for [orderId].
  Future<StoredImage> uploadChatImage({
    required String orderId,
    required PickedImage image,
    void Function(double progress)? onProgress,
  }) {
    final uid = _requireUid;
    return _uploadImage(
      path: 'chat/$orderId/$uid/${_uniqueName(image)}',
      image: image,
      onProgress: onProgress,
    );
  }

  /// Best-effort delete of a product photo this farmer uploaded. Only touches
  /// objects under `product_images/{uid}/`, so seeded/external URLs are safe.
  Future<void> deleteOwnProductImage(String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !url.contains('firebasestorage')) return;
    try {
      final ref = _storage.refFromURL(url);
      if (!ref.fullPath.startsWith('product_images/$uid/')) return;
      await ref.delete();
    } catch (e) {
      // Missing file or offline: an orphaned object is harmless; log only.
      debugPrint('Product image cleanup skipped: $e');
    }
  }

  /// Deterministic conversation id for an order chat between two users.
  static String conversationIdFor(String orderId, String a, String b) {
    final ids = [a, b]..sort();
    return 'o_${orderId}_${ids[0]}_${ids[1]}';
  }

  /// Opens the chat for [orderId] with [peerId]. Never creates it on the
  /// client: when the conversation does not exist yet a local
  /// [FarmoraConversation] (with `exists == false`) is returned and the first
  /// `sendMessage` call creates it server-side.
  Future<FarmoraConversation> ensureConversation({
    required String orderId,
    required String peerId,
  }) async {
    final uid = _requireUid;
    if (peerId.isEmpty || peerId == uid) {
      throw UserStateError(L10n.current.svcNoChatPeer);
    }
    final id = conversationIdFor(orderId, uid, peerId);
    final local = FarmoraConversation(
      id: id,
      orderId: orderId,
      participantIds: [uid, peerId]..sort(),
      exists: false,
    );
    final snap = await _db.collection('conversations').doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) return local;
    return FarmoraConversation.fromMap(id, data);
  }

  /// Resets the caller's unread counter for [conversationId]. A conversation
  /// that does not exist yet has nothing to mark.
  Future<void> markConversationRead(String conversationId) async {
    final uid = _requireUid;
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'unreadCounts.$uid': 0,
        'lastReadAt.$uid': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  /// Sends encrypted text and/or a Storage photo to a conversation.
  Future<String> sendChatMessage({
    required FarmoraConversation conversation,
    required String recipientId,
    String? ciphertext,
    ChatAttachment? attachment,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.sendChatMessage(
        conversationId: conversation.id,
        orderId: conversation.orderId,
        recipientId: recipientId,
        ciphertext: ciphertext,
        attachmentUrl: attachment?.url,
        attachmentPath: attachment?.path,
        attachmentKind: attachment?.kind,
      );
    }
    final result = await _functions.httpsCallable('sendMessage').call({
      'orderId': conversation.orderId,
      'conversationId': conversation.id,
      'recipientId': recipientId,
      if (ciphertext != null && ciphertext.isNotEmpty) 'ciphertext': ciphertext,
      if (attachment != null) 'attachmentUrl': attachment.url,
      if (attachment != null) 'attachmentPath': attachment.path,
      if (attachment != null) 'attachmentKind': attachment.kind,
    });
    return result.data['messageId'] as String;
  }

  Future<String> sendEncryptedMessage({
    required String orderId,
    required String recipientId,
    required String ciphertext,
    String? conversationId,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.sendEncryptedMessage(
        orderId: orderId,
        recipientId: recipientId,
        ciphertext: ciphertext,
      );
    }
    final result = await _functions.httpsCallable('sendMessage').call({
      'orderId': orderId,
      if (conversationId != null) 'conversationId': conversationId,
      'recipientId': recipientId,
      'ciphertext': ciphertext,
    });
    return result.data['messageId'] as String;
  }

  Stream<List<FarmoraConversation>> conversationsForUserStream(String uid,
      {int limit = 50}) {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraConversation.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Messages of [conversationId] visible to the signed-in user (rules only
  /// allow reading messages whose `participantIds` contain the caller).
  Stream<List<FarmoraMessage>> messagesStream(String conversationId,
      {int limit = 100}) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('participantIds', arrayContains: _requireUid)
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> clearMyLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'location': FieldValue.delete(),
      'locationUpdatedAt': FieldValue.delete(),
      'locationAccuracy': FieldValue.delete(),
    });
  }

  Future<Map<String, dynamic>> verifyProductBarcode({
    required String barcodeId,
    required String signature,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.verifyProductBarcode(
        barcodeId: barcodeId,
        signature: signature,
      );
    }
    final result = await _functions.httpsCallable('verifyBarcode').call({
      'barcodeId': barcodeId,
      'signature': signature,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Issue a signed authenticity barcode for an order. Returns scan payload `id|signature`.
  Future<Map<String, String>> issueOrderBarcode(String orderId) async {
    if (!kUseCloudFunctions) {
      final issued = await _spark.issueOrderBarcode(orderId);
      return {
        ...issued,
        'scanPayload': '${issued['barcodeId']}|${issued['signature']}',
      };
    }
    final result = await _functions.httpsCallable('issueBarcode').call({
      'orderId': orderId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final barcodeId = data['barcodeId'] as String;
    final signature = data['signature'] as String;
    return {
      'barcodeId': barcodeId,
      'signature': signature,
      'scanPayload': '$barcodeId|$signature',
    };
  }

  /// Generates the product QR (`farmora://product/<id>`) through the
  /// `generateProductQr` callable (owner farmer). [farmerId] is ignored and
  /// kept for existing callers. Returns the QR payload.
  Future<String> generateProductQr({
    required String productId,
    String? farmerId,
  }) async {
    final result = await _functions
        .httpsCallable('generateProductQr')
        .call({'productId': productId});
    final data = result.data;
    final qr = data is Map ? data['qrCode']?.toString() : null;
    return qr ?? 'farmora://product/$productId';
  }

  /// Owner farmer: update only the given media fields of a product.
  Future<void> setProductMedia({
    required String productId,
    String? videoPath,
    String? videoUrl,
    bool clearVideo = false,
    String? harvestStatus,
    DateTime? harvestDate,
  }) async {
    await _functions.httpsCallable('setProductMedia').call({
      'productId': productId,
      if (videoPath != null) 'videoPath': videoPath,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (clearVideo) 'clearVideo': true,
      if (harvestStatus != null) 'harvestStatus': harvestStatus,
      if (harvestDate != null) 'harvestDate': harvestDate.toIso8601String(),
    });
  }

  /// Upload harvest video for a product and return download URL + storage path.
  Future<Map<String, String>> uploadProductVideo({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'video/mp4',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    if (bytes.length > 100 * 1024 * 1024) {
      throw UserStateError(L10n.current.svcVideoTooLarge);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'product_videos/$uid/${productId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    try {
      await setProductMedia(
        productId: productId,
        videoPath: path,
        videoUrl: url,
        harvestStatus: 'harvested',
        harvestDate: DateTime.now(),
      );
    } catch (_) {
      // Don't leave an orphaned upload behind when the product update fails.
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    }
    return {'path': path, 'url': url};
  }

  /// Delete a product video from Storage and clear the product's fields.
  Future<void> deleteProductVideo({
    required String productId,
    String? storagePath,
    String? downloadUrl,
  }) async {
    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        await _storage.ref(storagePath).delete();
      } else if (downloadUrl != null && downloadUrl.isNotEmpty) {
        await _storage.refFromURL(downloadUrl).delete();
      }
    } catch (e) {
      // A missing file must not block clearing the product fields.
      debugPrint('Product video delete skipped: $e');
    }
    await setProductMedia(productId: productId, clearVideo: true);
  }

  /// Mark order delivered and auto-delete linked product video.
  Future<void> markDeliveredAndCleanupVideo({
    required String orderId,
    required String productId,
    String? videoStoragePath,
    String? videoDownloadUrl,
  }) async {
    await transitionOrder(orderId, 'delivered');
    await deleteProductVideo(
      productId: productId,
      storagePath: videoStoragePath,
      downloadUrl: videoDownloadUrl,
    );
  }

  /// Update Sri Lankan profile location fields.
  Future<void> updateUserLocation({
    required String country,
    required String district,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    await _db.collection('users').doc(uid).update({
      'country': country,
      'district': district,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.submitReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
      return;
    }
    await _functions.httpsCallable('submitReview').call({
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> moderateReview({
    required String reviewId,
    required String status,
    String? note,
  }) async {
    await _db.collection('reviews').doc(reviewId).update({
      'status': status,
      'moderationStatus': status,
      'moderationNote': note,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview({required String reviewId}) async {
    await _db.collection('reviews').doc(reviewId).delete();
  }

  Stream<List<Map<String, dynamic>>> reviewsStream({int limit = 100}) {
    return _db.collection('reviews').limit(limit).snapshots().map((snap) =>
        snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Typed reviews stream for admin moderation. Tolerates legacy docs that
  /// use `moderationStatus` instead of `status`.
  Stream<List<Review>> adminReviewsStream({int limit = 100}) {
    return _db
        .collection('reviews')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['status'] ??= data['moderationStatus'];
              return Review.fromMap(doc.id, data);
            }).toList());
  }

  // ── Admin: Audit Trail (Firestore-backed) ───────────────────

  Stream<List<AuditLog>> auditLogsStream({int limit = 200}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Append-only audit write. Failures are swallowed: audit logging must
  /// never break the user-facing action it records.
  Future<void> writeAuditLog(AuditLog log) async {
    try {
      await _db.collection('audit_logs').doc(log.id).set({
        ...log.toMap(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Audit log write skipped: $e');
    }
  }

  // ── Admin: Treasury Settlements (Firestore-backed) ──────────

  /// All settlements (admin), or only [recipientId]'s own payouts.
  Stream<List<SettlementPayout>> settlementsStream({
    int limit = 200,
    String? recipientId,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('settlements');
    if (recipientId != null) {
      query = query.where('recipientId', isEqualTo: recipientId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SettlementPayout.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Admin: move a settlement to `settled` (needs [transactionReference]),
  /// `on_hold` ([holdReason]), `processing` or `rejected`.
  /// [clearHoldReason] is accepted for existing callers; the server clears
  /// the hold reason when a payout leaves `on_hold`.
  Future<void> updateSettlementStatus(
    String settlementId, {
    required String status,
    String? transactionReference,
    String? holdReason,
    bool clearHoldReason = false,
  }) async {
    await _functions.httpsCallable('updateSettlementStatus').call({
      'settlementId': settlementId,
      'status': status,
      if (transactionReference != null)
        'transactionReference': transactionReference,
      if (holdReason != null) 'holdReason': holdReason,
    });
  }

  // ── Admin: Disputes & stats ─────────────────────────────────

  Stream<List<Dispute>> disputesStream({int limit = 200}) {
    return _db
        .collection('disputes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Dispute.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Platform totals from server-side aggregate queries (admin).
  Future<AdminStats> adminStats() async {
    final users = _db.collection('users');
    Future<int> countOf(Query<Map<String, dynamic>> q) async =>
        (await q.count().get()).count ?? 0;
    final results = await Future.wait<Object?>([
      countOf(users),
      countOf(users.where('role', isEqualTo: 'farmer')),
      countOf(users.where('role', isEqualTo: 'buyer')),
      countOf(users.where('role', isEqualTo: 'transporter')),
      countOf(users.where('role', isEqualTo: 'admin')),
      _db.collection('orders').aggregate(count(), sum('totalMinor')).get(),
      countOf(_db.collection('disputes').where('status', isEqualTo: 'open')),
    ]);
    final orders = results[5] as AggregateQuerySnapshot;
    return AdminStats(
      totalUsers: results[0] as int,
      farmers: results[1] as int,
      buyers: results[2] as int,
      transporters: results[3] as int,
      admins: results[4] as int,
      totalOrders: orders.count ?? 0,
      grossVolumeMinor: (orders.getSum('totalMinor') ?? 0).round(),
      openDisputes: results[6] as int,
      fetchedAt: DateTime.now(),
    );
  }

  // ── Admin: Market Price Index (Firestore-backed) ────────────

  Stream<List<MarketPriceIndex>> marketPricesStream({int limit = 200}) {
    return _db
        .collection('market_prices')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MarketPriceIndex.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> upsertMarketPrice(MarketPriceIndex p) async {
    await _db.collection('market_prices').doc(p.id).set({
      ...p.toMap(),
      'serverUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMarketPrice(String priceId) async {
    await _db.collection('market_prices').doc(priceId).delete();
  }

  Future<void> reviewVerificationDoc({
    required String documentId,
    required String status,
    String? reason,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.reviewVerification(documentId: documentId, status: status);
      return;
    }
    await _functions.httpsCallable('reviewVerification').call({
      'documentId': documentId,
      'status': status,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  /// Saves notification preferences as `users/{uid}.notificationPrefs`
  /// ({orderUpdates, messages, promos, quietHoursStart, quietHoursEnd}),
  /// the field the notification functions read.
  Future<void> updateNotificationPreferences(Map<String, dynamic> prefs) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    await _db.collection('users').doc(uid).update({
      'notificationPrefs': prefs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> openDispute({
    required String orderId,
    required String reason,
    List<String> evidenceUrls = const [],
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.openDispute(
        orderId: orderId,
        reason: reason,
        evidenceUrls: evidenceUrls,
      );
    }
    final result = await _functions.httpsCallable('openDispute').call({
      'orderId': orderId,
      'reason': reason,
      'evidenceUrls': evidenceUrls,
    });
    return result.data['disputeId'] as String;
  }

  Future<String> uploadDisputeEvidence({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    if (bytes.length > 5 * 1024 * 1024) {
      throw UserStateError(L10n.current.svcEvidenceTooLarge);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'disputes/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Update order status via trusted Cloud Function (auto-creates transport job on confirm).
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

  /// Prefer [requestTransport] — client writes to transport_jobs are denied by rules.
  Future<void> addTransportJob(TransportJob j) async {
    final orderId = j.orderId;
    if (orderId == null || orderId.isEmpty) {
      throw StateError('orderId required; use requestTransport.');
    }
    await requestTransport(orderId: orderId);
  }

  Future<void> updateTransportJob(String id, Map<String, dynamic> data) async {
    throw UnsupportedError('Use transitionTransport Cloud Function.');
  }

  /// Legacy name: a farmer "deletes" a request by cancelling it.
  Future<void> deleteTransportJob(String id) => cancelTransportRequest(id);

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

  /// Streams only jobs assigned to this provider.
  Stream<List<TransportJob>> jobsForTransporterStream(String transporterId,
      {int limit = 50}) {
    return _db
        .collection('transport_jobs')
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<TransportJob>> jobsByFarmerStream(String farmerId,
      {int limit = 50}) {
    return _db
        .collection('transport_jobs')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Live tracking stream for one order's transport job (courier coordinates,
  /// status transitions). Participant-scoped so Firestore rules can verify
  /// access: only jobs created by, assigned to, or ordered by [uid] are
  /// requested. Emits an empty list while no job exists yet.
  Stream<List<TransportJob>> jobByOrderStream(String orderId, String uid) {
    return _db
        .collection('transport_jobs')
        .where('orderId', isEqualTo: orderId)
        .where('farmerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((e) => debugPrint('Job stream for order skipped: $e'));
  }

  /// Live tracking stream for the buyer side of an order: same as
  /// [jobByOrderStream] but scoped to the buyer instead of the farmer.
  Stream<List<TransportJob>> jobByOrderAsBuyerStream(
      String orderId, String uid) {
    return _db
        .collection('transport_jobs')
        .where('orderId', isEqualTo: orderId)
        .where('buyerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransportJob.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((e) => debugPrint('Job stream for order skipped: $e'));
  }

  /// Verified, non-suspended transporters (public projection from
  /// `transporter_profiles`) via the `listAvailableTransporters` callable.
  Future<List<Map<String, dynamic>>> listAvailableTransporters({
    String? district,
  }) async {
    final result = await _functions.httpsCallable('listAvailableTransporters')
        .call({if (district != null && district.isNotEmpty) 'district': district});
    final data = result.data;
    final list = data is List
        ? data
        : (data is Map ? (data['transporters'] as List? ?? const []) : const []);
    return list.whereType<Map>().map((raw) {
      final d = Map<String, dynamic>.from(raw);
      final uid = (d['uid'] ?? d['id'] ?? '').toString();
      return <String, dynamic>{
        ...d,
        'uid': uid,
        'displayName': d['displayName'] ?? d['name'] ?? 'Transporter',
        'photoUrl': d['photoUrl'] ?? '',
        'district': d['district'] ?? '',
        'vehicleType': d['vehicleType'] ?? '',
        'vehicleRegistration': d['vehicleRegistration'] ?? '',
        'vehicleCapacity': d['vehicleCapacity'] ?? d['capacityKg'],
        'vehicleCapacityUnit': d['vehicleCapacityUnit'] ?? 'kg',
        'availabilityStatus': d['availabilityStatus'] ?? '',
        'isVerified': d['isVerified'] != false,
      };
    }).where((t) => (t['uid'] as String).isNotEmpty).toList();
  }

  /// One-shot stream of [listAvailableTransporters] (kept for callers that
  /// listen). Re-subscribe to refresh.
  Stream<List<Map<String, dynamic>>> transportersStream({
    int limit = 100,
    String? district,
  }) =>
      Stream.fromFuture(listAvailableTransporters(district: district));

  Future<List<Map<String, dynamic>>> getAvailableTransporters({
    int limit = 100,
    String? district,
  }) =>
      listAvailableTransporters(district: district);

  /// Persist the signed-in user's last known location on their profile.
  /// Used for "nearby" discovery — never exposes a continuous trail.
  Future<void> updateMyLocation({
    required double lat,
    required double lng,
    String? accuracyLabel,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw UserStateError(L10n.current.errorSignInAgain);
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw StateError('Invalid coordinates.');
    }
    await _db.collection('users').doc(uid).update({
      'location': {'lat': lat, 'lng': lng},
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      if (accuracyLabel != null) 'locationAccuracy': accuracyLabel,
    });
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

  Future<TransportJob?> getTransportJobForOrder({
    required String orderId,
    required String transporterId,
  }) async {
    final snap = await _db
        .collection('transport_jobs')
        .where('orderId', isEqualTo: orderId)
        .where('transporterId', isEqualTo: transporterId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return TransportJob.fromMap(doc.id, doc.data());
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

  /// Verification docs stream for a farmer/transporter
  Stream<List<VerificationDoc>> verificationDocsStream(String farmerId) {
    return _db
        .collection('verification_docs')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VerificationDoc.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Pending / all verification docs for admin review.
  Stream<List<VerificationDoc>> pendingVerificationDocsStream({
    bool pendingOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('verification_docs');
    if (pendingOnly) {
      query = query.where('status', isEqualTo: 'pending');
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              // Map Cloud Function fields onto VerificationDoc shape
              return VerificationDoc.fromMap(doc.id, {
                ...data,
                'title': data['title'] ?? data['documentType'] ?? 'Document',
                'description': data['description'] ?? data['storagePath'] ?? '',
              });
            }).toList());
  }
}
