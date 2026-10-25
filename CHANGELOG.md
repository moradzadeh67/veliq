# Changelog

All notable changes to Veliq are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-25

### Added
- **Translation without an API key.** A third provider, Google Translate (free), talks to Google's
  web client endpoint and needs no account and no key. It is the default for **fresh installs**,
  which also makes Veliq usable from Iran without a VPN; an existing install keeps the provider it
  already had. Gemini (your own key) and Apple's on-device engine are unchanged (T-164, D-020).
- **Android OCR confidence routing.** Source = Auto-detect now compares both bundled engines instead
  of trusting the Latin model: ML Kit is accepted at confidence >= 0.70, otherwise Tesseract
  (`rus+fas+ara`) also runs and the better valid reading wins. A winner below 0.45 is reported as an
  unreadable photo instead of being shown as a translation. A Tesseract result only competes when it
  has a comparable amount of text (`max(10, 30 % of the ML Kit length)` characters), so a confident
  three-letter fragment can no longer beat a correct paragraph (T-165, T-168, D-021).
- **OCR line breaks are rejoined for Google Translate.** Hard-wrapped lines used to be translated one
  by one ("By pitching the tailfinishing…"); blank lines still separate paragraphs, and a line that
  ends a sentence or a list item keeps its break. Gemini and Apple receive the text unchanged (T-168).

### Changed
- Settings shows the Gemini API-key fields only when Gemini is the selected provider, and describes
  the keyless provider as needing no setup.
- The Android "no text found" guidance and the release notes no longer claim that Persian, Arabic and
  Russian are read without qualification: an explicit source remains the most reliable choice, and
  handwriting is out of scope.

### Fixed
- **A non-Latin photo on Auto-detect is no longer shown as gibberish.** On Android a Persian, Arabic
  or Russian photo was "read" as look-alike Latin letters and the junk reached the translator; the
  confidence routing above, together with the existing writing-system check, now yields either real
  text or a clear "the photo was probably misread" message (T-162, T-165, T-168).
- **Source equal to target is rejected before OCR** with a readable message instead of translating a
  language into itself (T-166).

### Known limitations
- **Handwriting and blackletter (Fraktur) are not supported** — both engines misread them.
- **Printed Russian accuracy varies with the photo** (shadows, skew, low resolution). Image
  preprocessing and one Tesseract language per run are on the roadmap.
- **Chinese, Japanese, Korean and Devanagari are unreadable on Android**; macOS/iOS read them through
  Apple Vision.
- **iOS camera capture has not been tested on a physical iPhone**, and macOS/iOS are still built from
  source (no notarized desktop build).
- The free Google Translate endpoint is unofficial: it can be rate-limited or change without notice.
  Gemini remains the supported fallback.

## [1.1.0] - 2026-10-24

### Added
- **Multi-language source input.** The source language is now a choice from a 14-language catalog
  (`lib/models/language.dart`) instead of always English, and the default source is **Auto-detect**.
  Settings only offers languages the device's text recognition can actually read.
- **Language-aware OCR.** `OcrApi.recognizeText` takes a language hint and `OcrApi.supportedLanguages()`
  reports what the platform can read — from Apple Vision at runtime on macOS/iOS, from the bundled
  ML Kit Latin model on Android (D-018).
- **iOS OCR backend.** `ios/Runner/OcrHandler.swift` (UIImage → CGImage, EXIF orientation, Vision) — the
  iOS target previously had no OCR implementation at all.
- **Source language detection shown to the user.** With the source on Auto-detect, Gemini reports the
  language it recognised, so the result card reads `Original (French)` and History records
  `French → Persian` instead of a generic "Auto-detect" (T-157). An explicit source choice always wins.
- **Language names in History** instead of raw ISO codes (`English → Persian`, not `EN → FA`) (T-158).
- **Android reads Persian, Arabic and Russian.** ML Kit ships no model for those scripts, so Android
  bundles Tesseract as a second on-device engine (`fas`, `ara`, `rus` models, ~5.6 MB). Choose the
  language in Settings and pick a photo: it runs offline, the image never leaves the device, and
  auto-detect still tries the Latin model first (T-163).
- A Pigeon regeneration script (`tool/gen_pigeon.sh`) and a CI step that fails when the generated
  bindings are stale.

### Changed
- The Gemini prompt now uses language names rather than codes, and Apple's on-device translation is
  refused with a readable message when the source is Auto-detect, because it needs a concrete language
  (T-154).
- Settings warns when the source and target languages are the same.
- On Android the "no text found" guidance points at the language choice (Latin by default, Persian,
  Arabic and Russian when picked explicitly) instead of blaming the photo.

### Fixed
- Settings said the Gemini API key was stored in "this Mac's app preferences" although it lives in the
  Keychain; it now names the real store, and iOS no longer says "Mac" (T-158, T-159).
- Duplicate/unused code paths removed while wiring the language hint through the OCR pipeline.
- **Android "No text found" for Persian/Arabic/Cyrillic photos** now explains that the bundled model
  reads Latin script only, instead of telling the user to find a clearer photo (T-161).
- **A misread photo is no longer shown as a translation.** When the answer arrives in the source's
  writing system instead of the target's (a Cyrillic or Arabic photo on Android is "read" as look-alike
  Latin letters), the app now says the photo was misread and explains the Latin-only OCR limit, instead
  of presenting gibberish as Persian (T-162).
- **Gemini handing the text back untranslated** — for a paragraph cropped mid-sentence the model could
  answer with the source text, which the app then showed (and stored) as the translation. It now retries
  once with the language it detected, and reports a clear message if the answer is still an echo
  (T-161).

## [1.0.1] - 2026-10-16

### Fixed
- **Android release builds could not reach the network.** Flutter declares `android.permission.INTERNET`
  only in the debug/profile manifests, so the release build could not call the Gemini API; the permission
  is now in the main manifest (T-141).
- **Android release builds crashed on launch.** R8 (minify + resource shrinking) stripped and renamed the
  reflectively loaded ML Kit internals, crashing `MainActivity.configureFlutterEngine()`; a
  `proguard-rules.pro` with `-keep`/`-dontwarn` rules for `com.google.mlkit.**` is now wired into the
  release build type (T-141).

## [1.0.0] - 2026-10-16

### Added
- First public release.
- Signed Android APK (+ `.sha256`) published on GitHub Releases; macOS and iOS are built from source.
- Region capture on macOS (ScreenCaptureKit + overlay), local OCR with Apple Vision, translation with
  Google Gemini using a private API key kept in the Keychain, RTL-correct Persian result panel.
- Photo Picker / Camera input on iOS and Android with ML Kit OCR, translation history and a settings
  screen.

[1.2.0]: https://github.com/moradzadeh67/veliq/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moradzadeh67/veliq/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/moradzadeh67/veliq/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/moradzadeh67/veliq/releases/tag/v1.0.0
