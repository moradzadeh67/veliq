# Veliq — Release and Distribution

## Status
Not an active concern. Do not do distribution work unless it is the current task.
License: MIT (see LICENSE). The repository is public.

## Current distribution
- GitHub releases, built manually with `flutter build macos`.
- Personal use: no code signing required.
- iOS is **not distributed yet** (only `flutter build ios --no-codesign` is run, as a build check).
  The Xcode target now carries the real bundle id `com.moradzadeh67.veliq` and the D-013 iOS 16.0
  floor (T-126, 2026-10-14).

## Future (nothing decided)
- Code signing and notarization for Gatekeeper.
- Mac App Store consideration: do a fresh privacy and entitlement review against
  Apple's requirements at that time. Do not assume today's configuration is suitable.

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
7. README documents required permissions (macOS Screen Recording, iOS camera).
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

## Outstanding before a public release
1. Item 8 above (clean-machine / separate-user-account permission verification) — user's task.
2. GitHub repository **About/Topics** (browser) — user's task.
3. **iOS**: the T-124 remainder on the simulator (cancel path, revoked-permission message, history across restart). Navigation, screens and the gallery picker are simulator-verified (2026-10-14); camera capture is device-only (no device in scope, T-118 dropped).
