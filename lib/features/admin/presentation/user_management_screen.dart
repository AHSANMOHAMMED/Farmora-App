import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/navigation/app_navigator.dart';
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


  bool _isSeeding = false;

  Future<void> _seedTestUsers(BuildContext context) async {
    if (_isSeeding) return;
    setState(() => _isSeeding = true);
    final state = context.read<FarmoraState>();
    final db = FirebaseFirestore.instance;
    
    final roles = [
      {'role': 'farmer', 'name': 'Test Farmer', 'phone': '0710000001'},
      {'role': 'buyer', 'name': 'Test Buyer', 'phone': '0710000002'},
      {'role': 'transporter', 'name': 'Test Transporter', 'phone': '0710000003'},
      {'role': 'supplier', 'name': 'Test Supplier', 'phone': '0710000004'},
      {'role': 'expert', 'name': 'Test Expert', 'phone': '0710000005'},
    ];
    
    Map<String, String> uids = {};
    
    // 1. Seed Users (Smart check: only create if they don't exist)
    for (final r in roles) {
        final snap = await db.collection('users').where('phone', isEqualTo: r['phone']).limit(1).get();
        if (snap.docs.isNotEmpty) {
            uids[r['role']!] = snap.docs.first.id;
        } else {
            try {
                await state.adminCreateUser(
                  name: r['name']!,
                  phone: r['phone']!,
                  role: r['role']!,
                  password: 'password123',
                  district: 'Colombo',
                );
                final newSnap = await db.collection('users').where('phone', isEqualTo: r['phone']).limit(1).get();
                if (newSnap.docs.isNotEmpty) uids[r['role']!] = newSnap.docs.first.id;
            } catch (e) {
                debugPrint('Failed to seed user ${r['role']}: $e');
            }
        }
    }
    
    final farmerId = uids['farmer'];
    final buyerId = uids['buyer'];
    final transId = uids['transporter'];
    
    final now = FieldValue.serverTimestamp();
    
    if (farmerId != null) {
      final cropNames = ['Tomatoes', 'Carrots', 'Potatoes', 'Onions', 'Cabbage', 'Chili', 'Beans', 'Pumpkin', 'Brinjal', 'Beetroot'];
      final batch = db.batch();
      
      // 2. Seed Crop Plans & 3. Tasks
      final List<String> cropIds = [];
      for (int i = 0; i < 15; i++) {
        final cropName = cropNames[i % cropNames.length];
        final cropRef = db.collection('crop_plans').doc();
        cropIds.add(cropRef.id);
        batch.set(cropRef, {
          'farmerId': farmerId,
          'cropName': 'Organic $cropName',
          'area': (i + 1) * 1.5,
          'areaUnit': 'Acres',
          'plantedAt': now,
          'expectedHarvestAt': now,
          'notes': 'Test crop plan $i',
          'createdAt': now,
          'updatedAt': now,
        });
        
        final taskRef = db.collection('farm_tasks').doc();
        batch.set(taskRef, {
          'farmerId': farmerId,
          'cropId': cropRef.id,
          'cropName': 'Organic $cropName',
          'title': 'Farm Task $i for $cropName',
          'description': 'Description for task $i',
          'dueAt': now,
          'priority': i % 2 == 0 ? 'High' : 'Normal',
          'status': i % 3 == 0 ? 'completed' : 'pending',
          'createdAt': now,
          'updatedAt': now,
        });
      }

      // 4. Seed Products (Harvest)
      final List<String> productIds = [];
      for (int i = 0; i < 15; i++) {
        final cropName = cropNames[i % cropNames.length];
        final prodRef = db.collection('products').doc();
        productIds.add(prodRef.id);
        batch.set(prodRef, {
          'farmerId': farmerId,
          'name': 'Fresh $cropName',
          'category': 'Vegetables',
          'location': 'Colombo, Sri Lanka',
          'quantityAvailable': 100 + (i * 50),
          'unit': 'kg',
          'priceMinor': 45000 + (i * 5000),
          'emoji': '🌱',
          'color': 0xFFFFEbee,
          'status': 'Active',
          'isOrganic': true,
          'trustLevel': 'Verified',
          'description': 'Freshly picked organic $cropName.',
          'harvestStatus': 'harvested',
          'images': [],
          'media': [],
          'currency': 'LKR',
          'createdAt': now,
          'updatedAt': now,
        });
      }
      
      // 5. Seed Notifications
      for (int i = 0; i < 15; i++) {
        final notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': farmerId,
          'title': 'Notification $i',
          'body': 'This is a test notification number $i for your account.',
          'type': 'general',
          'read': i % 4 == 0,
          'createdAt': now,
        });
      }
      
      // 6. Seed Orders if buyer exists
      if (buyerId != null) {
        for (int i = 0; i < 15; i++) {
          final prodId = productIds[i % productIds.length];
          final cropName = cropNames[i % cropNames.length];
          final orderRef = db.collection('orders').doc();
          batch.set(orderRef, {
            'buyerId': buyerId,
            'farmerId': farmerId,
            'productId': prodId,
            'product': {
               'name': 'Fresh $cropName',
               'category': 'Vegetables',
               'unit': 'kg',
               'priceMinor': 45000 + (i * 1000),
               'isOrganic': true,
            },
            'buyerName': 'Test Buyer',
            'farmerName': 'Test Farmer',
            'quantity': 25 + i,
            'unitPriceMinor': 45000 + (i * 1000),
            'deliveryFeeMinor': 50000,
            'grossAmount': ((25 + i) * (45000 + (i * 1000))) + 50000,
            'status': i % 3 == 0 ? 'completed' : 'pending',
            'paymentMethod': 'cod',
            'deliveryAddress': '123 Test Road, Colombo',
            'createdAt': now,
            'updatedAt': now,
          });

          // 7. Seed Transport Jobs
          if (transId != null) {
            final job = db.collection('transport_jobs').doc();
            batch.set(job, {
              'orderId': orderRef.id,
              'buyerId': buyerId,
              'farmerId': farmerId,
              'productName': 'Fresh $cropName',
              'quantity': 25 + i,
              'unit': 'kg',
              'pickupAddress': 'Farmer Location, Colombo',
              'deliveryAddress': '123 Test Road, Colombo',
              'feeMinor': 40000 + (i * 2000),
              'distanceKm': 15.5 + i,
              'status': i % 4 == 0 ? 'accepted' : 'requested',
              'transporterId': i % 4 == 0 ? transId : null,
              'createdAt': now,
              'updatedAt': now,
            });
          }
        }
      }
      

      // 8. Seed Admin Data (Market Prices, Settlements, Audit Logs, Reports, Disputes, Verifications)
      final List<String> cropTypes = ['Tomatoes', 'Carrots', 'Potatoes', 'Onions', 'Cabbage', 'Chili'];
      for (int i = 0; i < 10; i++) {
        final crop = cropTypes[i % cropTypes.length];
        
        // Market Prices
        final marketRef = db.collection('market_prices').doc();
        batch.set(marketRef, {
          'commodityId': 'comm_$i',
          'commodityName': crop,
          'category': 'Vegetables',
          'unit': 'kg',
          'averagePriceMinor': 45000 + (i * 2000),
          'lowestPriceMinor': 40000 + (i * 2000),
          'highestPriceMinor': 50000 + (i * 2000),
          'trend': i % 2 == 0 ? 'up' : 'down',
          'marketCenter': 'Colombo',
          'updatedAt': now,
        });

        // Settlements
        final settlementRef = db.collection('settlements').doc();
        batch.set(settlementRef, {
          'orderId': 'order_$i',
          'orderNumber': 'ORD-${1000 + i}',
          'recipientId': farmerId,
          'recipientName': 'Test Farmer',
          'recipientRole': 'farmer',
          'grossAmount': 10000.0,
          'platformFee': 500.0,
          'netAmount': 9500.0,
          'bankName': 'BOC',
          'accountNumber': '12345678',
          'payoutMethod': 'CEFT',
          'status': i % 3 == 0 ? 'settled' : 'pending',
          'createdAt': now,
          'updatedAt': now,
        });

        // Audit Logs
        final auditRef = db.collection('audit_logs').doc();
        batch.set(auditRef, {
          'actorId': farmerId,
          'actorRole': 'farmer',
          'action': 'USER_LOGIN',
          'targetId': farmerId,
          'details': 'User logged in',
          'timestamp': now,
          'ipAddress': '127.0.0.1',
        });

        // Reports
        final reportRef = db.collection('reports').doc();
        batch.set(reportRef, {
          'reporterId': buyerId,
          'reportedId': farmerId,
          'reason': 'Spam content',
          'details': 'This listing is fake.',
          'status': 'open',
          'createdAt': now,
        });

        // Disputes
        final disputeRef = db.collection('disputes').doc();
        batch.set(disputeRef, {
          'orderId': 'order_$i',
          'plaintiffId': buyerId,
          'plaintiffRole': 'buyer',
          'defendantId': farmerId,
          'defendantRole': 'farmer',
          'reason': 'Quality mismatch',
          'description': 'The tomatoes were rotten.',
          'status': 'open',
          'resolution': '',
          'createdAt': now,
          'updatedAt': now,
        });

        // Verifications
        final verifRef = db.collection('verifications').doc();
        batch.set(verifRef, {
          'userId': transId,
          'userName': 'Test Transporter',
          'userRole': 'transporter',
          'documentType': 'nic',
          'documentUrl': 'https://example.com/doc.jpg',
          'status': 'pending',
          'submittedAt': now,
        });
      }
      
      // Commit all data in one fast batch!

      await batch.commit();
    }
    
    setState(() => _isSeeding = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully seeded 75+ items instantly!')),
    );
  }

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
        actions: [
          if (_isSeeding)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton.icon(
              onPressed: () => _seedTestUsers(context),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Seed Data'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
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
                for (final r in const [
                  Role.supplier,
                  Role.driver,
                  Role.warehouse,
                  Role.inspector,
                  Role.expert,
                  Role.finance,
                ]) ...[
                  const SizedBox(width: 8),
                  _buildRoleChip(r.name, r.label, color: const Color(0xFF455A64)),
                ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, state),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, FarmoraState state) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    String selectedRole = 'driver';
    String selectedDistrict = 'Colombo';
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isSubmitting = false;
    String? formError;

    final allowedRoles = [
      {'key': 'driver', 'label': 'Driver (Logistics)'},
      {'key': 'transporter', 'label': 'Transporter'},
      {'key': 'supplier', 'label': 'Input Supplier'},
      {'key': 'warehouse', 'label': 'Warehouse Manager'},
      {'key': 'inspector', 'label': 'Quality Inspector'},
      {'key': 'expert', 'label': 'Agricultural Expert'},
      {'key': 'finance', 'label': 'Finance Officer'},
      {'key': 'farmer', 'label': 'Farmer'},
      {'key': 'buyer', 'label': 'Buyer'},
    ];

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Create New Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Text('Select Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: allowedRoles.map((r) => DropdownMenuItem(
                        value: r['key'],
                        child: Text(r['label']!),
                      )).toList(),
                      onChanged: isSubmitting ? null : (val) {
                        if (val != null) setDlgState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'e.g. Kamal Perera',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: phoneCtrl,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. 0771234567',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        final clean = v.replaceAll(RegExp(r'[\s\-()]'), '');
                        if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(clean)) {
                          return 'Enter a valid phone number (e.g. 07XXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Email Address (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: emailCtrl,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. member@example.com (optional)',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('District', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
                        'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
                        'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
                        'Matale', 'Matara', 'Monaragala', 'Mullaitivu', 'Nuwara Eliya',
                        'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
                      ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: isSubmitting ? null : (val) {
                        if (val != null) setDlgState(() => selectedDistrict = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Create Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: passwordCtrl,
                      enabled: !isSubmitting,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Minimum 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDlgState(() => obscurePassword = !obscurePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Password is required';
                        if (v.trim().length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Confirm Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: confirmPasswordCtrl,
                      enabled: !isSubmitting,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Re-enter password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDlgState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please confirm the password';
                        if (v != passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() {
                        isSubmitting = true;
                        formError = null;
                      });
                      try {
                        await state.adminCreateUser(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          role: selectedRole,
                          password: passwordCtrl.text,
                          district: selectedDistrict,
                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Member "${nameCtrl.text.trim()}" created successfully!'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        final cleanMsg = e.toString()
                            .replaceFirst('Exception: ', '')
                            .replaceFirst('FarmoraAuthException: ', '');
                        setDlgState(() {
                          isSubmitting = false;
                          formError = cleanMsg;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Member', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
                  AppNavigator.push(context, const VerificationReviewScreen());
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
                    for (final r in const [
                      Role.supplier,
                      Role.driver,
                      Role.warehouse,
                      Role.inspector,
                      Role.expert,
                      Role.finance,
                    ])
                      RadioListTile<String>(value: r.name, title: Text(r.label)),
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
