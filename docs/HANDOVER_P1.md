# Phase 1 Handover — Veliq

## Completed Research & Decisions (P1)
- **D-001 (State Management)**: BLoC
- **D-002 (Bridge)**: Pigeon (verified via T-014 PoC)
- **D-003 (Capture API)**: ScreenCaptureKit (`SCScreenshotManager`) for macOS 14+
- **D-004 (Global Shortcut)**: DEFERRED (T-011)
- **D-005 (Translation)**: Apple Translation framework (on-device, macOS 15+) via `TranslationService` abstraction
- **D-006 (Local Storage)**: `shared_preferences` for settings; SQLite / local files for history
- **D-007 (OCR)**: Apple Vision (`VNRecognizeTextRequest`, local)
- **D-008 (IDE)**: Android Studio / Xcode

## Phase 2 Plan (Capture MVP)
1. **T-020 · [S] Capture Service Interface & Platform Bridge**: Define Dart abstract interface `CaptureService` and connect via Pigeon to Swift native ScreenCaptureKit implementation.
2. **T-021 · [L] Selection Overlay UI**: Implement full-screen transparent selection overlay in Flutter (mouse drag to select screen region).
3. **T-022 · [S] Capture Flow Integration**: Wire selection region coordinates -> Swift capture -> image data return.
