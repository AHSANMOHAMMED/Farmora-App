import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Delivery History',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Mock data
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery #${1000 + index}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiary,
                      ),
                    ),
                    Text(
                      'May ${20 - index}, 2024',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Organic Vegetables',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.route, size: 16, color: AppColors.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text(
                      'Kandy → Colombo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusApprovedBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusApprovedText,
                        ),
                      ),
                    ),
                    const Text(
                      'LKR 4,500',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
