import 'dart:typed_data';

import '../pigeon/messages.g.dart';
import 'ocr_service.dart';

/// Implementation of [OcrService] using Pigeon to communicate with macOS Apple Vision OCR.
class PigeonOcrService implements OcrService {
  final OcrApi _api;

  PigeonOcrService({OcrApi? api}) : _api = api ?? OcrApi();

  @override
  Future<String?> recognizeText(Uint8List imageBytes) async {
    return await _api.recognizeText(imageBytes);
  }
}
