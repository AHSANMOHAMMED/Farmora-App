import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/farm_operations_service.dart';
import '../../../services/farm_weather_service.dart';
import '../../../services/community_market_service.dart';
import '../../../services/farm_records_service.dart';
import '../../../core/localization/l10n.dart';
import 'farm_records_tabs.dart';

class FarmWorkspaceScreen extends StatefulWidget {
  const FarmWorkspaceScreen({super.key});

  @override
  State<FarmWorkspaceScreen> createState() => _FarmWorkspaceScreenState();
}

class _FarmWorkspaceScreenState extends State<FarmWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  final _farm = FarmOperationsService();
  final _market = CommunityMarketService();
  final _weather = FarmWeatherService();
  final _records = FarmRecordsService();
  late final TabController _tabs = TabController(length: 8, vsync: this);
  Future<Map<String, dynamic>>? _forecast;
  bool _remindersChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final district = context.read<FarmoraState>().district;
    _forecast ??= _weather.forecastFor(district);
    if (!_remindersChecked) {
      _remindersChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final count = await _farm.checkTaskReminders();
          if (mounted && count > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$count farm task reminder(s) added to notifications.')),
            );
          }
        } catch (_) {
          // The task list still shows due and overdue work if push is offline.
        }
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Farm'),
          bottom: TabBar(controller: _tabs, isScrollable: true, tabs: [
            const Tab(icon: Icon(Icons.spa_outlined), text: 'Crops'),
            Tab(icon: const Icon(Icons.grid_view_outlined), text: context.l10n.farmTabPlots),
            const Tab(icon: Icon(Icons.checklist_rounded), text: 'Tasks'),
            Tab(icon: const Icon(Icons.account_balance_wallet_outlined), text: context.l10n.farmTabFinances),
            const Tab(icon: Icon(Icons.cloud_outlined), text: 'Weather'),
            Tab(icon: const Icon(Icons.tips_and_updates_outlined), text: context.l10n.farmTabAdvice),
            const Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Reports'),
            const Tab(icon: Icon(Icons.campaign_outlined), text: 'Buyer requests'),
          ]),
        ),
        body: TabBarView(controller: _tabs, children: [
          _crops(),
          PlotsTab(service: _records),
          _tasks(),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _farm.watchCrops(),
            builder: (context, snap) => FinancesTab(
                service: _records, crops: snap.data ?? const []),
          ),
          _weatherTab(),
          AdviceTab(service: _records),
          _reports(),
          _buyerRequests(),
        ]),
        floatingActionButton: AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) {
            final l = context.l10n;
            final (String? label, Future<void> Function()? action) =
                switch (_tabs.index) {
              0 => ('Add crop', _createCrop),
              1 => (l.farmAddPlot, () => PlotsTab.edit(context, _records)),
              2 => ('Add task', _createTask),
              3 => (
                  l.farmAddEntry,
                  () async {
                    final crops = await _farm.watchCrops().first;
                    if (context.mounted) {
                      await FinancesTab.addEntry(context, _records, crops);
                    }
                  }
                ),
              _ => (null, null),
            };
            if (label == null) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: action,
              icon: const Icon(Icons.add),
              label: Text(label),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            );
          },
        ),
      );

  Widget _crops() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _farm.watchCrops(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final crops = snapshot.data!;
          if (crops.isEmpty) return _empty(Icons.spa_outlined, 'No crop plans yet', 'Add a crop to track planting, growth and expected harvest dates.');
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              final harvest = firebaseDate(crop['expectedHarvestAt']);
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), child: const Icon(Icons.eco, color: AppColors.primary)),
                title: Text('${crop['cropName']} · ${crop['area']} ${crop['areaUnit']}'),
                subtitle: Text([
                  'Harvest target ${harvest == null ? 'not set' : MaterialLocalizations.of(context).formatMediumDate(harvest)}${crop['expectedYield'] != null && crop['expectedYield'] != 0 ? ' · ${crop['expectedYield']} ${crop['yieldUnit']}' : ''}',
                  if ((crop['plotName'] ?? '').toString().isNotEmpty) crop['plotName'].toString(),
                  if (crop['actualYield'] is num) context.l10n.farmYieldActual('${crop['actualYield']}', '${crop['yieldUnit'] ?? 'kg'}'),
                ].join(' · ')),
                onLongPress: () => _cropActions(crop),
                trailing: DropdownButton<String>(value: (crop['status'] as String?) ?? 'planned', underline: const SizedBox(), items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Planned')),
                  DropdownMenuItem(value: 'planted', child: Text('Planted')),
                  DropdownMenuItem(value: 'growing', child: Text('Growing')),
                  DropdownMenuItem(value: 'harvested', child: Text('Harvested')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ], onChanged: (status) async { if (status != null) await _run(() => _farm.updateCrop(crop['id'], {'status': status})); }),
              ));
            },
          );
        },
      );

  Widget _tasks() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _farm.watchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final tasks = snapshot.data!;
          if (tasks.isEmpty) return _empty(Icons.checklist, 'Your task list is clear', 'Create reminders for watering, spraying, fertilizing and harvest preparation.');
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final due = firebaseDate(task['dueAt']);
              final status = task['status'] as String? ?? 'pending';
              final overdue = status != 'completed' && status != 'cancelled' && due != null && due.isBefore(DateTime.now());
              return Card(child: ListTile(
                leading: Icon(status == 'completed' ? Icons.task_alt : overdue ? Icons.warning_amber_rounded : Icons.event_note, color: status == 'completed' ? AppColors.primary : overdue ? Colors.red : Colors.orange),
                title: Text(task['title']?.toString() ?? 'Farm task', style: TextStyle(decoration: status == 'completed' ? TextDecoration.lineThrough : null)),
                subtitle: Text('${overdue ? 'OVERDUE · ' : ''}${due == null ? 'No due date' : MaterialLocalizations.of(context).formatFullDate(due)}${(task['cropName'] as String?)?.isNotEmpty == true ? ' · ${task['cropName']}' : ''}'),
                trailing: PopupMenuButton<String>(onSelected: (value) => value == 'delete'
                    ? _deleteThen(() => _farm.deleteTask(task['id']))
                    : _run(() => _farm.updateTask(task['id'], {'status': value})), itemBuilder: (_) => [
                  const PopupMenuItem(value: 'pending', child: Text('Mark pending')),
                  const PopupMenuItem(value: 'inProgress', child: Text('Start task')),
                  const PopupMenuItem(value: 'completed', child: Text('Complete task')),
                  const PopupMenuItem(value: 'cancelled', child: Text('Cancel task')),
                  PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
                ]),
              ));
            },
          );
        },
      );

  Widget _weatherTab() => RefreshIndicator(
        onRefresh: () async => setState(() => _forecast = _weather.forecastFor(context.read<FarmoraState>().district)),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _forecast,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ListView(children: [_empty(Icons.cloud_off, 'Weather unavailable', 'Check your connection or farm district, then pull to refresh.')]);
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            final current = Map<String, dynamic>.from(data['current'] as Map);
            final daily = Map<String, dynamic>.from(data['daily'] as Map);
            final dates = List<String>.from(daily['time'] as List);
            final highs = List<num>.from(daily['temperature_2m_max'] as List);
            final lows = List<num>.from(daily['temperature_2m_min'] as List);
            final rain = List<num>.from(daily['precipitation_probability_max'] as List);
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(color: AppColors.primaryContainer.withValues(alpha: .3), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${data['location']['name']} · Live forecast', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8), Text('${current['temperature_2m']}°C', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
                Text('Humidity ${current['relative_humidity_2m']}% · Wind ${current['wind_speed_10m']} km/h · Rain now ${current['precipitation']} mm'),
              ]))),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Seven-day outlook', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              for (var i = 0; i < dates.length; i++) Card(child: ListTile(
                leading: Icon(rain[i] >= 70 ? Icons.umbrella : Icons.wb_sunny_outlined, color: rain[i] >= 70 ? Colors.blue : Colors.orange),
                title: Text(DateTime.parse(dates[i]).weekday == DateTime.now().weekday ? 'Today' : MaterialLocalizations.of(context).formatShortDate(DateTime.parse(dates[i]))),
                subtitle: Text(rain[i] >= 70 ? 'Heavy rain chance · plan drainage and avoid spraying' : 'Rain chance ${rain[i]}% · rainfall ${daily['precipitation_sum'][i]} mm'),
                trailing: Text('${lows[i]}° / ${highs[i]}°'),
              )),
              const Padding(padding: EdgeInsets.all(8), child: Text('Forecast from Open-Meteo. Weather advice is guidance; confirm local conditions before farm work.', style: TextStyle(color: Colors.grey))),
            ]);
          },
        ),
      );

  Widget _reports() {
    final state = context.watch<FarmoraState>();
    final orders = state.orders.where((o) => o.farmerId == state.currentUserId).toList();
    final salesMinor = orders.where((o) => o.paymentStatus == 'paid' || o.paymentStatus == 'released').fold<int>(0, (sum, o) => sum + o.subtotalMinor);
    final pending = orders.where((o) => o.status.toLowerCase() == 'pending').length;
    final activeStock = state.products.where((p) => p.farmerId == state.currentUserId).fold<int>(0, (sum, p) => sum + p.quantityAvailable);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _farm.watchCrops(),
      builder: (context, cropSnapshot) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _farm.watchTasks(),
        builder: (context, taskSnapshot) {
          final crops = cropSnapshot.data ?? const [];
          final tasks = taskSnapshot.data ?? const [];
          final overdue = tasks.where((t) => (t['status'] != 'completed' && t['status'] != 'cancelled') && (firebaseDate(t['dueAt'])?.isBefore(DateTime.now()) ?? false)).length;
          final harvested = crops.where((c) => c['status'] == 'harvested').length;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _stat('Paid produce sales', 'LKR ${(salesMinor / 100).toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, 'Paid and released order subtotal'),
            _stat('Orders awaiting action', '$pending', Icons.pending_actions, 'Open buyer orders'),
            _stat('Active stock', '$activeStock units', Icons.inventory_2_outlined, '${state.products.where((p) => p.farmerId == state.currentUserId).length} active listings'),
            _stat('Crop plans / harvested', '${crops.length} / $harvested', Icons.agriculture_outlined, 'Tracked in this farm season'),
            _stat('Tasks due late', '$overdue', Icons.alarm, overdue > 0 ? 'Open the task tab to complete or reschedule' : 'No overdue tasks'),
            const SizedBox(height: 8),
            const Text('Accounting uses completed paid orders. Delivery fees are excluded from farm sales.', style: TextStyle(color: Colors.grey)),
          ]);
        },
      ),
    );
  }

  Widget _buyerRequests() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _market.watchOpenRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return _empty(Icons.campaign_outlined, 'No open buyer requests', 'Buyer requirements appear here while farmers are being matched.');
          return ListView.builder(padding: const EdgeInsets.all(12), itemCount: snapshot.data!.length, itemBuilder: (context, i) {
            final request = snapshot.data![i];
            final date = firebaseDate(request['deliveryDate']);
            return Card(child: ListTile(
              title: Text('${request['quantity']} ${request['unit']} ${request['produceName']}'),
              subtitle: Text('${request['district']} · Needed ${date == null ? '' : MaterialLocalizations.of(context).formatMediumDate(date)} · ${request['quoteCount'] ?? 0} quotes'),
              trailing: FilledButton.tonal(onPressed: () => _quoteRequest(request), child: const Text('Quote')),
            ));
          });
        },
      );

  Future<void> _createCrop() async {
    final name = TextEditingController(), area = TextEditingController(), notes = TextEditingController();
    final plots = await _records.watchPlots().first.catchError((_) => <FarmPlot>[]);
    if (!mounted) return;
    String plotId = '';
    var areaUnit = 'acres';
    var planted = DateTime.now();
    var harvest = DateTime.now().add(const Duration(days: 90));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Plan a crop'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Crop name')),
        TextField(controller: area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Farm area')),
        DropdownButtonFormField(initialValue: areaUnit, decoration: const InputDecoration(labelText: 'Area unit'), items: const [DropdownMenuItem(value: 'acres', child: Text('Acres')), DropdownMenuItem(value: 'hectares', child: Text('Hectares')), DropdownMenuItem(value: 'perches', child: Text('Perches'))], onChanged: (v) => setDialog(() => areaUnit = v ?? 'acres')),
        if (plots.isNotEmpty) DropdownButtonFormField<String>(initialValue: plotId, decoration: InputDecoration(labelText: context.l10n.farmPlotOptional), items: [DropdownMenuItem(value: '', child: Text(context.l10n.farmNoPlot)), for (final p in plots) DropdownMenuItem(value: p.id, child: Text('${p.name} · ${p.area} ${p.areaUnit}'))], onChanged: (v) => setDialog(() {
          plotId = v ?? '';
          final plot = plots.where((p) => p.id == plotId).firstOrNull;
          if (plot != null) { area.text = '${plot.area}'; areaUnit = plot.areaUnit; }
        })),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
        TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: planted, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setDialog(() => planted = d); }, child: Text('Planted: ${MaterialLocalizations.of(ctx).formatMediumDate(planted)}')),
        TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: harvest, firstDate: planted.add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 900))); if (d != null) setDialog(() => harvest = d); }, child: Text('Expected harvest: ${MaterialLocalizations.of(ctx).formatMediumDate(harvest)}')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save crop'))],
    )));
    if (ok != true) return;
    final parsed = double.tryParse(area.text);
    if (name.text.trim().isEmpty || parsed == null || parsed <= 0 || harvest.isBefore(planted)) return _message('Enter a crop and valid area/date range.');
    final plot = plots.where((p) => p.id == plotId).firstOrNull;
    await _run(() => _farm.createCrop(cropName: name.text.trim(), area: parsed, areaUnit: areaUnit, plantedAt: planted, harvestAt: harvest, notes: notes.text.trim(), plotId: plot?.id ?? '', plotName: plot?.name ?? ''));
  }

  /// Long-press on a crop: record the harvest or delete the plan.
  Future<void> _cropActions(Map<String, dynamic> crop) async {
    final l = context.l10n;
    final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.agriculture_rounded), title: Text(l.farmRecordHarvest), onTap: () => Navigator.pop(ctx, 'harvest')),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(l.delete), onTap: () => Navigator.pop(ctx, 'delete')),
    ])));
    if (!mounted || action == null) return;
    if (action == 'delete') return _deleteThen(() => _farm.deleteCrop(crop['id']));
    final qty = TextEditingController(text: crop['actualYield'] is num ? '${crop['actualYield']}' : '');
    var unit = (crop['yieldUnit'] ?? 'kg').toString();
    if (!const ['kg', 'tonnes', 'bushels', 'crates'].contains(unit)) unit = 'kg';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: Text('${l.farmRecordHarvest} · ${crop['cropName']}'),
      content: Row(children: [
        Expanded(child: TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l.farmHarvestQty))),
        const SizedBox(width: 12),
        DropdownButton<String>(value: unit, items: const [
          DropdownMenuItem(value: 'kg', child: Text('kg')), DropdownMenuItem(value: 'tonnes', child: Text('tonnes')),
          DropdownMenuItem(value: 'bushels', child: Text('bushels')), DropdownMenuItem(value: 'crates', child: Text('crates')),
        ], onChanged: (v) => setDialog(() => unit = v ?? unit)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save))],
    )));
    final value = double.tryParse(qty.text.trim());
    if (ok != true || value == null || value < 0) return;
    await _run(() => _farm.updateCrop(crop['id'], {'status': 'harvested', 'actualYield': value, 'yieldUnit': unit}));
  }

  Future<void> _deleteThen(Future<void> Function() action) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(content: Text(l.farmDeleteConfirm), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
    ]));
    if (ok == true) await _run(action);
  }

  Future<void> _createTask() async {
    final title = TextEditingController(), description = TextEditingController();
    var priority = 'normal';
    var due = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Add farm reminder'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Task')),
        TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
        DropdownButtonFormField(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority'), items: const [DropdownMenuItem(value: 'low', child: Text('Low')), DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'high', child: Text('High'))], onChanged: (v) => setDialog(() => priority = v ?? 'normal')),
        TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: due, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730))); if (d != null) setDialog(() => due = d); }, child: Text('Due: ${MaterialLocalizations.of(ctx).formatMediumDate(due)}')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save reminder'))],
    )));
    if (ok != true) return;
    if (title.text.trim().isEmpty) return _message('Enter a task name.');
    await _run(() => _farm.createTask(title: title.text.trim(), dueAt: due, priority: priority, description: description.text.trim()));
  }

  Future<void> _quoteRequest(Map<String, dynamic> request) async {
    final state = context.read<FarmoraState>();
    final matches = state.products.where((p) => p.farmerId == state.currentUserId).where((p) => p.isActive && p.quantityAvailable >= (request['quantity'] as num).toInt() && p.unit.toLowerCase() == '${request['unit']}'.toLowerCase()).toList();
    if (matches.isEmpty) return _message('List an active product with enough stock in ${request['unit']} before quoting.');
    Product selected = matches.first;
    final price = TextEditingController(), fee = TextEditingController(text: '0');
    final result = await showDialog<(Product, int, int)?>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: Text('Quote ${request['produceName']}'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<Product>(initialValue: selected, items: matches.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} · ${p.quantityAvailable} ${p.unit}'))).toList(), onChanged: (v) => setDialog(() => selected = v ?? selected)),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price per ${request['unit']} (LKR)')),
        TextField(controller: fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Delivery fee (LKR)')),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final p = double.tryParse(price.text), f = double.tryParse(fee.text); if (p != null && p > 0 && f != null && f >= 0) Navigator.pop(ctx, (selected, (p * 100).round(), (f * 100).round())); }, child: const Text('Send quote'))],
    )));
    if (result == null) return;
    await _run(() => _market.submitQuote(requestId: request['id'], productId: result.$1.id, unitPriceMinor: result.$2, deliveryFeeMinor: result.$3));
  }

  Future<void> _run(Future<void> Function() action) async {
    try { await action(); if (mounted) _message('Saved successfully.'); }
    catch (e) { if (mounted) _message(userMessage(e, action: 'save farm data')); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Widget _error(String text) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load farm data: $text')));
  Widget _empty(IconData icon, String title, String detail) => ListView(children: [SizedBox(height: 150, child: Icon(icon, size: 44, color: Colors.grey)), Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))), Padding(padding: const EdgeInsets.all(16), child: Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)))]);
  Widget _stat(String title, String value, IconData icon, String detail) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title), subtitle: Text(detail), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))));
}
