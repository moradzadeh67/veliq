import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/settings/bloc/settings_bloc.dart';
import 'package:veliq/features/settings/bloc/settings_state.dart';
import 'package:veliq/services/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings stored;
  bool shouldThrow = false;
  int saveCount = 0;

  InMemorySettingsRepository({AppSettings? initial})
    : stored = initial ?? AppSettings.defaults;

  @override
  Future<AppSettings> load() async {
    if (shouldThrow) throw Exception('load failed');
    return stored;
  }

  @override
  Future<void> save(AppSettings settings) async {
    saveCount++;
    if (shouldThrow) throw Exception('save failed');
    stored = settings;
  }
}

void main() {
  group('SettingsBloc Tests', () {
    late InMemorySettingsRepository repository;
    late SettingsBloc settingsBloc;
    late List<String> verifiedKeys;
    String? verifyResult;

    setUp(() {
      repository = InMemorySettingsRepository();
      verifiedKeys = <String>[];
      verifyResult = null;
      settingsBloc = SettingsBloc(
        settingsRepository: repository,
        googleApiKeyVerifier: (apiKey, sourceLanguage, targetLanguage) async {
          verifiedKeys.add('$apiKey|$sourceLanguage|$targetLanguage');
          return verifyResult;
        },
      );
    });

    tearDown(() {
      settingsBloc.dispose();
    });

    test('initial state is SettingsInitial', () {
      expect(settingsBloc.currentState, isA<SettingsInitial>());
    });

    test('settings getter returns defaults before load', () {
      expect(settingsBloc.settings, equals(AppSettings.defaults));
    });

    test('load emits SettingsLoaded with persisted settings', () async {
      repository.stored = const AppSettings(
        sourceLanguage: 'fr',
        targetLanguage: 'fa',
      );

      await settingsBloc.load();

      expect(settingsBloc.currentState, isA<SettingsLoaded>());
      expect(settingsBloc.settings.sourceLanguage, equals('fr'));
    });

    test('load emits SettingsFailure when the repository throws', () async {
      repository.shouldThrow = true;

      await settingsBloc.load();

      expect(settingsBloc.currentState, isA<SettingsFailure>());
    });

    test('update persists settings and updates state', () async {
      const updated = AppSettings(sourceLanguage: 'de', targetLanguage: 'fa');

      await settingsBloc.update(updated);

      expect(repository.stored, equals(updated));
      expect(settingsBloc.settings, equals(updated));
    });

    test('setTargetLanguage changes only the target language', () async {
      await settingsBloc.load();
      final before = settingsBloc.settings;

      await settingsBloc.setTargetLanguage('de');

      expect(settingsBloc.settings.targetLanguage, equals('de'));
      expect(
        settingsBloc.settings.sourceLanguage,
        equals(before.sourceLanguage),
      );
    });

    test('setSourceLanguage changes only the source language', () async {
      await settingsBloc.load();

      await settingsBloc.setSourceLanguage('it');

      expect(settingsBloc.settings.sourceLanguage, equals('it'));
      expect(
        settingsBloc.settings.targetLanguage,
        equals(AppSettings.defaultTargetLanguage),
      );
    });

    test('setSaveScreenshots toggles the retention flag', () async {
      await settingsBloc.load();
      expect(settingsBloc.settings.saveScreenshots, isFalse);

      await settingsBloc.setSaveScreenshots(true);

      expect(settingsBloc.settings.saveScreenshots, isTrue);
      expect(repository.stored.saveScreenshots, isTrue);
    });

    test('update emits SettingsFailure when persistence throws', () async {
      repository.shouldThrow = true;

      await settingsBloc.update(const AppSettings(sourceLanguage: 'de'));

      expect(settingsBloc.currentState, isA<SettingsFailure>());
    });

    test('update reflects the new value in state immediately', () async {
      final states = <SettingsState>[];
      final subscription = settingsBloc.stateStream.listen(states.add);

      await settingsBloc.setTargetLanguage('de');
      await subscription.cancel();

      expect(states.first, isA<SettingsLoaded>());
      expect((states.first as SettingsLoaded).settings.targetLanguage, 'de');
    });

    test('testGoogleApiKey returns null when the key works', () async {
      await settingsBloc.load();

      expect(await settingsBloc.testGoogleApiKey('AIza-1'), isNull);
      expect(verifiedKeys, equals(['AIza-1|en|fa']));
    });

    test('testGoogleApiKey checks against the configured pair', () async {
      await settingsBloc.load();
      await settingsBloc.setTargetLanguage('de');

      await settingsBloc.testGoogleApiKey('AIza-1');

      expect(verifiedKeys, equals(['AIza-1|en|de']));
    });

    test('testGoogleApiKey surfaces the verifier message', () async {
      verifyResult = 'The Cloud Translation API is not enabled';

      expect(
        await settingsBloc.testGoogleApiKey('AIza-1'),
        equals('The Cloud Translation API is not enabled'),
      );
    });

    test('testGoogleApiKey explains when no verifier is wired', () async {
      final unwired = SettingsBloc(settingsRepository: repository);
      addTearDown(unwired.dispose);

      expect(
        await unwired.testGoogleApiKey('AIza-1'),
        contains('not available'),
      );
    });
  });
}
