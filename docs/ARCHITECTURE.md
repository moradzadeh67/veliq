# Veliq — Architecture

## Overview
macOS desktop utility: Flutter/Dart for the app layer, Swift/macOS for native integration.
Local-first and privacy-focused: screen content stays on the Mac whenever possible.

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
```
trigger -> selection overlay (Dart) -> region coordinates -> Swift capture
-> image data -> Swift Vision OCR (local) -> extracted text -> Dart
-> translation provider (TEXT ONLY) -> result panel
```
Rules: screenshots stay local; image data released after OCR; only text leaves the Mac;
no analytics. See docs/PRIVACY.md.

## Decisions (append-only; keep IDs stable)
| ID | Topic | Decision | Status |
|---|---|---|---|
| D-001 | State management | BLoC | DECIDED |
| D-002 | Dart<->Swift bridge | Pigeon | DECIDED (verified in T-014) |
| D-003 | Screen capture API | ScreenCaptureKit (SCScreenshotManager); CGWindowListCreateImage is obsoleted in macOS 15 SDK. Minimum macOS 14. Region capture, Retina and multi-display conversion, and macOS 27 behavior are UNVERIFIED | DECIDED (API), UNVERIFIED (details) |
| D-004 | Global shortcut | native API vs maintained Flutter plugin | OPEN, T-011 |
| D-005 | Translation provider | Apple Translation framework (on-device) via `TranslationService` abstraction. Local-first, zero cost, zero API keys, complete privacy. Pluggable interface for alternative text-only providers. NOTE (verified in T-041): the programmatic `TranslationSession(installedSource:target:)` API is only available on macOS 26.0+, so the native handler is `#available(macOS 26.0)`-guarded and returns nil on older systems (Dart side must fall back). | DECIDED (API), UNVERIFIED (fallback UX) |
| D-006 | Local storage (history/settings) | `shared_preferences` (backed by NSUserDefaults) for app settings; JSON file at `~/Library/Application Support/veliq/history.json` for translation history (`JsonHistoryRepository`). Both behind service interfaces; no cloud sync. | DECIDED |
| D-007 | OCR | Apple Vision (VNRecognizeTextRequest), local | DECIDED |
| D-008 | IDE | Android Studio daily; Xcode only for deep Swift/permission/profiling issues | DECIDED |

An OPEN decision must not be implemented until its task is DONE.

## Components
Dart (lib/services, lib/features/*): CaptureService, OcrService, TranslationService
(abstract interfaces); HistoryRepository, SettingsRepository; Pigeon APIs in lib/pigeon.
Swift (macos/Runner): screen capture, Vision OCR, permission manager, shortcut manager (if native).
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
test/          mirrors lib/
docs/  references/  assets/
```
Subfolders inside a feature (e.g. bloc/, view/) are decided when the first feature task needs them.

## Permissions
Screen Recording expected; Accessibility NOT assumed. See docs/MACOS_PERMISSIONS.md.

## Testing
- Dart: unit tests for blocs/services, widget tests for UI, mocks for native services.
- Native: manual verification (capture, OCR accuracy, permissions, Retina/non-Retina,
  single/multi-monitor, several macOS versions).
- Privacy: checklist verification before release.

## Principles
Local-first · privacy-focused · minimal native code · type-safe bridge · testable
abstractions · clear separation of concerns · decisions documented here.
