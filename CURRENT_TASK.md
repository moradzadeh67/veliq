cat > CURRENT_TASK.md << 'EOF'
# CURRENT_TASK.md

### T-123 · [S] SafeArea + wrap for iPhone layout

- Files: lib/features/translation/translate_view.dart

- Background:
  The TranslateView Scaffold already has an AppBar (top inset handled).
  But the body has no SafeArea, so on iPhone with a home indicator, content
  can sit under the indicator. Also, _IdleState uses a Row for the two
  action buttons; on narrow iPhones (SE, mini) they can overflow.

- Do:
  1. Read lib/features/translation/translate_view.dart first.
  2. In the build method, wrap the existing body (the StreamBuilder) with:
     SafeArea(top: false, child: <existing StreamBuilder>)
     Do NOT set top: true (AppBar already handles that).
  3. In _IdleState.build, change the two-button Row to a Wrap:
     Wrap(
     alignment: WrapAlignment.center,
     spacing: 12,
     runSpacing: 8,
     children: [ FilledButton.icon(...Pick...), FilledButton.icon(...Take...) ],
     )
     Remove the SizedBox(width: 12) between the two buttons (spacing covers it).
     Do NOT change the single "Select region" button branch.
  4. Do NOT change any other widget (Progress, Failure, Result) in this task.

- Don't:
  - Do NOT add SafeArea to Scaffold (AppBar already handles it).
  - Do NOT change any other file.
  - Do NOT touch tests.
  - Do NOT touch TASKS.md.
  - Do NOT run git.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/features/translation/translate_view.dart

- Done when:
  - flutter analyze lib/ is clean.
  - flutter test passes (all 181 tests).
  - flutter build ios --no-codesign succeeds.

- Status: TODO
  EOF