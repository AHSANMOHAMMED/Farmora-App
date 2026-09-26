import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/utils/app_errors.dart';
import '../../../../providers/farmora_state.dart';
import '../../../auth/presentation/session_actions.dart';

/// True when dotted version [current] is lower than [minimum]
/// ("1.2.0" < "1.10"). Non-numeric parts (build suffixes) are ignored.
bool isVersionLower(String current, String minimum) {
  List<int> parse(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final a = parse(current);
  final b = parse(minimum);
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

/// Blocking screen shown to non-admin users while the platform is in
/// maintenance mode.
class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      await context.read<FarmoraState>().refreshPlatformSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage(e, action: 'check platform status')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await signOutAndReset(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage(e, action: 'sign out'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    return _GateScaffold(
      icon: Icons.construction_rounded,
      title: context.l10n.maintenanceMode,
      message: state.maintenanceNotice,
      primaryLabel: context.l10n.retry,
      busy: _checking,
      onPrimary: _retry,
      secondaryLabel: context.l10n.signOut,
      onSecondary: _signOut,
    );
  }
}

/// Blocking screen shown when the installed app is older than the platform
/// `minAppVersion`.
class UpdateRequiredView extends StatelessWidget {
  const UpdateRequiredView({
    super.key,
    required this.currentVersion,
    required this.minimumVersion,
  });

  final String currentVersion;
  final String minimumVersion;

  @override
  Widget build(BuildContext context) {
    return _GateScaffold(
      icon: Icons.system_update_rounded,
      title: 'Update required',
      message: 'This version of Farmora ($currentVersion) is no longer '
          'supported. Please install version $minimumVersion or newer from '
          'your app store to continue.',
      primaryLabel: context.l10n.retry,
      onPrimary: () async {
        try {
          await context.read<FarmoraState>().refreshPlatformSettings();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userMessage(e, action: 'check app version')),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.busy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final bool busy;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: busy ? null : onPrimary,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(primaryLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(220, 50),
                  ),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy ? null : onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
