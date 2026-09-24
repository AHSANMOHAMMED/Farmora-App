/// All builds default to trusted callable workflows. They require deployed
/// Functions (or the Firebase Emulator Suite configured for local development).
/// The direct Firestore adapter is for isolated demos only.
const bool kUseCloudFunctions = bool.fromEnvironment(
  'USE_CLOUD_FUNCTIONS',
  defaultValue: true,
);
