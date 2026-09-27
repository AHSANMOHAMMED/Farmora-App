import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/community_service.dart';
import '../../../services/crop_doctor_service.dart';
import '../../../services/firebase_service.dart';

/// AI crop doctor: photo → likely pest / disease with treatments, history,
/// and a one-tap hand-off to a human expert.
class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({super.key});

  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends State<CropDoctorScreen> {
  final _service = CropDoctorService();
  final _crop = TextEditingController();
  final _notes = TextEditingController();
  PickedImage? _photo;
  CropDiagnosis? _result;
  bool _busy = false;

  @override
  void dispose() {
    _crop.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final img = await ImagePickerHelper().pickOne(source: source);
      if (img != null) {
        setState(() {
          _photo = img;
          _result = null;
        });
      }
    } catch (e) {
      if (mounted) _snack(userMessage(e));
    }
  }

  void _snack(String m, {bool error = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), backgroundColor: error ? AppColors.error : null));

  Future<void> _diagnose() async {
    if (_photo == null) return;
    setState(() => _busy = true);
    try {
      final url = (await FirestoreService().uploadProductImage(_photo!)).url;
      final lang = context.read<FarmoraState>().locale.languageCode;
      final result = await _service.diagnose(
        bytes: _photo!.bytes,
        mimeType: _photo!.contentType,
        crop: _crop.text,
        notes: _notes.text,
        languageCode: lang,
        imageUrl: url,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) _snack(userMessage(e, action: 'check the photo'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askExpert(CropDiagnosis d) async {
    final l = context.l10n;
    try {
      await CommunityService().ask(
        topic: 'pest',
        question: [
          if (d.crop.isNotEmpty) '${d.crop}:',
          '${l.cdAiSaid} ${d.issue} (${d.confidence}).',
          d.summary,
          if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
        ].join(' '),
        imageUrl: d.imageUrl,
      );
      if (mounted) _snack(l.cdSentToExpert, error: false);
    } catch (e) {
      if (mounted) _snack(userMessage(e, action: 'ask an expert'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.cdTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.cdIntro,
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _photo == null
                ? const Center(
                    child: Icon(Icons.local_florist_outlined,
                        size: 56, color: Colors.grey))
                : Image.memory(_photo!.bytes, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l.cdTakePhoto),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l.cdFromGallery),
              ),
            ),
          ]),
          TextField(
            controller: _crop,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.cdCrop),
          ),
          TextField(
            controller: _notes,
            maxLength: 300,
            decoration: InputDecoration(labelText: l.cdNotes),
          ),
          FilledButton.icon(
            onPressed: _busy || _photo == null ? null : _diagnose,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.biotech_outlined),
            label: Text(l.cdDiagnose),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            DiagnosisCard(diagnosis: _result!, onAskExpert: _askExpert),
          ],
          const SizedBox(height: 24),
          Text(l.cdHistory,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          StreamBuilder<List<CropDiagnosis>>(
            stream: _service.history(),
            builder: (context, snap) {
              final items = snap.data ?? const <CropDiagnosis>[];
              if (snap.hasData && items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.cdNoHistory,
                      style: const TextStyle(color: Colors.grey)),
                );
              }
              return Column(children: [
                for (final d in items)
                  Card(
                    child: ListTile(
                      leading: d.imageUrl == null
                          ? const Icon(Icons.eco_outlined)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SafeImage(
                                  path: d.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover),
                            ),
                      title: Text(d.healthy ? l.cdHealthy : d.issue),
                      subtitle: Text([
                        if (d.crop.isNotEmpty) d.crop,
                        if (d.createdAt != null) AppFormat.date(d.createdAt!),
                      ].join(' · ')),
                      onTap: () => setState(() => _result = d),
                      trailing: IconButton(
                        tooltip: l.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _service.delete(d.id),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({
    super.key,
    required this.diagnosis,
    required this.onAskExpert,
  });

  final CropDiagnosis diagnosis;
  final void Function(CropDiagnosis) onAskExpert;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = diagnosis;
    final color = d.healthy
        ? AppColors.primary
        : d.confidence == 'high'
            ? AppColors.error
            : const Color(0xFFE65100);
    Widget section(String title, List<String> items, IconData icon) =>
        items.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    for (final i in items)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text('• $i'),
                      ),
                  ],
                ),
              );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: .4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(d.healthy ? Icons.check_circle : Icons.bug_report,
                  color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.healthy ? l.cdHealthy : d.issue,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: color)),
              ),
              Chip(label: Text(l.cdConfidence(d.confidence))),
            ]),
            if (d.summary.isNotEmpty) Text(d.summary),
            section(l.cdSymptoms, d.symptoms, Icons.visibility_outlined),
            section(l.cdOrganic, d.organicTreatment, Icons.spa_outlined),
            section(l.cdChemical, d.chemicalTreatment, Icons.science_outlined),
            section(l.cdPrevention, d.prevention, Icons.shield_outlined),
            const SizedBox(height: 10),
            Text(l.cdDisclaimer,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (!d.healthy)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onAskExpert(d),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(d.seeExpert ? l.cdExpertRecommended : l.conAskExpert),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
