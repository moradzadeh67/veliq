# TASKS.md
Legend: [S] Qwen 4B can do it · [L] needs a strong model
Status: TODO | DOING | DONE | BLOCKED

## Phases
P0 Scaffold ................ DONE
P1 Research & decisions .... DONE
P2 Capture MVP ............. DONE
P3 OCR ..................... DONE
P4 Translation ............. DONE
P5 History & settings ...... DONE
P6 Polish & release ........ DOING (T-063 open)

## P0 — Scaffold (current)
Folders, .gitkeep and feature placeholder files are created by the setup script (not a task).

### T-001 · [S] Replace lib/main.dart with a clean placeholder
- Files: lib/main.dart
- Do: see CURRENT_TASK.md (exact code is given there)
- Done when: `flutter analyze lib/main.dart` clean
- Status: DONE

### T-002 · [S] Replace the default widget test
- Files: test/widget_test.dart
- Do: Replace the ENTIRE content with this code, copied EXACTLY:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/main.dart';

void main() {
  testWidgets('Veliq app shows placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const VeliqApp());
    expect(find.text('Veliq - Ready for development'), findsOneWidget);
  });
}
```
- Don't: Do not change lib/main.dart or pubspec.yaml. No new packages.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/main.dart
- Done when: `flutter test test/widget_test.dart` passes + `flutter analyze` clean
- Status: DONE

## P1 — Research & decisions (all [L]; not started)
Each task ends with: findings written to docs/ARCHITECTURE.md (decision table) and
marked VERIFIED or UNVERIFIED. No production code.

### T-010 · [L] Choose screen capture API
- Do: Verify with authoritative Apple docs + a small local test whether
      CGWindowListCreateImage is still usable on target macOS versions, or whether
      ScreenCaptureKit is required. Define Retina / multi-display coordinate rules.
- Done when: D-003 in ARCHITECTURE.md is decided, with a reproducible test note.
- Status: DONE

### T-011 · [L] Choose global shortcut approach
- Do: Compare native API vs maintained Flutter plugin; test foreground/background,
      conflicts, sleep/wake, and whether Accessibility permission is needed.
- Done when: D-004 decided; docs/MACOS_PERMISSIONS.md updated.
- Status: DEFERRED

### T-012 · [L] Choose translation provider
- Do: Pick provider(s) for text-only translation to Persian; document cost, limits,
      privacy policy, and how API keys are stored.
- Done when: D-005 decided; docs/PRIVACY.md updated.
- Status: DONE

### T-013 · [L] Choose local storage for history/settings
- Do: Evaluate maintained options for macOS desktop; pick one.
- Done when: D-006 decided.
- Status: DONE

### T-014 · [L] Pigeon bridge proof of concept
- Do: Minimal Pigeon API (one ping method) Dart <-> Swift on macOS, working end to end.
- Done when: `flutter run -d macos` shows the round trip; setup steps written down.
- Status: DONE

## Phase handover
After P1: Architect writes docs/HANDOVER_P1.md and splits P2 into [S]/[L] tasks. (DONE)

## P2 — Capture MVP (current)

### T-020 · [S] Capture Service Interface & Pigeon API
- Files: pigeons/messages.dart, lib/services/capture_service.dart, lib/services/pigeon_capture_service.dart, test/services/capture_service_test.dart
- Do: Define CaptureRect & ScreenCaptureApi in pigeons/messages.dart, generate Dart/Swift pigeon outputs, create CaptureService interface & Pigeon implementation in Dart, write unit test.
- Done when: `dart run pigeon --input pigeons/messages.dart` succeeds, `flutter analyze` clean, `flutter test` passes.
- Status: DONE

### T-021 · [L] Selection Overlay UI
- Files: lib/features/capture/selection_overlay.dart, test/features/capture/selection_overlay_test.dart
- Do: Implement full-screen transparent selection overlay in Flutter (mouse drag to select region).
- Status: DONE

### T-022 · [S] Native ScreenCaptureKit Handler
- Files: macos/Runner/MainFlutterWindow.swift
- Do: Implement ScreenCaptureApi in Swift using ScreenCaptureKit for region screenshot.
- Status: DONE

## P3 — OCR (current)

### T-030 · [S] OCR Service Interface & Pigeon Definition
- Files: pigeons/messages.dart, lib/services/ocr_service.dart, lib/services/pigeon_ocr_service.dart, test/services/ocr_service_test.dart
- Do: Define OcrApi in pigeons/messages.dart, generate Pigeon outputs, create OcrService interface and PigeonOcrService in Dart, write unit test.
- Done when: `dart run pigeon --input pigeons/messages.dart` succeeds, `flutter analyze` clean, `flutter test` passes.
- Status: DONE

### T-031 · [S] Native Vision OCR Handler
- Files: macos/Runner/MainFlutterWindow.swift
- Do: Implement OcrApi in Swift using Apple Vision framework (VNRecognizeTextRequest).
- Status: DONE

### T-032 · [L] OCR BLoC & State Integration
- Files: lib/features/ocr/bloc/ocr_state.dart, lib/features/ocr/bloc/ocr_bloc.dart, test/features/ocr/bloc/ocr_bloc_test.dart
- Do: Implement OCR BLoC/state management for handling image-to-text workflow and states.
- Status: DONE

## P4 — Translation (current)

### T-040 · [S] Translation Service Interface & Pigeon Definition
- Files: pigeons/messages.dart, lib/services/translation_service.dart, lib/services/pigeon_translation_service.dart, test/services/translation_service_test.dart
- Do: Define TranslationApi in pigeons/messages.dart, generate Pigeon outputs, create TranslationService interface and PigeonTranslationService in Dart, write unit test.
- Done when: `dart run pigeon --input pigeons/messages.dart` succeeds, `flutter analyze` clean, `flutter test` passes.
- Status: DONE

### T-041 · [S] Native Apple Translation Handler
- Files: macos/Runner/MainFlutterWindow.swift
- Do: Implement TranslationApi in Swift using Apple Translation framework.
- Note: Programmatic TranslationSession is macOS 26.0+ only; guarded with #available, returns nil on older systems. Verified via `flutter build macos`.
- Status: DONE

### T-042 · [L] Translation BLoC & State Integration
- Files: lib/features/translation/bloc/translation_state.dart, lib/features/translation/bloc/translation_bloc.dart, test/features/translation/bloc/translation_bloc_test.dart
- Do: Implement Translation BLoC/state management for handling text translation workflow.
- Status: DONE

## P5 — History & settings (current)

### T-050 · [S] History Model & Repository
- Files: lib/models/translation_entry.dart, lib/services/history_repository.dart, lib/services/json_history_repository.dart, test/services/json_history_repository_test.dart
- Do: Define the `TranslationEntry` model (id, originalText, translatedText, sourceLanguage, targetLanguage, createdAt), an abstract `HistoryRepository` interface (load/add/clear/delete), and a local JSON-file implementation in Application Support. Write unit tests using a temp directory.
- Done when: `flutter analyze` clean, `flutter test` passes.
- Status: DONE

### T-051 · [S] Settings Repository
- Files: lib/services/settings_repository.dart, lib/services/prefs_settings_repository.dart, test/services/prefs_settings_repository_test.dart
- Do: Define `SettingsRepository` (source/target language, save-screenshots flag) and a `shared_preferences`-backed implementation with unit tests.
- Status: DONE

### T-052 · [L] History & Settings BLoC + UI
- Files: lib/features/history/bloc/history_state.dart, lib/features/history/bloc/history_bloc.dart, lib/features/history/history_view.dart, lib/features/settings/bloc/settings_state.dart, lib/features/settings/bloc/settings_bloc.dart, lib/features/settings/settings_view.dart, lib/features/home/home_shell.dart, lib/main.dart (+ tests)
- Do: Implement history/settings BLoCs and their UI (list, delete, clear-all, language pickers). Wire all three screens into a NavigationRail shell.
- Note: state base classes are `sealed` so UI can switch exhaustively; `shared_preferences` added in T-051.
- Status: DONE

## P6 — Polish & release (current)

Gap identified: `PigeonCaptureService`, `PigeonOcrService`, `PigeonTranslationService`, `OcrBloc` and
`TranslationBloc` all exist and are unit-tested, but are never instantiated outside `test/`. The
capture -> OCR -> translate -> history pipeline has no orchestration and no UI (the Translate tab is
still `TranslatePlaceholder`). T-060/T-061 close that gap.

### T-060 · [L] Translate Flow BLoC (pipeline orchestration)
- Files: lib/features/translation/bloc/translate_flow_state.dart, lib/features/translation/bloc/translate_flow_bloc.dart, test/features/translation/bloc/translate_flow_bloc_test.dart
- Ctx: lib/services/{capture,ocr,translation}_service.dart, lib/services/history_repository.dart, lib/services/settings_repository.dart, lib/features/ocr/bloc/ocr_bloc.dart, lib/features/translation/bloc/translation_bloc.dart, lib/models/translation_entry.dart
- Do: Orchestrate the full pipeline: capture region -> OCR -> translate (using persisted source/target languages) -> save a `TranslationEntry` to history. Reuse the existing `OcrBloc`/`TranslationBloc` instead of duplicating their logic. Emit a distinct processing step per stage. Unit test with fakes.
- Done when: `flutter test test/features/translation/bloc/translate_flow_bloc_test.dart` and `flutter analyze` pass.
- Status: DONE

### T-061 · [L] Translate View UI (overlay + result + error states)
- Files: lib/features/translation/translate_view.dart, lib/main.dart, lib/features/home/home_shell.dart (+ test)
- Do: Replace `TranslatePlaceholder` with a real view: a "Select region" action that opens `RegionSelectionOverlay` full-screen, runs the pipeline, then shows the original and translated text with copy support. Handle Screen Recording denial and "no text found" with clear, actionable messages.
- Status: DONE

### T-062 · [S] Permission UX & release documentation
- Files: README.md, docs/MACOS_PERMISSIONS.md, docs/RELEASE.md
- Do: Document required macOS permissions and the first-run flow in README; record the capture-coordinate limitation discovered in T-061; run the release-hygiene checklist.
- Status: DONE

### T-063 · [L] Retina & multi-display capture coordinates
- Files: macos/Runner/MainFlutterWindow.swift, macos/Runner/*.swift (coordinate helpers), test/ (Dart-side tests if the conversion is mirrored)
- Ctx: docs/MACOS_PERMISSIONS.md ("Current implementation status: INCOMPLETE"), PROJECT_SPEC.md MVP acceptance
- Do: Convert the Flutter logical-pixel selection rect into the correct ScreenCaptureKit coordinate space before capture:
  1. Pick the display containing the selection instead of always `displays.first`.
  2. Convert logical points to that display's backing-store pixels (`backingScaleFactor`).
  3. Apply the display's origin offset so secondary/negative-origin displays capture correctly.
  4. Account for the origin difference: Flutter's `Rect` is top-left based, ScreenCaptureKit's `sourceRect` is display-local and bottom-left based.
- Done when: Verified manually on (a) a Retina display and (b) a second display with a non-zero/negative origin, plus `flutter test` and `flutter analyze` still pass.
- Blocker note: this task requires the user's physical hardware for the final manual verification step; do not mark DONE from code inspection alone.
- Status: TODO