import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../models/transport_job.dart';
import '../constants/app_colors.dart';
import '../localization/l10n.dart';

/// Proof of delivery for a delivered job: whether the buyer's code was
/// entered, and the transporter's delivery photo (readable by the order's
/// parties and admins per storage rules). Empty for undelivered jobs.
class DeliveryProofView extends StatefulWidget {
  const DeliveryProofView({super.key, required this.job});

  final TransportJob job;

  @override
  State<DeliveryProofView> createState() => _DeliveryProofViewState();
}

class _DeliveryProofViewState extends State<DeliveryProofView> {
  Future<String>? _photoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DeliveryProofView old) {
    super.didUpdateWidget(old);
    if (old.job.podPhotoPath != widget.job.podPhotoPath) _load();
  }

  void _load() {
    final path = widget.job.podPhotoPath;
    _photoUrl = (path == null || path.isEmpty)
        ? null
        : FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    if (job.status != 'delivered' ||
        (!job.deliveredWithCode && _photoUrl == null)) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.deliveredWithCode)
            Row(children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(l.deliveryProofConfirmed)),
            ]),
          if (_photoUrl != null) ...[
            const SizedBox(height: 10),
            Text(l.deliveryProofPhoto,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            FutureBuilder<String>(
              future: _photoUrl,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: snap.hasError
                          ? const Icon(Icons.broken_image_outlined)
                          : const CircularProgressIndicator(),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(child: Image.network(snap.data!)),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(snap.data!,
                        height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
