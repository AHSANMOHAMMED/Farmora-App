import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    final faqs = [
      (q: l.helpFaqOrdersQ, a: l.helpFaqOrdersA),
      (q: l.helpFaqPayoutQ, a: l.helpFaqPayoutA),
      (q: l.helpFaqTransportQ, a: l.helpFaqTransportA),
      (q: l.helpFaqVerificationQ, a: l.helpFaqVerificationA),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.helpSupport,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF006E1C), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.headset_mic_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.helpSupport,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.helpSupportHours,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Contact options ──
            Text(
              l.helpContactUs,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_rounded,
                    label: l.helpCallSupport,
                    value: '+94 11 234 5678',
                    color: AppColors.primary,
                    bg: const Color(0xFFE8F5E9),
                    uri: Uri(scheme: 'tel', path: '+94112345678'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_rounded,
                    label: l.helpEmailUs,
                    value: 'support@farmora.lk',
                    color: const Color(0xFF1565C0),
                    bg: const Color(0xFFE3F2FD),
                    uri: Uri(
                      scheme: 'mailto',
                      path: 'support@farmora.lk',
                      query: 'subject=Farmora%20support',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat_rounded,
              label: l.helpWhatsApp,
              value: '+94 77 123 4567',
              color: const Color(0xFF2E7D32),
              bg: const Color(0xFFE8F5E9),
              wide: true,
              uri: Uri.parse('https://wa.me/94771234567'),
            ),
            const SizedBox(height: 24),

            // ── FAQ ──
            Text(
              l.helpFaqTitle,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            ...List.generate(faqs.length, (i) {
              final isOpen = _expandedFaq == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOpen
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: isOpen,
                    onExpansionChanged: (v) =>
                        setState(() => _expandedFaq = v ? i : null),
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    title: Text(
                      faqs[i].q,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    trailing: isOpen
                        ? const Icon(Icons.remove_circle_outline_rounded,
                            color: AppColors.primary)
                        : const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.onSurfaceVariant),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          faqs[i].a,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required Uri uri,
    bool wide = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(uri, value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(Uri uri, String label) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open $uri: $e');
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $label on this device.')),
      );
    }
  }
}
