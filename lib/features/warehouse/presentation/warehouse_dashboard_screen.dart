import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/warehouse_service.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

void _fail(BuildContext context, Object e, String action) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(userMessage(e, action: action)),
    backgroundColor: AppColors.error,
  ));
}

/// Warehouse home: stock summary, expiry alerts and lot list.
class WarehouseDashboardScreen extends StatelessWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = WarehouseService();
    return Scaffold(
      appBar: AppBar(title: Text(l.whTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _receive(context, service),
        icon: const Icon(Icons.move_to_inbox_rounded),
        label: Text(l.whReceive),
      ),
      body: StreamBuilder<List<WarehouseLot>>(
        stream: service.myLots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lots = snap.data!;
          final inStock = lots.where((x) => x.status == 'in_stock').toList();
          final expiring = inStock.where((x) => x.expiringSoon).length;
          final cold = inStock.where((x) => x.cold).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              Row(children: [
                _stat(l.whInStock, '${inStock.length}', AppColors.primary),
                _stat(l.whCold, '$cold', const Color(0xFF0277BD)),
                _stat(l.whExpiring, '$expiring',
                    expiring > 0 ? AppColors.error : Colors.grey),
              ]),
              if (lots.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.whNoLots, textAlign: TextAlign.center),
                ),
              for (final lot in lots) _LotCard(lot: lot, service: service),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      );

  Future<void> _receive(BuildContext context, WarehouseService service) async {
    final l = context.l10n;
    final produce = TextEditingController();
    final owner = TextEditingController();
    final qty = TextEditingController();
    var unit = 'kg';
    var grade = 'ungraded';
    var cold = false;
    DateTime? expiry;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.whReceive),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: produce,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.whProduce)),
              TextField(
                  controller: owner,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.whOwner)),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: qty,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.whQuantity),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'tonnes', child: Text('tonnes')),
                    DropdownMenuItem(value: 'crates', child: Text('crates')),
                    DropdownMenuItem(value: 'bags', child: Text('bags')),
                  ],
                  onChanged: (v) => setDialog(() => unit = v ?? unit),
                ),
              ]),
              DropdownButtonFormField<String>(
                initialValue: grade,
                decoration: InputDecoration(labelText: l.whGrade),
                items: [
                  for (final g in const ['A', 'B', 'C'])
                    DropdownMenuItem(value: g, child: Text(g)),
                  DropdownMenuItem(value: 'ungraded', child: Text(l.whUngraded)),
                ],
                onChanged: (v) => setDialog(() => grade = v ?? grade),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.whCold),
                value: cold,
                onChanged: (v) => setDialog(() => cold = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.whExpiry),
                trailing:
                    Text(expiry == null ? l.whNoExpiry : AppFormat.date(expiry!)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialog(() => expiry = d);
                },
              ),
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
      await service.receiveLot(
        productName: produce.text,
        ownerName: owner.text,
        quantity: double.tryParse(qty.text.trim()) ?? 0,
        unit: unit,
        grade: grade,
        cold: cold,
        expiresAt: expiry,
        district: context.read<FarmoraState>().district,
      );
    } catch (e) {
      if (context.mounted) _fail(context, e, 'receive the lot');
    }
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot, required this.service});

  final WarehouseLot lot;
  final WarehouseService service;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final statusText = switch (lot.status) {
      'dispatched' => l.whStatusDispatched,
      'spoiled' => l.whStatusSpoiled,
      _ => lot.cold ? l.whCold : l.whAmbient,
    };
    return Card(
      child: ExpansionTile(
        leading: Icon(lot.cold ? Icons.ac_unit_rounded : Icons.inventory_2_outlined,
            color: lot.expiringSoon ? AppColors.error : AppColors.primary),
        title: Text('${lot.productName} · ${lot.lotCode}'),
        subtitle: Text([
          l.whRemaining(_num(lot.quantityRemaining), lot.unit, _num(lot.quantity)),
          '${l.whGrade} ${lot.grade == 'ungraded' ? l.whUngraded : lot.grade}',
          statusText,
          if (lot.expiresAt != null)
            '${l.whExpiry}: ${AppFormat.date(lot.expiresAt!)}',
        ].join(' · '),
            style: TextStyle(color: lot.expiringSoon ? AppColors.error : null)),
        children: [
          if (lot.status == 'in_stock')
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _take(context, spoiled: true),
                  child: Text(l.whSpoiled),
                ),
                FilledButton.tonal(
                  onPressed: () => _take(context, spoiled: false),
                  child: Text(l.whDispatch),
                ),
              ],
            ),
          StreamBuilder<List<LotMove>>(
            stream: service.moves(lot.id),
            builder: (context, snap) => Column(children: [
              for (final m in snap.data ?? const <LotMove>[])
                ListTile(
                  dense: true,
                  leading: Icon(switch (m.type) {
                    'inward' => Icons.call_received_rounded,
                    'spoilage' => Icons.delete_sweep_outlined,
                    _ => Icons.call_made_rounded,
                  }),
                  title: Text('${switch (m.type) {
                    'inward' => l.whMoveInward,
                    'spoilage' => l.whMoveSpoilage,
                    _ => l.whMoveOutward,
                  }} · ${_num(m.quantity)} ${lot.unit}'),
                  subtitle: Text([
                    if (m.createdAt != null) AppFormat.dateTime(m.createdAt!),
                    if (m.note.isNotEmpty) m.note,
                  ].join(' · ')),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _take(BuildContext context, {required bool spoiled}) async {
    final l = context.l10n;
    final qty = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(spoiled ? l.whSpoiled : l.whDispatch),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: '${l.whQuantity} (≤ ${_num(lot.quantityRemaining)} ${lot.unit})'),
          ),
          TextField(
              controller: note,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.farmNotes)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.takeOut(lot, double.tryParse(qty.text.trim()) ?? 0,
          spoiled: spoiled, note: note.text);
    } catch (e) {
      if (context.mounted) _fail(context, e, 'update the lot');
    }
  }
}

/// Buyers: in-stock lots across warehouses.
class WarehouseStockScreen extends StatelessWidget {
  const WarehouseStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.whStockForBuyers)),
      body: StreamBuilder<List<WarehouseLot>>(
        stream: WarehouseService().availableStock(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) return Center(child: Text(l.whNoStock));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final lot in snap.data!)
                Card(
                  child: ListTile(
                    leading: Icon(
                        lot.cold ? Icons.ac_unit_rounded : Icons.warehouse_outlined,
                        color: AppColors.primary),
                    title: Text(
                        '${lot.productName} · ${_num(lot.quantityRemaining)} ${lot.unit}'),
                    subtitle: Text([
                      lot.warehouseName,
                      if (lot.district.isNotEmpty) lot.district,
                      '${l.whGrade} ${lot.grade == 'ungraded' ? l.whUngraded : lot.grade}',
                      if (lot.expiresAt != null)
                        '${l.whExpiry}: ${AppFormat.date(lot.expiresAt!)}',
                    ].join(' · ')),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
