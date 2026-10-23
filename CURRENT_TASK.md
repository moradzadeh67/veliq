Active: **release 1.1.0+3 (T-160)** — branch `release-1.1.0`. Everything else in P15 and the iOS
manual review is closed. The owner publishes (tag + GitHub release); nothing has been pushed yet.

Status: OPEN — only the owner's real-device check and the publish commands remain (see "Open items").

## What P15 (2026-10-23) delivered

P15 "Multi-language input" is DONE and merged to `main` (2026-10-23). Summary:

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

## Release 1.1.0 (2026-10-23)

Prepared on branch `release-1.1.0`, not pushed. `pubspec.yaml` is `1.1.0+3`; `CHANGELOG.md` is new
(1.1.0 / 1.0.1 / 1.0.0); `PROJECT_SPEC.md`, `README.md` and `docs/RELEASE.md` match the shipped
behaviour; `release_notes_1.1.0.md` holds the user-facing notes. Artifacts (git-ignored) built from this
branch and signed with the upload key — verified `SHA-256 1332bc48…a651af`:

| Artifact | Size |
|---|---|
| `build/app/outputs/bundle/release/app-release.aab` | 66.5 MB |
| `app-arm64-v8a-release.apk` | 31.7 MB |
| `app-armeabi-v7a-release.apk` | 24.8 MB |
| `app-x86_64-release.apk` | 33.7 MB |

Each has a `.sha256` next to it. D-017 smoke test on `Pixel_10_Pro_XL` (arm64-v8a): uninstall of the old
debug-signed build, fresh install, launch, 10 s, zero `FATAL EXCEPTION`. `flutter analyze` clean,
244/244 tests.

## Open items

- **Owner: real-device check** — install `app-arm64-v8a-release.apk` on a physical Android phone, pick a
  gallery photo, OCR → Gemini translate, check the result card and History.
- **Owner: publish** — merge `release-1.1.0` into `main`, tag `v1.1.0`, create the GitHub release with the
  four artifacts + their `.sha256` files (commands in the session log / `docs/RELEASE.md`).
- **iOS camera** — untested on a physical iPhone (device-only, T-118 dropped).
- `PROJECT_SPEC.md` is up to date since T-160; the earlier "source language selection is deferred"
  wording is gone.
- **Upload keystore** — restored 2026-10-23 (`~/Desktop/Veliq-upload-key/Veliq-upload.jks`); the release
  build signs with it. The passwords live only in the macOS Keychain (service
  `Veliq Android upload keystore`) and must never be copied into the repository, docs or any cloud.

Earlier work through T-129 is committed; P12 shipped in `82cbb9c`; the README/docs pass in `9db21b3`; P13
(T-140) in `fa7a2e9` + `5e65b53`; P14 (T-141) ships in the v1.0.1 release; P15 (T-150…T-157) merged to
`main` in `0b83dbb`; T-158 `0b83dbb`, T-159 `9149523`, T-124 closed in `8ed21f1`; release prep on
`release-1.1.0` (`b1a4b24`, `8bae5e2`).
