# TASKS.md
Legend: [S] small local model ok · [L] needs a strong model
Status: TODO | DOING | DONE | BLOCKED | DEFERRED

## Phases
P0 Scaffold ................ DONE
P1 Research & decisions .... DONE
P2 Capture MVP ............. DONE
P3 OCR ..................... DONE
P4 Translation ............. DONE
P5 History & settings ...... DONE
P6 Polish & release ........ DONE

## P0 — Scaffold
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

## P1 — Research & decisions (all [L])
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

## P2 — Capture MVP

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

## P3 — OCR

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

## P4 — Translation
Note: the provider was later migrated to Gemini (commit 6f4d048) without its own task; D-005 in ARCHITECTURE.md is the current truth (see T-064, T-070).

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

## P5 — History & settings

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
- Verified 2026-10-11 on the user's hardware: Retina 2x (`838x432 pt -> 1676x864 px`) and a second
  display with origin x=1728 (correct 760x126 pt capture; the pre-fix code clipped the same region
  to an 18 pt sliver). Root cause: `SCDisplay.frame` is in the Quartz global top-left space, but the
  code flipped it as if it were AppKit bottom-left. Fix: plain origin subtraction. Negative display
  origins not reproducible in this arrangement, but the formula is sign-agnostic (UNVERIFIED for y<0).
- Status: DONE

### T-064 · [S] Documentation sync after the Gemini migration
- Files: docs/ARCHITECTURE.md (D-005, D-009), HANDOVER_P1.md (D-005, D-006), TASKS.md (headings, new tasks)
- Do: record Gemini as the translation provider, the key-storage decision as OPEN, fix the D-006 inconsistency, remove stale "(current)" labels.
- Status: DONE

### T-065 · [L] Research: where to store the user's Google API key (D-009)
- Do: Confirm in code where the key is stored now. Compare macOS Keychain options for Flutter desktop (maintained plugin vs native Keychain via Pigeon) with authoritative sources; mark UNVERIFIED items; no production code.
- Done when: D-009 is DECIDED or UNVERIFIED with source URLs in docs/ARCHITECTURE.md.
- Status: DONE

### T-066 · [L] Move the Google API key to the Keychain
Needs a strong model (platform security behavior). Decision D-009 in docs/ARCHITECTURE.md.

- Files: pubspec.yaml, lib/services/prefs_settings_repository.dart, lib/services/settings_repository.dart,
  a new small key-store file under lib/services/, and the matching tests.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, the files above, docs/ARCHITECTURE.md (D-009 row only).
- Approval given: add the `flutter_secure_storage` package.
- Do:
    1. Store/read/delete the Google API key through FlutterSecureStorage configured for macOS with
       MacOsOptions(usesDataProtectionKeychain: false).
    2. Do NOT add keychain-access-groups to any .entitlements file. (network.client and app-sandbox stay as they are.)
    3. One-time migration: if an old key exists in shared_preferences, copy it to the Keychain, then delete the old value.
    4. Never log or print the key. Keep it out of toString of settings objects.
    5. Put the key store behind an interface so tests can use a fake in-memory store.
- Don't: no other packages, no Swift changes, no UI changes.
- Done when: `flutter analyze` clean, `flutter test` passes (fake store), and I confirm the manual checks below.
- Manual checks (I do these): (1) save key, restart app, key still works; (2) the app's preferences plist no longer
  contains the key; (3) rebuild and run again, note whether a Keychain password prompt appears (UNVERIFIED);
  (4) `flutter build macos --release` build reads the key; (5) migration from an old stored key works.
- Status: DONE

### T-067 · [L] Privacy notice for Gemini (UI + README + docs/PRIVACY.md)
- Do: Next to the provider choice, say clearly that extracted text (not the screenshot) is sent to Google, and that free-tier content may be used by Google to improve its products (EEA/CH/UK differ). Add the same to README and docs/PRIVACY.md. Re-read https://ai.google.dev/gemini-api/terms first.
- Status: DONE

