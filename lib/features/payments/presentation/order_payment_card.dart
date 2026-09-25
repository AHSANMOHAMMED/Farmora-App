import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/bank_details.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../messaging/presentation/conversations_screen.dart';

StatusChipType paymentChipType(PaymentState state) => switch (state) {
      PaymentState.pending => StatusChipType.pending,
      PaymentState.proofSubmitted => StatusChipType.active,
      PaymentState.paid => StatusChipType.approved,
      PaymentState.rejected => StatusChipType.rejected,
      PaymentState.refunded => StatusChipType.empty,
      PaymentState.disputed => StatusChipType.rejected,
    };

IconData paymentMethodIcon(String method) => switch (method) {
      PaymentMethod.bankDeposit => Icons.account_balance_outlined,
      PaymentMethod.payHere => Icons.credit_card_outlined,
      _ => Icons.payments_outlined,
    };

/// Payment section of an order detail screen, for either side of the deal.
///
/// Farmer: "Mark Cash Received" (COD, after delivery) or Confirm / Reject for a
/// submitted deposit slip. Buyer: what to pay, where, and what happens next.
class OrderPaymentCard extends StatefulWidget {
  final FarmoraOrder order;
  final bool viewerIsFarmer;

  const OrderPaymentCard({
    super.key,
    required this.order,
    required this.viewerIsFarmer,
  });

  @override
  State<OrderPaymentCard> createState() => _OrderPaymentCardState();
}

class _OrderPaymentCardState extends State<OrderPaymentCard> {
  bool _busy = false;
  double? _uploadProgress;
  PickedImage? _failedSlip;

