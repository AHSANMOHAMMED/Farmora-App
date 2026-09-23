import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
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
        title: const Text(
          'Buyer Offers',
          style: TextStyle(
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
                    '${state.pendingOffersCount} Pending',
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
                _buildFilterChip('all', 'All (${allOffers.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'pending',
                  'Pending (${allOffers.where((o) => o.status == 'pending').length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'countered',
                  'Countered (${allOffers.where((o) => o.status == 'countered').length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'accepted',
                  'Accepted (${allOffers.where((o) => o.status == 'accepted').length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'rejected',
                  'Rejected (${allOffers.where((o) => o.status == 'rejected').length})',
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
              emptyMessage: 'No offers matching this filter',
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
                      : 'Produce Order Offer',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildStatusBadge(offer.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Buyer: ${offer.buyerId.isNotEmpty ? offer.buyerId : "Verified Buyer"}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.proposedQuantity} kg',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offer Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LKR ${offer.proposedPrice.toStringAsFixed(2)} /kg',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Value',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LKR ${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
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
                    child: const Text('Reject'),
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
                    child: const Text('Counter'),
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
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

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
          const SnackBar(
            content: Text('Offer accepted! New order created in Orders.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
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
        title: const Text('Reject Offer?'),
        content: Text(
          'Are you sure you want to decline this offer for ${offer.proposedQuantity} kg of ${offer.productName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await state.rejectOffer(offer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offer rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
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
            child: const Text('Decline'),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Send Counter Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: ${offer.productName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Quantity: ${offer.proposedQuantity} kg'),
              Text(
                  'Buyer Offer: LKR ${offer.proposedPrice.toStringAsFixed(2)} /kg'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Your Counter Price (LKR / kg)',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
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
                    const Text('New Total:'),
                    Text(
                      'LKR ${currentCalc.toStringAsFixed(2)}',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(controller.text);
                if (newPrice == null || newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid counter price'),
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
                          'Counter offer sent: LKR ${newPrice.toStringAsFixed(2)} /kg',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending counter offer: $e'),
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
              child: const Text('Submit Counter'),
            ),
          ],
        ),
      ),
    );
  }
}
