# Changelog

All notable changes to Veliq are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-23

### Added
- **Multi-language source input.** The source language is now a choice from a 14-language catalog
  (`lib/models/language.dart`) instead of always English, and the default source is **Auto-detect**.
  Settings only offers languages the device's text recognition can actually read.
- **Language-aware OCR.** `OcrApi.recognizeText` takes a language hint and `OcrApi.supportedLanguages()`
  reports what the platform can read — from Apple Vision at runtime on macOS/iOS, from the bundled
  ML Kit Latin model on Android (D-018).
- **iOS OCR backend.** `ios/Runner/OcrHandler.swift` (UIImage → CGImage, EXIF orientation, Vision) — the
  iOS target previously had no OCR implementation at all.
- **Source language detection shown to the user.** With the source on Auto-detect, Gemini reports the
  language it recognised, so the result card reads `Original (French)` and History records
  `French → Persian` instead of a generic "Auto-detect" (T-157). An explicit source choice always wins.
- **Language names in History** instead of raw ISO codes (`English → Persian`, not `EN → FA`) (T-158).
- A Pigeon regeneration script (`tool/gen_pigeon.sh`) and a CI step that fails when the generated
  bindings are stale.

### Changed
- The Gemini prompt now uses language names rather than codes, and Apple's on-device translation is
  refused with a readable message when the source is Auto-detect, because it needs a concrete language
  (T-154).
- Settings warns when the source and target languages are the same.

### Fixed
- Settings said the Gemini API key was stored in "this Mac's app preferences" although it lives in the
  Keychain; it now names the real store, and iOS no longer says "Mac" (T-158, T-159).
- Duplicate/unused code paths removed while wiring the language hint through the OCR pipeline.

## [1.0.1] - 2026-10-16

### Fixed
- **Android release builds could not reach the network.** Flutter declares `android.permission.INTERNET`
  only in the debug/profile manifests, so the release build could not call the Gemini API; the permission
  is now in the main manifest (T-141).
- **Android release builds crashed on launch.** R8 (minify + resource shrinking) stripped and renamed the
  reflectively loaded ML Kit internals, crashing `MainActivity.configureFlutterEngine()`; a
  `proguard-rules.pro` with `-keep`/`-dontwarn` rules for `com.google.mlkit.**` is now wired into the
  release build type (T-141).

## [1.0.0] - 2026-10-16

### Added
- First public release.
- Signed Android APK (+ `.sha256`) published on GitHub Releases; macOS and iOS are built from source.
- Region capture on macOS (ScreenCaptureKit + overlay), local OCR with Apple Vision, translation with
  Google Gemini using a private API key kept in the Keychain, RTL-correct Persian result panel.
- Photo Picker / Camera input on iOS and Android with ML Kit OCR, translation history and a settings
  screen.

[1.1.0]: https://github.com/moradzadeh67/veliq/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/moradzadeh67/veliq/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/moradzadeh67/veliq/releases/tag/v1.0.0
