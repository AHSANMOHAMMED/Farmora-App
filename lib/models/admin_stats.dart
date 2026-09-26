/// Platform totals for the admin dashboard, computed with Firestore
/// aggregate queries (not by downloading collections).
class AdminStats {
  final int totalUsers;
  final int farmers;
  final int buyers;
  final int transporters;
  final int admins;
  final int totalOrders;

  /// Sum of `orders.totalMinor` (LKR cents).
  final int grossVolumeMinor;
  final int openDisputes;
  final DateTime? fetchedAt;

  const AdminStats({
    this.totalUsers = 0,
    this.farmers = 0,
    this.buyers = 0,
    this.transporters = 0,
    this.admins = 0,
    this.totalOrders = 0,
    this.grossVolumeMinor = 0,
    this.openDisputes = 0,
    this.fetchedAt,
  });

  static const empty = AdminStats();

  /// Gross order volume in LKR major units.
  double get grossVolume => grossVolumeMinor / 100.0;

  bool get isLoaded => fetchedAt != null;
}
