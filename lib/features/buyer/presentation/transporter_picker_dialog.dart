import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_errors.dart';
import '../../../services/firebase_service.dart';

/// Lets the buyer pick a verified transporter for a delivery.
///
/// Loads the public list via the `listAvailableTransporters` callable and
/// shows loading / empty / error (with retry) states. Returns the chosen
/// transporter uid, or null when dismissed.
Future<String?> showTransporterPicker(BuildContext context,
    {String? district}) async {
  final picked = await pickTransporter(context, district: district);
  return picked?['uid']?.toString();
}

/// Same as [showTransporterPicker] but returns the transporter's public
/// profile map (uid, displayName, vehicleType, ...).
Future<Map<String, dynamic>?> pickTransporter(BuildContext context,
    {String? district}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _TransporterPickerDialog(district: district),
  );
}

class _TransporterPickerDialog extends StatefulWidget {
  const _TransporterPickerDialog({this.district});

  final String? district;

  @override
  State<_TransporterPickerDialog> createState() =>
      _TransporterPickerDialogState();
}

class _TransporterPickerDialogState extends State<_TransporterPickerDialog> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      FirestoreService().listAvailableTransporters(district: widget.district);

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a transporter'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              final message = userMessage(snap.error!,
                  action: 'load available transporters',
                  stack: snap.stackTrace);
              return _StateMessage(
                icon: Icons.error_outline,
                color: AppColors.error,
                message: message,
                onRetry: _retry,
              );
            }
            final transporters = snap.data ?? const [];
            if (transporters.isEmpty) {
              return _StateMessage(
                icon: Icons.local_shipping_outlined,
                color: AppColors.onSurfaceVariant,
                message:
                    'No verified transporters are available right now. Try again later.',
                onRetry: _retry,
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: transporters.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = transporters[index];
                final name = (t['displayName'] ?? 'Transporter').toString();
                final photo = (t['photoUrl'] ?? '').toString();
                final district = (t['district'] ?? '').toString();
                final vehicle = (t['vehicleType'] ?? '').toString();
                final capacity = t['vehicleCapacity'];
                final capUnit = (t['vehicleCapacityUnit'] ?? 'kg').toString();
                final available =
                    (t['availabilityStatus'] ?? '').toString().toLowerCase();
                final details = [
                  if (district.isNotEmpty) district,
                  if (vehicle.isNotEmpty) vehicle,
                  if (capacity != null) '$capacity $capUnit capacity',
                  if (available.isNotEmpty) available,
                ].join(' • ');
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? const Icon(Icons.local_shipping_outlined)
                        : null,
                  ),
                  title: Text(name),
                  subtitle:
                      Text(details.isEmpty ? 'Verified transporter' : details),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(t),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.color,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
