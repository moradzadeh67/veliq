# CURRENT_TASK.md

### T-119 · [S] Route iOS retry and re-select buttons to gallery picker

- Files:
  lib/features/translation/translate_view.dart
  test/features/translation/translate_view_test.dart

- Background:
  T-117 added iOS "Pick image" / "Take photo" buttons on the idle screen.
  But two other buttons still call the macOS-only native region selector:
  (a) TranslateFlowFailure state — "Try again" button
  (b) _ResultState (success state) — "Select another region" button
  On iOS these would try to open the native macOS overlay, which does not
  exist on iOS. Fix this by routing them to the gallery picker on iOS.

- Do:
  1. Read lib/features/translation/translate_view.dart first.
  2. Find the widget that renders the "Try again" action inside the
     TranslateFlowFailure case.
  3. Find the widget that renders the "Select another region" action
     inside the _ResultState case.
  4. For both, wrap the onPressed callback so that:
     if (defaultTargetPlatform == TargetPlatform.iOS) → call _pickFromGallery()
     else → call _startSelection() (existing behavior, unchanged)
     Use the SAME _pickFromGallery() method that T-117 already added.
  5. In test/features/translation/translate_view_test.dart, add two widget
     tests using the existing iOS-only group pattern from T-117:
    - On failure state on iOS, tapping "Try again" calls the fake gallery
      image service.
    - On result state on iOS, tapping "Select another region" calls the
      fake gallery image service.
      Reuse the _FakeImageSourceService from T-117.

- Don't:
  - Do NOT change macOS behavior.
  - Do NOT touch the "Take photo" button.
  - Do NOT add new services or packages.
  - Do NOT modify translate_flow_bloc.dart.
  - Do NOT touch TASKS.md.

- Ctx: AGENTS.md, AGENTS.PROJECT.md,
  lib/features/translation/translate_view.dart,
  test/features/translation/translate_view_test.dart

- Done when:
  - flutter analyze lib/features/translation test/features/translation is clean
  - flutter test test/features/translation passes
  - flutter test passes (full suite)

- Status: TODO