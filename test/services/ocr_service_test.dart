import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/pigeon/messages.g.dart';
import 'package:veliq/services/pigeon_ocr_service.dart';

class MockOcrApi extends OcrApi {
  Uint8List? lastImageBytes;
  String? mockResult;

  @override
  Future<String?> recognizeText(Uint8List imageBytes) async {
    lastImageBytes = imageBytes;
    return mockResult;
  }
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
  });
}
