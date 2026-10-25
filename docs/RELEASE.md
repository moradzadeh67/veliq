# Veliq — Release and Distribution

## Status
Active as of 2026-10-25: the public GitHub releases ship **signed** Android APKs — `v1.2.0` (current:
keyless Google Translate, confidence-routed Android OCR), `v1.1.0` (multi-language input), `v1.0.1`
(Android release-build hotfix) and `v1.0.0` (first release). License:
MIT (see LICENSE). The repository is public, has a description, 16 topics and a GitHub Pages site
(https://moradzadeh67.github.io/veliq/).

## Current distribution
- **GitHub releases** — `v1.2.0` (2026-10-25, free translation + safer Android OCR) and `v1.1.0`
  (2026-10-24, multi-language input) ship per-ABI APKs and an AAB built
  from this repository and signed with the project upload key (see "Android release signing" below):
  `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`
  (each with a `.sha256`) plus `app-release.aab`. `v1.0.1` (2026-10-16) and `v1.0.0` (2026-10-16) each
  ship the single universal `app-release.apk` (+ `.sha256`).
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
  machine, together with a zipped copy of that folder and a README describing how it is wired.
- **Passwords**: they are **not** in the repository, in this documentation, in the backed-up folder or
  in its README/zip. On the owner's machine they live only in the macOS Keychain as generic passwords
  under the service name `Veliq Android upload keystore` (accounts `storePassword` and `keyPassword`);
  `android/key.properties` is the only file that materialises them for Gradle. Read one with
  `security find-generic-password -s "Veliq Android upload keystore" -a storePassword -w`.
- **Wiring**: `android/key.properties` (git-ignored — present in both `.gitignore` files) points Gradle
  at the keystore. `android/app/build.gradle.kts` reads it when it exists and otherwise falls back to
  the **debug** signing config, so a fresh clone still builds.
- **Certificate** (verified with `apksigner verify --print-certs`):
  `CN=Mohammadreza Moradzadeh, OU=Mobile, O=Veliq, C=IR`,
  SHA-256 `1332bc480e4fac26acab2ad82db950501dc9643604af2e0429b28668c1a651af`.
- **Artifacts**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
  (1.1.0: 78.6 MB, which includes the bundled Tesseract models);
  `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` (universal, v1.0.x
  releases); from 1.1.0 `flutter build apk --release --split-per-abi` →
  `app-arm64-v8a-release.apk` (41.9 MB), `app-armeabi-v7a-release.apk` (33.0 MB) and
  `app-x86_64-release.apk` (44.3 MB). All are
  git-ignored build output; the AAB and the per-ABI APKs are attached to the GitHub release.
- **Never** commit the keystore, `key.properties` or the passwords — and never copy them into docs,
  issues, release notes, CI logs or any cloud service. Losing the upload key means no further updates
  for `com.moradzadeh67.veliq`; treating the passwords as portable is what leaks them.


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

## Release procedure (per release, from 1.2.0)

Everything below is run locally by the owner; nothing is uploaded by an agent. No step prints or copies
the keystore, `android/key.properties` or a password.

1. **Pre-flight** on the release branch: `flutter analyze` (zero issues), `flutter test` (all green),
   `(cd android && ./gradlew :app:testDebugUnitTest)`, and `tool/gen_pigeon.sh` drift clean (CI enforces it).
   - **JDK version note**: Robolectric's Android SDK 36 runner needs **Java 21+**. On the owner's machine the
     system JDK is 17, so the *aggregate* Gradle run (`./gradlew testDebugUnitTest`, which also builds the
     plugins) fails inside `:shared_preferences_android` with
     `Android SDK 36 requires Java 21 (have Java 17)`. App tests pass either way; for the full run point
     `JAVA_HOME` at the JDK bundled with Android Studio — no project or system toolchain change needed:
     ```bash
     (cd android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
        ./gradlew testDebugUnitTest)
     ```
     Verified 2026-10-25 on JBR 25.0.3: 244 JVM tests (`:app` 12, plugins 232), 0 failures.
2. **Clean build** (build output is git-ignored):
   ```bash
   flutter clean && flutter pub get
   flutter build appbundle --release                          # → build/app/outputs/bundle/release/app-release.aab
   flutter build apk --release --split-per-abi                # → build/app/outputs/flutter-apk/app-*-release.apk
   ```
3. **Signing check** — every APK must report the upload certificate (D-009 / "Android release signing"):
   ```bash
   $ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs \
     build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```
   Expected SHA-256 digest: `1332bc480e4fac26acab2ad82db950501dc9643604af2e0429b28668c1a651af`.
   If a build falls back to the debug key, `android/key.properties` is missing — stop and fix that, do not
   publish.
4. **Checksums** next to each artifact (one `.sha256` per file, APKs and AAB):
   ```bash
   cd build/app/outputs/flutter-apk
   for f in app-*-release.apk; do shasum -a 256 "$f" > "$f.sha256"; done
   cd ../bundle/release && shasum -a 256 app-release.aab > app-release.aab.sha256
   ```
5. **Smoke test** (D-017): install `app-arm64-v8a-release.apk` on the emulator or a device, launch it, wait
   ~10 s, then `adb logcat -d | grep -E "FATAL EXCEPTION|AndroidRuntime"` must be empty and
   `adb shell dumpsys package com.moradzadeh67.veliq | grep versionName` must show the new version.
   `INSTALL_FAILED_UPDATE_INCOMPATIBLE` means a debug-signed build is installed: uninstall it first, then
   install the release APK (it is upload-key signed).
6. **Publish** (owner only):
   ```bash
   git checkout main && git merge --ff-only release-1.2.0
   git tag v1.2.0 && git push origin main --tags
   gh release create v1.2.0 \
     build/app/outputs/flutter-apk/app-arm64-v8a-release.apk{,.sha256} \
     build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk{,.sha256} \
     build/app/outputs/flutter-apk/app-x86_64-release.apk{,.sha256} \
     build/app/outputs/bundle/release/app-release.aab \
     --title "Veliq 1.2.0" --notes-file release_notes_1.2.0.md
   ```
7. **Post-release:** confirm `Analyze & test` and the Pages deployment are green, then update
   `CURRENT_TASK.md` with what shipped.

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

## Release v1.1.0 — published 2026-10-24
- Tag `v1.1.0` on `655446a`; GitHub release with `app-arm64-v8a-release.apk` (41.9 MB),
  `app-armeabi-v7a-release.apk` (33.0 MB) and `app-x86_64-release.apk` (44.3 MB), each with a `.sha256`,
  plus `app-release.aab` (78.6 MB). Signed with the upload key (`1332bc48…a651af`) and smoke-tested on
  `Pixel_10_Pro_XL` (zero `FATAL EXCEPTION`). The owner also verified Persian and Russian OCR on a Galaxy
  S24 with the release APK. CI (`Analyze & test`) and Pages both green.
- Follow-up for the next release: better printed-Russian OCR (one Tesseract language per run plus image
  preprocessing), CJK/Devanagari models on Android. Auto-detect with a Persian/Arabic/Russian photo is no
  longer a known defect: T-165/T-168 route it by confidence and refuse an unreadable photo instead of
  showing gibberish (the Latin model still runs first, so an explicit source remains the most reliable).

## Outstanding before a public release
1. Item 8 above (clean-machine / separate-user-account permission verification) — user's task.
2. ~~GitHub repository About/Topics~~ — **DONE 2026-10-16**: description + 16 topics set, homepage
   points at the Pages site.
3. ~~**iOS**: the T-124 remainder on the simulator~~ — **DONE 2026-10-23**: cancel path, history across
   restart and the first Vision OCR run verified on the iOS 26.5 iPhone simulator (Xcode 27 ships
   **Device Hub** instead of `Simulator.app`; the earlier "broken simulator" diagnosis was wrong).
   Camera capture stays device-only (T-118 dropped) and has never been run on a physical iPhone.

## Released
- `v1.2.0` (2026-10-25): free translation + safer Android OCR — keyless Google Translate default, confidence-based
  Android OCR routing (ML Kit ≥0.70 / competitor + explicit), line rejoin before translation, same-lang guard.
  Per-ABI APKs (`.sha256` each) + AAB (78.6 MB). Signed (`1332bc48…a651af`). Smoke-tested on device — pass.
  Aggregate Gradle (`./gradlew testDebugUnitTest`) verified on JBR 25 / Java 21: 244 JVM tests, 0 failures.
  Published: tag `v1.2.0`, GitHub release (3 APK + 3 .sha256 + AAB + AAB.sha256), CI `Analyze & test` + Pages green.
- `v1.1.0` (2026-10-24): multi-language input — 14-language source catalog with Auto-detect, per-platform
  OCR capability query, an iOS Vision OCR backend, the source language Gemini detects shown in the result
  and History, and the Settings/iOS wording fixes. Per-ABI APKs (`.sha256` each) + AAB.
- `v1.0.1` (2026-10-16): Android release-build hotfix — the missing `INTERNET` manifest permission and
  the R8 keep rules for ML Kit (T-141). Signed Android APK + `.sha256` attached.
- `v1.0.0` (2026-10-16): first release. Signed Android APK + `.sha256` attached.
- macOS/iOS remain build-from-source.
