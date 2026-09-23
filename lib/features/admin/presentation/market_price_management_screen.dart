import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/market_price_index.dart';
import '../../../providers/farmora_state.dart';

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

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Market Price Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Add Commodity Rate',
            onPressed: () => _showAddPriceDialog(context, state),
          ),
        ],
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
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: Icon(Icons.analytics_rounded,
                      color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sri Lankan Pola Wholesale Benchmark',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Benchmark rates reference Dambulla, Pettah, and regional economic centers to guide buyer offers and farmer listings.',
                        style: TextStyle(
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
                    label: Text(cat),
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
                ? const Center(
                    child: Text(
                      'No commodity rates found.',
                      style: TextStyle(color: AppColors.textSecondary),
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
    IconData trendIcon;
    Color trendColor;
    String trendLabel;

    switch (item.trend.toLowerCase()) {
      case 'up':
        trendIcon = Icons.trending_up_rounded;
        trendColor = Colors.red.shade700;
        trendLabel = 'Price Rising';
        break;
      case 'down':
        trendIcon = Icons.trending_down_rounded;
        trendColor = Colors.green.shade700;
        trendLabel = 'Price Softening';
        break;
      default:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = Colors.blueGrey;
        trendLabel = 'Stable';
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
                        '${item.district} Economic Center · ${item.category}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
                _buildPriceMetric('Wholesale Range',
                    'LKR ${item.minPricePerKg.toStringAsFixed(0)} - ${item.maxPricePerKg.toStringAsFixed(0)} / kg'),
                _buildPriceMetric('Avg Benchmark',
                    'LKR ${item.averagePricePerKg.toStringAsFixed(0)} / kg',
                    isPrimary: true),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.primary),
                      tooltip: 'Update Rates',
                      onPressed: () =>
                          _showEditPriceDialog(context, item, state),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      tooltip: 'Delete Benchmark',
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

  void _confirmDeletePrice(
      BuildContext context, MarketPriceIndex item, FarmoraState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${item.cropName}?'),
        content: Text(
          'This removes the ${item.district} benchmark from the marketplace. '
          'Farmers and buyers will no longer see this reference rate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              state.removeMarketPrice(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${item.cropName} benchmark')),
              );
            },
            child: const Text('Delete'),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit ${item.cropName} Benchmark'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Price (LKR/kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Price (LKR/kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: trend,
                decoration: const InputDecoration(
                  labelText: 'Market Trend',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'up', child: Text('Rising (↑)')),
                  DropdownMenuItem(value: 'stable', child: Text('Stable (→)')),
                  DropdownMenuItem(value: 'down', child: Text('Softening (↓)')),
                ],
                onChanged: (v) => setDialogState(() => trend = v ?? 'stable'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final minVal =
                    double.tryParse(minCtrl.text) ?? item.minPricePerKg;
                final maxVal =
                    double.tryParse(maxCtrl.text) ?? item.maxPricePerKg;
                state.updateMarketPrice(
                  item.id,
                  minPrice: minVal,
                  maxPrice: maxVal,
                  trend: trend,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${item.cropName} rate')),
                );
              },
              child: const Text('Save'),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Commodity Pola Rate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Crop / Commodity Name',
                    hintText: 'e.g. Red Dambulla Onions',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Economic Center / District',
                    hintText: 'e.g. Dambulla, Pettah, Jaffna',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Vegetables', child: Text('Vegetables')),
                    DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                    DropdownMenuItem(value: 'Spices', child: Text('Spices')),
                    DropdownMenuItem(value: 'Grains', child: Text('Grains')),
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
                        decoration: const InputDecoration(
                          labelText: 'Min Price',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Price',
                          border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final minVal = double.tryParse(minCtrl.text) ?? 100.0;
                final maxVal = double.tryParse(maxCtrl.text) ?? 150.0;
                final newId = 'mpi-${DateTime.now().millisecondsSinceEpoch}';
                state.addMarketPrice(
                  MarketPriceIndex(
                    id: newId,
                    cropName: nameCtrl.text.trim(),
                    category: category,
                    district: districtCtrl.text.trim(),
                    minPricePerKg: minVal,
                    maxPricePerKg: maxVal,
                    averagePricePerKg: (minVal + maxVal) / 2,
                    trend: trend,
                    updatedAt: DateTime.now(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${nameCtrl.text.trim()} rate')),
                );
              },
              child: const Text('Add Rate'),
            ),
          ],
        ),
      ),
    );
  }
}
