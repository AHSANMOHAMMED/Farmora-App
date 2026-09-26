import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// One entry of the fixed, role-specific required-document checklist.
class _RequiredDoc {
  const _RequiredDoc({
    required this.documentType,
    required this.label,
    required this.description,
    required this.icon,
    required this.keywords,
  });

  /// Value stored as `documentType` by the `submitVerification` callable.
  final String documentType;
  final String label;
  final String description;
  final IconData icon;

  /// Lower-case fragments used to match already-uploaded Firestore docs.
  final List<String> keywords;

  bool matches(String rawType) {
    final n = rawType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    final words = n.trim().split(' ');
    for (final k in keywords) {
      if (k.contains(' ')) {
        if (n.contains(k)) return true;
      } else if (words.contains(k) || (k.length > 4 && n.contains(k))) {
        return true;
      }
    }
    return false;
  }
}

/// A Firestore `verification_docs` row owned by the signed-in user.
class _UploadedDoc {
  _UploadedDoc(this.id, Map<String, dynamic> data)
      : documentType =
            (data['documentType'] ?? data['title'] ?? '').toString(),
        storagePath = (data['storagePath'] ?? data['fileName'])?.toString(),
        rejectionReason =
            (data['rejectionReason'] ?? data['errorMessage'])?.toString(),
        status = switch ((data['status'] ?? 'pending').toString()) {
          'approved' => VerificationStatus.approved,
          'rejected' => VerificationStatus.rejected,
          _ => VerificationStatus.pending,
        },
        createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String documentType;
  final String? storagePath;
  final String? rejectionReason;
  final VerificationStatus status;
  final DateTime createdAt;

  String get fileName {
    final p = storagePath ?? '';
    final base = p.split('/').last;
    // Uploaded names are `<millis>_<original name>`.
    final i = base.indexOf('_');
    return i > 0 && int.tryParse(base.substring(0, i)) != null
        ? base.substring(i + 1)
        : base;
  }
}

