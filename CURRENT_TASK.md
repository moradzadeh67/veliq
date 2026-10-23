# CURRENT_TASK.md

Active: **release 1.1.0** — branch `release-1.1.0` (prepared, artifacts built, not pushed) plus
**T-163 on `p16-android-non-latin-ocr`** (Persian/Arabic/Russian OCR on Android, built and verified).
`main` is at `8ed21f1` and CI is green.

## State of the branches (2026-10-24)

| Branch | Head | Contents |
|---|---|---|
| `main` | `8ed21f1` | Released-tree state: P15 merged, T-124 closed. Pushed. |
| `release-1.1.0` | `faf2a96` | Release prep + the two field fixes (T-160, T-161, T-162). Artifacts built and signed. |
| `p16-android-non-latin-ocr` | `5a88ff4` | T-163 on top of `release-1.1.0`: Tesseract for `fa`/`ar`/`ru`. |

Nothing is pushed beyond `main`. The owner publishes (tag + GitHub release).

## Open items

1. **Owner: three diagrams** — `assets/diagrams/architecture-layers.svg`, `data-flow.svg`,
   `project-structure.svg` are embedded in `README.md` and still show the pre-P15 pipeline (Apple
   Vision only, translation without detection). They need the Android OCR split (ML Kit + Tesseract) and
   the detection step. Update them, then the README images need no code change.
2. **Owner: real-device check** — install `app-arm64-v8a-release.apk` on a physical Android phone, pick a
   gallery photo, OCR → Gemini, check the result card, History and the detected-language labels.
3. **Owner: publish** — merge, tag `v1.1.0`, create the GitHub release with the four artifacts + their
   `.sha256` files.
4. **Decide the release cut**: ship 1.1.0 now and Tesseract as 1.2.0, or merge T-163 into 1.1.0 (bump to
   `1.2.0+4`, rebuild, APK +10 MB).
5. **iOS camera** — still untested on a physical iPhone (device-only, T-118 dropped).
6. **Tesseract accuracy** — verified only on clean rendered images; real photos (curved pages, shadows)
   are unmeasured. If quality disappoints, the fallback is to keep the language picker and raise the OCR
   resolution / add preprocessing — not to switch to a cloud API (privacy).

## Release 1.1.0 (2026-10-23)

`pubspec.yaml` is `1.1.0+3`; `CHANGELOG.md` is new (1.1.0 / 1.0.1 / 1.0.0); `PROJECT_SPEC.md`,
`README.md` and `docs/RELEASE.md` match the shipped behaviour; `release_notes_1.1.0.md` holds the
user-facing notes. Artifacts (git-ignored) built from `release-1.1.0` and signed with the upload key —
verified `SHA-256 1332bc48…a651af`:

| Artifact | Size |
|---|---|
| `build/app/outputs/bundle/release/app-release.aab` | 66.5 MB |
| `app-arm64-v8a-release.apk` | 31.7 MB |
| `app-armeabi-v7a-release.apk` | 24.8 MB |
| `app-x86_64-release.apk` | 33.7 MB |

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
