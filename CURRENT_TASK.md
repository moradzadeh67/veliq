# CURRENT_TASK.md

### T-120 · [S] Add path_provider dependency

- Files: pubspec.yaml

- Do:
  1. Read pubspec.yaml first.
  2. In the `dependencies:` block, after the line `http: ^1.2.2`, add exactly this new line:
     path_provider: ^2.1.5
  3. Do not reorder existing lines. Do not remove anything. Do not change other versions.
  4. Run: flutter pub get
  5. If pub get fails, STOP and report the exact error.

- Don't:
  - Do NOT add any other dependency.
  - Do NOT edit pubspec.lock by hand.
  - Do NOT touch any other file.
  - Do NOT run git.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, pubspec.yaml

- Done when:
  - flutter pub get succeeds.
  - grep "path_provider" pubspec.yaml shows exactly one line.
  - grep "path_provider" pubspec.lock shows it was resolved.

- Status: TODO