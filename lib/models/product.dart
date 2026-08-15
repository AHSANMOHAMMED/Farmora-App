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

  const Product({
    this.id = '',
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    required this.price,
    required this.emoji,
    required this.color,
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
}
