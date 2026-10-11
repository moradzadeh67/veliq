# Veliq — Privacy and Data Handling

## Status
This document describes the intended privacy model and implementation rules.
If the implementation differs from it, the implementation must not be described as
compliant until the difference is resolved.

## Principle
Veliq is a local-first desktop utility. Screen content stays on the user's Mac as long as possible.

Target flow:
Screen region -> local capture -> local OCR -> extracted text -> translation provider (text only) -> result

## Screen content
A selected region may contain sensitive information.
- Capture only the selected region when possible.
- Do not save screenshots permanently unless a future feature explicitly requires it.
- Do not upload screenshots to a translation provider when extracted text is sufficient.
- Release temporary image data when no longer needed.
- Debug logging must not dump screenshot content.

## OCR
- Preferred: Apple Vision, local processing, no network for the OCR stage.
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

### Shared rules
- **Data Flow**: Send extracted text only (never screenshots).
- **Logging & Security**: Do not log full user text in production. The API key is
  stored only in this Mac's local app preferences and must never be committed
  (see "Security rules"). Error messages surfaced to the UI must not contain the
  key or the translated text.
- **Extensibility**: The pluggable `TranslationService` interface allows further
  text-only providers.

## Local history (if enabled)
- Store only what the history feature needs.
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
Veliq may need macOS permissions (screen capture, possibly global input/shortcuts).
They must be documented, requested only when necessary, and handled gracefully when denied.
See docs/MACOS_PERMISSIONS.md.

## Security rules
Never commit: API keys, access tokens, private certificates, provisioning secrets,
`.env` files with real credentials.
Use configuration mechanisms appropriate to the chosen provider.
Before a public GitHub release: run a secrets scan and review history if a secret was ever committed.

## Future App Store consideration
If prepared for the App Store, do a fresh privacy and entitlement review based on Apple's
current requirements. Do not assume today's development configuration is suitable.
