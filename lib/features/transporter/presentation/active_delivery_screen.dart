import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/route_progress_map.dart';
import '../../../models/transport_job.dart';
import '../../../services/delivery_location_service.dart';
import '../../../services/firebase_service.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final TransportJob job;

  const ActiveDeliveryScreen({super.key, required this.job});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final FirestoreService _service = FirestoreService();
  StreamSubscription<List<TransportJob>>? _jobSub;
  TransportJob? _liveJob;
  bool _sharing = false;
  bool _pushing = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _liveJob = widget.job;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (widget.job.orderId != null && widget.job.orderId!.isNotEmpty && uid.isNotEmpty) {
      // The assigned transporter always reads their own job; fall back to a
      // direct doc subscription is unnecessary — transporterId scope suffices.
      _jobSub = _service.jobsByTransporterStream(uid).listen((jobs) {
        final match = jobs.where((j) => j.orderId == widget.job.orderId);
        if (match.isNotEmpty && mounted) {
          setState(() => _liveJob = match.first);
        }
      }, onError: (e) => debugPrint('Job stream error: $e'));
    }
    _sharing = DeliveryLocationService.instance.isSharing &&
        DeliveryLocationService.instance.activeJobId == widget.job.id;
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    super.dispose();
  }

  TransportJob get job => _liveJob ?? widget.job;

  bool get _isActiveDelivery =>
      const ['accepted', 'pickedUp', 'inTransit'].contains(job.status);

  Future<void> _startSharing() async {
    if (_starting) return;
    setState(() => _starting = true);
    final ok = await DeliveryLocationService.instance
        .requestConsentAndStart(jobId: job.id);
    if (!mounted) return;
    setState(() {
      _sharing = ok;
      _starting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Live location sharing is ON. Customers on this order can see you.'
          : 'Location permission denied — enable it in Settings to share live location.'),
      backgroundColor: ok ? AppColors.primary : AppColors.error,
    ));
  }

  Future<void> _pushNow() async {
    if (_pushing) return;
    setState(() => _pushing = true);
    final pos = await DeliveryLocationService.instance
        .pushCurrentPosition(jobId: job.id);
    if (!mounted) return;
    setState(() => _pushing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pos != null
          ? 'Location updated.'
          : 'Could not get a GPS fix. Try again outdoors.'),
      backgroundColor:
          pos != null ? AppColors.primary : AppColors.error,
    ));
  }

  Future<void> _transition(BuildContext context, String next) async {
    try {
      if (next == 'pickedUp' || next == 'inTransit') {
        final ok = await DeliveryLocationService.instance
            .requestConsentAndStart(jobId: job.id);
        if (!mounted) return;
        setState(() => _sharing = ok);
        final pos =
            await DeliveryLocationService.instance.currentPositionQuick();
        if (pos != null) {
          await FirestoreService().updateTransportJobLocation(
            jobId: job.id,
            lat: pos.latitude,
            lng: pos.longitude,
          );
        }
      }
      await FirestoreService().transitionTransport(job.id, next);
      DeliveryLocationService.instance.onJobStatusChanged(job.id, next);
      if (next == 'delivered' || next == 'cancelled') {
        DeliveryLocationService.instance.stopSharing(jobId: job.id);
        if (mounted) setState(() => _sharing = false);
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update delivery: $error')));
      }
    }
  }

  void _callParty() async {
    // Phone numbers stay private — direct users to in-app chat instead.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Calls go through the app: open chat to reach the farmer or buyer. Phone numbers stay private.'),
    ));
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = job.dropoff ?? job.route;
    final steps = [
      ('Accepted', job.status != 'requested'),
      ('Picked up', ['pickedUp', 'inTransit', 'delivered'].contains(job.status)),
      ('In transit', ['inTransit', 'delivered'].contains(job.status)),
      ('Delivered', job.status == 'delivered'),
    ];
    final courier = job.hasCourierLocation
        ? LatLng(job.courierLat!, job.courierLng!)
        : null;
    final fresh = DeliveryLocationService.isLocationFresh(job.locationUpdatedAt);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Active Delivery',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusApprovedBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          job.status.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusApprovedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destination: $destination',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job.fee.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Fee: ${job.fee}',
                        style: const TextStyle(fontFamily: 'Inter')),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Live sharing control ──
            _LiveSharingCard(
              sharing: _sharing,
              isActive: _isActiveDelivery,
              starting: _starting,
              pushing: _pushing,
              fresh: fresh,
              onStart: _startSharing,
              onPush: _pushNow,
            ),
            const SizedBox(height: 16),

            RouteProgressMap(
              progress: RouteProgressMap.progressForJobStatus(job.status),
              pickupLabel: job.pickup ?? job.route,
              dropoffLabel: job.dropoff ?? job.detail,
              statusLabel: '${job.title} • ${job.status.toUpperCase()}',
              pickup: job.pickupLat != null && job.pickupLng != null
                  ? LatLng(job.pickupLat!, job.pickupLng!)
                  : null,
              dropoff: job.dropoffLat != null && job.dropoffLng != null
                  ? LatLng(job.dropoffLat!, job.dropoffLng!)
                  : null,
              courier: courier,
            ),
            const SizedBox(height: 24),
            const Text(
              'Delivery Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    _buildTimelineStep(
                      steps[i].$1,
                      steps[i].$2 ? 'Done' : 'Pending',
                      steps[i].$2,
                      i < steps.length - 1 && steps[i].$2,
                      isLast: i == steps.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callParty,
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: job.canTransition
          ? Container(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => _transition(context, job.nextStatuses.first),
                child: Text('Mark ${job.nextStatuses.first}'),
              ),
            )
          : null,
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool completed,
    bool showLine, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? AppColors.primary : AppColors.outlineVariant,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: showLine ? AppColors.primary : AppColors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveSharingCard extends StatelessWidget {
  final bool sharing;
  final bool isActive;
  final bool starting;
  final bool pushing;
  final bool fresh;
  final VoidCallback onStart;
  final VoidCallback onPush;

  const _LiveSharingCard({
    required this.sharing,
    required this.isActive,
    required this.starting,
    required this.pushing,
    required this.fresh,
    required this.onStart,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) {
    final canShare = isActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sharing
            ? const Color(0xFFE8F5E9)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sharing ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sharing
                    ? Icons.my_location_rounded
                    : Icons.location_disabled_rounded,
                color: sharing ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sharing
                      ? 'Live location sharing ON'
                      : (canShare
                          ? 'Share live location'
                          : 'Location sharing unavailable for this job state'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (sharing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: fresh ? AppColors.primary : Colors.orange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    fresh ? 'LIVE' : 'STALE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sharing
                ? 'The farmer and buyer on this order can see your position in real time. Sharing stops automatically after delivery.'
                : 'While a delivery is accepted and in progress you can broadcast your GPS position so the farmer and buyer can track you live.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (canShare) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: starting ? null : onStart,
                    icon: starting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Icon(sharing
                            ? Icons.refresh_rounded
                            : Icons.play_arrow_rounded),
                    label: Text(sharing ? 'Restart' : 'Start sharing'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (sharing && !pushing) ? onPush : null,
                    icon: pushing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Update now'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
