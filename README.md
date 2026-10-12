# Veliq

Select any region of your screen, extract its text locally, and translate it to Persian.

<!-- TODO: add a 15-30 s demo GIF at docs/demo.gif (clean history, no personal content) and uncomment:
![Veliq demo](docs/demo.gif)
-->

Veliq is a small, local-first macOS utility built with **Flutter (Dart)** and a thin **Swift** native layer.
Screenshots never leave your Mac and are never written to disk: capture and OCR run on-device with Apple's
ScreenCaptureKit and Vision frameworks. Only the extracted **text** is sent to the translation provider.

## Features

- Drag-select any region of the screen, from a full-screen overlay (`Esc` cancels)
- On-device OCR (Apple Vision) and on-device capture (ScreenCaptureKit)
- Translation with Google Gemini using **your own API key**
- Right-to-left, justified Persian result view; copy the original or the translation
- Local, deletable translation history
- API key stored in the macOS Keychain

## How it works

```
select region (Swift overlay) -> capture (ScreenCaptureKit) -> OCR (Vision, on-device)
   -> extracted text -> Gemini API (text only) -> result view + local history
```

## Requirements

- macOS 14 or later <!-- TODO: confirm with MACOSX_DEPLOYMENT_TARGET in the Xcode project -->
- **Screen Recording** permission (required to capture the selected region)
- A Google Gemini API key (create one in Google AI Studio) <!-- TODO: link the official page after checking it -->

## Getting started

1. Build and run (see [Development](#development)) or download a release.
2. Open **Settings**, paste your API key, and press **Save & test**.
3. Open **Translate**, click **Select region**, and drag over the text.

First launch of an unsigned build: macOS may refuse to open it by double-click. Right-click the app and choose
**Open** once. <!-- TODO: verify the exact prompts on a clean Mac / second user account -->

## Permissions

Veliq asks for **Screen Recording** only. If you dismissed the prompt, enable it manually:

> System Settings -> Privacy & Security -> Screen Recording -> enable **Veliq**

Fully quit and reopen Veliq after changing this setting. Veliq does **not** request Accessibility, Full Disk Access,
or any other permission. See [docs/MACOS_PERMISSIONS.md](docs/MACOS_PERMISSIONS.md).

## Privacy

- Capture and OCR are entirely on-device; screenshots are held in memory and discarded.
- Only the recognized **text** is sent to Google's Gemini API, with your own key. On the free tier Google may use
  that text to improve its products, and human reviewers may read it; users in the EEA, Switzerland and the UK are
  covered by the paid-tier terms. Terms change: check Google's current Gemini API terms.
- Your API key is stored in the macOS Keychain, not in plain-text preferences.
- Translation history lives at `~/Library/Application Support/veliq/history.json` and can be cleared from the
  History screen.
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
flutter test          # 160+ unit and widget tests
flutter run -d macos
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
pigeons/                      Pigeon definitions
test/                         mirrors lib/
```

## Known limitations

- Region capture on a **second display / Retina scaling** is not fully verified yet (tracked in TASKS.md, T-063).
- Builds are unsigned; see "Getting started" for first launch.
- Global shortcut is deferred.

## How this project was built

Architecture, decisions and review are mine; routine implementation tasks were split into small, verifiable
tasks and partly executed with AI assistants under written rules (`AGENTS.md`, `TASKS.md`). Every change goes
through tests, `flutter analyze` and a manual check before it is committed.

## License

MIT. See [LICENSE](LICENSE).
