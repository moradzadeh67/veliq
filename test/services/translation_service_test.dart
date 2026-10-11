import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_translation_service.dart';
import 'package:veliq/services/translation_exception.dart';

class MockTranslationApi extends TranslationApi {
  String? lastText;
  String? lastSource;
  String? lastTarget;
  String? mockResult;
  Object? errorToThrow;

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    lastText = text;
    lastSource = sourceLanguage;
    lastTarget = targetLanguage;
    if (errorToThrow != null) throw errorToThrow!;
    return mockResult;
  }
}

Future<TranslationException> _expectFailure(
  Future<Object?> Function() action,
) async {
  try {
    await action();
  } on TranslationException catch (e) {
    return e;
  }
  fail('Expected a TranslationException');
}

void main() {
  group('PigeonTranslationService', () {
    test(
      'translateText passes arguments correctly to TranslationApi',
      () async {
        final mockApi = MockTranslationApi();
        mockApi.mockResult = 'سلام دنیا';

        final service = PigeonTranslationService(api: mockApi);
        final result = await service.translateText('Hello World', 'en', 'fa');

        expect(result, equals('سلام دنیا'));
        expect(mockApi.lastText, equals('Hello World'));
        expect(mockApi.lastSource, equals('en'));
        expect(mockApi.lastTarget, equals('fa'));
      },
    );

    test('maps unsupportedTargetLanguage to an actionable message', () async {
      final mockApi = MockTranslationApi();
      mockApi.errorToThrow = PlatformException(
        code: 'TranslationError',
        message: 'TranslationError(cause: unsupportedTargetLanguage)',
        details: '#0 TranslationHandler.translateText (Runner)',
      );

      final error = await _expectFailure(
        () =>
            PigeonTranslationService(api: mockApi)
                .translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('support'));
      expect(error.message, contains('Settings'));
      // The raw native identifiers and stack trace must not reach the user.
      expect(error.message, isNot(contains('unsupportedTargetLanguage')));
      expect(error.message, isNot(contains('#0')));
    });

    test('maps unableToIdentifyLanguage to a hint about the source', () async {
      final mockApi = MockTranslationApi();
      mockApi.errorToThrow = PlatformException(
        code: 'TranslationError',
        message: 'TranslationError(cause: unableToIdentifyLanguage)',
      );

      final error = await _expectFailure(
        () =>
            PigeonTranslationService(api: mockApi)
                .translateText('Hello', 'en', 'fa'),
      );

      expect(error.message.toLowerCase(), contains('source language'));
    });

    test('falls back to a generic message for unknown failures', () async {
      final mockApi = MockTranslationApi();
      mockApi.errorToThrow = PlatformException(
        code: 'SomeOtherError',
        message: 'kaboom',
      );

      final error = await _expectFailure(
        () =>
            PigeonTranslationService(api: mockApi)
                .translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('On-device translation failed'));
      expect(error.message, isNot(contains('kaboom')));
    });
  });
}
