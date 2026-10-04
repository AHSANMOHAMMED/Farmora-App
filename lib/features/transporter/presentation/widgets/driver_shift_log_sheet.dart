import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/logistics_fleet_service.dart';
import '../../domain/driver_shift_record.dart';
import '../../domain/fleet_driver_info.dart';

class DriverShiftLogSheet extends StatefulWidget {
  final FleetDriverInfo driver;

  const DriverShiftLogSheet({
    super.key,
    required this.driver,
  });

  static Future<void> show(BuildContext context, FleetDriverInfo driver) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverShiftLogSheet(driver: driver),
    );
  }

  @override
  State<DriverShiftLogSheet> createState() => _DriverShiftLogSheetState();
}

class _DriverShiftLogSheetState extends State<DriverShiftLogSheet> {
  final LogisticsFleetService _service = LogisticsFleetService();
  late Stream<List<DriverShiftRecord>> _shiftsStream;

  @override
  void initState() {
    super.initState();
    _shiftsStream = _service.streamDriverShifts(widget.driver.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Shifts & Duty Hours',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.driver.name} • License: ${widget.driver.licenseNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<DriverShiftRecord>>(
              stream: _shiftsStream,
              builder: (context, snapshot) {
                final shifts = snapshot.data ??
                    LogisticsFleetService.defaultDriverShifts(widget.driver.id);

                if (shifts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No shift logs recorded for this driver.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = shifts[index];
                    return _buildShiftCard(item);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'Start / Check-in New Shift',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _startShiftDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(DriverShiftRecord item) {
    Color statusColor;
    if (item.isActive) {
      statusColor = Colors.green;
    } else if (item.isOnBreak) {
      statusColor = Colors.orange;
    } else {
      statusColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.branchName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (item.assignedVehicleReg != null) ...[
            const SizedBox(height: 4),
            Text(
              'Assigned: ${item.assignedVehicleReg}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.notes,
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driving: ${item.drivingHours.toStringAsFixed(1)} hrs • Rest: ${item.restHours.toStringAsFixed(1)} hrs',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${item.completedTripsCount} Trips',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startShiftDialog(BuildContext context) {
    final noteCtrl =
        TextEditingController(text: 'Routine inter-district transit shift');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start shift for ${widget.driver.name}?'),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Shift Notes / Route',
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
              final newShift = DriverShiftRecord(
                id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
                driverId: widget.driver.id,
                driverName: widget.driver.name,
                branchId: widget.driver.stationedBranchId ?? 'main_hub',
                branchName:
                    widget.driver.stationedBranchName ?? 'Regional Transport Hub',
                checkInTime: DateTime.now(),
                status: 'active',
                notes: noteCtrl.text.trim(),
              );

              await _service.saveDriverShift(newShift);
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Confirm Start'),
          ),
        ],
      ),
    );
  }
}
