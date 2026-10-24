# CURRENT_TASK.md

Active: **P16 "Free translation + safer Android OCR"** (2026-10-24) — branch `p16-free-translation`.
Next up: T-164 (Google Translate free provider), then T-165 (Android OCR confidence routing),
T-166 (clear messages + release notes), T-167 (docs and acceptance).

## State of the repository (2026-10-24)

`main` at `655446a` is tagged `v1.1.0` and pushed; the working tree is clean and the two short-lived
branches (`release-1.1.0`, `p16-android-non-latin-ocr`) were deleted after merging. Release assets:
`app-arm64-v8a-release.apk` (41.9 MB), `app-armeabi-v7a-release.apk` (33.0 MB),
`app-x86_64-release.apk` (44.3 MB) with checksums, plus `app-release.aab` (78.6 MB) — signed with the
upload key (`SHA-256 1332bc48…a651af`), smoke-tested with zero `FATAL EXCEPTION`.

### Verified on a real device (2026-10-24)

Owner's Galaxy S24 (`SM-S928B`), release APK `app-arm64-v8a-release.apk` (41.9 MB, upload-key signed):
with **From = Russian** a photo of a Cyrillic screen is recognised as real Cyrillic and translated to
Persian; **From = Persian** reads Persian text. `Tesseract(native): Initialized … language=rus` appears in
logcat. With **From = Auto-detect** the Latin ML Kit model still wins and the app reports "probably
misread" instead of showing gibberish (T-162) — see the open item below.

## Open items

1. **Auto-detect with non-Latin photos — SUPERSEDED (2026-10-24) — replaced by the
   confidence-based routing in T-165.** The original plan was to re-run OCR with the language Gemini
   reported; investigation showed that cannot work (Gemini's language detection returns wrong
   neighbours such as `bg` on look-alike Latin gibberish, and ML Kit returns *non-empty* junk, so the
   Tesseract fallback never fired). T-165 instead routes on ML Kit's own confidence, which is local
   and reliable. Original prose kept below for the record.
   — On Android the Latin model runs first, so `auto` cannot read Persian/Arabic/Russian photos; the
   user must pick the language. Planned fix was: when Gemini reports a detected language that the
   bundled Tesseract models cover but the OCR text is in the wrong script, re-run OCR with that model
   and translate again.
2. **iOS camera** — still untested on a physical iPhone (device-only, T-118 dropped).
3. **Tesseract accuracy on paper photos** — verified on rendered images and one screen photo; curved
   pages/shadow are unmeasured. If quality disappoints: preprocessing or a higher OCR resolution, never a
   cloud OCR API (privacy).
4. **Diagrams** — `assets/diagrams/*.svg` were redrawn by the owner and already show the two Android
   engines and the detection step; no further drawing needed.

## Release 1.1.0 (2026-10-24)

`pubspec.yaml` is `1.1.0+3`; `CHANGELOG.md` is new (1.1.0 / 1.0.1 / 1.0.0); `PROJECT_SPEC.md`,
`README.md`, `docs/PRIVACY.md`, `docs/ARCHITECTURE.md` (D-019) and `docs/RELEASE.md` match the shipped
behaviour; `release_notes_1.1.0.md` holds the user-facing notes. Artifacts (git-ignored) built from
`main` and signed with the upload key — verified `SHA-256 1332bc48…a651af`:

| Artifact | Size |
|---|---|
| `build/app/outputs/bundle/release/app-release.aab` | 78.6 MB |
| `app-arm64-v8a-release.apk` | 41.9 MB |
| `app-armeabi-v7a-release.apk` | 33.0 MB |
| `app-x86_64-release.apk` | 44.3 MB |

Each has a `.sha256` next to it. D-017 smoke test on `Pixel_10_Pro_XL` (arm64-v8a): fresh install,
launch, 10 s, zero `FATAL EXCEPTION`. `flutter analyze` clean, 250/250 tests.

## Field fixes after the first release candidate

- **T-161** — Android's "No text found" now explains which scripts the device can read instead of blaming
  the photo; Gemini answers that merely repeat the input are retried once with the language the model
  reported (a paragraph cropped mid-sentence used to produce an "untranslated" result).
- **T-162** — a translation that cannot be in the target's writing system (Latin gibberish for a Persian
  target) is surfaced as a misread photo and never stored in History.
- **T-163** (branch `p16`) — Android now reads Persian, Arabic and Russian through bundled Tesseract;
  Settings unlocks those languages. Verified on the emulator line-for-line for Cyrillic and Persian
  rendered text; the image never leaves the device (no new privacy surface).

## What P15 (2026-10-23) delivered

P15 "Multi-language input" is DONE and merged to `main` in `0b83dbb`. Summary:

- `lib/models/language.dart`: `Language` + `LanguageCatalog` — 14 ISO 639-1 codes plus the source-only
  pseudo-code `auto`; `AppSettings.defaultSourceLanguage` is now `auto` (no migration; a stored choice is
  kept). `kSupportedLanguages` is gone.
- `OcrApi.recognizeText(bytes, languageHint)` + `OcrApi.supportedLanguages()` (D-018). macOS and iOS derive
  the list from `VNRecognizeTextRequest.supportedRecognitionLanguages()` at runtime and honour the hint
  (`auto` → `automaticallyDetectsLanguage`); Android combines ML Kit Latin with bundled Tesseract models
  (T-163).
- **iOS OCR now exists**: `ios/Runner/OcrHandler.swift` (UIImage → CGImage, EXIF orientation, registered via
  `OcrApiSetup`). Before T-153 the iOS target had no `OcrApi` implementation at all.
- Settings: the From picker disables languages the device cannot read, offers "Use auto-detect" when the
  stored source is unsupported, and warns when source == target.
- `tool/gen_pigeon.sh` + a CI step that fails when the generated files are stale.

Earlier work through T-129 is committed; P12 shipped in `82cbb9c`; the README/docs pass in `9db21b3`; P13
(T-140) in `fa7a2e9` + `5e65b53`; P14 (T-141) ships in the v1.0.1 release; P15 (T-150…T-157) merged to
`main` in `0b83dbb`; T-158 `0b83dbb`…`6feb1e0`; T-124 closed in `8ed21f1`; release prep + fixes on
`release-1.1.0` (`b1a4b24`, `8bae5e2`, `6feb1e0`, `c683bcc`, `faf2a96`, plus docs); T-163 in `5a88ff4`.
