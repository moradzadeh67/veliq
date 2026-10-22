import 'dart:async';
import 'dart:typed_data';

import '../../../models/language.dart';
import '../../../models/translation_entry.dart';
import '../../../services/capture_service.dart';
import '../../../services/history_repository.dart';
import '../../../services/image_source_service.dart';
import '../../../services/settings_repository.dart';
import '../../ocr/bloc/ocr_bloc.dart';
import '../../ocr/bloc/ocr_state.dart';
import 'translation_bloc.dart';
import 'translation_state.dart';
import 'translate_flow_state.dart';

/// Orchestrates the end-to-end "select region -> OCR -> translate -> save"
/// pipeline.
///
/// It deliberately delegates OCR and translation to the existing [OcrBloc] and
/// [TranslationBloc] instead of re-implementing them, so their behaviour (and
/// their tests) remain the single source of truth for those stages.
class TranslateFlowBloc {
  final CaptureService _captureService;
  final ImageSourceService? _imageSourceService;
  final OcrBloc _ocrBloc;
  final TranslationBloc _translationBloc;
  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;

  /// Injectable so tests get deterministic ids/timestamps.
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  final _stateController = StreamController<TranslateFlowState>.broadcast();
  Stream<TranslateFlowState> get stateStream => _stateController.stream;

  TranslateFlowState _currentState = const TranslateFlowIdle();
  TranslateFlowState get currentState => _currentState;

  TranslateFlowBloc({
    required this._captureService,
    this._imageSourceService,
    required this._ocrBloc,
    required this._translationBloc,
    required this._historyRepository,
    required this._settingsRepository,
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator ?? _defaultIdGenerator,
       _clock = clock ?? DateTime.now;

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  void _emit(TranslateFlowState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Marks that the user has begun drawing a selection.
  void startSelection() => _emit(const TranslateFlowSelecting());

  /// Abandons the current run and returns to idle.
  void cancel() => _emit(const TranslateFlowIdle());

  /// Runs the whole pipeline for the region described by [rect].
  ///
  /// [rect] is in logical Flutter pixels relative to the window.
  Future<void> runForRect({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    // Stage 1: capture.
    _emit(const TranslateFlowCapturing());

    Uint8List? imageBytes;
    try {
      imageBytes = await _captureService.captureRegion(
        x: x,
        y: y,
        width: width,
        height: height,
      );
    } catch (e) {
      _emit(
        TranslateFlowFailure(
          stage: TranslateFlowStage.capture,
          message: 'Screen capture failed: $e',
        ),
      );
      return;
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      _emit(
        const TranslateFlowFailure(
          stage: TranslateFlowStage.capture,
          message:
              'Could not capture that region. Veliq needs Screen Recording '
              'permission — grant it in System Settings > Privacy & Security, '
              'then try again.',
        ),
      );
      return;
    }

    await runForImageBytes(imageBytes);
  }

  /// Runs OCR -> translate -> save pipeline for given [imageBytes].
  Future<void> runForImageBytes(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      _emit(
        const TranslateFlowFailure(
          stage: TranslateFlowStage.capture,
          message: 'No image data provided.',
        ),
      );
      return;
    }

    // The pair is needed twice (OCR hint, then translator), so load it once.
    final settings = await _settingsRepository.load();

    // Stage 2: OCR. The OcrBloc owns the "no text found" case. The source
    // language is a hint for the platform OCR: `auto` lets it detect the script.
    _emit(const TranslateFlowRecognizing());
    await _ocrBloc.recognizeImage(
      imageBytes,
      languageHint: settings.sourceLanguage,
    );

    final ocrState = _ocrBloc.currentState;
    if (ocrState is! OcrSuccess) {
      final detail = ocrState is OcrFailure
          ? ocrState.message
          : 'Unknown error';
      _emit(
        TranslateFlowFailure(
          stage: TranslateFlowStage.recognize,
          message: detail,
        ),
      );
      return;
    }

    final recognizedText = ocrState.text;

    // Stage 3: translate, using the pair loaded above.
    _emit(const TranslateFlowTranslating());

    await _translationBloc.translate(
      text: recognizedText,
      sourceLanguage: settings.sourceLanguage,
      targetLanguage: settings.targetLanguage,
    );

    final translationState = _translationBloc.currentState;
    if (translationState is! TranslationSuccess) {
      final detail = translationState is TranslationFailure
          ? translationState.message
          : 'Unknown error';
      _emit(
        TranslateFlowFailure(
          stage: TranslateFlowStage.translate,
          message: detail,
        ),
      );
      return;
    }

    // With `auto` as the source, show and store the language the provider
    // actually detected instead of the literal "Auto-detect" (T-157).
    final detected = translationState.detectedSourceLanguage;
    final sourceLanguage =
        settings.sourceLanguage == LanguageCatalog.autoCode && detected != null
        ? detected
        : settings.sourceLanguage;

    // Stage 4: persist to history. A failure here must not discard the
    // translation the user is already looking at.
    try {
      await _historyRepository.add(
        TranslationEntry(
          id: _idGenerator(),
          originalText: recognizedText,
          translatedText: translationState.translatedText,
          sourceLanguage: sourceLanguage,
          targetLanguage: settings.targetLanguage,
          createdAt: _clock(),
        ),
      );
    } catch (_) {
      // Intentionally ignored: history is best-effort, the result still shows.
    }

    _emit(
      TranslateFlowSuccess(
        originalText: recognizedText,
        translatedText: translationState.translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: settings.targetLanguage,
      ),
    );
  }

  /// Picks an image from gallery and runs the translation pipeline.
  Future<void> pickFromGallery() async {
    if (_imageSourceService == null) return;
    _emit(const TranslateFlowCapturing());
    final bytes = await _imageSourceService.pickFromGallery();
    if (bytes == null || bytes.isEmpty) {
      _emit(const TranslateFlowIdle());
      return;
    }
    await runForImageBytes(bytes);
  }

  /// Alias for pickFromGallery.
  Future<void> pickImageFromGallery() => pickFromGallery();

  /// Captures a photo with camera and runs the translation pipeline.
  Future<void> takePhoto() async {
    if (_imageSourceService == null) return;
    _emit(const TranslateFlowCapturing());
    final bytes = await _imageSourceService.takePhoto();
    if (bytes == null || bytes.isEmpty) {
      _emit(const TranslateFlowIdle());
      return;
    }
    await runForImageBytes(bytes);
  }

  void dispose() {
    _stateController.close();
  }
}
