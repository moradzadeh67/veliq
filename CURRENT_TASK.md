# CURRENT_TASK.md

Active: **release 1.2.0+4** — branch `release-1.2.0`, built on `p16-free-translation` (`247f67b`).
`main` is at `3690f46` (`v1.1.0`, pushed and released); nothing is pushed, tagged or published from
this branch yet — that is the owner's last step.

## What 1.2.0 ships (P16, DONE 2026-10-24)

| Task | What it delivered |
|---|---|
| T-164 | **Google Translate (free)** provider — no API key, default for fresh installs, existing stored providers untouched (D-020) |
| T-165 | Confidence-based OCR routing on Android: `ML_KIT_TRUST` / `MIN_ACCEPT`, pure `chooseOcrResult`, JUnit coverage (D-021) |
| T-166 | Explicit source == target fails before OCR with a readable message; release notes lost the "read correctly" overclaim |
| T-167 | D-021 in `docs/ARCHITECTURE.md`, stale `PROJECT_SPEC.md` fixed, P16 closed |
| T-168 | Tesseract only competes with a comparable amount of text (`max(10, ceil(0.3 × mlKitLen))`), thresholds retuned to 0.70 / 0.45, OCR line breaks rejoined before Google translation |

The Dart layer and the Pigeon API are unchanged by the OCR work; all routing lives in Kotlin behind
`AndroidOcrApi`.

## Verification on this branch

- `flutter analyze` — no issues.
- `flutter test` — 268/268.
- `(cd android && ./gradlew testDebugUnitTest)` — 12/12 (`OcrRoutingTest`).
- Owner's Galaxy S24 (2026-10-24, 1.1.0 build): Russian and Persian photos read correctly with an
  explicit source; `Tesseract(native): Initialized … language=rus` in logcat.
- **Not verified yet:** OCR quality on photographs of paper (curves, shadows), the 1.2.0 artifacts on a
  device, and any iOS camera run.

## Open items

1. **Next candidate — printed-Russian OCR quality.** T-168 fixed *which* result wins; the remaining
   weakness is the input image. Planned approach: run one Tesseract language per pass instead of
   `rus+fas+ara`, and preprocess the bitmap (grayscale, 2× upscale, contrast/adaptive threshold) before
   handing it to Tesseract. Cheap, stays on-device, no new dependency. Measure on the same seven test
   photos (`~/Desktop/veliq-test-photos/`) before and after.
2. **Auto-detect with non-Latin photos** — improved but not solved: ML Kit still runs first, so an
   explicit source is the reliable path for `fa`/`ar`/`ru`. Any further work should build on T-165's
   confidence signal, not on the translator's language guess (that was tried and does not work).
3. **CJK / Devanagari on Android** — still unavailable (extra models, more APK size). macOS/iOS read
   them through Apple Vision.
4. **iOS camera** — never run on a physical iPhone (T-118 dropped; simulator-only verification).
5. **Diagrams and screenshots for 1.2.0** — the owner redraws `assets/diagrams/*.svg` and retakes the
   Settings screenshots; the brief with the exact stale text is in `~/Desktop/veliq-diagram-brief.md`.

## History

- **v1.1.0** (2026-10-24, tag on `655446a`): multi-language input — 14-language catalog, Auto-detect
  source, per-platform OCR capability query, iOS Vision OCR, Android Tesseract for `fa`/`ar`/`ru`,
  detected language shown in the result and History. Per-ABI APKs + AAB, upload-key signed
  (`SHA-256 1332bc48…a651af`), emulator smoke test clean, verified on a Galaxy S24.
- **v1.0.1** (2026-10-16): `INTERNET` manifest permission and R8 keep rules for ML Kit (T-141).
- **v1.0.0** (2026-10-16): first release.
- macOS and iOS remain build-from-source.
