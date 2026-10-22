import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/ocr/bloc/ocr_bloc.dart';
import 'package:veliq/features/ocr/bloc/ocr_state.dart';
import 'package:veliq/services/ocr_service.dart';

class MockOcrService implements OcrService {
  String? mockResult;
  bool shouldThrow = false;
  String? lastLanguageHint;
  Set<String> languages = const {'en'};

  @override
  Future<String?> recognizeText(
    Uint8List imageBytes, {
    String? languageHint,
  }) async {
    lastLanguageHint = languageHint;
    if (shouldThrow) throw Exception('OCR failed');
    return mockResult;
  }

  @override
  Future<Set<String>> supportedLanguages() async => languages;
}

void main() {
  group('OcrBloc Tests', () {
    late MockOcrService mockOcrService;
    late OcrBloc ocrBloc;

    setUp(() {
      mockOcrService = MockOcrService();
      ocrBloc = OcrBloc(ocrService: mockOcrService);
    });

    tearDown(() {
      ocrBloc.dispose();
    });

    test('initial state is OcrInitial', () {
      expect(ocrBloc.currentState, isA<OcrInitial>());
    });

    test('recognizeImage sets state to OcrSuccess on success', () async {
      mockOcrService.mockResult = 'Hello OCR';

      await ocrBloc.recognizeImage(Uint8List(0));

      expect(ocrBloc.currentState, isA<OcrSuccess>());
      expect((ocrBloc.currentState as OcrSuccess).text, equals('Hello OCR'));
    });

    test(
      'recognizeImage sets state to OcrFailure when no text found',
      () async {
        mockOcrService.mockResult = '';

        await ocrBloc.recognizeImage(Uint8List(0));

        expect(ocrBloc.currentState, isA<OcrFailure>());
      },
    );

    test('recognizeImage forwards the language hint to the service', () async {
      mockOcrService.mockResult = 'Bonjour';

      await ocrBloc.recognizeImage(Uint8List(0), languageHint: 'fr');

      expect(mockOcrService.lastLanguageHint, equals('fr'));
      expect(ocrBloc.currentState, isA<OcrSuccess>());
    });

    test('recognizeImage passes a null hint through', () async {
      mockOcrService.mockResult = 'Hello';

      await ocrBloc.recognizeImage(Uint8List(0));

      expect(mockOcrService.lastLanguageHint, isNull);
    });

    test('recognizeImage sets state to OcrFailure on exception', () async {
      mockOcrService.shouldThrow = true;

      await ocrBloc.recognizeImage(Uint8List(0));

      expect(ocrBloc.currentState, isA<OcrFailure>());
    });
  });
}
