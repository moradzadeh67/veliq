# Veliq

Select any region of your screen, extract its text locally, and translate it to Persian.

<!-- TODO: add a 15-30 s demo GIF at docs/demo.gif (clean history, no personal content) and uncomment:
![Veliq demo](docs/demo.gif)
-->

Veliq is a small, local-first macOS and iOS utility built with **Flutter (Dart)** and a thin **Swift**
native layer. Screenshots and photos never leave your device and are never written to disk: capture and OCR
run on-device with Apple's ScreenCaptureKit (macOS) and Vision frameworks. Only the extracted **text** is
sent to the translation provider.

## Status

Works end to end on **macOS 14.6+** for personal use: region select -> on-device OCR -> Gemini translation ->
local history. The **iOS port** (P7-P9) is in progress — photo-library and camera input, bottom navigation,
SafeArea-aware layout and Application Support storage are implemented, but it is **not device-verified yet**
(T-118 deferred, T-124 open). Builds are unsigned; the public-release checklist lives in
[docs/RELEASE.md](docs/RELEASE.md).

## Features

- Drag-select any region of the screen, from a full-screen overlay (`Esc` cancels) — macOS
- Pick a photo from the library or take one with the camera — iOS (no region selection is possible there)
- On-device OCR (Apple Vision) and on-device capture (ScreenCaptureKit on macOS)
- Bottom `NavigationBar` on iOS, `NavigationRail` on macOS
- Translation with Google Gemini using **your own API key**
- Right-to-left, justified Persian result view; copy the original or the translation
- Local, deletable translation history
- API key stored in the Keychain

## How it works

```
macOS: select region (Swift overlay) -> capture (ScreenCaptureKit) -> OCR (Vision, on-device)
         -> extracted text -> Gemini API (text only) -> result view + local history
iOS:   pick photo / take photo (Swift) -> OCR (Vision, on-device)
         -> extracted text -> Gemini API (text only) -> result view + local history
```

## Requirements

- macOS 14.6 or later (the Xcode deployment target), or iOS 16.0 or later (intended floor — the iOS
  Xcode target still says 15.0, see the open items in [TASKS.md](TASKS.md))
- **Screen Recording** permission on macOS (required to capture the selected region)
- **Camera** permission on iOS, and only if you take a photo; the photo library needs no permission
- A Google Gemini API key (create one in [Google AI Studio](https://aistudio.google.com/apikey))

## Getting started

1. Build and run (see [Development](#development)) or download a release.
2. Open **Settings**, paste your API key, and press **Save & test**.
3. Open **Translate**, click **Select region**, and drag over the text.

First launch of an unsigned build: macOS may refuse to open it by double-click. Right-click the app and choose
**Open** once. <!-- TODO: verify the exact prompts on a clean Mac / second user account -->

## Permissions

On macOS, Veliq asks for **Screen Recording** only. If you dismissed the prompt, enable it manually:

> System Settings -> Privacy & Security -> Screen Recording -> enable **Veliq**

Fully quit and reopen Veliq after changing this setting. Veliq does **not** request Accessibility, Full Disk Access,
or any other permission. On iOS, Veliq asks for the **Camera** only when you tap *Take photo*; picking from the
photo library uses `PHPickerViewController`, which needs no permission at all.
See [docs/MACOS_PERMISSIONS.md](docs/MACOS_PERMISSIONS.md).

## Privacy

- Capture and OCR are entirely on-device; screenshots and picked photos are held in memory and discarded.
- Only the recognized **text** is sent to Google's Gemini API, with your own key. On the free tier Google may use
  that text to improve its products, and human reviewers may read it; users in the EEA, Switzerland and the UK are
  covered by the paid-tier terms. Terms change: check Google's current Gemini API terms.
- Your API key is stored in the Keychain, not in plain-text preferences.
- Translation history lives in the app's Application Support directory
  (`getApplicationSupportDirectory()`), i.e. `~/Library/Application Support/com.moradzadeh67.veliq/history.json`
  on macOS, and can be cleared from the History screen.
- No account, no analytics, no backend.

Details: [docs/PRIVACY.md](docs/PRIVACY.md).

## Architecture and decisions

Dart owns UI, state, orchestration and storage; Swift owns the native capabilities. The boundary is a small,
Pigeon-generated interface. Decisions and their status (with sources for platform claims) are recorded in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Highlights:

| Topic | Choice | Why |
|---|---|---|
| State management | BLoC pattern (hand-written, no `bloc` package) <!-- TODO: confirm --> | testable, UI-independent state |
| Dart <-> Swift | Pigeon | type-safe bridge, generated code |
| Screen capture | ScreenCaptureKit | `CGWindowListCreateImage` is obsoleted in the macOS 15 SDK |
| OCR | Apple Vision | on-device, no network |
| Translation | Gemini API via a `TranslationService` interface | Apple's Translation framework does not cover Persian |
| API key storage | Keychain via `flutter_secure_storage` (legacy keychain) | works without a paid Apple developer account |

## Development

```bash
flutter pub get
flutter analyze
flutter test                      # 181 unit and widget tests
flutter run -d macos
flutter run -d "iPhone 15"        # iOS
flutter build ios --no-codesign   # iOS build check
```

### Project layout

```
lib/core/                     cross-cutting helpers
lib/features/capture/         region selection overlay
lib/features/ocr/             OCR state
lib/features/translation/     translation state + capture->OCR->translate->save flow
lib/features/history/         saved translations
lib/features/settings/        provider, language pair, API key
lib/features/home/            navigation shell
lib/services/                 service interfaces + Pigeon/native + Gemini implementations
lib/models/                   data models
lib/pigeon/                   generated Pigeon bindings (do not edit)
macos/                        Swift native code (capture, OCR, selection overlay)
ios/                          Swift native code (image source: photo picker + camera)
assets/app_icon/              icon master + generator script (not bundled)
pigeons/                      Pigeon definitions
test/                         mirrors lib/
```

## Known limitations

- Displays placed **above** the main one (negative-coordinate layouts) were not reproducible to test; Retina and a side-by-side second display are verified (T-063).
- Builds are unsigned; see "Getting started" for first launch.
- Global shortcut is deferred.
- **iOS is not device-verified yet**: no physical iPhone was available (T-118 deferred) and the simulator review (T-124) is still open. The iOS Xcode target also still carries the template bundle id `com.example.veliq` and a 15.0 deployment target.
- On iOS there is no region selection: you pick an existing photo or take a new one.

## How this project was built

Architecture, decisions and review are mine; routine implementation tasks were split into small, verifiable
tasks and partly executed with AI assistants under written rules (`AGENTS.md`, `TASKS.md`). Every change goes
through tests, `flutter analyze` and a manual check before it is committed.

## License

MIT. See [LICENSE](LICENSE).
