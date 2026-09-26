import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/farmora_state.dart';

/// Explains why the last session ended or sign-in was refused
/// ([FarmoraState.authBlockedReason]: suspended / deleted account,
/// inactivity timeout). Renders nothing when there is no reason.
class AuthBlockedBanner extends StatelessWidget {
  const AuthBlockedBanner({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final reason = context.watch<FarmoraState?>()?.authBlockedReason;
    if (reason == null || reason.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
