# CURRENT_TASK.md

### P6 — Polish & release (T-060, T-061, T-062 DONE)

The core gap that P5 left behind is now closed: the capture -> OCR -> translate
-> history pipeline is wired end to end and reachable from the UI.

- **T-060 DONE** — `TranslateFlowBloc` orchestrates the pipeline, delegating OCR
  and translation to the existing `OcrBloc`/`TranslationBloc`.
- **T-061 DONE** — `TranslateView` replaces `TranslatePlaceholder`: region
  selection, staged progress, result view with RTL translation + copy, and
  actionable failure states.
- **T-062 DONE** — README rewritten (permissions, macOS 26 caveat, usage),
  permission + release docs updated, release-hygiene checklist executed.

### Next: T-063 · [L] Retina & multi-display capture coordinates
- Status: TODO — **requires the user's hardware to verify**
- Blocking a real MVP: `ScreenCaptureHandler` maps the Flutter selection rect
  straight onto `SCStreamConfiguration.sourceRect` with no Retina scaling, no
  display selection, and no multi-display origin offset. On any Retina Mac the
  captured region is offset and smaller than what the user drew.
- Details: docs/MACOS_PERMISSIONS.md -> "Current implementation status: INCOMPLETE"

### Also outstanding
- Release hygiene item 8 (verify permissions on a clean machine / separate user account).
- `D-004` (global shortcut) still OPEN/DEFERRED.
- No git commit made — all git operations are the user's.