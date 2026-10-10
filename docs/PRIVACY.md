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
The translation layer is abstracted behind a service interface, conceptually:
`TranslationService.translate(text, sourceLanguage, targetLanguage)`

- Send extracted text, never the original screenshot.
- Do not log full user text in production by default.
- Never commit API keys or secrets.
- Handle network failures explicitly.
- Document the chosen provider's privacy policy before production use.
- If a provider needs a different data flow, document it before implementation.

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
