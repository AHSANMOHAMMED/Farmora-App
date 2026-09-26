import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';

class BroadcastAdvisoryScreen extends StatefulWidget {
  const BroadcastAdvisoryScreen({super.key});

  @override
  State<BroadcastAdvisoryScreen> createState() =>
      _BroadcastAdvisoryScreenState();
}

class _BroadcastAdvisoryScreenState extends State<BroadcastAdvisoryScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _targetRole = 'all';
  String _priority = 'normal';
  bool _sending = false;
  int? _lastRecipients;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  /// Ready-made advisories, written in the admin's current language.
  List<Map<String, String>> _templates(AppLocalizations l) => [
        {
          'title': l.adminBroadcastTplRainTitle,
          'message': l.adminBroadcastTplRainMessage,
          'role': 'all',
          'priority': 'emergency',
        },
        {
          'title': l.adminBroadcastTplPolaTitle,
          'message': l.adminBroadcastTplPolaMessage,
          'role': 'farmer',
          'priority': 'important',
        },
        {
          'title': l.adminBroadcastTplSubsidyTitle,
          'message': l.adminBroadcastTplSubsidyMessage,
          'role': 'farmer',
          'priority': 'normal',
        },
      ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          l.adminBroadcastTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Advisory Templates
            Text(
              l.adminBroadcastTemplates,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates(l).map((tmpl) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      avatar: const Icon(Icons.bolt_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text(tmpl['title']!),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      onPressed: () {
                        setState(() {
                          _titleCtrl.text = tmpl['title']!;
                          _messageCtrl.text = tmpl['message']!;
                          _targetRole = tmpl['role']!;
                          _priority = tmpl['priority']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Broadcast Form Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.adminBroadcastCompose,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: l.adminBroadcastHeadline,
                        hintText: l.adminBroadcastHeadlineHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.campaign_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l.adminBroadcastMessage,
                        hintText: l.adminBroadcastMessageHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('audience-$_targetRole'),
                            initialValue: _targetRole,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l.adminBroadcastAudience,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              for (final (value, label) in [
                                ('all', l.allUsers),
                                ('farmer', l.adminBroadcastFarmersOnly),
                                ('buyer', l.adminBroadcastBuyersOnly),
                                ('transporter', l.adminBroadcastTransportersOnly),
                              ])
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: _sending
                                ? null
                                : (v) =>
                                    setState(() => _targetRole = v ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('priority-$_priority'),
                            initialValue: _priority,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l.adminBroadcastPriority,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              for (final (value, label) in [
                                ('normal', l.adminBroadcastPriorityNormal),
                                ('important', l.important),
                                ('emergency', l.adminBroadcastPriorityEmergency),
                              ])
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _priority = v ?? 'normal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _sending
                              ? l.adminBroadcastSending
                              : l.adminBroadcastSend,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _priority == 'emergency'
                              ? Colors.red.shade700
                              : AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _sending
                            ? null
                            : () async {
                                if (_titleCtrl.text.trim().isEmpty ||
                                    _messageCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(l.adminBroadcastMissingFields),
                                    ),
                                  );
                                  return;
                                }

                                final messenger =
                                    ScaffoldMessenger.of(context);
                                setState(() => _sending = true);
                                try {
                                  final recipients =
                                      await state.broadcastPlatformAdvisory(
                                    title: _titleCtrl.text.trim(),
                                    message: _messageCtrl.text.trim(),
                                    targetRole: _targetRole,
                                    priority: _priority,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _sending = false;
                                    _lastRecipients = recipients;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${l.adminBroadcastSent} '
                                          '($recipients recipients)'),
                                    ),
                                  );
                                  _titleCtrl.clear();
                                  _messageCtrl.clear();
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _sending = false);
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(userMessage(e,
                                          action: 'broadcast the advisory')),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    if (_lastRecipients != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Last advisory delivered to '
                              '$_lastRecipients recipient'
                              '${_lastRecipients == 1 ? '' : 's'}.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
