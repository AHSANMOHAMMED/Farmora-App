import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String route;
  final String detail;
  final String fee;
  final bool accepted;
  final VoidCallback? onAccept;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.route,
    required this.detail,
    required this.fee,
    this.accepted = false,
    this.onAccept,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                fee,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48, // Touch target height
            child: ElevatedButton.icon(
              onPressed: accepted ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: accepted ? AppColors.surfaceContainerHigh : AppColors.primary,
                foregroundColor: accepted ? AppColors.onSurfaceVariant : Colors.white,
                elevation: accepted ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 8px border radius for buttons as per design
                ),
              ),
              icon: Icon(accepted ? Icons.check_circle_outline : Icons.local_shipping_outlined, size: 20),
              label: Text(
                accepted ? 'Job Accepted' : 'Accept Job',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

/// Alias for backward compatibility
class Job extends StatelessWidget {
  final String t, r, d, f;
  final VoidCallback? onAccept;

  const Job(this.t, this.r, this.d, this.f, {super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return JobCard(
      title: t,
      route: r,
      detail: d,
      fee: f,
      onAccept: onAccept,
    );
  }
}
