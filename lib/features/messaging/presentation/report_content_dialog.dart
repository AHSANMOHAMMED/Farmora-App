import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';

/// Asks for a reason and files a `reports` document for admins to review:
/// `{reporterId, targetType, targetId, reason, details, createdAt}` (+ an
/// optional `orderId` for context). Shows the outcome in a SnackBar and
/// returns true when the report was saved.
Future<bool> showReportContentDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String? orderId,
  String title = 'Report user',
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      targetType: targetType,
      targetId: targetId,
      orderId: orderId,
      title: title,
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report sent. Farmora support will review it.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
  return saved == true;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.targetType,
    required this.targetId,
    required this.title,
    this.orderId,
  });

  final String targetType;
  final String targetId;
  final String? orderId;
  final String title;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = {
    'spam': 'Spam or scam',
    'abuse': 'Abusive or offensive',
    'fraud': 'Fraud or fake listing',
    'other': 'Something else',
  };

  final _details = TextEditingController();
  String _reason = 'spam';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw AppException(L10n.current.errorSignInAgain);
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': uid,
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'reason': _reason,
        'details': _details.text.trim(),
        if (widget.orderId != null && widget.orderId!.isNotEmpty)
          'orderId': widget.orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = userMessage(e, action: 'send the report'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in _reasons.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _reason == entry.key,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _reason = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              enabled: !_busy,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(context.l10n.report),
        ),
      ],
    );
  }
}
