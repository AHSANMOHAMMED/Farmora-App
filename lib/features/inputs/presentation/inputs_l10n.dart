import 'package:flutter/material.dart';

import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/farm_input.dart';

String inputCategoryLabel(AppLocalizations l, InputCategory c) => switch (c) {
      InputCategory.seeds => l.inpCatSeeds,
      InputCategory.fertilizer => l.inpCatFertilizer,
      InputCategory.pesticide => l.inpCatPesticide,
      InputCategory.tools => l.inpCatTools,
      InputCategory.machinery => l.inpCatMachinery,
    };

IconData inputCategoryIcon(InputCategory c) => switch (c) {
      InputCategory.seeds => Icons.grass_rounded,
      InputCategory.fertilizer => Icons.science_outlined,
      InputCategory.pesticide => Icons.bug_report_outlined,
      InputCategory.tools => Icons.handyman_outlined,
      InputCategory.machinery => Icons.agriculture_rounded,
    };

String inputStatusLabel(AppLocalizations l, String status) => switch (status) {
      InputOrderStatus.pending => l.inpStatusPending,
      InputOrderStatus.confirmed => l.inpStatusConfirmed,
      InputOrderStatus.dispatched => l.inpStatusDispatched,
      InputOrderStatus.delivered => l.inpStatusDelivered,
      InputOrderStatus.inUse => l.inpStatusInUse,
      InputOrderStatus.returned => l.inpStatusReturned,
      InputOrderStatus.rejected => l.inpStatusRejected,
      InputOrderStatus.cancelled => l.inpStatusCancelled,
      _ => status,
    };

Color inputStatusColor(String status) => switch (status) {
      InputOrderStatus.pending => const Color(0xFFE65100),
      InputOrderStatus.rejected || InputOrderStatus.cancelled =>
        const Color(0xFFC62828),
      InputOrderStatus.delivered || InputOrderStatus.returned =>
        const Color(0xFF2E7D32),
      _ => const Color(0xFF1565C0),
    };

/// "LKR 1,200 / bag" or "LKR 8,000 / day".
String inputPriceLabel(AppLocalizations l, FarmInput i) => l.inpPricePer(
    AppFormat.lkr(i.price), i.isRental ? l.inpPerDay : i.unit);

/// Small coloured status chip used by both farmer and supplier lists.
class InputStatusChip extends StatelessWidget {
  const InputStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = inputStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(inputStatusLabel(context.l10n, status),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
