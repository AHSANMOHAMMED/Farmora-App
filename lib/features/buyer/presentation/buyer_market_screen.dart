import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_errors.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../models/market_price_index.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/community_market_service.dart';
import '../../../services/firebase_service.dart';
import 'buyer_orders_screen.dart';

class BuyerMarketScreen extends StatefulWidget {
  const BuyerMarketScreen({super.key});
  @override
  State<BuyerMarketScreen> createState() => _BuyerMarketScreenState();
}

class _BuyerMarketScreenState extends State<BuyerMarketScreen> with SingleTickerProviderStateMixin {
  final _market = CommunityMarketService();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _busy = false;
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Market & Requests'), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'My requests'), Tab(text: 'Market prices')])),
    body: TabBarView(controller: _tabs, children: [_requests(), _prices()]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _newRequest, icon: const Icon(Icons.campaign_outlined), label: const Text('Request produce')),
  );

  Widget _requests() => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _market.watchBuyerRequests(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return _empty(userMessage(snapshot.error!, action: 'load your requests'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.isEmpty) return _empty('Post a requirement to invite verified farmers to quote your produce order.');
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: snapshot.data!.length, itemBuilder: (context, i) {
        final request = snapshot.data![i];
        final date = firebaseDate(request['deliveryDate']);
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('${request['quantity']} ${request['unit']} ${request['produceName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text('${request['status']}'))]),
          Text('${request['district']} · Need by ${date == null ? 'date pending' : MaterialLocalizations.of(context).formatMediumDate(date)} · ${request['quoteCount'] ?? 0} farmer quote(s)'),
          if (request['status'] == 'open') ...[
            const Divider(),
            StreamBuilder<List<Map<String, dynamic>>>(stream: _market.watchQuotes(request['id']), builder: (context, quoteSnapshot) {
              if (!quoteSnapshot.hasData) return const LinearProgressIndicator();
              final quotes = quoteSnapshot.data!;
              if (quotes.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Waiting for farmer quotes.'));
              return Column(children: quotes.map((quote) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${quote['farmerName']} · LKR ${((quote['unitPriceMinor'] as num).toInt() / 100).toStringAsFixed(2)} / ${request['unit']}'),
                subtitle: Text('${quote['productName']} · delivery LKR ${((quote['deliveryFeeMinor'] as num).toInt() / 100).toStringAsFixed(2)}${(quote['message'] as String?)?.isNotEmpty == true ? '\n${quote['message']}' : ''}'),
                trailing: FilledButton(onPressed: quote['status'] == 'pending' && !_busy ? () => _accept(request['id'], quote['farmerId']) : null, child: const Text('Accept')),
              )).toList());
            }),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _busy ? null : () => _run(() => _market.cancelRequest(request['id']), success: 'Request closed.'), icon: const Icon(Icons.close), label: const Text('Close request'))),
          ],
          if (request['status'] == 'matched') TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BuyerOrdersScreen())), child: const Text('View resulting order')),
        ])));
      });
    },
  );

  Widget _prices() {
    final state = context.watch<FarmoraState>();
    return StreamBuilder<List<MarketPriceIndex>>(
      stream: FirestoreService().marketPricesStream(),
      builder: (context, snapshot) {
        final report = FilledButton.tonalIcon(
          onPressed: _busy ? null : _reportPrice,
          icon: const Icon(Icons.add_chart),
          label: const Text('Report a market price'),
        );
        final prices = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : state.marketPrices;

        if (prices.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            report,
            const SizedBox(height: 8),
            if (prices.isEmpty)
              _empty(
                  'No verified prices yet. Submit a market observation and an admin can add it to the benchmark.')
            else
              for (final price in prices)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.green),
                    title: Text(price.cropName),
                    subtitle: Text(
                        '${price.marketName.isEmpty ? price.district : price.marketName} · ${price.district} · ${price.category} · ${price.updatedAt.toLocal().toString().split(' ').first}'),
                    trailing: Text(
                      'LKR ${price.minPricePerKg.toStringAsFixed(2)}–${price.maxPricePerKg.toStringAsFixed(2)} / ${price.unit}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Benchmarks include community reports approved by Farmora administrators.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _newRequest() async {
    final state = context.read<FarmoraState>();
    final name = TextEditingController(), quantity = TextEditingController(), address = TextEditingController(), budget = TextEditingController(), notes = TextEditingController();
    final district = TextEditingController(text: state.district);
    var category = 'Vegetables', unit = 'kg', date = DateTime.now().add(const Duration(days: 3));
    final data = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Broadcast a produce request'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Produce item')),
        DropdownButtonFormField(initialValue: category, items: const ['Vegetables','Fruits','Grains','Spices','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => category = v ?? 'Other')),
        Row(children: [Expanded(child: TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField(initialValue: unit, decoration: const InputDecoration(labelText: 'Unit'), items: const ['kg','g','ton','pcs','piece','box','crate','bunch','bag','liter'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => unit = v ?? 'kg')))]),
        TextField(controller: district, decoration: const InputDecoration(labelText: 'Delivery district')),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Delivery address')),
        TextField(controller: budget, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Maximum price per $unit (optional LKR)')),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Grade, quality, or other details')),
        TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setDialog(() => date = d); }, child: Text('Required by ${MaterialLocalizations.of(ctx).formatMediumDate(date)}')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final q = int.tryParse(quantity.text); if (q != null && q > 0 && name.text.trim().isNotEmpty && address.text.trim().length >= 5) Navigator.pop(ctx, {'name': name.text.trim(),'category': category,'quantity': q,'unit': unit,'district': district.text.trim(),'address': address.text.trim(),'budget': double.tryParse(budget.text) ?? 0.0,'notes': notes.text.trim(),'date': date}); }, child: const Text('Broadcast'))],
    )));
    if (data == null) return;
    await _run(() => _market.createRequest(produceName: data['name'], category: data['category'], quantity: data['quantity'], unit: data['unit'], district: data['district'], deliveryAddress: data['address'], deliveryDate: data['date'], maxUnitPriceMinor: (data['budget'] * 100).round(), notes: data['notes']).then((_) {}), success: 'Request broadcast to farmers.');
  }

  Future<void> _reportPrice() async {
    final crop = TextEditingController(), market = TextEditingController(), district = TextEditingController(text: context.read<FarmoraState>().district), price = TextEditingController();
    var category = 'Vegetables', unit = 'kg';
    final data = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Report a local market price'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: crop, decoration: const InputDecoration(labelText: 'Produce item')),
        TextField(controller: market, decoration: const InputDecoration(labelText: 'Market / pola')),
        TextField(controller: district, decoration: const InputDecoration(labelText: 'District')),
        DropdownButtonFormField(initialValue: category, items: const ['Vegetables','Fruits','Grains','Spices','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => category = v ?? 'Other')),
        Row(children: [Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'LKR price'))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField(initialValue: unit, items: const ['kg','g','ton','pcs','piece','box','crate','bunch','bag','liter'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialog(() => unit = v ?? 'kg')))]),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final p = double.tryParse(price.text); if (p != null && p > 0 && crop.text.trim().isNotEmpty && market.text.trim().isNotEmpty && district.text.trim().isNotEmpty) Navigator.pop(ctx, {'crop':crop.text.trim(),'market':market.text.trim(),'district':district.text.trim(),'category':category,'unit':unit,'price':p}); }, child: const Text('Submit for review'))],
    )));
    if (data == null) return;
    await _run(() => _market.submitPriceReport(cropName: data['crop'], category: data['category'], marketName: data['market'], district: data['district'], unit: data['unit'], price: data['price']), success: 'Price report submitted for review.');
  }

  Future<void> _accept(String requestId, String farmerId) async {
    await _run(() async { await _market.acceptQuote(requestId, farmerId); },
        success: 'Quote accepted. The order is now in your orders for farmer confirmation.');
  }

  /// Awaits [action]; shows [success] only after it succeeded, otherwise the
  /// mapped error. Actions are disabled while one is in flight.
  Future<bool> _run(Future<void> Function() action, {String success = 'Saved.'}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      return true;
    } catch (e, st) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userMessage(e, stack: st)), backgroundColor: Colors.red.shade700));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _empty(String text) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center)));
}
