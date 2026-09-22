# Project-specific R8 rules belong here.
# Keep this file present so release builds fail only on real shrinker errors.

# Firebase Firestore pulls in optional gRPC/Geo type references that are not
# part of the APK classpath. These are safe to ignore at shrink time.
-dontwarn com.google.rpc.Status
-dontwarn com.google.type.LatLng
-dontwarn com.google.type.LatLng$Builder
