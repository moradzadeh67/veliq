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
