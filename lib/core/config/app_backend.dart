/// Production workflows can route through trusted Cloud Functions when deployed.
/// When running on Firebase Spark (or without deployed Cloud Functions),
/// Farmora seamlessly uses SparkBackend (direct secured Firestore operations).
const bool kUseCloudFunctions = bool.fromEnvironment(
  'USE_CLOUD_FUNCTIONS',
  defaultValue: false,
);

/// Optional public image CDN for Spark builds. Configure with:
/// `--dart-define=USE_CLOUDINARY=true --dart-define=CLOUDINARY_CLOUD_NAME=...`
/// and an unsigned upload preset. Only public product/profile images use it;
/// private evidence still requires Firebase Storage.
const bool kUseCloudinary = bool.fromEnvironment(
  'USE_CLOUDINARY',
  defaultValue: true,
);
const String kCloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
  defaultValue: 'lzc3piy6',
);
const String kCloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
  defaultValue: 'farmora',
);

/// Sample Sri Lankan catalog (products, orders, jobs, offers, market prices)
/// for offline demos only. Off in real builds so every screen shows
/// Firestore records and nothing is "placed" without reaching the backend.
/// Enable with `--dart-define=DEMO_DATA=true`.
const bool kDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: false);
