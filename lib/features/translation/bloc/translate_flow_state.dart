/// Base class for the end-to-end translate flow states.
///
/// `sealed` so the UI can switch exhaustively without a default branch.
sealed class TranslateFlowState {
  const TranslateFlowState();
}

/// Nothing is running; waiting for the user to select a region.
class TranslateFlowIdle extends TranslateFlowState {
  const TranslateFlowIdle();
}

/// The user is dragging out a region on the overlay.
class TranslateFlowSelecting extends TranslateFlowState {
  const TranslateFlowSelecting();
}

/// A region was chosen and the screenshot is being taken.
class TranslateFlowCapturing extends TranslateFlowState {
  const TranslateFlowCapturing();
}

/// Running OCR on the captured image.
class TranslateFlowRecognizing extends TranslateFlowState {
  const TranslateFlowRecognizing();
}

/// Translating the recognized text.
class TranslateFlowTranslating extends TranslateFlowState {
  const TranslateFlowTranslating();
}

/// The pipeline finished successfully.
class TranslateFlowSuccess extends TranslateFlowState {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  const TranslateFlowSuccess({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
}

/// A stage failed. [stage] says where, so the UI can give a targeted hint.
class TranslateFlowFailure extends TranslateFlowState {
  final TranslateFlowStage stage;
  final String message;

  const TranslateFlowFailure({required this.stage, required this.message});
}

/// The stage of the pipeline that produced a failure.
enum TranslateFlowStage { capture, recognize, translate, save }
