# PROJECT_SPEC.md — Veliq

## Goal
Select any region of the screen, extract its text locally, translate it to Persian,
and show the result in a small, fast UI.

## Users
Primarily the author. Secondarily GitHub users who want a local-first screen translator.

## MVP (must have)
1. Trigger capture (button first; global shortcut later).
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
Windows/Linux/mobile, accounts, cloud sync, analytics, backend, payments,
saving screenshots permanently.

## Constraints
- macOS only; Flutter + Swift; open source; GitHub distribution first.
- Do not design around App Store submission, but do not block it.
- Privacy rules: docs/PRIVACY.md. Permissions: docs/MACOS_PERMISSIONS.md.

## MVP acceptance (done when)
- Capture -> OCR -> Persian translation works on a Retina display and on a second display.
- Denied permission shows a clear error, no crash, retry works.
- No screenshot stored on disk; no secrets in repo.
