import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/transport_job.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/fleet_service.dart';
import '../../transporter/presentation/active_delivery_screen.dart';

void _fail(BuildContext context, Object e, String action) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(userMessage(e, action: action)),
    backgroundColor: AppColors.error,
  ));
}

/// Driver home: fleet invitations / membership and assigned deliveries,
/// which open the shared active-delivery screen (pickup, transit, POD).
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _fleet = FleetService();

  @override
  void initState() {
    super.initState();
    // Keep the public driver card current so fleet owners can find us.
    _fleet.ensureDriverProfile().catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.drvTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          StreamBuilder<List<FleetLink>>(
            stream: _fleet.myFleets(),
            builder: (context, snap) {
              final links = snap.data ?? const <FleetLink>[];
              final invites = links.where((x) => x.status == 'invited');
              final active = links.where((x) => x.status == 'active');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invites.isNotEmpty) _title(l.drvInvites),
                  for (final link in invites)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: Text(l.drvInvitedBy(link.transporterName)),
                        subtitle: OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _fleet
                                  .respond(link, accept: false)
                                  .catchError((Object e) => _fail(context, e, 'decline')),
                              child: Text(l.drvDecline),
                            ),
                            FilledButton(
                              onPressed: () => _fleet
                                  .respond(link, accept: true)
                                  .catchError((Object e) => _fail(context, e, 'accept')),
                              child: Text(l.drvAccept),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _title(l.drvMyFleet),
                  if (active.isEmpty && snap.hasData)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l.drvNoFleet,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant)),
                    ),
                  for (final link in active)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping_rounded,
                            color: AppColors.primary),
                        title: Text(link.transporterName),
                        trailing: TextButton(
                          onPressed: () => _fleet
                              .respond(link, accept: false)
                              .catchError((Object e) => _fail(context, e, 'leave')),
                          child: Text(l.drvLeave),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          _title(l.drvAssigned),
          StreamBuilder<List<TransportJob>>(
            stream: _fleet.assignedJobs(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(userMessage(snap.error!));
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final jobs = snap.data!;
              if (jobs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l.drvNoJobs,
                      style:
                          const TextStyle(color: AppColors.onSurfaceVariant)),
                );
              }
              return Column(children: [
                for (final job in jobs)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        job.status == 'delivered'
                            ? Icons.task_alt_rounded
                            : Icons.route_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(job.productName ?? job.title),
                      subtitle: Text(
                          '${job.pickup ?? ''} → ${job.dropoff ?? ''}\n${job.status}'),
                      isThreeLine: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ActiveDeliveryScreen(job: job))),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(t,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

/// Transporter: invite drivers by phone and manage the fleet.
class FleetDriversScreen extends StatefulWidget {
  const FleetDriversScreen({super.key});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  final _fleet = FleetService();
  final _phone = TextEditingController();
  DriverProfile? _found;
  bool _searched = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    setState(() => _busy = true);
    try {
      final d = await _fleet.findDriver(_phone.text);
      setState(() {
        _found = d;
        _searched = true;
      });
    } catch (e) {
      if (mounted) _fail(context, e, 'find the driver');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.fleetMyDrivers)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: l.fleetFindPhone,
                    border: const OutlineInputBorder()),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
                onPressed: _busy ? null : _find, child: Text(l.fleetFind)),
          ]),
          if (_searched && _found == null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.fleetNotFound,
                  style: const TextStyle(color: AppColors.error)),
            ),
          if (_found != null)
            Card(
              child: ListTile(
                leading: Icon(
                    _found!.isVerified ? Icons.verified : Icons.person_outline,
                    color: AppColors.primary),
                title: Text(_found!.name),
                subtitle: Text(_found!.district),
                trailing: FilledButton(
                  onPressed: () async {
                    try {
                      await _fleet.invite(_found!);
                      setState(() => _found = null);
                      _phone.clear();
                    } catch (e) {
                      if (context.mounted) _fail(context, e, 'invite');
                    }
                  },
                  child: Text(l.fleetInvite),
                ),
              ),
            ),
          const SizedBox(height: 16),
          StreamBuilder<List<FleetLink>>(
            stream: _fleet.myDrivers(),
            builder: (context, snap) {
              final links = snap.data ?? const <FleetLink>[];
              if (snap.hasData && links.isEmpty) {
                return Text(l.fleetNoDrivers);
              }
              return Column(children: [
                for (final link in links)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(link.driverName),
                      subtitle: Text(switch (link.status) {
                        'active' => l.fleetActive,
                        'removed' => l.fleetRemoved,
                        _ => l.fleetInvited,
                      }),
                      trailing: link.status == 'removed'
                          ? null
                          : TextButton(
                              onPressed: () => _fleet
                                  .remove(link)
                                  .catchError((Object e) => _fail(context, e, 'remove')),
                              child: Text(l.fleetRemove),
                            ),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

/// Transporter: pick an active fleet driver for [job] (or take it back).
Future<void> showAssignDriverSheet(BuildContext context, TransportJob job) async {
  final l = context.l10n;
  final fleet = FleetService();
  final links = (await fleet.myDrivers().first)
      .where((x) => x.status == 'active')
      .toList();
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<Object>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(l.fleetAssign,
            style: const TextStyle(fontWeight: FontWeight.w700))),
        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.fleetNoActiveDrivers),
          ),
        for (final link in links)
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(link.driverName),
            onTap: () => Navigator.pop(ctx, link),
          ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l.fleetUnassign),
          onTap: () => Navigator.pop(ctx, 'self'),
        ),
      ]),
    ),
  );
  if (choice == null || !context.mounted) return;
  try {
    await fleet.assign(job, choice is FleetLink ? choice : null);
  } catch (e) {
    if (context.mounted) _fail(context, e, 'assign the driver');
  }
}

/// Whether the signed-in user owns [job] (for showing the assign action).
bool ownsJob(BuildContext context, TransportJob job) =>
    job.transporterId != null &&
    job.transporterId == context.read<FarmoraState>().currentUserId;
