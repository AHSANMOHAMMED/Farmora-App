import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String location;
  final String quantity;
  final String price;
  final String emoji;
  final Color color;
  final String description;
  final String? imagePath;
  final bool isActive;
  final bool isOrganic;
  final String status;
  final String farmerId;

  const Product({
    this.id = '',
    required this.name,
    this.category = '',
    this.location = '',
    this.quantity = '',
    this.price = '',
    this.emoji = '🌱',
    this.color = const Color(0xffdcefe2),
    this.description = '',
    this.imagePath,
    this.isActive = true,
    this.isOrganic = false,
    this.status = 'active',
    this.farmerId = '',
  });

  /// Positional factory constructor for backward compatibility
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

  bool get isEmpty => quantity.isEmpty;

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'location': location,
    'quantity': quantity,
    'price': price,
    'emoji': emoji,
    'color': color.value,
    'description': description,
    'imagePath': imagePath ?? '',
    'isActive': isActive,
    'isOrganic': isOrganic,
    'status': status,
    'farmerId': farmerId,
  };

  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
    id: id,
    name: m['name'] ?? '',
    category: m['category'] ?? '',
    location: m['location'] ?? '',
    quantity: m['quantity'] ?? '',
    price: m['price'] ?? '',
    emoji: m['emoji'] ?? '🌱',
    color: Color(m['color'] ?? 0xffdcefe2),
    description: m['description'] ?? '',
    imagePath: m['imagePath'] ?? '',
    isActive: m['isActive'] ?? true,
    isOrganic: m['isOrganic'] ?? false,
    status: m['status'] ?? 'active',
    farmerId: m['farmerId'] ?? '',
  );
}
