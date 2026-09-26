import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/offer.dart';
import '../../../providers/farmora_state.dart';
import 'buyer_products_screen.dart';
import 'buyer_orders_screen.dart';
import 'buyer_l10n.dart';
import 'accept_counter_offer_dialog.dart';

class BuyerOffersScreen extends StatefulWidget {
  const BuyerOffersScreen({super.key});

  @override
  State<BuyerOffersScreen> createState() => _BuyerOffersScreenState();
}

class _BuyerOffersScreenState extends State<BuyerOffersScreen> {
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Countered, 3: Accepted, 4: Rejected

  /// Offer ids with a backend call in flight (buttons disabled).
  final Set<String> _busy = {};

  Future<void> _runOfferAction(
    String offerId,
    Future<void> Function() action, {
    required String success,
    required String errorAction,
  }) async {
    if (_busy.contains(offerId)) return;
    setState(() => _busy.add(offerId));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(userMessage(e, action: errorAction, stack: st)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy.remove(offerId));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(title)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _declineCounter(FarmoraState state, FarmoraOffer offer) async {
    final l = context.l10n;
    if (!await _confirm(l.decline, "Decline the farmer's counter-offer?")) {
      return;
    }
    await _runOfferAction(offer.id, () => state.rejectOffer(offer.id),
        success: 'Counter-offer declined.',
        errorAction: 'decline the counter-offer');
  }

  Future<void> _withdraw(FarmoraState state, FarmoraOffer offer) async {
    final l = context.l10n;
    if (!await _confirm(l.buyerWithdrawOffer, 'Withdraw this offer?')) return;
    await _runOfferAction(offer.id, () => state.cancelOffer(offer.id),
        success: 'Offer withdrawn.', errorAction: 'withdraw the offer');
  }

  Future<void> _acceptCounter(FarmoraOffer offer) async {
    if (_busy.contains(offer.id)) return;
    setState(() => _busy.add(offer.id));
    try {
      final ok = await showAcceptCounterOfferDialog(context, offer);
      if (!ok || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.buyerCounterAccepted),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy.remove(offer.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    final allOffers = state.buyerOffers;

    List<FarmoraOffer> filteredOffers;
    switch (_selectedFilter) {
      case 1:
        filteredOffers = allOffers.where((o) => o.status.toLowerCase() == 'pending').toList();
        break;
      case 2:
        filteredOffers = allOffers.where((o) => o.status.toLowerCase() == 'countered').toList();
        break;
      case 3:
        filteredOffers = allOffers.where((o) => o.status.toLowerCase() == 'accepted').toList();
        break;
      case 4:
        filteredOffers = allOffers.where((o) =>
            o.status.toLowerCase() == 'rejected' || o.status.toLowerCase() == 'cancelled').toList();
        break;
      default:
        filteredOffers = allOffers;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Flexible(
              child: Text(
              l10n.myOffers,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            ),
            if (state.pendingOffersCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.buyerActiveOffersCount(state.pendingOffersCount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.buyerNegotiationTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.buyerNegotiationSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Segmented Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill(0, l10n.buyerFilterWithCount(l10n.commonAll, allOffers.length)),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, l10n.buyerFilterWithCount(l10n.statusPending, allOffers.where((o) => o.status == 'pending').length)),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, l10n.buyerFilterWithCount(l10n.statusCountered, allOffers.where((o) => o.status == 'countered').length)),
                  const SizedBox(width: 8),
                  _buildFilterPill(3, l10n.buyerFilterWithCount(l10n.statusAccepted, allOffers.where((o) => o.status == 'accepted').length)),
                  const SizedBox(width: 8),
                  _buildFilterPill(4, l10n.statusDeclined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Offers List
            if (filteredOffers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          size: 36,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.buyerNoOffersFound,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.buyerNoOffersHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BuyerProductsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: Text(l10n.makeAnOfferOnCrops),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOffers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildOfferCard(context, state, filteredOffers[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String title) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A1B9A) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, FarmoraState state, FarmoraOffer offer) {
    final l = context.l10n;
    final unitLabel = buyerUnitLabel(l, offer.unit);
    String perKg(double price) =>
        l.buyerPricePerUnit(AppFormat.lkr(price, decimals: price % 1 == 0 ? 0 : 2), unitLabel);
    final busy = _busy.contains(offer.id);
    final isPending = offer.status.toLowerCase() == 'pending';
    final isCountered = offer.status.toLowerCase() == 'countered';
    final isAccepted = offer.status.toLowerCase() == 'accepted';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCountered
              ? const Color(0xFFFFB300)
              : AppColors.outlineVariant.withValues(alpha: 0.1),
          width: isCountered ? 1.5 : 1.0,
        ),
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
          // Header: Offer ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  offer.id.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildOfferStatusBadge(l, offer.status),
            ],
          ),
          const SizedBox(height: 12),

          // Crop info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, color: Color(0xFF6A1B9A), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.productName.isNotEmpty ? offer.productName : l.buyerAgriculturalCrop,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.buyerOfferRequestedQty(
                        l.buyerQuantityWithUnit(AppFormat.number(offer.proposedQuantity), unitLabel),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price Details Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.buyerProposedUnitPrice,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perKg(offer.proposedPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '× ${AppFormat.number(offer.proposedQuantity)} $unitLabel',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l.buyerTotalContractValue,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormat.lkr(offer.totalPrice, decimals: 2),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ),
              ],
            ),
          ),

          // Counter-Offer Banner
          if (isCountered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.buyerFarmerCounterProposal(perKg(offer.proposedPrice)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          if (isCountered) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _declineCounter(state, offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l.decline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _acceptCounter(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l.acceptCounter),
                  ),
                ),
              ],
            ),
          ] else if (isPending) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _withdraw(state, offer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(l.buyerWithdrawOffer, style: const TextStyle(fontSize: 12)),
                ),
                ),
              ],
            ),
          ] else if (isAccepted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text(l.buyerViewInOrders, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferStatusBadge(AppLocalizations l, String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'accepted':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case 'countered':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        icon = Icons.sync_problem_rounded;
        break;
      case 'rejected':
      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.cancel_rounded;
        break;
      default: // pending
        bgColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF6A1B9A);
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusLabel(status, l),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
