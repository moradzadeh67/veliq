# Veliq — macOS Permissions

## Purpose
Records macOS permissions Veliq may require and how to handle them.
Exact requirements depend on the native APIs and shortcut mechanism finally chosen.
Do not claim a permission is required until implementation or authoritative documentation confirms it.

## Screen Recording
The core capture workflow is expected to need Screen Recording permission.
The app should:
- detect whether capture is permitted
- explain why permission is needed
- avoid unexplained blank/error results
- handle denial gracefully
- guide the user on how to grant permission
The exact System Settings path must be verified on the target macOS version before release docs are final.

## Accessibility
NOT assumed. It may be needed depending on how Veliq implements global shortcuts,
system-wide event monitoring, or synthetic input.
Before requesting it:
1. Identify the exact API/library that requires it.
2. Test behavior without the permission.
3. Request only if technically necessary.
4. Document the reason.
Do not request broad permissions "just in case".

## Global shortcut
A technical decision (see TASKS.md T-011). Candidates: native macOS APIs, a maintained Flutter plugin,
another platform-specific mechanism. Test for: app in foreground, app in background, other apps focused,
conflicting shortcuts, permission requirements, sleep/wake.
Do not finalize permission requirements before this investigation.

## Retina / display coordinates
Capture is not independent of display geometry. Verify:
- Retina scale factors
- logical vs physical pixels
- display origin and negative coordinates
- multiple displays
- selection rectangle conversion
A capture that looks right on one Mac is not proof that conversion is correct.

### Current implementation status: FIXED & VERIFIED on hardware (T-063, 2026-10-11)
`ScreenCaptureHandler.captureRegion` in `macos/Runner/MainFlutterWindow.swift` now performs
the full conversion:

- **Display selection.** The display whose `SCDisplay.frame` contains the selection center is
  used (fallback: first display).
- **Retina scaling.** `sourceRect` (points) is converted to pixels via `pointPixelScale`
  (`SCContentFilter.pointPixelScale` on macOS 14+, `backingScaleFactor` fallback) and applied to
  `SCStreamConfiguration.width`/`height`.
- **Multi-display origin.** The selection arrives in Quartz global top-left coordinates — the
  same space as `SCDisplay.frame` — so the display origin is subtracted directly:
  `localRect = globalRect - display.frame.origin`. (Root cause of the original bug: the code
  flipped `SCDisplay.frame` as if it were AppKit bottom-left. Verified on hardware that it is
  Quartz: the secondary display reported `SCDisplay.frame=(1728, 0, …)` next to
  `NSScreen.frame=(1728, -323, …)`.)

Verified manually on the user's hardware (2026-10-11):

- Retina (built-in, 2x): `838x432 pt -> 1676x864 px`, capture matches the drawn region.
- Second display (origin x=1728): correct `760x126 pt` capture; the pre-fix code clipped the same
  region to an 18 pt sliver.
- `flutter analyze`, `flutter test` (167), and `flutter build macos --debug` all pass.

Not yet verified: displays with negative y-origin (not reproducible in the tested arrangement).
The formula is sign-agnostic, but this remains UNVERIFIED. PROJECT_SPEC.md MVP acceptance for
Retina + second display is met.

## Permission denial UX
- show a clear error state
- explain the required permission
- do not request in a loop
- allow retry after granting
- do not crash

## Testing
Test at least: granted, denied, revoked after being granted, app restart after change,
capture after permission restored.
Prefer a clean machine or a separate macOS user account before a public release.

## Documentation rule
When a native permission is added or removed: update this file, update the relevant
architecture/task docs, add manual verification steps, and mention it in README if users must act.
