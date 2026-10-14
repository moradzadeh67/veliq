import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/settings/bloc/settings_bloc.dart';
import 'package:veliq/features/settings/settings_view.dart';
import 'package:veliq/services/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings stored;

  FakeSettingsRepository({AppSettings? initial})
    : stored = initial ?? AppSettings.defaults;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

Future<void> _pumpView(WidgetTester tester, SettingsBloc bloc) async {
  // The settings list is long; give it room so nothing is clipped, which would
  // otherwise make taps and hit-tests in the lower half unreliable.
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(MaterialApp(home: SettingsView(bloc: bloc)));
}

void main() {
  group('SettingsView Widget Tests', () {
    late FakeSettingsRepository repository;
    late SettingsBloc bloc;
    late List<String> verifiedKeys;
    String? verifyResult;

    setUp(() {
      repository = FakeSettingsRepository();
      verifiedKeys = <String>[];
      verifyResult = null;
      bloc = SettingsBloc(
        settingsRepository: repository,
        googleApiKeyVerifier: (apiKey, sourceLanguage, targetLanguage) async {
          verifiedKeys.add(apiKey);
          return verifyResult;
        },
      );
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgets('renders the translation and privacy sections', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Keep screenshots'), findsOneWidget);
    });

    testWidgets('shows the persisted language names as subtitles', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        sourceLanguage: 'de',
        targetLanguage: 'fa',
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('German'), findsOneWidget);
      expect(find.text('Persian (فارسی)'), findsOneWidget);
    });

    testWidgets('screenshots switch reflects the stored value', (tester) async {
      repository.stored = const AppSettings(saveScreenshots: true);

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgets('toggling the switch persists the new value', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(repository.stored.saveScreenshots, isTrue);
    });

    testWidgets('changing the target language persists it', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      // The language dropdowns are the only `DropdownButton<String>` widgets;
      // the "To" one is last.
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('German (de)').last);
      await tester.pumpAndSettle();

      expect(repository.stored.targetLanguage, equals('de'));
    });

    testWidgets('an unknown persisted language code does not crash', (
      tester,
    ) async {
      repository.stored = const AppSettings(sourceLanguage: 'xx');

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('From'), findsOneWidget);
    });

    testWidgets('shows the Google provider by default', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Google Gemini'), findsWidgets);
    });

    testWidgets('switching the provider to Apple persists it', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<TranslationProvider>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple (on-device)').last);
      await tester.pumpAndSettle();

      expect(
        repository.stored.translationProvider,
        equals(TranslationProvider.apple),
      );
    });

    testWidgets('shows the API key field while Google is selected', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Google AI API key'), findsOneWidget);
      expect(find.text('No API key yet'), findsOneWidget);
    });

    testWidgets('hides the API key field for the Apple provider', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.apple,
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Google AI API key'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('hides the warning once a key is stored', (tester) async {
      repository.stored = const AppSettings(googleApiKey: 'test-api-key');

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('No API key yet'), findsNothing);
    });

    testWidgets('Enter in the API key field saves and tests (T-129)', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.stored.googleApiKey, equals('test-api-key'));
      expect(verifiedKeys, equals(['test-api-key']));
      expect(find.text('Connected. The API key works.'), findsOneWidget);
    });

    testWidgets('Save & test stores the key and reports success', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();

      expect(repository.stored.googleApiKey, equals('test-api-key'));
      expect(verifiedKeys, equals(['test-api-key']));
      expect(find.text('Connected. The API key works.'), findsOneWidget);
    });

    testWidgets('Save & test reports why Google rejected the key', (
      tester,
    ) async {
      verifyResult = 'The Generative Language API is not enabled.';

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();

      expect(
        find.text('The Generative Language API is not enabled.'),
        findsOneWidget,
      );
      expect(find.text('Connected. The API key works.'), findsNothing);
    });

    testWidgets('the verdict clears once the key is edited again', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();
      expect(find.text('Connected. The API key works.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test-api-key-2');
      await tester.pumpAndSettle();

      expect(find.text('Connected. The API key works.'), findsNothing);
    });

    testWidgets('a successful test clears the no-key warning', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();
      expect(find.text('No API key yet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();

      expect(find.text('No API key yet'), findsNothing);
    });
  });
}
