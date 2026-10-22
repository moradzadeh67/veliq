import '../models/language.dart';

/// Which backend performs the actual translation.
enum TranslationProvider {
  /// Apple's on-device Translation framework.
  ///
  /// Free and fully offline, but limited to the languages Apple ships
  /// (roughly 21). Notably, Persian is **not** one of them, so this provider
  /// cannot be used for an `fa` target.
  apple,

  /// Google's Gemini API (`generativelanguage.googleapis.com`).
  ///
  /// Requires a user-supplied API key and sends the extracted text — never the
  /// screenshot — to Google. Supports Persian.
  ///
  /// Gemini rather than Cloud Translation: Cloud Translation answers a plain
  /// API key with `CREDENTIALS_MISSING` for many projects and demands OAuth2,
  /// which a desktop app cannot ship without exposing a private key.
  google,
}

/// Immutable user-configurable application settings.
class AppSettings {
  /// Language the OCR text is translated from (ISO 639-1, e.g. `en`), or
  /// [LanguageCatalog.autoCode] to detect it.
  final String sourceLanguage;

  /// Language the OCR text is translated to (ISO 639-1, e.g. `fa`).
  final String targetLanguage;

  /// Whether captured screenshots are kept alongside history entries.
  /// Defaults to `false` — see docs/PRIVACY.md (screenshots stay local & transient).
  final bool saveScreenshots;

  /// Which backend translates the text.
  final TranslationProvider translationProvider;

  /// Google AI (Gemini) API key. Only required when
  /// [translationProvider] is [TranslationProvider.google].
  final String? googleApiKey;

  const AppSettings({
    this.sourceLanguage = defaultSourceLanguage,
    this.targetLanguage = defaultTargetLanguage,
    this.saveScreenshots = false,
    this.translationProvider = defaultTranslationProvider,
    this.googleApiKey,
  });

  /// New installs start from auto-detect so any language's text works without
  /// the user having to pick a source first (T-151).
  static const String defaultSourceLanguage = LanguageCatalog.autoCode;
  static const String defaultTargetLanguage = 'fa';

  /// Google is the default because the app's target language (Persian) is not
  /// supported by Apple's on-device engine at all.
  static const TranslationProvider defaultTranslationProvider =
      TranslationProvider.google;

  /// The defaults used when nothing has been persisted yet.
  static const AppSettings defaults = AppSettings();

  /// Whether a usable Google API key has been configured.
  bool get hasGoogleApiKey =>
      googleApiKey != null && googleApiKey!.trim().isNotEmpty;

  AppSettings copyWith({
    String? sourceLanguage,
    String? targetLanguage,
    bool? saveScreenshots,
    TranslationProvider? translationProvider,
    String? googleApiKey,
  }) {
    return AppSettings(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      saveScreenshots: saveScreenshots ?? this.saveScreenshots,
      translationProvider: translationProvider ?? this.translationProvider,
      googleApiKey: googleApiKey ?? this.googleApiKey,
    );
  }

  /// Returns a copy with the stored Google API key removed.
  ///
  /// [copyWith] treats `null` as "leave unchanged", so clearing the key needs
  /// its own entry point.
  AppSettings withoutGoogleApiKey() {
    return AppSettings(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      saveScreenshots: saveScreenshots,
      translationProvider: translationProvider,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.sourceLanguage == sourceLanguage &&
        other.targetLanguage == targetLanguage &&
        other.saveScreenshots == saveScreenshots &&
        other.translationProvider == translationProvider &&
        other.googleApiKey == googleApiKey;
  }

  @override
  int get hashCode => Object.hash(
    sourceLanguage,
    targetLanguage,
    saveScreenshots,
    translationProvider,
    googleApiKey,
  );

  @override
  String toString() =>
      'AppSettings(sourceLanguage: $sourceLanguage, '
      'targetLanguage: $targetLanguage, '
      'saveScreenshots: $saveScreenshots, '
      'translationProvider: ${translationProvider.name}, '
      'googleApiKey: ${googleApiKey == null ? 'null' : '<redacted>'})';
}

/// Abstract interface for reading and persisting [AppSettings].
abstract class SettingsRepository {
  /// Loads the persisted settings, falling back to [AppSettings.defaults]
  /// for any value that has never been written.
  Future<AppSettings> load();

  /// Persists [settings], replacing any previously stored values.
  Future<void> save(AppSettings settings);
}
