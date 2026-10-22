# CURRENT_TASK.md

Active: **T-124 — manual review on the iOS simulator** (the last open verification task; P15 is DONE).

Status: OPEN — blocked on hardware. The bundled `Simulator.app` on the owner's Mac is broken (unsigned
binary that exits immediately; no Simulator.app inside Xcode.app either), so no UI-driven verification is
possible on this machine. Remaining checks: cancel path, revoked-permission message, history across an app
restart, and now also the first real iOS OCR run (gallery image → Vision → translate, added by T-153).
`idb` / `idb-companion` was evaluated as a headless alternative on 2026-10-16 and dropped (no longer
published in Homebrew). The owner decided to leave T-124 until a repaired simulator or a physical device
is available. Camera capture stays device-only (T-118 dropped).

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
- History rows still print raw codes (`EN → FA`) in the *list*; the translate-result labels and the stored entry now use the detected language (T-157).

Earlier work through T-129 is committed; P12 shipped in `82cbb9c`; the README/docs pass in `9db21b3`; P13
(T-140) in `fa7a2e9` + `5e65b53`; P14 (T-141) ships in the v1.0.1 release; P15 (T-150…T-156) on branch
`p15-multi-language`.
