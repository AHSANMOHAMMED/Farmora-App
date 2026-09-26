import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/verification_model.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class VerificationReviewScreen extends StatefulWidget {
  const VerificationReviewScreen({super.key});

  @override
  State<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState extends State<VerificationReviewScreen> {
  String _filterStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final verificationDocs = state.verificationDocs;

    final filteredDocs = verificationDocs.where((doc) {
      return _filterStatus == 'all' ||
          doc.status.name.toLowerCase() == _filterStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: filteredDocs.isEmpty
                ? _buildEmptyState()
                : _buildVerificationList(filteredDocs),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.adminVerificationTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.adminVerificationSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final l = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip(l.commonAll, _filterStatus == 'all', () {
            setState(() => _filterStatus = 'all');
          }),
          const SizedBox(width: 8),
          _buildFilterChip(l.statusPending, _filterStatus == 'pending', () {
            setState(() => _filterStatus = 'pending');
          }),
          const SizedBox(width: 8),
          _buildFilterChip(l.statusApproved, _filterStatus == 'approved', () {
            setState(() => _filterStatus = 'approved');
          }),
          const SizedBox(width: 8),
          _buildFilterChip(l.statusRejected, _filterStatus == 'rejected', () {
            setState(() => _filterStatus = 'rejected');
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimaryContainer,
      backgroundColor: AppColors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.onPrimaryContainer
            : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.adminVerificationEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.adminVerificationEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationList(List<VerificationDoc> docs) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _buildVerificationCard(doc);
      },
    );
  }

  Widget _buildVerificationCard(VerificationDoc doc) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(doc.status),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showVerificationDetail(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    doc.icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.displayDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(doc.status),
                ],
              ),
              if (doc.fileName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc.fileName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (doc.fileSizeInfo != null)
                        Text(
                          doc.fileSizeInfo!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (doc.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(VerificationStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case VerificationStatus.pending:
        backgroundColor = AppColors.surfaceContainerHighest;
        textColor = AppColors.onSurfaceVariant;
        label = context.l10n.statusPending;
        break;
      case VerificationStatus.approved:
        backgroundColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        label = context.l10n.statusApproved;
        break;
      case VerificationStatus.rejected:
        backgroundColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        label = context.l10n.statusRejected;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.outlineVariant;
      case VerificationStatus.approved:
        return AppColors.primary;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  void _showVerificationDetail(VerificationDoc doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VerificationDetailSheet(doc: doc),
    );
  }
}

class _VerificationDetailSheet extends StatefulWidget {
  final VerificationDoc doc;

  const _VerificationDetailSheet({required this.doc});

  @override
  State<_VerificationDetailSheet> createState() =>
      _VerificationDetailSheetState();
}

/// Resolved Storage file for a verification document.
class _DocFile {
  final String storagePath;
  final String? url;
  final bool isImage;
  final String? ownerId;
  final String? rejectionReason;
  final String? error;

  const _DocFile({
    required this.storagePath,
    this.url,
    this.isImage = false,
    this.ownerId,
    this.rejectionReason,
    this.error,
  });
}

class _VerificationDetailSheetState extends State<_VerificationDetailSheet> {
  final _rejectionReasonController = TextEditingController();
  bool _isApproving = false;
  bool _showRejectForm = false;
  bool _isRejecting = false;
  late Future<_DocFile> _fileFuture;

  bool get _busy => _isApproving || _isRejecting;

  @override
  void initState() {
    super.initState();
    _fileFuture = _loadFile();
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'bmp'];

  /// Reads the verification doc for its `storagePath` and owner, then
  /// resolves a download URL for the uploaded file.
  Future<_DocFile> _loadFile() async {
    String storagePath = '';
    String? ownerId;
    String? rejectionReason;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('verification_docs')
          .doc(widget.doc.id)
          .get();
      final data = snap.data() ?? const <String, dynamic>{};
      storagePath = (data['storagePath'] ?? '').toString();
      ownerId = (data['ownerId'] ?? data['farmerId'] ?? data['userId'])
          ?.toString();
      rejectionReason = data['rejectionReason']?.toString();
    } catch (_) {
      // Fall back to the path carried in the model below.
    }
    if (storagePath.isEmpty &&
        widget.doc.description.trim().startsWith('verification/')) {
      storagePath = widget.doc.description.trim();
    }
    if (storagePath.isEmpty) {
      return _DocFile(
        storagePath: '',
        ownerId: ownerId,
        rejectionReason: rejectionReason,
        error: 'No uploaded file is linked to this document.',
      );
    }
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      final url = await ref.getDownloadURL();
      String? contentType;
      try {
        contentType = (await ref.getMetadata()).contentType;
      } catch (_) {
        contentType = null;
      }
      final ext = storagePath.split('.').last.toLowerCase();
      final isImage = contentType != null
          ? contentType.startsWith('image/')
          : _imageExtensions.contains(ext);
      return _DocFile(
        storagePath: storagePath,
        url: url,
        isImage: isImage,
        ownerId: ownerId,
        rejectionReason: rejectionReason,
      );
    } catch (e) {
      return _DocFile(
        storagePath: storagePath,
        ownerId: ownerId,
        rejectionReason: rejectionReason,
        error: userMessage(e, action: 'load the verification file'),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Could not open the document.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'open the document'))));
    }
  }

  String? _ownerLabel(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return null;
    final users = context.read<FarmoraState>().users;
    for (final u in users) {
      final uid = (u['uid'] ?? u['id'] ?? '').toString();
      if (uid == ownerId) {
        final name = (u['displayName'] ?? u['name'] ?? '').toString();
        final role = (u['role'] ?? '').toString();
        if (name.isEmpty) return ownerId;
        return role.isEmpty ? name : '$name ($role)';
      }
    }
    return ownerId;
  }

  Widget _buildFileSection(_DocFile file) {
    final l = context.l10n;
    final owner = _ownerLabel(file.ownerId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (owner != null)
          _buildDetailRow(Icons.person_outline, 'Submitted by', owner),
        if (file.storagePath.isNotEmpty)
          _buildDetailRow(Icons.description, l.adminVerificationFileName,
              file.storagePath.split('/').last),
        if ((file.rejectionReason ?? '').isNotEmpty &&
            widget.doc.status == VerificationStatus.rejected)
          _buildDetailRow(Icons.block, l.adminVerificationRejectionReason,
              file.rejectionReason!),
        const SizedBox(height: 8),
        Text(
          l.adminVerificationDocument,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (file.url == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(file.error ?? l.errorGeneric)),
                TextButton(
                  onPressed: () =>
                      setState(() => _fileFuture = _loadFile()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (file.isImage) ...[
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Image.network(file.url!, fit: BoxFit.contain),
                ),
              ),
            ),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  file.url!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(l.adminVerificationDocument),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openUrl(file.url!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open full size'),
            ),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openUrl(file.url!),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open document'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final canReview = doc.status == VerificationStatus.pending;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  doc.icon,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.displayTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        doc.displayDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            _buildStatusChip(doc.status),
            const SizedBox(height: 16),

            // Document info
            if (doc.fileName != null) ...[
              _buildDetailRow(Icons.description,
                  context.l10n.adminVerificationFileName, doc.fileName!),
              if (doc.fileSizeInfo != null)
                _buildDetailRow(Icons.storage,
                    context.l10n.adminVerificationFileSize, doc.fileSizeInfo!),
            ],

            if (doc.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Uploaded file from Storage
            FutureBuilder<_DocFile>(
              future: _fileFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final file = snap.data ??
                    _DocFile(
                        storagePath: '',
                        error: snap.error == null
                            ? null
                            : userMessage(snap.error!,
                                action: 'load the verification file'));
                return _buildFileSection(file);
              },
            ),

            const SizedBox(height: 24),

            // Review actions
            if (canReview) ...[
              if (_showRejectForm) ...[
                Text(
                  context.l10n.adminVerificationRejectionReason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rejectionReasonController,
                  enabled: !_busy,
                  maxLines: 3,
                  maxLength: 300,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.l10n.adminVerificationRejectionHint,
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy || _showRejectForm
                          ? null
                          : () => _handleApprove(),
                      icon: _isApproving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isApproving
                            ? context.l10n.adminVerificationApproving
                            : context.l10n.adminVerificationApprove,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () =>
                              setState(() => _showRejectForm = !_showRejectForm),
                      icon: _showRejectForm
                          ? const Icon(Icons.close)
                          : const Icon(Icons.cancel),
                      label: Text(
                        _showRejectForm
                            ? context.l10n.commonCancel
                            : context.l10n.adminVerificationReject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showRejectForm) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ||
                            _rejectionReasonController.text.trim().isEmpty
                        ? null
                        : () => _handleReject(),
                    icon: _isRejecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.block),
                    label: Text(context.l10n.adminVerificationConfirmRejection),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Already reviewed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: doc.status == VerificationStatus.approved
                      ? AppColors.primaryContainer
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      doc.status == VerificationStatus.approved
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: doc.status == VerificationStatus.approved
                          ? AppColors.onPrimaryContainer
                          : AppColors.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        doc.status == VerificationStatus.approved
                            ? context.l10n.adminVerificationDocApproved
                            : context.l10n.adminVerificationDocRejected,
                        style: TextStyle(
                          color: doc.status == VerificationStatus.approved
                              ? AppColors.onPrimaryContainer
                              : AppColors.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(VerificationStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case VerificationStatus.pending:
        backgroundColor = AppColors.surfaceContainerHighest;
        textColor = AppColors.onSurfaceVariant;
        label = context.l10n.adminVerificationPendingReview;
        break;
      case VerificationStatus.approved:
        backgroundColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        label = context.l10n.statusApproved;
        break;
      case VerificationStatus.rejected:
        backgroundColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        label = context.l10n.statusRejected;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == VerificationStatus.pending
                ? Icons.pending
                : status == VerificationStatus.approved
                    ? Icons.check_circle
                    : Icons.cancel,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported,
            size: 32,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Approve/reject go through the `reviewVerification` callable; the
  /// verification stream shows the new status. Success is shown only after
  /// the call returns.
  Future<void> _handleApprove() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    setState(() => _isApproving = true);
    try {
      await FirestoreService().reviewVerificationDoc(
        documentId: widget.doc.id,
        status: 'approved',
      );
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(l.adminVerificationApprovedSnack),
        ),
      );
      if (mounted) navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(l.adminVerificationApproveFailed(
              userMessage(error, action: 'approve verification document'))),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _handleReject() async {
    final reason = _rejectionReasonController.text.trim();
    if (reason.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    setState(() => _isRejecting = true);
    try {
      await FirestoreService().reviewVerificationDoc(
        documentId: widget.doc.id,
        status: 'rejected',
        reason: reason,
      );
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(l.adminVerificationRejectedSnack),
        ),
      );
      if (mounted) navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(l.adminVerificationRejectFailed(
              userMessage(error, action: 'reject verification document'))),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }
}
