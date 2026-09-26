import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import 'auth_gate.dart';
import 'auth_l10n.dart';

/// Forgot password: phone → SMS code → new password.
///
/// Step 1 calls [FarmoraState.sendPasswordResetOtp]; step 2 calls
/// [FarmoraState.resetPasswordWithOtp], which leaves the user signed out so
/// they log in with the new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.initialPhone);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _verificationId;
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _errorText(Object e, String fallback) {
    final l10n = context.l10n;
    final raw = e is AppException ? e.message : null;
    return authErrorText(raw, l10n, userMessage(e, action: fallback));
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await context
          .read<FarmoraState>()
          .sendPasswordResetOtp(_phoneController.text.trim());
      if (!mounted) return;
      setState(() {
        _verificationId = id;
        _codeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.otpSent),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e, 'send the reset code'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final verificationId = _verificationId;
    if (verificationId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = context.read<FarmoraState>();
    try {
      // The reset signs in with the SMS code for a moment; keep the gate on
      // the signed-out UI meanwhile.
      await AuthGate.guardAuthFlow(() => state.resetPasswordWithOtp(
            verificationId: verificationId,
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset. Log in with your new password.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e, 'reset the password'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final codeSent = _verificationId != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(l10n.forgotPassword),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              codeSent
                  ? l10n.authOtpEnterCode(_phoneController.text.trim())
                  : 'Enter the mobile number of your Farmora account. '
                      'We will send you a verification code by SMS.',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _phoneFormKey,
              child: TextFormField(
                controller: _phoneController,
                enabled: !_busy && !codeSent,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: l10n.phoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.phoneRequiredError;
                  }
                  return null;
                },
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 16),
              Form(
                key: _resetFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.authVerificationCode,
                        counterText: '',
                        prefixIcon: const Icon(Icons.sms_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch((value ?? '').trim())
                              ? null
                              : l10n.authErrEnterSixDigits,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_busy,
                      obscureText: _obscure,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordRequiredError;
                        }
                        if (value.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.confirmPasswordRequiredError;
                        }
                        if (value != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : (codeSent ? _resetPassword : _sendCode),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(codeSent ? 'Reset password' : 'Send code'),
            ),
            if (codeSent) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _verificationId = null;
                              _error = null;
                            }),
                    child: const Text('Change number'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: Text(l10n.resend),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
