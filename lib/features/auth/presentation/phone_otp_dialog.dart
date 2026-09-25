import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import 'auth_l10n.dart';

Future<bool> showPhoneOtpDialog({
  required BuildContext context,
  required String phone,
  required Future<bool> Function(String code) verify,
  required Future<bool> Function() resend,
  required String? Function() error,
}) async {
  final controller = TextEditingController();
  var busy = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(context.l10n.verifyPhoneNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.authOtpEnterCode(phone)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              enabled: !busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: context.l10n.authVerificationCode,
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    setDialogState(() => busy = true);
                    final sent = await resend();
                    if (!context.mounted) return;
                    setDialogState(() => busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sent
                            ? context.l10n.authNewCodeRequested
                            : authErrorText(error(), context.l10n,
                                context.l10n.authCouldNotResendOtp)),
                        backgroundColor: sent ? AppColors.primary : Colors.red,
                      ),
                    );
                  },
            child: Text(context.l10n.resend),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setDialogState(() => busy = true);
                    final verified = await verify(controller.text);
                    if (!context.mounted) return;
                    if (verified) {
                      Navigator.pop(dialogContext, true);
                      return;
                    }
                    setDialogState(() => busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authErrorText(error(), context.l10n,
                            context.l10n.authOtpVerificationFailed)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.verify),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result ?? false;
}
