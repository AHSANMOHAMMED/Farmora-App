import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/offer.dart';
import '../../../providers/farmora_state.dart';
import 'buyer_products_screen.dart';
import 'buyer_orders_screen.dart';

class BuyerOffersScreen extends StatefulWidget {
  const BuyerOffersScreen({super.key});

  @override
  State<BuyerOffersScreen> createState() => _BuyerOffersScreenState();
}

class _BuyerOffersScreenState extends State<BuyerOffersScreen> {
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Countered, 3: Accepted, 4: Rejected

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
            Text(
              l10n.myOffers,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
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
                  '${state.pendingOffersCount} Active',
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
                        const Text(
                          'Direct Price Negotiation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Propose custom prices and bulk quantities directly to local farmers.',
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
                  _buildFilterPill(0, 'All (${allOffers.length})'),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, 'Pending (${allOffers.where((o) => o.status == 'pending').length})'),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, 'Countered (${allOffers.where((o) => o.status == 'countered').length})'),
                  const SizedBox(width: 8),
                  _buildFilterPill(3, 'Accepted (${allOffers.where((o) => o.status == 'accepted').length})'),
                  const SizedBox(width: 8),
                  _buildFilterPill(4, 'Declined'),
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
                      const Text(
                        'No Offers Found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Find fresh produce in the marketplace and propose your price.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
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
                        label: const Text('Make an Offer on Crops'),
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
              Text(
                offer.id.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              _buildOfferStatusBadge(offer.status),
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
                      offer.productName.isNotEmpty ? offer.productName : 'Agricultural Crop',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested: ${offer.proposedQuantity} kg',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proposed Unit Price',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LKR ${offer.proposedPrice.toStringAsFixed(0)} / kg',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Contract Value',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LKR ${(offer.proposedPrice * offer.proposedQuantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
                      'Farmer offered counter-proposal: LKR ${offer.proposedPrice.toStringAsFixed(0)}/kg.',
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
                    onPressed: () => state.rejectOffer(offer.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await state.acceptOffer(offer.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Counter offer accepted! Order created.'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept Counter'),
                  ),
                ),
              ],
            ),
          ] else if (isPending) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => state.cancelOffer(offer.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Withdraw Offer', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ] else if (isAccepted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
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
                  label: const Text('View in Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferStatusBadge(String status) {
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
            status.toUpperCase(),
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
