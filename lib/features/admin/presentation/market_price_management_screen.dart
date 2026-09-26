import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/market_price_index.dart';
import '../../../providers/farmora_state.dart';
import '../../../models/user_role.dart';

class MarketPriceManagementScreen extends StatefulWidget {
  const MarketPriceManagementScreen({super.key});

  @override
  State<MarketPriceManagementScreen> createState() =>
      _MarketPriceManagementScreenState();
}

class _MarketPriceManagementScreenState
    extends State<MarketPriceManagementScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Spices',
    'Grains'
  ];

  /// Display name for a category value (stored values stay English).
  String _categoryLabel(AppLocalizations l, String category) =>
      switch (category.toLowerCase()) {
        'all' => l.commonAll,
        'vegetables' => l.vegetables,
        'fruits' => l.fruits,
        'spices' => l.spices,
        'grains' => l.grains,
        _ => category,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<FarmoraState>();
    final allPrices = state.marketPrices;
    final filtered = _selectedCategory == 'All'
        ? allPrices
        : allPrices
            .where((p) =>
                p.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          l.adminMarketTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: state.role == Role.admin ? [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: l.adminMarketAddTooltip,
            onPressed: () => _showAddPriceDialog(context, state),
          ),
        ] : [],
      ),
      body: Column(
        children: [
          // Pola Benchmark Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: Icon(Icons.analytics_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.adminMarketBenchmarkTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.adminMarketBenchmarkBody,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(_categoryLabel(l, cat)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Price list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l.adminMarketEmpty,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildPriceCard(context, item, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
      BuildContext context, MarketPriceIndex item, FarmoraState state) {
    final l = context.l10n;
    IconData trendIcon;
    Color trendColor;
    String trendLabel;

    switch (item.trend.toLowerCase()) {
      case 'up':
        trendIcon = Icons.trending_up_rounded;
        trendColor = Colors.red.shade700;
        trendLabel = l.adminMarketTrendRising;
        break;
      case 'down':
        trendIcon = Icons.trending_down_rounded;
        trendColor = Colors.green.shade700;
        trendLabel = l.adminMarketTrendSoftening;
        break;
      default:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = Colors.blueGrey;
        trendLabel = l.adminMarketTrendStable;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.cropName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.marketName.isEmpty ? item.district : item.marketName} · ${item.district} · ${_categoryLabel(l, item.category)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 14, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        trendLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildPriceMetric(
                      l.adminMarketWholesaleRange,
                      '${AppFormat.lkr(item.minPricePerKg, decimals: 2)} - ${AppFormat.number(item.maxPricePerKg, decimals: 2)} / ${item.unit}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPriceMetric(l.adminMarketAvgBenchmark,
                      '${AppFormat.lkr(item.averagePricePerKg, decimals: 2)} / ${item.unit}',
                      isPrimary: true),
                ),
                if (state.role == Role.admin) Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.primary),
                      tooltip: l.adminMarketUpdateTooltip,
                      onPressed: () =>
                          _showEditPriceDialog(context, item, state),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      tooltip: l.adminMarketDeleteTooltip,
                      onPressed: () =>
                          _confirmDeletePrice(context, item, state),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _saving = false;

  /// Awaits a market-price write; success is shown only after it returns.
  Future<void> _runPriceAction(
      Future<void> Function() action, String success) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'save the market price'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Validates a min/max price pair; returns an error text or null.
  String? _priceError(double? minVal, double? maxVal) {
    if (minVal == null || maxVal == null || minVal <= 0 || maxVal <= 0) {
      return 'Enter valid minimum and maximum prices.';
    }
    if (minVal > maxVal) {
      return 'The minimum price cannot exceed the maximum price.';
    }
    return null;
  }

  void _confirmDeletePrice(
      BuildContext context, MarketPriceIndex item, FarmoraState state) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.adminMarketDeleteTitle(item.cropName)),
        content: Text(l.adminMarketDeleteBody(item.district)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _runPriceAction(() => state.removeMarketPrice(item.id),
                  l.adminMarketDeleted(item.cropName));
            },
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceMetric(String label, String value,
      {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showEditPriceDialog(
      BuildContext context, MarketPriceIndex item, FarmoraState state) {
    final minCtrl =
        TextEditingController(text: item.minPricePerKg.toStringAsFixed(0));
    final maxCtrl =
        TextEditingController(text: item.maxPricePerKg.toStringAsFixed(0));
    String trend = item.trend;
    final l = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.adminMarketEditTitle(item.cropName)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.adminMarketMinPriceKg,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.adminMarketMaxPriceKg,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: trend,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.adminMarketTrendLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'up', child: Text(l.adminMarketTrendRisingOption)),
                  DropdownMenuItem(
                      value: 'stable',
                      child: Text(l.adminMarketTrendStableOption)),
                  DropdownMenuItem(
                      value: 'down',
                      child: Text(l.adminMarketTrendSofteningOption)),
                ],
                onChanged: (v) => setDialogState(() => trend = v ?? 'stable'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final minVal = double.tryParse(minCtrl.text.trim());
                final maxVal = double.tryParse(maxCtrl.text.trim());
                final error = _priceError(minVal, maxVal);
                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                Navigator.pop(ctx);
                _runPriceAction(
                  () => state.updateMarketPrice(
                    item.id,
                    minPrice: minVal!,
                    maxPrice: maxVal!,
                    trend: trend,
                  ),
                  l.adminMarketUpdated(item.cropName),
                );
              },
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPriceDialog(BuildContext context, FarmoraState state) {
    final nameCtrl = TextEditingController();
    final districtCtrl = TextEditingController(text: 'Dambulla');
    final minCtrl = TextEditingController(text: '150');
    final maxCtrl = TextEditingController(text: '200');
    String category = 'Vegetables';
    String trend = 'stable';
    final l = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.adminMarketAddTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l.adminMarketCropName,
                    hintText: l.adminMarketCropHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtCtrl,
                  decoration: InputDecoration(
                    labelText: l.adminMarketDistrict,
                    hintText: l.adminMarketDistrictHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.category,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final value in const [
                      'Vegetables',
                      'Fruits',
                      'Spices',
                      'Grains'
                    ])
                      DropdownMenuItem(
                          value: value, child: Text(_categoryLabel(l, value))),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? 'Vegetables'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l.adminMarketMinPrice,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l.adminMarketMaxPrice,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final cropName = nameCtrl.text.trim();
                if (cropName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a crop name.')));
                  return;
                }
                final minVal = double.tryParse(minCtrl.text.trim());
                final maxVal = double.tryParse(maxCtrl.text.trim());
                final error = _priceError(minVal, maxVal);
                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                final newId = 'mpi-${DateTime.now().millisecondsSinceEpoch}';
                Navigator.pop(ctx);
                _runPriceAction(() => state.addMarketPrice(
                  MarketPriceIndex(
                    id: newId,
                    cropName: cropName,
                    category: category,
                    district: districtCtrl.text.trim(),
                    minPricePerKg: minVal!,
                    maxPricePerKg: maxVal!,
                    averagePricePerKg: (minVal + maxVal) / 2,
                    trend: trend,
                    updatedAt: DateTime.now(),
                  ),
                ), l.adminMarketAdded(cropName));
              },
              child: Text(l.adminMarketAddRate),
            ),
          ],
        ),
      ),
    );
  }
}
