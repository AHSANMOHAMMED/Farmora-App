import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/user_role.dart';
import 'verification_review_screen.dart';

/// Display label for a raw role value stored in Firestore.
String _roleLabel(String raw) {
  for (final r in Role.values) {
    if (r.name == raw.toLowerCase()) return r.label;
  }
  return raw;
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRole = 'all'; // all, farmer, buyer, transporter, admin
  String _selectedStatus = 'all'; // all, verified, suspended

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final query = _searchCtrl.text.trim().toLowerCase();
    final l = context.l10n;

    final filteredUsers = state.users.where((user) {
      final name = (user['name'] ?? user['displayName'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final uid = (user['uid'] ?? user['id'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final verified = user['isVerified'] == true;
      final suspended = user['isSuspended'] == true;

      // Query filter
      if (query.isNotEmpty) {
        final matches = name.contains(query) ||
            phone.contains(query) ||
            email.contains(query) ||
            uid.contains(query);
        if (!matches) return false;
      }

      // Role filter
      if (_selectedRole != 'all' && role != _selectedRole) {
        return false;
      }

      // Status filter
      if (_selectedStatus == 'verified' && !verified) return false;
      if (_selectedStatus == 'pending' && verified) return false;
      if (_selectedStatus == 'suspended' && !suspended) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminUsersTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l.adminUsersSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildRoleChip('all', l.adminUsersAllRoles(state.users.length)),
                const SizedBox(width: 8),
                _buildRoleChip('farmer', l.adminUsersFarmers, color: AppColors.primary),
                const SizedBox(width: 8),
                _buildRoleChip('buyer', l.adminUsersBuyers, color: const Color(0xFF1B6BD8)),
                const SizedBox(width: 8),
                _buildRoleChip('transporter', l.adminUsersTransporters, color: const Color(0xFFE65100)),
                const SizedBox(width: 8),
                _buildRoleChip('admin', l.adminUsersAdmins, color: const Color(0xFF6A1B9A)),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: AppColors.outlineVariant),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(l.adminUsersVerifiedOnly),
                  selected: _selectedStatus == 'verified',
                  onSelected: (val) {
                    setState(() => _selectedStatus = val ? 'verified' : 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending Approval'),
                  selected: _selectedStatus == 'pending',
                  selectedColor: Colors.amber.shade100,
                  onSelected: (val) {
                    setState(() => _selectedStatus = val ? 'pending' : 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l.statusSuspended),
                  selected: _selectedStatus == 'suspended',
                  onSelected: (val) {
                    setState(() => _selectedStatus = val ? 'suspended' : 'all');
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // User list
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(l.adminUsersEmpty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredUsers.length,
                    itemBuilder: (ctx, idx) {
                      final u = filteredUsers[idx];
                      return _UserListCard(
                        user: u,
                        onTap: () => _showUserActionSheet(context, u, state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String roleKey, String label, {Color? color}) {
    final isSelected = _selectedRole == roleKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (color ?? AppColors.primary) : AppColors.textPrimary,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedRole = roleKey);
      },
    );
  }

  /// Users with an admin call in flight.
  final Set<String> _busyUids = {};

  /// Awaits one admin action; shows [success] only after it returns and
  /// `userMessage(e)` on failure.
  Future<void> _runUserAction(
    String uid,
    Future<void> Function() action, {
    required String success,
    required String actionName,
  }) async {
    if (_busyUids.contains(uid)) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyUids.add(uid));
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(userMessage(e, action: actionName))));
    } finally {
      if (mounted) setState(() => _busyUids.remove(uid));
    }
  }

  void _showUserActionSheet(BuildContext context, Map<String, dynamic> user, FarmoraState state) {
    final l = context.l10n;
    final uid = (user['uid'] ?? user['id'] ?? '').toString();
    final name = (user['name'] ?? user['displayName'] ?? l.adminUsersUnknownUser).toString();
    final role = (user['role'] ?? 'farmer').toString();
    final phone = (user['phone'] ?? l.adminUsersNotProvided).toString();
    final email = (user['email'] ?? l.adminUsersNotProvided).toString();
    final district = (user['district'] ?? l.adminUsersDefaultDistrict).toString();
    final verified = user['isVerified'] == true;
    final suspended = user['isSuspended'] == true;
    final deleted = user['isDeleted'] == true;
    final isSelf = uid.isNotEmpty && uid == state.currentUserId;
    final busy = _busyUids.contains(uid);
    final canAct = uid.isNotEmpty && !busy && !deleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    radius: 24,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (verified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                            ],
                          ],
                        ),
                        Text(l.adminUsersRoleDistrict(_roleLabel(role), district), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(l.adminUsersUid(uid), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),

              Text(l.adminUsersActionsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (deleted) ...[
                const SizedBox(height: 8),
                const Text('This account has been deleted.',
                    style: TextStyle(fontSize: 12, color: AppColors.error)),
              ] else if (busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 12),

              // Verify / Unverify Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canAct,
                leading: Icon(
                  verified ? Icons.cancel_outlined : Icons.verified_user_rounded,
                  color: verified ? Colors.orange : Colors.blue,
                ),
                title: Text(verified ? l.adminUsersRevokeBadge : l.adminUsersGrantBadge),
                subtitle: Text(verified ? l.adminUsersRevokeBadgeSubtitle : l.adminUsersGrantBadgeSubtitle),
                onTap: () {
                  Navigator.pop(bCtx);
                  _runUserAction(
                    uid,
                    () => state.setUserVerified(userId: uid, verified: !verified),
                    success: !verified ? l.adminUsersVerifiedSnack : l.adminUsersRevokedSnack,
                    actionName: 'update verification',
                  );
                },
              ),

              // Suspend / Unsuspend Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canAct && !isSelf,
                leading: Icon(
                  suspended ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: suspended ? Colors.green : AppColors.error,
                ),
                title: Text(suspended ? l.adminUsersLiftSuspension : l.adminUsersSuspend),
                subtitle: Text(isSelf
                    ? 'You cannot suspend your own account.'
                    : (suspended ? l.adminUsersLiftSuspensionSubtitle : l.adminUsersSuspendSubtitle)),
                onTap: () {
                  Navigator.pop(bCtx);
                  _runUserAction(
                    uid,
                    () => state.setUserSuspended(uid, !suspended),
                    success: suspended ? l.adminUsersRestoredSnack : l.adminUsersSuspendedSnack,
                    actionName: suspended ? 'lift the suspension' : 'suspend the user',
                  );
                },
              ),

              // Change Role Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canAct && !isSelf,
                leading: const Icon(Icons.switch_account_rounded, color: AppColors.primary),
                title: Text(l.adminUsersChangeRole),
                subtitle: Text(isSelf
                    ? 'You cannot change your own role.'
                    : l.adminUsersCurrentRole(_roleLabel(role))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(bCtx);
                  _showChangeRoleDialog(context, uid, name, role, state);
                },
              ),

              // View KYC Documents
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.document_scanner_rounded, color: Color(0xFF6A1B9A)),
                title: Text(l.adminUsersInspectKyc),
                subtitle: Text(l.adminUsersInspectKycSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(bCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VerificationReviewScreen()),
                  );
                },
              ),

              // Delete user
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: canAct && !isSelf,
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                title: const Text('Delete user'),
                subtitle: Text(isSelf
                    ? 'You cannot delete your own account here.'
                    : 'Disables sign-in and marks the account as deleted.'),
                onTap: () {
                  Navigator.pop(bCtx);
                  _confirmDeleteUser(context, uid, name, state);
                },
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  l.adminUsersContact(phone, email),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(
      BuildContext context, String uid, String name, FarmoraState state) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
            'The account will be disabled and marked as deleted. The user '
            'can no longer sign in. This action is audited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete user'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runUserAction(
      uid,
      () => state.adminDeleteUser(uid),
      success: '$name was deleted.',
      actionName: 'delete the user',
    );
  }

  void _showChangeRoleDialog(BuildContext context, String uid, String name, String currentRole, FarmoraState state) {
    if (uid == state.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot change your own role.')),
      );
      return;
    }
    String selected = currentRole.toLowerCase();
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          title: Text(l.adminUsersChangeRoleFor(name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v ?? selected),
                child: Column(
                  children: [
                    RadioListTile<String>(value: 'farmer', title: Text(l.adminUsersRoleFarmerOption)),
                    RadioListTile<String>(value: 'buyer', title: Text(l.adminUsersRoleBuyerOption)),
                    RadioListTile<String>(value: 'transporter', title: Text(l.adminUsersRoleTransporterOption)),
                    RadioListTile<String>(value: 'admin', title: Text(l.adminUsersRoleAdminOption)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
            FilledButton(
              onPressed: selected == currentRole.toLowerCase()
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _runUserAction(
                        uid,
                        () => state.adminSetUserRole(userId: uid, role: selected),
                        success: l.adminUsersRoleUpdated(name, _roleLabel(selected)),
                        actionName: 'change the role',
                      );
                    },
              child: Text(l.adminUsersConfirmRoleChange),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserListCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserListCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = (user['name'] ?? user['displayName'] ?? l.adminUsersUnknownUser).toString();
    final role = (user['role'] ?? 'farmer').toString();
    final district = (user['district'] ?? l.adminUsersDefaultDistrict).toString();
    final phone = (user['phone'] ?? '').toString();
    final verified = user['isVerified'] == true;
    final suspended = user['isSuspended'] == true;

    Color roleColor;
    switch (role.toLowerCase()) {
      case 'farmer':
        roleColor = AppColors.primary;
        break;
      case 'buyer':
        roleColor = const Color(0xFF1B6BD8);
        break;
      case 'transporter':
        roleColor = const Color(0xFFE65100);
        break;
      default:
        roleColor = const Color(0xFF6A1B9A);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
            ],
          ],
        ),
        subtitle: Text(
          '${_roleLabel(role).toUpperCase()} · $district${phone.isNotEmpty ? ' · $phone' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user['isDeleted'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Deleted', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
              )
            else if (suspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l.statusSuspended, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l.statusActive, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
