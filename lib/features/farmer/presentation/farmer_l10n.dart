import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/product.dart';

/// Display helpers for farmer screens. Values stored in Firestore (product
/// categories, units, legacy quantity/price strings) stay English; only the
/// text shown to the user is translated here.

/// Label for a stored product category ('Vegetables', 'Fruits', 'All' …).
String farmerCategoryLabel(String raw, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  return switch (raw.trim().toLowerCase()) {
    'all' => l.commonAll,
    'vegetables' || 'vegetable' => l.vegetables,
    'fruits' || 'fruit' => l.fruits,
    'grains' || 'grain' => l.grains,
    'spices' || 'spice' => l.spices,
    'herbs' || 'herb' => l.farmerCategoryHerbs,
    'dairy' => l.farmerCategoryDairy,
    _ => raw,
  };
}

/// Label for a stored unit ('kg', 'lbs', 'pcs', 'box', 'bunches').
String farmerUnitLabel(String raw, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  return switch (raw.trim().toLowerCase()) {
    'kg' => l.unitKg,
    'lbs' || 'lb' => l.farmerUnitLbs,
    'pcs' || 'pc' => l.farmerUnitPcs,
    'box' => l.farmerUnitBox,
    'bunches' || 'bunch' => l.farmerUnitBunches,
    _ => raw,
  };
}

String farmerHarvestStatusLabel(HarvestStatus s, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  return switch (s) {
    HarvestStatus.growing => l.farmerHarvestGrowing,
    HarvestStatus.harvested => l.statusHarvested,
    HarvestStatus.packed => l.farmerHarvestPacked,
    HarvestStatus.inTransit => l.statusInTransit,
    HarvestStatus.delivered => l.statusDelivered,
  };
}

final _storedQuantity =
    RegExp(r'^\s*(\d+(?:\.\d+)?)\s*([A-Za-z]+)\s+available\s*$');

/// "50 kg available" in the current language. The stored English string is
/// shown unchanged when it does not follow the standard pattern.
String farmerProductQuantityText(Product p, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  final m = _storedQuantity.firstMatch(p.quantity);
  if (m != null) {
    final n = num.tryParse(m.group(1)!) ?? 0;
    return l.farmerQuantityAvailable(
        AppFormat.number(n, decimals: n % 1 == 0 ? 0 : 2),
        farmerUnitLabel(m.group(2)!, l));
  }
  if (p.quantity.trim().isEmpty && p.quantityAvailable > 0) {
    return l.farmerQuantityAvailable(
        AppFormat.number(p.quantityAvailable), farmerUnitLabel(p.unit, l));
  }
  return p.quantity;
}

/// "LKR 120.00 / kg" in the current language (falls back to the stored text
/// when no numeric price is known).
String farmerProductPriceText(Product p, [AppLocalizations? l10n]) {
  final l = l10n ?? L10n.current;
  final price = p.effectivePricePerUnit;
  if (price <= 0 || p.unit.trim().isEmpty) return p.price;
  return l.farmerPricePerUnitValue(
      AppFormat.lkr(price, decimals: 2), farmerUnitLabel(p.unit, l));
}
