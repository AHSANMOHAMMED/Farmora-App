import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import 'language_picker.dart';
import 'role_sheet.dart';
import '../../farmer/presentation/account_verification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isFarmer = role == Role.farmer;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
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
              role.label,
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
                title: const Text(
                  'Account Verification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('2 documents pending review'),
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
                  title: const Text('Language',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                const ListTile(
                  leading: Icon(Icons.help_outline_rounded,
                      color: AppColors.primary),
                  title: Text('Help & Support',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    height: 1,
                    indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Sign Out',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () => context.read<FarmoraState>().signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for backward compatibility
typedef Profile = ProfileScreen;
