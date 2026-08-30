import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/order.dart';

class TrackOrderScreen extends StatelessWidget {
  final FarmoraOrder order;

  const TrackOrderScreen({super.key, required this.order});

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
          'Track Order',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ORDER ${order.orderNumber.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tertiary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusPendingBg, // mock
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusPendingText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.productName.isNotEmpty ? order.productName : order.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${order.totalAmount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Mock map placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: AppColors.outlineVariant),
                    SizedBox(height: 8),
                    Text(
                      'Live Tracking Map',
                      style: TextStyle(fontFamily: 'Inter', color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Delivery Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTimelineStep('Order Placed', 'Your order was confirmed', true, true),
                  _buildTimelineStep('Processing', 'Farmer is preparing the order', true, true),
                  _buildTimelineStep('In Transit', 'Order is on the way', order.status.toLowerCase() == 'in transit' || order.status.toLowerCase() == 'delivered', order.status.toLowerCase() == 'delivered'),
                  _buildTimelineStep('Delivered', 'Package arrived', order.status.toLowerCase() == 'delivered', order.status.toLowerCase() == 'delivered', isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isActive, bool isCompleted, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : isActive
                      ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? AppColors.primary : AppColors.surfaceContainerHigh,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
