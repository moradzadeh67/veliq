import 'settings_repository.dart';
import 'translation_service.dart';

/// Routes each translation to the backend selected in [AppSettings].
///
/// This keeps [TranslationService] consumers (the blocs) unaware of providers:
/// they hold one service and always call `translateText`.
///
/// The cloud backend is built lazily and rebuilt whenever the stored API key
/// changes, so editing the key in Settings takes effect without a restart.
class SwitchingTranslationService implements TranslationService {
  final SettingsRepository _settings;

  /// The on-device (Apple) backend.
  final TranslationService _apple;

  /// Builds a cloud backend for [apiKey]. Injected so tests can supply a fake
  /// and so the service doesn't own HTTP concerns.
  final TranslationService Function(String apiKey) _googleFactory;

  TranslationService? _google;
  String? _googleKey;

  SwitchingTranslationService({
    required this._settings,
    required this._apple,
    required this._googleFactory,
  });

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final settings = await _settings.load();

    switch (settings.translationProvider) {
      case TranslationProvider.apple:
        return _apple.translateText(text, sourceLanguage, targetLanguage);
      case TranslationProvider.google:
        return _googleFor(settings)
            .translateText(text, sourceLanguage, targetLanguage);
    }
  }

  TranslationService _googleFor(AppSettings settings) {
    final key = settings.googleApiKey?.trim() ?? '';
    if (_google == null || _googleKey != key) {
      _googleKey = key;
      _google = _googleFactory(key);
    }
    return _google!;
  }
}
