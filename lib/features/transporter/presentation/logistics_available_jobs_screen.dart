import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../application/transporter_controller.dart';
import '../domain/collection_job.dart';
import 'collection_job_details_screen.dart';
import 'widgets/collection_job_card.dart';
import 'widgets/transporter_states.dart';

class LogisticsAvailableJobsScreen extends StatefulWidget {
  const LogisticsAvailableJobsScreen({super.key});

  @override
  State<LogisticsAvailableJobsScreen> createState() =>
      _LogisticsAvailableJobsScreenState();
}

class _LogisticsAvailableJobsScreenState
    extends State<LogisticsAvailableJobsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.transporterAvailableJobsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.transporterRefreshJobs,
            onPressed:
                state.isRefreshing ? null : () => state.loadJobs(refresh: true),
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            searchController: _searchController,
            state: state,
            onPickDate: () => _pickDate(context, state),
            onClear: () {
              _searchController.clear();
              state.clearFilters();
            },
          ),
          Expanded(child: _JobsBody(state: state)),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TransporterController state,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      initialDate: state.selectedDate ?? now,
    );
    if (date != null) state.updateDate(date);
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchController;
  final TransporterController state;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  const _Filters({
    required this.searchController,
    required this.state,
    required this.onPickDate,
    required this.onClear,
  });

  /// Display label for a filter option; the "all" sentinels stay English
  /// inside the controller and are translated only here.
  static String _optionLabel(AppLocalizations l10n, String value) =>
      switch (value) {
        'All locations' => l10n.transporterAllLocations,
        'All destinations' => l10n.transporterAllDestinations,
        'All produce' => l10n.transporterAllProduce,
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFilters = state.searchQuery.isNotEmpty ||
        state.selectedLocation != 'All locations' ||
        state.selectedDelivery != 'All destinations' ||
        state.selectedProduce != 'All produce' ||
        state.selectedDate != null ||
        state.selectedStatus != null ||
        state.suitableOnly;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: state.updateSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.transporterSearchJobsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.transporterClearSearch,
                      onPressed: () {
                        searchController.clear();
                        state.updateSearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedLocation),
                  initialValue: state.selectedLocation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.transporterPickupArea,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: state.locationOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_optionLabel(l10n, value),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: state.updateLocation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedProduce),
                  initialValue: state.selectedProduce,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.transporterProduceLabel,
                    prefixIcon: const Icon(Icons.eco_outlined),
                  ),
                  items: state.produceOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_optionLabel(l10n, value),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: state.updateProduce,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedDelivery),
                  initialValue: state.selectedDelivery,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.transporterDestinationLabel,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  items: state.deliveryOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_optionLabel(l10n, value),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: state.updateDelivery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<CollectionJobStatus>(
                  key: ValueKey(state.selectedStatus),
                  initialValue: state.selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.status,
                    prefixIcon: const Icon(Icons.filter_alt_outlined),
                  ),
                  items: [
                    DropdownMenuItem<CollectionJobStatus>(
                      value: null,
                      child: Text(l10n.transporterAllStatuses,
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...CollectionJobStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child:
                            Text(status.label, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: state.updateStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    state.selectedDate == null
                        ? l10n.transporterAnyCollectionDate
                        : AppFormat.date(state.selectedDate!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onClear, child: Text(l10n.clear)),
              ],
            ],
          ),
          if (state.vehicleCapacity != null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: state.suitableOnly,
              onChanged: (value) => state.updateSuitableOnly(value ?? false),
              title: Text(l10n.transporterSuitableForMyVehicle),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }
}

class _JobsBody extends StatelessWidget {
  final TransporterController state;

  const _JobsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError != null) {
      return TransporterErrorState(
        message: state.loadError!,
        onRetry: state.loadJobs,
      );
    }
    final jobs = state.availableJobs;
    if (jobs.isEmpty) {
      return TransporterEmptyState(
        icon: Icons.search_off_rounded,
        title: context.l10n.transporterNoMatchingJobs,
        message: context.l10n.transporterNoMatchingJobsHint,
        actionLabel: context.l10n.transporterClearFilters,
        onAction: state.clearFilters,
      );
    }
    return RefreshIndicator(
      onRefresh: () => state.loadJobs(refresh: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        itemCount: jobs.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 10 : 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              context.l10n.transporterOpenJobsCount(jobs.length),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          final job = jobs[index - 1];
          return CollectionJobCard(
            job: job,
            score: state.suitabilityFor(job),
            onViewDetails: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CollectionJobDetailsScreen(jobId: job.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
