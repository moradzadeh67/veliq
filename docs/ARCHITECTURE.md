# Veliq — Architecture

## Overview
macOS, iOS and Android (v1) utility: Flutter/Dart for the app layer, Swift for the Apple
integrations (`macos/Runner`, `ios/Runner`) and Kotlin for Android (`android/app`). Local-first
and privacy-focused: captured content stays on the device whenever possible.

## Layers
```
+--------------------------------------------------+
| UI (Flutter)                                     |
| Selection overlay | Result panel | Settings/History |
+--------------------------------------------------+
                      |
+--------------------------------------------------+
| Application (Dart): BLoC state, controllers,     |
| service abstractions                             |
+--------------------------------------------------+
                      |
+--------------------------------------------------+
| Native bridge: Pigeon (Dart <-> Swift/Kotlin)    |
+--------------------------------------------------+
                      |
+--------------------------------------------------+
| Native (Swift/Kotlin): capture and Vision/ML Kit |
| OCR, permissions, shortcuts (if native)          |
+--------------------------------------------------+
```

## Responsibilities
- UI: selection overlay, result panel (RTL-correct Persian), settings, history.
- Application: capture workflow, translation workflow, settings, history. State is immutable and
  separated from UI.
- Bridge: only the interfaces needed by the app, defined in Pigeon.
- Native: only what Flutter cannot do reliably. Keep it small.

## Data flow
macOS:
```
trigger -> selection overlay (Dart) -> region coordinates -> Swift capture
-> image data -> Swift Vision OCR (local, source language hint, D-018) -> extracted text -> Dart
-> translation provider (TEXT ONLY) -> result panel
```
iOS (no region selection — the user supplies the image):
```
Pick image / Take photo (Dart) -> Swift ImageSourceHandler (PHPickerViewController or
UIImagePickerController) -> image bytes -> Swift OcrHandler (Vision, EXIF orientation honoured)
-> extracted text -> Dart -> translation provider (TEXT ONLY) -> result panel
```
Android (no region selection; any of the three providers):
```
pick photo (Photo Picker intents, no permission) or take photo (Kotlin, ACTION_IMAGE_CAPTURE +
FileProvider cache file, deleted after reading) -> Kotlin ImageSourceApi -> bytes ->
Kotlin OCR (local): ML Kit Latin, plus Tesseract for an explicit fa/ar/ru; with `auto` both run
and the results are compared by confidence (D-018, D-019, D-021) -> extracted text -> Dart ->
selected provider (TEXT ONLY) -> result panel + local history
```
Language selection (P15, D-018): `AppSettings.sourceLanguage` (default `auto`) is passed to
OCR as a hint before the same pair is used for translation; the From picker only offers the
codes `OcrApi.supportedLanguages()` reports for the current platform.

Rules: captured content stays local; image data released after OCR; only text leaves the
device; no analytics. See docs/PRIVACY.md.

