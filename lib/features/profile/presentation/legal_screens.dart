import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Privacy Policy',
      body: [
        'Farmora collects your profile, listings, orders and delivery data to operate the marketplace.',
        'Phone numbers stay private by default. Buyers, farmers and transporters contact each other through order-scoped in-app messaging.',
        'Media you upload (product images, harvest videos, verification documents) is stored in Firebase Storage and shown only where needed for trade and verification.',
        'You can request data export or account deletion from Help & Support. Deletion removes your profile and personal data, subject to legal record-keeping for completed transactions.',
      ],
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Terms of Service',
      body: [
        'Farmora connects farmers, buyers and transport providers. Prices, stock and order totals are committed by trusted backend functions, not by the app.',
        'Farmers may list only produce they can supply. Buyers pay for confirmed orders. Transporters accept only jobs they can fulfil and follow the valid delivery state machine.',
        'Reviews are allowed once per delivered order and may be moderated. Abuse, fraud or harassment leads to suspension.',
        'Disputes pause escrow release until an administrator resolves them.',
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Help & Support'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.email_outlined), title: Text('support@farmora.app'), subtitle: Text('Replies within 2 business days')),
          ListTile(leading: Icon(Icons.phone_outlined), title: Text('+94 11 234 5678'), subtitle: Text('Mon–Fri, 9am–5pm (Asia/Colombo)')),
          ListTile(leading: Icon(Icons.delete_outline), title: Text('Request data export or deletion'), subtitle: Text('Mention your registered phone number')),
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
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: body.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => Text('•  ${body[i]}', style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
    );
  }
}
