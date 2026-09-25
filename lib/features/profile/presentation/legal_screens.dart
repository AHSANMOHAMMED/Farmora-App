import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _LegalScaffold(
      title: l.profilePrivacyPolicy,
      body: [
        l.legalPrivacy1,
        l.legalPrivacy2,
        l.legalPrivacy3,
        l.legalPrivacy4,
      ],
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _LegalScaffold(
      title: l.profileTerms,
      body: [
        l.legalTerms1,
        l.legalTerms2,
        l.legalTerms3,
        l.legalTerms4,
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const _supportPhone = String.fromEnvironment('SUPPORT_PHONE');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
          title: Text(l.helpSupport),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_supportEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text(_supportEmail),
              subtitle: Text(l.emailFarmoraSupport),
            ),
          if (_supportPhone.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text(_supportPhone),
              subtitle: Text(l.callFarmoraSupport),
            ),
          if (_supportEmail.isEmpty && _supportPhone.isEmpty)
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: Text(l.legalSupportNotConfigured),
              subtitle: Text(l.legalSupportNotConfiguredHint),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.legalDataRequest),
            subtitle: Text(l.legalDataRequestHint),
          ),
        ],
      ),
    );
  }
}

class _LegalScaffold extends StatelessWidget {
  final String title;
  final List<String> body;
  const _LegalScaffold({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: body.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => Text('•  ${body[i]}',
            style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
    );
  }
}
