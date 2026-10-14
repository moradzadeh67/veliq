# PROJECT_SPEC.md — Veliq

## Goal
Select any region of the screen (macOS) or pick a photo (iOS), extract its text locally,
translate it to Persian, and show the result in a small, fast UI.

## Users
Primarily the author. Secondarily GitHub users who want a local-first screen/photo translator.

## MVP (must have)
1. Trigger capture (button first; global shortcut later). On iOS: pick from the photo
   library or take a photo (no region selection is possible).
2. Selection overlay to choose a screen region (Retina + multi-display correct).
3. Local capture of that region.
4. Local OCR with Apple Vision.
5. Translate extracted text to Persian (provider chosen in a research task).
6. Compact result panel (copy text, RTL-correct Persian display).
7. Clear handling of missing Screen Recording permission.

## Post-MVP (deferred, needs explicit task)
- Global shortcut, translation history (user-deletable), settings screen,
  dictionary-style lookup, source language selection, other target languages.

## Out of scope
Windows/Linux/Android, accounts, cloud sync, analytics, backend, payments,
saving screenshots permanently.

## Constraints
- macOS 14.6+ and iOS; Flutter + Swift; open source; GitHub distribution first.
- Do not design around App Store submission, but do not block it.
- Privacy rules: docs/PRIVACY.md. Permissions: docs/MACOS_PERMISSIONS.md.

## MVP acceptance (done when)
- Capture -> OCR -> Persian translation works on a Retina display and on a second display.
- Denied permission shows a clear error, no crash, retry works.
- No screenshot stored on disk; no secrets in repo.

## iOS scope (P7-P9, in progress)
iOS was added as a second target after the macOS MVP shipped.
- **Image acquisition**: photo library via `PHPickerViewController` (out-of-process, no
  permission) and camera via `UIImagePickerController` (`NSCameraUsageDescription` only).
  There is no region selection — iOS has no ScreenCaptureKit equivalent for third-party apps.
- **UI**: bottom `NavigationBar` instead of the macOS `NavigationRail`, with `SafeArea`
  handling and a wrapping button row for narrow screens (T-122, T-123).
- **Storage**: history lives in the app's Application Support directory via `path_provider`
  (`getApplicationSupportDirectory()`, T-120/T-121).
- **Status**: T-110..T-117 and T-119..T-123 DONE; T-118 (physical iPhone) DROPPED — no device
  in scope, its scenarios folded into T-124; T-124 (simulator review) mostly verified 2026-10-14
  (gallery picker works after T-127; short remainder checklist open); T-126 (iOS 16.0 floor
  + real bundle id `com.moradzadeh67.veliq`) and T-127 (picker fix) DONE.
