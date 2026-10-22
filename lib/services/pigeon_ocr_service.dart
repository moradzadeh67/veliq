import 'dart:typed_data';

import '../pigeon/messages.g.dart';
import 'ocr_service.dart';

/// Implementation of [OcrService] using Pigeon to talk to the platform OCR:
/// Apple Vision on macOS/iOS, ML Kit on Android.
class PigeonOcrService implements OcrService {
  final OcrApi _api;

  PigeonOcrService({OcrApi? api}) : _api = api ?? OcrApi();

  @override
  Future<String?> recognizeText(
    Uint8List imageBytes, {
    String? languageHint,
  }) async {
    return await _api.recognizeText(imageBytes, languageHint);
  }

  @override
  Future<Set<String>> supportedLanguages() async {
    return (await _api.supportedLanguages()).toSet();
  }
}
