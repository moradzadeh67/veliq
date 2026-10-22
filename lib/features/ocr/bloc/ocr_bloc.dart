import 'dart:async';
import 'dart:typed_data';

import '../../../services/ocr_service.dart';
import 'ocr_state.dart';

/// BLC / state controller for OCR processing.
class OcrBloc {
  final OcrService _ocrService;

  final _stateController = StreamController<OcrState>.broadcast();
  Stream<OcrState> get stateStream => _stateController.stream;

  OcrState _currentState = const OcrInitial();
  OcrState get currentState => _currentState;

  OcrBloc({required this._ocrService});

  void _emit(OcrState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> recognizeImage(
    Uint8List imageBytes, {
    String? languageHint,
  }) async {
    _emit(const OcrLoading());
    await Future.microtask(() {});
    try {
      final text = await _ocrService.recognizeText(
        imageBytes,
        languageHint: languageHint,
      );
      if (text != null && text.trim().isNotEmpty) {
        _emit(OcrSuccess(text));
      } else {
        _emit(const OcrFailure('No text found in image'));
      }
    } catch (e) {
      _emit(OcrFailure(e.toString()));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