List<_RequiredDoc> _requiredDocsFor(Role role) {
  switch (role) {
    case Role.transporter:
      return [
        _RequiredDoc(
          documentType: 'NIC',
          label: VerificationDoc.documentTypeLabel('NIC'),
          description: 'National Identity Card (front and back in one file).',
          icon: Icons.badge_outlined,
          keywords: const ['nic', 'national id'],
        ),
        _RequiredDoc(
          documentType: 'Driving Licence',
          label: VerificationDoc.documentTypeLabel('Driving Licence'),
          description: 'A valid driving licence for your vehicle class.',
          icon: Icons.credit_card_outlined,
          keywords: const ['driving', 'driver'],
        ),
        _RequiredDoc(
          documentType: 'Vehicle Registration',
          label: VerificationDoc.documentTypeLabel('Vehicle Registration'),
          description: 'Certificate of registration for the delivery vehicle.',
          icon: Icons.local_shipping_outlined,
          keywords: const ['vehicle', 'registration', 'revenue licen'],
        ),
        _RequiredDoc(
          documentType: 'Insurance',
          label: VerificationDoc.documentTypeLabel('Insurance'),
          description: 'Current vehicle insurance certificate.',
          icon: Icons.shield_outlined,
          keywords: const ['insurance'],
        ),
      ];
    case Role.buyer:
      return [
        const _RequiredDoc(
          documentType: 'NIC or Business Registration',
          label: 'NIC or Business Registration',
          description:
              'Your National Identity Card, or the business registration '
              'certificate if you buy as a company.',
          icon: Icons.badge_outlined,
          keywords: ['nic', 'national id', 'business', 'br'],
        ),
      ];
    case Role.farmer:
    case Role.admin:
      return [
        _RequiredDoc(
          documentType: 'NIC',
          label: VerificationDoc.documentTypeLabel('NIC'),
          description: 'National Identity Card (front and back in one file).',
          icon: Icons.badge_outlined,
          keywords: const ['nic', 'national id'],
        ),
        const _RequiredDoc(
          documentType: 'Land Deed / Agrarian Permit',
          label: 'Land Deed / Agrarian Permit',
          description:
              'Land ownership deed, lease, or agrarian services permit for '
              'your farm.',
          icon: Icons.description_outlined,
          keywords: ['land', 'deed', 'agrarian', 'farmer registration'],
        ),
        _RequiredDoc(
          documentType: 'Bank Proof',
          label: VerificationDoc.documentTypeLabel('Bank Proof'),
          description:
              'Bank passbook page or statement showing your name and '
              'account number.',
          icon: Icons.account_balance_outlined,
          keywords: const ['bank', 'passbook'],
        ),
      ];
  }
}

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  final _service = FirestoreService();

  /// documentType currently uploading (null when idle).
  String? _uploadingType;
  final _vehicleTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _districtsController = TextEditingController();
  bool _savingProfile = false;
  Stream<List<_UploadedDoc>>? _docsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _docsStream = FirebaseFirestore.instance
          .collection('verification_docs')
          .where('farmerId', isEqualTo: uid)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => _UploadedDoc(d.id, d.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
            vehicleCapacity: int.tryParse(_capacityController.text.trim()) ?? 0,
            vehicleCapacityUnit: 'kg',
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
              content: Text(context.l10n.farmerVerificationSaveFailed(
                  userMessage(e, action: 'save vehicle profile')))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  /// Uploads to Storage `verification/{uid}/…` and registers the file with the
  /// `submitVerification` callable, which creates a pending review doc.
  Future<void> _pickDocument(String documentType) async {
    if (_uploadingType != null) return;
    final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false);
    final file = result?.files.single;
    if (file == null) return;
    if (file.bytes == null) return;
    if (!mounted) return;
    setState(() => _uploadingType = documentType);
    try {
      final ext = (file.extension ?? '').toLowerCase();
      final contentType = ext == 'pdf'
          ? 'application/pdf'
          : 'image/${ext == 'jpg' ? 'jpeg' : ext}';
      final path = await _service.uploadVerificationDocument(
          bytes: file.bytes!, fileName: file.name, contentType: contentType);
      await _service.submitVerification(
          documentType: documentType, storagePath: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.farmerVerificationUploadedQueued)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.farmerVerificationUploadFailed(
                userMessage(error, action: 'upload verification document')))));
      }
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final role = state.role;
    final isTransporter = role == Role.transporter;
    final required = _requiredDocsFor(role);
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
      body: StreamBuilder<List<_UploadedDoc>>(
        stream: _docsStream,
        builder: (context, snapshot) {
          final uploaded = snapshot.data ?? const <_UploadedDoc>[];
          // Latest upload per required type; everything else is "other".
          final matched = <String, _UploadedDoc>{};
          final used = <String>{};
          for (final req in required) {
            for (final doc in uploaded) {
              if (used.contains(doc.id)) continue;
              if (doc.documentType == req.documentType ||
                  req.matches(doc.documentType)) {
                matched[req.documentType] = doc;
                break;
              }
            }
            final m = matched[req.documentType];
            if (m != null) {
              // Older uploads of the same type are superseded, not "other".
              for (final doc in uploaded) {
                if (doc.documentType == m.documentType ||
                    req.matches(doc.documentType)) {
                  used.add(doc.id);
                }
              }
            }
          }
          final others =
              uploaded.where((d) => !used.contains(d.id)).toList();
          final approvedCount = required
              .where((r) =>
                  matched[r.documentType]?.status ==
                  VerificationStatus.approved)
              .length;
          final missingCount =
              required.where((r) => matched[r.documentType] == null).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12),
                _buildProgress(
                  approved: approvedCount,
                  total: required.length,
                  missing: missingCount,
                  isVerified: state.isVerified,
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    userMessage(snapshot.error!,
                        action: 'load verification documents'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 20),
                if (isTransporter) ...[
                  _buildVehicleSection(context),
                  const SizedBox(height: 20),
                ],
                ...required.map((req) =>
                    _buildDocCard(context, req, matched[req.documentType])),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Other uploaded documents',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...others.map((d) => _buildOtherRow(d)),
                ],
                const SizedBox(height: 8),
                Text(
                  l.farmerVerificationAllRequired,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgress({
    required int approved,
    required int total,
    required int missing,
    required bool isVerified,
  }) {
    final String text;
    if (isVerified) {
      text = 'Your account is verified.';
    } else if (missing > 0) {
      text = '$missing of $total required document'
          '${total == 1 ? '' : 's'} still to upload.';
    } else if (approved == total) {
      text = 'All documents approved. Verification will update shortly.';
    } else {
      text = 'All documents uploaded. An admin will review them soon.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending_actions_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$text  ($approved/$total approved)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection(BuildContext context) {
    final l = context.l10n;
    return Container(
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
              onPressed: _savingProfile ? null : _saveTransporterProfile,
              child: Text(_savingProfile
                  ? l.farmerSaving
                  : l.farmerVerificationSaveProfile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(VerificationStatus? status) {
    if (status == null) {
      return const StatusChip(label: 'Not uploaded', type: StatusChipType.empty);
    }
    return StatusChip(
      label: status.name,
      type: status == VerificationStatus.approved
          ? StatusChipType.approved
          : status == VerificationStatus.rejected
              ? StatusChipType.rejected
              : StatusChipType.pending,
    );
  }

  Widget _buildDocCard(
      BuildContext context, _RequiredDoc req, _UploadedDoc? doc) {
    final l = context.l10n;
    final busy = _uploadingType == req.documentType;
    final anyBusy = _uploadingType != null;
    final status = doc?.status;
    final rejected = status == VerificationStatus.rejected;
    final approved = status == VerificationStatus.approved;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: rejected
            ? Border.all(color: AppColors.error.withValues(alpha: 0.5))
            : null,
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
          Row(
            children: [
              Icon(req.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  req.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (rejected) ...[
            const SizedBox(height: 8),
            Text(
              'Rejected: ${(doc?.rejectionReason ?? '').trim().isEmpty ? 'Please upload a clearer or valid document.' : doc!.rejectionReason!.trim()}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (doc != null && doc.fileName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    approved
                        ? Icons.check_circle
                        : rejected
                            ? Icons.error_outline
                            : Icons.hourglass_top_outlined,
                    color: rejected ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.fileName,
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
                          approved
                              ? l.farmerVerificationUploaded
                              : rejected
                                  ? 'Needs a new upload'
                                  : l.svcDocUploadedForReview,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!approved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: doc == null
                  ? OutlinedButton.icon(
                      onPressed: anyBusy
                          ? null
                          : () => _pickDocument(req.documentType),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined,
                              color: AppColors.primary),
                      label: Text(
                        busy ? 'Uploading…' : l.farmerVerificationSelectFile,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: anyBusy
                          ? null
                          : () => _pickDocument(req.documentType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rejected
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        foregroundColor:
                            rejected ? Colors.white : AppColors.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay, size: 18),
                      label: Text(busy ? 'Uploading…' : l.reupload),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherRow(_UploadedDoc doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  VerificationDoc.documentTypeLabel(doc.documentType),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (doc.status == VerificationStatus.rejected &&
                    (doc.rejectionReason ?? '').trim().isNotEmpty)
                  Text(
                    doc.rejectionReason!.trim(),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error),
                  ),
              ],
            ),
          ),
          _statusChip(doc.status),
        ],
      ),
    );
  }
}
