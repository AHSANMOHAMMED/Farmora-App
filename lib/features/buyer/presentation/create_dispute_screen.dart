import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/dispute_model.dart';
import '../../../models/order.dart';
import '../../../services/firebase_service.dart';

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Dispute',
          style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.receipt_long, 'Order #', widget.order.orderNumber),
          _buildInfoRow(Icons.attach_money, 'Total', 'Rs. ${widget.order.total.toStringAsFixed(2)}'),
          _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(widget.order.createdAt)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for Dispute',
          style: TextStyle(
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
                  title: Text(_getReasonDisplayName(reason)),
                  subtitle: Text(_getReasonDescription(reason)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please provide details about your dispute',
          style: TextStyle(
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
              return 'Please provide a description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add photos to support your dispute',
          style: TextStyle(
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
                          onTap: () {
                            setState(() {
                              _evidenceFiles.removeAt(index);
                            });
                          },
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
      label: Text(_isPicking ? 'Loading photos…' : 'Add Photo (${_evidenceFiles.length}/5)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _pickEvidence() async {
    if (_evidenceFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
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
          SnackBar(content: Text('Could not open photo library: $e')),
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
          : const Text(
              'Submit Dispute',
              style: TextStyle(
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
            content: Text('Dispute $disputeId opened. Escrow is paused while it is reviewed.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to submit dispute: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getReasonDisplayName(DisputeReason reason) {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return 'Damaged Goods';
      case DisputeReason.wrongItems:
        return 'Wrong Items Delivered';
      case DisputeReason.lateDelivery:
        return 'Late Delivery';
      case DisputeReason.qualityIssues:
        return 'Quality Issues';
      case DisputeReason.pricingDiscrepancy:
        return 'Pricing Discrepancy';
      case DisputeReason.other:
        return 'Other';
    }
  }

  String _getReasonDescription(DisputeReason reason) {
    switch (reason) {
      case DisputeReason.damagedGoods:
        return 'Items arrived damaged or broken';
      case DisputeReason.wrongItems:
        return 'Received different items than ordered';
      case DisputeReason.lateDelivery:
        return 'Delivery was significantly delayed';
      case DisputeReason.qualityIssues:
        return 'Product quality did not meet expectations';
      case DisputeReason.pricingDiscrepancy:
        return 'Charged differently than agreed price';
      case DisputeReason.other:
        return 'Other issue not listed above';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}