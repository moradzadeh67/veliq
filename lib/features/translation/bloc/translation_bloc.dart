import 'dart:async';

import '../../../services/translation_exception.dart';
import '../../../services/translation_service.dart';
import 'translation_state.dart';

/// BLoC / state controller for the translation workflow.
class TranslationBloc {
  final TranslationService _translationService;

  final _stateController = StreamController<TranslationState>.broadcast();
  Stream<TranslationState> get stateStream => _stateController.stream;

  TranslationState _currentState = const TranslationInitial();
  TranslationState get currentState => _currentState;

  /// Default source (auto-detected languages fall back to English) and target (Persian).
  static const String defaultSourceLanguage = 'en';
  static const String defaultTargetLanguage = 'fa';

  TranslationBloc({required this._translationService});

  void _emit(TranslationState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> translate({
    required String text,
    String sourceLanguage = defaultSourceLanguage,
    String targetLanguage = defaultTargetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      _emit(const TranslationFailure('No text to translate'));
      return;
    }

    _emit(const TranslationLoading());
    await Future.microtask(() {});

    try {
      final translated = await _translationService.translateText(
        text,
        sourceLanguage,
        targetLanguage,
      );

      if (translated != null && translated.trim().isNotEmpty) {
        _emit(
          TranslationSuccess(originalText: text, translatedText: translated),
        );
      } else {
        _emit(
          const TranslationFailure(
            'Translation returned no result. Check the provider in Settings.',
          ),
        );
      }
    } on TranslationException catch (e) {
      // Backends raise this with a message that is already safe to display.
      _emit(TranslationFailure(e.message));
    } catch (_) {
      // Never surface a raw exception: a PlatformException carries a native
      // stack trace that means nothing to the user (and can leak internals).
      _emit(
        const TranslationFailure(
          'Translation failed. Check the translation provider in Settings.',
        ),
      );
    }
  }

  void dispose() {
    _stateController.close();
  }
}
