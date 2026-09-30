import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/farmora_state.dart';
import '../../../models/transport_job.dart';
import '../../../services/delivery_location_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';

class LogisticsManagementScreen extends StatefulWidget {
  const LogisticsManagementScreen({super.key});

  @override
  State<LogisticsManagementScreen> createState() =>
      _LogisticsManagementScreenState();
}

class _LogisticsManagementScreenState extends State<LogisticsManagementScreen> {
  String _selectedStatus = 'all';
  bool _actionBusy = false;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'intransit':
      case 'in_transit':
      case 'pickedup':
        return const Color(0xFF1B6BD8);
      case 'assigned':
      case 'accepted':
        return const Color(0xFFF57C00);
      case 'requested':
      default:
        return const Color(0xFF7B1FA2);
    }
  }

  // ── Admin action helpers ─────────────────────────────────────────────────

  /// Admin cancels an active transport job.
  Future<void> _adminCancelJob(
      BuildContext context, FarmoraState state, TransportJob job) async {
    final l = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l.adminLogisticsCancelJobTitle,
      message: l.adminLogisticsCancelJobMessage,
      confirmLabel: l.adminLogisticsCancelJobAction,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _actionBusy = true);
    try {
      await state.updateJobStatus(job.id, 'cancelled');
      if (context.mounted) _snack(context, l.adminLogisticsJobCancelled);
    } catch (error) {
      if (context.mounted) {
        _snack(context, userMessage(error, action: 'cancel the job'),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  /// Admin reassigns job back to the open pool (removes transporterId).
  Future<void> _adminReassignJob(
      BuildContext context, FarmoraState state, TransportJob job) async {
    final l = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l.adminLogisticsReassignTitle,
      message: l.adminLogisticsReassignMessage,
      confirmLabel: l.adminLogisticsReassignAction,
      destructive: false,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _actionBusy = true);
    try {
      // Transition back to 'requested' and clear the transporter assignment.
      await state.updateJobStatus(job.id, 'requested');
      if (context.mounted) _snack(context, l.adminLogisticsJobReassigned);
    } catch (error) {
      if (context.mounted) {
        _snack(context, userMessage(error, action: 'reassign the job'),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  /// Admin force-marks an active job as delivered.
  Future<void> _adminForceDeliver(
      BuildContext context, FarmoraState state, TransportJob job) async {
    final l = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l.adminLogisticsForceDeliverTitle,
      message: l.adminLogisticsForceDeliverMessage,
      confirmLabel: l.adminLogisticsForceDeliver,
      destructive: false,
    );
    if (!confirmed || !context.mounted) return;
    setState(() => _actionBusy = true);
    try {
      await state.updateJobStatus(job.id, 'delivered');
      if (context.mounted) _snack(context, l.adminLogisticsJobDelivered);
    } catch (error) {
      if (context.mounted) {
        _snack(context, userMessage(error, action: 'mark the job delivered'),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void _snack(BuildContext context, String message,
      {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ));
  }

  // ── Detail bottom sheet ──────────────────────────────────────────────────

  void _showJobDetail(BuildContext context, TransportJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AdminJobDetailSheet(
        job: job,
        actionBusy: _actionBusy,
        statusColor: _statusColor(job.status),
        onCancel: (job.isCancelled || job.isDelivered)
            ? null
            : () {
                Navigator.pop(ctx);
                _adminCancelJob(context, context.read<FarmoraState>(), job);
              },
        onReassign: (job.isCancelled ||
                job.isDelivered ||
                job.status == 'requested' ||
                job.transporterId == null ||
                job.transporterId!.isEmpty)
            ? null
            : () {
                Navigator.pop(ctx);
                _adminReassignJob(context, context.read<FarmoraState>(), job);
              },
        onForceDeliver: (job.isDelivered ||
                job.isCancelled ||
                job.status == 'requested')
            ? null
            : () {
                Navigator.pop(ctx);
                _adminForceDeliver(context, context.read<FarmoraState>(), job);
              },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();

    final totalJobs = state.jobs.length;
    final activeShipments = state.jobs
        .where((j) =>
            j.isActive || j.status == 'inTransit' || j.status == 'pickedUp')
        .length;
    final completedShipments = state.jobs
        .where((j) => j.isDelivered || j.status == 'delivered')
        .length;
    final requestedShipments =
        state.jobs.where((j) => j.status == 'requested').length;

    final filtered = state.jobs.where((j) {
      if (_selectedStatus == 'all') return true;
      if (_selectedStatus == 'active') {
        return j.isActive || j.status == 'inTransit' || j.status == 'pickedUp';
      }
      if (_selectedStatus == 'completed') {
        return j.isDelivered || j.status == 'delivered';
      }
      return j.status.toLowerCase() == _selectedStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          // Fleet KPI Overview
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FleetKpiCard(
                        title: l.adminLogisticsActiveInTransit,
                        value: l.adminLogisticsHauls(activeShipments),
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF1B6BD8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FleetKpiCard(
                        title: l.adminLogisticsAwaitingPickup,
                        value: l.adminLogisticsJobs(requestedShipments),
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FleetKpiCard(
                        title: l.statusDelivered,
                        value: l.adminLogisticsTrips(completedShipments),
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                          'all', l.adminLogisticsAllJobs(totalJobs)),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                          'active', l.adminLogisticsActiveInTransit),
                      const SizedBox(width: 6),
                      _buildFilterChip('requested', l.statusRequested),
                      const SizedBox(width: 6),
                      _buildFilterChip('completed', l.statusDelivered),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Shipment Cards List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(l.adminLogisticsEmptyTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l.adminLogisticsEmptyHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final job = filtered[i];
                      final color = _statusColor(job.status);
                      return Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showJobDetail(context, job),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusLabel(job.status, l)
                                              .toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        job.orderId ?? job.id,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        job.fee.isNotEmpty
                                            ? job.fee
                                            : l.adminLogisticsNotSet,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.route_rounded,
                                        size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        job.route.isNotEmpty
                                            ? job.route
                                            : l.adminLogisticsCentralCorridor,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.scale_rounded,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        job.weightKg != null
                                            ? l.adminLogisticsKgLoad(
                                                '${job.weightKg}')
                                            : (job.detail.isNotEmpty
                                                ? job.detail
                                                : l.adminLogisticsCapacity),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = key),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}

// ── Detail sheet widget ────────────────────────────────────────────────────

class _AdminJobDetailSheet extends StatelessWidget {
  const _AdminJobDetailSheet({
    required this.job,
    required this.actionBusy,
    required this.statusColor,
    this.onCancel,
    this.onReassign,
    this.onForceDeliver,
  });

  final TransportJob job;
  final bool actionBusy;
  final Color statusColor;
  final VoidCallback? onCancel;
  final VoidCallback? onReassign;
  final VoidCallback? onForceDeliver;

  Widget _milestoneRow(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted ? AppColors.textPrimary : Colors.grey,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final load = job.weightKg != null
        ? l.adminLogisticsWeightKg('${job.weightKg}')
        : (job.detail.isNotEmpty ? job.detail : l.adminLogisticsStandardCrates);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel(job.status, l).toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.id,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.grey.shade600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            job.route.isNotEmpty ? job.route : l.adminLogisticsDefaultRoute,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (job.orderId != null && job.orderId!.isNotEmpty) ...[
            Text(l.adminLogisticsLinkedOrder(job.orderId!),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 4),
          ],
          Text(l.adminLogisticsCargoLoad(load),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),

          // Live GPS panel for active hauls
          if (job.hasCourierLocation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DeliveryLocationService.isLocationFresh(
                        job.locationUpdatedAt)
                    ? const Color(0xFFE8F5E9)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DeliveryLocationService.isLocationFresh(
                          job.locationUpdatedAt)
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    DeliveryLocationService.isLocationFresh(
                            job.locationUpdatedAt)
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    size: 18,
                    color: DeliveryLocationService.isLocationFresh(
                            job.locationUpdatedAt)
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DeliveryLocationService.isLocationFresh(
                              job.locationUpdatedAt)
                          ? l.adminLogisticsGpsLive(
                              job.courierLat!.toStringAsFixed(4),
                              job.courierLng!.toStringAsFixed(4))
                          : l.adminLogisticsGpsLast(
                              job.courierLat!.toStringAsFixed(4),
                              job.courierLng!.toStringAsFixed(4)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(l.adminLogisticsFee,
                    style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Text(
                job.fee.isNotEmpty ? job.fee : l.adminLogisticsNotSet,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.adminLogisticsMilestones,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _milestoneRow(l.adminLogisticsMilestoneRequested, true),
          _milestoneRow(
            l.adminLogisticsMilestonePickup,
            const {'pickedUp', 'inTransit', 'delivered'}.contains(job.status),
          ),
          _milestoneRow(l.adminLogisticsMilestoneDelivered, job.isDelivered),

          // ── Admin Actions ────────────────────────────────────────────────
          if (onCancel != null ||
              onReassign != null ||
              onForceDeliver != null) ...[
            const Divider(height: 24),
            Text(l.adminLogisticsActions,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReassign != null)
                  OutlinedButton.icon(
                    onPressed: actionBusy ? null : onReassign,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(l.adminLogisticsReassignAction),
                  ),
                if (onForceDeliver != null)
                  OutlinedButton.icon(
                    onPressed: actionBusy ? null : onForceDeliver,
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: Text(l.adminLogisticsForceDeliver),
                  ),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: actionBusy ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(l.adminLogisticsCancelJobAction),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l.commonClose),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI card widget ────────────────────────────────────────────────────────

class _FleetKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FleetKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
