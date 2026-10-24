import '../models/language.dart';
import 'settings_repository.dart';
import 'translation_exception.dart';
import 'translation_service.dart';

/// Routes each translation to the backend selected in [AppSettings].
///
/// This keeps [TranslationService] consumers (the blocs) unaware of providers:
/// they hold one service and always call `translateText`.
///
/// The cloud backend is built lazily and rebuilt whenever the stored API key
/// changes, so editing the key in Settings takes effect without a restart.
class SwitchingTranslationService extends TranslationService {
  final SettingsRepository settings;
  final TranslationService apple;
  final TranslationService googleTranslate;
  final TranslationService Function(String apiKey) googleFactory;

  TranslationService? _google;
  String? _googleKey;

  SwitchingTranslationService({
    required this.settings,
    required this.apple,
    required this.googleTranslate,
    required this.googleFactory,
  });

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final outcome = await translateWithDetection(
      text,
      sourceLanguage,
      targetLanguage,
    );
    return outcome.text;
  }

  @override
  Future<TranslationOutcome> translateWithDetection(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final settings = await _loadFor(sourceLanguage);

    switch (settings.translationProvider) {
      case TranslationProvider.apple:
        // Apple cannot report a detected language, so `auto` stays `auto`.
        return TranslationOutcome(
          await apple.translateText(text, sourceLanguage, targetLanguage),
        );
      case TranslationProvider.google:
        return _googleFor(settings)
            .translateWithDetection(text, sourceLanguage, targetLanguage);
      case TranslationProvider.googleTranslate:
        return googleTranslate.translateWithDetection(
          text,
          sourceLanguage,
          targetLanguage,
        );
    }
  }

  /// Loads the settings and enforces the one combination a provider cannot do.
  ///
  /// Apple's Translation framework cannot take "auto" (T-154): it needs a
  /// concrete source language, so say so instead of failing natively.
  Future<AppSettings> _loadFor(String sourceLanguage) async {
    final s = await settings.load();
    if (s.translationProvider == TranslationProvider.apple &&
        sourceLanguage == LanguageCatalog.autoCode) {
      throw const TranslationException(
        'On-device translation needs a specific source language. Choose one in '
        'Settings, or switch to Google Gemini.',
      );
    }
    return s;
  }

  TranslationService _googleFor(AppSettings settings) {
    final key = settings.googleApiKey?.trim() ?? '';
    if (_google == null || _googleKey != key) {
      _googleKey = key;
      _google = googleFactory(key);
    }
    return _google!;
  }
}
