import 'dart:typed_data';

/// Abstract service interface for performing OCR on captured image bytes.
abstract class OcrService {
  /// Recognizes text from image bytes [imageBytes].
  ///
  /// [languageHint] is an ISO 639-1 code, or `null` / `auto` to detect the
  /// script. Returns recognized text string, or null/empty if no text found.
  Future<String?> recognizeText(Uint8List imageBytes, {String? languageHint});

  /// The ISO 639-1 base codes this platform's OCR can read.
  ///
  /// Queried from the native side because it depends on the device: Apple
  /// Vision reports its own list at runtime, Android ships a fixed ML Kit Latin
  /// model. See D-018.
  Future<Set<String>> supportedLanguages();
}
