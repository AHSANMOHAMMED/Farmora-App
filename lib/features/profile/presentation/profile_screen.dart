import 'dart:convert';

import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'edit_profile_screen.dart';
import 'language_picker.dart';
import 'role_sheet.dart';
import 'legal_screens.dart';
import 'help_support_screen.dart';
import '../../farmer/presentation/account_verification_screen.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../transporter/presentation/nearby_transporters_screen.dart';
import '../../../services/user_location_service.dart';
import '../../auth/presentation/auth_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final data = await context.read<FarmoraState>().exportUserData();
      final encoded = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: encoded));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data export copied to clipboard.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This permanently deletes your Farmora account and related data. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<FarmoraState>().deleteAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete account: $e')),
        );
      }
    }
  }

  static Widget _avatarFallback(bool isFarmer) {
    if (isFarmer) {
      return Image.asset(
        'assets/images/farmer_headshot.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person,
          size: 48,
          color: AppColors.primary,
        ),
      );
    }
    return const Icon(
      Icons.person,
      size: 48,
      color: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isFarmer = role == Role.farmer;
    final isTransporter = role == Role.transporter;
    final showVerification = isFarmer || isTransporter;

    // Fetch current user data from state.users
    final currentUserData =
        state.users.where((u) => u['uid'] == state.currentUserId).firstOrNull ??
            {};
    final displayName = state.displayName.isNotEmpty
        ? state.displayName
        : (currentUserData['name'] as String? ?? 'User Profile');
    final district = state.district.isNotEmpty
        ? state.district
        : (currentUserData['district'] as String? ?? '');

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n?.profile ?? 'Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipOval(
                    child: state.photoUrl.isNotEmpty
                        ? Image.network(
                            state.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarFallback(isFarmer),
                          )
                        : _avatarFallback(isFarmer),
                  ),
                ),
                if (state.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              district.isEmpty
                  ? '${state.country} · ${role.label}'
                  : '$district, ${state.country} · ${role.label}',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Account Verification Card (farmer + transporter)
          if (showVerification) ...[
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.statusPendingBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: AppColors.statusPendingText, size: 22),
                ),
                title: const Text(
                  'Account Verification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(state.isVerified
                    ? 'Verified'
                    : 'Submit documents for review'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountVerificationScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (isTransporter) ...[
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.primary),
                    title: Text(l10n?.messages ?? 'Messages',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ConversationsScreen()),
                    ),
                  ),
                  Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      height: 1,
                      indent: 56),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.primary),
                    title: Text(l10n?.notifications ?? 'Notifications',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Options Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.edit_rounded, color: AppColors.primary),
                  title: const Text('Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update your name, photo & location'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  title: const Text('Account Role',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Current: ${role.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const RoleSheet(),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded,
                      color: AppColors.primary),
                  title: Text(l10n?.language ?? 'Language',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(state.language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const LanguagePicker(),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded,
                      color: AppColors.primary),
                  title: const Text('Help & Support',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                // ── Live location sharing (opt-in) ──
                const _LocationSharingTile(),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.near_me_rounded,
                      color: AppColors.primary),
                  title: const Text('Nearby Transporters',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Find verified logistics providers close to you'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NearbyTransportersScreen()),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  title: const Text('Privacy Policy',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: AppColors.primary),
                  title: const Text('Terms of Service',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen()),
                  ),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text(l10n?.signOut ?? 'Sign out',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () async {
                    await context.read<FarmoraState>().signOut();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy section
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Privacy',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined,
                      color: AppColors.primary),
                  title: Text(l10n?.exportMyData ?? 'Export my data',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Download a copy of your Farmora data'),
                  onTap: () => _exportData(context),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: AppColors.error),
                  title: Text(l10n?.deleteAccount ?? 'Delete account',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  subtitle: const Text('Permanently remove your account'),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opt-in live location sharing toggle. Reflects the current state of
/// [UserLocationService] and starts/stops continuous location broadcast.
class _LocationSharingTile extends StatefulWidget {
  const _LocationSharingTile();

  @override
  State<_LocationSharingTile> createState() => _LocationSharingTileState();
}

class _LocationSharingTileState extends State<_LocationSharingTile> {
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _sharing = UserLocationService.instance.isSharing;
  }

  Future<void> _toggle(bool on) async {
    final service = UserLocationService.instance;
    if (on) {
      final result = await service.startSharing();
      if (!mounted) return;
      setState(() => _sharing = service.isSharing);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          switch (result) {
            LocationConsentResult.granted => 'Live location sharing started.',
            LocationConsentResult.permissionDenied =>
              'Location permission denied. Enable it in Settings.',
            LocationConsentResult.serviceDisabled =>
              'Device location is turned off.',
          },
        ),
        backgroundColor: result == LocationConsentResult.granted
            ? AppColors.primary
            : AppColors.error,
      ));
    } else {
      await service.stopSharing();
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        _sharing ? Icons.location_on_rounded : Icons.location_off_rounded,
        color: _sharing ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      title: const Text('Live location sharing',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _sharing
            ? 'ON — nearby transporters and your order partners can see your last known position.'
            : 'OFF — share your position so transporters nearby can find you.',
        style: const TextStyle(fontSize: 12),
      ),
      value: _sharing,
      onChanged: _toggle,
    );
  }
}

/// Alias for backward compatibility
typedef Profile = ProfileScreen;
