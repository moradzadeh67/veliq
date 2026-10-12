# CURRENT_TASK.md

### T-122 · [S] Responsive navigation for iOS (NavigationRail → NavigationBar)

- Files: lib/features/home/home_shell.dart

- Background:
  On iPhone, NavigationRail takes too much space. iOS convention is a bottom
  navigation bar. Keep NavigationRail on macOS; use Material 3 NavigationBar
  at the bottom on iOS.

- Do:
  1. Read lib/features/home/home_shell.dart first.
  2. Add `import 'package:flutter/foundation.dart';` at the top if not present.
  3. Add a private instance getter inside _HomeShellState:
       bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  4. In build(), keep the destinations list and _Destination class unchanged.
  5. Replace the single `return Scaffold(body: Row(...))` with a conditional:
     if (_isIOS) return a Scaffold whose:
       - body is SafeArea(child: destinations[_index].view)
       - bottomNavigationBar is NavigationBar(
           selectedIndex: _index,
           onDestinationSelected: (index) => setState(() => _index = index),
           destinations: built from the same destinations list using
             NavigationDestination(icon: Icon(d.icon), label: d.label),
         )
     else return the existing Scaffold(body: Row(NavigationRail, VerticalDivider,
     Expanded)) UNCHANGED.
  6. Do NOT add SafeArea to the macOS branch.

- Don't:
  - Do NOT change _Destination or the destinations list content.
  - Do NOT change any other file.
  - Do NOT add new packages.
  - Do NOT touch tests.
  - Do NOT touch TASKS.md.
  - Do NOT run git.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/features/home/home_shell.dart

- Done when:
  - flutter analyze lib/ is clean.
  - flutter test passes (all 181 tests).

- Status: TODO
