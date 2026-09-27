import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/farm_records_service.dart';

String ledgerCategoryLabel(AppLocalizations l, String c) => switch (c) {
      'seed' => l.catSeed,
      'fertilizer' => l.catFertilizer,
      'pesticide' => l.catPesticide,
      'labour' => l.catLabour,
      'water' => l.catWater,
      'fuel' => l.catFuel,
      'machinery' => l.catMachinery,
      'transport' => l.catTransport,
      'land' => l.catLand,
      'produce_sale' => l.catProduceSale,
      'subsidy' => l.catSubsidy,
      _ => l.catOther,
    };

void _snack(BuildContext context, String text, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.error : null,
    ));

Future<bool> _confirmDelete(BuildContext context) async {
  final l = context.l10n;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l.farmDeleteConfirm),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.delete)),
          ],
        ),
      ) ==
      true;
}

Widget _emptyState(IconData icon, String text) => ListView(children: [
      const SizedBox(height: 100),
      Icon(icon, size: 44, color: Colors.grey),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
      ),
    ]);

// ── Plots ─────────────────────────────────────────────────────

class PlotsTab extends StatelessWidget {
  const PlotsTab({super.key, required this.service});

  final FarmRecordsService service;

  static Future<void> edit(BuildContext context, FarmRecordsService service,
      [FarmPlot? plot]) async {
    final l = context.l10n;
    final name = TextEditingController(text: plot?.name);
    final area = TextEditingController(
        text: plot == null ? '' : plot.area.toString());
    final soil = TextEditingController(text: plot?.soilType);
    final water = TextEditingController(text: plot?.irrigation);
    final notes = TextEditingController(text: plot?.notes);
    var unit = plot?.areaUnit ?? 'acres';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(plot == null ? l.farmAddPlot : l.farmEditPlot),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l.farmPlotName)),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: area,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.farmArea),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(value: 'acres', child: Text('acres')),
                    DropdownMenuItem(value: 'hectares', child: Text('hectares')),
                    DropdownMenuItem(value: 'perches', child: Text('perches')),
                  ],
                  onChanged: (v) => setDialog(() => unit = v ?? unit),
                ),
              ]),
              TextField(
                  controller: soil,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l.farmSoilType)),
              TextField(
                  controller: water,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l.farmIrrigation)),
              TextField(
                  controller: notes,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.farmNotes)),
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
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.savePlot(
        id: plot?.id,
        name: name.text,
        area: double.tryParse(area.text.trim()) ?? 0,
        areaUnit: unit,
        soilType: soil.text,
        irrigation: water.text,
        notes: notes.text,
      );
    } catch (e) {
      if (context.mounted) {
        _snack(context, userMessage(e, action: 'save the plot'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<FarmPlot>>(
      stream: service.watchPlots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(userMessage(snap.error!)));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final plots = snap.data!;
        if (plots.isEmpty) {
          return _emptyState(Icons.grid_view_outlined, l.farmNoPlots);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final p in plots)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.grid_view_rounded)),
                  title: Text(p.name),
                  subtitle: Text([
                    '${p.area} ${p.areaUnit}',
                    if (p.soilType.isNotEmpty) p.soilType,
                    if (p.irrigation.isNotEmpty) p.irrigation,
                  ].join(' · ')),
                  onTap: () => edit(context, service, p),
                  trailing: IconButton(
                    tooltip: l.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await _confirmDelete(context)) {
                        await service.deletePlot(p.id);
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Finances ──────────────────────────────────────────────────

class FinancesTab extends StatelessWidget {
  const FinancesTab({super.key, required this.service, required this.crops});

  final FarmRecordsService service;

  /// Crop plans ({id, cropName}) for linking entries to a crop.
  final List<Map<String, dynamic>> crops;

  static Future<void> addEntry(BuildContext context, FarmRecordsService service,
      List<Map<String, dynamic>> crops) async {
    final l = context.l10n;
    final amount = TextEditingController();
    final note = TextEditingController();
    var expense = true;
    var category = kExpenseCategories.first;
    var date = DateTime.now();
    String cropId = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.farmAddEntry),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l.farmExpense)),
                  ButtonSegment(value: false, label: Text(l.farmIncome)),
                ],
                selected: {expense},
                onSelectionChanged: (v) => setDialog(() {
                  expense = v.first;
                  category = expense
                      ? kExpenseCategories.first
                      : kIncomeCategories.first;
                }),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l.farmAmount),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: l.farmCategory),
                items: [
                  for (final c
                      in expense ? kExpenseCategories : kIncomeCategories)
                    DropdownMenuItem(
                        value: c, child: Text(ledgerCategoryLabel(l, c))),
                ],
                onChanged: (v) => setDialog(() => category = v ?? category),
              ),
              DropdownButtonFormField<String>(
                initialValue: cropId,
                decoration: InputDecoration(labelText: l.farmCropOptional),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.farmGeneral)),
                  for (final c in crops)
                    DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['cropName'].toString())),
                ],
                onChanged: (v) => setDialog(() => cropId = v ?? ''),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (d != null) setDialog(() => date = d);
                },
                child: Text('${l.farmDate}: ${AppFormat.date(date)}'),
              ),
              TextField(
                  controller: note,
                  maxLength: 300,
                  decoration: InputDecoration(labelText: l.farmNotes)),
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
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final crop = crops.where((c) => c['id'] == cropId).firstOrNull;
    try {
      await service.addEntry(
        isExpense: expense,
        category: category,
        amountMinor: (int.tryParse(amount.text) ?? 0) * 100,
        date: date,
        cropId: cropId,
        cropName: crop?['cropName']?.toString() ?? '',
        note: note.text,
      );
    } catch (e) {
      if (context.mounted) {
        _snack(context, userMessage(e, action: 'save the entry'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    // Paid Farmora orders count as income without manual entry.
    final appSalesMinor = state.orders
        .where((o) =>
            o.farmerId == state.currentUserId &&
            (o.paymentStatus == 'paid' || o.paymentStatus == 'released'))
        .fold<int>(0, (sum, o) => sum + o.subtotalMinor);
    return StreamBuilder<List<LedgerEntry>>(
      stream: service.watchLedger(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(userMessage(snap.error!)));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snap.data!;
        final income = appSalesMinor +
            entries
                .where((e) => !e.isExpense)
                .fold<int>(0, (s, e) => s + e.amountMinor);
        final expense = entries
            .where((e) => e.isExpense)
            .fold<int>(0, (s, e) => s + e.amountMinor);
        final byCrop = <String, int>{};
        for (final e in entries.where((e) => e.cropName.isNotEmpty)) {
          byCrop[e.cropName] = (byCrop[e.cropName] ?? 0) +
              (e.isExpense ? -e.amountMinor : e.amountMinor);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(children: [
              _total(l.farmIncome, income, AppColors.primary),
              _total(l.farmExpense, expense, AppColors.error),
              _total(l.farmProfit, income - expense,
                  income >= expense ? AppColors.primary : AppColors.error),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  '${l.farmAppSales}: ${AppFormat.lkr(appSalesMinor / 100)} · ${l.farmSalesNote}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            if (byCrop.isNotEmpty) ...[
              Text(l.farmByCrop,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              for (final e in byCrop.entries)
                ListTile(
                  dense: true,
                  title: Text(e.key),
                  trailing: Text(AppFormat.lkr(e.value / 100),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: e.value >= 0
                              ? AppColors.primary
                              : AppColors.error)),
                ),
              const Divider(),
            ],
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.farmNoEntries,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ),
            for (final e in entries)
              Card(
                child: ListTile(
                  leading: Icon(
                      e.isExpense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: e.isExpense ? AppColors.error : AppColors.primary),
                  title: Text(ledgerCategoryLabel(l, e.category)),
                  subtitle: Text([
                    AppFormat.date(e.date),
                    if (e.cropName.isNotEmpty) e.cropName,
                    if (e.note.isNotEmpty) e.note,
                  ].join(' · ')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        '${e.isExpense ? '-' : '+'}${AppFormat.lkr(e.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        if (await _confirmDelete(context)) {
                          await service.deleteEntry(e.id);
                        }
                      },
                    ),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _total(String label, int minor, Color color) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(AppFormat.lkr(minor / 100),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: color)),
              ),
            ]),
          ),
        ),
      );
}

// ── Advice ────────────────────────────────────────────────────

class AdviceTab extends StatelessWidget {
  const AdviceTab({super.key, required this.service});

  final FarmRecordsService service;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<Advisory>>(
      stream: service.watchAdvisories('farmer'),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(userMessage(snap.error!)));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return _emptyState(Icons.campaign_outlined, l.farmNoAdvice);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final a in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.campaign_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(a.body),
                      if (a.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(AppFormat.date(a.createdAt!),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
