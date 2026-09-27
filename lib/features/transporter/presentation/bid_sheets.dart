import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../services/bidding_service.dart';

void _fail(BuildContext context, Object e, String action) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(userMessage(e, action: action)),
    backgroundColor: AppColors.error,
  ));
}

/// Transporter: place, change or withdraw a bid on an open job.
Future<void> showPlaceBidSheet(BuildContext context, String jobId) async {
  final l = context.l10n;
  final service = BiddingService();
  final int max;
  final TransportBid? mine;
  try {
    max = await service.maxFeeMinor(jobId);
    mine = await service.myBid(jobId).first;
  } catch (e) {
    if (context.mounted) _fail(context, e, 'load the bid');
    return;
  }
  if (!context.mounted) return;
  final amount = TextEditingController(
      text: mine == null ? '' : '${mine.amountMinor ~/ 100}');
  final eta = TextEditingController(text: '${mine?.etaHours ?? 24}');
  final note = TextEditingController(text: mine?.note);
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(mine == null ? l.bidPlace : l.bidUpdate,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(l.bidMax(AppFormat.lkr(max / 100)),
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: l.bidAmount, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: eta,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: l.bidEta, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: note,
            maxLength: 300,
            decoration: InputDecoration(
                labelText: l.bidNote, border: const OutlineInputBorder()),
          ),
          Row(children: [
            if (mine != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'withdraw'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l.bidWithdraw),
              ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(mine == null ? l.bidPlace : l.bidUpdate),
            ),
          ]),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  try {
    if (action == 'withdraw') {
      await service.withdrawBid(jobId);
    } else {
      await service.placeBid(
        jobId: jobId,
        amountMinor: (int.tryParse(amount.text) ?? 0) * 100,
        etaHours: int.tryParse(eta.text) ?? 0,
        note: note.text,
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'withdraw' ? l.bidWithdrawn : l.bidSent)));
    }
  } catch (e) {
    if (context.mounted) _fail(context, e, 'place the bid');
  }
}

/// Farmer: compare bids on an open delivery and award one.
Future<void> showBidsSheet(BuildContext context, String jobId) {
  final l = context.l10n;
  final service = BiddingService();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => StreamBuilder<List<TransportBid>>(
        stream: service.bids(jobId),
        builder: (ctx, snap) {
          final bids = snap.data ?? const <TransportBid>[];
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.bidsTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              Text(l.bidsHint,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
              if (snap.hasError) Text(userMessage(snap.error!)),
              if (snap.hasData && bids.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.bidsNone, textAlign: TextAlign.center),
                ),
              for (final (i, b) in bids.indexed)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          i == 0 ? AppColors.primary : Colors.grey.shade300,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: i == 0 ? Colors.white : Colors.black)),
                    ),
                    title: Text(
                        '${AppFormat.lkr(b.amount)} · ${b.transporterName}'),
                    subtitle: Text([
                      l.bidEtaValue('${b.etaHours}'),
                      if (b.vehicleType.isNotEmpty) b.vehicleType,
                      if (b.note.isNotEmpty) b.note,
                    ].join(' · ')),
                    trailing: FilledButton(
                      onPressed: () async {
                        try {
                          await service.award(jobId, b, others: bids);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.bidAwarded)));
                          }
                        } catch (e) {
                          if (context.mounted) _fail(context, e, 'accept the bid');
                        }
                      },
                      child: Text(l.bidAccept),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
