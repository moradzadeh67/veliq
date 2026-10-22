import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/translation/bloc/translation_bloc.dart';
import 'package:veliq/features/translation/bloc/translation_state.dart';
import 'package:veliq/services/translation_exception.dart';
import 'package:veliq/services/translation_service.dart';

class MockTranslationService extends TranslationService {
  String? mockResult;
  bool shouldThrow = false;
  Object? errorToThrow;
  String? lastText;
  String? lastSource;
  String? lastTarget;

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
    if (shouldThrow) throw Exception('Translation failed');
    return mockResult;
  }

  /// Stands in for Gemini reporting the language it detected.
  String? detectedLanguage;

  @override
  Future<TranslationOutcome> translateWithDetection(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    return TranslationOutcome(
      await translateText(text, sourceLanguage, targetLanguage),
      detectedSourceLanguage: detectedLanguage,
    );
  }
}

void main() {
  group('TranslationBloc Tests', () {
    late MockTranslationService mockService;
    late TranslationBloc translationBloc;

    setUp(() {
      mockService = MockTranslationService();
      translationBloc = TranslationBloc(translationService: mockService);
    });

    tearDown(() {
      translationBloc.dispose();
    });

    test('initial state is TranslationInitial', () {
      expect(translationBloc.currentState, isA<TranslationInitial>());
    });

    test('translate sets state to TranslationSuccess on success', () async {
      mockService.mockResult = 'سلام دنیا';

      await translationBloc.translate(text: 'Hello World');

      expect(translationBloc.currentState, isA<TranslationSuccess>());
      final state = translationBloc.currentState as TranslationSuccess;
      expect(state.originalText, equals('Hello World'));
      expect(state.translatedText, equals('سلام دنیا'));
    });

    test('translate uses default en -> fa languages', () async {
      mockService.mockResult = 'سلام';

      await translationBloc.translate(text: 'Hi');

      expect(mockService.lastSource, equals('en'));
      expect(mockService.lastTarget, equals('fa'));
    });

    test('translate respects explicit languages', () async {
      mockService.mockResult = 'Bonjour';

      await translationBloc.translate(
        text: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'fr',
      );

      expect(mockService.lastSource, equals('en'));
      expect(mockService.lastTarget, equals('fr'));
    });

    test(
      'translate sets state to TranslationFailure when result is null',
      () async {
        mockService.mockResult = null;

        await translationBloc.translate(text: 'Hello');

        expect(translationBloc.currentState, isA<TranslationFailure>());
      },
    );

    test('translate sets state to TranslationFailure on exception', () async {
      mockService.shouldThrow = true;

      await translationBloc.translate(text: 'Hello');

      expect(translationBloc.currentState, isA<TranslationFailure>());
    });

    test(
      'translate sets state to TranslationFailure for empty input',
      () async {
        await translationBloc.translate(text: '   ');

        expect(translationBloc.currentState, isA<TranslationFailure>());
      },
    );

    test('surfaces the message carried by a TranslationException', () async {
      mockService.errorToThrow = const TranslationException(
        "Apple's engine doesn't support this language pair.",
      );

      await translationBloc.translate(text: 'Hello');

      final state = translationBloc.currentState;
      expect(state, isA<TranslationFailure>());
      expect(
        (state as TranslationFailure).message,
        equals("Apple's engine doesn't support this language pair."),
      );
    });

    test('does not leak a raw PlatformException or its stack trace', () async {
      mockService.errorToThrow = PlatformException(
        code: 'TranslationError',
        message: 'unsupportedTargetLanguage',
        details: '#0 TranslationHandler.translateText (Runner)',
      );

      await translationBloc.translate(text: 'Hello');

      final message =
          (translationBloc.currentState as TranslationFailure).message;
      expect(message, isNot(contains('PlatformException')));
      expect(message, isNot(contains('unsupportedTargetLanguage')));
      expect(message, isNot(contains('#0')));
      expect(message.toLowerCase(), contains('provider'));
    });

    test('does not leak a generic exception message', () async {
      mockService.errorToThrow = StateError('internal detail at 0x1f');

      await translationBloc.translate(text: 'Hello');

      final message =
          (translationBloc.currentState as TranslationFailure).message;
      expect(message, isNot(contains('internal detail')));
      expect(message, isNot(contains('0x1f')));
    });
    test('carries the detected source language into the success state', () async {
      mockService.mockResult = 'Bonjour le monde';
      mockService.detectedLanguage = 'fr';

      await translationBloc.translate(text: 'Hello world', sourceLanguage: 'auto');

      final state = translationBloc.currentState;
      expect(state, isA<TranslationSuccess>());
      expect(
        (state as TranslationSuccess).detectedSourceLanguage,
        equals('fr'),
      );
    });

    test('reports no detection when the provider cannot detect', () async {
      mockService.mockResult = 'Bonjour';

      await translationBloc.translate(text: 'Hello', sourceLanguage: 'en');

      expect(
        (translationBloc.currentState as TranslationSuccess)
            .detectedSourceLanguage,
        isNull,
      );
    });
  });
}