import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_ocr_service.dart';

class MockOcrApi extends OcrApi {
  Uint8List? lastImageBytes;
  String? lastLanguageHint;
  String? mockResult;
  List<String> mockLanguages = const <String>[];

  @override
  Future<String?> recognizeText(
    Uint8List imageBytes,
    String? languageHint,
  ) async {
    lastImageBytes = imageBytes;
    lastLanguageHint = languageHint;
    return mockResult;
  }

  @override
  Future<List<String>> supportedLanguages() async => mockLanguages;
}

void main() {
  group('PigeonOcrService', () {
    test('recognizeText passes image bytes correctly to OcrApi', () async {
      final mockApi = MockOcrApi();
      final bytes = Uint8List.fromList([10, 20, 30, 40]);
      mockApi.mockResult = 'Hello Veliq OCR';

      final service = PigeonOcrService(api: mockApi);
      final result = await service.recognizeText(bytes);

      expect(result, equals('Hello Veliq OCR'));
      expect(mockApi.lastImageBytes, equals(bytes));
    });

    test('recognizeText forwards the language hint to OcrApi', () async {
      final mockApi = MockOcrApi();
      mockApi.mockResult = 'Bonjour le monde';

      final service = PigeonOcrService(api: mockApi);
      await service.recognizeText(
        Uint8List.fromList([1, 2]),
        languageHint: 'fr',
      );

      expect(mockApi.lastLanguageHint, equals('fr'));
    });

    test('recognizeText forwards a null hint unchanged', () async {
      final mockApi = MockOcrApi();

      final service = PigeonOcrService(api: mockApi);
      await service.recognizeText(Uint8List.fromList([1, 2]));

      expect(mockApi.lastLanguageHint, isNull);
    });

    test('supportedLanguages is returned as a set', () async {
      final mockApi = MockOcrApi()
        ..mockLanguages = const ['en', 'fr', 'fr', 'de'];

      final service = PigeonOcrService(api: mockApi);

      expect(
        await service.supportedLanguages(),
        equals(<String>{'en', 'fr', 'de'}),
      );
    });
  });
}
