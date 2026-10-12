# Veliq — Release and Distribution

## Status
Not an active concern. Do not do distribution work unless it is the current task.
License: MIT (see LICENSE). The repository is public.

## Current distribution
- GitHub releases, built manually with `flutter build macos`.
- Personal use: no code signing required.

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
4. No real API keys in source. Keys are entered by the user at runtime and stored in the macOS Keychain
   or an equivalent secure store (mechanism decided in T-012).
5. Git author email is a GitHub noreply address, not a private one.
6. LICENSE has the correct copyright holder name.
7. README documents required macOS permissions.
8. Verify permission flows on a clean machine or a separate macOS user account.

## Hygiene review — 2026 (T-062)

| # | Check | Result |
|---|-------|--------|
| 1 | `git ls-files` for secrets/build/IDE | PASS — no matches |
| 2 | Secret scan of working tree + history | PASS — no credentials; history clean |
| 3 | Manual review of `api_key|secret|token|password|/Users/` hits | PASS — all hits are docs or ignore-pattern text, no values |
| 4 | No real API keys in source | PASS — Veliq has no API keys by design (on-device OCR + Apple Translation) |
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

Remaining before a public release: item 8 and the GitHub About/Topics entry.
