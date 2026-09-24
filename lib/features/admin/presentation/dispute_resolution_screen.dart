import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Dispute & Escrow Arbitrator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            child: Row(
              children: ['Open', 'Resolved', 'All'].map((tab) {
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab),
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
                          'No $_selectedFilter disputes.',
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
                Row(
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
                        isResolved ? 'RESOLVED' : 'DISPUTED',
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
                    Text(
                      order.orderNumber.isNotEmpty
                          ? order.orderNumber
                          : order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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
              'Dispute Reference: ${order.disputeId}',
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyer Claim Reason',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Produce quality damaged upon delivery or missing quantity mismatch.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Escrow Status: ${order.paymentStatus}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (!isResolved)
                  FilledButton.icon(
                    icon: const Icon(Icons.gavel_rounded, size: 16),
                    label: const Text('Arbitrate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        _showArbitrationModal(context, order, state),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Settled',
                        style: TextStyle(
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
    String resolution = 'refund_buyer';
    final notesCtrl = TextEditingController(
        text: 'Inspected photographic evidence and verified delivery log.');

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
                  const Text(
                    'Arbitrate Dispute',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order: ${order.orderNumber} · Amount: ${order.displayTotal}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Arbitration Outcome',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: resolution,
                onChanged: (v) =>
                    setModalState(() => resolution = v ?? 'refund_buyer'),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Full Refund to Buyer (100%)'),
                      subtitle:
                          Text('Return locked escrow to buyer. Cancel order.'),
                      value: 'refund_buyer',
                      activeColor: AppColors.primary,
                    ),
                    RadioListTile<String>(
                      title: Text('Release to Farmer (100%)'),
                      subtitle:
                          Text('Dismiss dispute. Payout full funds to farmer.'),
                      value: 'release_farmer',
                      activeColor: AppColors.primary,
                    ),
                    RadioListTile<String>(
                      title: Text('Split Settlement (50% / 50%)'),
                      subtitle:
                          Text('Partial refund to buyer, remainder to farmer.'),
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
                decoration: const InputDecoration(
                  labelText: 'Admin Audit Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (notesCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Add audit notes before resolving this dispute.'),
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
                          const SnackBar(
                              content: Text('Dispute decision recorded.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Could not resolve the dispute. Try again.')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Record Dispute Decision'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
