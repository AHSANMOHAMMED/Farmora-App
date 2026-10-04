import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../data/logistics_fleet_service.dart';
import '../domain/logistics_vehicle.dart';
import '../domain/logistics_branch.dart';
import '../domain/fleet_driver_info.dart';
import 'widgets/logistics_fleet_map_view.dart';
import 'widgets/vehicle_maintenance_sheet.dart';
import 'widgets/hub_cold_storage_card.dart';
import 'widgets/driver_shift_log_sheet.dart';
import 'widgets/emergency_breakdown_dialog.dart';

class LogisticsFleetHubScreen extends StatefulWidget {
  const LogisticsFleetHubScreen({super.key});

  @override
  State<LogisticsFleetHubScreen> createState() => _LogisticsFleetHubScreenState();
}

class _LogisticsFleetHubScreenState extends State<LogisticsFleetHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LogisticsFleetService _service = LogisticsFleetService();

  List<LogisticsVehicle> _vehicles = [];
  List<LogisticsBranch> _branches = [];
  List<FleetDriverInfo> _drivers = [];

  static const List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
    'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
    'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
    'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
    'Trincomalee', 'Vavuniya',
  ];

  static const Map<String, List<double>> _districtCoords = {
    'Colombo': [6.9271, 79.8612],
    'Gampaha': [7.0917, 79.9999],
    'Kalutara': [6.5854, 79.9607],
    'Kandy': [7.2906, 80.6337],
    'Matale': [7.4675, 80.6234],
    'Nuwara Eliya': [6.9497, 80.7891],
    'Galle': [6.0535, 80.2210],
    'Matara': [5.9549, 80.5550],
    'Hambantota': [6.1429, 81.1212],
    'Jaffna': [9.6615, 80.0255],
    'Kilinochchi': [9.3803, 80.3770],
    'Mannar': [8.9810, 79.9044],
    'Vavuniya': [8.7542, 80.4982],
    'Mullaitivu': [9.2671, 80.8142],
    'Batticaloa': [7.7310, 81.6747],
    'Ampara': [7.2975, 81.6720],
    'Trincomalee': [8.5874, 81.2152],
    'Kurunegala': [7.4863, 80.3623],
    'Puttalam': [8.0333, 79.8333],
    'Anuradhapura': [8.3114, 80.4037],
    'Polonnaruwa': [7.9403, 81.0188],
    'Badulla': [6.9934, 81.0550],
    'Monaragala': [6.8728, 81.3507],
    'Ratnapura': [6.7056, 80.3847],
    'Kegalle': [7.2513, 80.3464],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final transporterId = state.currentUserId.isNotEmpty
        ? state.currentUserId
        : 'demo';

    return StreamBuilder<List<LogisticsBranch>>(
      stream: _service.streamBranches(transporterId),
      builder: (context, branchSnap) {
        _branches = branchSnap.data ?? LogisticsFleetService.defaultBranches(transporterId);

        return StreamBuilder<List<LogisticsVehicle>>(
          stream: _service.streamVehicles(transporterId),
          builder: (context, vehSnap) {
            _vehicles = vehSnap.data ?? LogisticsFleetService.defaultVehicles(transporterId);

            return StreamBuilder<List<FleetDriverInfo>>(
              stream: _service.streamDrivers(transporterId),
              builder: (context, drvSnap) {
                _drivers = drvSnap.data ?? LogisticsFleetService.defaultDrivers(transporterId);

                return Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'Fleet & Hub Management',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                        ),
                        tooltip: 'Roadside Breakdown & Relief',
                        onPressed: () => EmergencyBreakdownDialog.show(
                          context,
                          transporterId: transporterId,
                          vehicles: _vehicles,
                        ),
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.onSurfaceVariant,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.local_shipping_rounded),
                          text: 'Vehicles (${_vehicles.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.store_mall_directory_rounded),
                          text: 'Branches (${_branches.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.badge_rounded),
                          text: 'Drivers (${_drivers.length})',
                        ),
                        const Tab(
                          icon: Icon(Icons.map_rounded),
                          text: 'Live Fleet Map',
                        ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVehiclesTab(transporterId),
                      _buildBranchesTab(transporterId),
                      _buildDriversTab(transporterId),
                      LogisticsFleetMapView(
                        branches: _branches,
                        vehicles: _vehicles,
                        drivers: _drivers,
                      ),
                    ],
                  ),
                  floatingActionButton: _buildFab(transporterId),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget? _buildFab(String transporterId) {
    if (_tabController.index == 3) return null; // No FAB on Map tab
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        _tabController.index == 0
            ? 'Add Vehicle'
            : (_tabController.index == 1 ? 'Add Branch' : 'Add Driver'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        if (_tabController.index == 0) {
          _showAddVehicleDialog(transporterId);
        } else if (_tabController.index == 1) {
          _showAddBranchDialog(transporterId);
        } else if (_tabController.index == 2) {
          _showAddDriverDialog(transporterId);
        }
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: FLEET VEHICLES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildVehiclesTab(String transporterId) {
    if (_vehicles.isEmpty) {
      return const Center(child: Text('No vehicles added yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: v.isRefrigerated
                            ? Colors.cyan.withValues(alpha: 0.15)
                            : AppColors.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        v.isRefrigerated
                            ? Icons.ac_unit_rounded
                            : Icons.local_shipping_rounded,
                        color: v.isRefrigerated ? Colors.cyan[800] : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.registrationNumber,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            v.modelName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(v.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.scale_rounded,
                        label: 'Capacity',
                        value: '${(v.capacityKg / 1000).toStringAsFixed(1)} Tons (${v.capacityKg.toInt()} kg)',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.ac_unit_rounded,
                        label: 'Cold Chain',
                        value: v.isRefrigerated ? 'Reefer Box (Yes)' : 'Standard (No)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Assigned Driver',
                        value: v.assignedDriverName ?? 'Unassigned',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Stationed Branch',
                        value: v.stationedBranchName ?? 'Main Depot',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.build_circle_outlined, size: 16),
                    label: const Text('Maintenance & Telemetry'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    onPressed: () => VehicleMaintenanceSheet.show(context, v),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: BRANCHES & HUBS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBranchesTab(String transporterId) {
    if (_branches.isEmpty) {
      return const Center(child: Text('No branches added yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _branches.length,
      itemBuilder: (context, index) {
        final b = _branches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.blue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${b.district} District • ${b.address}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.person_rounded,
                        label: 'Manager',
                        value: '${b.managerName} (${b.managerPhone})',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.warehouse_rounded,
                        label: 'Storage Capacity',
                        value: '${b.storageCapacityTons.toInt()} Tons ${b.hasColdStorage ? "(Cold)" : ""}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Stationed Fleet',
                        value: '${b.vehicleCount} Vehicles',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.location_on_outlined,
                        label: 'GPS Coordinates',
                        value: '${b.latitude.toStringAsFixed(4)}, ${b.longitude.toStringAsFixed(4)}',
                      ),
                    ),
                  ],
                ),
                if (b.hasColdStorage) ...[
                  const SizedBox(height: 8),
                  HubColdStorageCard(branch: b),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: FLEET DRIVERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDriversTab(String transporterId) {
    if (_drivers.isEmpty) {
      return const Center(child: Text('No drivers registered yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final d = _drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tel: ${d.phone} • Lic: ${d.licenseNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(d.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Assigned Vehicle',
                        value: d.assignedVehicleReg ?? 'Unassigned',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Stationed Branch',
                        value: d.stationedBranchName ?? 'Regional Depot',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        icon: Icons.card_membership_rounded,
                        label: 'License Class',
                        value: d.licenseClass,
                      ),
                    ),
                    Expanded(
                      child: _infoItem(
                        icon: Icons.star_rate_rounded,
                        label: 'Performance Rating',
                        value: '★ ${d.rating.toStringAsFixed(1)} / 5.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: const Text('Duty Shifts & Hours'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.teal,
                      side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
                    ),
                    onPressed: () => DriverShiftLogSheet.show(context, d),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS: ADD VEHICLE / BRANCH / DRIVER
  // ══════════════════════════════════════════════════════════════════════════

  void _showAddVehicleDialog(String transporterId) {
    final regCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '3500');
    String type = 'mini_truck';
    bool reefer = false;
    String? selectedBranchId = _branches.isNotEmpty ? _branches.first.id : null;
    String? selectedDriverId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
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
                    const Text(
                      'Add New Fleet Vehicle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: regCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number (e.g. WP-NA-4512)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Model Name (e.g. Isuzu Elf 3.5T)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mini_truck', child: Text('Mini Truck (1.5T)')),
                        DropdownMenuItem(value: 'heavy_lorry', child: Text('Heavy Commercial Lorry (6T+)')),
                        DropdownMenuItem(value: 'refrigerated_truck', child: Text('Refrigerated Reefer Truck')),
                        DropdownMenuItem(value: 'pickup_van', child: Text('Pickup Van / Utility')),
                        DropdownMenuItem(value: 'three_wheeler', child: Text('Three Wheeler Delivery')),
                        DropdownMenuItem(value: 'tractor', child: Text('Agri Tractor & Trailer')),
                      ],
                      onChanged: (v) => setSheetState(() => type = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Equipped with Cold Storage (Reefer Box)'),
                      value: reefer,
                      onChanged: (v) => setSheetState(() => reefer = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Stationed Branch Depot',
                        border: OutlineInputBorder(),
                      ),
                      items: _branches.map((b) {
                        return DropdownMenuItem(value: b.id, child: Text(b.name));
                      }).toList(),
                      onChanged: (v) => setSheetState(() => selectedBranchId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Driver (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None (Assign Later)')),
                        ..._drivers.map((d) {
                          return DropdownMenuItem(value: d.id, child: Text(d.name));
                        }),
                      ],
                      onChanged: (v) => setSheetState(() => selectedDriverId = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () async {
                          if (regCtrl.text.trim().isEmpty) return;
                          final b = _branches.firstWhere(
                            (b) => b.id == selectedBranchId,
                            orElse: () => _branches.first,
                          );
                          final d = selectedDriverId != null
                              ? _drivers.firstWhere((d) => d.id == selectedDriverId)
                              : null;
                          final newVehicle = LogisticsVehicle(
                            id: 'veh_${DateTime.now().millisecondsSinceEpoch}',
                            transporterId: transporterId,
                            registrationNumber: regCtrl.text.trim().toUpperCase(),
                            vehicleType: type,
                            modelName: modelCtrl.text.trim().isNotEmpty
                                ? modelCtrl.text.trim()
                                : 'Commercial Vehicle',
                            capacityKg: double.tryParse(capCtrl.text.trim()) ?? 2500,
                            isRefrigerated: reefer,
                            stationedBranchId: b.id,
                            stationedBranchName: b.name,
                            assignedDriverId: d?.id,
                            assignedDriverName: d?.name,
                            currentLat: b.latitude,
                            currentLng: b.longitude,
                            updatedAt: DateTime.now(),
                          );
                          await _service.saveVehicle(newVehicle);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Save Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBranchDialog(String transporterId) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final mgrNameCtrl = TextEditingController();
    final mgrPhoneCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '100');
    String selectedDistrict = 'Matale';
    bool coldStorage = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
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
                    const Text(
                      'Add New Logistics Branch / Depot',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name (e.g. Dambulla Central Depot)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(),
                      ),
                      items: _districts.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (v) => setSheetState(() => selectedDistrict = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mgrNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manager Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mgrPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Manager Phone (e.g. 0771234567)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Storage Capacity (Metric Tons)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Cold Storage Facility Available'),
                      value: coldStorage,
                      onChanged: (v) => setSheetState(() => coldStorage = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final coords = _districtCoords[selectedDistrict] ?? [7.8731, 80.7718];
                          final newBranch = LogisticsBranch(
                            id: 'br_${DateTime.now().millisecondsSinceEpoch}',
                            transporterId: transporterId,
                            name: nameCtrl.text.trim(),
                            district: selectedDistrict,
                            address: addressCtrl.text.trim().isNotEmpty
                                ? addressCtrl.text.trim()
                                : '$selectedDistrict Main Road',
                            latitude: coords[0],
                            longitude: coords[1],
                            managerName: mgrNameCtrl.text.trim().isNotEmpty
                                ? mgrNameCtrl.text.trim()
                                : 'Station Manager',
                            managerPhone: mgrPhoneCtrl.text.trim().isNotEmpty
                                ? mgrPhoneCtrl.text.trim()
                                : '0770000000',
                            hasColdStorage: coldStorage,
                            storageCapacityTons: double.tryParse(capCtrl.text.trim()) ?? 50.0,
                            updatedAt: DateTime.now(),
                          );
                          await _service.saveBranch(newBranch);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Save Branch', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDriverDialog(String transporterId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licCtrl = TextEditingController();
    String licClass = 'Heavy Commercial Vehicle (Class C)';
    String? selectedBranchId = _branches.isNotEmpty ? _branches.first.id : null;
    String? selectedVehicleId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
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
                    const Text(
                      'Register Fleet Driver',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Driver Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (e.g. 0771234567)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: licCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License Number (e.g. B-7489123)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: licClass,
                      decoration: const InputDecoration(
                        labelText: 'License Class',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Heavy Commercial Vehicle (Class C)', child: Text('Heavy Commercial (Class C)')),
                        DropdownMenuItem(value: 'Heavy Commercial Vehicle (Class C1)', child: Text('Heavy Commercial (Class C1)')),
                        DropdownMenuItem(value: 'Light Commercial Vehicle (Class B)', child: Text('Light Commercial (Class B)')),
                        DropdownMenuItem(value: 'Dual Purpose Commercial (Class B)', child: Text('Dual Purpose Commercial')),
                      ],
                      onChanged: (v) => setSheetState(() => licClass = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Stationed Branch',
                        border: OutlineInputBorder(),
                      ),
                      items: _branches.map((b) {
                        return DropdownMenuItem(value: b.id, child: Text(b.name));
                      }).toList(),
                      onChanged: (v) => setSheetState(() => selectedBranchId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Vehicle (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None (Assign Later)')),
                        ..._vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.registrationNumber} (${v.modelName})'),
                          );
                        }),
                      ],
                      onChanged: (v) => setSheetState(() => selectedVehicleId = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final b = _branches.firstWhere(
                            (b) => b.id == selectedBranchId,
                            orElse: () => _branches.first,
                          );
                          final v = selectedVehicleId != null
                              ? _vehicles.firstWhere((veh) => veh.id == selectedVehicleId)
                              : null;
                          final newDriver = FleetDriverInfo(
                            id: 'drv_${DateTime.now().millisecondsSinceEpoch}',
                            transporterId: transporterId,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '0770000000',
                            licenseNumber: licCtrl.text.trim().isNotEmpty ? licCtrl.text.trim() : 'B-0000000',
                            licenseClass: licClass,
                            status: 'available',
                            stationedBranchId: b.id,
                            stationedBranchName: b.name,
                            assignedVehicleId: v?.id,
                            assignedVehicleReg: v?.registrationNumber,
                            currentLat: b.latitude,
                            currentLng: b.longitude,
                            rating: 5.0,
                            updatedAt: DateTime.now(),
                          );
                          await _service.saveDriver(newDriver);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Save Driver', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String text = status.toUpperCase();
    switch (status) {
      case 'available':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green[800]!;
        break;
      case 'on_trip':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange[800]!;
        break;
      case 'maintenance':
      case 'off_duty':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red[800]!;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey[800]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
