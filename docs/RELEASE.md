# Veliq — Release and Distribution

## Status
Active as of 2026-10-16: the public GitHub releases ship a **signed** Android APK — `v1.0.0` (first
release) and `v1.0.1` (Android release-build hotfix). License: MIT (see LICENSE). The repository is
public, has a description, 16 topics and a GitHub Pages site (https://moradzadeh67.github.io/veliq/).

## Current distribution
- **GitHub releases** — `v1.0.1` (2026-10-16, Android release-build hotfix) and `v1.0.0` (2026-10-16,
  first release) each ship `app-release.apk` (+ `.sha256`) built from this repository and signed with
  the project upload key (see "Android release signing" below).
- macOS: build from source (`flutter build macos`); no code signing / notarization yet.
- iOS is **not distributed yet** (only `flutter build ios --no-codesign` is run, as a build check).
  The Xcode target carries the real bundle id `com.moradzadeh67.veliq` and the D-013 iOS 16.0 floor
  (T-126, 2026-10-14).
- Android: signed APK **and** AAB are reproducible locally; there is still **no store listing**
  (Google Play was explicitly declined by the owner on 2026-10-16 — distribution stays on GitHub).

## Future (nothing decided)
- Code signing and notarization for Gatekeeper.
- Android store distribution (Play/F-Droid). Note for any future F-Droid attempt: ML Kit is a
  proprietary bundled dependency, so the app would not qualify as fully free software.
- Mac App Store consideration: do a fresh privacy and entitlement review against
  Apple's requirements at that time. Do not assume today's configuration is suitable.

## Android release signing (2026-10-16)

- **Upload key**: `Veliq-upload.jks` (PKCS12, alias `veliq`, RSA 2048, validity 10000 days).
  It lives **outside the repository** at `~/Desktop/Veliq-upload-key/Veliq-upload.jks` on the owner's
  machine; a complete backup (keystore + `key.properties` + the passwords, documented in a README)
  is the zipped folder `~/Desktop/Veliq-upload-key.zip`.
- **Wiring**: `android/key.properties` (git-ignored — present in both `.gitignore` files) points Gradle
  at the keystore. `android/app/build.gradle.kts` reads it when it exists and otherwise falls back to
  the **debug** signing config, so a fresh clone still builds.
- **Certificate** (verified with `apksigner verify --print-certs`):
  `CN=Mohammadreza Moradzadeh, OU=Mobile, O=Veliq, C=IR`,
  SHA-256 `1332bc480e4fac26acab2ad82db950501dc9643604af2e0429b28668c1a651af`.
- **Artifacts**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
  (66 MB); `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` (~84 MB,
  signing verified). Both are git-ignored build output; the APK is attached to the GitHub releases.
- **Never** commit the keystore, `key.properties` or the passwords. Losing the upload key means no
  further updates for `com.moradzadeh67.veliq`.


## Android release build notes: R8 / ProGuard (2026-10-16)

Android `--release` builds run **R8** (minify + resource shrinking, full mode) by default. Because the
bundled ML Kit recognizer discovers and instantiates its components **reflectively**, its internals
must be kept: the consumer rules the ML Kit AARs ship only keep native method names and proto fields,
which is not enough. Without keep rules R8 stripped/renamed those classes and the app crashed on
launch inside `MainActivity.configureFlutterEngine()` → `TextRecognition.getClient()`.

- **Rules file**: `android/app/proguard-rules.pro` — `-keep class com.google.mlkit.** { *; }`,
  `-keep class com.google.android.gms.internal.mlkit_** { *; }`,
  `-keep class com.google.android.libraries.vision.** { *; }`,
  `-keep class com.google.android.gms.internal.vision.** { *; }`, plus matching `-dontwarn` lines.
- **Wiring**: `android/app/build.gradle.kts`, release build type →
  `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.
- **Diagnosis aid**: R8 writes `build/app/outputs/mapping/release/mapping.txt`; deobfuscate a release
  crash trace with it before guessing at the cause.
- **Also required for the network**: `android/app/src/main/AndroidManifest.xml` must declare
  `android.permission.INTERNET` — Flutter only adds it to the debug/profile manifests, never to
  `main`, so a release build otherwise cannot reach the Gemini API.
- **Smoke test**: debug builds do **not** run R8, so always launch a `--release` APK after changing
  OCR code, dependencies or build configuration. Both defects above were release-only and invisible
  in debug.

## Public repository hygiene (check BEFORE the first public push and before every release)
1. `git ls-files` contains no secrets, keys, certificates, provisioning profiles, .env files,
   build output, IDE folders, backups or logs.
2. Secrets scan of the working tree AND full git history (e.g. gitleaks). Any hit = stop;
   deleting the file later does not remove it from history.
3. `grep -rniE "api[_-]?key|secret|token|password|/Users/" .` reviewed by hand (excluding build/ and .dart_tool/).
4. No real API keys in source. Keys are entered by the user at runtime and stored in the Keychain
   (macOS, via `flutter_secure_storage`, D-009) or an equivalent secure store (mechanism decided in T-012).
5. Git author email is a GitHub noreply address, not a private one.
6. LICENSE has the correct copyright holder name.
7. README documents required permissions (macOS Screen Recording, iOS camera, Android camera).
8. Verify permission flows on a clean machine or a separate macOS user account.

## Hygiene review — 2026 (T-062)

| # | Check | Result |
|---|-------|--------|
| 1 | `git ls-files` for secrets/build/IDE | PASS — no matches |
| 2 | Secret scan of working tree + history | PASS — no credentials; history clean |
| 3 | Manual review of `api_key|secret|token|password|/Users/` hits | PASS — all hits are docs or ignore-pattern text, no values |
| 4 | No real API keys in source | PASS — as of T-062 Veliq shipped no keys by design (on-device OCR + Apple Translation). Since the Gemini migration (T-064, commit 6f4d048) users supply their own key at runtime; re-verified in the T-071 table below (only the UI hint `'AIza...'` is in the source). |
| 5 | Git author email | PASS — `139646005+moradzadeh67@users.noreply.github.com` |
| 6 | LICENSE copyright holder | PASS — `Copyright (c) 2026 moradzadeh67` |
| 7 | README documents macOS permissions | PASS — added the Screen Recording section and macOS 26 translation requirement |
| 8 | Clean-machine permission verification | **TODO — not done**; needs a separate macOS user account |
| — | Local agent/IDE artifacts | FIXED in T-062 — `*.artifact.md` and `.aiexclude` added to `.gitignore` |

## Hygiene review — 2026-10-12 (T-071)

| # | Check | Result |
|---|-------|--------|
| 1 | `git ls-files` for secrets/build/IDE | PASS — no matches; `xcuserdata`, `Flutter/ephemeral` and `Pods/` confirmed ignored, not tracked |
| 2 | Secrets scan of full git history | PASS — gitleaks 8.30.1, 32 commits, `no leaks found` |
| 3 | Manual review of `api_key|secret|token|password|/Users/` hits | PASS — 1,807 hits reviewed: identifiers, URLs, policy docs, ignore patterns and synthetic test values (`test-api-key`, `key-1`, `legacy-key`); no real values and no personal `/Users/` paths in tracked files |
| 4 | No real API keys in source | PASS — only the UI hint `'AIza...'` |
| 5 | Git author email | PASS — `139646005+moradzadeh67@users.noreply.github.com` |
| 6 | LICENSE copyright holder | PASS — `Copyright (c) 2026 moradzadeh67` |
| 7 | README documents macOS permissions | PASS — dedicated "Permissions" section (Screen Recording only) |
| 8 | Clean-machine permission verification | **TODO — not done**; needs a separate macOS user account (user's task) |

Also outstanding for the user: GitHub repository **About/Topics** (browser), item 8 above.

## Hygiene review — 2026-10-12 (T-125, app icons)

| # | Check | Result |
|---|-------|--------|
| 1 | `git ls-files` for secrets/build/IDE | PASS — 22 app-icon PNGs added under the two `Assets.xcassets/AppIcon.appiconset` folders, plus `assets/app_icon/` (master PNG, shell script, README); no build output tracked |
| 2 | Secrets scan of the new files | PASS — new files are PNGs, a shell script and Markdown; no credentials, no `/Users/` paths |
| 4 | No real API keys in source | PASS — unchanged |
| 7 | README documents required permissions | PASS — now covers macOS Screen Recording **and** the iOS camera |
| — | `.gitignore` syntax fix | FIXED — the line `assets/app_icon/veliq.icns # comment` did **not** ignore anything: gitignore has no trailing comments, so the whole line became the pattern. The comment was moved to its own line. **Resolved (2026-10-14)**: the ignore line was then removed entirely — `veliq.icns` is deliberately tracked as the distributable icon artifact, regenerated by the SVG pipeline (D-015 rework / T-128). |

## Hygiene review — 2026-10-16 (T-141, Android release hotfix)

| # | Check | Result |
|---|-------|--------|
| 1 | `git ls-files` for secrets/build/IDE | PASS — only `android/app/proguard-rules.pro` added (plain text keep rules); `android/key.properties`, the keystore and `build/` stay ignored |
| 2 | Secrets scan of the new files | PASS — no credentials, no `/Users/` paths; the file contains ProGuard directives only |
| 4 | No real API keys in source | PASS — unchanged |
| — | Release smoke test | ADDED to the process: launch a `--release` APK after any OCR/dependency/build change (R8 only runs in release; see the R8/ProGuard section above) |

## Outstanding before a public release
1. Item 8 above (clean-machine / separate-user-account permission verification) — user's task.
2. ~~GitHub repository About/Topics~~ — **DONE 2026-10-16**: description + 16 topics set, homepage
   points at the Pages site.
3. **iOS**: the T-124 remainder on the simulator (cancel path, revoked-permission message, history
   across restart). Navigation, screens and the gallery picker are simulator-verified (2026-10-14);
   camera capture is device-only (no device in scope, T-118 dropped). On the owner's current Mac the
   bundled `Simulator.app` is broken (unsigned binary, exits immediately), so this stays open until a
   repaired simulator or a physical device is available. A headless alternative (`idb`) was evaluated on
   2026-10-16 and dropped as well: `idb-companion` is no longer published in Homebrew.

## Released
- `v1.0.1` (2026-10-16): Android release-build hotfix — the missing `INTERNET` manifest permission and
  the R8 keep rules for ML Kit (T-141). Signed Android APK + `.sha256` attached.
- `v1.0.0` (2026-10-16): first release. Signed Android APK + `.sha256` attached.
- macOS/iOS remain build-from-source.
