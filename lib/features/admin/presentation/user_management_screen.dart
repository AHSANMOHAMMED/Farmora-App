import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../core/constants/app_colors.dart';
import 'verification_review_screen.dart';

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

    final filteredUsers = state.users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
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
      if (_selectedStatus == 'suspended' && !suspended) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management & Access Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, or user ID...',
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
                _buildRoleChip('all', 'All Roles (${state.users.length})'),
                const SizedBox(width: 8),
                _buildRoleChip('farmer', 'Farmers', color: AppColors.primary),
                const SizedBox(width: 8),
                _buildRoleChip('buyer', 'Buyers', color: const Color(0xFF1B6BD8)),
                const SizedBox(width: 8),
                _buildRoleChip('transporter', 'Transporters', color: const Color(0xFFE65100)),
                const SizedBox(width: 8),
                _buildRoleChip('admin', 'Admins', color: const Color(0xFF6A1B9A)),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: AppColors.outlineVariant),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Verified Only'),
                  selected: _selectedStatus == 'verified',
                  onSelected: (val) {
                    setState(() => _selectedStatus = val ? 'verified' : 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Suspended'),
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
                        const Text('No users match your criteria.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
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

  void _showUserActionSheet(BuildContext context, Map<String, dynamic> user, FarmoraState state) {
    final uid = (user['uid'] ?? user['id'] ?? '').toString();
    final name = (user['name'] ?? 'Unknown User').toString();
    final role = (user['role'] ?? 'farmer').toString();
    final phone = (user['phone'] ?? 'Not provided').toString();
    final email = (user['email'] ?? 'Not provided').toString();
    final district = (user['district'] ?? 'Sri Lanka').toString();
    final verified = user['isVerified'] == true;
    final suspended = user['isSuspended'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                        Text('Role: ${role.toUpperCase()} · District: $district', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('UID: $uid', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),

              const Text('Administrative Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),

              // Verify / Unverify Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  verified ? Icons.cancel_outlined : Icons.verified_user_rounded,
                  color: verified ? Colors.orange : Colors.blue,
                ),
                title: Text(verified ? 'Revoke Verified Badge' : 'Grant Verified Badge'),
                subtitle: Text(verified ? 'Remove trust badge from marketplace listings' : 'Mark user as officially verified partner'),
                onTap: () async {
                  Navigator.pop(bCtx);
                  await state.setUserVerified(userId: uid, verified: !verified);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(!verified ? 'User verified successfully' : 'Verification badge revoked')),
                    );
                  }
                },
              ),

              // Suspend / Unsuspend Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  suspended ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: suspended ? Colors.green : AppColors.error,
                ),
                title: Text(suspended ? 'Lift User Suspension' : 'Suspend User Account'),
                subtitle: Text(suspended ? 'Allow user to trade and sign in' : 'Block user from logging in or accepting orders'),
                onTap: () async {
                  Navigator.pop(bCtx);
                  await state.setUserSuspended(uid, !suspended);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(suspended ? 'User account restored' : 'User account suspended')),
                    );
                  }
                },
              ),

              // Change Role Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.switch_account_rounded, color: AppColors.primary),
                title: const Text('Change User Role'),
                subtitle: Text('Current: ${role.toUpperCase()}'),
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
                title: const Text('Inspect KYC Verification Documents'),
                subtitle: const Text('National Identity Card, Land Deeds, Driving License'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(bCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VerificationReviewScreen()),
                  );
                },
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Contact: $phone · $email',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, String uid, String name, String currentRole, FarmoraState state) {
    String selected = currentRole.toLowerCase();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          title: Text('Change Role for $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v ?? selected),
                child: const Column(
                  children: [
                    RadioListTile<String>(value: 'farmer', title: Text('Farmer (Grower/Producer)')),
                    RadioListTile<String>(value: 'buyer', title: Text('Buyer (Wholesaler/Retailer)')),
                    RadioListTile<String>(value: 'transporter', title: Text('Transporter (Logistics Provider)')),
                    RadioListTile<String>(value: 'admin', title: Text('Admin (Platform Operations)')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await state.updateUserRole(userId: uid, role: selected);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated $name role to ${selected.toUpperCase()}')),
                  );
                }
              },
              child: const Text('Confirm Role Change'),
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
    final name = (user['name'] ?? 'Unknown User').toString();
    final role = (user['role'] ?? 'farmer').toString();
    final district = (user['district'] ?? 'Sri Lanka').toString();
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
          '${role.toUpperCase()} · $district${phone.isNotEmpty ? ' · $phone' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Suspended', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Active', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
