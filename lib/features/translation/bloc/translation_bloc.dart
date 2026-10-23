import 'dart:async';

import '../../../models/language.dart';
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
      final outcome = await _translationService.translateWithDetection(
        text,
        sourceLanguage,
        targetLanguage,
      );
      final translated = outcome.text;

      if (translated != null && translated.trim().isNotEmpty) {
        // A translation in the wrong writing system means the photo was not
        // read correctly, not that the model failed (T-162). Showing it would
        // put gibberish in front of the user and in History.
        final misread = _misreadReason(text, translated, targetLanguage);
        if (misread != null) {
          _emit(TranslationFailure(misread));
          return;
        }

        _emit(
          TranslationSuccess(
            originalText: text,
            translatedText: translated,
            detectedSourceLanguage: outcome.detectedSourceLanguage,
          ),
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

  /// The writing system a target language must be written in, when we can
  /// recognise it. Latin-script targets are absent: Latin gibberish is
  /// indistinguishable from Latin words by script alone.
  static final Map<String, RegExp> _targetScript = {
    'fa': _arabicScript,
    'ar': _arabicScript,
    'ru': _cyrillicScript,
    'zh': _hanScript,
    'ja': _japaneseScript,
    'ko': _hangulScript,
  };

  static final RegExp _arabicScript = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  static final RegExp _cyrillicScript = RegExp(r'[\u0400-\u04FF]');
  static final RegExp _hanScript = RegExp(r'[\u4E00-\u9FFF]');
  static final RegExp _japaneseScript = RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]');
  static final RegExp _hangulScript = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF]');
  static final RegExp _letters = RegExp(r'\p{L}', unicode: true);

  /// Explains a translation that came back in the source's writing system, or
  /// `null` when the answer is plausible.
  ///
  /// A photo of Cyrillic or Arabic text on Android is "read" by the Latin-only
  /// model as look-alike Latin letters, so the translator dutifully returns
  /// Latin gibberish. Users read that as a broken translator, when the real
  /// limit is the OCR model — say so instead.
  static String? _misreadReason(
    String source,
    String translation,
    String targetLanguage,
  ) {
    final expected = _targetScript[targetLanguage];
    if (expected == null) return null;
    // Nothing to translate (numbers, a URL): an unchanged answer is fine.
    if (!_letters.hasMatch(source)) return null;
    if (expected.hasMatch(translation)) return null;

    final name = LanguageCatalog.displayName(targetLanguage);
    return "The translation came back without any $name text, so the photo was "
        'probably misread rather than mistranslated. Veliq only reads Latin '
        'script on Android, which is why Persian, Arabic, Russian, Chinese, '
        'Japanese and Korean photos cannot be read there yet. Try a photo with '
        'Latin text, or use the macOS or iOS app for those languages.';
  }

  void dispose() {
    _stateController.close();
  }
}
