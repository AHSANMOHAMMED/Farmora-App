
import 'package:flutter/material.dart';

class TrustBadge extends StatelessWidget {
  final String trustLevel;
  final double size;

  const TrustBadge({
    super.key,
    required this.trustLevel,
    this.size = 24.0,
  });

  Color _getTrustColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (trustLevel) {
      case 'High':
        return isDark ? Colors.amber : Colors.amber;
      case 'Medium':
        return isDark ? Colors.yellow : Colors.yellow;
      case 'Low':
        return isDark ? Colors.orange : Colors.orange;
      default:
        return isDark ? Colors.grey : Colors.grey;
    }
  }

  String _getTrustText() {
    switch (trustLevel) {
      case 'High':
        return 'Highly Trusted';
      case 'Medium':
        return 'Verified';
      case 'Low':
        return 'New Farmer';
      default:
        return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTrustColor(context);
    final text = _getTrustText();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trustLevel == 'High' ? Icons.star : 
            trustLevel == 'Medium' ? Icons.verified_outlined : 
            Icons.person_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
