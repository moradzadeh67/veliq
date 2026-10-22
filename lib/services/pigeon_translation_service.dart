import 'package:flutter/services.dart';

import '../pigeon/messages.g.dart';
import 'translation_exception.dart';
import 'translation_service.dart';

/// Implementation of [TranslationService] using Pigeon to communicate with the
/// native macOS Translation framework (on-device, free, offline).
///
/// Native failures are converted into [TranslationException]s so a raw
/// `PlatformException` — which carries a native stack trace — never reaches
/// the UI.
class PigeonTranslationService extends TranslationService {
  final TranslationApi _api;

  PigeonTranslationService({TranslationApi? api})
    : _api = api ?? TranslationApi();

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      return await _api.translateText(text, sourceLanguage, targetLanguage);
    } on PlatformException catch (e) {
      throw TranslationException(_friendlyMessage(e), cause: e);
    } on MissingPluginException catch (e) {
      throw TranslationException(
        "Translation isn't available in this build.",
        cause: e,
      );
    }
  }

  /// Turns a native `TranslationError` into something a user can act on.
  ///
  /// The Swift side reports failures via the Pigeon error code/message/details,
  /// so the cause is matched against their textual form.
  static String _friendlyMessage(PlatformException error) {
    final details = '${error.code} ${error.message} ${error.details}';

    if (details.contains('unsupportedTargetLanguage') ||
        details.contains('unsupportedSourceLanguage') ||
        details.contains('unsupportedLanguagePairing')) {
      return "Apple's on-device translation engine doesn't support this language "
          'pair (Persian, for example, is not available). Choose another '
          'target language, or switch to Google Gemini in Settings.';
    }

    if (details.contains('unableToIdentifyLanguage')) {
      return "Apple's translation engine couldn't identify the source "
          'language. Set an explicit source language in Settings.';
    }

    return 'On-device translation failed. Check the language pair in Settings, '
        'or switch to Google Gemini.';
  }
}
