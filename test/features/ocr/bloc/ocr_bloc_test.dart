import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/ocr/bloc/ocr_bloc.dart';
import 'package:veliq/features/ocr/bloc/ocr_state.dart';
import 'package:veliq/services/ocr_service.dart';

class MockOcrService implements OcrService {
  String? mockResult;
  bool shouldThrow = false;

  @override
  Future<String?> recognizeText(Uint8List imageBytes) async {
    if (shouldThrow) throw Exception('OCR failed');
    return mockResult;
  }
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

    test('recognizeImage sets state to OcrFailure on exception', () async {
      mockOcrService.shouldThrow = true;

      await ocrBloc.recognizeImage(Uint8List(0));

      expect(ocrBloc.currentState, isA<OcrFailure>());
    });
  });
}
