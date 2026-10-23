# Veliq — Privacy and Data Handling

## Status
This document describes the intended privacy model and implementation rules.
If the implementation differs from it, the implementation must not be described as
compliant until the difference is resolved.

## Principle
Veliq is a local-first macOS, iOS and Android utility. Captured content stays on the device
as long as possible.

Target flow:
macOS:   screen region -> local capture -> local OCR -> extracted text -> translation provider (text only) -> result
iOS:     picked/taken photo -> local OCR -> extracted text -> translation provider (text only) -> result
Android: picked/taken photo -> local OCR (ML Kit Latin, or Tesseract for fa/ar/ru) -> extracted text -> Gemini (text only) -> result
         (Android v1 has Gemini only — the text always leaves the device when translating)

## Screen content
A selected region may contain sensitive information.
- Capture only the selected region when possible.
- Do not save screenshots permanently unless a future feature explicitly requires it.
- Do not upload screenshots to a translation provider when extracted text is sufficient.
- Release temporary image data when no longer needed.
- Debug logging must not dump screenshot content.

## Image sources (iOS)
On iOS the user supplies the image instead of selecting a screen region.
- **Photo library**: `PHPickerViewController` (PhotosUI). It runs out-of-process, so the app
  never receives photo-library access and **no photo-library permission is requested or
  needed** (D-010, D-012).
- **Camera**: `UIImagePickerController`. The captured photo is handed to the app as image
  bytes; the app needs `NSCameraUsageDescription` and nothing else (D-011, D-012).
- Picked/captured image bytes are held in memory, passed to Vision for OCR, then released.
  They are never written to disk and never uploaded. Veliq never writes to the photo library.
- The macOS rule still applies: only the recognized **text** may leave the device.

## Image sources (Android)
On Android v1 the user supplies the image; there is no region selection.
- **Photo Picker**: the system picker intents (`ACTION_PICK_IMAGES` on API 33+,
  `ACTION_GET_CONTENT` fallback) run out-of-process. No storage permission is requested or
  needed (D-016).
- **Camera**: `ACTION_IMAGE_CAPTURE` with an `EXTRA_OUTPUT` FileProvider URI. The photo is
  written to a temporary file in the app's cache (`cacheDir/photos/`), read back as JPEG
  bytes, and the file is **deleted immediately afterwards**, success or not (verified in
  MainActivity, 2026-10-15). The app needs the CAMERA runtime permission and nothing else.
- Picked/captured image bytes are held in memory for OCR and then released (same rule as
  iOS). The macOS rule still applies: only the recognized **text** may leave the device.

## OCR
- Preferred: Apple Vision, local processing, no network for the OCR stage.
- Android: **two bundled, offline engines** — ML Kit Latin (`com.google.mlkit:text-recognition`)
  for `en, de, fr, es, it, pt, nl, tr` and Tesseract with the `fas`, `ara` and `rus` traineddata
  files for Persian, Arabic and Russian (D-016, T-163). Both run in-process, need no network, and
  are the only addition: nothing is downloaded, nothing is uploaded, and the traineddata files are
  read-only assets copied into the app's private storage on first use. Chinese, Japanese and Korean
  are not bundled, so those languages stay unavailable on Android.
- The OCR service returns text and relevant metadata and does not retain the source image unnecessarily.

## Translation
The translation layer is abstracted behind a service interface:
`TranslationService.translateText(text, sourceLanguage, targetLanguage)`

Veliq ships two providers, chosen by the user in Settings. Which one is active
is the only thing that decides whether text leaves the machine.

### Apple (on-device)
- **Privacy**: Text is translated on the machine; nothing is sent anywhere.
- **Availability**: The programmatic `TranslationSession` API requires macOS 26.0+.
  On older systems this provider cannot translate at all.
- **Languages**: Limited to the roughly 21 languages Apple ships. **Persian is not
  among them**, so this provider cannot produce Persian output.
- **Cost & Limits**: Free. No API key, no subscription.

### Google Gemini (cloud)
- **Privacy**: The extracted text **is sent to Google** for translation. This is a
  deliberate, user-selected exception to the local-first principle:
  screenshots are still never uploaded — only the recognized text.
- **Android v1**: Gemini is the **only** provider there (Apple Translation does not exist on
  Android; the provider selector is hidden), so every translation on Android sends text to Google.
- **Requirements**: A user-supplied Google AI (Gemini) API key, created at
  https://aistudio.google.com/apikey.
- **Data Flow**: The recognized text travels inside a single prompt, with
  `temperature: 0`. No screenshots, no history, no identifiers.
- **Cost & Limits**: Billed by Google against the user's own key.
- **Why not Cloud Translation**: its API answers a plain API key with
  `CREDENTIALS_MISSING` — "API keys are not supported by this API" — for many
  projects, and demands OAuth2 instead. That would mean shipping a
  service-account private key inside a desktop app, which is not acceptable.
  Gemini accepts an ordinary API key.
- **Data use (free tier)**: Google's terms state that on unpaid services the
  submitted text and the generated responses may be used to provide, improve
  and develop Google products and machine-learning technologies, and that
  human reviewers may read and annotate API input and output. Users in the
  European Economic Area, Switzerland and the United Kingdom are covered by
  the paid-tier terms even on the free tier.
  Source: https://ai.google.dev/gemini-api/terms

### Shared rules
- **Data Flow**: Send extracted text only (never screenshots).
- **Logging & Security**: Do not log full user text in production. The API key is
  stored only in a device-local secure store — the macOS Keychain on Apple platforms, an
  Android-Keystore-encrypted store on Android (same `flutter_secure_storage` plugin, D-009/D-016)
  — and must never be
  committed (see "Security rules"). Error messages surfaced to the UI must not contain the
  key or the translated text.
- **Extensibility**: The pluggable `TranslationService` interface allows further
  text-only providers.

## Local history (if enabled)
- Store only what the history feature needs.
- Location: `history.json` inside `getApplicationSupportDirectory()` — the sandbox container on
  macOS, the app-private files dir on Android (`/data/data/com.moradzadeh67.veliq/files/history.json`,
  verified on the emulator 2026-10-15).
- Deletion must be possible, with a clear way to clear history.
- No silent cloud sync. No account-based sync without explicit product approval.

## Logging
Production logs must avoid: screenshots, complete OCR output (unless intentionally enabled
for debugging), API keys, tokens, unnecessary personal data.
Debug logging must be easy to disable or remove before release.

## Analytics and tracking
Current scope: no analytics, no advertising SDK, no behavioral tracking, no profiling.
Any future telemetry needs an explicit product decision and updated documentation.

## Permissions
- **macOS**: screen capture, and possibly global input/shortcuts.
- **iOS**: camera only (`NSCameraUsageDescription`). The photo library needs no permission
  because `PHPickerViewController` is out-of-process.
- **Android**: camera runtime permission only (*Take photo*); the Photo Picker needs no
  permission.
Permissions must be documented, requested only when necessary, and handled gracefully when
denied. See docs/MACOS_PERMISSIONS.md.

## Security rules
Never commit: API keys, access tokens, private certificates, provisioning secrets,
`.env` files with real credentials.
Use configuration mechanisms appropriate to the chosen provider.
Before a public GitHub release: run a secrets scan and review history if a secret was ever committed.

## Future App Store consideration
If prepared for the App Store, do a fresh privacy and entitlement review based on Apple's
current requirements. Do not assume today's development configuration is suitable.
