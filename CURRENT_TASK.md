# CURRENT_TASK.md

### T-014 · [L] Pigeon bridge proof of concept (Dart <-> Swift on macOS)
Needs a strong model. Another agent may continue this task from the state below.

- Goal: `PingApi().ping('hello')` called from Dart returns `pong: hello` from Swift.
- Already DONE (do not redo):
    1. `pigeon 29.0.8` added as dev_dependency.
    2. `pigeons/messages.dart` defines `@HostApi() abstract class PingApi { String ping(String message); }`
       with outputs lib/pigeon/messages.g.dart and macos/Runner/Messages.g.swift.
    3. Both files generated. `Messages.g.swift` was added to the Runner target in Xcode
       (project.pbxproj changed). Generated names confirmed: `protocol PingApi`, `class PingApiSetup`.
- Files to change: macos/Runner/MainFlutterWindow.swift, lib/main.dart (temporary only).
- Remaining steps:
    1. Read the `protocol PingApi` block in macos/Runner/Messages.g.swift and use its EXACT method signature.
    2. In MainFlutterWindow.swift, after `RegisterGeneratedPlugins(registry: flutterViewController)` add:
       `PingApiSetup.setUp(binaryMessenger: flutterViewController.engine.binaryMessenger, api: PingHandler())`
       and at the end of the file (outside the class):
       class PingHandler: PingApi { func ping(message: String) throws -> String { return "pong: \(message)" } }
       (UNVERIFIED: adjust signature/labels to what Messages.g.swift really declares.)
    3. In lib/main.dart add `import 'pigeon/messages.g.dart';` and make main:
       Future<void> main() async { WidgetsFlutterBinding.ensureInitialized();
       debugPrint('PING -> ${await PingApi().ping('hello')}'); runApp(const VeliqApp()); }
    4. Run `flutter run -d macos`; the console must print `PING -> pong: hello`.
    5. Remove the temporary ping call and import from lib/main.dart (restore `void main() { runApp(const VeliqApp()); }`).
- Don't: no other files, no new packages, no git commands (I do git myself).
- Done when: step 4 printed the expected line, then `flutter analyze` and `flutter test` are clean.
- After done (by me): TASKS.md T-014 DONE; docs/ARCHITECTURE.md D-002 = "Pigeon verified on macOS (definition in pigeons/messages.dart, generated Dart in lib/pigeon/)".
- Status: DOING