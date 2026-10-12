import 'package:shared_preferences/shared_preferences.dart';

import 'keychain_api_key_store.dart';
import 'settings_repository.dart';

/// A [SettingsRepository] backed by [SharedPreferences]
/// (NSUserDefaults on macOS) for simple values and the Keychain
/// ([ApiKeyStore]) for the Google API key.
///
/// All keys are namespaced under `veliq.` to avoid collisions with other
/// plugins that share the same defaults domain.
class PrefsSettingsRepository implements SettingsRepository {
  static const String _sourceLanguageKey = 'veliq.settings.sourceLanguage';
  static const String _targetLanguageKey = 'veliq.settings.targetLanguage';
  static const String _saveScreenshotsKey = 'veliq.settings.saveScreenshots';
  static const String _translationProviderKey =
      'veliq.settings.translationProvider';

  static const String _legacyApiKeyKey = 'veliq.settings.googleApiKey';

  /// Optional pre-resolved instance. When omitted, the instance is resolved
  /// lazily on each call, which is convenient in production but slower.
  final SharedPreferences? prefs;

  /// Where the Google API key is persisted (Keychain). Defaults to a
  /// production [KeychainApiKeyStore]; tests inject a fake here.
  final ApiKeyStore _apiKeyStore;

  PrefsSettingsRepository({this.prefs, ApiKeyStore? apiKeyStore})
    : _apiKeyStore = apiKeyStore ?? const KeychainApiKeyStore();

  Future<SharedPreferences> _instance() async {
    return prefs ?? await SharedPreferences.getInstance();
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
      googleApiKey: await _loadApiKey(),
    );
  }

  /// Returns the API key, migrating it from shared_preferences if necessary.
  ///
  /// One-time migration (D-009): if an old key exists in shared_preferences
  /// under `veliq.settings.googleApiKey`, copy it to the Keychain, then remove
  /// it from shared_preferences so it no longer lingers in the plist.
  Future<String?> _loadApiKey() async {
    final p = await _instance();

    final legacyKey = p.getString(_legacyApiKeyKey);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _apiKeyStore.write(legacyKey);
      await p.remove(_legacyApiKeyKey);
      return legacyKey;
    }

    return _apiKeyStore.read();
  }

  @override
  Future<void> save(AppSettings settings) async {
    final p = await _instance();

    await p.setString(_sourceLanguageKey, settings.sourceLanguage);
    await p.setString(_targetLanguageKey, settings.targetLanguage);
    await p.setBool(_saveScreenshotsKey, settings.saveScreenshots);
    await p.setString(
      _translationProviderKey,
      settings.translationProvider.name,
    );

    // Key is stored in the Keychain, not in shared_preferences.
    final apiKey = settings.googleApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await _apiKeyStore.delete();
    } else {
      await _apiKeyStore.write(apiKey);
    }
  }
}
