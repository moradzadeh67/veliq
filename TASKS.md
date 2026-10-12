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
P7 iOS Research ............ DONE
P8 iOS Image acquisition ... DONE
P9 iOS UI & storage ........ DOING

---

## P0 — Scaffold (DONE)

### T-001 · [S] Replace lib/main.dart with a clean placeholder — DONE
### T-002 · [S] Replace the default widget test — DONE

---

## P1 — Research & decisions (DONE)

### T-010 · [L] Choose screen capture API — DONE
### T-011 · [L] Choose global shortcut approach — DEFERRED
### T-012 · [L] Choose translation provider — DONE
### T-013 · [L] Choose local storage for history/settings — DONE
### T-014 · [L] Pigeon bridge proof of concept — DONE

---

## P2 — Capture MVP (DONE)

### T-020 · [S] Capture Service Interface & Pigeon API — DONE
### T-021 · [L] Selection Overlay UI — DONE
### T-022 · [S] Native ScreenCaptureKit Handler — DONE

---

## P3 — OCR (DONE)

### T-030 · [S] OCR Service Interface & Pigeon Definition — DONE
### T-031 · [S] Native Vision OCR Handler — DONE
### T-032 · [L] OCR BLoC & State Integration — DONE

---

## P4 — Translation (DONE)

### T-040 · [S] Translation Service Interface & Pigeon Definition — DONE
### T-041 · [S] Native Apple Translation Handler — DONE
### T-042 · [L] Translation BLoC & State Integration — DONE

---

## P5 — History & settings (DONE)

### T-050 · [S] History Model & Repository — DONE
### T-051 · [S] Settings Repository — DONE
### T-052 · [L] History & Settings BLoC + UI — DONE

---

## P6 — Polish & release (DONE)

### T-060 · [L] Translate Flow BLoC (pipeline orchestration) — DONE
### T-061 · [L] Translate View UI (overlay + result + error states) — DONE
### T-062 · [S] Permission UX & release documentation — DONE
### T-063 · [L] Retina & multi-display capture coordinates — DONE
### T-064 · [S] Documentation sync after the Gemini migration — DONE
### T-065 · [L] Research: where to store the user's Google API key (D-009) — DONE
### T-066 · [L] Move the Google API key to the Keychain — DONE
### T-067 · [L] Privacy notice for Gemini (UI + README + docs/PRIVACY.md) — DONE
### T-068 · [S] Neutral fake keys in tests — DONE
### T-069 · [L] Remove the PingApi proof of concept — DONE
### T-070 · [L] Verify Gemini model id and quota claims — DONE (2026-10-12) — D-005 updated: model ids VERIFIED. Default model → gemini-3.5-flash-lite, fallbacks → gemini-3.8-flash / gemini-2.0-flash. flutter analyze clean, 167/167 tests.
### T-071 · [L] Real README and release checklist — DONE (2026-10-12) — README updated. Checklist items 1-7 PASS. Items left to user: #8 (clean machine) and GitHub About/Topics.

---

## P7 — iOS Research (DONE)

### T-100 · [L] Research: iOS image acquisition strategy — DONE (2026-10-12) — D-010..D-014 added. Gallery: PHPickerViewController (no permission). Camera: UIImagePickerController (+ NSCameraUsageDescription only). iOS minimum: 16.0. Pigeon: no limitation for 2–5 MB JPEG.

---

## P8 — iOS Image acquisition (DONE)

### T-110 · [S] Add iOS Info.plist privacy usage descriptions
- Files: ios/Runner/Info.plist
- Do: Add NSCameraUsageDescription only. (NSPhotoLibraryUsageDescription omitted per D-012 as PHPickerViewController is out-of-process.)
- Done when: plutil -lint ios/Runner/Info.plist prints "OK"
- Status: DONE (2026-10-12)

### T-111 · [S] Define ImageSourceApi in pigeons/messages.dart
- Files: pigeons/messages.dart
- Do: Define ImageSourceApi with pickImageFromGallery and takePhotoWithCamera (@async, returns Uint8List?).
- Done when: dart analyze clean.
- Status: DONE (2026-10-12)

