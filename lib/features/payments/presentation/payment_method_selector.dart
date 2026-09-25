import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'order_payment_card.dart' show paymentMethodIcon;

/// Checkout choice between Cash on Delivery and Bank Deposit.
///
/// Bank Deposit is disabled unless every farmer in the cart has bank details.
class PaymentMethodSelector extends StatefulWidget {
  const PaymentMethodSelector({super.key});

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  String _cartKey = '';
  Future<bool>? _bankAvailable;

  Future<bool> _checkBank(FarmoraState state) {
    final key = state.cartItems.map((c) => c.product.farmerId).toSet().join(',');
    if (key != _cartKey || _bankAvailable == null) {
      _cartKey = key;
      _bankAvailable = state.cartSupportsBankDeposit().then((ok) {
        if (!ok && state.paymentMethodDraft == PaymentMethod.bankDeposit) {
          state.setPaymentMethodDraft(PaymentMethod.cod);
        }
        return ok;
      }).catchError((_) => false);
    }
    return _bankAvailable!;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    return FutureBuilder<bool>(
      future: _checkBank(state),
      builder: (context, snap) {
        final bankOk = snap.data ?? false;
        final checking = snap.connectionState != ConnectionState.done;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment method',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _option(
                    state,
                    method: PaymentMethod.cod,
                    title: 'Cash on Delivery',
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _option(
                    state,
                    method: PaymentMethod.bankDeposit,
                    title: 'Bank Deposit',
                    enabled: bankOk,
                  ),
                ),
              ],
            ),
            if (!checking && !bankOk)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Bank deposit is unavailable: a farmer in your cart has not added bank details.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            if (state.paymentMethodDraft == PaymentMethod.bankDeposit)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "You'll see the farmer's bank details on the order. Upload the deposit slip in the order chat.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _option(
    FarmoraState state, {
    required String method,
    required String title,
    required bool enabled,
  }) {
    final selected = state.paymentMethodDraft == method;
    final color = !enabled
        ? AppColors.outline
        : selected
            ? AppColors.primary
            : AppColors.onSurface;
    return InkWell(
      onTap: enabled ? () => state.setPaymentMethodDraft(method) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(paymentMethodIcon(method), size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
