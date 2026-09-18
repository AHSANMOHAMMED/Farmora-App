import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/offer.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class BuyerOffersScreen extends StatelessWidget {
  const BuyerOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final fs = FirestoreService();
    final buyerId = state.currentUserId;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Offers')),
      body: buyerId.isEmpty
          ? Center(child: Text(l10n.signIn))
          : StreamBuilder<List<FarmoraOffer>>(
              stream: fs.offersByBuyerStream(buyerId),
              builder: (context, snapshot) {
                return AsyncStateView(
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.hasError ? snapshot.error : null,
                  isEmpty: (snapshot.data ?? []).isEmpty,
                  emptyMessage: l10n.emptyState,
                  onRetry: () => (context as Element).markNeedsBuild(),
                  child: ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final offer = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(offer.productName),
                          subtitle: Text(
                            '${l10n.quantity}: ${offer.proposedQuantity}\n'
                            '${l10n.price}: LKR ${(offer.proposedPriceMinor / 100).toStringAsFixed(2)}\n'
                            '${l10n.status}: ${offer.status.toUpperCase()}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
