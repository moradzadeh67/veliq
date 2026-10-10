# TASKS.md
Legend: [S] Qwen 4B can do it · [L] needs a strong model
Status: TODO | DOING | DONE | BLOCKED

## Phases
P0 Scaffold ................ DOING   (T-001, T-002)
P1 Research & decisions .... TODO   (all [L]; results go into docs/ARCHITECTURE.md)
P2 Capture MVP ............. TODO   (split into tasks after P1 handover)
P3 OCR ..................... TODO
P4 Translation ............. TODO
P5 History & settings ...... TODO
P6 Polish & release ........ TODO

## P0 — Scaffold (current)
Folders, .gitkeep and feature placeholder files are created by the setup script (not a task).

### T-001 · [S] Replace lib/main.dart with a clean placeholder
- Files: lib/main.dart
- Do: see CURRENT_TASK.md (exact code is given there)
- Done when: `flutter analyze lib/main.dart` clean
- Status: TODO

### T-002 · [S] Replace the default widget test
- Files: test/widget_test.dart
- Do: Replace the ENTIRE content with this code, copied EXACTLY:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/main.dart';

void main() {
  testWidgets('Veliq app shows placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const VeliqApp());
    expect(find.text('Veliq - Ready for development'), findsOneWidget);
  });
}
```
- Don't: Do not change lib/main.dart or pubspec.yaml. No new packages.
- Ctx: AGENTS.md, AGENTS.PROJECT.md, lib/main.dart
- Done when: `flutter test test/widget_test.dart` passes + `flutter analyze` clean
- Status: TODO

## P1 — Research & decisions (all [L]; not started)
Each task ends with: findings written to docs/ARCHITECTURE.md (decision table) and
marked VERIFIED or UNVERIFIED. No production code.

### T-010 · [L] Choose screen capture API
- Do: Verify with authoritative Apple docs + a small local test whether
      CGWindowListCreateImage is still usable on target macOS versions, or whether
      ScreenCaptureKit is required. Define Retina / multi-display coordinate rules.
- Done when: D-003 in ARCHITECTURE.md is decided, with a reproducible test note.
- Status: TODO

### T-011 · [L] Choose global shortcut approach
- Do: Compare native API vs maintained Flutter plugin; test foreground/background,
      conflicts, sleep/wake, and whether Accessibility permission is needed.
- Done when: D-004 decided; docs/MACOS_PERMISSIONS.md updated.
- Status: TODO

### T-012 · [L] Choose translation provider
- Do: Pick provider(s) for text-only translation to Persian; document cost, limits,
      privacy policy, and how API keys are stored.
- Done when: D-005 decided; docs/PRIVACY.md updated.
- Status: TODO

### T-013 · [L] Choose local storage for history/settings
- Do: Evaluate maintained options for macOS desktop; pick one.
- Done when: D-006 decided.
- Status: TODO

### T-014 · [L] Pigeon bridge proof of concept
- Do: Minimal Pigeon API (one ping method) Dart <-> Swift on macOS, working end to end.
- Done when: `flutter run -d macos` shows the round trip; setup steps written down.
- Status: TODO

## Phase handover
After P1: Architect writes docs/HANDOVER_P1.md and splits P2 into [S]/[L] tasks.
