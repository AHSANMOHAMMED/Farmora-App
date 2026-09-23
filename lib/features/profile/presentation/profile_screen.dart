import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/farmora_strings.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'language_picker.dart';
import 'role_sheet.dart';
import 'help_support_screen.dart';
import '../../farmer/presentation/account_verification_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final strings = FarmoraStrings.of(context);
    final role = state.role;
    final isFarmer = role == Role.farmer;

    // Settings screens shown in the "More Settings" sheet
    void openMoreSettings() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary),
                title: Text(strings.t('helpSupport'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('support@farmora.lk · +94 11 234 5678'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '${strings.t('helpSupport')}: support@farmora.lk'),
                    backgroundColor: AppColors.primary,
                  ));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(strings.t('signOut'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.read<FarmoraState>().signOut();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(strings.t('navProfile')),
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
                    child: isFarmer
                        ? Image.asset(
                            'assets/images/farmer_headshot.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 48,
                            color: AppColors.primary,
                          ),
                  ),
                ),
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
              isFarmer ? 'Rohan Silva' : 'Alex Perera',
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
              role == Role.farmer
                  ? strings.t('farmer')
                  : role.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Account Verification Card (for Farmer)
          if (isFarmer) ...[
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
                title: Text(
                  strings.t('accountVerification'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(strings.t('docsPending')),
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

          // Options Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  title: Text(strings.t('accountRole'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text('${strings.t('current')}${role.label}'),
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
                  title: Text(strings.t('language'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(state.language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
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
                  title: Text(strings.t('helpSupport'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sign out full-width button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<FarmoraState>().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(strings.t('signOut'),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: const Color(0xFFFDE8E8),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
