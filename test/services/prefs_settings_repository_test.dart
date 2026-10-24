import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veliq/services/keychain_api_key_store.dart';
import 'package:veliq/services/prefs_settings_repository.dart';
import 'package:veliq/services/settings_repository.dart';

/// In-memory fake for [ApiKeyStore], used in tests.
class FakeApiKeyStore implements ApiKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String key) async {
    value = key;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

void main() {
  group('AppSettings', () {
    test('defaults are auto -> fa with screenshots off', () {
      const settings = AppSettings.defaults;

      expect(settings.sourceLanguage, equals('auto'));
      expect(settings.targetLanguage, equals('fa'));
      expect(settings.saveScreenshots, isFalse);
    });

    test('copyWith overrides only the provided fields', () {
      const original = AppSettings.defaults;

      final updated = original.copyWith(targetLanguage: 'de');

      expect(updated.targetLanguage, equals('de'));
      expect(updated.sourceLanguage, equals(original.sourceLanguage));
      expect(updated.saveScreenshots, equals(original.saveScreenshots));
    });

    test('equality is value-based', () {
      const a = AppSettings(sourceLanguage: 'en', targetLanguage: 'fa');
      const b = AppSettings(sourceLanguage: 'en', targetLanguage: 'fa');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('defaults select the googleTranslate provider without a key', () {
      const settings = AppSettings.defaults;

      expect(
        settings.translationProvider,
        equals(TranslationProvider.googleTranslate),
      );
      expect(settings.googleApiKey, isNull);
      expect(settings.hasGoogleApiKey, isFalse);
    });

    test('hasGoogleApiKey ignores blank keys', () {
      expect(const AppSettings(googleApiKey: '   ').hasGoogleApiKey, isFalse);
      expect(
        const AppSettings(googleApiKey: 'test-api-key').hasGoogleApiKey,
        isTrue,
      );
    });

    test('equality includes the provider and the API key', () {
      const a = AppSettings(googleApiKey: 'one');
      const b = AppSettings(googleApiKey: 'two');

      expect(a, isNot(equals(b)));
      expect(
        a,
        isNot(
          equals(a.copyWith(translationProvider: TranslationProvider.apple)),
        ),
      );
    });

    test('withoutGoogleApiKey clears only the key', () {
      const original = AppSettings(googleApiKey: 'test-api-key');

      final cleared = original.withoutGoogleApiKey();

      expect(cleared.googleApiKey, isNull);
      expect(cleared.sourceLanguage, equals(original.sourceLanguage));
      expect(cleared.translationProvider, equals(original.translationProvider));
    });
  });

  group('PrefsSettingsRepository', () {
    late PrefsSettingsRepository repository;
    late FakeApiKeyStore apiKeyStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      apiKeyStore = FakeApiKeyStore();
      repository = PrefsSettingsRepository(
        prefs: prefs,
        apiKeyStore: apiKeyStore,
      );
    });

    test('load returns defaults when nothing is persisted', () async {
      expect(await repository.load(), equals(AppSettings.defaults));
    });

    test(
      'load keeps a stored explicit source language (no auto migration)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'veliq.settings.sourceLanguage': 'en',
        });
        final prefs = await SharedPreferences.getInstance();
        final existing = PrefsSettingsRepository(
          prefs: prefs,
          apiKeyStore: apiKeyStore,
        );

        expect((await existing.load()).sourceLanguage, equals('en'));
      },
    );

    test('save then load round-trips every field', () async {
      const settings = AppSettings(
        sourceLanguage: 'fr',
        targetLanguage: 'fa',
        saveScreenshots: true,
      );

      await repository.save(settings);

      expect(await repository.load(), equals(settings));
    });

    test('save persists across repository instances', () async {
      await repository.save(
        const AppSettings(sourceLanguage: 'de', targetLanguage: 'fa'),
      );

      final prefs = await SharedPreferences.getInstance();
      final second = PrefsSettingsRepository(
        prefs: prefs,
        apiKeyStore: apiKeyStore,
      );

      expect((await second.load()).sourceLanguage, equals('de'));
    });

    test('load falls back to defaults for individually missing keys', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'veliq.settings.sourceLanguage': 'it',
      });
      final prefs = await SharedPreferences.getInstance();
      final partial = PrefsSettingsRepository(
        prefs: prefs,
        apiKeyStore: apiKeyStore,
      );

      final settings = await partial.load();

      expect(settings.sourceLanguage, equals('it'));
      expect(
        settings.targetLanguage,
        equals(AppSettings.defaultTargetLanguage),
      );
      expect(settings.saveScreenshots, isFalse);
    });

    test('load ignores keys from foreign namespaces', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.sourceLanguage': 'xx',
      });
      final prefs = await SharedPreferences.getInstance();
      final isolated = PrefsSettingsRepository(
        prefs: prefs,
        apiKeyStore: apiKeyStore,
      );

      expect(
        (await isolated.load()).sourceLanguage,
        equals(AppSettings.defaultSourceLanguage),
      );
    });

    test('save then load round-trips the provider and the API key', () async {
      const settings = AppSettings(
        translationProvider: TranslationProvider.apple,
        googleApiKey: 'test-api-key',
      );

      await repository.save(settings);

      final loaded = await repository.load();
      expect(loaded.translationProvider, equals(TranslationProvider.apple));
      expect(loaded.googleApiKey, equals('test-api-key'));
      expect(loaded, equals(settings));
    });

    test(
      'load falls back to the default provider for unknown values',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'veliq.settings.translationProvider': 'something-else',
        });
        final prefs = await SharedPreferences.getInstance();
        final withUnknown = PrefsSettingsRepository(
          prefs: prefs,
          apiKeyStore: apiKeyStore,
        );

        expect(
          (await withUnknown.load()).translationProvider,
          equals(AppSettings.defaultTranslationProvider),
        );
      },
    );

    test('clears a stored key when the new settings have none', () async {
      await repository.save(const AppSettings(googleApiKey: 'test-api-key'));
      expect((await repository.load()).googleApiKey, equals('test-api-key'));

      await repository.save(const AppSettings());

      expect((await repository.load()).googleApiKey, isNull);
    });

    test('an empty key is not persisted', () async {
      await repository.save(const AppSettings(googleApiKey: ''));

      expect((await repository.load()).googleApiKey, isNull);
    });

    test(
      'migrates a legacy key from shared_preferences to the KeyChain store',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'veliq.settings.googleApiKey': 'legacy-key',
        });
        final prefs = await SharedPreferences.getInstance();
        final withLegacy = PrefsSettingsRepository(
          prefs: prefs,
          apiKeyStore: apiKeyStore,
        );

        final settings = await withLegacy.load();

        expect(settings.googleApiKey, equals('legacy-key'));
        expect(apiKeyStore.value, equals('legacy-key'));
        // Legacy key must be removed from shared_preferences after migration.
        expect(prefs.getString('veliq.settings.googleApiKey'), isNull);
      },
    );
  });
}
