import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/logistics_fleet_service.dart';
import '../../domain/logistics_vehicle.dart';
import '../../domain/vehicle_maintenance_record.dart';

class VehicleMaintenanceSheet extends StatefulWidget {
  final LogisticsVehicle vehicle;

  const VehicleMaintenanceSheet({
    super.key,
    required this.vehicle,
  });

  static Future<void> show(BuildContext context, LogisticsVehicle vehicle) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleMaintenanceSheet(vehicle: vehicle),
    );
  }

  @override
  State<VehicleMaintenanceSheet> createState() =>
      _VehicleMaintenanceSheetState();
}

class _VehicleMaintenanceSheetState extends State<VehicleMaintenanceSheet> {
  final LogisticsFleetService _service = LogisticsFleetService();
  late Stream<List<VehicleMaintenanceRecord>> _recordsStream;

  @override
  void initState() {
    super.initState();
    _recordsStream = _service.streamMaintenanceRecords(widget.vehicle.id);
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
                  Icons.build_circle_rounded,
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
                      'Fleet Maintenance Logs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.vehicle.registrationNumber} • ${widget.vehicle.vehicleType.toUpperCase()}',
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
            child: StreamBuilder<List<VehicleMaintenanceRecord>>(
              stream: _recordsStream,
              builder: (context, snapshot) {
                final records = snapshot.data ??
                    LogisticsFleetService.defaultMaintenanceRecords(
                        widget.vehicle.id);

                if (records.isEmpty) {
                  return const Center(
                    child: Text(
                      'No maintenance logs recorded for this vehicle.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = records[index];
                    return _buildRecordCard(item);
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
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Log Maintenance Event',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showAddRecordDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(VehicleMaintenanceRecord item) {
    final statusColor = item.isCompleted ? Colors.green : Colors.orange;

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
                item.serviceTypeDisplayName,
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
                  item.isCompleted ? 'COMPLETED' : 'IN SERVICE',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
                'LKR ${item.costLkr.toStringAsFixed(0)} • ${item.garageName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${item.odometerKm.toStringAsFixed(0)} km',
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

  void _showAddRecordDialog(BuildContext context) {
    final typeCtrl = TextEditingController(text: 'oil_change');
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final garageCtrl = TextEditingController(text: 'Dambulla Fleet Works');
    final odoCtrl = TextEditingController(text: '52000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Maintenance Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service Notes',
                  hintText: 'e.g. Engine oil & air filter replacement',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Cost (LKR)',
                  hintText: 'e.g. 24000',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: odoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Odometer (km)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: garageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Garage / Service Center',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final record = VehicleMaintenanceRecord(
                id: 'maint_${DateTime.now().millisecondsSinceEpoch}',
                vehicleId: widget.vehicle.id,
                vehicleReg: widget.vehicle.registrationNumber,
                serviceType: typeCtrl.text.trim(),
                garageName: garageCtrl.text.trim(),
                costLkr: double.tryParse(costCtrl.text.trim()) ?? 15000.0,
                serviceDate: DateTime.now(),
                odometerKm: double.tryParse(odoCtrl.text.trim()) ?? 50000.0,
                notes: descCtrl.text.trim(),
                isCompleted: true,
              );

              await _service.saveMaintenanceRecord(record);
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }
}
