import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/models/language.dart';
import 'package:veliq/services/settings_repository.dart';

void main() {
  group('LanguageCatalog', () {
    test('byCode finds a real language', () {
      final persian = LanguageCatalog.byCode('fa');

      expect(persian, isNotNull);
      expect(persian!.englishName, equals('Persian'));
      expect(persian.nativeName, equals('فارسی'));
      expect(persian.isRtl, isTrue);
    });

    test('byCode finds the auto pseudo-language', () {
      expect(LanguageCatalog.byCode(LanguageCatalog.autoCode), isNotNull);
      expect(
        LanguageCatalog.byCode(LanguageCatalog.autoCode)!.englishName,
        equals('Auto-detect'),
      );
    });

    test('byCode returns null for an unknown code', () {
      expect(LanguageCatalog.byCode('xx'), isNull);
    });

    test('displayName falls back to the raw code when unknown', () {
      expect(LanguageCatalog.displayName('en'), equals('English'));
      expect(LanguageCatalog.displayName('fr'), equals('French'));
      expect(
        LanguageCatalog.displayName(LanguageCatalog.autoCode),
        equals('Auto-detect'),
      );
      expect(LanguageCatalog.displayName('xx'), equals('xx'));
    });

    test('auto is first in sourceOptions and never a target', () {
      expect(
        LanguageCatalog.sourceOptions.first.code,
        equals(LanguageCatalog.autoCode),
      );
      expect(
        LanguageCatalog.sourceOptions.map((l) => l.code),
        contains(LanguageCatalog.autoCode),
      );
      expect(
        LanguageCatalog.targetOptions.map((l) => l.code),
        isNot(contains(LanguageCatalog.autoCode)),
      );
      expect(
        LanguageCatalog.sourceOptions.length,
        equals(LanguageCatalog.all.length + 1),
      );
      expect(
        LanguageCatalog.targetOptions.length,
        equals(LanguageCatalog.all.length),
      );
    });

    test('the catalog has no duplicate codes', () {
      final codes = LanguageCatalog.all.map((l) => l.code).toList();

      expect(codes.toSet().length, equals(codes.length));
    });

    test('Persian and Arabic are right-to-left, the rest are not', () {
      final rtl = LanguageCatalog.all
          .where((language) => language.isRtl)
          .map((language) => language.code)
          .toSet();

      expect(rtl, equals(<String>{'fa', 'ar'}));
    });

    test('the previously offered languages are still present', () {
      final codes = LanguageCatalog.all.map((l) => l.code).toSet();

      expect(
        codes.containsAll(<String>{
          'en',
          'fa',
          'ar',
          'de',
          'fr',
          'es',
          'it',
          'ru',
          'tr',
          'zh',
          'ja',
        }),
        isTrue,
      );
      expect(codes.containsAll(<String>{'pt', 'nl', 'ko'}), isTrue);
    });
  });

  group('AppSettings language defaults', () {
    test(
      'a fresh AppSettings uses auto as the source and fa as the target',
      () {
        const settings = AppSettings();

        expect(settings.sourceLanguage, equals(LanguageCatalog.autoCode));
        expect(settings.targetLanguage, equals('fa'));
        expect(AppSettings.defaultSourceLanguage, equals('auto'));
      },
    );
  });
}
