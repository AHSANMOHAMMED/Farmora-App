import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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
        title: const Text('Verify phone number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code for $phone.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              enabled: !busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spark plan: use the fixed code configured for this test phone number in Firebase Console.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
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
                            ? 'A new code was requested.'
                            : (error() ?? 'Could not resend OTP.')),
                        backgroundColor: sent ? AppColors.primary : Colors.red,
                      ),
                    );
                  },
            child: const Text('Resend'),
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
                        content: Text(error() ?? 'OTP verification failed.'),
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
                : const Text('Verify'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result ?? false;
}
