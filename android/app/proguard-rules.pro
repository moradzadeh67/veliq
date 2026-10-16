# Veliq R8 / ProGuard rules.
#
# `flutter build apk --release` enables R8 (minify + resource shrinking) with
# full mode, which is the AGP 8+ default. Most libraries are fine with that,
# but ML Kit is not.

# ---------------------------------------------------------------------------
# ML Kit on-device text recognition (Android OCR, see D-016)
# ---------------------------------------------------------------------------
# ML Kit discovers and instantiates its components reflectively
# (ComponentDiscovery + MlKitInitProvider) and resolves the bundled recognizer
# implementation by class name, so R8 cannot see the references and renames /
# strips what they need. The AARs only ship consumer rules for native method
# names and proto fields, which is NOT enough.
#
# Symptom without these rules: the release APK crashes on launch with
#   java.lang.RuntimeException: Unable to start activity ... MainActivity
#   Caused by: java.lang.NullPointerException ... (ML Kit vision.text.internal)
# because MainActivity.configureFlutterEngine() creates the recognizer via
# TextRecognition.getClient(). Debug builds do not run R8, so this only shows
# up in release builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.libraries.vision.** { *; }
-keep class com.google.android.gms.internal.vision.** { *; }

-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.libraries.vision.**
