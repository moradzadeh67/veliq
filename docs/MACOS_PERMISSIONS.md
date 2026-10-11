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

### Current implementation status: INCOMPLETE (verified by code review)
`ScreenCaptureHandler.captureRegion` in `macos/Runner/MainFlutterWindow.swift`
currently maps the Flutter selection rectangle straight onto
`SCStreamConfiguration.sourceRect` with no conversion:

- **No Retina scaling.** On a 2x display the requested logical rect is applied to a
  backing-store coordinate space, so the captured region is offset and smaller than
  the region the user drew.
- **No display selection.** The handler always uses `content.displays.first` and
  ignores which display the selection was made on. Selecting on a secondary display
  captures from the primary display instead.
- **No multi-display origin handling.** Display origins (including negative
  coordinates for displays arranged left of / above the main one) are not applied.

Consequence: the app is usable only on a single, non-Retina-scaled display until
this is fixed. The PROJECT_SPEC.md MVP acceptance criteria ("works on a Retina display
and on a second display") are **not yet met**. Tracking task: T-063.

Do not treat this as a permission problem when reproducing; the failure looks like an
off-by-region capture, not a denial.

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
