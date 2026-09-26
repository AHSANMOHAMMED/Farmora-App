/// Production workflows can route through trusted Cloud Functions when deployed.
/// When running on Firebase Spark (or without deployed Cloud Functions),
/// Farmora seamlessly uses SparkBackend (direct secured Firestore operations).
const bool kUseCloudFunctions = bool.fromEnvironment(
  'USE_CLOUD_FUNCTIONS',
  defaultValue: false,
);

