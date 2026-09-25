import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';

/// Firestore-only backend for Firebase Spark (no Cloud Functions).
class SparkBackend {
  SparkBackend(this._db);
  final FirebaseFirestore _db;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required.');
    return uid;
  }

  Future<Map<String, dynamic>> userDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data() ?? {};
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final uid = _uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('device_tokens')
        .doc(token.hashCode.toString())
        .set({
      'token': token,
      'platform': platform,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unregisterDeviceToken(String token) async {
    final uid = _uid;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('device_tokens')
        .where('token', isEqualTo: token)
        .get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  Future<Map<String, dynamic>> getPlatformSettings() async {
    final snap = await _db.collection('settings').doc('platform').get();
    return {
      'maintenanceMode': false,
      'platformFeeBps': 250,
      'sessionTimeoutMinutes': 60,
      'defaultDeliveryFeeMinor': 35000,
      'currency': 'LKR',
      ...?snap.data(),
    };
  }

  Future<void> updatePlatformSettings(Map<String, dynamic> settings) async {
    await _db.collection('settings').doc('platform').set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> createProduct(Product product) async {
    final uid = _uid;
    final quantityAvailable = product.quantityAvailable > 0
        ? product.quantityAvailable
        : int.tryParse(
              RegExp(r'\d+').firstMatch(product.quantity)?.group(0) ?? '',
            ) ??
            0;
    final media = product.media.isNotEmpty
        ? product.media
        : (product.imageUrls.isNotEmpty
            ? product.imageUrls
            : product.images.where((u) => u.startsWith('http')).toList());
    final priceMinor = product.priceMinor > 0
        ? product.priceMinor
        : (product.pricePerUnit * 100).round();
    final ref = _db.collection('products').doc();
    await ref.set({
      'farmerId': uid,
      'name': product.name,
      'category': product.category,
      'description': product.description,
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
      'harvestStatus': 'growing',
      'listingVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> createOrder({
    required String productId,
    required int quantity,
    int deliveryFeeMinor = 0,
    String? transporterId,
    required String deliveryAddress,
  }) async {
    final uid = _uid;
    final productSnap = await _db.collection('products').doc(productId).get();
    final product = productSnap.data();
    if (product == null) throw StateError('Product not found.');
    final available = (product['quantityAvailable'] as num?)?.toInt() ?? 0;
    if (quantity < 1 || quantity > available) {
      throw StateError('Not enough stock.');
    }
    final priceMinor = (product['priceMinor'] as num?)?.toInt() ?? 0;
    final subtotal = priceMinor * quantity;
    final farmerId = product['farmerId'] as String;
    final buyer = await userDoc(uid);
    final orderRef = _db.collection('orders').doc();
    final batch = _db.batch();
    batch.set(orderRef, {
      'buyerId': uid,
      'farmerId': farmerId,
      'productId': productId,
      'productName': product['name'] ?? '',
      'title': '$quantity ${product['unit'] ?? 'kg'} ${product['name'] ?? ''}',
      'quantity': '$quantity ${product['unit'] ?? 'kg'}',
      'unit': product['unit'] ?? 'kg',
      'items': [
        {
          'productId': productId,
          'quantity': quantity,
          'pricePerUnitMinor': priceMinor,
        }
      ],
      'subtotalMinor': subtotal,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': subtotal + deliveryFeeMinor,
      'currency': 'LKR',
      'deliveryAddress': deliveryAddress,
      'pickupAddress': product['location'] ?? '',
      'location': product['location'] ?? '',
      'buyerName': buyer['name'] ?? buyer['displayName'] ?? '',
      'farmerName': product['farmerName'] ?? '',
      if (transporterId != null) 'transporterId': transporterId,
      'status': 'pending',
      'paymentStatus': 'payment_required',
      'escrowStatus': 'not_funded',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(productSnap.reference, {
      'quantityAvailable': available - quantity,
      'quantity':
          '${available - quantity} ${product['unit'] ?? 'kg'} available',
      'status': available - quantity > 0 ? 'Active' : 'Empty',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _notify(
      farmerId,
      'New order',
      'A buyer ordered ${product['name'] ?? 'your produce'}.',
      'order',
      orderRef.id,
    );
    if (transporterId != null && transporterId.isNotEmpty) {
      final jobRef = _db.collection('transport_jobs').doc();
      await jobRef.set({
        'orderId': orderRef.id,
        'farmerId': farmerId,
        'buyerId': uid,
        'transporterId': transporterId,
        'title': 'Delivery for ${product['name'] ?? 'Produce'}',
        'route': '${product['location'] ?? 'Farm'} → $deliveryAddress',
        'detail': '$quantity ${product['unit'] ?? 'kg'}',
        'fee': 'LKR ${(deliveryFeeMinor / 100).toStringAsFixed(0)}',
        'offeredFeeMinor': deliveryFeeMinor,
        'pickupAddress': product['location'] ?? '',
        'dropoffAddress': deliveryAddress,
        'pickup': product['location'] ?? '',
        'dropoff': deliveryAddress,
        'productName': product['name'] ?? '',
        'quantity': '$quantity ${product['unit'] ?? 'kg'}',
        'district': product['location'] ?? '',
        'status': 'requested',
        'accepted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _notify(
        transporterId,
        'Delivery request',
        'A buyer selected you for a delivery request.',
        'logistics',
        orderRef.id,
      );
    }
    return orderRef.id;
  }

  Future<void> transitionOrder(String orderId, String status) async {
    final uid = _uid;
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    final order = snap.data();
    if (order == null) throw StateError('Order not found.');
    if (order['farmerId'] != uid &&
        order['buyerId'] != uid &&
        order['transporterId'] != uid) {
      throw StateError('Not allowed.');
    }
    await ref.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'confirmed') 'confirmedAt': FieldValue.serverTimestamp(),
      if (status == 'delivered') 'deliveredAt': FieldValue.serverTimestamp(),
    });
    if (status == 'confirmed' && order['transporterId'] == null) {
      await requestTransport(orderId: orderId);
    }
    final notifyUid =
        order['farmerId'] == uid ? order['buyerId'] : order['farmerId'];
    if (notifyUid is String && notifyUid.isNotEmpty) {
      await _notify(
        notifyUid,
        'Order update',
        'Order is now $status.',
        'order',
        orderId,
      );
    }
  }

  Future<void> requestTransport({
    required String orderId,
    int? deliveryFeeMinor,
  }) async {
    final uid = _uid;
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    final order = orderSnap.data();
    if (order == null || order['farmerId'] != uid) {
      throw StateError('Order not found.');
    }
    final existing = await _db
        .collection('transport_jobs')
        .where('orderId', isEqualTo: orderId)
        .where('status',
            whereIn: ['requested', 'accepted', 'pickedUp', 'inTransit'])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final fee = deliveryFeeMinor ??
        (order['deliveryFeeMinor'] as num?)?.toInt() ??
        35000;
    final productName =
        (order['productName'] ?? order['title'] ?? 'Produce').toString();
    final pickup =
        (order['pickupAddress'] ?? order['location'] ?? 'Farm').toString();
    final dropoff = (order['deliveryAddress'] ?? 'Buyer').toString();
    await _db.collection('transport_jobs').add({
      'orderId': orderId,
      'farmerId': order['farmerId'],
      'buyerId': order['buyerId'],
      'title': 'Delivery for $productName',
      'route': '$pickup → $dropoff',
      'detail': (order['quantity'] ?? '').toString(),
      'fee': 'LKR ${(fee / 100).toStringAsFixed(0)}',
      'offeredFeeMinor': fee,
      'pickupAddress': pickup,
      'dropoffAddress': dropoff,
      'pickup': pickup,
      'dropoff': dropoff,
      'productName': productName,
      'quantity': order['quantity'] ?? '',
      'district': order['location'] ?? '',
      'status': 'requested',
      'accepted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> transitionTransport(String jobId, String status) async {
    final uid = _uid;
    final ref = _db.collection('transport_jobs').doc(jobId);
    final snap = await ref.get();
    final job = snap.data();
    if (job == null) throw StateError('Job not found.');
    final updates = <String, dynamic>{
      'status': status,
      'transporterId': uid,
      'accepted': true,
      'updatedAt': FieldValue.serverTimestamp(),
      '${status}At': FieldValue.serverTimestamp(),
    };
    if (job['transporterId'] != null && job['transporterId'] != uid) {
      throw StateError(
          'This delivery request is assigned to another transporter.');
    }
    await ref.update(updates);

    // Privacy: clear the live courier position on delivery and cancellation
    // so a finished job never retains an exposed last known GPS position.
    if (status == 'delivered' || status == 'cancelled') {
      await ref.update({
        'courierLat': FieldValue.delete(),
        'courierLng': FieldValue.delete(),
        'locationUpdatedAt': FieldValue.delete(),
      });
    }

    final orderId = job['orderId'] as String?;
    if (orderId == null) return;
    const map = {
      'accepted': 'confirmed',
      'pickedUp': 'pickedUp',
      'inTransit': 'inTransit',
      'delivered': 'delivered',
    };
    final orderStatus = map[status];
    if (orderStatus == null) return;
    await _db.collection('orders').doc(orderId).update({
      'status': orderStatus,
      'transporterId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (orderStatus == 'delivered')
        'deliveredAt': FieldValue.serverTimestamp(),
    });
    if (status == 'delivered') {
      await _cleanupVideoForOrder(orderId);
    }
  }

  Future<void> updateTransportLocation({
    required String jobId,
    required double lat,
    required double lng,
  }) async {
    await _db.collection('transport_jobs').doc(jobId).update({
      'courierLat': lat,
      'courierLng': lng,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderAddress({
    required String orderId,
    required String deliveryAddress,
  }) async {
    final uid = _uid;
    final snap = await _db.collection('orders').doc(orderId).get();
    final order = snap.data();
    if (order == null || order['buyerId'] != uid) {
      throw StateError('Order not found.');
    }
    if (order['status'] != 'pending') {
      throw StateError('Address can only change while pending.');
    }
    await snap.reference.update({
      'deliveryAddress': deliveryAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markPaymentReceived({
    required String orderId,
    String method = 'cod',
  }) async {
    final uid = _uid;
    final snap = await _db.collection('orders').doc(orderId).get();
    final order = snap.data();
    if (order == null) throw StateError('Order not found.');
    if (order['buyerId'] != uid) throw StateError('Not allowed.');
    await snap.reference.update({
      'paymentStatus': 'paid',
      'escrowStatus': 'held',
      'paymentMethod': method,
      'paidAt': FieldValue.serverTimestamp(),
      'paidBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final farmerId = order['farmerId'];
    if (farmerId is String) {
      await _notify(
        farmerId,
        'Payment received',
        'COD/payment marked paid.',
        'order',
        orderId,
      );
    }
  }

  Future<String> createOffer({
    required String productId,
    required int proposedQuantity,
    required double proposedPrice,
  }) async {
    final uid = _uid;
    final productSnap = await _db.collection('products').doc(productId).get();
    final product = productSnap.data();
    if (product == null) throw StateError('Product not found.');
    final ref = _db.collection('offers').doc();
    await ref.set({
      'productId': productId,
      'productName': product['name'] ?? '',
      'buyerId': uid,
      'farmerId': product['farmerId'],
      'proposedQuantity': proposedQuantity,
      'proposedPrice': proposedPrice,
      'proposedPriceMinor': (proposedPrice * 100).round(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> acceptOffer({
    required String offerId,
    int deliveryFeeMinor = 35000,
  }) async {
    final uid = _uid;
    final offerSnap = await _db.collection('offers').doc(offerId).get();
    final offer = offerSnap.data();
    if (offer == null || offer['farmerId'] != uid) {
      throw StateError('Offer not found.');
    }
    if (offer['status'] != 'pending') throw StateError('Offer not pending.');

    final productId = offer['productId'] as String;
    final quantity = (offer['proposedQuantity'] as num).toInt();
    final buyerId = offer['buyerId'] as String;
    final productSnap = await _db.collection('products').doc(productId).get();
    final product = productSnap.data();
    if (product == null) throw StateError('Product not found.');
    final available = (product['quantityAvailable'] as num?)?.toInt() ?? 0;
    if (quantity < 1 || quantity > available) {
      throw StateError('Not enough stock.');
    }
    final priceMinor = (offer['proposedPriceMinor'] as num?)?.toInt() ??
        (((offer['proposedPrice'] as num?)?.toDouble() ?? 0) * 100).round();
    final subtotal = priceMinor * quantity;
    final buyer = await userDoc(buyerId);
    final orderRef = _db.collection('orders').doc();
    final batch = _db.batch();
    batch.set(orderRef, {
      'buyerId': buyerId,
      'farmerId': uid,
      'productId': productId,
      'offerId': offerId,
      'productName': product['name'] ?? '',
      'title': '$quantity ${product['unit'] ?? 'kg'} ${product['name'] ?? ''}',
      'quantity': '$quantity ${product['unit'] ?? 'kg'}',
      'unit': product['unit'] ?? 'kg',
      'items': [
        {
          'productId': productId,
          'quantity': quantity,
          'pricePerUnitMinor': priceMinor,
        }
      ],
      'subtotalMinor': subtotal,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': subtotal + deliveryFeeMinor,
      'currency': 'LKR',
      'deliveryAddress': 'To be confirmed by buyer',
      'pickupAddress': product['location'] ?? '',
      'location': product['location'] ?? '',
      'buyerName': buyer['name'] ?? buyer['displayName'] ?? '',
      'farmerName': product['farmerName'] ?? '',
      'status': 'confirmed',
      'paymentStatus': 'payment_required',
      'escrowStatus': 'not_funded',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(productSnap.reference, {
      'quantityAvailable': available - quantity,
      'quantity':
          '${available - quantity} ${product['unit'] ?? 'kg'} available',
      'status': available - quantity > 0 ? 'Active' : 'Empty',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(offerSnap.reference, {
      'status': 'accepted',
      'orderId': orderRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await requestTransport(
      orderId: orderRef.id,
      deliveryFeeMinor: deliveryFeeMinor,
    );
    return orderRef.id;
  }

  Future<void> rejectOffer(String offerId) async {
    final uid = _uid;
    final snap = await _db.collection('offers').doc(offerId).get();
    final offer = snap.data();
    if (offer == null || offer['farmerId'] != uid) {
      throw StateError('Offer not found.');
    }
    await snap.reference.update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> submitVerification({
    required String documentType,
    required String storagePath,
  }) async {
    final uid = _uid;
    final ref = _db.collection('verification_docs').doc();
    await ref.set({
      'ownerId': uid,
      'farmerId': uid,
      'documentType': documentType,
      'storagePath': storagePath,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> reviewVerification({
    required String documentId,
    required String status,
  }) async {
    final snap =
        await _db.collection('verification_docs').doc(documentId).get();
    final doc = snap.data();
    if (doc == null) throw StateError('Document not found.');
    await snap.reference.update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _uid,
    });
    if (status == 'approved' && doc['ownerId'] != null) {
      await _db.collection('users').doc(doc['ownerId'] as String).update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    await _db.collection('users').doc(userId).update({
      'isSuspended': suspended,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> releaseEscrow({required String orderId}) async {
    await _db.collection('orders').doc(orderId).update({
      'escrowStatus': 'released',
      'paymentStatus': 'released',
      'releasedAt': FieldValue.serverTimestamp(),
      'releasedBy': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> exportUserData() async {
    final uid = _uid;
    final profile = await userDoc(uid);
    final orders = await _db
        .collection('orders')
        .where('buyerId', isEqualTo: uid)
        .limit(100)
        .get();
    final farmerOrders = await _db
        .collection('orders')
        .where('farmerId', isEqualTo: uid)
        .limit(100)
        .get();
    final products = await _db
        .collection('products')
        .where('farmerId', isEqualTo: uid)
        .limit(100)
        .get();
    return {
      'profile': profile,
      'ordersAsBuyer': orders.docs.map((d) => d.data()).toList(),
      'ordersAsFarmer': farmerOrders.docs.map((d) => d.data()).toList(),
      'products': products.docs.map((d) => d.data()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> deleteAccount() async {
    final uid = _uid;
    await _db.collection('users').doc(uid).set({
      'displayName': 'Deleted User',
      'name': 'Deleted User',
      'phone': '',
      'isSuspended': true,
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await FirebaseAuth.instance.currentUser?.delete();
  }

  Future<Map<String, dynamic>> createPayHereCheckout({
    required String orderId,
  }) async {
    return {'enabled': false, 'useCod': true};
  }

  Future<String> sendEncryptedMessage({
    required String orderId,
    required String recipientId,
    required String ciphertext,
  }) async {
    final uid = _uid;
    final participants = [uid, recipientId]..sort();
    final convoQuery = await _db
        .collection('conversations')
        .where('orderId', isEqualTo: orderId)
        .get();
    String conversationId = '';
    for (final doc in convoQuery.docs) {
      final ids = List<String>.from(doc.data()['participantIds'] ?? []);
      ids.sort();
      if (ids.length == participants.length &&
          ids.asMap().entries.every((e) => e.value == participants[e.key])) {
        conversationId = doc.id;
        break;
      }
    }
    if (conversationId.isEmpty) {
      final convoRef = _db.collection('conversations').doc();
      await convoRef.set({
        'orderId': orderId,
        'participantIds': participants,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      conversationId = convoRef.id;
    }
    final msgRef = _db.collection('messages').doc();
    await msgRef.set({
      'orderId': orderId,
      'conversationId': conversationId,
      'senderId': uid,
      'receiverId': recipientId,
      'recipientId': recipientId,
      'ciphertext': ciphertext,
      'body': ciphertext,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage':
          ciphertext.length > 140 ? ciphertext.substring(0, 140) : ciphertext,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await _notify(
      recipientId,
      'New message',
      'You have a new encrypted order message.',
      'message',
      orderId,
    );
    return msgRef.id;
  }

  Future<Map<String, String>> issueOrderBarcode(String orderId) async {
    final uid = _uid;
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    final order = orderSnap.data();
    if (order == null || order['farmerId'] != uid) {
      throw StateError('Order not found.');
    }
    final barcodeId = _db.collection('barcodes').doc().id;
    final signature = _simpleSig('$barcodeId|$orderId|$uid');
    await _db.collection('barcodes').doc(barcodeId).set({
      'orderId': orderId,
      'farmerId': uid,
      'signature': signature,
      'status': 'issued',
      'scanCount': 0,
      'payload': '{"barcodeId":"$barcodeId","orderId":"$orderId"}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return {'barcodeId': barcodeId, 'signature': signature};
  }

  Future<Map<String, dynamic>> verifyProductBarcode({
    required String barcodeId,
    required String signature,
  }) async {
    final uid = _uid;
    final snap = await _db.collection('barcodes').doc(barcodeId).get();
    final barcode = snap.data();
    if (barcode == null || barcode['signature'] != signature) {
      throw StateError('Invalid barcode.');
    }
    final orderSnap =
        await _db.collection('orders').doc(barcode['orderId'] as String).get();
    final order = orderSnap.data();
    if (order == null || order['buyerId'] != uid) {
      throw StateError('Barcode not for this buyer.');
    }
    await snap.reference.update({
      'status': 'verified',
      'verifiedBy': uid,
      'verifiedAt': FieldValue.serverTimestamp(),
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
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    final order = orderSnap.data();
    if (order == null || order['buyerId'] != uid) {
      throw StateError('Order not found.');
    }
    await _db.collection('reviews').doc('${orderId}_$uid').set({
      'orderId': orderId,
      'reviewerId': uid,
      'subjectId': order['farmerId'],
      'rating': rating,
      'comment': comment,
      'moderationStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> openDispute({
    required String orderId,
    required String reason,
    List<String> evidenceUrls = const [],
  }) async {
    final uid = _uid;
    final disputeRef = _db.collection('disputes').doc();
    await disputeRef.set({
      'orderId': orderId,
      'openedBy': uid,
      'reason': reason,
      'status': 'open',
      'evidenceImages': evidenceUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('orders').doc(orderId).update({
      'paymentStatus': 'disputed',
      'disputeId': disputeRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return disputeRef.id;
  }

  Future<void> _cleanupVideoForOrder(String orderId) async {
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    final order = orderSnap.data();
    if (order == null) return;
    final productId = (order['productId'] ??
            ((order['items'] is List && (order['items'] as List).isNotEmpty)
                ? (order['items'] as List).first['productId']
                : null))
        ?.toString();
    if (productId == null || productId.isEmpty) return;
    await _db.collection('products').doc(productId).update({
      'videoPath': FieldValue.delete(),
      'videoUrl': FieldValue.delete(),
      'harvestStatus': 'delivered',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notify(
    String userId,
    String title,
    String body,
    String type,
    String? referenceId,
  ) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      if (referenceId != null) 'referenceId': referenceId,
      if (referenceId != null) 'orderId': referenceId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _simpleSig(String input) {
    // Spark fallback: deterministic non-crypto tag (not for production Blaze).
    var hash = 0;
    for (final c in input.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final rnd = Random(hash);
    return List.generate(24, (_) => rnd.nextInt(16).toRadixString(16)).join();
  }
}
