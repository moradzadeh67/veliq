import 'package:shared_preferences/shared_preferences.dart';

import 'settings_repository.dart';

/// A [SettingsRepository] backed by [SharedPreferences]
/// (NSUserDefaults on macOS).
///
/// All keys are namespaced under `veliq.` to avoid collisions with other
/// plugins that share the same defaults domain.
class PrefsSettingsRepository implements SettingsRepository {
  static const String _sourceLanguageKey = 'veliq.settings.sourceLanguage';
  static const String _targetLanguageKey = 'veliq.settings.targetLanguage';
  static const String _saveScreenshotsKey = 'veliq.settings.saveScreenshots';
  static const String _translationProviderKey =
      'veliq.settings.translationProvider';
  static const String _googleApiKeyKey = 'veliq.settings.googleApiKey';

  /// Optional pre-resolved instance. When omitted, the instance is resolved
  /// lazily on each call, which is convenient in production but slower.
  final SharedPreferences? _prefs;

  PrefsSettingsRepository({this._prefs});

  Future<SharedPreferences> _instance() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Maps a stored provider name back to its enum value, tolerating values
  /// written by an older or newer build.
  static TranslationProvider _parseProvider(String? raw) {
    for (final provider in TranslationProvider.values) {
      if (provider.name == raw) return provider;
    }
    return AppSettings.defaultTranslationProvider;
  }

  @override
  Future<AppSettings> load() async {
    final prefs = await _instance();

    return AppSettings(
      sourceLanguage:
          prefs.getString(_sourceLanguageKey) ??
          AppSettings.defaultSourceLanguage,
      targetLanguage:
          prefs.getString(_targetLanguageKey) ??
          AppSettings.defaultTargetLanguage,
      saveScreenshots:
          prefs.getBool(_saveScreenshotsKey) ??
          AppSettings.defaults.saveScreenshots,
      translationProvider: _parseProvider(
        prefs.getString(_translationProviderKey),
      ),
      googleApiKey: prefs.getString(_googleApiKeyKey),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await _instance();

    await prefs.setString(_sourceLanguageKey, settings.sourceLanguage);
    await prefs.setString(_targetLanguageKey, settings.targetLanguage);
    await prefs.setBool(_saveScreenshotsKey, settings.saveScreenshots);
    await prefs.setString(
      _translationProviderKey,
      settings.translationProvider.name,
    );

    // Clear rather than store an empty string, so a removed key doesn't linger.
    final apiKey = settings.googleApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await prefs.remove(_googleApiKeyKey);
    } else {
      await prefs.setString(_googleApiKeyKey, apiKey);
    }
  }
}
