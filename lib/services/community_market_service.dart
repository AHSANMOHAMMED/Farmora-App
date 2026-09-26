import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_backend.dart';
import 'spark_backend.dart';

class CommunityMarketService {
  CommunityMarketService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  late final SparkBackend _spark = SparkBackend(_db);

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to use the market.');
    return uid;
  }

  Stream<List<Map<String, dynamic>>> watchBuyerRequests() => _db
      .collection('produce_requests')
      .where('buyerId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchOpenRequests() => _db
      .collection('produce_requests')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchQuotes(String requestId) => _db
      .collection('produce_requests').doc(requestId).collection('quotes')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchPriceReports({bool pendingOnly = false}) {
    Query<Map<String, dynamic>> query = _db.collection('market_price_reports');
    if (pendingOnly) query = query.where('status', isEqualTo: 'pending');
    return query.orderBy('createdAt', descending: true).limit(100).snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String> createRequest({required String produceName, required String category,
      required int quantity, required String unit, required String district,
      required String deliveryAddress, required DateTime deliveryDate,
      int maxUnitPriceMinor = 0, String notes = ''}) async {
    if (!kUseCloudFunctions) {
      return _spark.createProduceRequest(
        produceName: produceName, category: category, quantity: quantity,
        unit: unit, district: district, deliveryAddress: deliveryAddress,
        deliveryDate: deliveryDate, maxUnitPriceMinor: maxUnitPriceMinor,
        notes: notes,
      );
    }
    final result = await _functions.httpsCallable('createProduceRequest').call({
      'produceName': produceName, 'category': category, 'quantity': quantity,
      'unit': unit, 'district': district, 'deliveryAddress': deliveryAddress,
      'deliveryDate': deliveryDate.toIso8601String(),
      'maxUnitPriceMinor': maxUnitPriceMinor, 'notes': notes,
    });
    return result.data['requestId'] as String;
  }

  Future<void> submitQuote({required String requestId, required String productId,
      required int unitPriceMinor, required int deliveryFeeMinor,
      String message = ''}) async {
    if (!kUseCloudFunctions) {
      await _spark.submitProduceRequestQuote(
        requestId: requestId, productId: productId,
        unitPriceMinor: unitPriceMinor, deliveryFeeMinor: deliveryFeeMinor,
        message: message,
      );
      return;
    }
    await _functions.httpsCallable('submitProduceRequestQuote').call({
      'requestId': requestId, 'productId': productId,
      'unitPriceMinor': unitPriceMinor, 'deliveryFeeMinor': deliveryFeeMinor,
      'message': message,
    });
  }

  Future<String> acceptQuote(String requestId, String farmerId) async {
    if (!kUseCloudFunctions) {
      return _spark.acceptProduceRequestQuote(requestId, farmerId);
    }
    final result = await _functions.httpsCallable('acceptProduceRequestQuote')
        .call({'requestId': requestId, 'farmerId': farmerId});
    return result.data['orderId'] as String;
  }

  Future<void> cancelRequest(String requestId) async {
    if (!kUseCloudFunctions) {
      await _spark.cancelProduceRequest(requestId);
      return;
    }
    await _functions.httpsCallable('cancelProduceRequest').call({'requestId': requestId});
  }

  Future<void> submitPriceReport({required String cropName,
      required String category, required String marketName,
      required String district, required String unit,
      required double price}) async {
    if (!kUseCloudFunctions) {
      await _spark.submitMarketPriceReport(
        cropName: cropName, category: category, marketName: marketName,
        district: district, unit: unit, priceMinor: (price * 100).round(),
      );
      return;
    }
    await _functions.httpsCallable('submitMarketPriceReport').call({
      'cropName': cropName, 'category': category, 'marketName': marketName,
      'district': district, 'unit': unit, 'priceMinor': (price * 100).round(),
    });
  }

  Future<void> reviewPriceReport(String reportId, String decision) async {
    if (!kUseCloudFunctions) {
      await _spark.reviewMarketPriceReport(reportId, decision);
      return;
    }
    await _functions.httpsCallable('reviewMarketPriceReport').call({
      'reportId': reportId, 'decision': decision,
    });
  }
}
