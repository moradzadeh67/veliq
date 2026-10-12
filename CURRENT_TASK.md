# CURRENT_TASK.md

### P6 — Polish & release (T-060..T-063, T-065..T-070 DONE)

The core gap that P5 left behind is now closed: the capture -> OCR -> translate
-> history pipeline is wired end to end and reachable from the UI.

- **T-060 DONE** — `TranslateFlowBloc` orchestrates the pipeline, delegating OCR
  and translation to the existing `OcrBloc`/`TranslationBloc`.
- **T-061 DONE** — `TranslateView` replaces `TranslatePlaceholder`: region
  selection, staged progress, result view with RTL translation + copy, and
  actionable failure states.
- **T-062 DONE** — README rewritten (permissions, macOS 26 caveat, usage),
  permission + release docs updated, release-hygiene checklist executed.
- **T-063 DONE** — Retina & multi-display capture verified on real hardware
  (2026-10-11): display picked by selection center, `pointPixelScale` applied,
  Quartz top-left origin subtraction (root cause was an AppKit-style flip on a
  Quartz `SCDisplay.frame`). `flutter analyze` + 167 tests + debug build pass.
  Details: TASKS.md T-063, docs/MACOS_PERMISSIONS.md "Current implementation status".
- **T-065 DONE** — D-009 decided (Keychain via `flutter_secure_storage`).
- **T-066 DONE** — API key moved to Keychain with one-time migration.
- **T-067 DONE** — Gemini privacy notice in Settings UI, README, docs/PRIVACY.md.
- **T-068 DONE** — neutral fake keys in tests (`git grep "AIza"` = UI hint only).
- **T-069 DONE** — PingApi removed, Pigeon outputs regenerated.
- **T-070 DONE** — Gemini model ids/quota checked against official docs
  (2026-10-12): `gemini-2.5-flash` exists but the 2.5 family is limited to
  projects that actively used it before → explains the per-run HTTP 404;
  `gemini-3.5-flash-lite` (what the fallback serves) is Google's recommended
  model for new projects; quota numbers UNVERIFIED (official rate-limits page
  has no static RPD table → AI Studio). Details: TASKS.md T-070, D-005.

### Next: open task T-071
- **T-071** [L] Real README and release checklist (docs/RELEASE.md).

### Also outstanding
- Release hygiene item 8 (verify permissions on a clean machine / separate user account).
- `D-004` (global shortcut) still OPEN/DEFERRED.
- No git commit made — all git operations are the user's.
