import 'package:flutter/material.dart';

enum ProductStatus {
  active,
  empty,
  draft,
}

class Product {
  final String id;
  final String name;
  final String category;
  final String location;
  final String quantity;
  final String unit;
  final String price;
  final double pricePerUnit;
  final String emoji;
  final Color color;
  final String? imagePath;
  final String status;
  final bool isOrganic;
  final String description;
  final DateTime? availabilityDate;
  final List<String> images;

  const Product({
    this.id = '',
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    this.unit = 'kg',
    required this.price,
    this.pricePerUnit = 0.0,
    this.emoji = '🌱',
    this.color = const Color(0xFFE8F5E9),
    this.imagePath,
    this.status = 'Active',
    this.isOrganic = true,
    this.description = '',
    this.availabilityDate,
    this.images = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isEmpty => status.toLowerCase() == 'empty' || status.toLowerCase() == 'out of stock';

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? quantity,
    String? unit,
    String? price,
    double? pricePerUnit,
    String? emoji,
    Color? color,
    String? imagePath,
    String? status,
    bool? isOrganic,
    String? description,
    DateTime? availabilityDate,
    List<String>? images,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      isOrganic: isOrganic ?? this.isOrganic,
      description: description ?? this.description,
      availabilityDate: availabilityDate ?? this.availabilityDate,
      images: images ?? this.images,
    );
  }

  /// Positional factory constructor for backward compatibility with existing tests
  factory Product.positional(
    String name,
    String category,
    String location,
    String quantity,
    String price,
    String emoji,
    Color color, {
    String id = '',
  }) {
    return Product(
      id: id,
      name: name,
      category: category,
      location: location,
      quantity: quantity,
      price: price,
      emoji: emoji,
      color: color,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'pricePerUnit': pricePerUnit,
      'emoji': emoji,
      'color': color.value,
      'imagePath': imagePath,
      'status': status,
      'isOrganic': isOrganic,
      'description': description,
      'availabilityDate': availabilityDate?.toIso8601String(),
      'images': images,
    };
  }

  /// Deserialize from Firestore Map
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      quantity: data['quantity'] ?? '',
      unit: data['unit'] ?? 'kg',
      price: data['price'] ?? '',
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      emoji: data['emoji'] ?? '🌱',
      color: Color(data['color'] as int? ?? 0xFFE8F5E9),
      imagePath: data['imagePath'] as String?,
      status: data['status'] ?? 'Active',
      isOrganic: data['isOrganic'] ?? true,
      description: data['description'] ?? '',
      availabilityDate: data['availabilityDate'] != null
          ? DateTime.tryParse(data['availabilityDate'] as String)
          : null,
      images: List<String>.from(data['images'] ?? []),
    );
  }
}
