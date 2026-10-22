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
P12 Android v1 .............. DONE
P13 Public release (GitHub) .. DONE
P14 Android release hotfix ... DONE
P15 Multi-language input .... DONE

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
- Status: TODO — progress 2026-10-14: navigation bar, the three screens, Settings (API key + connect) and the gallery picker verified working by the user on the iPhone 17 Pro Max simulator (after T-127). Remaining: cancel path, revoked-permission message, history persistence across restart. 2026-10-16: still open — the bundled `Simulator.app` on the owner's Mac is broken (binary is unsigned and exits immediately; no Simulator.app exists inside Xcode.app either), so no UI-driven verification is possible on this machine. The owner decided to leave T-124 until a repaired simulator or a physical device is available. 2026-10-16 (later): a headless alternative was investigated — `idb` / `idb-companion` is no longer published in Homebrew (there is no `facebook/fb` tap), and building it from source was judged not worth the effort; the owner decided to record the block in the roadmap and move on.

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

---

## P12 — Android v1: photo input + local OCR (DONE)

Scope approved by the user 2026-10-14 (decision D-016): gallery + camera only -> on-device OCR (ML
Kit) -> Gemini with the user's own key -> existing History/Settings unchanged. Region selection and
screen capture are NOT part of Android v1 (complex and a poor fit for Android's model); Apple
Translation is not available on Android. In Kotlin only `ImageSourceApi` and `OcrApi` are implemented
and registered — `SelectionApi`, `ScreenCaptureApi` and `TranslationApi` are never registered on
Android because no Android UI ever calls them. ML Kit is added in Kotlin/Gradle directly, not as a
Flutter package, so the Dart layer stays untouched. Rules: no API keys / .env changes; never edit
generated Pigeon files by hand (regenerate from pigeons/messages.dart); one task at a time with
analyze/test after each.

### T-131 · [S] Android scaffold
- Files: android/** (new)
- Do: From the repo root run `flutter create --platforms=android .`; verify the applicationId matches the existing bundle id `com.moradzadeh67.veliq`; do not add any new native capability yet.
- Done when: `flutter run -d <android-emulator>` launches the current app UI unchanged.
- Status: DONE (2026-10-22) — stale status corrected in P15; the Android scaffold shipped with P12 (DONE).

### T-132 · [S] Android UI (mobile layout)
- Files: lib/features/home/home_shell.dart, lib/features/translation/translate_view.dart, test/features/home/home_shell_test.dart, test/features/translation/translate_view_test.dart
- Do: Treat Android like iOS (`_isIOS` -> `_isMobile`): bottom `NavigationBar` instead of `NavigationRail`; "Pick image" and "Take photo" buttons; no "Select region" button or text on Android. Cmd/Meta shortcuts stay macOS-only and must not be the only path on Android.
- Done when: existing suite green; new widget test asserts Android shows gallery + camera buttons and hides "Select region"; analyze clean.
- Status: DONE (analyze 0, tests 192/192, APK installed + bottom NavigationBar / Pick image / Take photo verified on emulator-5554; default host-platform tests pinned to macOS via testWidgetsMac variant)

### T-133 · [S] Pigeon Kotlin output
- Files: pigeons/messages.dart, android/app/src/main/kotlin/** (generated)
- Do: Add a `kotlinOut` target under `android/app/src/main/kotlin/...` whose package exactly matches the Android app package; regenerate Pigeon. Do not edit generated files by hand; implement/register only `ImageSourceApi` and `OcrApi` on the Android host. `SelectionApi`, `ScreenCaptureApi` and `TranslationApi` must NOT be registered on Android. Dart and Swift bindings must stay byte-identical.
- Done when: the generated Kotlin file exists, `git diff` on lib/pigeon/messages.g.dart and macos/Runner/Messages.g.swift is empty, analyze + tests green.
- Status: DONE (Messages.g.kt generated, Dart/Swift hashes byte-identical, only ImageSourceApi+OcrApi registered in MainActivity.kt with cancel-safe stubs; analyze 0, tests 192/192, APK on emulator taps Pick image without crash)

### T-134 · [S] Gallery (Android Photo Picker)
- Files: android/app/src/main/kotlin/** (ImageSource handler)
- Do: `pickImageFromGallery()` uses the Android Photo Picker (`ActivityResultContracts.PickVisualMedia`); no broad storage permission may be requested. Cancelling returns null. Returns JPEG bytes.
- Done when: on the emulator the picker opens and returns an image to the existing flow; cancel returns null and the UI goes back to Idle; analyze + tests green.
- Status: DONE (Photo Picker ACTION_PICK_IMAGES/API33+ + ACTION_GET_CONTENT fallback, JPEG bytes via ContentResolver, no storage permission; emulator verified: picker -> image -> flow -> OCR stub "No text found", Try again reopens picker, Back cancels to Idle; analyze 0, tests 192/192)

### T-135 · [M] Camera (CAMERA permission + TakePicture + FileProvider)
- Files: android/app/src/main/kotlin/**, android/app/src/main/AndroidManifest.xml, android/app/src/main/res/xml/file_paths.xml
- Do: `takePhotoWithCamera()` requests the CAMERA runtime permission first; if denied return null so Flutter returns to Idle. Use `ActivityResultContracts.TakePicture` with a temporary file exposed through a FileProvider so the full-quality photo is returned. Cancelling returns null. Declare the camera as optional in the Manifest (`<uses-feature android:name="android.hardware.camera" android:required="false"/>`) so camera-less devices can still install the app.
- Done when: camera flow returns full-quality bytes on a device/emulator with a camera; deny + cancel both return null without a crash; analyze + tests green.
- Status: DONE (CAMERA runtime permission via requestPermissions/onRequestPermissionsResult + suspendCancellableCoroutine; ACTION_IMAGE_CAPTURE + EXTRA_OUTPUT via FileProvider (cache/photos, res/xml/file_paths.xml); Manifest CAMERA permission + uses-feature required=false; emulator verified: deny->Idle, grant->camera->shutter->confirm->bytes->flow->OCR stub; analyze 0, tests 192/192)

### T-136 · [M] On-device OCR (ML Kit, bundled)
- Files: android/app/build.gradle(.kts), android/app/src/main/kotlin/** (Ocr handler)
- Do: Add the bundled ML Kit Latin OCR dependency `com.google.mlkit:text-recognition` to the app module Gradle file; raise minSdk to 23 to match ML Kit. Build an OCR handler that turns JPEG bytes into a `Bitmap`, feeds it through `InputImage` + `TextRecognition.getClient(...)`, returns null for empty text, and converts decode/ML Kit errors into a comprehensible Pigeon error. OCR must not write the image to disk, logs or the network.
- Done when: an English-text image produces recognized text through the existing Dart flow; an image without text returns null (UI shows the existing empty/failure state); analyze + tests green.
- Status: DONE (com.google.mlkit:text-recognition:16.0.1 bundled added to build.gradle.kts; MlKitOcrApi: bytes->Bitmap->InputImage->TextRecognition, null for empty text, readable Pigeon errors, no disk/log/network writes; minSdk already 24 so no change; emulator verified: English image -> text -> translation step ("No API key" as expected), blank image -> "No text found"; analyze 0, tests 192/192)

### T-137 · [S] Gemini-only on Android
- Files: lib/features/settings/settings_view.dart (and settings bloc if needed), matching tests
- Do: On Android show only the Google Gemini provider in Settings (hide or disable the Apple option). If a stored setting still points at Apple, show a clear message that Android supports Gemini only — never crash. The Gemini key stays in `flutter_secure_storage`; never write the key into Gradle, the Manifest, source or logs. Only OCR text is sent to Gemini, never the image.
- Done when: on Android Settings offers Gemini only; a stored Apple selection shows the message and stays usable; analyze + tests green.
- Status: DONE (settings_view.dart: isAndroid -> provider forced to Gemini, dropdown removed on Android, stored-Apple shows "Android supports Google Gemini only" notice with "Use Gemini" fix button; key stays in flutter_secure_storage, only OCR text to Gemini; macOS tests pinned via testWidgetsMac, new Android test group x4; analyze 0, tests 196/196; emulator verified: Gemini-only Settings)

### T-138 · [S] App icon and metadata
- Files: android/app/src/main/res/**
- Do: App name "Veliq"; use the project's existing icon asset for the Android adaptive icon. Do not change `version: 1.0.0+1` in pubspec.yaml unless the project owner asks for a new version.
- Done when: the launcher shows the Veliq icon and the name Veliq on the emulator; pubspec version untouched.
- Status: DONE (adaptive icon from assets/branding/logo.svg: background = brand gradient vector, foreground = artwork-only PNGs at 108/162/216/324/432 fitted to the 66dp safe zone; legacy PNGs regenerated 48-192; strings.xml app_name=Veliq + manifest label; version 1.0.0+1 untouched; macOS-only copy ("this Mac", "Try selecting a region...", "Select another region") made platform-aware with 3 new tests; analyze 0, tests 199/199; emulator drawer + recents show the Veliq icon and the name Veliq)

### T-139 · [S] Acceptance (analyze / test / apk + manual checklist)
- Files: — (verification only)
- Do: `flutter analyze`, `flutter test`, `flutter build apk --debug`. Manual on the emulator: (1) cancel gallery, (2) cancel camera, (3) deny Camera permission, (4) image without text, (5) image with English text, (6) missing Gemini key, (7) successful Gemini translation, (8) history survives an app restart.
- Done when: all three commands green; the checklist is executed on the emulator and the report lists changed files, the three command outputs and what was verified on a device.
- Status: DONE (2026-10-15). Commands green: analyze 0, tests 199/199, apk built and installed. Emulator checklist, all 8 items verified: (1) cancel gallery -> Idle, (2) cancel camera -> Idle, (3) deny camera permission -> app alive + Idle, (4) blank image -> "No text found" + Android guidance, (5) English image -> OCR succeeded, (6) missing key -> "No Google AI API key is configured. Add one in Settings.", (7) after the owner entered the key in Settings ("Connected. The API key works."), a real Gemini translation succeeded: en->fa RTL output + "Saved to history", (8) History entry survived am force-stop + relaunch. (Items 7-8 were first deferred with the owner's note "needs the user's key", then executed on 2026-10-15 once the key was in place.)

---

## P13 — Public release (GitHub) (DONE)

### T-140 · [M] Release prep: signing, CI, SEO site and v1.0.0
- Files: android/app/build.gradle.kts, .github/workflows/ci.yml (new), CONTRIBUTING.md (new), docs/index.html + docs/robots.txt + docs/sitemap.xml + docs/.nojekyll (new), README.md, PROJECT_SPEC.md, docs/RELEASE.md, docs/ARCHITECTURE.md, assets/screenshots/**, assets/demo/demo.gif
- Do: sign Android release builds with a real upload key (keystore outside the repo; `android/key.properties` git-ignored, debug fallback kept); replace the whole-desktop overlay screenshot and rebuild the demo GIF from app-only frames; refresh the README to the reference structure (badges, Release Signing, CI/CD, Development Environment, Requirements) and record the multi-language roadmap; add a CI workflow; add a crawlable landing page for a GitHub Pages site.
- Done when: analyze clean, tests green, signed AAB + APK verified with apksigner, release published.
- Status: DONE (2026-10-16) — keystore `Veliq-upload.jks` created (PKCS12, alias `veliq`, 10000 days) with a complete zipped backup on the owner's Desktop; `apksigner verify --print-certs` → `CN=Mohammadreza Moradzadeh, OU=Mobile, O=Veliq, C=IR`; AAB 66 MB + APK 84 MB built; `flutter analyze` clean, 199/199 tests; GitHub release `v1.0.0` published with `app-release.apk` + `.sha256`; repo description + 16 topics set; GitHub Pages enabled (source `main` `/docs`) with the SEO landing page. macOS history was cleared of the 4 test entries created while capturing media; a stale `Application Support/veliq/history.json` (13 owner entries from Oct 11-12, older build) was found and preserved. History path corrected in README + ARCHITECTURE: it is the bundle-id folder, not `veliq/`.

---

## P14 — Android release hotfix (DONE)

### T-141 · [M] Fix the Android release-build launch crash (R8 obfuscated ML Kit)
- Files: android/app/proguard-rules.pro (new), android/app/build.gradle.kts, android/app/src/main/AndroidManifest.xml, pubspec.yaml
- Do: Two independent release-only defects found after v1.0.0 shipped. (1) **Network**: Flutter only declares `android.permission.INTERNET` in the debug/profile manifests, so release builds could not reach the Gemini API — add it to the main manifest. (2) **Crash**: Android `--release` runs R8 (minify + resource shrinking, full mode) by default, and ML Kit loads its internals reflectively; the consumer rules the AARs ship only keep native method names + proto fields, so R8 stripped/renamed `com.google.mlkit.**` and the app crashed in `MainActivity.configureFlutterEngine()` when creating the recognizer via `TextRecognition.getClient()`. Add `android/app/proguard-rules.pro` with `-keep`/`-dontwarn` rules for `com.google.mlkit.**` and the ML Kit/Vision internals, and wire it into the release build type with `proguardFiles(...)`. Bump the app version to 1.0.1+2 for the hotfix release.
- Done when: a release APK launches without a FATAL exception, on-device OCR runs end to end, and analyze/tests stay green.
- Status: DONE (2026-10-16) — root cause confirmed by deobfuscating the release stack trace with `build/app/outputs/mapping/release/mapping.txt` (`yg1`/`wh1` = `com.google.mlkit.vision.text.internal.zzo`/`zzp`). The earlier INTERNET fix alone did not stop the crash — both defects had to be fixed. Verified on emulator-5554: the release APK (84.4 MB) installs and launches with no FATAL exception and zero ML Kit `NoSuchMethodException`; the full gallery → ML Kit OCR path runs and the flow reaches the Gemini step ("No Google AI API key is configured" as expected without a key). `flutter analyze` clean, 199/199 tests. macOS and iOS confirmed unaffected (macOS already carries `com.apple.security.network.client` in both Debug and Release entitlements; iOS needs no explicit network permission and has no ATS restriction). Shipped as release **v1.0.1**.
## P15 — Multi-language input (DONE)

Goal: translate text from many more source languages into Persian, and make the
existing From/To pickers truthful. Today `AppSettings` already stores a free
source/target pair and Settings already offers 11 languages (`kSupportedLanguages`),
but OCR ignores the choice: Apple Vision runs with its default language list and ML Kit
is Latin-only, so picking e.g. Russian or Arabic silently yields empty or garbage text.

Scope decisions (owner-approved 2026-10-22):
- Priority now: many source languages -> Persian. Source AND target stay user-selectable
  (target default `fa`); nothing already selectable is removed.
- **No offline translation engine for now.** Revisit only through a research task with a
  quality gate (see "Not in P15"); ship it only if quality is good, otherwise not at all.
- A source language is offered on a platform only if that platform's OCR can read it.

Order: T-150 -> T-151 -> T-152 -> T-153 -> T-154 -> T-155 -> T-156.

### T-150 · [S] Pigeon generation script + drift check + doc fixes
- Files: tool/gen_pigeon.sh (new), .github/workflows/ci.yml, TASKS.md, pubspec.yaml
- Do: `pigeons/messages.dart` has a single `swiftOut` (macOS); `ios/Runner/Messages.g.swift` is a manual copy (T-112), so any API change can leave iOS stale. Add `tool/gen_pigeon.sh`: run `dart run pigeon --input pigeons/messages.dart`, then copy `macos/Runner/Messages.g.swift` to `ios/Runner/Messages.g.swift` (keep the `#if os(iOS)` / `#elseif os(macOS)` import guards from T-112 — verify the generated file still carries them, otherwise re-apply). Add a CI step after `flutter pub get`: run the script, then `git diff --exit-code` (fails if generated files are not committed). Fix stale docs: T-131 status TODO -> DONE (P12 is DONE), and the `description:` in pubspec.yaml ("A new Flutter project.") -> a real one-line description.
- Done when: running the script on a clean tree produces no diff; CI fails if a Pigeon change is not regenerated/committed; analyze + tests green.
- Status: DONE (2026-10-22) — `bash tool/gen_pigeon.sh` on a clean tree regenerates identical files (no diff); CI now runs it followed by `git diff --exit-code`; T-131 status fixed; pubspec description set. analyze clean, 199/199 tests. Follow-up: `dart format` had reflowed `lib/pigeon/messages.g.dart`, which made the drift check fail on a clean tree — the file is kept byte-identical to the generator output (commit 423429de).

### T-151 · [M] Language catalog and truthful "auto-detect" source
- Files: lib/models/language.dart (new), lib/services/settings_repository.dart, lib/services/prefs_settings_repository.dart, lib/features/settings/settings_view.dart, test/models/language_test.dart (new)
- Do: Add `Language { code (ISO 639-1), englishName, nativeName, isRtl }` and a `LanguageCatalog` (replaces `kSupportedLanguages` in settings_view.dart). Keep the current 11 codes and add `pt`, `nl`, `ko`. Add the pseudo-code `auto` (source only). Change `AppSettings.defaultSourceLanguage` from `en` to `auto`; existing installs keep their stored value (no migration needed because `load()` only falls back when nothing is stored). Provide `LanguageCatalog.displayName(code)` so the History/result views stop printing raw codes where a name exists. `auto` must never be offered as a target.
- Done when: catalog unit tests pass (lookup, unknown code fallback, `auto` not a valid target, RTL flags for fa/ar); a fresh install defaults to `auto`; an existing stored `en` is preserved; analyze + tests green (update tests that assumed default `en`).
- Status: DONE (2026-10-22) — `lib/models/language.dart` (`Language`, `LanguageCatalog` with 14 languages + `auto`); `kSupportedLanguages` removed; both pickers read the catalog; `AppSettings.defaultSourceLanguage` is `auto` with no migration (repository test proves a stored `en` survives); catalog/default tests added, tests that assumed `en` updated. analyze clean, 209/209 tests.

### T-152 · [L] OcrApi: language hints + supported-language query (Pigeon, macOS, Android)
- Files: pigeons/messages.dart, lib/pigeon/messages.g.dart, macos/Runner/Messages.g.swift, ios/Runner/Messages.g.swift, android/app/src/main/kotlin/com/moradzadeh67/veliq/Messages.g.kt, macos/Runner/MainFlutterWindow.swift (OcrHandler), android/.../MainActivity.kt (MlKitOcrApi), lib/services/ocr_service.dart, lib/services/pigeon_ocr_service.dart, lib/features/ocr/bloc/ocr_bloc.dart, test/services/ocr_service_test.dart, test/features/ocr/bloc/ocr_bloc_test.dart
- Do: Change `OcrApi.recognizeText(Uint8List imageBytes, String? languageHint)` (`null` or `auto` = detect) and add `@async List<String> supportedLanguages()` returning ISO 639-1 base codes this platform's OCR can read. macOS Swift: when the hint is `auto`, set `request.automaticallyDetectsLanguage = true`; otherwise map the base code to the matching entries of `VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: request.revision)` (match by prefix, e.g. `zh` -> `zh-Hans`/`zh-Hant`) and set `request.recognitionLanguages`; if no entry matches, throw a readable error. `supportedLanguages()` derives base codes from that same Vision list — do not hard-code it. Android Kotlin: keep the single bundled Latin recognizer, ignore the hint, and return `["en","de","fr","es","it","pt","nl","tr"]`. Thread the hint through `OcrService`, `PigeonOcrService` and `OcrBloc.recognizeImage(bytes, {languageHint})`; add `Future<Set<String>> supportedLanguages()` to `OcrService`. No image data is logged or written (privacy rules unchanged).
- Done when: Pigeon outputs regenerated via tools/gen_pigeon.sh for all three platforms; on macOS a French and a Russian screenshot are read correctly with `auto` and with an explicit hint; on the Android emulator a French/German image is read; unit tests cover hint forwarding and the supported-language set (with fakes); analyze + tests green; release build still launches (D-017 smoke test).
- Status: DONE (2026-10-22) — `OcrApi.recognizeText(bytes, languageHint)` + `supportedLanguages()` regenerated for Dart/macOS/Android (iOS copy updated by the script); macOS handler derives its language list from `VNRecognizeTextRequest.supportedRecognitionLanguages()` and throws a readable error for an unmapped hint; Android ignores the hint (single Latin model) and returns `en,de,fr,es,it,pt,nl,tr`; hint threaded through `OcrService`/`PigeonOcrService`/`OcrBloc`. `flutter build macos` and `flutter build apk --debug` succeed; analyze clean, 214/214 tests. Manual multi-language OCR checks stay on the T-156 acceptance list (no GUI driving here).

### T-153 · [L] iOS OCR handler (Vision) — verify, then implement if missing
- Files: ios/Runner/OcrHandler.swift (new), ios/Runner/AppDelegate.swift, ios/Runner.xcodeproj/project.pbxproj (add file to Runner target, as for ImageSourceHandler in T-113)
- Do: First verify with `grep -rn "OcrApiSetup\|VNRecognizeTextRequest" ios/`. The files received for review show `ios/Runner/AppDelegate.swift` registering only `ImageSourceApiSetup`, and the only Vision code (`OcrHandler`) lives in `macos/Runner/MainFlutterWindow.swift` using `NSImage`, which does not exist on iOS. If confirmed, the iOS flow (gallery/camera -> OCR) has no OCR backend. Implement an iOS `OcrHandler: OcrApi` with the same behaviour as T-152's macOS handler but decoding via `UIImage(data:)?.cgImage` (honour `imageOrientation` by passing the matching `CGImagePropertyOrientation` to `VNImageRequestHandler`), and register it in `didInitializeImplicitFlutterEngine` with `OcrApiSetup.setUp(binaryMessenger: messenger, api: OcrHandler())`.
- Done when: the grep result is recorded here; an iOS build compiles; `OcrApi` is registered on iOS; a gallery image on the simulator goes through OCR to the translate step (manual check, joins T-124).
- Status: DONE (2026-10-22) — grep confirmed: before this task the only `OcrApiSetup` reference on iOS was the generated `Messages.g.swift`, and every Vision/`VNRecognizeTextRequest` call lived in `macos/Runner/MainFlutterWindow.swift` (`NSImage`, macOS-only), so iOS had no OCR backend. Added `ios/Runner/OcrHandler.swift` (UIImage -> CGImage, EXIF orientation mapped to `CGImagePropertyOrientation`, hint + `supportedLanguages()` like macOS), registered it in `didInitializeImplicitFlutterEngine`, and added the four Runner-target entries to `project.pbxproj` next to `ImageSourceHandler.swift`. `flutter build ios --simulator --no-codesign` succeeds (so the file is in the target — the call would not compile otherwise). Gallery-image-on-simulator check stays on the T-156/T-124 manual list. D-017 release smoke test on emulator-5554: `flutter build apk --release` (84.4 MB) installs, launches and shows the Translate screen with no `FATAL EXCEPTION` in logcat. NOTE for the owner: `~/Desktop/Veliq-upload-key/Veliq-upload.jks` is missing on this machine, so `validateSigningRelease` failed; the smoke APK was built with `android/key.properties` moved aside temporarily (falls back to the debug key) and restored afterwards. The upload keystore must be recovered before any store release.

### T-154 · [S] Gemini prompt: language names and auto-detect
- Files: lib/services/gemini_translation_service.dart, test/services/gemini_translation_service_test.dart
- Do: `_buildPrompt` currently injects raw codes (`from language "en"`). Resolve codes to English names through `LanguageCatalog` (fallback: the raw code). For `auto`, use a prompt variant: "Detect the language of the text between the markers and translate it to <target>; if it is already <target>, return it unchanged". Keep every existing rule (output only the translation, preserve line breaks, never echo the source). `verifyApiKey` keeps working with `auto`. Text only — never an image.
- Done when: tests assert the prompt text for an explicit pair and for `auto`; analyze + tests green.
- Status: DONE (2026-10-22) — `_buildPrompt` resolves codes through `LanguageCatalog` (raw code fallback) and uses a detect-then-translate wording for `auto`; `SwitchingTranslationService` throws a readable `TranslationException` for Apple + `auto` before touching Apple, while Google + `auto` still routes normally. Prompt tests added for the explicit pair, `auto` and an unknown code; switching tests for both new paths. analyze clean, 219/219 tests. Reaching Apple with an `auto` source from the UI is prevented in T-155 (picker + notice).

### T-155 · [M] Settings and flow: platform-aware source picker
- Files: lib/features/settings/settings_view.dart, lib/features/settings/bloc/settings_bloc.dart, lib/features/translation/bloc/translate_flow_bloc.dart, lib/features/translation/translate_view.dart, test/features/settings/settings_view_test.dart, test/features/translation/bloc/translate_flow_bloc_test.dart
- Do: Source picker lists `Auto-detect` first, then catalog languages; entries not in `OcrService.supportedLanguages()` are shown disabled with a short reason ("Not supported by this device's text recognition"). If the stored source is unsupported on this platform, show a fixable notice (same pattern as `appleNeedsFix` in T-137) offering "Use auto-detect" instead of silently keeping it. The target picker is NOT locked (remove nothing); show a hint when source == target. `TranslateFlowBloc.runForImageBytes` passes `settings.sourceLanguage` as the OCR `languageHint`. Result/history labels show language names, not raw codes. Do not add a third picker to the translate screen in this task.
- Done when: widget tests cover disabled entries, the unsupported-stored-source notice and the source==target hint; a flow test asserts the hint reaches `OcrBloc`; analyze + tests green.
- Status: DONE (2026-10-23) — `SettingsBloc` takes an optional `ocrLanguagesProvider` (wired in `main.dart` to the single `PigeonOcrService`, so the settings UI never touches Pigeon); the From picker disables unsupported languages with "Not supported by this device's text recognition" and keeps everything enabled while the set is unknown/loading; an unsupported stored source shows a "Use auto-detect" notice; source == target (non-auto) shows a warning; the To picker is untouched. `TranslateFlowBloc` loads settings once and passes `sourceLanguage` as the OCR hint; `translate_view` labels use `LanguageCatalog.displayName`. analyze clean, 227/227 tests.

### T-156 · [S] Docs, D-018 and acceptance
- Files: docs/ARCHITECTURE.md, README.md, docs/PRIVACY.md (only if wording changes), TASKS.md, CURRENT_TASK.md
- Do: Add **D-018 — OCR language model**: language catalog, `auto` default, per-platform capability via `OcrApi.supportedLanguages()` (Vision list at runtime, ML Kit Latin set on Android), and the explicit gaps (Android: no Arabic/Persian/Cyrillic script recognizers in ML Kit; CJK/Devanagari need separate ML Kit dependencies; Persian OCR availability on Apple is whatever Vision reports). Update README (Roadmap, Known limitations, FAQ "which languages") and the data-flow section. Run acceptance: analyze, tests, macOS manual (3 languages), Android emulator manual (2 Latin languages), release-APK smoke test.
- Done when: docs match behaviour; acceptance checklist recorded in the Status line.
- Status: DONE (2026-10-23) — ARCHITECTURE has **D-018** plus corrected data-flow/components text (iOS `ios/Runner/OcrHandler.swift`, new `OcrApi` signature, and an explicit note that iOS had no OCR backend before T-153); README Roadmap/Known limitations/FAQ 6 updated; CURRENT_TASK points at T-124. Acceptance run: `flutter analyze` clean, `flutter test` 227/227, `flutter build macos` ✓ (46.7 MB), `flutter build ios --simulator --no-codesign` ✓, `flutter build apk --release` ✓ (84.4 MB) and the emulator-5554 smoke test shows the Translate screen with **zero** `FATAL EXCEPTION`. Android Settings verified by screenshot on the emulator: From = Auto-detect, To = Persian, and the From list disables Persian/Arabic/Russian/Chinese/Japanese/Korean with "Not supported by this device's text recognition". The macOS multi-language capture check and the first iOS OCR run stay with the owner (GUI / broken simulator).

### Not in P15 (recorded, not scheduled)
- **Offline translation:** only via a future research task with a quality gate — blind comparison against Gemini on ~50 real sentences, owner sets the threshold; if it fails, no offline engine ships. Note: Apple Translation has no Persian, and ML Kit Translate model downloads come from Google servers (may be unreachable from Iran).
- **Persian (Arabic-script) OCR on Android** and **ML Kit CJK/Devanagari recognizers** (extra dependencies, APK size): separate task after P15, informed by the supported-language data.
- Crop-before-OCR, Persian UI localisation, share-intent / PROCESS_TEXT, release automation, split-per-ABI APKs: tracked separately.
