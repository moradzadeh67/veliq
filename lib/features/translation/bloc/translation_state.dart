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

  const TranslationSuccess({
    required this.originalText,
    required this.translatedText,
  });
}

class TranslationFailure extends TranslationState {
  final String message;

  const TranslationFailure(this.message);
}
