import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/models/product.dart';
import 'package:farmora/models/order.dart';
import 'package:farmora/models/transport_job.dart';
import 'package:farmora/models/offer.dart';
import 'package:farmora/models/notification_model.dart';
import 'package:flutter/material.dart';

void main() {
  group('Product Model CRUD', () {
    test('Product creation and serialization', () {
      const p = Product(
        id: 'p1',
        name: 'Fresh Carrots',
        price: 'LKR 250/kg',
        category: 'Vegetables',
        location: 'Nuwara Eliya',
        quantity: '100 kg',
        pricePerUnit: 250.0,
        unit: 'kg',
      );

      expect(p.name, 'Fresh Carrots');
      expect(p.effectivePricePerUnit, 250.0);

      final map = p.toMap();
      expect(map['name'], 'Fresh Carrots');
      expect(map['category'], 'Vegetables');

      final fromMapProduct = Product.fromMap('p1', map);
      expect(fromMapProduct.id, 'p1');
      expect(fromMapProduct.name, 'Fresh Carrots');
    });
  });

  group('FarmoraOffer Model CRUD (Epic 1)', () {
    test('Offer creation, price calculation, status transitions', () {
      final offer = FarmoraOffer(
        id: 'off-101',
        productId: 'prod-50',
        productName: 'Organic Potatoes',
        buyerId: 'buyer-001',
        farmerId: 'farmer-002',
        proposedQuantity: 50,
        proposedPrice: 180.0,
        status: 'pending',
      );

      expect(offer.id, 'off-101');
      expect(offer.proposedPriceMinor, 18000);
      expect(offer.status, 'pending');

      final acceptedOffer = offer.copyWith(status: 'accepted');
      expect(acceptedOffer.status, 'accepted');

      final map = offer.toMap();
      expect(map['productName'], 'Organic Potatoes');
      expect(map['proposedPrice'], 180.0);

      final reconstructed = FarmoraOffer.fromMap('off-101', map);
      expect(reconstructed.productName, 'Organic Potatoes');
      expect(reconstructed.proposedQuantity, 50);
    });
  });

  group('TransportJob Model CRUD (Epic 2)', () {
    test('Job linking to Order, status progression', () {
      const job = TransportJob(
        id: 'job-1',
        title: 'Delivery for Fresh Carrots',
        route: 'Farm → Colombo Port',
        detail: '100 kg · Ready for pickup',
        fee: 'LKR 3,500',
        status: 'requested',
        orderId: 'ord-999',
        buyerId: 'buyer-001',
        farmerId: 'farmer-002',
      );

      expect(job.orderId, 'ord-999');
      expect(job.buyerId, 'buyer-001');
      expect(job.farmerId, 'farmer-002');
      expect(job.status, 'requested');

      final inTransitJob = job.copyWith(
        status: 'in transit',
        transporterId: 'trans-55',
      );
      expect(inTransitJob.status, 'in transit');
      expect(inTransitJob.transporterId, 'trans-55');

      final map = job.toMap();
      final fromMapJob = TransportJob.fromMap('job-1', map);
      expect(fromMapJob.orderId, 'ord-999');
      expect(fromMapJob.fee, 'LKR 3,500');
    });
  });

  group('FarmoraOrder Model CRUD (Epic 3)', () {
    test('Order lifecycle and status filtering', () {
      final order = FarmoraOrder(
        id: 'ord-1',
        orderNumber: '#1001',
        title: 'Fresh Carrots',
        productName: 'Fresh Carrots',
        quantity: '50 kg',
        grade: 'Grade A',
        unitPrice: 'LKR 200',
        totalAmount: 'LKR 10,000',
        totalAmountNumber: 10000.0,
        buyerName: 'Sarah',
        buyerCompany: 'Sarah Foods',
        buyerAvatar: '',
        buyerPhone: '0771234567',
        deliveryAddress: 'Kandy Road, Colombo',
        detail: '50 kg · LKR 10,000',
        status: 'pending',
        progress: 0.1,
        color: Colors.orange,
        timestamp: 'Just now',
        requestedDate: 'Today',
      );

      expect(order.isPending, isTrue);
      expect(order.isAccepted, isFalse);

      final confirmedOrder = order.copyWith(status: 'Accepted', progress: 0.5);
      expect(confirmedOrder.isAccepted, isTrue);

      final completedOrder = order.copyWith(status: 'Completed', progress: 1.0);
      expect(completedOrder.isCompleted, isTrue);
    });
  });

  group('FarmoraNotification Model CRUD (Epic 4)', () {
    test('Notification creation, unread status, type handling', () {
      final notif = FarmoraNotification(
        id: 'notif-1',
        userId: 'farmer-123',
        title: 'New Price Offer',
        body: 'Buyer proposed LKR 180 for 50 kg Potatoes.',
        type: 'offer',
        read: false,
        referenceId: 'off-101',
      );

      expect(notif.read, isFalse);
      expect(notif.type, 'offer');
      expect(notif.referenceId, 'off-101');

      final readNotif = notif.copyWith(read: true);
      expect(readNotif.read, isTrue);

      final map = notif.toMap();
      expect(map['title'], 'New Price Offer');
      expect(map['read'], false);

      final fromMapNotif = FarmoraNotification.fromMap('notif-1', map);
      expect(fromMapNotif.id, 'notif-1');
      expect(fromMapNotif.body, 'Buyer proposed LKR 180 for 50 kg Potatoes.');
    });
  });
}
