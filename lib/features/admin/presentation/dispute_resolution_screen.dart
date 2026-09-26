import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/dispute_model.dart';
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

  bool _isResolved(Dispute d) =>
      d.status == DisputeStatus.resolved || d.status == DisputeStatus.rejected;

  FarmoraOrder? _orderFor(FarmoraState state, Dispute d) {
    for (final o in state.orders) {
      if (o.id == d.orderId) return o;
    }
    return null;
  }

  String _orderRef(Dispute d, FarmoraOrder? order) {
    if (d.orderNumber.isNotEmpty) return d.orderNumber;
    if (order != null) return order.displayNumber;
    return d.orderId.isNotEmpty ? d.orderId : d.id;
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final disputes = state.disputes;

    final open = disputes.where((d) => !_isResolved(d)).toList();
    final resolved = disputes.where(_isResolved).toList();
    final showSections = _selectedFilter == 'All';
    final filtered = switch (_selectedFilter) {
      'Open' => open,
      'Resolved' => resolved,
      _ => [...open, ...resolved],
    };

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
                final count = switch (tab) {
                  'Open' => open.length,
                  'Resolved' => resolved.length,
                  _ => disputes.length,
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${_filterLabel(l, tab)} ($count)'),
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: showSections
                        ? [
                            if (open.isNotEmpty)
                              _sectionHeader(l.statusOpen, open.length),
                            for (final d in open)
                              _buildDisputeCard(context, d, state),
                            if (resolved.isNotEmpty)
                              _sectionHeader(
                                  l.statusResolved, resolved.length),
                            for (final d in resolved)
                              _buildDisputeCard(context, d, state),
                          ]
                        : [
                            for (final d in filtered)
                              _buildDisputeCard(context, d, state),
                          ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      );

  String _partyName(FarmoraOrder? order, String uid) {
    if (order == null || uid.isEmpty) return uid;
    if (uid == order.buyerId && order.buyerName.isNotEmpty) {
      return '${order.buyerName} (buyer)';
    }
    if (uid == order.farmerId && order.farmerName.isNotEmpty) {
      return '${order.farmerName} (farmer)';
    }
    return uid;
  }

  Widget _buildDisputeCard(
      BuildContext context, Dispute dispute, FarmoraState state) {
    final l = context.l10n;
    final isResolved = _isResolved(dispute);
    final order = _orderFor(state, dispute);
    final openedBy = dispute.userName.isNotEmpty
        ? dispute.userName
        : _partyName(order, dispute.userId);
    final evidence = dispute.evidenceImages ?? const <String>[];
    final statusColor = dispute.getStatusColor();

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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dispute.getStatusDisplayName().toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _orderRef(dispute, order),
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
                if (order != null) ...[
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
              ],
            ),
            const SizedBox(height: 12),
            if (order != null)
              Text(
                order.productName.isNotEmpty ? order.productName : order.title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 4),
            Text(
              l.adminDisputeReference(dispute.id),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              'Opened by ${openedBy.isNotEmpty ? openedBy : '-'}'
              ' · ${_formatDate(dispute.createdAt)}',
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
                  Row(
                    children: [
                      Icon(dispute.getReasonIcon(),
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l.adminDisputeClaimReason} · '
                          '${dispute.getReasonDisplayName()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dispute.description.trim().isNotEmpty
                        ? dispute.description
                        : l.adminDisputeDefaultReason,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (evidence.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Evidence',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: evidence.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _showEvidence(context, evidence[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        evidence[i],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (isResolved &&
                (dispute.adminResponse ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${l.adminDisputeNotesLabel}: ${dispute.adminResponse}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: order == null
                      ? const SizedBox.shrink()
                      : Text(
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
                    onPressed: dispute.orderId.isEmpty
                        ? null
                        : () => _showArbitrationModal(
                            context, dispute, order, state),
                  )
                else
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dispute.resolvedAt != null
                                ? '${l.statusSettled} · '
                                    '${_formatDate(dispute.resolvedAt!)}'
                                : l.statusSettled,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEvidence(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(32),
              child: Icon(Icons.broken_image_outlined, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  void _showArbitrationModal(BuildContext context, Dispute dispute,
      FarmoraOrder? order, FarmoraState state) {
    final l = context.l10n;
    String resolution = 'refund_buyer';
    bool busy = false;
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
          child: SingleChildScrollView(
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
                      onPressed: busy ? null : () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.adminDisputeOrderAmount(
                      _orderRef(dispute, order), order?.displayTotal ?? '-'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text(
                  l.adminDisputeSelectOutcome,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: resolution,
                  onChanged: (v) {
                    if (busy) return;
                    setModalState(() => resolution = v ?? 'refund_buyer');
                  },
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
                  enabled: !busy,
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
                    onPressed: busy
                        ? null
                        : () async {
                            final notes = notesCtrl.text.trim();
                            if (notes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.adminDisputeNotesRequired),
                                ),
                              );
                              return;
                            }
                            setModalState(() => busy = true);
                            try {
                              await state.resolveDisputeArbitration(
                                orderId: dispute.orderId,
                                resolution: resolution,
                                adminNotes: notes,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l.adminDisputeRecorded)),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setModalState(() => busy = false);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(userMessage(e,
                                        action: 'resolve the dispute')),
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l.adminDisputeRecordDecision),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
