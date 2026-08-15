import 'package:flutter/material.dart';

class FarmoraOrder {
  final String id;
  final String title;
  final String detail;
  final String status;
  final double progress;
  final Color color;

  const FarmoraOrder({
    required this.id,
    required this.title,
    required this.detail,
    required this.status,
    required this.progress,
    required this.color,
  });
}
