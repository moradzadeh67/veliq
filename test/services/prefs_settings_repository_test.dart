import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veliq/services/prefs_settings_repository.dart';
import 'package:veliq/services/settings_repository.dart';

void main() {
  group('AppSettings', () {
    test('defaults are en -> fa with screenshots off', () {
      const settings = AppSettings.defaults;

      expect(settings.sourceLanguage, equals('en'));
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

    test('defaults select the Google provider without a key', () {
      const settings = AppSettings.defaults;

      expect(settings.translationProvider, equals(TranslationProvider.google));
      expect(settings.googleApiKey, isNull);
      expect(settings.hasGoogleApiKey, isFalse);
    });

    test('hasGoogleApiKey ignores blank keys', () {
      expect(const AppSettings(googleApiKey: '   ').hasGoogleApiKey, isFalse);
      expect(
        const AppSettings(googleApiKey: 'AIza123').hasGoogleApiKey,
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
      const original = AppSettings(googleApiKey: 'AIza123');

      final cleared = original.withoutGoogleApiKey();

      expect(cleared.googleApiKey, isNull);
      expect(cleared.sourceLanguage, equals(original.sourceLanguage));
      expect(cleared.translationProvider, equals(original.translationProvider));
    });
  });

  group('PrefsSettingsRepository', () {
    late PrefsSettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      repository = PrefsSettingsRepository(prefs: prefs);
    });

    test('load returns defaults when nothing is persisted', () async {
      expect(await repository.load(), equals(AppSettings.defaults));
    });

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
      final second = PrefsSettingsRepository(prefs: prefs);

      expect((await second.load()).sourceLanguage, equals('de'));
    });

    test('load falls back to defaults for individually missing keys', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'veliq.settings.sourceLanguage': 'it',
      });
      final prefs = await SharedPreferences.getInstance();
      final partial = PrefsSettingsRepository(prefs: prefs);

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
      final isolated = PrefsSettingsRepository(prefs: prefs);

      expect(
        (await isolated.load()).sourceLanguage,
        equals(AppSettings.defaultSourceLanguage),
      );
    });

    test('save then load round-trips the provider and the API key', () async {
      const settings = AppSettings(
        translationProvider: TranslationProvider.apple,
        googleApiKey: 'AIza-secret',
      );

      await repository.save(settings);

      final loaded = await repository.load();
      expect(loaded.translationProvider, equals(TranslationProvider.apple));
      expect(loaded.googleApiKey, equals('AIza-secret'));
      expect(loaded, equals(settings));
    });

    test(
      'load falls back to the default provider for unknown values',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'veliq.settings.translationProvider': 'something-else',
        });
        final prefs = await SharedPreferences.getInstance();
        final withUnknown = PrefsSettingsRepository(prefs: prefs);

        expect(
          (await withUnknown.load()).translationProvider,
          equals(AppSettings.defaultTranslationProvider),
        );
      },
    );

    test('clears a stored key when the new settings have none', () async {
      await repository.save(const AppSettings(googleApiKey: 'AIza-secret'));
      expect((await repository.load()).googleApiKey, equals('AIza-secret'));

      await repository.save(const AppSettings());

      expect((await repository.load()).googleApiKey, isNull);
    });

    test('an empty key is not persisted', () async {
      await repository.save(const AppSettings(googleApiKey: ''));

      expect((await repository.load()).googleApiKey, isNull);
    });
  });
}
