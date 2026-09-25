/// Backend mode.
///
/// Default (false): Spark plan. The client writes directly to Firestore and
/// Storage through [SparkBackend]; every write is validated by
/// `firestore.rules` / `storage.rules`. No Cloud Functions are required.
///
/// `--dart-define=USE_CLOUD_FUNCTIONS=true`: trusted callable workflows in
/// `functions/src/index.ts`. Only enable this after upgrading the project to
/// Blaze and running `firebase deploy --only functions`; otherwise every
/// callable fails (on web as `[firebase_functions/internal] internal`).
const bool kUseCloudFunctions = bool.fromEnvironment(
  'USE_CLOUD_FUNCTIONS',
  defaultValue: false,
);
