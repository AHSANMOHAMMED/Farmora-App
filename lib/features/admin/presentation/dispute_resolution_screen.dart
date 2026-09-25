import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';

class DisputeResolutionScreen extends StatefulWidget {
  const DisputeResolutionScreen({super.key});

  @override
  State<DisputeResolutionScreen> createState() =>
      _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  String _selectedFilter = 'Open';

  String _filterLabel(AppLocalizations l, String filter) => switch (filter) {
        'Open' => l.statusOpen,
        'Resolved' => l.statusResolved,
        _ => l.commonAll,
      };

  String _emptyLabel(AppLocalizations l) => switch (_selectedFilter) {
        'Open' => l.adminDisputeNoneOpen,
        'Resolved' => l.adminDisputeNoneResolved,
        _ => l.adminDisputeNoneAll,
      };

  String _escrowStatusLabel(AppLocalizations l, String raw) => switch (raw) {
        'released' => l.adminDisputeStatusReleased,
        'settled_split' => l.adminDisputeStatusSplit,
        _ => statusLabel(raw, l),
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final allOrders = state.orders;
    final disputedOrders = allOrders
        .where((o) => o.disputeId != null && o.disputeId!.isNotEmpty)
        .toList();

    final filtered = disputedOrders.where((o) {
      final isResolved = o.paymentStatus == 'refunded' ||
          o.paymentStatus == 'released' ||
          o.paymentStatus == 'settled_split';
      if (_selectedFilter == 'Open') return !isResolved;
      if (_selectedFilter == 'Resolved') return isResolved;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          l.adminDisputeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              runSpacing: 8,
              children: ['Open', 'Resolved', 'All'].map((tab) {
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(l, tab)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = tab),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerLow,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel_rounded,
                            size: 48,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _emptyLabel(l),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _buildDisputeCard(context, order, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(
      BuildContext context, FarmoraOrder order, FarmoraState state) {
    final l = context.l10n;
    final isResolved = order.paymentStatus == 'refunded' ||
        order.paymentStatus == 'released' ||
        order.paymentStatus == 'settled_split';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isResolved ? AppColors.outlineVariant : Colors.orange.shade300,
          width: isResolved ? 1 : 1.5,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (isResolved ? l.statusResolved : l.statusDisputed)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isResolved
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.orderNumber.isNotEmpty
                            ? order.orderNumber
                            : order.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.displayTotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.productName.isNotEmpty ? order.productName : order.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l.adminDisputeReference(order.disputeId ?? ''),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.adminDisputeClaimReason,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.adminDisputeDefaultReason,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.adminDisputeEscrowStatus(
                        _escrowStatusLabel(l, order.paymentStatus)),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isResolved)
                  FilledButton.icon(
                    icon: const Icon(Icons.gavel_rounded, size: 16),
                    label: Text(l.adminDisputeArbitrate),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        _showArbitrationModal(context, order, state),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l.statusSettled,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArbitrationModal(
      BuildContext context, FarmoraOrder order, FarmoraState state) {
    final l = context.l10n;
    String resolution = 'refund_buyer';
    final notesCtrl =
        TextEditingController(text: l.adminDisputeDefaultNotes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l.adminDisputeArbitrateTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l.commonClose,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.adminDisputeOrderAmount(order.orderNumber, order.displayTotal),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                l.adminDisputeSelectOutcome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: resolution,
                onChanged: (v) =>
                    setModalState(() => resolution = v ?? 'refund_buyer'),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(l.adminDisputeRefundTitle),
                      subtitle: Text(l.adminDisputeRefundSubtitle),
                      value: 'refund_buyer',
                      activeColor: AppColors.primary,
                    ),
                    RadioListTile<String>(
                      title: Text(l.adminDisputeReleaseTitle),
                      subtitle: Text(l.adminDisputeReleaseSubtitle),
                      value: 'release_farmer',
                      activeColor: AppColors.primary,
                    ),
                    RadioListTile<String>(
                      title: Text(l.adminDisputeSplitTitle),
                      subtitle: Text(l.adminDisputeSplitSubtitle),
                      value: 'split_settlement',
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l.adminDisputeNotesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (notesCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.adminDisputeNotesRequired),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await state.resolveDisputeArbitration(
                        orderId: order.id,
                        resolution: resolution,
                        adminNotes: notesCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.adminDisputeRecorded)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l.adminDisputeResolveFailed)),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l.adminDisputeRecordDecision),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
