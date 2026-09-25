import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../models/verification_model.dart';
import '../../../providers/farmora_state.dart';
import '../../farmer/presentation/account_verification_screen.dart';

/// Professional, full-featured Awaiting Verification screen shown to
/// Farmers, Buyers, and Logistics Providers whose profiles are pending verification.
///
/// Features:
/// - Real-time approval listener (unblocks as soon as Admin approves in portal)
/// - Document submission checklist (NIC, Business Registration, Land Deeds, Vehicle Docs)
/// - Direct action to complete KYC requirements via [AccountVerificationScreen]
/// - Contact Admin / Refresh status trigger
class AwaitingVerificationView extends StatelessWidget {
  const AwaitingVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final docs = state.verificationDocs;
    final approvedCount =
        docs.where((d) => d.status == VerificationStatus.approved).length;
    final pendingCount =
        docs.where((d) => d.status == VerificationStatus.pending).length;
    final rejectedCount =
        docs.where((d) => d.status == VerificationStatus.rejected).length;

    final roleLabel = switch (role) {
      Role.farmer => 'Farmer Partner',
      Role.buyer => 'Wholesale Buyer',
      Role.transporter => 'Logistics Provider',
      Role.admin => 'Administrator',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ── Header Icon Badge ──
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 46,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Title & Role Subtitle ──
              Text(
                'Verification Under Review',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Profile Role: $roleLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Welcome, ${state.displayName.isNotEmpty ? state.displayName : "Partner"}! To protect our marketplace and maintain agricultural trade integrity, platform administrators must verify your credentials before your trading dashboard becomes active.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // ── Status Overview Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'KYC Document Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: rejectedCount > 0
                                ? AppColors.errorContainer
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rejectedCount > 0
                                ? 'Action Required'
                                : 'Pending Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: rejectedCount > 0
                                  ? AppColors.onErrorContainer
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Metrics row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Uploaded',
                            '${docs.length}',
                            Icons.upload_file_rounded,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            'Approved',
                            '$approvedCount',
                            Icons.check_circle_outline_rounded,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            'Pending',
                            '$pendingCount',
                            Icons.pending_actions_rounded,
                            Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick list of requirements
                    const Text(
                      'Verification Checklist:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (role == Role.farmer) ...[
                      _buildCheckItem('National Identity Card (NIC) / Passport', docs),
                      _buildCheckItem('Land Deed or Agrarian Services Permit', docs),
                      _buildCheckItem('Bank Details & Produce Declaration', docs),
                    ] else if (role == Role.transporter) ...[
                      _buildCheckItem('National Identity Card (NIC)', docs),
                      _buildCheckItem('Driving License & Revenue License', docs),
                      _buildCheckItem('Vehicle Registration & Goods Transit Insurance', docs),
                    ] else ...[
                      _buildCheckItem('Business Registration (BR) or NIC', docs),
                      _buildCheckItem('Wholesale License / Purchasing Permit', docs),
                      _buildCheckItem('Payment / Bank Settlement Details', docs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ──
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountVerificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(
                  docs.isEmpty
                      ? 'Upload Required Documents'
                      : 'Complete / Update Documents',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  if (state.currentUserId.isNotEmpty) {
                    state.initFromFirestore(state.currentUserId);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking latest verification status...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Admin Notice Footnote ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verification typically takes 1-2 business hours. Once Platform Admin verifies your profile, your trading dashboard and marketplace features will activate automatically.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, List<VerificationDoc> docs) {
    final matchedDoc = docs.where((d) =>
        d.title.toLowerCase().contains(title.toLowerCase().split(' ').first) ||
        title.toLowerCase().contains(d.title.toLowerCase())).firstOrNull;

    final isApproved = matchedDoc?.status == VerificationStatus.approved;
    final isUploaded = matchedDoc != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : isUploaded
                    ? Icons.hourglass_bottom_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isApproved
                ? Colors.green
                : isUploaded
                    ? Colors.amber.shade700
                    : AppColors.outlineVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isApproved
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isApproved ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
