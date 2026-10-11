import 'dart:typed_data';

/// Abstract service interface for performing OCR on captured image bytes.
abstract class OcrService {
  /// Recognizes text from image bytes [imageBytes].
  /// Returns recognized text string, or null/empty if no text found.
  Future<String?> recognizeText(Uint8List imageBytes);
}
