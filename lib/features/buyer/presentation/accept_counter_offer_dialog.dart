import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/offer.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'transporter_picker_dialog.dart';

/// Buyer accepts a farmer's counter-offer. Accepting creates the order, so
/// this collects the delivery address, payment method and transporter, then
/// calls `acceptOffer`. Returns true when the order was created.
Future<bool> showAcceptCounterOfferDialog(
    BuildContext context, FarmoraOffer offer) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AcceptCounterOfferDialog(offer: offer),
  );
  return ok ?? false;
}

class _AcceptCounterOfferDialog extends StatefulWidget {
  const _AcceptCounterOfferDialog({required this.offer});

  final FarmoraOffer offer;

  @override
  State<_AcceptCounterOfferDialog> createState() =>
      _AcceptCounterOfferDialogState();
}

class _AcceptCounterOfferDialogState extends State<_AcceptCounterOfferDialog> {
  late final TextEditingController _address;
  String _method = PaymentMethod.cod;
  bool? _bankAvailable;
  Map<String, dynamic>? _transporter;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _address = TextEditingController(text: state.deliveryAddressDraft);
    _checkBank(state);
  }

  Future<void> _checkBank(FarmoraState state) async {
    try {
      final ok = await state.farmerAcceptsBankDeposit(widget.offer.farmerId);
      if (mounted) setState(() => _bankAvailable = ok);
    } catch (e, st) {
      userMessage(e, action: 'check bank deposit availability', stack: st);
      if (mounted) setState(() => _bankAvailable = false);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickTransporter() async {
    final picked = await pickTransporter(context);
    if (picked != null && mounted) setState(() => _transporter = picked);
  }

  Future<void> _submit() async {
    final address = _address.text.trim();
    if (address.length < 5) {
      setState(() => _error = context.l10n.buyerEnterAddressToOrder);
      return;
    }
    final transporterId = _transporter?['uid']?.toString() ?? '';
    if (transporterId.isEmpty) {
      setState(() => _error = 'Choose a transporter for this delivery.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<FarmoraState>().acceptOffer(
            widget.offer.id,
            deliveryAddress: address,
            paymentMethod: _method,
            transporterId: transporterId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = userMessage(e, action: 'accept the counter-offer', stack: st);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offer = widget.offer;
    final unit = offer.unit.isEmpty ? 'kg' : offer.unit;
    return AlertDialog(
      title: Text(l.acceptCounter),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${offer.productName}: ${AppFormat.number(offer.proposedQuantity)} $unit × '
              '${AppFormat.lkr(offer.proposedPrice, decimals: 2)}/$unit = '
              '${AppFormat.lkr(offer.totalPrice, decimals: 2)}',
              style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'A delivery fee is added to the order total.',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _address,
              enabled: !_submitting,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.buyerDeliveryAddress,
                hintText: l.buyerDeliveryAddressHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(l.payMethodTitle,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.payMethodCod),
                  selected: _method == PaymentMethod.cod,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _method = PaymentMethod.cod),
                ),
                ChoiceChip(
                  label: Text(l.payMethodBankDeposit),
                  selected: _method == PaymentMethod.bankDeposit,
                  onSelected: _submitting || _bankAvailable != true
                      ? null
                      : (_) => setState(
                          () => _method = PaymentMethod.bankDeposit),
                ),
              ],
            ),
            if (_bankAvailable != true)
              Text(
                _bankAvailable == null
                    ? 'Checking bank deposit availability…'
                    : 'Bank deposit unavailable: this farmer has not added bank details.',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickTransporter,
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: Text(
                _transporter == null
                    ? 'Choose transporter'
                    : (_transporter!['displayName'] ?? 'Transporter')
                        .toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l.placeOrder),
        ),
      ],
    );
  }
}
