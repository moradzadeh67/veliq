/// Base class for translation states.
abstract class TranslationState {
  const TranslationState();
}

class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

class TranslationLoading extends TranslationState {
  const TranslationLoading();
}

class TranslationSuccess extends TranslationState {
  final String originalText;
  final String translatedText;

  /// ISO 639-1 code the provider detected in the source text, when it was asked
  /// to (`auto`) and can report it. `null` otherwise.
  final String? detectedSourceLanguage;

  const TranslationSuccess({
    required this.originalText,
    required this.translatedText,
    this.detectedSourceLanguage,
  });
}

class TranslationFailure extends TranslationState {
  final String message;

  const TranslationFailure(this.message);
}
