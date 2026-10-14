# TASKS.md
Legend: [S] small local model ok · [L] needs a strong model
Status: TODO | DOING | DONE | BLOCKED | DEFERRED | DROPPED

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
P10 Branding & icons ....... DONE
P11 Keyboard affordances .... DOING

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
- Status: DROPPED (2026-10-14) — no physical iPhone in scope; only the simulator and this MacBook are available. The scenarios are folded into T-124 wherever the simulator allows; an actual camera capture is the only device-only check.

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
- Status: DONE (2026-10-12) — Wrapped Scaffold body in SafeArea(top: false, ...). _IdleState button Row → Wrap(alignment: center, spacing: 12, runSpacing: 8) for narrow iPhones. macOS behavior unchanged. Verified: analyze clean, 181/181 tests pass, flutter build ios succeeds.

### T-124 · [L] Manual review on iOS simulator
- Files: (none — manual task)
- Do: Run the app on an iPhone simulator (`flutter run -d "iPhone 17 Pro Max"`) and verify: navigation bar at the bottom; the three main screens work; the RTL Persian result displays correctly; picking a photo from the gallery works; cancelling the picker returns cleanly; a revoked camera permission surfaces a clear message (toggle with `xcrun simctl privacy booted revoke camera com.moradzadeh67.veliq` / `grant`); history persists across an app restart. Absorbs T-118's scenarios where the simulator allows — the simulator has no camera, so an actual photo capture stays device-only (out of scope, no device).
- Done when: all checks pass on simulator.
- Status: TODO — progress 2026-10-14: navigation bar, the three screens, Settings (API key + connect) and the gallery picker verified working by the user on the iPhone 17 Pro Max simulator (after T-127). Remaining: cancel path, revoked-permission message, history persistence across restart.

### T-126 · [S] Apply D-013: iOS deployment target 16.0 + real bundle id
- Files: ios/Runner.xcodeproj/project.pbxproj, ios/Podfile
- Do: Set IPHONEOS_DEPLOYMENT_TARGET to 16.0 in all three configs, replace the template bundle id com.example.veliq (app + RunnerTests) with com.moradzadeh67.veliq, uncomment `platform :ios, '16.0'` in ios/Podfile.
- Done when: `flutter build ios --no-codesign` succeeds.
- Status: DONE (2026-10-14) — build log now reads "Building com.moradzadeh67.veliq"; pod install ran with the new platform. Verified: analyze clean, 181/181 tests.

### T-127 · [M] Fix iOS gallery/camera pickers (tap did nothing)
- Files: ios/Runner/AppDelegate.swift, ios/Runner/ImageSourceHandler.swift, lib/main.dart
- Do: Two independent locks: (1) with the scene-based lifecycle self.window is nil when the engine starts, so the handler held an orphan UIViewController and present() showed nothing — resolve the host view controller lazily at call time; (2) main.dart never passed imageSourceService to TranslateFlowBloc, so the bloc's null-guard turned both buttons into silent no-ops — wire PigeonImageSourceService.
- Done when: tapping Pick image on the simulator opens PHPicker; analyze + tests pass.
- Status: DONE (2026-10-14) — user verified the gallery flow works on the simulator. Verified: analyze clean, 181/181 tests, flutter build ios --simulator succeeds. Take photo stays meaningless on the simulator (no camera hardware).

---

## P10 — Branding & icons (DONE)

