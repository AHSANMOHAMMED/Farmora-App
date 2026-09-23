import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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

  final List<Map<String, String>> _templates = [
    {
      'title': 'Heavy Monsoon Rainfall Warning',
      'message':
          'Department of Meteorology warns of heavy rainfall across Nuwara Eliya and Badulla districts. Expect transport delays along mountain corridors.',
      'role': 'all',
      'priority': 'emergency',
    },
    {
      'title': 'Dambulla Pola Festive Market Schedule',
      'message':
          'Dambulla Dedicated Economic Center will operate special extended trading hours this weekend. Transporters are advised to book loading bays early.',
      'role': 'farmer',
      'priority': 'important',
    },
    {
      'title': 'Fertilizer & Pesticide Subsidy Advisory',
      'message':
          'Agrarian Services Department has updated certified organic fertilizer distribution centers across Central and Southern provinces.',
      'role': 'farmer',
      'priority': 'normal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Broadcast Advisories & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            const Text(
              'Quick AgriTech Templates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates.map((tmpl) {
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
                    const Text(
                      'Compose Announcement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Advisory Headline',
                        hintText: 'e.g. Flash Flood Alert in Nuwara Eliya',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.campaign_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Message',
                        hintText:
                            'Provide actionable details for farmers, buyers, or transporters...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _targetRole,
                            decoration: const InputDecoration(
                              labelText: 'Target Audience',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('All Users')),
                              DropdownMenuItem(
                                  value: 'farmer', child: Text('Farmers Only')),
                              DropdownMenuItem(
                                  value: 'buyer', child: Text('Buyers Only')),
                              DropdownMenuItem(
                                  value: 'transporter',
                                  child: Text('Transporters Only')),
                            ],
                            onChanged: (v) =>
                                setState(() => _targetRole = v ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority Level',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'normal', child: Text('Normal (Info)')),
                              DropdownMenuItem(
                                  value: 'important',
                                  child: Text('Important')),
                              DropdownMenuItem(
                                  value: 'emergency',
                                  child: Text('🚨 Emergency Alert')),
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
                        label: Text(_sending
                            ? 'Broadcasting...'
                            : 'Send Broadcast Notification'),
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
                                    const SnackBar(
                                      content: Text(
                                          'Please enter both title and message.'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _sending = true);
                                await state.broadcastPlatformAdvisory(
                                  title: _titleCtrl.text.trim(),
                                  message: _messageCtrl.text.trim(),
                                  targetRole: _targetRole,
                                  priority: _priority,
                                );
                                setState(() => _sending = false);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Advisory successfully broadcasted to users!'),
                                    ),
                                  );
                                  _titleCtrl.clear();
                                  _messageCtrl.clear();
                                }
                              },
                      ),
                    ),
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
