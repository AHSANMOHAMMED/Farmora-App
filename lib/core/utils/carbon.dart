import 'dart:math' as math;

/// Transparent, estimate-only carbon maths (kg CO2e). Factors are rounded
/// public averages (road freight per vehicle-km; Sri Lanka grid; IPCC-style
/// soil and tree defaults) and are labelled as estimates in the app.
class Carbon {
  Carbon._();

  /// kg CO2e per vehicle-km by vehicle class.
  static const _perKm = {
    'motorbike': 0.08,
    'threeWheeler': 0.10,
    'van': 0.25,
    'lorry': 0.60,
    'tractor': 0.90,
  };

  /// Vehicle class from a free-text vehicle type.
  static String vehicleClass(String type) {
    final t = type.toLowerCase();
    if (RegExp(r'bike|motor|scooter').hasMatch(t)) return 'motorbike';
    if (RegExp(r'three|tuk|3.?wheel|trishaw').hasMatch(t)) return 'threeWheeler';
    if (RegExp(r'tractor|land ?master|two.?wheel').hasMatch(t)) return 'tractor';
    if (RegExp(r'van|car|pickup|pick-up|cab|jeep').hasMatch(t)) return 'van';
    return 'lorry';
  }

  /// Delivery emissions; refrigerated (cold-chain) loads add ~20%.
  static double deliveryKg(double km, String vehicleType, {bool cold = false}) =>
      km * _perKm[vehicleClass(vehicleType)]! * (cold ? 1.2 : 1.0);

  /// Approximate district centres (lat, lng) for distance estimates.
  static const districts = {
    'Colombo': (6.93, 79.85), 'Gampaha': (7.09, 80.00), 'Kalutara': (6.58, 79.96),
    'Kandy': (7.29, 80.63), 'Matale': (7.47, 80.62), 'Nuwara Eliya': (6.97, 80.77),
    'Galle': (6.05, 80.22), 'Matara': (5.95, 80.54), 'Hambantota': (6.12, 81.12),
    'Jaffna': (9.66, 80.02), 'Kilinochchi': (9.39, 80.40), 'Mannar': (8.98, 79.90),
    'Vavuniya': (8.75, 80.50), 'Mullaitivu': (9.27, 80.81), 'Batticaloa': (7.73, 81.69),
    'Ampara': (7.30, 81.67), 'Trincomalee': (8.59, 81.21), 'Kurunegala': (7.49, 80.36),
    'Puttalam': (8.04, 79.83), 'Anuradhapura': (8.31, 80.40), 'Polonnaruwa': (7.94, 81.00),
    'Badulla': (6.99, 81.06), 'Monaragala': (6.87, 81.35), 'Ratnapura': (6.68, 80.40),
    'Kegalle': (7.25, 80.35), 'Dambulla': (7.86, 80.65), 'Peradeniya': (7.27, 80.60),
  };

  static (double, double)? placeOf(String? text) {
    if (text == null || text.isEmpty) return null;
    final t = text.toLowerCase();
    for (final e in districts.entries) {
      if (t.contains(e.key.toLowerCase())) return e.value;
    }
    return null;
  }

  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Road distance estimate: straight line × 1.3, from coordinates when
  /// known, otherwise from district names in the addresses. Null when
  /// neither end can be placed. A same-district trip counts as 10 km.
  static double? roadKm({
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    String? fromText,
    String? toText,
  }) {
    final a = (fromLat != null && fromLng != null) ? (fromLat, fromLng) : placeOf(fromText);
    final b = (toLat != null && toLng != null) ? (toLat, toLng) : placeOf(toText);
    if (a == null || b == null) return null;
    final km = haversineKm(a.$1, a.$2, b.$1, b.$2) * 1.3;
    return km < 10 ? 10 : double.parse(km.toStringAsFixed(1));
  }

  /// Farm practices that store carbon or avoid emissions: unit and
  /// t CO2e per unit per year.
  static const practices = {
    'composting': ('t compost', 0.20),
    'mulching': ('acre', 0.10),
    'no_till': ('acre', 0.30),
    'cover_crop': ('acre', 0.15),
    'agroforestry_trees': ('trees', 0.02),
    'solar_pump': ('L diesel saved', 0.00268),
    'biogas': ('digester', 1.00),
    'reduced_fertilizer': ('kg N saved', 0.0055),
  };

  static double practiceTonnes(String practice, double quantity) =>
      (practices[practice]?.$2 ?? 0) * quantity;
}
