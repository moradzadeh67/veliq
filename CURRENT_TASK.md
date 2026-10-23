# CURRENT_TASK.md

Active: **T-124 — manual review on the iOS simulator** (the last open verification task; P15 is DONE).

Status: OPEN (partial, owner-side only). Xcode 27 replaced `Simulator.app` with **Device Hub**, which is
why the old "broken simulator" diagnosis was wrong; Device Hub runs, but it exposes no windows to System
Events and `osascript` has no assistive access here, so scripted taps are impossible. Headless proof on
2026-10-23: the current build installs, launches and shows the bottom navigation bar on the iOS 26.5
iPhone 17 Pro Max simulator. The three residual checks now have automated equivalents (picker cancel at
app level, permission message is moot with `PHPickerViewController`, history round-trip tests); what is
left for the owner is tapping the native picker's Cancel and a short visual pass. The first iOS OCR run
(Vision, added by T-153) was confirmed by the owner on all three platforms on 2026-10-23. Camera capture
stays device-only (T-118 dropped).

## What P15 (2026-10-23) delivered

P15 "Multi-language input" is DONE on branch `p15-multi-language` (not pushed). Summary:

- `lib/models/language.dart`: `Language` + `LanguageCatalog` — 14 ISO 639-1 codes plus the source-only
  pseudo-code `auto`; `AppSettings.defaultSourceLanguage` is now `auto` (no migration; a stored choice is
  kept). `kSupportedLanguages` is gone.
- `OcrApi.recognizeText(bytes, languageHint)` + `OcrApi.supportedLanguages()` (D-018). macOS and iOS derive
  the list from `VNRecognizeTextRequest.supportedRecognitionLanguages()` at runtime and honour the hint
  (`auto` → `automaticallyDetectsLanguage`); Android keeps the single bundled ML Kit Latin model, ignores
  the hint and reports `en,de,fr,es,it,pt,nl,tr`.
- **iOS OCR now exists**: `ios/Runner/OcrHandler.swift` (UIImage → CGImage, EXIF orientation, registered via
  `OcrApiSetup`). Before T-153 the iOS target had no `OcrApi` implementation at all.
- Settings: the From picker disables languages the device cannot read, offers "Use auto-detect" when the
  stored source is unsupported, and warns when source == target. The flow passes the source language to OCR
  as a hint and the Gemini prompt now uses language names (Apple + `auto` is refused with a readable error).
- `tool/gen_pigeon.sh` + a CI step that fails when the generated files are stale.

## Open items after P15

- **T-124** (above) — including the first iOS OCR run.
- `PROJECT_SPEC.md` still lists "source language selection, other target languages" under *Post-MVP
  (deferred)*; that wording predates P15 and was left untouched by T-156.
- **Upload keystore missing** (2026-10-23): `~/Desktop/Veliq-upload-key/Veliq-upload.jks` is not on this
  machine, so `validateSigningRelease` fails. The T-153 smoke APK was built with the debug key (by moving
  `android/key.properties` aside temporarily). Recover the keystore from the documented backup
  (`~/Desktop/Veliq-upload-key.zip`) before any further release.
- ~~History rows print raw codes (`EN → FA`)~~ — fixed by T-158 together with the Keychain wording.

Earlier work through T-129 is committed; P12 shipped in `82cbb9c`; the README/docs pass in `9db21b3`; P13
(T-140) in `fa7a2e9` + `5e65b53`; P14 (T-141) ships in the v1.0.1 release; P15 (T-150…T-156) on branch
`p15-multi-language`.
