import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/transport_job.dart';
import '../../services/cold_chain_service.dart';
import '../constants/app_colors.dart';
import '../localization/app_format.dart';
import '../localization/l10n.dart';
import '../utils/app_errors.dart';

/// Live cold-chain view for a delivery: target range, chart of cargo and
/// outside-air readings, breaches. Carriers can log a reading; the farmer
/// can set the range.
class ColdChainCard extends StatelessWidget {
  const ColdChainCard({
    super.key,
    required this.job,
    this.canLog = false,
    this.canConfigure = false,
  });

  final TransportJob job;
  final bool canLog;
  final bool canConfigure;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!job.coldChain && !canConfigure) return const SizedBox.shrink();
    final service = ColdChainService.instance;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.ac_unit_rounded, color: Color(0xFF0277BD)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.coldChain
                      ? l.ccRange('${job.tempMinC?.toStringAsFixed(0)}',
                          '${job.tempMaxC?.toStringAsFixed(0)}')
                      : l.ccNotSet,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (canConfigure)
                TextButton(
                  onPressed: () => _configure(context),
                  child: Text(l.ccSetRange),
                ),
            ]),
            if (job.coldChain) ...[
              if (job.tempBreachCount > 0)
                Text(l.ccBreaches('${job.tempBreachCount}'),
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
              StreamBuilder<List<TempReading>>(
                stream: service.readings(job.id),
                builder: (context, snap) {
                  final all = snap.data ?? const <TempReading>[];
                  if (all.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.ccNoReadings,
                          style: const TextStyle(color: Colors.grey)),
                    );
                  }
                  final cargo =
                      all.where((r) => r.source != 'ambient').toList();
                  final air = all.where((r) => r.source == 'ambient').toList();
                  final latest = cargo.isNotEmpty ? cargo.last : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Wrap(spacing: 16, children: [
                        if (latest != null)
                          Text(l.ccCargoNow(latest.celsius.toStringAsFixed(1)),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _outside(latest.celsius)
                                      ? AppColors.error
                                      : AppColors.primary)),
                        if (air.isNotEmpty)
                          Text(l.ccAirNow(air.last.celsius.toStringAsFixed(1)),
                              style: const TextStyle(color: Colors.grey)),
                        if (all.last.recordedAt != null)
                          Text(AppFormat.dateTime(all.last.recordedAt!),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                      ]),
                      SizedBox(height: 160, child: _chart(cargo, air)),
                      Text(l.ccLegend,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  );
                },
              ),
              if (canLog)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _log(context),
                    icon: const Icon(Icons.thermostat_rounded),
                    label: Text(l.ccLog),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  bool _outside(double c) =>
      job.tempMinC != null &&
      job.tempMaxC != null &&
      (c < job.tempMinC! || c > job.tempMaxC!);

  Widget _chart(List<TempReading> cargo, List<TempReading> air) {
    final t0 = [...cargo, ...air]
        .map((r) => r.recordedAt ?? DateTime.now())
        .reduce((a, b) => a.isBefore(b) ? a : b);
    double x(TempReading r) =>
        (r.recordedAt ?? DateTime.now()).difference(t0).inMinutes.toDouble();
    LineChartBarData line(List<TempReading> rs, Color c, {bool dashed = false}) =>
        LineChartBarData(
          spots: [for (final r in rs) FlSpot(x(r), r.celsius)],
          color: c,
          barWidth: 2,
          dashArray: dashed ? [4, 4] : null,
          dotData: FlDotData(show: rs.length < 20),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: LineChart(LineChartData(
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
          if (job.tempMinC != null && job.tempMaxC != null)
            HorizontalRangeAnnotation(
              y1: job.tempMinC!,
              y2: job.tempMaxC!,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
        ]),
        lineBarsData: [
          if (cargo.isNotEmpty) line(cargo, const Color(0xFF0277BD)),
          if (air.isNotEmpty) line(air, Colors.grey, dashed: true),
        ],
      )),
    );
  }

  Future<void> _log(BuildContext context) async {
    final l = context.l10n;
    final c = TextEditingController();
    var source = 'manual';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.ccLog),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
              ],
              decoration: InputDecoration(labelText: l.ccCargoTemp),
            ),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'manual', label: Text(l.ccThermometer)),
                ButtonSegment(value: 'sensor', label: Text(l.ccLogger)),
              ],
              selected: {source},
              onSelectionChanged: (v) => setDialog(() => source = v.first),
            ),
          ]),
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
    final value = double.tryParse(c.text.trim());
    if (ok != true || value == null || !context.mounted) return;
    try {
      await ColdChainService.instance.logReading(job.id, value, source: source);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'log the temperature')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _configure(BuildContext context) async {
    final l = context.l10n;
    var enabled = true;
    final min = TextEditingController(text: '${job.tempMinC ?? 2}');
    final max = TextEditingController(text: '${job.tempMaxC ?? 8}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.ccSetRange),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.ccRequired),
              value: enabled,
              onChanged: (v) => setDialog(() => enabled = v),
            ),
            if (enabled)
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: min,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(labelText: l.ccMin),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: max,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(labelText: l.ccMax),
                  ),
                ),
              ]),
          ]),
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
      await ColdChainService.instance.setRequirement(
        job.id,
        enabled: enabled,
        min: double.tryParse(min.text) ?? 2,
        max: double.tryParse(max.text) ?? 8,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'save the range')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}