### T-112 · [S] Regenerate Pigeon outputs for iOS
- Files: lib/pigeon/messages.g.dart, macos/Runner/Messages.g.swift, ios/Runner/Messages.g.swift
- Do: Run dart run pigeon --input pigeons/messages.dart, then copy macOS Swift output to iOS path.
- Done when: flutter build ios --no-codesign succeeds.
- Status: DONE (2026-10-12) — iOS Swift was created by copying macOS output. The generated file already contains platform guards (#if os(iOS) import Flutter #elseif os(macOS) import FlutterMacOS), so the same file works on both platforms.

### T-113 · [L] Implement Swift ImageSourceHandler for iOS
- Files: ios/Runner/ImageSourceHandler.swift (new), ios/Runner/AppDelegate.swift
- Do: Implement ImageSourceApi protocol using PHPickerViewController (gallery) and UIImagePickerController (camera). Register in AppDelegate via ImageSourceApiSetup.
- Done when: flutter build ios --no-codesign succeeds.
- Status: DONE (2026-10-12) — Uses async throws protocol with continuation. Registered in AppDelegate.swift via engineBridge.applicationRegistrar.messenger(). Files added to project.pbxproj.

### T-114 · [S] Add ImageSourceService Dart interface
- Files: lib/services/image_source_service.dart (new), lib/services/pigeon_image_source_service.dart (new)
- Do: Abstract interface + Pigeon implementation.
- Done when: flutter analyze lib/services clean.
- Status: DONE (2026-10-12)

### T-115 · [S] Unit test for PigeonImageSourceService with fake
- Files: test/services/image_source_service_test.dart (new)
- Do: Fake ImageSourceApi returns known bytes; assert delegation.
- Done when: flutter test test/services/image_source_service_test.dart passes.
- Status: DONE (2026-10-12) — 4 tests covering success and cancel paths for both gallery and camera. All pass.

### T-116 · [S] Wire ImageSourceService into TranslateFlowBloc
- Files: lib/features/translation/bloc/translate_flow_bloc.dart, test/features/translation/bloc/translate_flow_bloc_test.dart
- Do: Add optional ImageSourceService dependency. Add pickImageFromGallery() / takePhoto() methods that run the same OCR → translate → save pipeline. Cancel emits existing TranslateFlowIdle.
- Done when: flutter test test/features/translation/bloc/translate_flow_bloc_test.dart passes.
- Status: DONE (2026-10-12)

### T-117 · [S] Add iOS capture buttons in TranslateView
- Files: lib/features/translation/translate_view.dart, test/features/translation/translate_view_test.dart
- Do: On iOS show "Pick image" and "Take photo". On macOS keep "Select region".
- Done when: flutter test test/features/translation passes.
- Status: DONE (2026-10-12)

### T-118 · [L] Manual verification on a real iPhone
- Files: (none — manual task)
- Do: Verify 5 scenarios (gallery, camera, cancel, denied permission, history persists) on physical iPhone.
- Done when: all five checks pass on a physical iPhone.
- Status: DEFERRED (2026-10-12) — No physical iPhone available yet. Will resume when a device is available. Code path covered by simulator + unit tests (181/181).

### T-119 · [S] Route iOS retry and re-select buttons to gallery picker
- Files: lib/features/translation/translate_view.dart, test/features/translation/translate_view_test.dart
- Do: The failure-state "Try again" and result-state "Select another region" buttons must use the gallery picker on iOS; keep macOS native region selector.
- Done when: flutter test test/features/translation passes.
- Status: DONE (2026-10-12) — Added _retryOrSelect() helper (iOS → _pickFromGallery(), macOS → _startSelection()). macOS path unchanged. Two iOS widget tests added. Verified: analyze clean, 181/181 tests pass.

---

## P9 — iOS UI & storage adaptation (DOING)

### T-120 · [S] Add path_provider dependency
- Files: pubspec.yaml
- Do: Add path_provider: ^2.1.5 to dependencies.
- Done when: flutter pub get succeeds.
- Status: DONE (2026-10-12) — path_provider promoted from transitive to direct dependency at ^2.1.5 (resolved 2.1.6). Plugin already registered; no other changes needed.

### T-121 · [S] Use getApplicationSupportDirectory for history file path
- Status: DONE (2026-10-12) — main() is now async, uses getApplicationSupportDirectory() from path_provider. defaultHistoryFilePath() deleted. JsonHistoryRepository() without an explicit File throws StateError. Verified: analyze clean, 181/181 tests pass, flutter build ios succeeds.

### T-122 · [S] Responsive navigation for iOS
- Status: DONE (2026-10-12) — Added `bool get _isIOS` instance getter in _HomeShellState. On iOS: Scaffold with NavigationBar at bottom + SafeArea body. On macOS: existing NavigationRail layout unchanged. Verified: analyze clean, 181/181 tests pass, flutter build ios succeeds.

### T-123 · [S] SafeArea + mobile padding
- Files: lib/features/translation/translate_view.dart (and possibly other views)
- Do: Wrap top-level content with SafeArea. Adjust padding for iPhone notch and home indicator.
- Done when: widget tests pass, manual check on simulator.
- Status: TODO

### T-124 · [L] Manual review on iOS simulator
- Files: (none — manual task)
- Do: Run flutter run -d "iPhone 15" and verify: navigation bar at bottom, three main screens work, RTL Persian result displays correctly, history persists across app restart.
- Done when: all checks pass on simulator.
- Status: TODO