import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AccountVerificationScreen extends StatelessWidget {
  const AccountVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Account Verification',
          style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildProfileAvatar(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pending Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Color(0xFF93000A)),
                          SizedBox(width: 8),
                          Text(
                            'Pending Verification',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF93000A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please upload the required documents below to verify your account and gain full access to the marketplace.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF93000A), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── National ID Card Section ──
                _buildDocSection(
                  title: 'National ID Card',
                  badge: 'Required',
                  badgeColor: const Color(0xFFE8F5E9),
                  badgeTextColor: const Color(0xFF2E7D32),
                  description: 'Upload a clear photo of the front and back of your valid National ID.',
                  child: Row(
                    children: [
                      Expanded(child: _buildUploadBox('Front', Icons.add_photo_alternate_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUploadBox('Back', Icons.add_photo_alternate_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Farm Document Section ──
                _buildDocSection(
                  title: 'Farm Document',
                  badge: 'Optional',
                  badgeColor: const Color(0xFFF3F4F6),
                  badgeTextColor: AppColors.onSurfaceVariant,
                  description: 'Upload your farm registration or land ownership proof for a verified badge.',
                  child: _buildUploadBox('Tap to upload document', Icons.upload_file_outlined),
                ),
                const SizedBox(height: 16),

                // ── Vehicle Details Section ──
                _buildDocSection(
                  title: 'Vehicle Details',
                  badge: 'Required',
                  badgeColor: const Color(0xFFE8F5E9),
                  badgeTextColor: const Color(0xFF2E7D32),
                  description: 'For logistics partners, provide details of your transport vehicle.',
                  child: Column(
                    children: [
                      _buildUploadRow('Vehicle License', 'Upload current license', Icons.directions_car_outlined),
                      const SizedBox(height: 10),
                      _buildUploadRow('Vehicle Photo', 'Clear exterior photo', Icons.local_shipping_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Submit Button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.primary, content: Text('Documents submitted for verification review!')),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.verified_outlined, size: 20),
                label: const Text(
                  'Submit for Verification',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildDocSection({
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String description,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  badge,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: badgeTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadBox(String label, IconData icon) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRow(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.upload, size: 20, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
