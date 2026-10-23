## Veliq 1.1.0

**Multi-language input.** Veliq no longer assumes the text it reads is English. Pick the source
language in Settings, or leave it on **Auto-detect** — which is now the default — and Gemini reports the
language it recognised, so the result card says `Original (French)` and History records
`French → Persian` instead of a generic "Auto-detect". Persian is still the target language.

### What's new

- **Source language picker** — 14 languages. Settings only offers the ones your device can actually
  read, and marks the rest as "Not supported by this device's text recognition".
- **Auto-detect** — the default source. Detection is reported by Gemini, so it works with a photo in
  any language the model knows.
- **iOS text recognition** — the iPhone build previously had no OCR backend at all; it now uses Apple
  Vision, like the macOS app.
- **Language names in History** — `English → Persian` instead of `EN → FA`.
- **Clearer Settings copy** — the API key is described as living in the device Keychain (it always did),
  and the iPhone build no longer talks about "this Mac".

### Source languages your device can read

| Platform | Languages |
|---|---|
| macOS / iOS (Apple Vision) | whatever the OS reports at runtime — typically en, fr, de, es, it, pt, nl, tr, plus other scripts such as Russian, Chinese, Japanese and Korean on recent versions. Settings lists exactly what your device supports. |
| Android (bundled ML Kit Latin model) | `en`, `de`, `fr`, `es`, `it`, `pt`, `nl`, `tr` |

### Known limits

- **Android OCR reads Latin script only.** Persian/Arabic, Cyrillic and CJK input are **not available
  on Android yet** — the UI shows those choices disabled with an explanation. Reading them needs extra
  ML Kit models and a larger APK; it is on the roadmap.
- **Apple's on-device translation needs a concrete source language**, so it cannot be combined with
  Auto-detect. Veliq tells you so in plain words instead of failing silently; switch to Google Gemini
  for auto-detect.
- **iOS camera capture has not been tested on a physical device** (only the gallery picker has been
  verified on the simulator).
- The Android APKs are signed with the Veliq upload key; install them over a previous GitHub build of
  the same package. Pick the file for your CPU: `arm64-v8a` (any recent phone), `armeabi-v7a` (older
  32-bit devices) or `x86_64` (emulators). Each has a matching `.sha256` checksum.
- macOS and iOS are still build-from-source (no notarized desktop build yet).
