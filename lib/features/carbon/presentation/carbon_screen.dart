import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/carbon.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../models/transport_job.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';

String carbonPracticeLabel(AppLocalizations l, String p) => switch (p) {
      'composting' => l.co2Composting,
      'mulching' => l.co2Mulching,
      'no_till' => l.co2NoTill,
      'cover_crop' => l.co2CoverCrop,
      'agroforestry_trees' => l.co2Trees,
      'solar_pump' => l.co2Solar,
      'biogas' => l.co2Biogas,
      'reduced_fertilizer' => l.co2LessFertilizer,
      _ => p,
    };

/// Carbon dashboard: delivery footprint for the user's role and, for
/// farmers, climate-smart practices with estimated credits. Estimates only.
class CarbonScreen extends StatelessWidget {
  const CarbonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final uid = state.currentUserId;
    final field = switch (state.role) {
      Role.buyer => 'buyerId',
      Role.farmer => 'farmerId',
      Role.driver => 'driverId',
      _ => 'transporterId',
    };
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.co2Title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.co2Deliveries,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('transport_jobs')
                .where(field, isEqualTo: uid)
                .where('status', isEqualTo: 'delivered')
                .limit(200)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text(userMessage(snap.error!));
              final jobs = (snap.data?.docs ?? const [])
                  .map((d) => TransportJob.fromMap(d.id, d.data()))
                  .where((j) => j.co2Kg != null)
                  .toList();
              final kg = jobs.fold<double>(0, (s, j) => s + j.co2Kg!);
              final km = jobs.fold<double>(0, (s, j) => s + (j.distanceKm ?? 0));
              return Column(children: [
                Row(children: [
                  _stat(l.co2Total, '${kg.toStringAsFixed(1)} kg'),
                  _stat(l.co2Distance, '${km.toStringAsFixed(0)} km'),
                  _stat(l.co2PerDelivery,
                      jobs.isEmpty ? '–' : '${(kg / jobs.length).toStringAsFixed(1)} kg'),
                ]),
                if (jobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.co2NoDeliveries,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                for (final j in jobs.take(10))
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text(j.productName ?? j.title),
                    subtitle: Text('${j.distanceKm?.toStringAsFixed(0) ?? '?'} km'),
                    trailing: Text('${j.co2Kg!.toStringAsFixed(1)} kg CO₂e'),
                  ),
                Text(l.co2Tip, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]);
            },
          ),
          if (state.role == Role.farmer) ...[
            const Divider(height: 32),
            _FarmPractices(uid: uid),
          ],
          const SizedBox(height: 16),
          Text(l.co2Disclaimer,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              FittedBox(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      );
}

class _FarmPractices extends StatelessWidget {
  const _FarmPractices({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('carbon_practices');

  Future<void> _add(BuildContext context) async {
    final l = context.l10n;
    var practice = 'agroforestry_trees';
    final qty = TextEditingController();
    final notes = TextEditingController();
    var started = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final unit = Carbon.practices[practice]!.$1;
          final q = double.tryParse(qty.text) ?? 0;
          return AlertDialog(
            title: Text(l.co2AddPractice),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: practice,
                  isExpanded: true,
                  items: [
                    for (final p in Carbon.practices.keys)
                      DropdownMenuItem(
                          value: p, child: Text(carbonPracticeLabel(l, p))),
                  ],
                  onChanged: (v) => setDialog(() => practice = v ?? practice),
                ),
                TextField(
                  controller: qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: '${l.whQuantity} ($unit)'),
                  onChanged: (_) => setDialog(() {}),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.inpStartDate),
                  trailing: Text(AppFormat.date(started)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: started,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialog(() => started = d);
                  },
                ),
                TextField(
                  controller: notes,
                  maxLength: 300,
                  decoration: InputDecoration(labelText: l.farmNotes),
                ),
                Text(l.co2Estimate(
                    Carbon.practiceTonnes(practice, q).toStringAsFixed(2))),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.save)),
            ],
          );
        },
      ),
    );
    final q = double.tryParse(qty.text.trim()) ?? 0;
    if (ok != true || q <= 0 || !context.mounted) return;
    try {
      await _col.add({
        'farmerId': uid,
        'practice': practice,
        'quantity': q,
        'unit': Carbon.practices[practice]!.$1,
        'tonnesPerYear':
            double.parse(Carbon.practiceTonnes(practice, q).toStringAsFixed(3)),
        'startedAt': Timestamp.fromDate(started),
        'notes': notes.text.trim(),
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'updatedBy': uid,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'save the practice')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(l.co2Practices,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          TextButton.icon(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add),
            label: Text(l.co2AddPractice),
          ),
        ]),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _col
              .where('farmerId', isEqualTo: uid)
              .where('isDeleted', isEqualTo: false)
              .orderBy('startedAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text(userMessage(snap.error!));
            final docs = snap.data?.docs ?? const [];
            final tonnes = docs.fold<double>(
                0, (s, d) => s + (firebaseDouble(d.data()['tonnesPerYear']) ?? 0));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const Icon(Icons.eco, color: AppColors.primary),
                    title: Text(l.co2Credits(tonnes.toStringAsFixed(2))),
                    subtitle: Text(l.co2CreditsHint),
                  ),
                ),
                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.co2NoPractices,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                for (final d in docs)
                  ListTile(
                    leading: const Icon(Icons.forest_outlined),
                    title: Text(carbonPracticeLabel(l, '${d.data()['practice']}')),
                    subtitle: Text(
                        '${d.data()['quantity']} ${d.data()['unit']} · ${l.co2PerYear('${d.data()['tonnesPerYear']}')}'),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => d.reference.update({
                        'isDeleted': true,
                        'updatedAt': FieldValue.serverTimestamp(),
                        'updatedBy': uid,
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
