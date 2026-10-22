/// A language the translator can read or produce.
///
/// The catalog is deliberately static: it describes what Veliq's UI offers, not
/// what a particular platform's OCR can read. Per-platform capability is queried
/// at runtime through `OcrService.supportedLanguages()` (see D-018).
class Language {
  /// ISO 639-1 code, e.g. `en`, `fa`. The pseudo-code `auto` is only used as a
  /// *source* option and is never a real language.
  final String code;

  /// English name, used for prompts and labels, e.g. `Persian`.
  final String englishName;

  /// Name in the language itself, e.g. `فارسی`.
  final String nativeName;

  /// Whether the language is written right-to-left.
  final bool isRtl;

  const Language({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.isRtl,
  });
}

/// The languages Veliq offers, plus the `auto` source pseudo-language.
class LanguageCatalog {
  /// Source-only pseudo-code meaning "let the OCR and the translator detect it".
  static const String autoCode = 'auto';

  /// The pseudo-language shown as `Auto-detect` in the source picker.
  static const Language auto = Language(
    code: autoCode,
    englishName: 'Auto-detect',
    nativeName: 'Auto-detect',
    isRtl: false,
  );

  /// Real languages only — never contains [auto].
  static const List<Language> all = [
    Language(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      isRtl: false,
    ),
    Language(
      code: 'fa',
      englishName: 'Persian',
      nativeName: 'فارسی',
      isRtl: true,
    ),
    Language(
      code: 'ar',
      englishName: 'Arabic',
      nativeName: 'العربية',
      isRtl: true,
    ),
    Language(
      code: 'de',
      englishName: 'German',
      nativeName: 'Deutsch',
      isRtl: false,
    ),
    Language(
      code: 'fr',
      englishName: 'French',
      nativeName: 'Français',
      isRtl: false,
    ),
    Language(
      code: 'es',
      englishName: 'Spanish',
      nativeName: 'Español',
      isRtl: false,
    ),
    Language(
      code: 'it',
      englishName: 'Italian',
      nativeName: 'Italiano',
      isRtl: false,
    ),
    Language(
      code: 'ru',
      englishName: 'Russian',
      nativeName: 'Русский',
      isRtl: false,
    ),
    Language(
      code: 'tr',
      englishName: 'Turkish',
      nativeName: 'Türkçe',
      isRtl: false,
    ),
    Language(
      code: 'zh',
      englishName: 'Chinese',
      nativeName: '中文',
      isRtl: false,
    ),
    Language(
      code: 'ja',
      englishName: 'Japanese',
      nativeName: '日本語',
      isRtl: false,
    ),
    Language(
      code: 'pt',
      englishName: 'Portuguese',
      nativeName: 'Português',
      isRtl: false,
    ),
    Language(
      code: 'nl',
      englishName: 'Dutch',
      nativeName: 'Nederlands',
      isRtl: false,
    ),
    Language(
      code: 'ko',
      englishName: 'Korean',
      nativeName: '한국어',
      isRtl: false,
    ),
  ];

  /// Options for the "From" picker: [auto] first, then every language.
  static const List<Language> sourceOptions = [auto, ...all];

  /// Options for the "To" picker: every language, never [auto].
  static const List<Language> targetOptions = all;

  /// Returns the language for [code], or `null` when it is unknown.
  static Language? byCode(String code) {
    if (code == autoCode) return auto;
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// English display name for [code]; falls back to the raw code.
  static String displayName(String code) => byCode(code)?.englishName ?? code;
}
