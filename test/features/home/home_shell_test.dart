import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/history/bloc/history_bloc.dart';
import 'package:veliq/features/home/home_shell.dart';
import 'package:veliq/features/settings/bloc/settings_bloc.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/history_repository.dart';
import 'package:veliq/services/settings_repository.dart';

class _FakeHistoryRepository implements HistoryRepository {
  final List<TranslationEntry> entries = <TranslationEntry>[];

  @override
  Future<List<TranslationEntry>> load() async => List.of(entries);

  @override
  Future<void> add(TranslationEntry entry) async => entries.add(entry);

  @override
  Future<void> delete(String id) async =>
      entries.removeWhere((e) => e.id == id);

  @override
  Future<void> clear() async => entries.clear();
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

void main() {
  group('HomeShell Widget Tests', () {
    late HistoryBloc historyBloc;
    late SettingsBloc settingsBloc;

    setUp(() {
      historyBloc = HistoryBloc(historyRepository: _FakeHistoryRepository());
      settingsBloc = SettingsBloc(
        settingsRepository: _FakeSettingsRepository(),
      );
    });

    tearDown(() {
      historyBloc.dispose();
      settingsBloc.dispose();
    });

    Future<void> pumpShell(WidgetTester tester) async {
      // The settings list is long; a taller surface keeps every tile built so
      // assertions in the lower half of the list are reliable.
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            historyBloc: historyBloc,
            settingsBloc: settingsBloc,
            translateView: const Center(child: Text('Translate placeholder')),
          ),
        ),
      );
    }

    testWidgets('shows all three navigation destinations', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('starts on the translate destination', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      expect(find.text('Translate placeholder'), findsOneWidget);
    });

    testWidgets('tapping History opens the history view', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('tapping Settings opens the settings view', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Keep screenshots'), findsOneWidget);
    });

    testWidgets('returning to Translate restores the workflow view', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      expect(find.text('Translate placeholder'), findsOneWidget);
    });

    testWidgets('Cmd+1/2/3 switch tabs without the mouse (T-129)', (
      tester,
    ) async {
      Future<void> pressCmd(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyDownEvent(key);
        await tester.sendKeyUpEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pumpAndSettle();
      }

      await pumpShell(tester);
      await tester.pumpAndSettle();

      await pressCmd(LogicalKeyboardKey.digit2);
      expect(find.text('No history yet'), findsOneWidget);

      await pressCmd(LogicalKeyboardKey.digit3);
      expect(find.text('Keep screenshots'), findsOneWidget);

      await pressCmd(LogicalKeyboardKey.digit1);
      expect(find.text('Translate placeholder'), findsOneWidget);
    });

    testWidgets('tab shortcuts survive a translate view that focuses itself', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            historyBloc: historyBloc,
            settingsBloc: settingsBloc,
            // Mimics the real app, where TranslateView nests inside HomeShell
            // and brings its own focus + shortcuts.
            translateView: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
                    () {},
              },
              child: const Focus(
                autofocus: true,
                child: Center(child: Text('Translate placeholder')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(find.text('No history yet'), findsOneWidget);
    });
  });
}