## Decisions (append-only; keep IDs stable)
| ID | Topic | Decision | Status |
|---|---|---|---|
| D-001 | State management | BLoC | DECIDED |
| D-002 | Dart<->Swift bridge | Pigeon | DECIDED (verified in T-014) |
| D-003 | Screen capture API | ScreenCaptureKit (SCScreenshotManager); CGWindowListCreateImage is obsoleted in macOS 15 SDK. Minimum macOS 14. Region capture, Retina and multi-display conversion are **VERIFIED on hardware** (T-063, 2026-10-11 — details in docs/MACOS_PERMISSIONS.md). Displays with a negative y-origin and macOS 27 behavior remain UNVERIFIED. | DECIDED (API); VERIFIED for Retina + multi-display (T-063); UNVERIFIED for negative-origin displays and macOS 27 |
| D-004 | Global shortcut | native API vs maintained Flutter plugin | OPEN, T-011 |
| D-005 | Translation provider | Gemini API (text only, never the screenshot) via `GeminiTranslationService`, selected through `SwitchingTranslationService`. Apple Translation (`PigeonTranslationService`) is kept as the on-device option (programmatic API is macOS 26.0+ only; no Persian support per project owner). The user supplies their own API key. Free-tier Gemini content may be used by Google to improve its products (see docs/PRIVACY.md). Model ids VERIFIED (T-070, checked 2026-10-12 against https://ai.google.dev/gemini-api/docs/models): `gemini-2.5-flash` exists, but Google limits the 2.5 family to projects that actively used them before, so new keys get HTTP 404. The default model is therefore `gemini-3.5-flash-lite` (Google's recommended model for new projects) with fallbacks `gemini-3.8-flash` → `gemini-2.0-flash`; before this fix the default was `gemini-2.5-flash` (commit 6f4d048), which cost a failed 404 round trip on every run. Quota numbers (1500 RPD in commit 6f4d048) UNVERIFIED: the official rate-limits page (https://ai.google.dev/gemini-api/docs/rate-limits, last updated 2026-10-09) publishes no static RPD table and refers to AI Studio instead. | DECIDED (API); privacy notice DONE (T-067); model ids VERIFIED / quota UNVERIFIED (T-070) |
| D-006 | Local storage (history/settings) | `shared_preferences` (backed by NSUserDefaults) for app settings; a JSON file `history.json` for translation history (`JsonHistoryRepository`). Since T-121 the directory is resolved with `path_provider`'s `getApplicationSupportDirectory()` (on macOS that resolves inside the sandbox container to `~/Library/Containers/com.moradzadeh67.veliq/Data/Library/Application Support/com.moradzadeh67.veliq/` — the folder is named after the bundle id; path re-verified on disk 2026-10-16, an older `veliq/` folder from a previous build may still exist), not a hard-coded default; `JsonHistoryRepository()` without an explicit `File` throws `StateError`. Both behind service interfaces; no cloud sync. | DECIDED (path resolution updated in T-121; path corrected 2026-10-16) |
| D-007 | OCR | Apple Vision (VNRecognizeTextRequest), local | DECIDED |
| D-008 | IDE | Android Studio daily; Xcode only for deep Swift/permission/profiling issues | DECIDED |
| D-009 | API key storage | flutter_secure_storage with MacOsOptions(usesDataProtectionKeychain: false) (legacy login keychain: no keychain-access-groups, no provisioning profile; documented by the package). No paid Apple account assumed. App Sandbox interplay, Keychain password prompts after ad-hoc rebuilds, and a later move to the data-protection keychain are UNVERIFIED. One-time migration from shared_preferences. | DECIDED (approach), UNVERIFIED (details) |
| D-010 | iOS image source (gallery) | `PHPickerViewController` (PhotosUI framework). Runs out-of-process, requires NO photo-library permission. Available since iOS 14.0. Apple's recommended picker for new apps. | DECIDED (source: https://developer.apple.com/documentation/photokit/phpickerviewcontroller) |
| D-011 | iOS image source (camera) | `UIImagePickerController` with `sourceType = .camera`, `mediaTypes = ["public.image"]`. Still Apple's standard camera modal for capturing a single photo. Available since iOS 2.0. | DECIDED (source: https://developer.apple.com/documentation/uikit/uiimagepickercontroller) |
| D-012 | iOS Info.plist privacy keys | Only `NSCameraUsageDescription` is required (for the camera). `NSPhotoLibraryUsageDescription` is NOT required because `PHPickerViewController` is out-of-process. `NSPhotoLibraryAddUsageDescription` is NOT required because Veliq never writes to the photo library. | DECIDED (source: https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription) |
| D-013 | iOS minimum deployment target | iOS 16.0. Rationale: (1) aligns with the existing macOS 14.6 baseline's modernity; (2) `PHPickerViewController` comfortably available; (3) modern Swift concurrency available without `#available` guards; (4) VNRecognizeTextRequest stable. | DECIDED, APPLIED (T-126, 2026-10-14): `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in ios/Runner.xcodeproj (all three configs) and `platform :ios, '16.0'` in ios/Podfile. (source: https://developer.apple.com/documentation/photokit/phpickerviewcontroller — "Availability: iOS 14.0+"; 16.0 is a stricter, still-compatible floor) |
| D-014 | Pigeon bridge and image bytes | Dart `Uint8List` maps to Swift `FlutterStandardTypedData` via the standard codec. Sizes of 2–5 MB JPEG are within Flutter's standard channel limits (no fragmentation API needed). No platform-specific workaround required. | DECIDED (source: https://docs.flutter.dev/platform-integration/platform-channels) |
| D-015 | App icon source of truth | One master vector at `assets/branding/logo.svg` (512×512 squircle, four white brackets pushed 20 % outward, four gold text bars), turned into every required size by `assets/app_icon/source/generate_icons.sh` with `rsvg-convert` at the exact target pixel size — no intermediate raster, so no keying/crop/resize tuning. macOS renders keep the squircle clip and therefore a **transparent** surround; iOS renders strip the clip attribute and are **full-bleed opaque** (no alpha channel, asserted by `sips -g hasAlpha`) because Apple rejects icons carrying alpha and the OS applies its own mask. The former raster master `icon_master.png` was deleted (2026-10-14). File names are unchanged from the Flutter templates, so neither `Contents.json` needed an edit. | DECIDED, IMPLEMENTED (T-125); REWORKED (2026-10-14): master is now the vector `assets/branding/logo.svg` |
| D-016 | Android v1 scope and native stack | Android v1 (P12) is **photo input only**: gallery via the Android **Photo Picker** intents (`ACTION_PICK_IMAGES` on API 33+, `ACTION_GET_CONTENT` fallback, no storage permission) and camera via `ACTION_IMAGE_CAPTURE` + `EXTRA_OUTPUT` + a `FileProvider` cache file deleted right after reading (CAMERA runtime permission; `<uses-feature camera required="false">`). `ActivityResultContracts.TakePicture` was not usable because `FlutterActivity` is not a `ComponentActivity` (deviation from the original plan, T-135). OCR is the **bundled ML Kit Latin** recognizer `com.google.mlkit:text-recognition:16.0.1` (Latin script only) implemented **directly in Kotlin behind Pigeon** — no Flutter ML Kit package, so the Dart layer stays untouched; `minSdk = flutter.minSdkVersion` (24 with Flutter 3.47). Only `ImageSourceApi` and `OcrApi` are registered on the Android Pigeon host; `SelectionApi`, `ScreenCaptureApi` and `TranslationApi` are never registered there because no Android UI calls them. Region selection and screen capture (MediaProjection + foreground service) are explicitly out of v1, and Apple Translation is unavailable on Android — at the time of this decision translation was Gemini only (**superseded in part** by D-019, a second OCR engine, and D-020, the keyless Google Translate provider, which is now the default). | DECIDED (user-approved 2026-10-14); IMPLEMENTED — T-131..T-139 DONE 2026-10-15, emulator-verified (T-139); extended by D-019/D-020/D-021 |
| D-017 | Android release build vs. R8 | Android `--release` enables R8 (minify + resource shrinking, full mode) by default; ML Kit instantiates its components **reflectively**, so its internals must be kept or R8 strips/renames them and the app crashes on launch when `TextRecognition.getClient()` runs. Keep rules live in `android/app/proguard-rules.pro` (`com.google.mlkit.**`, `com.google.android.gms.internal.mlkit_**`, `com.google.android.libraries.vision.**`) and are wired into the release build type with `proguardFiles(...)`. `android.permission.INTERNET` is declared in the **main** manifest because Flutter only adds it to debug/profile. Debug builds never run R8, so a `--release` APK must be smoke-tested after OCR/dependency/build changes. | DECIDED (T-141, 2026-10-16) |
| D-018 | OCR language model | Languages come from one static catalog (`lib/models/language.dart`: `Language` + `LanguageCatalog`, 14 ISO 639-1 codes plus the source-only pseudo-code `auto`), while *capability* is asked from the platform at runtime through `OcrApi.supportedLanguages()` (`OcrService.supportedLanguages()` → `Set<String>`). Apple (macOS + iOS) returns the de-duplicated base codes of `VNRecognizeTextRequest.supportedRecognitionLanguages()` — never a hard-coded list; Android returns the bundled ML Kit Latin set plus the Tesseract scripts — `en, de, fr, es, it, pt, nl, tr, fa, ar, ru` (T-163). `recognizeText(bytes, languageHint)` takes the source language: `null`/`auto` sets `automaticallyDetectsLanguage = true`, an explicit code restricts `recognitionLanguages` to the matching Vision entries (`zh-Hans` → `zh`) and throws a readable error when nothing matches; on Android the hint **selects the engine** — an explicit `fa`/`ar`/`ru` goes to Tesseract, a Latin code or `auto` starts with ML Kit (D-019, D-021). `AppSettings.defaultSourceLanguage` is `auto` and there is **no migration**: `load()` only falls back when nothing is stored, so an existing choice survives. Settings disables languages the device does not report and shows a "Use auto-detect" notice when a stored source is unsupported; the target picker is neither locked nor filtered. Known gaps: ML Kit has no Arabic/Persian, Cyrillic, CJK or Devanagari recognizer, so Android bundles Tesseract4Android with the `fas`, `ara` and `rus` traineddata files for those scripts (T-163); CJK and Devanagari remain unavailable there (APK size), Persian OCR on Apple is whatever Vision reports, and Apple's on-device Translation cannot take `auto`, so `SwitchingTranslationService` refuses Apple + `auto` with a readable error instead of failing natively. **Reporting what was detected (T-157):** `TranslationService.translateWithDetection` returns `TranslationOutcome(text, detectedSourceLanguage)`; its default implementation delegates to `translateText` and reports nothing, so Apple and every existing fake are unaffected. With an `auto` source Gemini is asked for `{"detected_language": "<ISO 639-1>", "translation": "..."}` and the reply is parsed leniently (code fences, English/native names, regional codes; an unparsable reply still translates); `GoogleTranslateFreeService` reads the same information from the endpoint's own `data[2]` field, and Apple's engine reports nothing. The flow then stores and displays the detected code instead of `auto`; an explicit source choice always wins. | DECIDED, IMPLEMENTED (P15, 2026-10-23; detection reporting added by T-157) |
| D-019 | Second Android OCR engine (Tesseract) | ML Kit publishes models for Latin, Chinese, Devanagari, Japanese and Korean only — there is **no** Arabic/Persian or Cyrillic model to add, so those scripts stayed unreadable on Android (the Latin model even "reads" Cyrillic as look-alike Latin letters, which reached Gemini as gibberish). Decision: bundle **Tesseract4Android 4.9.0** (JitPack, `com.github.adaptech-cz:tesseract4android`, OpenMP variant excluded) next to ML Kit, with the `tessdata_fast` `fas`, `ara` and `rus` files (~5.6 MB) as **assets** copied into `filesDir/tesseract/tessdata` on first use. Routing lives in `AndroidOcrApi` and the pure `chooseOcrResult` function: an explicit Latin source goes to ML Kit, `fa`/`ar`/`ru` go to Tesseract (one engine cached per language string), and `auto` runs ML Kit first, adds Tesseract `rus+fas+ara` when ML Kit is not trusted, and keeps the better *valid* candidate (see D-021). No download, no network, image stays in memory. `supportedLanguages()` advertises the union, so Settings unlocks those three languages on Android; CJK stays macOS/iOS-only (devanagari/CJK models would add several MB each for languages the app barely targets). Cost: arm64-v8a APK 31.7 → 41.9 MB. ProGuard keeps the JNI-facing `com.googlecode.tesseract.android.**` classes. Verified on the arm64 emulator with rendered Cyrillic and Persian paragraphs (correct line-for-line); accuracy on real photographs is NOT verified. | DECIDED, IMPLEMENTED (T-163, 2026-10-24) |
| D-020 | Free Google Translate provider | A third translation backend is added: Google Translate's free web endpoint (`translate_a/single`, `client=gtx`). It needs **no API key**, making it the default for new installs (Gemini requires an API key that is unreachable in Iran without a VPN). Only the extracted text — never the photo — is sent over HTTPS via POST. Lengthy text is chunked up to 1500 characters on line boundaries and sent sequentially. Handles HTTP 429 with one retry after delay (default 2s, 0s in tests). Implemented in `GoogleTranslateFreeService` and wired into `SwitchingTranslationService`. `TranslationProvider.googleTranslate` is appended to the enum; existing stored settings survive. Settings UI shows Gemini API key fields only when Gemini is selected, and displays a helper text for the free provider. | DECIDED, IMPLEMENTED (T-164, 2026-10-24) |
| D-021 | OCR confidence routing on Android | ML Kit Latin and Tesseract both run on Android. `ML_KIT_TRUST = 0.70`, `MIN_ACCEPT = 0.45`, `TESS_MIN_COVERAGE = 0.30` and `MIN_TESS_TEXT_CHARS = 10` are named, tunable constants in `AndroidOcrApi`. With source `auto`, ML Kit runs first: when its average element confidence is `>= ML_KIT_TRUST` and the text is non-blank it is accepted without running Tesseract. Otherwise Tesseract (`rus+fas+ara`) runs and the **better valid candidate** wins — but a Tesseract reading only competes when it has at least `max(10, ceil(0.30 × mlKitLength))` characters, because Tesseract averages over the few characters it happened to read (measured: 3 characters @0.82 beat 71 correct ones @0.608, T-168). A single candidate wins outright; with none, or with a winner below `MIN_ACCEPT`, the result is the empty string, which triggers T-162's readable misread-photo error in Flutter. Explicit sources run their matching engine only (Tesseract for `fa, ar, ru`, ML Kit for Latin) and also apply `MIN_ACCEPT`. The decision is the pure function `chooseOcrResult` (+ `minTessTextLength`), covered by 12 JUnit cases in `android/app/src/test/kotlin/com/moradzadeh67/veliq/OcrRoutingTest.kt`. One `Log.d("VeliqOcr", ...)` line records `mlConf`, `tessConf`, `chosen`, `mlLen`, `tessLen` and whether Tesseract counted as a candidate — numbers only, never recognised text. Pigeon API and Dart layer are unchanged. | DECIDED, IMPLEMENTED (T-165 + T-168, 2026-10-24) |

An OPEN decision must not be implemented until its task is DONE.

## Components
Dart (lib/services, lib/features/*): CaptureService, OcrService, TranslationService,
ImageSourceService (abstract interfaces); HistoryRepository, SettingsRepository;
Pigeon APIs in lib/pigeon.
Swift (macos/Runner): screen capture, Vision OCR, permission manager, shortcut manager (if native).
Swift (ios/Runner): ImageSourceHandler.swift (PHPickerViewController + UIImagePickerController),
registered in AppDelegate via ImageSourceApiSetup; the host view controller is resolved lazily at
call time because the scene-based lifecycle has no window when the engine starts (T-127). iOS reuses the same generated Pigeon Swift
file as macOS — it carries `#if os(iOS)` / `#elseif os(macOS)` import guards (T-112).
Vision OCR on iOS lives in ios/Runner/OcrHandler.swift (UIImage -> CGImage, EXIF orientation mapped
to `CGImagePropertyOrientation`, language hint + `supportedLanguages()`) and is registered with
`OcrApiSetup` in the same method (T-153). Before P15 the iOS target had **no** `OcrApi`
implementation — the only Vision handler was the macOS one, which uses `NSImage` and cannot run on
iOS — so gallery/camera OCR did not work on iOS until T-153.
Kotlin (android/app, P12 DONE T-131..T-139): hosts `ImageSourceApi` (Photo Picker intents,
`ACTION_IMAGE_CAPTURE` via a FileProvider cache file deleted after reading, CAMERA runtime
permission) and `AndroidOcrApi` (bundled ML Kit Latin plus Tesseract for Persian/Arabic/Russian;
`supportedLanguages()` returns `en, de, fr, es, it, pt, nl, tr, fa, ar, ru`) only — `SelectionApi`,
`ScreenCaptureApi` and `TranslationApi` are not registered on Android; everything is wired in
`MainActivity.configureFlutterEngine` (T-133). The engine choice is the pure `chooseOcrResult`
(+ `minTessTextLength`) covered by `android/app/src/test/kotlin/com/moradzadeh67/veliq/OcrRoutingTest.kt`
(D-021). The interface is built **through R8** (the release default), so ML Kit needs explicit keep
rules (D-017) and the Tesseract JNI classes need theirs (D-019) or the release build crashes.
Translation implementations: GoogleTranslateFreeService (keyless web endpoint; joined OCR lines,
1500-character chunks, one retry on HTTP 429), GeminiTranslationService (network, user key),
PigeonTranslationService (Apple, macOS 26+), and SwitchingTranslationService, which reads the stored
`TranslationProvider` and enforces the one impossible combination (Apple + `auto`). Language names and
the 14-language catalog live in `lib/models/language.dart` (`LanguageCatalog`), and the platform's
real capability comes from `OcrService.supportedLanguages()` / `OcrApi.supportedLanguages()`.
Tooling: `tool/gen_pigeon.sh` regenerates `lib/pigeon/messages.g.dart`, the Swift and the Kotlin
bindings from `pigeons/messages.dart`; CI fails when a generated file is stale.
Native selection overlay: macos/Runner/SelectionOverlayWindow.swift (SelectionApi).
Exact class/file names are fixed in each task, not here.

## Code organization
```
lib/
  main.dart    entry point and dependency wiring
  features/    home/ capture/ ocr/ translation/ history/ settings/ (each with bloc/ where it has state)
  services/    interfaces, Pigeon implementations and the three translation providers
  models/      data models (ScreenRegion, TranslationEntry, Language/LanguageCatalog)
  pigeon/      generated Dart bindings (never edited by hand)
pigeons/messages.dart  Pigeon definition — the source of truth for the bridge
tool/gen_pigeon.sh     regenerates every binding from it (CI checks for drift)
macos/Runner/  Swift native code: capture, Vision OCR, overlay window, Apple translation (+ generated Pigeon Swift)
ios/Runner/    Swift native code: ImageSourceHandler + OcrHandler (Vision) (+ the same generated Pigeon Swift)
android/app/   Kotlin native code: Photo Picker + camera + ML Kit/Tesseract OCR (own generated Pigeon Kotlin)
android/app/src/main/assets/tessdata/  fas/ara/rus traineddata (~5.6 MB, bundled, offline)
android/app/src/test/kotlin/           JUnit tests for the OCR routing (OcrRoutingTest.kt)
              proguard-rules.pro keeps ML Kit and the Tesseract JNI classes intact through R8 (D-017, D-019)
assets/app_icon/  icon generator script + veliq.icns output (not bundled: no pubspec assets entry)
assets/branding/  logo.svg master + social/readme branding assets (not bundled)
assets/diagrams/  the three SVG diagrams embedded in the README
test/          mirrors lib/
docs/          PRIVACY, ARCHITECTURE, RELEASE, MACOS_PERMISSIONS + the GitHub Pages site
references/    research notes
```
Subfolders inside a feature (e.g. bloc/, view/) are decided when the first feature task needs them.

## Permissions
macOS: Screen Recording expected; Accessibility NOT assumed.
iOS: camera only (`NSCameraUsageDescription`); the photo library needs no permission because
`PHPickerViewController` runs out-of-process (D-012).
Android: camera runtime permission only (*Take photo*); the Photo Picker needs no permission
(D-016). The `INTERNET` permission (manifest-declared, not a runtime prompt) is required for the
Gemini call and lives in the **main** manifest — Flutter only declares it in debug/profile (T-141).
See docs/MACOS_PERMISSIONS.md (Apple platforms).

## Testing
- Dart: unit tests for blocs/services, widget tests for UI, mocks for native services.
- Native: manual verification (capture, OCR accuracy, permissions, Retina/non-Retina,
  single/multi-monitor, several macOS versions).
- Android: manual verification on the emulator (Pixel_10_Pro_XL AVD); no physical device is in
  scope (T-139, 2026-10-15).
- Privacy: checklist verification before release.

## Principles
Local-first · privacy-focused · minimal native code · type-safe bridge · testable
abstractions · clear separation of concerns · decisions documented here.