### T-125 · [S] Real macOS and iOS app icons
- Files: assets/app_icon/source/{icon_master.png,generate_icons.sh,README.md}, assets/app_icon/veliq.icns, macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png, ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
- Do: Generate every required icon size from the Concept B master. macOS keeps a transparent surround; iOS is flattened onto #2B1F5C with no alpha channel.
- Done when: flutter analyze lib/ clean, flutter test passes, flutter build macos --debug and flutter build ios --no-codesign succeed.
- Status: DONE (2026-10-12) — 7 macOS + 15 iOS PNGs regenerated in place; file names were kept, so neither Contents.json needed an edit (both are byte-identical to before, confirmed with git status). Pipeline: key the master's black surround out → crop the ~1% empty margin → Lanczos resize → flatten for iOS. Also fixed a dark edge halo (a 256 px edge pixel was #0f0d38 at 42% alpha, now #2b15b5 at 100%). Source of truth: assets/app_icon/source/. Verified: analyze clean, 181/181 tests, both builds pass. Committed as c1ca1cd (source + script) and 3fdf23d (regenerated PNGs); pushed to origin/main. **Reworked by T-128 on 2026-10-14** — the raster master pipeline is gone, see D-015.

### T-128 · [M] Branding redesign: SVG master + full asset set (D-015 rework)
- Files: assets/branding/* (new), assets/app_icon/source/{generate_icons.sh,README.md}, assets/app_icon/source/icon_master.png (deleted), assets/app_icon/veliq.icns, macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png, ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png, .gitignore
- Do: Replace the raster master pipeline with the user-approved 4-line vector design: assets/branding/logo.svg becomes the single source of truth; generate_icons.sh renders every size with rsvg-convert (macOS keeps the squircle clip → transparent surround; iOS strips the clip → full-bleed opaque, no alpha). Deliver the branding set (logo-1024.png, social-preview.png, readme-banner.png, favicon.ico, github-avatar.png, about-logo.png). Drop the stale .gitignore line for the deliberately tracked .icns.
- Done when: script regenerates all icons byte-stable; both Contents.json untouched; user approves the design.
- Status: DONE (2026-10-14) — executed by a second agent with user design approval (two-phase preview → final). 7 macOS + 15 iOS PNGs + veliq.icns + 7 branding assets; D-015 updated (REWORKED); re-run of generate_icons.sh exits 0 with no new diffs (reproducible). The stale .gitignore line for assets/app_icon/veliq.icns was removed — the .icns stays deliberately tracked as the distributable artifact. Follow-up (same day): assets/branding/generate_branding.py + assets/branding/README.md committed to the repo (the branding pipeline now lives in-repo, no /tmp dependency; byte-identical outputs verified), and the readme banner was linked at the top of README.md.

---

## P11 — Keyboard affordances (macOS) (DOING)

### T-129 · [M] In-app keyboard shortcuts
- Files: lib/features/home/home_shell.dart, lib/features/translation/translate_view.dart, lib/features/settings/ (save flow), matching tests
- Do: Flutter Shortcuts/Actions (no packages): Cmd+1/2/3 switch tabs; Cmd+R starts capture (macOS region selection, iOS gallery picker); Esc on the result/failure screen = Start over; Enter in the Settings API-key field = Save & test; Cmd+C on the result screen copies the translation. Existing Esc-cancel of the selection overlay stays as is.
- Done when: flutter analyze clean and the new widget tests pass alongside the existing suite.
- Status: DONE (2026-10-14) — implemented with CallbackShortcuts + Focus(autofocus) (no packages); state-guarded Cmd+R/Esc/Cmd+C in TranslateView, Cmd+1/2/3 in HomeShell, Enter-to-save-and-test in the settings key field. flutter analyze clean, 187/187 tests pass. Verified live on the macOS build (Cmd+2 switched to History; raw Cmd+R/Cmd+C/digit key events confirmed reaching the framework).

### T-130 · [L] System-wide capture hotkey (closes D-004 / T-011)
- Files: macos/Runner (RegisterEventHotKey), pigeons/messages.dart, lib wiring
- Do: Register a system-wide hotkey with RegisterEventHotKey (no Accessibility permission required, unlike global monitors). Open decisions: default key combo (Option+Space vs Cmd+Shift+V) and behavior when the app is not running (launch straight into capture vs bring to front).
- Done when: pressing the hotkey anywhere on macOS starts the region selection; user verifies on the MacBook.
- Status: TODO — blocked on the two open decisions (user input needed)