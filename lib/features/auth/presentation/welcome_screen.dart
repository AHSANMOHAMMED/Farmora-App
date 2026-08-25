import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_role.dart';
import '../../../services/firebase_service.dart';
import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Role selectedRole = Role.farmer;
  final _authService = FirebaseAuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      if (_isSignUp) {
        final credential = await _authService.signUp(email, password);
        await _authService.saveUserProfile(
          uid: credential.user!.uid,
          role: selectedRole.name,
          displayName: name.isNotEmpty ? name : email.split('@').first,
          email: email,
        );
      } else {
        await _authService.signIn(email, password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = _getErrorMessage(e.code); });
    } catch (e) {
      setState(() { _errorMessage = 'An unexpected error occurred.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password': return 'The password provided is too weak.';
      case 'email-already-in-use': return 'An account already exists for that email.';
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'invalid-email': return 'The email address is not valid.';
      default: return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            Text('Welcome to\nFarmora', style: const TextStyle(fontSize: 40, height: 1.05, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            const Text('A fairer, fresher way to connect farms, families, and reliable transport.', style: TextStyle(fontSize: 17, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 36),
            const Text('I am joining as a\u2026', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 12),
            ...Role.values.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => setState(() => selectedRole = r),
                leading: Icon(r.icon, color: AppColors.primary),
                title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Icon(selectedRole == r ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
                tileColor: selectedRole == r ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            )),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isSignUp = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: _isSignUp ? AppColors.primary : AppColors.surfaceContainerLow, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12))),
                  child: Center(child: Text('Sign Up', style: TextStyle(color: _isSignUp ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700))),
                ),
              )),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isSignUp = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: !_isSignUp ? AppColors.primary : AppColors.surfaceContainerLow, borderRadius: const BorderRadius.horizontal(right: Radius.circular(12))),
                  child: Center(child: Text('Sign In', style: TextStyle(color: !_isSignUp ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700))),
                ),
              )),
            ]),
            const SizedBox(height: 20),
            Form(key: _formKey, child: Column(children: [
              if (_isSignUp) ...[
                TextFormField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Full Name', hintText: 'Enter your name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.surfaceContainerLowest)),
                const SizedBox(height: 16),
              ],
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }, decoration: InputDecoration(labelText: 'Email', hintText: 'Enter your email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.surfaceContainerLowest)),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, obscureText: true, validator: (v) { if (v == null || v.isEmpty) return 'Password is required'; if (v.length < 6) return 'Password must be at least 6 characters'; return null; }, decoration: InputDecoration(labelText: 'Password', hintText: 'Enter your password', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.surfaceContainerLowest)),
            ])),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(_isSignUp ? 'Create Account & Continue' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Firebase Auth \u00b7 Secure account required', style: TextStyle(color: Colors.black45, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
