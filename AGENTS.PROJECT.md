# AGENTS.PROJECT.md — Veliq

## Project
macOS + iOS, open-source utility (personal use + GitHub portfolio). macOS is the
mature target; the iOS port (P7-P9) is in progress and is not yet device-verified.
Flow: select a screen region (macOS) or pick/take a photo (iOS) -> local capture
-> local OCR (Apple Vision) -> translate extracted TEXT to Persian -> compact result UI.
Local-first. No backend, no account, no analytics, no payments.

## Stack
Flutter/Dart (macOS + iOS) · State: BLoC · Native: Swift (macos/, ios/) · Bridge: Pigeon

## Folders
lib/core/  lib/features/{capture,ocr,translation,history,settings}/
lib/services/  lib/models/  lib/pigeon/  macos/ (Swift)  ios/ (Swift)
assets/app_icon/ (icon master + generator script)  test/ (mirrors lib/)

## Commands
- Format:  dart format <file>   (never `dart format lib` — it reflows lib/pigeon/messages.g.dart and breaks the CI drift check)
- Analyze: flutter analyze <path>
- Test:    flutter test <file>
- Run:     flutter run -d macos   ·   flutter run -d "iPhone 15"
- Build:   flutter build macos --debug   ·   flutter build ios --no-codesign

## Source of truth (when files disagree, higher wins)
1 CURRENT_TASK.md  2 TASKS.md  3 docs/ARCHITECTURE.md  4 PROJECT_SPEC.md
5 docs/PRIVACY.md  6 docs/MACOS_PERMISSIONS.md  7 docs/RELEASE.md  8 README.md

## Native boundary
- Dart: UI, state, orchestration, settings, history, models, service abstractions.
- Swift: screen capture, Vision OCR, macOS permissions, native shortcut/event code.
- Keep the native boundary small and explicit. Do not write Swift unless the task says so.

## Privacy rules (details: docs/PRIVACY.md)
- Never commit secrets/API keys. Never log screenshots, full OCR text, or keys.
- Send only extracted text to translation providers, never screenshots.
- Prefer local OCR. No analytics/tracking/login/cloud/backend without approval.
- Local history must be user-deletable.

## Project rules
- One task at a time. Do not start future tasks even if they look easy.
- Do not build deferred features without an explicit task.
- Never invent macOS/Flutter APIs, package features or test results.
  If unverified, write "UNVERIFIED".
- Language: code, comments, file names, commit messages in English.

## Stop and ask (do not guess) when
- a macOS permission behaves unexpectedly
- Retina / multi-display coordinates are inconsistent
- a native API or package behavior is unclear
- a build/signing failure cannot be explained

## Commits
One focused commit per task, e.g. `feat: add Vision OCR service`, `fix: ...`,
`test: ...`, `docs: ...`. Format + analyze + task verification before committing.
