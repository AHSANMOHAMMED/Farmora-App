/// Production workflows always go through trusted callable Cloud Functions.
/// Use the Firebase Emulator Suite for local development; never switch to the
/// legacy client-side write adapter in a real build.
const bool kUseCloudFunctions = true;
