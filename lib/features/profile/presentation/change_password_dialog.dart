import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/auth_l10n.dart';

/// Shows the change-password dialog (current + new + confirm →
/// [FarmoraState.changePassword]). Returns true when the password changed.
Future<bool> showChangePasswordDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ChangePasswordDialog(),
  );
  if (changed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.passwordChanged),
        backgroundColor: AppColors.primary,
      ),
    );
  }
  return changed == true;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<FarmoraState>().changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final raw = e is AppException ? e.message : null;
      setState(() => _error = authErrorText(
          raw, context.l10n, userMessage(e, action: 'change password')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        );
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                enabled: !_busy,
                obscureText: _obscure,
                decoration: deco('Current password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.authPasswordRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _new,
                enabled: !_busy,
                obscureText: _obscure,
                decoration: deco('New password'),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.passwordRequiredError;
                  if (v.length < 6) return l10n.passwordTooShort;
                  if (v == _current.text) {
                    return 'Choose a password different from the current one.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: _obscure,
                decoration: deco(l10n.confirmPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.confirmPasswordRequiredError;
                  }
                  if (v != _new.text) return l10n.passwordsDoNotMatch;
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.update),
        ),
      ],
    );
  }
}
