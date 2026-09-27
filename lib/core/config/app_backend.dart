/// Production workflows can route through trusted Cloud Functions when deployed.
/// When running on Firebase Spark (or without deployed Cloud Functions),
/// Farmora seamlessly uses SparkBackend (direct secured Firestore operations).
const bool kUseCloudFunctions = bool.fromEnvironment(
  'USE_CLOUD_FUNCTIONS',
  defaultValue: false,
);

/// Sample Sri Lankan catalog (products, orders, jobs, offers, market prices)
/// for offline demos only. Off in real builds so every screen shows
/// Firestore records and nothing is "placed" without reaching the backend.
/// Enable with `--dart-define=DEMO_DATA=true`.
const bool kDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: false);
