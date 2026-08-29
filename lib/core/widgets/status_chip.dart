import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum StatusChipType {
  active,
  empty,
  pending,
  accepted,
  completed,
  approved,
  rejected,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType? type;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    final resolvedType = type ?? _inferType(label);

    switch (resolvedType) {
      case StatusChipType.active:
        bg = AppColors.statusActiveBg;
        text = AppColors.statusActiveText;
        break;
      case StatusChipType.empty:
        bg = AppColors.statusEmptyBg;
        text = AppColors.statusEmptyText;
        break;
      case StatusChipType.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPendingText;
        break;
      case StatusChipType.accepted:
      case StatusChipType.approved:
        bg = AppColors.statusApprovedBg;
        text = AppColors.statusApprovedText;
        break;
      case StatusChipType.completed:
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF1B5E20);
        break;
      case StatusChipType.rejected:
        bg = AppColors.errorContainer;
        text = AppColors.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  StatusChipType _inferType(String str) {
    final lower = str.toLowerCase();
    if (lower.contains('active')) return StatusChipType.active;
    if (lower.contains('empty') || lower.contains('out of stock')) return StatusChipType.empty;
    if (lower.contains('pending')) return StatusChipType.pending;
    if (lower.contains('approved') || lower.contains('accepted')) return StatusChipType.approved;
    if (lower.contains('rejected') || lower.contains('declined')) return StatusChipType.rejected;
    if (lower.contains('completed') || lower.contains('delivered')) return StatusChipType.completed;
    return StatusChipType.active;
  }
}
