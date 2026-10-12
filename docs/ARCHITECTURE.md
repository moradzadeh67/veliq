# Veliq — Architecture

## Overview
macOS and iOS utility: Flutter/Dart for the app layer, Swift for native integration
(`macos/Runner`, `ios/Runner`). Local-first and privacy-focused: captured content stays
on the device whenever possible.

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
| Native bridge: Pigeon (type-safe Dart <-> Swift) |
+--------------------------------------------------+
                      |
+--------------------------------------------------+
| Native (Swift): screen capture, Vision OCR,      |
| permission checks, shortcuts (if native)         |
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
-> image data -> Swift Vision OCR (local) -> extracted text -> Dart
-> translation provider (TEXT ONLY) -> result panel
```
iOS (no region selection — the user supplies the image):
```
Pick image / Take photo (Dart) -> Swift ImageSourceHandler (PHPickerViewController or
UIImagePickerController) -> image bytes -> Swift Vision OCR (local) -> extracted text
-> Dart -> translation provider (TEXT ONLY) -> result panel
```
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
| D-006 | Local storage (history/settings) | `shared_preferences` (backed by NSUserDefaults) for app settings; a JSON file `history.json` for translation history (`JsonHistoryRepository`). Since T-121 the directory is resolved with `path_provider`'s `getApplicationSupportDirectory()` (on macOS that is `~/Library/Application Support/com.moradzadeh67.veliq/`), not a hard-coded default; `JsonHistoryRepository()` without an explicit `File` throws `StateError`. Both behind service interfaces; no cloud sync. | DECIDED (path resolution updated in T-121) |
| D-007 | OCR | Apple Vision (VNRecognizeTextRequest), local | DECIDED |
| D-008 | IDE | Android Studio daily; Xcode only for deep Swift/permission/profiling issues | DECIDED |
| D-009 | API key storage | flutter_secure_storage with MacOsOptions(usesDataProtectionKeychain: false) (legacy login keychain: no keychain-access-groups, no provisioning profile; documented by the package). No paid Apple account assumed. App Sandbox interplay, Keychain password prompts after ad-hoc rebuilds, and a later move to the data-protection keychain are UNVERIFIED. One-time migration from shared_preferences. | DECIDED (approach), UNVERIFIED (details) |
| D-010 | iOS image source (gallery) | `PHPickerViewController` (PhotosUI framework). Runs out-of-process, requires NO photo-library permission. Available since iOS 14.0. Apple's recommended picker for new apps. | DECIDED (source: https://developer.apple.com/documentation/photokit/phpickerviewcontroller) |
| D-011 | iOS image source (camera) | `UIImagePickerController` with `sourceType = .camera`, `mediaTypes = ["public.image"]`. Still Apple's standard camera modal for capturing a single photo. Available since iOS 2.0. | DECIDED (source: https://developer.apple.com/documentation/uikit/uiimagepickercontroller) |
| D-012 | iOS Info.plist privacy keys | Only `NSCameraUsageDescription` is required (for the camera). `NSPhotoLibraryUsageDescription` is NOT required because `PHPickerViewController` is out-of-process. `NSPhotoLibraryAddUsageDescription` is NOT required because Veliq never writes to the photo library. | DECIDED (source: https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription) |
| D-013 | iOS minimum deployment target | iOS 16.0. Rationale: (1) aligns with the existing macOS 14.6 baseline's modernity; (2) `PHPickerViewController` comfortably available; (3) modern Swift concurrency available without `#available` guards; (4) VNRecognizeTextRequest stable. | DECIDED — **NOT APPLIED**: `ios/Runner.xcodeproj/project.pbxproj` still has `IPHONEOS_DEPLOYMENT_TARGET = 15.0` and `ios/Podfile` still has the platform line commented out (checked 2026-10-12). Needs a task. (source: https://developer.apple.com/documentation/photokit/phpickerviewcontroller — "Availability: iOS 14.0+"; we choose 16.0 as a stricter, still-compatible floor) |
| D-014 | Pigeon bridge and image bytes | Dart `Uint8List` maps to Swift `FlutterStandardTypedData` via the standard codec. Sizes of 2–5 MB JPEG are within Flutter's standard channel limits (no fragmentation API needed). No platform-specific workaround required. | DECIDED (source: https://docs.flutter.dev/platform-integration/platform-channels) |
| D-015 | App icon source of truth | One master PNG at `assets/app_icon/source/icon_master.png`, turned into every required size by `assets/app_icon/source/generate_icons.sh` (key the black surround out → crop the empty margin → Lanczos resize → flatten for iOS). macOS icons keep a **transparent** surround; iOS icons are **opaque** on `#2B1F5C` because Apple rejects icons carrying an alpha channel. File names are unchanged from the Flutter templates, so neither `Contents.json` needed an edit. | DECIDED, IMPLEMENTED (T-125) |

An OPEN decision must not be implemented until its task is DONE.

## Components
Dart (lib/services, lib/features/*): CaptureService, OcrService, TranslationService,
ImageSourceService (abstract interfaces); HistoryRepository, SettingsRepository;
Pigeon APIs in lib/pigeon.
Swift (macos/Runner): screen capture, Vision OCR, permission manager, shortcut manager (if native).
Swift (ios/Runner): ImageSourceHandler.swift (PHPickerViewController + UIImagePickerController),
registered in AppDelegate via ImageSourceApiSetup. iOS reuses the same generated Pigeon Swift
file as macOS — it carries `#if os(iOS)` / `#elseif os(macOS)` import guards (T-112).
Translation implementations: GeminiTranslationService (network, user key), PigeonTranslationService (Apple, macOS 26+),
SwitchingTranslationService (chooses between them from settings).
Native selection overlay: macos/Runner/SelectionOverlayWindow.swift (SelectionApi).
Exact class/file names are fixed in each task, not here.

## Code organization
```
lib/
  core/        constants, utilities
  features/    capture/ ocr/ translation/ history/ settings/
  services/    abstract service interfaces
  models/      data models
  pigeon/      Pigeon definition + generated Dart
macos/Runner/  Swift native code (+ generated Pigeon Swift)
ios/Runner/    Swift native code (+ the same generated Pigeon Swift)
assets/app_icon/  icon master + generator script (not bundled: no pubspec assets entry)
test/          mirrors lib/
docs/  references/
```
Subfolders inside a feature (e.g. bloc/, view/) are decided when the first feature task needs them.

## Permissions
macOS: Screen Recording expected; Accessibility NOT assumed.
iOS: camera only (`NSCameraUsageDescription`); the photo library needs no permission because
`PHPickerViewController` runs out-of-process (D-012).
See docs/MACOS_PERMISSIONS.md.

## Testing
- Dart: unit tests for blocs/services, widget tests for UI, mocks for native services.
- Native: manual verification (capture, OCR accuracy, permissions, Retina/non-Retina,
  single/multi-monitor, several macOS versions).
- Privacy: checklist verification before release.

## Principles
Local-first · privacy-focused · minimal native code · type-safe bridge · testable
abstractions · clear separation of concerns · decisions documented here.