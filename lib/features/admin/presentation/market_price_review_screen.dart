import 'package:flutter/material.dart';
import '../../../services/community_market_service.dart';

class MarketPriceReviewScreen extends StatelessWidget {
  MarketPriceReviewScreen({super.key});
  final CommunityMarketService _market = CommunityMarketService();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community price reports')),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _market.watchPriceReports(pendingOnly: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load reports: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('No market price reports awaiting review.'));
        return ListView.builder(padding: const EdgeInsets.all(12), itemCount: snapshot.data!.length, itemBuilder: (context, index) {
          final report = snapshot.data![index];
          final price = (report['priceMinor'] as num).toInt() / 100;
          return Card(child: ListTile(
            title: Text('${report['cropName']} · LKR ${price.toStringAsFixed(2)} / ${report['unit']}'),
            subtitle: Text('${report['marketName']} · ${report['district']} · ${report['category']}\nSubmitted by ${report['reporterRole']}'),
            isThreeLine: true,
            trailing: Wrap(spacing: 4, children: [
              IconButton(tooltip: 'Reject report', onPressed: () => _review(context, report['id'], 'reject'), icon: const Icon(Icons.close, color: Colors.red)),
              IconButton(tooltip: 'Approve report', onPressed: () => _review(context, report['id'], 'approve'), icon: const Icon(Icons.check_circle, color: Colors.green)),
            ]),
          ));
        });
      },
    ),
  );

  Future<void> _review(BuildContext context, String reportId, String decision) async {
    try {
      await _market.reviewPriceReport(reportId, decision);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decision == 'approve' ? 'Verified report added to market rates.' : 'Report rejected.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not review report: $error')));
    }
  }
}
