# CURRENT_TASK.md
(Copy of the single active task from TASKS.md. Replace the content for each new task.
Source of truth for status is TASKS.md.)

### T-001 · [S] Replace lib/main.dart with a clean placeholder
- Files: lib/main.dart
- Do: Replace the ENTIRE content of lib/main.dart with the code below, copied EXACTLY.
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const VeliqApp());
}

class VeliqApp extends StatelessWidget {
  const VeliqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veliq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veliq'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Veliq - Ready for development'),
      ),
    );
  }
}
```
- Don't: Do not change any other file (test/widget_test.dart will fail until T-002; that is expected).
        Do not rename classes. Do not touch pubspec.yaml. No new packages.
- Ctx: AGENTS.md, AGENTS.PROJECT.md
- Done when: `flutter analyze lib/main.dart` reports no issues.
- Status: TODO
