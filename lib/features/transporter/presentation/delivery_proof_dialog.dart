import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../services/firebase_service.dart';

/// What the transporter supplies to complete a delivery.
class DeliveryProof {
  const DeliveryProof({required this.code, this.photoPath});

  /// The buyer's 6-digit delivery code (checked by the rules).
  final String code;

  /// Storage path of the uploaded proof-of-delivery photo, if any.
  final String? photoPath;
}

/// Asks for the buyer's delivery code and an optional photo, uploading the
/// photo before returning. Null when the transporter backs out.
Future<DeliveryProof?> collectDeliveryProof(
  BuildContext context, {
  required String orderId,
}) {
  return showDialog<DeliveryProof>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeliveryProofDialog(orderId: orderId),
  );
}

class _DeliveryProofDialog extends StatefulWidget {
  const _DeliveryProofDialog({required this.orderId});

  final String orderId;

  @override
  State<_DeliveryProofDialog> createState() => _DeliveryProofDialogState();
}

class _DeliveryProofDialogState extends State<_DeliveryProofDialog> {
  final _code = TextEditingController();
  PickedImage? _photo;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final image =
          await ImagePickerHelper().pickOne(source: ImageSource.camera);
      if (image != null && mounted) setState(() => _photo = image);
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    }
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = l.deliveryProofCodeInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? path;
      if (_photo != null) {
        final stored = await FirestoreService().uploadDeliveryPhoto(
          orderId: widget.orderId,
          image: _photo!,
        );
        path = stored.path;
      }
      if (!mounted) return;
      Navigator.of(context).pop(DeliveryProof(code: code, photoPath: path));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = userMessage(e, action: 'upload the photo');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.deliveryProofTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deliveryProofCodeHint,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              enabled: !_busy,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, letterSpacing: 6),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: l.deliveryProofCodeLabel,
                counterText: '',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickPhoto,
              icon: Icon(_photo == null
                  ? Icons.photo_camera_outlined
                  : Icons.check_circle_outline),
              label: Text(_photo == null
                  ? l.deliveryProofAddPhoto
                  : l.deliveryProofPhotoAdded),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.memory(_photo!.bytes, height: 120, fit: BoxFit.cover),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.deliveryProofTitle),
        ),
      ],
    );
  }
}
