import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/geo.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';

/// Discovery screen where farmers and buyers find verified transport
/// providers near their location and connect with them via in-app chat.
/// Distance is computed client-side from last-known profile locations —
/// no continuous tracking of other users, and phone numbers stay private.
class NearbyTransportersScreen extends StatefulWidget {
  const NearbyTransportersScreen({super.key});

  @override
  State<NearbyTransportersScreen> createState() =>
      _NearbyTransportersScreenState();
}

class _NearbyTransportersScreenState extends State<NearbyTransportersScreen> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _transporters = [];
  bool _loading = true;
  String? _loadError;
  Position? _myPosition;
  String _search = '';
  bool _locating = false;
  _LocationProblem? _locationError;

  @override
  void initState() {
    super.initState();
    _loadTransporters();
    _locateMe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// One-shot load via the `listAvailableTransporters` callable (the
  /// transporter directory is not readable directly). Pull to refresh.
  Future<void> _loadTransporters() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await _service.listAvailableTransporters();
      if (!mounted) return;
      setState(() {
        _transporters = list;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            userMessage(e, action: 'load transport providers', stack: st);
      });
    }
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        final req = await Permission.locationWhenInUse.request();
        if (!req.isGranted) {
          if (mounted) {
            setState(() {
              _locating = false;
              _locationError = _LocationProblem.permissionOff;
            });
          }
          return;
        }
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = _LocationProblem.deviceOff;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
      _myPosition = pos;
      // One-shot local fix only — continuous sharing stays an explicit
      // opt-in via the profile toggle. Publish a single snapshot so
      // transporters can also see this user on their discovery list.
      await _service.updateMyLocation(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (mounted) setState(() => _locating = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationError = _LocationProblem.failed;
        });
      }
    }
  }

  List<_TransporterEntry> get _sorted {
    final entries = <_TransporterEntry>[];
    for (final t in _transporters) {
      final name = (t['displayName'] ?? t['name'] ?? 'Transporter').toString();
      if (_search.isNotEmpty &&
          !name.toLowerCase().contains(_search.toLowerCase()) &&
          !(t['district'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase())) {
        continue;
      }
      final rawLoc = t['location'];
      final loc = GeoPoint.fromMap(
          rawLoc is Map ? Map<String, dynamic>.from(rawLoc) : null);
      double? km;
      if (_myPosition != null && loc.isValid) {
        km = distanceKm(
          lat1: _myPosition!.latitude,
          lng1: _myPosition!.longitude,
          lat2: loc.latitude,
          lng2: loc.longitude,
        );
      }
      entries.add(_TransporterEntry(data: t, distanceKm: km));
    }
    entries.sort((a, b) {
      final ad = a.distanceKm ?? double.infinity;
      final bd = b.distanceKm ?? double.infinity;
      return ad.compareTo(bd);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _sorted;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.transporterNearbyTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.transporterSearchNameDistrict,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        tooltip: l10n.transporterClearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Flexible(
                  child: TextButton.icon(
                    onPressed: _locating ? null : _locateMe,
                    icon: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(
                      _myPosition == null
                          ? l10n.transporterUseMyLocation
                          : l10n.transporterLocationSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.transporterProvidersCount(entries.length),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFFB26A00)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        switch (_locationError!) {
                          _LocationProblem.permissionOff =>
                            l10n.transporterLocationPermissionOff,
                          _LocationProblem.deviceOff =>
                            l10n.transporterDeviceLocationOff,
                          _LocationProblem.failed =>
                            l10n.transporterLocationFailed,
                        },
                        style:
                            const TextStyle(fontFamily: 'Inter', fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading && _transporters.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTransporters,
                    child: _loadError != null && _transporters.isEmpty
                        ? _messageList(
                            icon: Icons.error_outline,
                            message: _loadError!,
                            showRetry: true,
                          )
                        : entries.isEmpty
                            ? _messageList(
                                icon: Icons.local_shipping_outlined,
                                message: l10n.transporterNoProviders,
                                showRetry: false,
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: entries.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) =>
                                    _TransporterCard(entry: entries[i]),
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Scrollable (so pull-to-refresh works) empty/error message.
  Widget _messageList({
    required IconData icon,
    required String message,
    required bool showRetry,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(icon, size: 44, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (showRetry) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _loadTransporters,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ),
        ],
      ],
    );
  }
}

enum _LocationProblem { permissionOff, deviceOff, failed }

class _TransporterEntry {
  final Map<String, dynamic> data;
  final double? distanceKm;
  const _TransporterEntry({required this.data, this.distanceKm});
}

class _TransporterCard extends StatelessWidget {
  final _TransporterEntry entry;

  const _TransporterCard({required this.entry});

  /// Read-only provider details. Messaging is order-scoped, so there is no
  /// direct "connect" here: pick this provider at checkout, then chat from
  /// the order.
  void _showDetails(BuildContext context, String name) {
    final t = entry.data;
    final districts = (t['serviceDistricts'] is List)
        ? (t['serviceDistricts'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final rating = t['rating'];
    final capacity = t['vehicleCapacity'];
    final rows = <MapEntry<String, String>>[
      if ((t['district'] ?? '').toString().isNotEmpty)
        MapEntry('District', t['district'].toString()),
      if (districts.isNotEmpty) MapEntry('Serves', districts.join(', ')),
      if ((t['vehicleType'] ?? '').toString().isNotEmpty)
        MapEntry('Vehicle', t['vehicleType'].toString()),
      if ((t['vehicleRegistration'] ?? '').toString().isNotEmpty)
        MapEntry('Registration', t['vehicleRegistration'].toString()),
      if (capacity != null)
        MapEntry('Capacity',
            '$capacity ${(t['vehicleCapacityUnit'] ?? 'kg').toString()}'),
      if (rating is num && rating > 0)
        MapEntry('Rating', rating.toStringAsFixed(1)),
      if (entry.distanceKm != null)
        MapEntry('Distance', distanceLabel(entry.distanceKm!)),
      MapEntry('Verified', t['isVerified'] == true ? 'Yes' : 'No'),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(r.key,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text(r.value,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                context.l10n.transporterConnectTooltip,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _initials {
    final name =
        (entry.data['displayName'] ?? entry.data['name'] ?? '?').toString();
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final t = entry.data;
    final l10n = context.l10n;
    final name =
        (t['displayName'] ?? t['name'] ?? l10n.roleTransporter).toString();
    final district = (t['district'] ?? '').toString();
    final vehicle = (t['vehicleType'] ?? '').toString();
    final registration = (t['vehicleRegistration'] ?? '').toString();
    final capacity = t['vehicleCapacity'];
    final capacityUnit = (t['vehicleCapacityUnit'] ?? 'kg').toString();
    final verified = t['isVerified'] == true;
    final availability = (t['availabilityStatus'] ?? '').toString();
    final available = availability.isEmpty || availability == 'available';
    final fresh = DeliveryLocationService.isLocationFresh(
      firebaseDate(t['locationUpdatedAt']),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    t['photoUrl'] != null && t['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(t['photoUrl'].toString())
                        : null,
                child: (t['photoUrl'] ?? '').toString().isEmpty
                    ? Text(
                        _initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              if (verified)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        size: 14, color: Color(0xFF2E7D32)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fresh
                                  ? Icons.near_me_rounded
                                  : Icons.place_rounded,
                              size: 10,
                              color: const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceLabel(entry.distanceKm!),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (district.isNotEmpty) district,
                    if (vehicle.isNotEmpty)
                      registration.isNotEmpty
                          ? '$vehicle · $registration'
                          : vehicle,
                    if (capacity != null)
                      l10n.transporterCapacityLine(
                        l10n.transporterCapacityAmount(
                          capacity is num
                              ? AppFormat.number(capacity,
                                  decimals: capacity % 1 == 0 ? 0 : 1)
                              : capacity.toString(),
                          capacityUnit == 'tons'
                              ? l10n.transporterUnitTons
                              : capacityUnit == 'kg'
                                  ? l10n.unitKg
                                  : capacityUnit,
                        ),
                      ),
                  ].join(' • '),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(0xFFD8EFC9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        available
                            ? l10n.transporterAvailable
                            : l10n.transporterBusy,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: available
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFB26A00),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: l10n.transporterConnectTooltip,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetails(context, name),
                        icon: const Icon(Icons.info_outline, size: 14),
                        label: const Text('Details',
                            style: TextStyle(
                                fontFamily: 'Inter', fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
