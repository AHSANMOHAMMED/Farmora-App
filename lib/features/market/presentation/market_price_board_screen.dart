import 'package:flutter/material.dart';
import '../../../models/market_price_index.dart';
import '../../../services/community_market_service.dart';
import '../../../services/firebase_service.dart';

class MarketPriceBoardScreen extends StatefulWidget {
  const MarketPriceBoardScreen({super.key});
  @override
  State<MarketPriceBoardScreen> createState() => _MarketPriceBoardScreenState();
}

class _MarketPriceBoardScreenState extends State<MarketPriceBoardScreen> {
  final _market = CommunityMarketService();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Market price board')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _report, icon: const Icon(Icons.add_chart), label: const Text('Report a price')),
    body: StreamBuilder<List<MarketPriceIndex>>(
      stream: FirestoreService().marketPricesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Market prices could not load: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No verified market price benchmarks yet. Report prices from your local market for admin review.', textAlign: TextAlign.center)));
        return ListView(padding: const EdgeInsets.all(12), children: [
          for (final MarketPriceIndex item in snapshot.data!) Card(child: ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: Text(item.cropName),
            subtitle: Text('${item.marketName.isEmpty ? item.district : item.marketName} · ${item.district} · ${item.category} · ${item.reportCount} report(s)'),
            trailing: Text('LKR ${item.minPricePerKg.toStringAsFixed(2)}–${item.maxPricePerKg.toStringAsFixed(2)} / ${item.unit}', textAlign: TextAlign.end),
          )),
        ]);
      },
    ),
  );

  Future<void> _report() async {
    final crop = TextEditingController(), market = TextEditingController(), district = TextEditingController(), price = TextEditingController();
    var category = 'Vegetables', unit = 'kg';
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Submit local market price'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: crop, decoration: const InputDecoration(labelText: 'Produce')),
        TextField(controller: market, decoration: const InputDecoration(labelText: 'Market / pola')),
        TextField(controller: district, decoration: const InputDecoration(labelText: 'District')),
        DropdownButtonFormField(value: category, items: const ['Vegetables','Fruits','Grains','Spices','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => category = v ?? 'Other')),
        Row(children: [Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (LKR)'))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField(value: unit, items: const ['kg','g','ton','pcs','piece','box','crate','bunch','bag','liter'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => unit = v ?? 'kg')))]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final p = double.tryParse(price.text); if (p != null && p > 0 && crop.text.trim().isNotEmpty && market.text.trim().isNotEmpty && district.text.trim().isNotEmpty) Navigator.pop(ctx, {'crop':crop.text.trim(),'market':market.text.trim(),'district':district.text.trim(),'category':category,'unit':unit,'price':p}); }, child: const Text('Submit for review'))],
    )));
    if (result == null) return;
    try {
      await _market.submitPriceReport(cropName: result['crop'], category: result['category'], marketName: result['market'], district: result['district'], unit: result['unit'], price: result['price']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price submitted for verification.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit price: $error')));
    }
  }
}