### T-068 · [S] Neutral fake keys in tests
- Files: test files that use fake keys starting with the real key prefix (settings_bloc_test, settings_view_test, gemini_translation_service_test, prefs_settings_repository_test)
- Do: replace fake keys with a neutral string such as 'test-api-key'; keep behavior. If a test depends on the key shape, stop and report BLOCKED.
- Done when: `flutter test` passes and `git grep -n "AIza"` shows only the UI hint text.
- Status: DONE

### T-069 · [L] Remove the PingApi proof of concept
- Files: pigeons/messages.dart (+ regenerated Dart/Swift outputs, native handler registration)
- Do: remove PingApi everywhere and regenerate Pigeon outputs; app still builds and runs.
- Done when: `dart run pigeon --input pigeons/messages.dart`, `flutter analyze`, `flutter test`, `flutter run -d macos` all fine.
- Status: DONE

### T-070 · [L] Verify Gemini model id and quota claims
- Do: Check with official Google docs that the configured model id is available, and whether the quota numbers in the commit message are current. Do not hard-code quota numbers in UI/README without a source.
- Done when: D-005 notes updated (VERIFIED / UNVERIFIED with URLs).
- Status: DONE (2026-10-12) — D-005 updated: model ids VERIFIED (2.5 family access-limited to prior users → explains the per-run HTTP 404), quota numbers UNVERIFIED (official rate-limits page → AI Studio). Follow-up approved and applied: `defaultModel` → `gemini-3.5-flash-lite`, fallbacks → `gemini-3.8-flash`/`gemini-2.0-flash`, unverified 1500 RPD comment removed (`flutter analyze` clean, 167/167 tests).

### T-071 · [L] Real README and release checklist
- Do: README with description, features, status, build instructions, required permissions, privacy (incl. Gemini note), license. Run the checklist in docs/RELEASE.md (gitleaks on full history, author email, About/Topics).
- Status: DONE (2026-10-12) — README: Status section added, macOS 14.6, AI Studio link, 167 tests, stale T-063 limitation replaced. Checklist items 1-7 PASS (gitleaks full history: no leaks; results table in docs/RELEASE.md). Items left to the user: #8 (clean machine) and GitHub About/Topics.
- ---

## Phases (iOS port)

P7  iOS Research & decisions ..... TODO   (all [L])
P8  iOS Image acquisition ........ TODO   (gallery + camera)
P9  iOS UI & storage adaptation .. TODO
P10 iOS signing & Keychain ....... TODO
P11 iOS polish & release ......... TODO

---

## P7 — iOS Research & decisions
### T-100 · [L] Research: iOS image acquisition strategy
- Status: DONE (2026-10-12) — D-010..D-014 added. Gallery: PHPickerViewController (no permission). Camera: UIImagePickerController (+ NSCameraUsageDescription only). iOS minimum: 16.0. Pigeon: no limitation for 2–5 MB JPEG.

---

## P8 — iOS Image acquisition

Goal: user picks a photo from the gallery or takes a photo with the camera, app runs the same OCR → translate → save pipeline as macOS.

### T-110 · [S] Add iOS Info.plist privacy usage descriptions
- Files: ios/Runner/Info.plist
- Do: Add these keys inside the top-level <dict>:
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Veliq reads text from an image you pick, to translate it. Photos never leave your device.</string>
  <key>NSCameraUsageDescription</key>
  <string>Veliq reads text from a photo you take, to translate it. Photos never leave your device.</string>
- Don't: no other key, no other file, do not reorder existing keys.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, ios/Runner/Info.plist
- Done when: `plutil -lint ios/Runner/Info.plist` prints "OK"
- Status: TODO

### T-111 · [S] Define ImageSourceApi in pigeons/messages.dart
- Files: pigeons/messages.dart
- Do: Add a new @HostApi at top level:
  @HostApi()
  abstract class ImageSourceApi {
  @async
  Uint8List? pickImageFromGallery();
  @async
  Uint8List? takePhotoWithCamera();
  }
