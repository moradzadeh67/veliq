# PROJECT_SPEC.md — Veliq

## Goal
Select any region of the screen (macOS), or pick a photo / take a photo (iOS, Android), extract its
text locally, translate it to Persian, and show the result in a small, fast UI.

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
  Roadmap: more languages — additional OCR scripts and additional source/target
  languages beyond English -> Persian (owner request, 2026-10-16).

## Out of scope
Windows/Linux, accounts, cloud sync, analytics, backend, payments, saving screenshots
permanently. On Android v1 additionally: region selection, screen capture (MediaProjection) and
Apple Translation — see "Android scope (P12, v1)".

## Constraints
- macOS 14.6+, iOS 16.0+ and Android 7.0+ (`minSdk = flutter.minSdkVersion`, 24 with Flutter 3.47);
  Flutter + Swift (Apple targets) and Kotlin (Android); open source; GitHub distribution first.
- Do not design around App Store submission, but do not block it.
- Distribution: GitHub first. Android releases are signed with the upload key `Veliq-upload.jks`
  (kept outside the repository; `android/key.properties` is git-ignored, with a debug fallback when
  the file is absent). GitHub release `v1.0.0` (2026-10-16) ships the signed APK. No store listing:
  Google Play was explicitly declined by the owner on 2026-10-16, and the public web presence is the
  GitHub Pages landing site under `docs/` (with robots.txt + sitemap.xml).
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

## Android scope (P12, v1)
Android was added as a third target after the iOS port (decision D-016). v1 is photo input only:
- **Image acquisition**: gallery via the Android **Photo Picker** intents (`ACTION_PICK_IMAGES` on
  API 33+, `ACTION_GET_CONTENT` fallback; no storage permission) and camera via
  `ACTION_IMAGE_CAPTURE` + `EXTRA_OUTPUT` + a `FileProvider` cache file that is deleted right after
  reading (CAMERA runtime permission; camera declared optional in the Manifest so camera-less devices
  can install the app). `ActivityResultContracts.TakePicture` was not usable because `FlutterActivity`
  is not a `ComponentActivity` (deviation from the original plan, T-135).
- **OCR**: on-device with the bundled ML Kit Latin recognizer (`com.google.mlkit:text-recognition`,
  Latin script only), implemented directly in Kotlin behind Pigeon — no Flutter ML Kit package, so the
  Dart layer is untouched. Only `ImageSourceApi` and `OcrApi` are registered on the Android Pigeon host.
- **Translation**: Google Gemini only (the user's own key, `flutter_secure_storage`). The Apple
  provider is hidden on Android.
- **UI**: the mobile layout already used by iOS — bottom `NavigationBar`, no "Select region".
- **Not in v1**: region selection, screen capture (MediaProjection + foreground service), Apple
  Translation, any new feature.
- **Identity**: app label "Veliq" (`res/values/strings.xml`), adaptive launcher icon derived from
  `assets/branding/logo.svg` (D-015); version stays `1.0.0+1`.
- **Status**: P12 tasks T-131..T-139 all DONE (2026-10-15); verified end to end on the Android
  emulator (Pixel 10 Pro XL AVD), including a real Gemini translation and history surviving an app
  restart (T-139). No physical Android device is in scope.
