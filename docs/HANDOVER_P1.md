# Phase 1 Handover — Veliq

> **Historical document.** This is the point-in-time handover written at the end of Phase 1 (P1).
> It is kept for provenance and is deliberately **not** maintained — do not treat it as current.
> For the current state use [TASKS.md](../TASKS.md) and [docs/ARCHITECTURE.md](ARCHITECTURE.md).
>
> **Status as of 2026-10-12:** P0-P8 are DONE, P9 (iOS UI & storage) is in progress, P10
> (branding & icons) is DONE. Decisions **D-009..D-015** were added after this document was
> written (API key storage in the Keychain, iOS image sources, iOS minimum target, Pigeon image
> bytes, app icons). The history file path is now resolved with `path_provider`
> (`getApplicationSupportDirectory()`, T-121) instead of a hard-coded default.

## Completed Research & Decisions (P1)
- **D-001 (State Management)**: BLoC
- **D-002 (Bridge)**: Pigeon (verified via T-014 PoC)
- **D-003 (Capture API)**: ScreenCaptureKit (`SCScreenshotManager`) for macOS 14+
- **D-004 (Global Shortcut)**: DEFERRED (T-011)
- **D-005 (Translation)**: CHANGED after P5 — Gemini API via `GeminiTranslationService` (text only); Apple Translation kept as on-device option (macOS 26+). See ARCHITECTURE.md.
- **D-006 (Local Storage)**: `shared_preferences` for settings; JSON file (`JsonHistoryRepository`) for history. (Earlier text said SQLite; the implemented choice is JSON.)
- **D-007 (OCR)**: Apple Vision (`VNRecognizeTextRequest`, local)
- **D-008 (IDE)**: Android Studio / Xcode

## Phase 2 Plan (Capture MVP)
1. **T-020 · [S] Capture Service Interface & Platform Bridge**: Define Dart abstract interface `CaptureService` and connect via Pigeon to Swift native ScreenCaptureKit implementation.
2. **T-021 · [L] Selection Overlay UI**: Implement full-screen transparent selection overlay in Flutter (mouse drag to select screen region).
3. **T-022 · [S] Capture Flow Integration**: Wire selection region coordinates -> Swift capture -> image data return.