- Don't: do not rename or remove any existing class or method.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, pigeons/messages.dart
- Done when: `dart analyze pigeons/messages.dart` has no new errors.
- Status: TODO

### T-112 · [S] Regenerate Pigeon outputs for iOS
- Files: lib/pigeon/messages.g.dart, ios/Runner/Messages.g.swift, macos/Runner/Messages.g.swift (all regenerated)
- Do: Run: `dart run pigeon --input pigeons/messages.dart`
- Don't: do not edit generated files manually.
- Done when:
  `flutter analyze lib/` clean
  `grep -l "ImageSourceApi" lib/pigeon/messages.g.dart ios/Runner/Messages.g.swift macos/Runner/Messages.g.swift` returns all three paths
- Status: TODO

### T-113 · [L] Implement Swift ImageSourceHandler for iOS   ⚠ strong model
- Files:
  ios/Runner/ImageSourceHandler.swift (new — must be added to Runner target in Xcode)
  ios/Runner/AppDelegate.swift (register the handler)
- Do:
  1. Implement ImageSourceApiProtocol (generated by Pigeon) in ImageSourceHandler.swift.
  2. Gallery: present PHPickerViewController with filter = .images, selectionLimit = 1.
     Load UIImage, convert to JPEG (quality 0.9), return as FlutterStandardTypedData.
  3. Camera: present UIImagePickerController with sourceType = .camera, mediaTypes = ["public.image"].
  4. Cancel in either case → return nil.
  5. In AppDelegate.swift register ImageSourceApiSetup.setUp.
- Don't: do not modify any Dart file. Do not touch macos/.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, ios/Runner/AppDelegate.swift, ios/Runner/Messages.g.swift
- Done when: `flutter build ios --no-codesign` succeeds.
- Status: TODO
- Note: adding the new Swift file to Runner target is a MANUAL step in Xcode.

### T-114 · [S] Add ImageSourceService Dart interface
- Files: lib/services/image_source_service.dart (new), lib/services/pigeon_image_source_service.dart (new)
- Do: Wrap ImageSourceApi behind an abstract interface, same pattern as existing services.
- Don't: no other file. Do not modify existing services.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/pigeon/messages.g.dart
- Done when: `scripts/verify.sh lib/services` clean
- Status: TODO

### T-115 · [S] Unit test for PigeonImageSourceService with fake
- Files: test/services/image_source_service_test.dart (new)
- Do: Fake ImageSourceApi returns known bytes; assert delegation.
- Done when: `scripts/verify.sh test/services test/services/image_source_service_test.dart` clean
- Status: TODO

### T-116 · [S] Wire ImageSourceService into TranslateFlowBloc
- Files: lib/features/translation/bloc/translate_flow_bloc.dart, test/features/translation/bloc/translate_flow_bloc_test.dart
- Do: Add ImageSourceService dependency. Add PickImageFromGallery / TakePhoto events that run the same OCR → translate → save pipeline.
- Don't: do not change ocr_bloc.dart or translation_bloc.dart.
- Done when: `scripts/verify.sh lib/features/translation test/features/translation/bloc/translate_flow_bloc_test.dart` clean
- Status: TODO

### T-117 · [S] Add iOS capture buttons in TranslateView
- Files: lib/features/translation/translate_view.dart
- Do: If defaultTargetPlatform == iOS show "Pick image" and "Take photo" buttons. On macOS keep "Select region".
- Don't: do not redesign layout.
- Done when: `scripts/verify.sh lib/features/translation` clean
- Status: TODO

### T-118 · [L] Manual verification on a real iPhone
- Files: (none — manual task)
- Do: run `flutter run -d <device-id>` and verify 5 scenarios (gallery, camera, cancel, denied permission, history persists).
- Done when: all five checks pass on a physical iPhone.
- Status: TODO

