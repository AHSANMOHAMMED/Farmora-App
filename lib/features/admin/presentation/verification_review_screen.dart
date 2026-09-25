import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/verification_model.dart';
import 'package:provider/provider.dart';
import '../../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

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

class _VerificationDetailSheetState extends State<_VerificationDetailSheet> {
  final _rejectionReasonController = TextEditingController();
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final canReview = doc.status == VerificationStatus.pending;

    return Container(
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
                onPressed: () => Navigator.pop(context),
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

          if (doc.hasFrontBack) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.adminVerificationImages,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildImagePreview(
                      context.l10n.adminVerificationFront, doc.frontImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImagePreview(
                      context.l10n.adminVerificationBack, doc.backImage),
                ),
              ],
            ),
          ] else if (doc.imagePreview != null) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.adminVerificationPreview,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildImagePreview(
                context.l10n.adminVerificationDocument, doc.imagePreview),
          ],

          const SizedBox(height: 24),

          // Review actions
          if (canReview) ...[
            if (_isRejecting) ...[
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
                maxLines: 3,
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
                    onPressed: _isApproving || _isRejecting
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
                    onPressed: _isApproving || _isRejecting
                        ? null
                        : () => setState(() => _isRejecting = !_isRejecting),
                    icon: _isRejecting
                        ? const Icon(Icons.close)
                        : const Icon(Icons.cancel),
                    label: Text(
                      _isRejecting
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
            if (_isRejecting) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _rejectionReasonController.text.trim().isEmpty
                      ? null
                      : () => _handleReject(),
                  icon: const Icon(Icons.block),
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

  Widget _buildImagePreview(String label, String? imagePath) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(label),
              ),
            )
          : _buildPlaceholder(label),
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

  Future<void> _handleApprove() async {
    setState(() => _isApproving = true);

    try {
      await FirestoreService().reviewVerificationDoc(
        documentId: widget.doc.id,
        status: 'approved',
      );

      if (mounted) {
        context.read<FarmoraState>().updateVerificationDoc(
              widget.doc.id,
              status: VerificationStatus.approved,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(context.l10n.adminVerificationApprovedSnack),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(context.l10n.adminVerificationApproveFailed(
                userMessage(error, action: 'approve verification document'))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final reason = _rejectionReasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _isRejecting = true);

    try {
      await FirestoreService().reviewVerificationDoc(
        documentId: widget.doc.id,
        status: 'rejected',
      );

      if (mounted) {
        context.read<FarmoraState>().updateVerificationDoc(
              widget.doc.id,
              status: VerificationStatus.rejected,
              errorMessage: reason,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(context.l10n.adminVerificationRejectedSnack),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(context.l10n.adminVerificationRejectFailed(
                userMessage(error, action: 'reject verification document'))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }
}
