import 'dart:async';

import '../../../services/gemini_translation_service.dart';
import '../../../services/settings_repository.dart';
import 'settings_state.dart';

/// BLoC / state controller for user settings.
class SettingsBloc {
  final SettingsRepository _repository;

  /// Checks a Google API key on demand. Injected from the composition root so
  /// this layer never builds an HTTP client itself.
  final GoogleApiKeyVerifier? _googleApiKeyVerifier;

  /// Reports which languages this device's OCR can read. Injected from the
  /// composition root so the settings layer never talks to Pigeon directly.
  /// When absent, capability is unknown and the UI enables everything.
  final Future<Set<String>> Function()? _ocrLanguagesProvider;

  final _stateController = StreamController<SettingsState>.broadcast();
  Stream<SettingsState> get stateStream => _stateController.stream;

  SettingsState _currentState = const SettingsInitial();
  SettingsState get currentState => _currentState;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    this._googleApiKeyVerifier,
    this._ocrLanguagesProvider,
  }) : _repository = settingsRepository;

  void _emit(SettingsState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Currently loaded settings, or [AppSettings.defaults] before [load].
  AppSettings get settings {
    final state = _currentState;
    return state is SettingsLoaded ? state.settings : AppSettings.defaults;
  }

  /// Loads persisted settings, emitting [SettingsLoading] then [SettingsLoaded].
  Future<void> load() async {
    _emit(const SettingsLoading());
    await Future.microtask(() {});
    try {
      final settings = await _repository.load();
      _emit(SettingsLoaded(settings));
    } catch (e) {
      _emit(SettingsFailure(e.toString()));
    }
  }

  /// Persists [settings] and reflects them in state.
  Future<void> update(AppSettings settings) async {
    // Reflect the change immediately so the UI feels responsive, then persist.
    _emit(SettingsLoaded(settings));
    try {
      await _repository.save(settings);
    } catch (e) {
      _emit(SettingsFailure(e.toString()));
    }
  }

  /// Convenience helper: change the target (output) language.
  Future<void> setTargetLanguage(String languageCode) {
    return update(settings.copyWith(targetLanguage: languageCode));
  }

  /// Convenience helper: change the source (input) language.
  Future<void> setSourceLanguage(String languageCode) {
    return update(settings.copyWith(sourceLanguage: languageCode));
  }

  /// Convenience helper: toggle whether screenshots are retained.
  Future<void> setSaveScreenshots(bool enabled) {
    return update(settings.copyWith(saveScreenshots: enabled));
  }

  /// Convenience helper: change the translation backend.
  Future<void> setTranslationProvider(TranslationProvider provider) {
    return update(settings.copyWith(translationProvider: provider));
  }

  /// Convenience helper: store (or clear) the Google Cloud API key.
  ///
  /// Blank input clears the stored key rather than persisting an empty string.
  Future<void> setGoogleApiKey(String? apiKey) {
    final trimmed = apiKey?.trim();
    return update(
      trimmed == null || trimmed.isEmpty
          ? settings.withoutGoogleApiKey()
          : settings.copyWith(googleApiKey: trimmed),
    );
  }

  /// Tests whether [apiKey] can actually translate.
  ///
  /// Returns `null` when the key works, otherwise a message explaining what is
  /// wrong. Never throws: the UI only needs something to display.
  Future<String?> testGoogleApiKey(String apiKey) async {
    final verifier = _googleApiKeyVerifier;
    if (verifier == null) {
      return 'Key verification is not available in this build.';
    }

    final current = settings;
    try {
      return await verifier(
        apiKey,
        current.sourceLanguage,
        current.targetLanguage,
      );
    } catch (_) {
      return 'Could not verify the key: unexpected error.';
    }
  }

  /// Languages this device's OCR can read, or `null` when that is unknown
  /// (no provider injected, or the query failed). Callers must treat `null` as
  /// "every language is available" so a failed query never disables the UI.
  Future<Set<String>?> supportedOcrLanguages() async {
    final provider = _ocrLanguagesProvider;
    if (provider == null) return null;
    try {
      return await provider();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _stateController.close();
  }
}
