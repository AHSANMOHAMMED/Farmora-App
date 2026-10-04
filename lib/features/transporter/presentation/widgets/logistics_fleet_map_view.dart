import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/logistics_vehicle.dart';
import '../../domain/logistics_branch.dart';
import '../../domain/fleet_driver_info.dart';

enum FleetMapFilter { all, branches, vehicles, inTransit }

class LogisticsFleetMapView extends StatefulWidget {
  final List<LogisticsBranch> branches;
  final List<LogisticsVehicle> vehicles;
  final List<FleetDriverInfo> drivers;
  final Function(LogisticsBranch)? onBranchSelected;
  final Function(LogisticsVehicle)? onVehicleSelected;

  const LogisticsFleetMapView({
    super.key,
    required this.branches,
    required this.vehicles,
    required this.drivers,
    this.onBranchSelected,
    this.onVehicleSelected,
  });

  @override
  State<LogisticsFleetMapView> createState() => _LogisticsFleetMapViewState();
}

class _LogisticsFleetMapViewState extends State<LogisticsFleetMapView> {
  GoogleMapController? _mapController;
  FleetMapFilter _currentFilter = FleetMapFilter.all;
  dynamic _selectedItem; // LogisticsBranch or LogisticsVehicle

  // Sri Lanka Geographic Center (Dambulla)
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // 1. Branches / Hubs
    if (_currentFilter == FleetMapFilter.all ||
        _currentFilter == FleetMapFilter.branches) {
      for (final branch in widget.branches) {
        markers.add(
          Marker(
            markerId: MarkerId('branch_${branch.id}'),
            position: LatLng(branch.latitude, branch.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: '🏢 ${branch.name}',
              snippet: '${branch.district} • ${branch.address}',
            ),
            onTap: () {
              setState(() => _selectedItem = branch);
              widget.onBranchSelected?.call(branch);
            },
          ),
        );
      }
    }

    // 2. Vehicles / Trucks
    if (_currentFilter == FleetMapFilter.all ||
        _currentFilter == FleetMapFilter.vehicles ||
        _currentFilter == FleetMapFilter.inTransit) {
      for (final vehicle in widget.vehicles) {
        if (_currentFilter == FleetMapFilter.inTransit && !vehicle.isOnTrip) {
          continue;
        }
        final lat = vehicle.currentLat ?? 7.8742;
        final lng = vehicle.currentLng ?? 80.6511;
        final hue = vehicle.isOnTrip
            ? BitmapDescriptor.hueOrange
            : (vehicle.isRefrigerated
                ? BitmapDescriptor.hueCyan
                : BitmapDescriptor.hueGreen);

        markers.add(
          Marker(
            markerId: MarkerId('vehicle_${vehicle.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: '🚚 ${vehicle.registrationNumber} (${vehicle.modelName})',
              snippet: 'Driver: ${vehicle.assignedDriverName ?? "Unassigned"} • ${vehicle.status.toUpperCase()}',
            ),
            onTap: () {
              setState(() => _selectedItem = vehicle);
              widget.onVehicleSelected?.call(vehicle);
            },
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    // Draw route lines connecting on-trip vehicles to their stationed branches
    for (final vehicle in widget.vehicles) {
      if (vehicle.isOnTrip &&
          vehicle.currentLat != null &&
          vehicle.currentLng != null &&
          vehicle.stationedBranchId != null) {
        final branch = widget.branches.firstWhere(
          (b) => b.id == vehicle.stationedBranchId,
          orElse: () => widget.branches.first,
        );
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${vehicle.id}'),
            points: [
              LatLng(branch.latitude, branch.longitude),
              LatLng(vehicle.currentLat!, vehicle.currentLng!),
            ],
            color: AppColors.primary,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }
    return polylines;
  }

  void _zoomTo(LatLng target, {double zoom = 12}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── GOOGLE MAP ──
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _sriLankaCenter,
            zoom: 7.8,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          myLocationEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
          liteModeEnabled: false,
          onTap: (_) => setState(() => _selectedItem = null),
        ),

        // ── TOP FILTER CHIPS ──
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Assets (${widget.branches.length + widget.vehicles.length})',
                  filter: FleetMapFilter.all,
                  icon: Icons.layers_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Hubs (${widget.branches.length})',
                  filter: FleetMapFilter.branches,
                  icon: Icons.store_mall_directory_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Trucks (${widget.vehicles.length})',
                  filter: FleetMapFilter.vehicles,
                  icon: Icons.local_shipping_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'In Transit (${widget.vehicles.where((v) => v.isOnTrip).length})',
                  filter: FleetMapFilter.inTransit,
                  icon: Icons.navigation_rounded,
                ),
              ],
            ),
          ),
        ),

        // ── BOTTOM SELECTED CARD ──
        if (_selectedItem != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildDetailsCard(_selectedItem),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required FleetMapFilter filter,
    required IconData icon,
  }) {
    final selected = _currentFilter == filter;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.onSurface,
        ),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      selectedColor: AppColors.primary,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: (_) => setState(() => _currentFilter = filter),
    );
  }

  Widget _buildDetailsCard(dynamic item) {
    if (item is LogisticsBranch) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.district} District • ${item.address}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(() => _selectedItem = null),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manager: ${item.managerName}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Cold Storage: ${item.hasColdStorage ? "Yes (${item.storageCapacityTons.toInt()}T)" : "No"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (item.managerPhone.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _makeCall(item.managerPhone),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (item is LogisticsVehicle) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isOnTrip
                          ? Colors.orange.withValues(alpha: 0.2)
                          : AppColors.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: item.isOnTrip ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.registrationNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.modelName} • ${(item.capacityKg / 1000).toStringAsFixed(1)} Tons',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isOnTrip
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.isOnTrip ? Colors.orange[800] : Colors.green[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(() => _selectedItem = null),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver: ${item.assignedDriverName ?? "Unassigned"}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Base: ${item.stationedBranchName ?? "Central Hub"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                    label: const Text('Focus'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      if (item.currentLat != null && item.currentLng != null) {
                        _zoomTo(LatLng(item.currentLat!, item.currentLng!), zoom: 14);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
