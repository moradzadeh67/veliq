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
}
