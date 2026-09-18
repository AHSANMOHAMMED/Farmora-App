/// Spark (free) plan: Cloud Functions are unavailable.
/// Set `--dart-define=USE_CLOUD_FUNCTIONS=true` after upgrading to Blaze.
const bool kUseCloudFunctions =
    bool.fromEnvironment('USE_CLOUD_FUNCTIONS', defaultValue: false);
