import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/logistics_fleet_service.dart';
import '../../domain/hub_cold_storage_log.dart';
import '../../domain/logistics_branch.dart';

class HubColdStorageCard extends StatelessWidget {
  final LogisticsBranch branch;
  final LogisticsFleetService _service = LogisticsFleetService();

  HubColdStorageCard({
    super.key,
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    if (!branch.hasColdStorage) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<HubColdStorageLog>>(
      stream: _service.streamColdStorageLogs(branch.id),
      builder: (context, snapshot) {
        final logs =
            snapshot.data ?? LogisticsFleetService.defaultColdStorageLogs(branch.id);

        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.ac_unit_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Depot Cold Storage Telemetry',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${branch.storageCapacityTons.toStringAsFixed(0)}T Cap',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...logs.map((log) => _buildChamberRow(context, log)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChamberRow(BuildContext context, HubColdStorageLog log) {
    final isBreached = log.isBreached;
    final statusColor = isBreached ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.roomName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Safe range: ${log.minSafeTempC}°C - ${log.maxSafeTempC}°C • Humidity: ${log.relativeHumidityPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBreached
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${log.currentTempC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
