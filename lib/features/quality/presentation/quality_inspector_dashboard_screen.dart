import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/product.dart';
import '../../../services/quality_service.dart';

Color qualityGradeColor(String grade) => switch (grade) {
      'A' => const Color(0xFF2E7D32),
      'B' => const Color(0xFF558B2F),
      'C' => const Color(0xFFF9A825),
      _ => AppColors.error,
    };

/// Inspector home: open requests to grade and their past inspections.
class QualityInspectorDashboardScreen extends StatelessWidget {
  const QualityInspectorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = QualityService();
    Widget note(String t) => Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t, textAlign: TextAlign.center)));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.qcTitle),
          bottom: TabBar(tabs: [
            Tab(text: l.qcRequests),
            Tab(text: l.qcMyInspections),
          ]),
        ),
        body: TabBarView(children: [
          StreamBuilder<List<QualityRequest>>(
            stream: service.openRequests(),
            builder: (context, snap) {
              if (snap.hasError) return note(userMessage(snap.error!));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.data!.isEmpty) return note(l.qcNoRequests);
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final r in snap.data!)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.fact_check_outlined,
                            color: AppColors.primary),
                        title: Text(r.productName),
                        subtitle: Text([
                          r.farmerName,
                          if (r.district.isNotEmpty) r.district,
                          if (r.createdAt != null) AppFormat.date(r.createdAt!),
                        ].join(' · ')),
                        trailing: FilledButton.tonal(
                          onPressed: () => _inspect(context, service, r),
                          child: Text(l.qcInspect),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<List<QualityInspection>>(
            stream: service.myInspections(),
            builder: (context, snap) {
              if (snap.hasError) return note(userMessage(snap.error!));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.data!.isEmpty) return note(l.qcNoInspections);
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final i in snap.data!)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: qualityGradeColor(i.grade),
                          child: Text(i.grade == 'Reject' ? '✕' : i.grade,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(i.productName),
                        subtitle: Text([
                          if (i.createdAt != null) AppFormat.date(i.createdAt!),
                          if (i.moisturePct != null) '${i.moisturePct}%',
                          if (i.notes.isNotEmpty) i.notes,
                        ].join(' · ')),
                      ),
                    ),
                ],
              );
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _inspect(
      BuildContext context, QualityService service, QualityRequest r) async {
    final l = context.l10n;
    var grade = 'A';
    final moisture = TextEditingController();
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(r.productName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.qcGrade),
                Wrap(spacing: 8, children: [
                  for (final g in kQualityGrades)
                    ChoiceChip(
                      label: Text(g),
                      selected: grade == g,
                      selectedColor: qualityGradeColor(g).withValues(alpha: .2),
                      onSelected: (_) => setDialog(() => grade = g),
                    ),
                ]),
                TextField(
                  controller: moisture,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.qcMoisture),
                ),
                TextField(
                  controller: notes,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.qcNotes),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.qcSubmit)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.grade(
        r,
        grade: grade,
        moisturePct: double.tryParse(moisture.text.trim()),
        notes: notes.text,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'record the grade')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

/// Grade badge for product pages, plus the owner's request button.
class ProductQualityPanel extends StatelessWidget {
  const ProductQualityPanel({
    super.key,
    required this.product,
    required this.isOwner,
  });

  final Product product;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final grade = product.qualityGrade;
    final badge = grade == null
        ? null
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: qualityGradeColor(grade).withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: qualityGradeColor(grade).withValues(alpha: .4)),
            ),
            child: Row(children: [
              Icon(grade == 'Reject' ? Icons.cancel_outlined : Icons.verified,
                  color: qualityGradeColor(grade)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(grade == 'Reject' ? l.qcRejected : l.qcCertified(grade),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: qualityGradeColor(grade))),
                    if (product.qualityInspectedAt != null)
                      Text(
                          l.qcCertifiedBy(product.qualityInspectorName ?? '',
                              AppFormat.date(product.qualityInspectedAt!)),
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ]),
          );
    if (!isOwner) return badge ?? const SizedBox.shrink();
    final service = QualityService();
    return Column(children: [
      if (badge != null) badge,
      StreamBuilder<QualityRequest?>(
        stream: service.watchRequest(product.id),
        builder: (context, snap) {
          final open = snap.data?.status == 'open';
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(open
                    ? Icons.hourglass_top_rounded
                    : Icons.fact_check_outlined),
                label: Text(open ? l.qcRequested : l.qcRequest),
                onPressed: open
                    ? null
                    : () => service.requestInspection(product).catchError(
                        (Object e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(userMessage(e,
                                  action: 'request an inspection')),
                              backgroundColor: AppColors.error,
                            ));
                          }
                        },
                      ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}
