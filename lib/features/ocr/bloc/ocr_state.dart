/// Base class for OCR states.
abstract class OcrState {
  const OcrState();
}

class OcrInitial extends OcrState {
  const OcrInitial();
}

class OcrLoading extends OcrState {
  const OcrLoading();
}

class OcrSuccess extends OcrState {
  final String text;
  const OcrSuccess(this.text);
}

class OcrFailure extends OcrState {
  final String message;
  const OcrFailure(this.message);
}
