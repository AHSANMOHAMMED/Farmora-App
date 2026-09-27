import '../core/utils/firebase_values.dart';

/// Kinds of farm inputs sold (or rented) by input suppliers.
enum InputCategory { seeds, fertilizer, pesticide, tools, machinery }

InputCategory inputCategoryFrom(Object? value) => InputCategory.values
    .firstWhere((c) => c.name == value, orElse: () => InputCategory.tools);

/// A supplier listing in `inputs/{id}`: a product for sale (price per unit)
/// or a machine for rent (price per day).
class FarmInput {
  const FarmInput({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.name,
    required this.category,
    required this.isRental,
    required this.priceMinor,
    required this.unit,
    required this.stock,
    this.description = '',
    this.imageUrl,
    this.district = '',
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String name;
  final InputCategory category;

  /// Rentals are priced per day; sales per [unit].
  final bool isRental;
  final int priceMinor;
  final String unit;

  /// Units in stock (sales) or machines available (rentals).
  final int stock;
  final String description;
  final String? imageUrl;
  final String district;
  final bool active;
  final DateTime? createdAt;

  double get price => priceMinor / 100.0;
  bool get inStock => stock > 0;

  factory FarmInput.fromMap(String id, Map<String, dynamic> d) => FarmInput(
        id: id,
        supplierId: (d['supplierId'] ?? '').toString(),
        supplierName: (d['supplierName'] ?? '').toString(),
        name: (d['name'] ?? '').toString(),
        category: inputCategoryFrom(d['category']),
        isRental: d['listingType'] == 'rental',
        priceMinor: firebaseInt(d['priceMinor']) ?? 0,
        unit: (d['unit'] ?? '').toString(),
        stock: firebaseInt(d['stock']) ?? 0,
        description: (d['description'] ?? '').toString(),
        imageUrl: (d['imageUrl'] ?? '').toString().trim().isEmpty
            ? null
            : d['imageUrl'].toString(),
        district: (d['district'] ?? '').toString(),
        active: d['status'] == 'Active' && d['isDeleted'] != true,
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Statuses of an input order. Sales: pending → confirmed → dispatched →
/// delivered. Rentals: pending → confirmed → inUse → returned. A pending
/// order can be rejected (supplier) or cancelled (farmer).
class InputOrderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const dispatched = 'dispatched';
  static const delivered = 'delivered';
  static const inUse = 'inUse';
  static const returned = 'returned';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  /// The supplier's next step from [status], or null when none.
  static String? nextFor(String status, {required bool rental}) =>
      switch (status) {
        confirmed => rental ? inUse : dispatched,
        dispatched => delivered,
        inUse => returned,
        _ => null,
      };

  static bool isClosed(String status) =>
      const {delivered, returned, rejected, cancelled}.contains(status);
}

/// A farmer's purchase or rental booking in `input_orders/{id}`.
class InputOrder {
  const InputOrder({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.supplierId,
    required this.supplierName,
    required this.inputId,
    required this.inputName,
    required this.isRental,
    required this.quantity,
    required this.unitPriceMinor,
    required this.totalMinor,
    required this.deliveryAddress,
    required this.status,
    this.category = InputCategory.tools,
    this.unit = '',
    this.days,
    this.startDate,
    this.createdAt,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String supplierId;
  final String supplierName;
  final String inputId;
  final String inputName;
  final bool isRental;
  final int quantity;
  final int unitPriceMinor;
  final int totalMinor;
  final String deliveryAddress;
  final String status;
  final InputCategory category;
  final String unit;
  final int? days;
  final DateTime? startDate;
  final DateTime? createdAt;

  double get total => totalMinor / 100.0;

  factory InputOrder.fromMap(String id, Map<String, dynamic> d) => InputOrder(
        id: id,
        farmerId: (d['farmerId'] ?? '').toString(),
        farmerName: (d['farmerName'] ?? '').toString(),
        supplierId: (d['supplierId'] ?? '').toString(),
        supplierName: (d['supplierName'] ?? '').toString(),
        inputId: (d['inputId'] ?? '').toString(),
        inputName: (d['inputName'] ?? '').toString(),
        isRental: d['listingType'] == 'rental',
        quantity: firebaseInt(d['quantity']) ?? 0,
        unitPriceMinor: firebaseInt(d['unitPriceMinor']) ?? 0,
        totalMinor: firebaseInt(d['totalMinor']) ?? 0,
        deliveryAddress: (d['deliveryAddress'] ?? '').toString(),
        status: (d['status'] ?? InputOrderStatus.pending).toString(),
        category: inputCategoryFrom(d['category']),
        unit: (d['unit'] ?? '').toString(),
        days: firebaseInt(d['days']),
        startDate: firebaseDate(d['startDate']),
        createdAt: firebaseDate(d['createdAt']),
      );
}
