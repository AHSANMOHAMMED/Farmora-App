import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/review_model.dart';
import '../../../models/user_role.dart';
import '../../../models/verification_model.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/user_location_service.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/session_actions.dart';
import '../../farmer/presentation/account_verification_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../payments/presentation/bank_details_screen.dart';
import '../../transporter/presentation/nearby_transporters_screen.dart';
import 'change_password_dialog.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'language_picker.dart';
import 'legal_screens.dart';

/// Verification state shown on the profile header and account section.
enum ProfileVerification { verified, pending, notVerified }

extension ProfileInfo on FarmoraState {
  ProfileVerification get verificationState {
    if (isVerified) return ProfileVerification.verified;
    if (verificationDocs.any((d) => d.status == VerificationStatus.pending)) {
      return ProfileVerification.pending;
    }
    return ProfileVerification.notVerified;
  }

  bool get hasFarmDetails => farmName.isNotEmpty || mainCrops.isNotEmpty;
}

/// Profile tab for farmer and buyer accounts.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FarmoraState>().refreshProfile();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            '${l.profileRefreshFailed} ${userMessage(e, action: 'refresh profile')}'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;
    final loading = state.currentUserId.isNotEmpty && !state.profileLoaded;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.profile),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const _ProfileSkeleton()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                children: [
                  const _ProfileHeader(),
                  if (isFarmer && state.currentUserId.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _FarmerStats(),
                  ],
                  const _CompletenessCard(),
                  const SizedBox(height: 24),
                  _AccountSection(isFarmer: isFarmer),
                  if (isFarmer) ...[
                    const SizedBox(height: 24),
                    _Section(
                      title: l.profileSectionLocation,
                      children: [
                        const _LocationSharingTile(),
                        _Tile(
                          icon: Icons.near_me_rounded,
                          title: l.profileNearbyTransporters,
                          subtitle: l.profileNearbyTransportersSubtitle,
                          onTap: () =>
                              _push(context, const NearbyTransportersScreen()),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _Section(
                    title: l.profileSectionPreferences,
                    children: [
                      _Tile(
                        icon: Icons.language_rounded,
                        title: l.language,
                        subtitle: state.language,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const LanguagePicker(),
                        ),
                      ),
                      _Tile(
                        icon: Icons.notifications_none_rounded,
                        title: l.notifications,
                        subtitle: l.profileNotificationsSubtitle,
                        onTap: () =>
                            _push(context, const NotificationsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: l.profileSectionSupport,
                    children: [
                      _Tile(
                        icon: Icons.help_outline_rounded,
                        title: l.helpSupport,
                        subtitle: l.profileHelpSubtitle,
                        onTap: () => _push(context, const HelpSupportScreen()),
                      ),
                      _Tile(
                        icon: Icons.description_outlined,
                        title: l.profileTerms,
                        onTap: () =>
                            _push(context, const TermsOfServiceScreen()),
                      ),
                      _Tile(
                        icon: Icons.privacy_tip_outlined,
                        title: l.profilePrivacyPolicy,
                        onTap: () =>
                            _push(context, const PrivacyPolicyScreen()),
                      ),
                      const _AboutTile(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _PrivacySection(),
                  const SizedBox(height: 24),
                  const _LogoutButton(),
                ],
              ),
            ),
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

String _roleLabel(AppLocalizations l, Role role) => switch (role) {
      Role.farmer => l.farmer,
      Role.buyer => l.buyer,
      Role.transporter => l.transporter,
      Role.admin => role.label,
    };

// ── Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    if (_uploading) return;
    final l = AppLocalizations.of(context);
    final state = context.read<FarmoraState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final image = await ImagePickerHelper().pickOne();
      if (image == null || !mounted) return;
      setState(() => _uploading = true);
      await state.changeProfilePhoto(image);
      messenger.showSnackBar(SnackBar(
        content: Text(l.profilePhotoUpdated),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            '${l.profilePhotoFailed} ${userMessage(e, action: 'change profile photo')}'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;
    final name = state.displayName.isNotEmpty
        ? state.displayName
        : l.profileUnnamedUser;
    final location = state.district.isEmpty
        ? state.country
        : '${state.district}, ${state.country}';
    final memberSince = state.memberSince == null
        ? null
        : DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag())
            .format(state.memberSince!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l.profileChangePhotoHint,
            child: InkWell(
              onTap: _changePhoto,
              customBorder: const CircleBorder(),
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: _uploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              ),
                            )
                          : state.photoUrl.isNotEmpty
                              ? Image.network(
                                  state.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _AvatarFallback(isFarmer: isFarmer),
                                )
                              : _AvatarFallback(isFarmer: isFarmer),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accentWheat,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderBadge(
                      icon: isFarmer
                          ? Icons.agriculture_rounded
                          : Icons.shopping_basket_rounded,
                      label: _roleLabel(l, state.role),
                    ),
                    if (isFarmer) _VerificationBadge(state.verificationState),
                  ],
                ),
                const SizedBox(height: 8),
                if (isFarmer && state.farmName.isNotEmpty)
                  _HeaderInfo(
                      icon: Icons.grass_rounded, text: state.farmName),
                _HeaderInfo(icon: Icons.location_on_outlined, text: location),
                if (memberSince != null)
                  _HeaderInfo(
                    icon: Icons.calendar_today_outlined,
                    text: l.profileMemberSince(memberSince),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final bool isFarmer;

  const _AvatarFallback({required this.isFarmer});

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.person, size: 44, color: AppColors.primary);
    if (!isFarmer) return const Center(child: icon);
    return Image.asset(
      'assets/images/farmer_headshot.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: icon),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    this.background = const Color(0x33FFFFFF),
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final ProfileVerification status;

  const _VerificationBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (status) {
      ProfileVerification.verified => _HeaderBadge(
          icon: Icons.verified,
          label: l.profileVerified,
          background: Colors.white,
          foreground: AppColors.primary,
        ),
      ProfileVerification.pending => _HeaderBadge(
          icon: Icons.hourglass_top_rounded,
          label: l.profileVerificationPending,
          background: AppColors.statusPendingBg,
          foreground: AppColors.statusPendingText,
        ),
      ProfileVerification.notVerified => _HeaderBadge(
          icon: Icons.shield_outlined,
          label: l.profileNotVerified,
        ),
    };
  }
}

class _HeaderInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Farmer stats ───────────────────────────────────────────────────────

class _FarmerStats extends StatelessWidget {
  const _FarmerStats();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final uid = state.currentUserId;
    final products = state.products.where((p) => p.farmerId == uid).length;
    final completed =
        state.completedOrders.where((o) => o.farmerId == uid).length;
    final reviews = state.reviews
        .where((r) => r.subjectId == uid && r.status == ReviewStatus.approved)
        .toList();
    final rating = reviews.isEmpty
        ? null
        : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.inventory_2_outlined,
            value: '$products',
            label: l.profileStatProducts,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.task_alt_rounded,
            value: '$completed',
            label: l.profileStatCompletedOrders,
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              iconColor: AppColors.accentWheat,
              value: rating.toStringAsFixed(1),
              label: l.profileReviewCount(reviews.length),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completeness ───────────────────────────────────────────────────────

class _CompletenessItem {
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _CompletenessItem(this.label, this.done, this.onTap);
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;
    void edit() => _push(context, const EditProfileScreen());

    final items = [
      _CompletenessItem(l.profileMissingPhoto, state.photoUrl.isNotEmpty, edit),
      _CompletenessItem(
          l.profileMissingDistrict, state.district.isNotEmpty, edit),
      if (isFarmer) ...[
        _CompletenessItem(l.profileMissingFarm, state.hasFarmDetails, edit),
        _CompletenessItem(l.profileMissingBank, state.hasBankDetails,
            () => _push(context, const BankDetailsScreen())),
        _CompletenessItem(
          l.profileMissingVerification,
          state.verificationState != ProfileVerification.notVerified,
          () => _push(context, const AccountVerificationScreen()),
        ),
      ],
    ];
    final missing = items.where((i) => !i.done).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    final percent =
        ((items.length - missing.length) * 100 / items.length).round();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.profileCompletePercent(percent),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFarmer ? l.profileCompleteHint : l.profileCompleteHintBuyer,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in missing)
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded,
                        size: 16, color: AppColors.primary),
                    label: Text(item.label),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: item.onTap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sections & tiles ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: AppColors.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  final bool highlight;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color = AppColors.primary,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color == AppColors.error ? AppColors.error : AppColors.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: highlight
                    ? AppColors.statusPendingText
                    : AppColors.onSurfaceVariant,
              ),
            ),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline)),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final bool isFarmer;

  const _AccountSection({required this.isFarmer});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final verification = state.verificationState;
    final farmSummary = [
      if (state.farmName.isNotEmpty) state.farmName,
      if (state.farmSize.isNotEmpty) state.farmSize,
      if (state.mainCrops.isNotEmpty) state.mainCrops.join(', '),
    ].join(' · ');

    return _Section(
      title: l.profileSectionAccount,
      children: [
        _Tile(
          icon: Icons.person_outline_rounded,
          title: l.editProfile,
          subtitle: l.profileEditSubtitle,
          onTap: () => _push(context, const EditProfileScreen()),
        ),
        _Tile(
          icon: Icons.lock_outline_rounded,
          title: 'Change password',
          subtitle: 'Update the password you use to log in',
          onTap: () => showChangePasswordDialog(context),
        ),
        if (isFarmer) ...[
          _Tile(
            icon: Icons.grass_rounded,
            title: l.profileFarmDetails,
            subtitle:
                farmSummary.isEmpty ? l.profileFarmDetailsEmpty : farmSummary,
            highlight: farmSummary.isEmpty,
            onTap: () => _push(context, const EditProfileScreen()),
          ),
          _Tile(
            icon: Icons.account_balance_outlined,
            title: l.profileBankDetails,
            subtitle: state.hasBankDetails
                ? '${state.myBankDetails.bankName} · '
                    '${state.myBankDetails.maskedAccountNumber}'
                : l.profileBankDetailsEmpty,
            highlight: !state.hasBankDetails,
            onTap: () => _push(context, const BankDetailsScreen()),
          ),
        ],
        // Farmers must verify; buyers may (optional, not gated).
        if (state.role == Role.farmer || state.role == Role.buyer)
          _Tile(
            icon: Icons.verified_user_outlined,
            title: l.profileVerification,
            subtitle: switch (verification) {
              ProfileVerification.verified =>
                l.profileVerificationDoneSubtitle,
              ProfileVerification.pending =>
                l.profileVerificationPendingSubtitle,
              ProfileVerification.notVerified =>
                l.profileVerificationNoneSubtitle,
            },
            highlight:
                isFarmer && verification == ProfileVerification.notVerified,
            onTap: () => _push(context, const AccountVerificationScreen()),
          ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  static Future<PackageInfo?>? _info;

  static Future<PackageInfo?> _load() => _info ??= PackageInfo.fromPlatform()
      .then<PackageInfo?>((i) => i)
      .catchError((Object _) => null);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo?>(
      future: _load(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        return _Tile(
          icon: Icons.info_outline_rounded,
          title: l.profileAbout,
          subtitle: version == null ? null : l.profileAppVersion(version),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Farmora',
            applicationVersion: version,
            applicationIcon: const FarmoraLogo(size: 48),
            children: [Text(l.profileAboutDescription)],
          ),
        );
      },
    );
  }
}

// ── Privacy & account removal ──────────────────────────────────────────

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  Future<void> _exportData(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await context.read<FarmoraState>().exportUserData();
      final encoded = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: encoded));
      messenger.showSnackBar(SnackBar(content: Text(l.profileExportCopied)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(userMessage(e, action: 'export your data')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final state = context.read<FarmoraState>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    unbindTransporterController(context);
    try {
      await state.deleteAccount();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            '${l.profileDeleteFailed} ${userMessage(e, action: 'delete account')}'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (context.mounted) AuthGate.resetTo(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Section(
      title: l.profileSectionPrivacy,
      children: [
        _Tile(
          icon: Icons.download_outlined,
          title: l.exportMyData,
          subtitle: l.profileExportSubtitle,
          onTap: () => _exportData(context),
        ),
        _Tile(
          icon: Icons.delete_forever_outlined,
          title: l.deleteAccount,
          subtitle: l.profileDeleteSubtitle,
          color: AppColors.error,
          onTap: () => _deleteAccount(context),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget point(String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.circle, size: 6, color: AppColors.error),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );

    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded,
          color: AppColors.error, size: 32),
      title: Text(l.profileDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.profileDeleteIntro,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            point(l.profileDeletePoint1),
            point(l.profileDeletePoint2),
            point(l.profileDeletePoint3),
            point(l.profileDeletePoint4),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _understood,
              onChanged: (v) => setState(() => _understood = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.error,
              title: Text(l.profileDeleteConfirmCheck,
                  style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.profileCancel),
        ),
        FilledButton(
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(l.deleteAccount),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _confirmLogout(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profileLogoutTitle),
        content: Text(l.profileLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await signOutAndReset(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'sign out')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded),
        label: Text(l.logOut),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Loading skeleton ───────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double radius = 16}) => Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        block(136, radius: 24),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: block(96)),
          const SizedBox(width: 8),
          Expanded(child: block(96)),
          const SizedBox(width: 8),
          Expanded(child: block(96)),
        ]),
        const SizedBox(height: 24),
        block(220),
        const SizedBox(height: 24),
        block(140),
      ],
    );
  }
}

// ── Live location sharing ──────────────────────────────────────────────

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
    final l = AppLocalizations.of(context);
    final service = UserLocationService.instance;
    if (on) {
      final result = await service.startSharing();
      if (!mounted) return;
      setState(() => _sharing = service.isSharing);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          switch (result) {
            LocationConsentResult.granted => l.profileLiveLocationStarted,
            LocationConsentResult.permissionDenied => l.profileLocationDenied,
            LocationConsentResult.serviceDisabled => l.profileLocationOff,
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
    final l = AppLocalizations.of(context);
    return _Tile(
      icon: _sharing ? Icons.location_on_rounded : Icons.location_off_rounded,
      color: _sharing ? AppColors.primary : AppColors.outline,
      title: l.profileLiveLocation,
      subtitle: _sharing ? l.profileLiveLocationOn : l.profileLiveLocationOff,
      trailing: Switch(value: _sharing, onChanged: _toggle),
      onTap: () => _toggle(!_sharing),
    );
  }
}

/// Alias for backward compatibility
typedef Profile = ProfileScreen;
