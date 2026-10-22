import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/services/settings_repository.dart';
import 'package:veliq/services/translation_exception.dart';
import 'package:veliq/services/switching_translation_service.dart';
import 'package:veliq/services/translation_service.dart';

class _StubService implements TranslationService {
  final String label;
  final List<String> calls = <String>[];

  _StubService(this.label);

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    calls.add('$text|$sourceLanguage|$targetLanguage');
    return label;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored;

  _FakeSettingsRepository(this.stored);

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

void main() {
  group('SwitchingTranslationService', () {
    late _StubService apple;

    setUp(() {
      apple = _StubService('apple');
    });

    test('routes to the Apple backend when it is selected', () async {
      final google = _StubService('google');
      final service = SwitchingTranslationService(
        settings: _FakeSettingsRepository(
          const AppSettings(translationProvider: TranslationProvider.apple),
        ),
        apple: apple,
        googleFactory: (_) => google,
      );

      final result = await service.translateText('Hello', 'en', 'fa');

      expect(result, equals('apple'));
      expect(apple.calls, equals(['Hello|en|fa']));
      expect(google.calls, isEmpty);
    });

    test('routes to the Google backend when it is selected', () async {
      final google = _StubService('google');
      String? usedKey;

      final service = SwitchingTranslationService(
        settings: _FakeSettingsRepository(
          const AppSettings(
            translationProvider: TranslationProvider.google,
            googleApiKey: 'key-1',
          ),
        ),
        apple: apple,
        googleFactory: (apiKey) {
          usedKey = apiKey;
          return google;
        },
      );

      final result = await service.translateText('Hello', 'en', 'fa');

      expect(result, equals('google'));
      expect(usedKey, equals('key-1'));
      expect(google.calls, equals(['Hello|en|fa']));
      expect(apple.calls, isEmpty);
    });

    test('builds the Google backend once for an unchanged key', () async {
      var factoryCalls = 0;
      final google = _StubService('google');

      final service = SwitchingTranslationService(
        settings: _FakeSettingsRepository(
          const AppSettings(
            translationProvider: TranslationProvider.google,
            googleApiKey: 'key-1',
          ),
        ),
        apple: apple,
        googleFactory: (_) {
          factoryCalls++;
          return google;
        },
      );

      await service.translateText('One', 'en', 'fa');
      await service.translateText('Two', 'en', 'fa');

      expect(factoryCalls, equals(1));
      expect(google.calls, hasLength(2));
    });

    test('rebuilds the Google backend when the stored key changes', () async {
      final keys = <String>[];
      final repository = _FakeSettingsRepository(
        const AppSettings(
          translationProvider: TranslationProvider.google,
          googleApiKey: 'key-1',
        ),
      );

      final service = SwitchingTranslationService(
        settings: repository,
        apple: apple,
        googleFactory: (apiKey) {
          keys.add(apiKey);
          return _StubService('google-$apiKey');
        },
      );

      await service.translateText('One', 'en', 'fa');
      repository.stored = repository.stored.copyWith(googleApiKey: 'key-2');
      final second = await service.translateText('Two', 'en', 'fa');

      expect(keys, equals(['key-1', 'key-2']));
      expect(second, equals('google-key-2'));
    });

    test('Apple plus an auto source throws a readable error', () async {
      final google = _StubService('google');
      final service = SwitchingTranslationService(
        settings: _FakeSettingsRepository(
          const AppSettings(translationProvider: TranslationProvider.apple),
        ),
        apple: apple,
        googleFactory: (_) => google,
      );

      await expectLater(
        service.translateText('Bonjour', 'auto', 'fa'),
        throwsA(
          isA<TranslationException>().having(
            (e) => e.message,
            'message',
            contains('On-device translation needs a specific source language'),
          ),
        ),
      );
      expect(apple.calls, isEmpty);
      expect(google.calls, isEmpty);
    });

    test('Google still accepts an auto source', () async {
      final google = _StubService('google');
      final service = SwitchingTranslationService(
        settings: _FakeSettingsRepository(
          const AppSettings(
            translationProvider: TranslationProvider.google,
            googleApiKey: 'key-1',
          ),
        ),
        apple: apple,
        googleFactory: (_) => google,
      );

      expect(
        await service.translateText('Bonjour', 'auto', 'fa'),
        equals('google'),
      );
      expect(google.calls, equals(['Bonjour|auto|fa']));
    });

    test('switching provider per call is honoured', () async {
      final google = _StubService('google');
      final repository = _FakeSettingsRepository(
        const AppSettings(translationProvider: TranslationProvider.apple),
      );

      final service = SwitchingTranslationService(
        settings: repository,
        apple: apple,
        googleFactory: (_) => google,
      );

      expect(await service.translateText('One', 'en', 'fa'), equals('apple'));

      repository.stored = repository.stored.copyWith(
        translationProvider: TranslationProvider.google,
        googleApiKey: 'key-1',
      );

      expect(await service.translateText('Two', 'en', 'fa'), equals('google'));
      expect(apple.calls, hasLength(1));
      expect(google.calls, hasLength(1));
    });
  });
}