  FarmoraOrder get _order => widget.order;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success),
        backgroundColor: AppColors.primary,
      ));
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(userMessage(e, action: 'update the payment', stack: st)),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markCashReceived() async {
    final ok = await _confirmDialog(
      title: 'Mark cash received?',
      body: 'Confirm you received ${_order.displayTotal} in cash from '
          '${_order.buyerName.isNotEmpty ? _order.buyerName : 'the buyer'}. '
          'This adds it to your earnings and cannot be undone.',
      action: 'Cash received',
    );
    if (ok != true || !mounted) return;
    final state = context.read<FarmoraState>();
    await _run(() => state.markCashReceived(_order.id), 'Cash payment recorded.');
  }

  Future<void> _confirmPayment() async {
    final ok = await _confirmDialog(
      title: 'Confirm payment?',
      body: 'Only confirm after you see ${_order.displayTotal} in your bank '
          'account. This adds it to your earnings.',
      action: 'Confirm payment',
    );
    if (ok != true || !mounted) return;
    final state = context.read<FarmoraState>();
    await _run(() => state.confirmBankPayment(_order.id), 'Payment confirmed.');
  }

  Future<void> _rejectPayment() async {
    final reason = await showRejectReasonDialog(context);
    if (reason == null || !mounted) return;
    final state = context.read<FarmoraState>();
    await _run(() => state.rejectBankPayment(_order.id, reason),
        'Receipt rejected. The buyer has been notified.');
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  /// Buyer: take/select a deposit slip photo and submit it.
  Future<void> _pickAndUploadReceipt() async {
    final source =
        await showImageSourceSheet(context, title: 'Upload deposit slip');
    if (source == null || !mounted) return;
    final PickedImage? image;
    try {
      image = await ImagePickerHelper().pickOne(source: source);
    } catch (e, st) {
      _snack(userMessage(e, action: 'open the photo', stack: st), error: true);
      return;
    }
    if (image == null || !mounted) return; // cancelled
    await _uploadReceipt(image);
  }

  Future<void> _uploadReceipt(PickedImage image) async {
    final state = context.read<FarmoraState>();
    setState(() {
      _busy = true;
      _uploadProgress = 0;
      _failedSlip = null;
    });
    try {
      final chatError = await state.submitPaymentSlip(
        order: _order,
        image: image,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      _snack(chatError == null
          ? 'Receipt sent to the farmer for confirmation.'
          : 'Receipt submitted, but it could not be posted in chat: $chatError');
    } catch (e, st) {
      if (mounted) setState(() => _failedSlip = image);
      _snack(userMessage(e, action: 'upload the receipt', stack: st),
          error: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _uploadProgress = null;
        });
      }
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.primary,
    ));
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationsScreen(orderId: _order.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              StatusChip(
                label: _order.paymentStatusLabel,
                type: paymentChipType(_order.paymentState),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(paymentMethodIcon(_order.paymentMethod),
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  PaymentMethod.label(_order.paymentMethod),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                _order.displayTotal,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _guidance(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (_order.paymentState == PaymentState.rejected &&
              (_order.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _Notice(
              icon: Icons.error_outline,
              color: AppColors.statusRejectedText,
              background: AppColors.statusRejectedBg,
              text: 'Receipt rejected: ${_order.rejectionReason}',
            ),
          ],
          if (!widget.viewerIsFarmer &&
              _order.isBankDeposit &&
              _order.bankDetailsSnapshot != null &&
              !_order.isPaid) ...[
            const SizedBox(height: 14),
            BankDetailsPanel(details: _order.bankDetailsSnapshot!),
          ],
          if (_order.isBankDeposit && (_order.proofImageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Open deposit slip',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showImageViewer(context,
                    url: _order.proofImageUrl!, title: 'Deposit slip'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: SafeImage(
                            path: _order.proofImageUrl!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Tap to view',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_uploadProgress != null) ...[
            const SizedBox(height: 14),
            Text(
              'Uploading receipt... ${(_uploadProgress! * 100).round()}%',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: _uploadProgress! > 0 ? _uploadProgress : null,
              color: AppColors.primary,
            ),
          ],
          ..._actions(),
        ],
      ),
    );
  }

  String _guidance() {
    final farmer = widget.viewerIsFarmer;
    switch (_order.paymentState) {
      case PaymentState.paid:
        final when = _order.paidAt;
        return when == null
            ? 'Payment received.'
            : 'Payment received on ${when.day}/${when.month}/${when.year}.';
      case PaymentState.proofSubmitted:
        return farmer
            ? 'The buyer uploaded a deposit slip. Check your bank account before confirming.'
            : 'Receipt sent. Waiting for the farmer to confirm the deposit.';
      case PaymentState.rejected:
        return farmer
            ? 'Waiting for the buyer to upload a new receipt.'
            : 'Please upload a new receipt.';
      case PaymentState.refunded:
        return 'This payment was refunded.';
      case PaymentState.disputed:
        return 'Payment is on hold while the dispute is reviewed.';
      case PaymentState.pending:
        if (_order.isCancelled) return 'Order cancelled — no payment due.';
        if (_order.isBankDeposit) {
          return farmer
              ? 'Waiting for the buyer to deposit and upload the slip.'
              : 'Deposit the total to the account below, then upload a photo of the slip.';
        }
        return farmer
            ? (_order.isCompleted
                ? 'Delivered. Mark the cash as received once you have it.'
                : 'The buyer pays cash on delivery.')
            : 'Pay the farmer in cash when your order is delivered.';
    }
  }

  List<Widget> _actions() {
    final buttons = <Widget>[];
    if (widget.viewerIsFarmer && _order.canMarkCashReceived) {
      buttons.add(SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy ? null : _markCashReceived,
          icon: _busyIcon(Icons.payments_outlined),
          label: const Text('Mark Cash Received'),
        ),
      ));
    }
    if (widget.viewerIsFarmer && _order.canReviewProof) {
      buttons.add(Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _rejectPayment,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.errorContainer, width: 2),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirmPayment,
              icon: _busyIcon(Icons.check_circle_outline),
              label: const Text('Confirm Payment'),
            ),
          ),
        ],
      ));
    }
    if (!widget.viewerIsFarmer && _order.canSubmitProof) {
      final retry = _failedSlip;
      buttons.add(SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy
              ? null
              : (retry != null
                  ? () => _uploadReceipt(retry)
                  : _pickAndUploadReceipt),
          icon: _busy
              ? _busyIcon(Icons.upload)
              : Icon(retry != null ? Icons.refresh : Icons.receipt_long_outlined,
                  size: 18),
          label: Text(retry != null
              ? 'Retry Upload'
              : _order.paymentState == PaymentState.pending
                  ? 'Upload Payment Receipt'
                  : 'Upload New Receipt'),
        ),
      ));
      if (retry != null) {
        buttons.add(Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _busy ? null : () => setState(() => _failedSlip = null),
            child: const Text('Choose a different photo'),
          ),
        ));
      }
    }
    if (_order.buyerId.isNotEmpty && _order.farmerId.isNotEmpty) {
      buttons.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: Text(widget.viewerIsFarmer ? 'Message Buyer' : 'Message Farmer'),
        ),
      ));
    }
    return [
      for (final b in buttons) ...[const SizedBox(height: 14), b],
    ];
  }

  Widget _busyIcon(IconData icon) => _busy
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Icon(icon, size: 18);
}

/// Asks the farmer why a receipt is rejected. Returns null when cancelled.
Future<String?> showRejectReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final valid = controller.text.trim().length >= 3;
        return AlertDialog(
          title: const Text('Reject receipt'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Reason (shown to the buyer)',
              hintText: 'e.g. Amount does not match / slip is unreadable',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed:
                  valid ? () => Navigator.pop(ctx, controller.text.trim()) : null,
              child: const Text('Reject'),
            ),
          ],
        );
      },
    ),
  );
}

/// Farmer's bank account as the buyer needs it to make a deposit.
class BankDetailsPanel extends StatelessWidget {
  final BankDetails details;

  const BankDetailsPanel({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Bank', details.bankName),
          _row('Branch', details.branch),
          _row('Account name', details.accountHolderName),
          Row(
            children: [
              Expanded(child: _row('Account no.', details.accountNumber)),
              IconButton(
                tooltip: 'Copy account number',
                icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: details.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  const _Notice({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Lets the user choose camera or gallery. Returns null when dismissed.
Future<ImageSource?> showImageSourceSheet(BuildContext context,
    {String title = 'Add photo'}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
