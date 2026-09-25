import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/offer.dart';
import '../../../providers/farmora_state.dart';

class FarmerOffersScreen extends StatefulWidget {
  const FarmerOffersScreen({super.key});

  @override
  State<FarmerOffersScreen> createState() => _FarmerOffersScreenState();
}

class _FarmerOffersScreenState extends State<FarmerOffersScreen> {
  String _selectedFilter = 'all'; // all, pending, accepted, countered, rejected

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l10n = AppLocalizations.of(context);
    final allOffers = state.farmerOffers;

    final filteredOffers = allOffers.where((offer) {
      if (_selectedFilter == 'all') return true;
      return offer.status.toLowerCase() == _selectedFilter;
    }).toList();

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
          l10n.farmerOffersTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          if (state.pendingOffersCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    l10n.farmerOffersPendingCount(state.pendingOffersCount),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                    'all',
                    l10n.farmerOffersFilterLabel(
                        l10n.commonAll, allOffers.length)),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'pending',
                  l10n.farmerOffersFilterLabel(l10n.statusPending,
                      allOffers.where((o) => o.status == 'pending').length),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'countered',
                  l10n.farmerOffersFilterLabel(l10n.statusCountered,
                      allOffers.where((o) => o.status == 'countered').length),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'accepted',
                  l10n.farmerOffersFilterLabel(l10n.statusAccepted,
                      allOffers.where((o) => o.status == 'accepted').length),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'rejected',
                  l10n.farmerOffersFilterLabel(l10n.statusRejected,
                      allOffers.where((o) => o.status == 'rejected').length),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          // Offers List
          Expanded(
            child: AsyncStateView(
              isLoading: state.currentUserId.isNotEmpty && !state.profileLoaded,
              isEmpty: filteredOffers.isEmpty,
              emptyMessage: l10n.farmerOffersEmpty,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOffers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final offer = filteredOffers[index];
                  return _buildOfferCard(context, state, offer, l10n);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = filterKey);
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, FarmoraState state,
      FarmoraOffer offer, AppLocalizations l10n) {
    final bool isActionable =
        offer.status == 'pending' || offer.status == 'countered';
    final totalAmount = offer.proposedPrice * offer.proposedQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActionable
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  offer.productName.isNotEmpty
                      ? offer.productName
                      : l10n.farmerOffersProduceOffer,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildStatusBadge(offer.status, l10n),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.farmerOffersBuyerLine(offer.buyerId.isNotEmpty
                      ? offer.buyerId
                      : l10n.farmerOffersVerifiedBuyer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      l10n.quantity,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      l10n.farmerQuantityKg(
                          AppFormat.number(offer.proposedQuantity)),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      l10n.farmerOffersOfferPrice,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      l10n.farmerPricePerKgValue(
                          AppFormat.lkr(offer.proposedPrice, decimals: 2)),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      l10n.farmerOffersTotalValue,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormat.lkr(totalAmount),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
          if (isActionable) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showRejectDialog(context, state, offer, l10n),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(l10n.reject,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCounterDialog(context, state, offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(l10n.counter,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleAcceptOffer(context, state, offer, l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(l10n.accept,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color bg;
    Color fg;
    final label = statusLabel(status, l10n).toUpperCase();

    switch (status.toLowerCase()) {
      case 'accepted':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      case 'countered':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Future<void> _handleAcceptOffer(BuildContext context, FarmoraState state,
      FarmoraOffer offer, AppLocalizations l10n) async {
    try {
      await state.acceptOffer(offer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.farmerOffersAccepted),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(describeError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, FarmoraState state,
      FarmoraOffer offer, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectOffer),
        content: Text(
          l10n.farmerOffersRejectConfirm(
              AppFormat.number(offer.proposedQuantity), offer.productName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await state.rejectOffer(offer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.offerRejected)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(describeError(e)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.decline),
          ),
        ],
      ),
    );
  }

  void _showCounterDialog(
      BuildContext context, FarmoraState state, FarmoraOffer offer) {
    final controller = TextEditingController(
      text: offer.proposedPrice.toStringAsFixed(0),
    );
    double currentCalc = offer.proposedPrice * offer.proposedQuantity;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.sendCounterOffer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.farmerOffersProductLine(offer.productName),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(l10n.farmerOffersQuantityLine(
                  AppFormat.number(offer.proposedQuantity))),
              Text(l10n.farmerOffersBuyerOfferLine(
                  AppFormat.lkr(offer.proposedPrice, decimals: 2))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.farmerOffersCounterPriceLabel,
                  prefixText: 'LKR ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  setDialogState(() {
                    currentCalc = parsed * offer.proposedQuantity;
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(l10n.newTotal)),
                    const SizedBox(width: 8),
                    Text(
                      AppFormat.lkr(currentCalc, decimals: 2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(controller.text);
                if (newPrice == null || newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.farmerOffersInvalidCounterPrice),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await state.counterOffer(offer.id, newPrice);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.farmerOffersCounterSent(
                              AppFormat.lkr(newPrice, decimals: 2)),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            l10n.farmerOffersCounterFailed(describeError(e))),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(l10n.submitCounter),
            ),
          ],
        ),
      ),
    );
  }
}
