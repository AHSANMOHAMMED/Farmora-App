import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/dispute_model.dart';
import '../../../models/order.dart';
import '../../../services/firebase_service.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';

class CreateDisputeScreen extends StatefulWidget {
  final FarmoraOrder order;

  const CreateDisputeScreen({super.key, required this.order});

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  DisputeReason _selectedReason = DisputeReason.damagedGoods;
  final List<XFile> _evidenceFiles = [];
  final _picker = ImagePicker();
  final _service = FirestoreService();
  bool _isSubmitting = false;
  bool _isPicking = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          l.disputeCreateTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOrderInfo(),
            const SizedBox(height: 24),
            _buildReasonSelection(),
            const SizedBox(height: 24),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildEvidenceSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.buyerOrderInformation,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.receipt_long, l.buyerOrderNumberLabel, widget.order.orderNumber),
          _buildInfoRow(Icons.attach_money, l.commonTotal, AppFormat.lkr(widget.order.total, decimals: 2)),
          _buildInfoRow(Icons.calendar_today, l.buyerDate, _formatDate(widget.order.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
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

  Widget _buildReasonSelection() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.disputeReasonTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        RadioGroup<DisputeReason>(
          groupValue: _selectedReason,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedReason = value);
            }
          },
          child: Column(
            children: [
              for (final reason in DisputeReason.values)
                RadioListTile<DisputeReason>(
                  title: Text(_getReasonDisplayName(l, reason)),
                  subtitle: Text(_getReasonDescription(l, reason)),
                  value: reason,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.disputeDescriptionHelp,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l.disputeDescriptionRequired;
            }
            if (value.trim().length < 20) {
              return l.disputeDescriptionTooShort(20);
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: l.disputeDescriptionHint,
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.disputeEvidenceTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.disputeEvidenceHelp,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (_evidenceFiles.isEmpty)
          _buildAddEvidenceButton()
        else
          Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _evidenceFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snap) => snap.hasData
                                ? Image.memory(snap.data!, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.surfaceContainerHighest,
                                    child: const Icon(Icons.image, size: 32),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _evidenceFiles.removeAt(index);
                            });
                          },
                          child: Semantics(
                            button: true,
                            label: l.disputeRemovePhoto,
                            child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              _buildAddEvidenceButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildAddEvidenceButton() {
    return OutlinedButton.icon(
      onPressed: _isPicking ? null : _pickEvidence,
      icon: _isPicking
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.add_photo_alternate),
      label: Text(_isPicking
          ? context.l10n.disputeLoadingPhotos
          : context.l10n.disputeAddPhotoCount(_evidenceFiles.length, 5)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _pickEvidence() async {
    if (_evidenceFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.maximum5ImagesAllowed)),
      );
      return;
    }
    setState(() => _isPicking = true);
    try {
      final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
      if (mounted && files.isNotEmpty) {
        setState(() {
          _evidenceFiles.addAll(files.take(5 - _evidenceFiles.length));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage(e, action: 'open photo library'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              context.l10n.disputeSubmit,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final evidenceUrls = <String>[];
      for (final file in _evidenceFiles) {
        final bytes = await file.readAsBytes();
        final url = await _service.uploadDisputeEvidence(
          bytes: bytes,
          fileName: file.name,
          contentType: 'image/jpeg',
        );
        evidenceUrls.add(url);
      }
      final disputeId = await _service.openDispute(
        orderId: widget.order.id,
        reason: '${_selectedReason.name}: ${_descriptionController.text.trim()}',
        evidenceUrls: evidenceUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(context.l10n.disputeOpenedEscrowPaused(disputeId)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(context.l10n.disputeSubmitFailed(
                userMessage(error, action: 'submit dispute'))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getReasonDisplayName(AppLocalizations l, DisputeReason reason) {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return l.disputeReasonDamaged;
      case DisputeReason.wrongItems:
        return l.disputeReasonWrongItems;
      case DisputeReason.lateDelivery:
        return l.disputeReasonLate;
      case DisputeReason.qualityIssues:
        return l.disputeReasonQuality;
      case DisputeReason.pricingDiscrepancy:
        return l.disputeReasonPricing;
      case DisputeReason.other:
        return l.disputeReasonOther;
    }
  }

  String _getReasonDescription(AppLocalizations l, DisputeReason reason) {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return l.disputeReasonDamagedDesc;
      case DisputeReason.wrongItems:
        return l.disputeReasonWrongItemsDesc;
      case DisputeReason.lateDelivery:
        return l.disputeReasonLateDesc;
      case DisputeReason.qualityIssues:
        return l.disputeReasonQualityDesc;
      case DisputeReason.pricingDiscrepancy:
        return l.disputeReasonPricingDesc;
      case DisputeReason.other:
        return l.disputeReasonOtherDesc;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.l10n.commonUnknown;
    return AppFormat.date(date);
  }
}