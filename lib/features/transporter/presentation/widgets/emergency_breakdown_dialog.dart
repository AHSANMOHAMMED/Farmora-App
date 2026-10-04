import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/logistics_fleet_service.dart';
import '../../domain/fleet_breakdown_request.dart';
import '../../domain/logistics_vehicle.dart';

class EmergencyBreakdownDialog extends StatefulWidget {
  final String transporterId;
  final List<LogisticsVehicle> vehicles;

  const EmergencyBreakdownDialog({
    super.key,
    required this.transporterId,
    required this.vehicles,
  });

  static Future<void> show(
    BuildContext context, {
    required String transporterId,
    required List<LogisticsVehicle> vehicles,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EmergencyBreakdownDialog(
        transporterId: transporterId,
        vehicles: vehicles,
      ),
    );
  }

  @override
  State<EmergencyBreakdownDialog> createState() =>
      _EmergencyBreakdownDialogState();
}

class _EmergencyBreakdownDialogState extends State<EmergencyBreakdownDialog> {
  final LogisticsFleetService _service = LogisticsFleetService();

  late String _selectedVehicleId;
  String _failureType = 'cooling_failure';
  String _severity = 'critical_cargo_rescue';
  final TextEditingController _locationCtrl = TextEditingController(
    text: 'A9 Highway near Dambulla Junction',
  );
  final TextEditingController _notesCtrl = TextEditingController(
    text: 'Reefer compressor failure. Fresh vegetable cargo at risk.',
  );
  String? _selectedReliefVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId =
        widget.vehicles.isNotEmpty ? widget.vehicles.first.id : 'veh_01';
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableReliefVehicles = widget.vehicles
        .where((v) => v.id != _selectedVehicleId && v.isAvailable)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Roadside Breakdown Alert',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stranded Vehicle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedVehicleId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.vehicles.map((v) {
                return DropdownMenuItem<String>(
                  value: v.id,
                  child: Text(
                    '${v.registrationNumber} (${v.modelName})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVehicleId = val);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Failure Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _failureType,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cooling_failure',
                  child: Text(
                    'Reefer Cooling Unit Failure',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'engine',
                  child: Text(
                    'Engine / Mechanical Breakdown',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'flat_tire',
                  child: Text(
                    'Tire Puncture / Blowout',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'transmission',
                  child: Text(
                    'Transmission / Gearbox Fault',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'accident',
                  child: Text(
                    'Accident / Road Obstruction',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _failureType = val);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Incident Severity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _severity,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'critical_cargo_rescue',
                  child: Text(
                    'CRITICAL: Cargo Spoilage Risk (Immediate Relief)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'towing_required',
                  child: Text(
                    'MODERATE: Towing Required',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'minor',
                  child: Text(
                    'LOW: Roadside Repair Possible',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _severity = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Current Location / Landmark',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (availableReliefVehicles.isNotEmpty) ...[
              const Text(
                'Assign Relief Vehicle (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                value: _selectedReliefVehicleId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Relief Vehicle Dispatched Yet'),
                  ),
                  ...availableReliefVehicles.map((v) {
                    return DropdownMenuItem<String?>(
                      value: v.id,
                      child: Text(
                        'Dispatch: ${v.registrationNumber} (${v.modelName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (val) =>
                    setState(() => _selectedReliefVehicleId = val),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Dispatcher & Safety Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final targetVeh = widget.vehicles.firstWhere(
              (v) => v.id == _selectedVehicleId,
              orElse: () => widget.vehicles.first,
            );
            final reliefVeh = _selectedReliefVehicleId != null
                ? widget.vehicles.firstWhere(
                    (v) => v.id == _selectedReliefVehicleId,
                  )
                : null;

            final breakdown = FleetBreakdownRequest(
              id: 'bkd_${DateTime.now().millisecondsSinceEpoch}',
              vehicleId: targetVeh.id,
              vehicleReg: targetVeh.registrationNumber,
              driverId: targetVeh.assignedDriverId ?? 'drv_emergency',
              driverName: targetVeh.assignedDriverName ?? 'Active Driver',
              driverPhone: '0771234567',
              latitude: targetVeh.currentLat ?? 7.8742,
              longitude: targetVeh.currentLng ?? 80.6511,
              locationDescription: _locationCtrl.text.trim(),
              failureType: _failureType,
              severity: _severity,
              status: _selectedReliefVehicleId != null
                  ? 'relief_en_route'
                  : 'reported',
              reliefVehicleId: reliefVeh?.id,
              reliefVehicleReg: reliefVeh?.registrationNumber,
              reportedAt: DateTime.now(),
              notes: _notesCtrl.text.trim(),
            );

            await _service.reportBreakdown(breakdown);

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    'Emergency dispatch alert broadcasted for ${targetVeh.registrationNumber}',
                  ),
                ),
              );
            }
          },
          child: const Text('Broadcast Alert'),
        ),
      ],
    );
  }
}
