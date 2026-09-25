/// Display helpers for buyer screens. Values stored in Firestore (categories,
/// units, payment methods, statuses) stay English; only the label shown to
/// the user is translated here.
library;

import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';

/// Translated label for a product category stored in English.
String buyerCategoryLabel(AppLocalizations l, String category) {
  switch (category.trim().toLowerCase()) {
    case 'all':
      return l.commonAll;
    case 'vegetables':
      return l.vegetables;
    case 'fruits':
      return l.fruits;
    case 'spices':
      return l.spices;
    case 'grains':
      return l.grains;
    case 'herbs':
      return l.buyerCategoryHerbs;
    default:
      return category;
  }
}

/// Translated unit ("kg" → கிலோ / කිලෝ). Unknown units are shown as stored.
String buyerUnitLabel(AppLocalizations l, String unit) {
  final u = unit.trim().toLowerCase();
  if (u == 'kg' || u == 'kgs' || u.isEmpty) return l.unitKg;
  return unit;
}

String _money(num value) =>
    AppFormat.lkr(value, decimals: value % 1 == 0 ? 0 : 2);

/// "LKR 200/kg" built from the numeric price, falling back to the stored text.
String buyerProductPrice(AppLocalizations l, Product product) {
  final value = product.effectivePricePerUnit;
  if (value <= 0) return product.price;
  return l.buyerPricePerUnit(_money(value), buyerUnitLabel(l, product.unit));
}

/// "100 kg" built from the numeric stock, falling back to the stored text.
String buyerProductQuantity(AppLocalizations l, Product product) {
  if (product.quantityAvailable <= 0) return product.quantity;
  return l.buyerQuantityWithUnit(
    AppFormat.number(product.quantityAvailable),
    buyerUnitLabel(l, product.unit),
  );
}

/// Order total as "LKR 1,234.00", falling back to the stored text.
String buyerOrderTotal(FarmoraOrder order) {
  final total = order.total;
  if (total <= 0) return order.totalAmount;
  return AppFormat.lkr(total, decimals: 2);
}

String buyerHarvestStatusLabel(AppLocalizations l, HarvestStatus status) {
  switch (status) {
    case HarvestStatus.growing:
      return l.buyerHarvestGrowing;
    case HarvestStatus.harvested:
      return l.statusHarvested;
    case HarvestStatus.packed:
      return l.buyerHarvestPacked;
    case HarvestStatus.inTransit:
      return l.statusInTransit;
    case HarvestStatus.delivered:
      return l.statusDelivered;
  }
}
