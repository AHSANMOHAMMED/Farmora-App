import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/geo.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';
import '../../messaging/presentation/conversations_screen.dart';

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
  StreamSubscription<List<Map<String, dynamic>>>? _transportersSub;
  List<Map<String, dynamic>> _transporters = [];
  Position? _myPosition;
  String _search = '';
  bool _locating = false;
  _LocationProblem? _locationError;

  @override
  void initState() {
    super.initState();
    _transportersSub = _service.transportersStream().listen((list) {
      if (mounted) setState(() => _transporters = list);
    }, onError: (e) => debugPrint('Transporters stream error: $e'));
    _locateMe();
  }

  @override
  void dispose() {
    _transportersSub?.cancel();
    _searchController.dispose();
    super.dispose();
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
      final loc = GeoPoint.fromMap(t['location'] as Map<String, dynamic>?);
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
    final state = context.watch<FarmoraState>();
    final isVerifiedUser = state.isVerified;
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
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.transporterNoProviders,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return _TransporterCard(
                        entry: e,
                        canChat: isVerifiedUser || state.role != Role.farmer,
                      );
                    },
                  ),
          ),
        ],
      ),
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
  final bool canChat;

  const _TransporterCard({required this.entry, required this.canChat});

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
                        onPressed: canChat
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ConversationsScreen(),
                                  ),
                                )
                            : null,
                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
                        label: Text(l10n.transporterConnect,
                            style: const TextStyle(
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
