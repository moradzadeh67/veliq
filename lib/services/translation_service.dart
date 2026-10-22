/// What a translation provider produced for one request.
///
/// [text] is the translation itself. [detectedSourceLanguage] is the ISO 639-1
/// code the provider recognised in the source text — only filled in when the
/// caller asked for detection (`sourceLanguage == 'auto'`) and the provider can
/// actually report it (Gemini can, Apple's on-device engine cannot).
class TranslationOutcome {
  final String? text;
  final String? detectedSourceLanguage;

  const TranslationOutcome(this.text, {this.detectedSourceLanguage});
}

/// Abstract service interface for translating text between languages.
abstract class TranslationService {
  /// Translates [text] from [sourceLanguage] to [targetLanguage].
  ///
  /// Returns the translated text, or `null` when the provider produced no
  /// usable result (for example on a macOS version without the native API).
  ///
  /// Implementations throw a `TranslationException` — whose `message` is safe
  /// to display — when the provider fails, so callers never have to render a
  /// raw exception.
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  );

  /// Like [translateText], but may also report the language it detected.
  ///
  /// Providers that cannot detect a language keep this default: they delegate to
  /// [translateText] and report no detection, so `auto` simply stays `auto`.
  Future<TranslationOutcome> translateWithDetection(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    return TranslationOutcome(
      await translateText(text, sourceLanguage, targetLanguage),
    );
  }
}
