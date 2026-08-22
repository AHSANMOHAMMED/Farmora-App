import 'package:equatable/equatable.dart';

enum ProductCategory {
  vegetables,
  fruits,
  herbs,
  grains,
  dairy,
  spices,
  other;

  String get label {
    switch (this) {
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.herbs:
        return 'Herbs';
      case ProductCategory.grains:
        return 'Grains';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.spices:
        return 'Spices';
      case ProductCategory.other:
        return 'Other';
    }
  }
}

enum ProductAvailability {
  available,
  limited,
  outOfStock;

  String get label {
    switch (this) {
      case ProductAvailability.available:
        return 'Available';
      case ProductAvailability.limited:
        return 'Limited';
      case ProductAvailability.outOfStock:
        return 'Out of stock';
    }
  }
}

class ProductModel extends Equatable {
  final String id;
  final String farmerId;
  final String name;
  final ProductCategory category;
  final String description;
  final List<String> imageUrls;
  final double quantityAvailable;
  final String unit;
  final int priceMinor;
  final String currency;
  final String location;
  final ProductAvailability availability;
  final List<String> searchTokens;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? availableFrom;
  final DateTime? availableTo;

  const ProductModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    this.description = '',
    this.imageUrls = const [],
    required this.quantityAvailable,
    required this.unit,
    required this.priceMinor,
    this.currency = 'LKR',
    required this.location,
    this.availability = ProductAvailability.available,
    this.searchTokens = const [],
    this.createdAt,
    this.updatedAt,
    this.availableFrom,
    this.availableTo,
  });

  String get displayPrice => '$currency $priceMinor / $unit';
  String get displayQuantity =>
      '${quantityAvailable.toStringAsFixed(0)} $unit available';

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        farmerId: json['farmerId'] as String,
        name: json['name'] as String,
        category: ProductCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ProductCategory.other,
        ),
        description: json['description'] as String? ?? '',
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
        quantityAvailable: (json['quantityAvailable'] as num).toDouble(),
        unit: json['unit'] as String,
        priceMinor: json['priceMinor'] as int,
        currency: json['currency'] as String? ?? 'LKR',
        location: json['location'] as String,
        availability: ProductAvailability.values.firstWhere(
          (a) => a.name == json['availability'],
          orElse: () => ProductAvailability.available,
        ),
        searchTokens:
            (json['searchTokens'] as List?)?.cast<String>() ?? [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        availableFrom: json['availableFrom'] != null
            ? DateTime.parse(json['availableFrom'] as String)
            : null,
        availableTo: json['availableTo'] != null
            ? DateTime.parse(json['availableTo'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerId': farmerId,
        'name': name,
        'category': category.name,
        'description': description,
        'imageUrls': imageUrls,
        'quantityAvailable': quantityAvailable,
        'unit': unit,
        'priceMinor': priceMinor,
        'currency': currency,
        'location': location,
        'availability': availability.name,
        'searchTokens': searchTokens,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'availableFrom': availableFrom?.toIso8601String(),
        'availableTo': availableTo?.toIso8601String(),
      };

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? name,
    ProductCategory? category,
    String? description,
    List<String>? imageUrls,
    double? quantityAvailable,
    String? unit,
    int? priceMinor,
    String? currency,
    String? location,
    ProductAvailability? availability,
    List<String>? searchTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? availableFrom,
    DateTime? availableTo,
  }) =>
      ProductModel(
        id: id ?? this.id,
        farmerId: farmerId ?? this.farmerId,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        imageUrls: imageUrls ?? this.imageUrls,
        quantityAvailable: quantityAvailable ?? this.quantityAvailable,
        unit: unit ?? this.unit,
        priceMinor: priceMinor ?? this.priceMinor,
        currency: currency ?? this.currency,
        location: location ?? this.location,
        availability: availability ?? this.availability,
        searchTokens: searchTokens ?? this.searchTokens,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        availableFrom: availableFrom ?? this.availableFrom,
        availableTo: availableTo ?? this.availableTo,
      );

  @override
  List<Object?> get props => [
        id, farmerId, name, category, description, imageUrls,
        quantityAvailable, unit, priceMinor, currency, location,
        availability, searchTokens, createdAt, updatedAt,
        availableFrom, availableTo,
      ];
}
