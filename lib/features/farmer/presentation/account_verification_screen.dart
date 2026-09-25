import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/user_role.dart';
import '../../../models/verification_model.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  final _service = FirestoreService();
  bool _uploading = false;
  final _vehicleTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _districtsController = TextEditingController();
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<FarmoraState>();
      _vehicleTypeController.text = state.vehicleType;
      _capacityController.text =
          state.capacityKg > 0 ? '${state.capacityKg}' : '';
      _districtsController.text = state.serviceDistricts.join(', ');
    });
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _capacityController.dispose();
    _districtsController.dispose();
    super.dispose();
  }

  Future<void> _saveTransporterProfile() async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      final districts = _districtsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await context.read<FarmoraState>().updateTransporterProfile(
            vehicleType: _vehicleTypeController.text.trim(),
            capacityKg: int.tryParse(_capacityController.text.trim()) ?? 0,
            serviceDistricts: districts,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.farmerVerificationSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  context.l10n.farmerVerificationSaveFailed(describeError(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _pickDocument(VerificationDoc doc) async {
    if (_uploading) return;
    final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false);
    final file = result?.files.single;
    if (file == null) return;
    if (file.bytes == null) return;
    setState(() => _uploading = true);
    try {
      final contentType = file.extension == 'pdf'
          ? 'application/pdf'
          : 'image/${file.extension == 'jpg' ? 'jpeg' : file.extension}';
      final path = await _service.uploadVerificationDocument(
          bytes: file.bytes!, fileName: file.name, contentType: contentType);
      await _service.submitVerification(
          documentType: doc.title, storagePath: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.farmerVerificationUploadedQueued)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
                content: Text(context.l10n
                    .farmerVerificationUploadFailed(describeError(error)))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final docs = state.verificationDocs;
    final isTransporter = state.role == Role.transporter;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.farmerVerificationTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Intro
                Text(
                  l.farmerVerificationHeading,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.farmerVerificationIntro,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                if (isTransporter) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.farmerVerificationVehicleSection,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _vehicleTypeController,
                          decoration: InputDecoration(
                            labelText: l.vehicleType,
                            hintText: l.farmerVerificationVehicleHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l.farmerVerificationCapacity,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _districtsController,
                          decoration: InputDecoration(
                            labelText: l.farmerVerificationDistricts,
                            hintText: l.farmerVerificationDistrictsHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed:
                                _savingProfile ? null : _saveTransporterProfile,
                            child: Text(_savingProfile
                                ? l.farmerSaving
                                : l.farmerVerificationSaveProfile),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // List of Verification Cards
                ...docs.map((doc) => _buildDocCard(context, state, doc)),
              ],
            ),
          ),

          // Sticky Bottom Submit Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text(l.farmerVerificationSubmitted),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 20),
                    label: Text(
                      l.farmerVerificationSubmit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.farmerVerificationAllRequired,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(
      BuildContext context, FarmoraState state, VerificationDoc doc) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(doc.icon, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doc.displayTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: doc.status.name,
                type: doc.status == VerificationStatus.approved
                    ? StatusChipType.approved
                    : doc.status == VerificationStatus.rejected
                        ? StatusChipType.rejected
                        : StatusChipType.pending,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            doc.displayDescription,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (doc.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              doc.errorMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Content section based on document type
          if (doc.hasFrontBack) ...[
            Row(
              children: [
                Expanded(
                  child: _buildUploadTile(
                    label: l.farmerVerificationFront,
                    icon: Icons.add_a_photo_outlined,
                    onTap: () => _pickDocument(doc),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUploadTile(
                    label: l.farmerVerificationBack,
                    icon: Icons.add_a_photo_outlined,
                    onTap: () => _pickDocument(doc),
                  ),
                ),
              ],
            ),
          ] else if (doc.status == VerificationStatus.approved &&
              doc.fileName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.fileName!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc.fileSizeInfo ?? l.farmerVerificationUploaded,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ] else if (doc.imagePreview != null) ...[
            // Vehicle photo with rejected overlay
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(doc.imagePreview!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.updateVerificationDoc(
                      doc.id,
                      status: VerificationStatus.pending,
                      imagePreview: 'assets/images/roma_tomatoes_1.png',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.farmerVerificationNewPhoto)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  icon: const Icon(Icons.replay, size: 18),
                  label: Text(l.reupload),
                ),
              ),
            ),
          ] else ...[
            // Select File button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _pickDocument(doc),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.onSurfaceVariant,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.upload_file_outlined,
                    color: AppColors.primary),
                label: Text(
                  l.farmerVerificationSelectFile,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
