import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../core/widgets/job_card.dart';
import '../../../models/transport_job.dart';
import 'transport_request_detail_screen.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Nearby', 'High Fee', 'Today'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final availableJobs = state.availableJobs;
    final filteredJobs = _applyFilters(availableJobs);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Available Jobs',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: AppColors.surfaceContainerLow,
                    selectedColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Job count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filteredJobs.length} jobs available',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Jobs list
          Expanded(
            child: filteredJobs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: AppColors.outlineVariant,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No jobs available',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check back later for new opportunities',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredJobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final j = filteredJobs[index];
                      return JobCard(
                        title: j.title,
                        route: j.route,
                        detail: j.detail,
                        fee: j.fee,
                        accepted: j.accepted,
                        onAccept: () => context.read<FarmoraState>().assignJobToMe(j.id),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransportRequestDetailScreen(job: j),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<TransportJob> _applyFilters(List<TransportJob> jobs) {
    switch (_selectedFilter) {
      case 'Nearby':
        return jobs.take(5).toList();
      case 'High Fee':
        final sorted = List<TransportJob>.from(jobs);
        sorted.sort((a, b) => b.fee.compareTo(a.fee));
        return sorted;
      case 'Today':
        return jobs.where((j) {
          final detail = j.detail.toLowerCase();
          return detail.contains('today') || detail.contains('now');
        }).toList();
      default:
        return jobs;
    }
  }
}
