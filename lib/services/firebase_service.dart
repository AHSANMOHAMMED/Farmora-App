import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../core/config/app_backend.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transport_job.dart';
import '../models/verification_model.dart';
import '../models/conversation_model.dart';
import '../models/offer.dart';
import '../models/notification_model.dart';
import 'spark_backend.dart';

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

  Future<Map<String, dynamic>> getPlatformSettings() async {
    if (!kUseCloudFunctions) return _spark.getPlatformSettings();
    final result = await _functions.httpsCallable('getPlatformSettings').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> updatePlatformSettings(Map<String, dynamic> settings) async {
    if (!kUseCloudFunctions) {
      await _spark.updatePlatformSettings(settings);
      return;
    }
    await _functions.httpsCallable('updatePlatformSettings').call(settings);
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

  Future<void> sendInAppNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? referenceId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification failure shouldn't crash main operation
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
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

  Future<String> acceptOffer({
    required String offerId,
    int deliveryFeeMinor = 50000,
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
    });
    return result.data['orderId'] as String;
  }

  Future<void> rejectOffer(String offerId) async {
    if (!kUseCloudFunctions) {
      await _spark.rejectOffer(offerId);
      return;
    }
    await _functions.httpsCallable('rejectOffer').call({'offerId': offerId});
  }

  Future<void> updateOfferStatus(String id, String status) async {
    if (status == 'accepted') {
      await acceptOffer(offerId: id);
      return;
    }
    if (status == 'rejected') {
      await rejectOffer(id);
      return;
    }
    await _db.collection('offers').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FarmoraOffer>> offersByFarmerStream(String farmerId, {int limit = 50}) {
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

  Stream<List<FarmoraOffer>> offersByBuyerStream(String buyerId, {int limit = 50}) {
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
    required String deliveryAddress,
  }) async {
    if (!kUseCloudFunctions) {
      return _spark.createOrder(
        productId: productId,
        quantity: quantity,
        deliveryFeeMinor: deliveryFeeMinor,
        deliveryAddress: deliveryAddress,
      );
    }
    final result = await _functions.httpsCallable('createOrder').call({
      'productId': productId,
      'quantity': quantity,
      'deliveryFeeMinor': deliveryFeeMinor,
      'deliveryAddress': deliveryAddress,
      if (offerId != null) 'offerId': offerId,
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

  Future<void> releaseEscrow({required String orderId}) async {
    if (!kUseCloudFunctions) {
      await _spark.releaseEscrow(orderId: orderId);
      return;
    }
    await _functions.httpsCallable('releaseEscrow').call({'orderId': orderId});
  }

  Future<void> resolveDispute({
    required String orderId,
    required String resolution,
    required String adminNotes,
    double refundPercent = 100.0,
  }) async {
    if (!kUseCloudFunctions) {
      await _db.collection('orders').doc(orderId).update({
        'disputeStatus': 'resolved',
        'disputeResolution': resolution,
        'adminNotes': adminNotes,
        'status': resolution == 'refund_buyer' ? 'cancelled' : 'completed',
        'paymentStatus': resolution == 'refund_buyer' ? 'refunded' : 'released',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _functions.httpsCallable('resolveDispute').call({
      'orderId': orderId,
      'resolution': resolution,
      'adminNotes': adminNotes,
      'refundPercent': refundPercent,
    });
  }

  Future<void> publishAdvisory({
    required String title,
    required String message,
    required String targetRole,
    String priority = 'normal',
  }) async {
    await _db.collection('advisories').add({
      'title': title,
      'message': message,
      'targetRole': targetRole,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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
    final result = await _functions.httpsCallable('createPayHereCheckout').call({
      'orderId': orderId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> publishChatPublicKey(String publicKeyB64) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    await _db.collection('users').doc(uid).update({
      'chatPublicKey': publicKeyB64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> fetchChatPublicKey(String userId) async {
    final snap = await _db.collection('users').doc(userId).get();
    final key = snap.data()?['chatPublicKey'];
    return key is String && key.isNotEmpty ? key : null;
  }

  Future<void> updateTransporterProfile({
    String? vehicleType,
    int? capacityKg,
    List<String>? serviceDistricts,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (vehicleType != null) updates['vehicleType'] = vehicleType;
    if (capacityKg != null) updates['capacityKg'] = capacityKg;
    if (serviceDistricts != null) updates['serviceDistricts'] = serviceDistricts;
    await _db.collection('users').doc(uid).update(updates);
  }

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
        : int.tryParse(RegExp(r'\d+').firstMatch(product.quantity)?.group(0) ?? '') ?? 0;
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

  Future<void> transitionTransport(String jobId, String status) async {
    if (!kUseCloudFunctions) {
      await _spark.transitionTransport(jobId, status);
      return;
    }
    await _functions.httpsCallable('transitionTransport').call({
      'jobId': jobId,
      'status': status,
    });
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
    if (!kUseCloudFunctions) {
      return _spark.submitVerification(
        documentType: documentType,
        storagePath: storagePath,
      );
    }
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

  /// Upload a product image to Storage and return its download URL.
  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Image must be smaller than 5 MB.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'product_images/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<String> sendEncryptedMessage({
    required String orderId,
    required String recipientId,
    required String ciphertext,
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
      'recipientId': recipientId,
      'ciphertext': ciphertext,
    });
    return result.data['messageId'] as String;
  }

  Stream<List<FarmoraConversation>> conversationsForUserStream(String uid, {int limit = 50}) {
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

  Stream<List<FarmoraMessage>> messagesStream(String conversationId, {int limit = 100}) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FarmoraMessage.fromMap(doc.id, doc.data()))
            .toList());
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

  /// Generate and persist QR payload for a packed product.
  /// Prefer [issueOrderBarcode] for delivery authenticity verification.
  Future<String> generateProductQr({
    required String productId,
    required String farmerId,
  }) async {
    final payload = 'FARMORA:$productId:$farmerId:${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('products').doc(productId).update({
      'qrCode': payload,
      'packingDate': DateTime.now().toIso8601String(),
      'harvestStatus': 'packed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return payload;
  }

  /// Upload harvest video for a product and return download URL + storage path.
  Future<Map<String, String>> uploadProductVideo({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'video/mp4',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    if (bytes.length > 100 * 1024 * 1024) {
      throw StateError('Video must be smaller than 100 MB.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'product_videos/$uid/${productId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    await _db.collection('products').doc(productId).update({
      'videoPath': path,
      'videoUrl': url,
      'harvestStatus': 'harvested',
      'harvestDate': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return {'path': path, 'url': url};
  }

  /// Delete a product video from Storage and clear Firestore fields.
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
    } catch (_) {
      // Ignore missing-file errors; still clear Firestore fields.
    }
    await _db.collection('products').doc(productId).update({
      'videoPath': null,
      'videoUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    if (uid == null) throw StateError('Authentication required.');
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

  Future<void> reviewVerificationDoc({
    required String documentId,
    required String status,
  }) async {
    if (!kUseCloudFunctions) {
      await _spark.reviewVerification(documentId: documentId, status: status);
      return;
    }
    await _functions.httpsCallable('reviewVerification').call({
      'documentId': documentId,
      'status': status,
    });
  }

  Future<void> updateNotificationPreferences(Map<String, dynamic> prefs) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    await _db.collection('users').doc(uid).update({
      'notificationPreferences': prefs,
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
    if (uid == null) throw StateError('Authentication required.');
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Evidence photo must be smaller than 5 MB.');
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

  Future<void> deleteTransportJob(String id) async {
    throw UnsupportedError('Transport jobs cannot be deleted from the client.');
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

  // ── Database Seeding ──────────────────────────────────────

  /// Seeds demo products/orders/jobs (Spark: admin Firestore writes).
  Future<void> seedDatabase() async {
    if (!kUseCloudFunctions) {
      await _spark.seedDatabase();
      return;
    }
    await _functions.httpsCallable('seedDatabase').call();
  }
}
