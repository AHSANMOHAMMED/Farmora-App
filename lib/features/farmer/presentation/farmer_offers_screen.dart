import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/offer.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

class FarmerOffersScreen extends StatelessWidget {
  const FarmerOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final fs = FirestoreService();
    final farmerId = state.currentUserId;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Offers'),
      ),
      body: farmerId.isEmpty
          ? Center(child: Text(l10n.signIn))
          : StreamBuilder<List<FarmoraOffer>>(
              stream: fs.offersByFarmerStream(farmerId),
              builder: (context, snapshot) {
                return AsyncStateView(
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(offer.productName),
                          subtitle: Text(
                            '${l10n.quantity}: ${offer.proposedQuantity}\n'
                            '${l10n.price}: LKR ${(offer.proposedPriceMinor / 100).toStringAsFixed(2)}\n'
                            '${l10n.status}: ${offer.status.toUpperCase()}',
                          ),
                          isThreeLine: true,
                          trailing: offer.status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await fs.acceptOffer(offerId: offer.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.success),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('${l10n.error}: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await fs.rejectOffer(offer.id);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('${l10n.error}: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : null,
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
