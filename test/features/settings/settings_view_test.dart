import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/settings/bloc/settings_bloc.dart';
import 'package:veliq/features/settings/settings_view.dart';
import 'package:veliq/models/language.dart';
import 'package:veliq/services/settings_repository.dart';

/// [testWidgets] pinned to macOS: on a desktop test host the default target
/// platform is Android, but this suite exercises the desktop Settings flow,
/// which still offers Apple (T-137).
void testWidgetsMac(String description, WidgetTesterCallback body) {
  testWidgets(
    description,
    body,
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

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

    /// What the fake device's OCR can read. `null` means "the test does not
    /// care" and every catalog language is reported as supported.
    late Future<Set<String>> Function()? languagesProvider;

    setUp(() {
      repository = FakeSettingsRepository();
      verifiedKeys = <String>[];
      verifyResult = null;
      languagesProvider = null;
      bloc = SettingsBloc(
        settingsRepository: repository,
        googleApiKeyVerifier: (apiKey, sourceLanguage, targetLanguage) async {
          verifiedKeys.add(apiKey);
          return verifyResult;
        },
        ocrLanguagesProvider: () {
          final provider = languagesProvider;
          if (provider == null) {
            return Future.value(
              LanguageCatalog.all.map((language) => language.code).toSet(),
            );
          }
          return provider();
        },
      );
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgetsMac('renders the translation and privacy sections', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Keep screenshots'), findsOneWidget);
    });

    testWidgetsMac('shows the persisted language names as subtitles', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        sourceLanguage: 'de',
        targetLanguage: 'fa',
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('German'), findsOneWidget);
      expect(find.text('Persian'), findsOneWidget);
    });

    testWidgetsMac('screenshots switch reflects the stored value', (
      tester,
    ) async {
      repository.stored = const AppSettings(saveScreenshots: true);

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgetsMac('toggling the switch persists the new value', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(repository.stored.saveScreenshots, isTrue);
    });

    testWidgetsMac('changing the target language persists it', (tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      // The language dropdowns are the only `DropdownButton<String>` widgets;
      // the "To" one is last.
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('German (Deutsch)').last);
      await tester.pumpAndSettle();

      expect(repository.stored.targetLanguage, equals('de'));
    });

    testWidgetsMac('an unknown persisted language code does not crash', (
      tester,
    ) async {
      repository.stored = const AppSettings(sourceLanguage: 'xx');

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('From'), findsOneWidget);
    });

    testWidgetsMac('marks the languages this device cannot read', (
      tester,
    ) async {
      languagesProvider = () async => <String>{'en', 'de', 'fa'};

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      expect(
        find.text("Not supported by this device's text recognition"),
        findsWidgets,
      );

      final items = tester
          .widgetList<DropdownMenuItem<String>>(
            find.byType(DropdownMenuItem<String>),
          )
          .toList();
      expect(
        items.firstWhere((item) => item.value == 'de').enabled,
        isTrue,
        reason: 'German is in the supported set',
      );
      expect(
        items.firstWhere((item) => item.value == 'ru').enabled,
        isFalse,
        reason: 'Russian was not reported by this device',
      );
      expect(
        items
            .firstWhere((item) => item.value == LanguageCatalog.autoCode)
            .enabled,
        isTrue,
        reason: 'auto-detect is always selectable',
      );
    });

    testWidgetsMac('offers auto-detect when the stored source is unsupported', (
      tester,
    ) async {
      repository.stored = const AppSettings(sourceLanguage: 'ru');
      languagesProvider = () async => <String>{'en', 'fa'};

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('This device cannot read Russian'), findsOneWidget);

      await tester.tap(find.text('Use auto-detect'));
      await tester.pumpAndSettle();

      expect(repository.stored.sourceLanguage, equals('auto'));
    });

    testWidgetsMac('no notice when the stored source is supported', (
      tester,
    ) async {
      repository.stored = const AppSettings(sourceLanguage: 'de');
      languagesProvider = () async => <String>{'en', 'de'};

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('This device cannot read'), findsNothing);
    });

    testWidgetsMac('warns when source and target are the same', (tester) async {
      repository.stored = const AppSettings(
        sourceLanguage: 'de',
        targetLanguage: 'de',
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(
        find.text('Source and target language are the same.'),
        findsOneWidget,
      );
    });

    testWidgetsMac('does not warn when the source is auto-detect', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        sourceLanguage: LanguageCatalog.autoCode,
        targetLanguage: 'fa',
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(
        find.text('Source and target language are the same.'),
        findsNothing,
      );
    });

    testWidgetsMac('shows the Google Translate (free) provider by default', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Google Translate (free, no key)'), findsWidgets);
    });

    testWidgetsMac('switching the provider to Apple persists it', (
      tester,
    ) async {
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

    testWidgetsMac('shows the API key field while Google Gemini is selected', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Google AI API key'), findsOneWidget);
      expect(find.text('No API key yet'), findsOneWidget);
    });

    testWidgetsMac(
      'hides the API key field for the Google Translate provider',
      (tester) async {
        repository.stored = const AppSettings(
          translationProvider: TranslationProvider.googleTranslate,
        );

        await _pumpView(tester, bloc);
        await tester.pumpAndSettle();

        expect(find.text('Google AI API key'), findsNothing);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgetsMac('hides the warning once a key is stored', (tester) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
        googleApiKey: 'test-api-key',
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('No API key yet'), findsNothing);
    });

    testWidgetsMac('Enter in the API key field saves and tests (T-129)', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.stored.googleApiKey, equals('test-api-key'));
      expect(verifiedKeys, equals(['test-api-key']));
      expect(find.text('Connected. The API key works.'), findsOneWidget);
    });

    testWidgetsMac('Save & test stores the key and reports success', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();

      expect(repository.stored.googleApiKey, equals('test-api-key'));
      expect(verifiedKeys, equals(['test-api-key']));
      expect(find.text('Connected. The API key works.'), findsOneWidget);
    });

    testWidgetsMac('Save & test reports why Google rejected the key', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );
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

    testWidgetsMac('the verdict clears once the key is edited again', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );

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

    testWidgetsMac('a successful test clears the no-key warning', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.google,
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();
      expect(find.text('No API key yet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.tap(find.text('Save & test'));
      await tester.pumpAndSettle();

      expect(find.text('No API key yet'), findsNothing);
    });
  });

  group('SettingsView Android Widget Tests (T-137)', () {
    late FakeSettingsRepository repository;
    late SettingsBloc bloc;

    setUp(() {
      repository = FakeSettingsRepository();
      bloc = SettingsBloc(settingsRepository: repository);
    });

    tearDown(() {
      bloc.dispose();
    });

    Future<void> pumpAndroid(WidgetTester tester) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();
    }

    testWidgets('offers no Apple in the provider dropdown on Android', (
      tester,
    ) async {
      await pumpAndroid(tester);

      expect(find.byType(DropdownButton<TranslationProvider>), findsOneWidget);
      expect(find.text('Apple (on-device)'), findsNothing);
    });

    testWidgets('a stored Apple choice shows the notice and stays usable', (
      tester,
    ) async {
      repository.stored = const AppSettings(
        translationProvider: TranslationProvider.apple,
      );

      await pumpAndroid(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.text('Android does not support Apple Translation'),
        findsOneWidget,
      );
      expect(find.text('Google Translate (free, no key)'), findsWidgets);
    });

    testWidgets(
      '"Use Google Translate" persists the switch and clears the notice',
      (tester) async {
        repository.stored = const AppSettings(
          translationProvider: TranslationProvider.apple,
        );

        await pumpAndroid(tester);
        await tester.tap(find.text('Use Google Translate'));
        await tester.pumpAndSettle();

        expect(
          repository.stored.translationProvider,
          equals(TranslationProvider.googleTranslate),
        );
        expect(
          find.text('Android does not support Apple Translation'),
          findsNothing,
        );
      },
    );

    testWidgets('the notice is absent when Google Translate is stored', (
      tester,
    ) async {
      await pumpAndroid(tester);

      expect(
        find.text('Android does not support Apple Translation'),
        findsNothing,
      );
    });
  });

  group('Key storage copy', () {
    late FakeSettingsRepository repository;
    late SettingsBloc bloc;

    setUp(() {
      repository = FakeSettingsRepository(
        initial: const AppSettings(
          translationProvider: TranslationProvider.google,
        ),
      );
      bloc = SettingsBloc(settingsRepository: repository);
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgetsMac('names the Keychain, not the app preferences', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining("this device's Keychain"), findsOneWidget);
      expect(find.textContaining('app preferences'), findsNothing);
    });
  });

  group('SettingsView iOS Copy Tests', () {
    late FakeSettingsRepository repository;
    late SettingsBloc bloc;

    setUp(() {
      repository = FakeSettingsRepository();
      bloc = SettingsBloc(settingsRepository: repository);
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgets('privacy copy says "this device", never "this Mac"', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('stay on this device'), findsOneWidget);
      expect(find.textContaining('this Mac'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('SettingsView Android Copy Tests (T-138)', () {
    late FakeSettingsRepository repository;
    late SettingsBloc bloc;

    setUp(() {
      repository = FakeSettingsRepository(
        initial: const AppSettings(
          translationProvider: TranslationProvider.google,
        ),
      );
      bloc = SettingsBloc(settingsRepository: repository);
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgets('privacy and key copy say "this device", not "this Mac"', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('stay on this device'), findsOneWidget);
      expect(
        find.textContaining('Stored securely in an encrypted store'),
        findsOneWidget,
      );
      expect(find.textContaining('this Mac'), findsNothing);
    });
  });
}
