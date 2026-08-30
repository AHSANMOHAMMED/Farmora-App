import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xff1f7a4d)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Stat = StatCard;
