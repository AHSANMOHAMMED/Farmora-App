import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import '../../transporter/application/transporter_controller.dart';
import 'auth_gate.dart';

/// Stops the transporter module's live subscriptions, when that provider is
/// in the tree (it is provided app-wide in app.dart; tests may omit it).
void unbindTransporterController(BuildContext context) {
  try {
    Provider.of<TransporterController>(context, listen: false).unbind();
  } on ProviderNotFoundException {
    // Not provided in this tree — nothing to unbind.
  }
}

/// Signs out everywhere (FarmoraState + transporter module) and returns to a
/// fresh [AuthGate] from the root navigator. Throws when sign-out fails.
Future<void> signOutAndReset(BuildContext context, {String? reason}) async {
  final state = context.read<FarmoraState>();
  unbindTransporterController(context);
  await state.signOut(reason: reason);
  if (context.mounted) AuthGate.resetTo(context);
}

/// Prompts with a confirmation dialog and signs out of the platform if confirmed.
Future<bool> confirmAndSignOut(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  final l = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title ?? l.logOut,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Text(
        message ?? l.profileLogoutMessage,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.profileCancel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(l.signOut),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await signOutAndReset(context);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage(e, action: 'sign out')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  return false;
}

