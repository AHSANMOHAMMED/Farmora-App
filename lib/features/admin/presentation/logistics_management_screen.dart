import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../models/transport_job.dart';
import '../../../services/delivery_location_service.dart';
import '../../../core/constants/app_colors.dart';

class LogisticsManagementScreen extends StatefulWidget {
  const LogisticsManagementScreen({super.key});

  @override
  State<LogisticsManagementScreen> createState() =>
      _LogisticsManagementScreenState();
}

class _LogisticsManagementScreenState extends State<LogisticsManagementScreen> {
  String _selectedStatus = 'all';

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

  void _showJobDetail(BuildContext context, TransportJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final color = _statusColor(job.status);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    job.id,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey.shade600,
                        fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                job.route.isNotEmpty ? job.route : 'Supply Corridor Dispatch',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (job.orderId != null && job.orderId!.isNotEmpty) ...[
                Text('Linked Order: ${job.orderId}',
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 4),
              ],
              Text(
                  'Cargo Load: ${job.weightKg != null ? "${job.weightKg} kg" : (job.detail.isNotEmpty ? job.detail : "Standard Agricultural Crates")}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              // Live courier GPS panel for active hauls.
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
                              ? 'Driver GPS LIVE — ${job.courierLat!.toStringAsFixed(4)}, ${job.courierLng!.toStringAsFixed(4)}'
                              : 'Last known driver GPS: ${job.courierLat!.toStringAsFixed(4)}, ${job.courierLng!.toStringAsFixed(4)}',
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
                  const Text('Transporter Fee:',
                      style: TextStyle(fontSize: 14)),
                  Text(
                    job.fee.isNotEmpty ? job.fee : 'LKR 3,500.00',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Transit Milestones',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              _buildMilestoneRow('Pickup / Farm Departure', true),
              _buildMilestoneRow('Highland Supply Highway Checkpoint',
                  job.status != 'requested'),
              _buildMilestoneRow('Destination Central Pola Arrival',
                  job.status == 'delivered' || job.status == 'completed'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestoneRow(String title, bool isCompleted) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isCompleted ? AppColors.textPrimary : Colors.grey,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();

    // Compute fleet metrics
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
                        title: 'Active In-Transit',
                        value: '$activeShipments hauls',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF1B6BD8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FleetKpiCard(
                        title: 'Awaiting Pickup',
                        value: '$requestedShipments jobs',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FleetKpiCard(
                        title: 'Delivered',
                        value: '$completedShipments trips',
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Fleet Jobs ($totalJobs)'),
                      const SizedBox(width: 6),
                      _buildFilterChip('active', 'Active In-Transit'),
                      const SizedBox(width: 6),
                      _buildFilterChip('requested', 'Requested'),
                      const SizedBox(width: 6),
                      _buildFilterChip('completed', 'Delivered'),
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
                          const Text('No Fleet Hauls Found',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('No transport routes match the selected filter.',
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        job.status.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      job.orderId ?? job.id,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const Spacer(),
                                    Text(
                                      job.fee.isNotEmpty
                                          ? job.fee
                                          : 'LKR 3,500',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                          fontSize: 14),
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
                                            : 'Central Supply Corridor',
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
                                    Text(
                                      job.weightKg != null
                                          ? '${job.weightKg} kg load'
                                          : (job.detail.isNotEmpty
                                              ? job.detail
                                              : '500 kg capacity'),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                    const Spacer(),
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
