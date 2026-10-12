import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'translation_exception.dart';
import 'translation_service.dart';

/// Verifies that a Google AI (Gemini) API key can actually translate.
///
/// Returns `null` when the key works, or a user-facing explanation when it does
/// not, so the Settings screen can report a result instead of failing silently.
typedef GoogleApiKeyVerifier = Future<String?> Function(
  String apiKey,
  String sourceLanguage,
  String targetLanguage,
);

/// Translates text with Google's Gemini API.
///
/// Chosen over Cloud Translation (v2) because that API answers a plain API key
/// with `CREDENTIALS_MISSING` — "API keys are not supported by this API" — for
/// large classes of project, forcing OAuth2/service-account credentials. Gemini
/// accepts an ordinary API key, so a desktop app never has to ship a private
/// key. Only the OCR-extracted text is sent — screenshots never leave the
/// machine.
class GeminiTranslationService implements TranslationService {
  /// Default model: 3.5 Flash-Lite is Google's recommended model for new
  /// projects (https://ai.google.dev/gemini-api/docs/models, checked
  /// 2026-10-12). The 2.5 family answers HTTP 404 on keys that did not use it
  /// before, so it is not offered. No quota numbers are hard-coded here on
  /// purpose — Google publishes none statically (see D-005, ARCHITECTURE.md).
  static const String defaultModel = 'gemini-3.5-flash-lite';

  /// Fallback models tried in order if the primary model hits a 429 rate limit
  /// or 404 model-not-found error.
  static const List<String> fallbackModels = [
    'gemini-3.8-flash',
    'gemini-2.0-flash',
  ];

  /// Budget for a single attempt.
  ///
  /// Gemini's free tier is noticeably variable under load, so this is generous —
  /// and a retry covers the hang rather than making the user wait it out.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// How long to wait before the single retry.
  static const Duration retryDelay = Duration(milliseconds: 500);

  /// The `generateContent` endpoint for [model].
  static String endpointFor(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent';

  final String _apiKey;
  final String _model;
  final Duration _timeout;
  final http.Client _client;

  /// When true, a failure's message carries Google's own wording.
  ///
  /// Off by default so the UI never shows Google's free-form text — it can echo
  /// request details. The app opts in for debug builds, where an undiagnosable
  /// "temporarily unavailable" costs far more than the exposure.
  final bool _includeDiagnostics;

  GeminiTranslationService({
    required this._apiKey,
    this._model = defaultModel,
    this._timeout = defaultTimeout,
    http.Client? client,
    this._includeDiagnostics = false,
  }) : _client = client ?? http.Client();

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      throw const TranslationException(
        'No Google AI API key is configured. Add one in Settings.',
      );
    }

    final modelsToTry = <String>{_model, ...fallbackModels}.toList();

    http.Response? lastResponse;
    String? lastReason;
    String? lastModel;

    for (var i = 0; i < modelsToTry.length; i++) {
      final currentModel = modelsToTry[i];
      final uri = Uri.parse(endpointFor(currentModel))
          .replace(queryParameters: {'key': key});

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _buildPrompt(text, sourceLanguage, targetLanguage)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          if (currentModel.startsWith('gemini-3'))
            'thinkingConfig': const {'thinkingLevel': 'low'},
        },
      });

      final http.Response response;
      try {
        response = await _sendWithRetry(uri, body);
      } on TimeoutException catch (e) {
        if (i == modelsToTry.length - 1) {
          throw TranslationException(
            'Gemini did not answer in time, even after a retry. This is not an '
            'API-key problem — a bad key fails immediately. Free-tier keys are '
            'variable under load, so try again in a moment.',
            cause: e,
          );
        }
        continue;
      } catch (e) {
        if (i == modelsToTry.length - 1) {
          throw TranslationException(
            'Could not reach Gemini. Check your internet connection.',
            cause: e,
          );
        }
        continue;
      }

      if (response.statusCode == 200) {
        return _parseTranslatedText(response.body);
      }

      final reason = _errorReason(response.body);
      lastResponse = response;
      lastReason = reason;
      lastModel = currentModel;

      // If status is 429 (quota/rate limit) or 404 (model not found), try the next fallback model
      if ((response.statusCode == 429 || response.statusCode == 404) &&
          i < modelsToTry.length - 1) {
        if (kDebugMode) {
          debugPrint(
            '[GeminiTranslationService] Model $currentModel returned '
            'HTTP ${response.statusCode} ($reason). Falling back to next model...',
          );
        }
        continue;
      }

      // For invalid key (400), permission denied (403), or non-retryable status, fail out
      _logFailure(
        response.statusCode,
        reason,
        response.body,
        model: currentModel,
      );
      throw TranslationException(
        '${_messageForFailure(response.statusCode, reason)}'
        '${_diagnosticSuffix(response, reason, model: currentModel)}',
        cause:
            'HTTP ${response.statusCode}${reason == null ? '' : ' ($reason)'}',
      );
    }

    if (lastResponse != null) {
      _logFailure(
        lastResponse.statusCode,
        lastReason,
        lastResponse.body,
        model: lastModel,
      );
      throw TranslationException(
        '${_messageForFailure(lastResponse.statusCode, lastReason)}'
        '${_diagnosticSuffix(lastResponse, lastReason, model: lastModel)}',
        cause:
            'HTTP ${lastResponse.statusCode}${lastReason == null ? '' : ' ($lastReason)'}',
      );
    }

    return null;
  }

  /// Sends [body], retrying once when the attempt fails transiently.
  ///
  /// Two shapes of transient failure are covered: an explicit 5xx, and a request
  /// that simply never answers. Each attempt gets its own timeout, so a hung
  /// request costs one budget instead of hanging the UI indefinitely.
  Future<http.Response> _sendWithRetry(Uri uri, String body) async {
    try {
      final response = await _send(uri, body);
      if (response.statusCode < 500) return response;
    } on TimeoutException {
      // Fall through to the single retry below.
    }

    await Future<void>.delayed(retryDelay);
    return _send(uri, body);
  }

  Future<http.Response> _send(Uri uri, String body) {
    return _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: body,
        )
        .timeout(_timeout);
  }

  /// Proves the key works by performing one tiny translation.
  ///
  /// Returns `null` on success, otherwise the reason it failed.
  Future<String?> verifyApiKey({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final translated = await translateText(
        'Hello',
        sourceLanguage,
        targetLanguage,
      );
      if (translated == null || translated.trim().isEmpty) {
        return 'Gemini accepted the key but returned no translation.';
      }
      return null;
    } on TranslationException catch (e) {
      return e.message;
    }
  }

  /// Wraps the source text in an instruction that keeps the reply clean.
  ///
  /// The model is told to return nothing but the translation, because any
  /// conversational padding would land straight in the user's clipboard.
  static String _buildPrompt(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) {
    return 'You are a translation engine, not an assistant. Translate the text '
        'between the markers from language "$sourceLanguage" to language '
        '"$targetLanguage".\n'
        'Rules:\n'
        '- Output only the translation. No quotes, no notes, no explanations.\n'
        '- If the text is already entirely in "$targetLanguage", return it '
        'unchanged.\n'
        '- Otherwise translate every word into "$targetLanguage" — never echo '
        'the source text back.\n'
        '- Preserve the original line breaks, punctuation and layout.\n'
        '- Do not summarise, reorder or "fix" the content.\n'
        '- If the text looks like code, an identifier or a stray label, still '
        'translate the words inside it.\n'
        '---\n'
        '$text\n'
        '---';
  }

  /// Prints Gemini's raw error to the console, in debug builds only.
  ///
  /// The UI deliberately never shows this text — it can echo request details —
  /// but a bare reason code is often not enough to diagnose a failure. The API
  /// key is redacted, and release builds stay silent.
  void _logFailure(
    int httpStatus,
    String? reason,
    String body, {
    String? model,
  }) {
    if (!kDebugMode) return;

    final trimmedKey = _apiKey.trim();
    var message = _googleMessage(body);
    if (message != null && trimmedKey.isNotEmpty) {
      message = message.replaceAll(trimmedKey, '<redacted>');
    }

    debugPrint(
      '[GeminiTranslationService] model=${model ?? _model} HTTP $httpStatus '
      'reason=${reason ?? '-'} message=${message ?? '-'}',
    );
  }

  /// Appends Google's own words, in debug builds only.
  ///
  /// The API key is redacted, and release builds never see this.
  String _diagnosticSuffix(
    http.Response response,
    String? reason, {
    String? model,
  }) {
    if (!_includeDiagnostics) return '';

    var message = _googleMessage(response.body) ?? '<no message>';
    final trimmedKey = _apiKey.trim();
    if (trimmedKey.isNotEmpty) {
      message = message.replaceAll(trimmedKey, '<redacted>');
    }

    return '  [debug: model=${model ?? _model}, HTTP ${response.statusCode}, '
        'reason=${reason ?? '-'} — $message]';
  }

  /// Builds an actionable sentence for a failed request.
  static String _messageForFailure(int statusCode, String? reason) {
    final specific = _specificMessage(reason);
    if (specific != null) return specific;

    // Surface Google's own code when we have no scripted advice for it. It is
    // an enum-like token (never the free-form message, which can echo the key
    // back), so it is safe to show — and it is what makes a bare
    // "request failed" report actionable.
    final code = (reason == null || reason == 'PERMISSION_DENIED')
        ? ''
        : ' (Google code: $reason)';

    switch (statusCode) {
      case 400:
        return 'Gemini rejected the request$code. The API key may be invalid.';
      case 401:
      case 403:
        return 'Gemini denied access$code. Check that the Generative Language '
            'API is enabled for the project that owns this key.';
      case 404:
        return 'Gemini does not recognise the model "$defaultModel" for this '
            'key. Check that the key belongs to a project with the Generative '
            'Language API enabled.';
      case 429:
        return 'Gemini rate limit reached. Wait a moment and try again.';
      default:
        if (statusCode >= 500) {
          return 'Gemini is temporarily unavailable (HTTP $statusCode$code). '
              'Try again shortly.';
        }
        return 'Gemini returned an unexpected error (HTTP $statusCode$code).';
    }
  }

  /// Scripted advice for the failure codes we recognise, or `null`.
  ///
  /// Both vocabularies are covered: the modern `google.rpc.ErrorInfo` codes
  /// (`API_KEY_INVALID`) and the legacy lowercase ones.
  static String? _specificMessage(String? reason) {
    switch (reason) {
      // The exact answer Cloud Translation gives when handed a plain key. Also
      // what Gemini says when the supplied key is not an AI Studio key at all
      // (for example a Cloud API key copied from the wrong console page).
      case 'CREDENTIALS_MISSING':
        return 'This key is not accepted as a Gemini API key. Create one at '
            'https://aistudio.google.com/apikey and paste it here.';

      case 'API_KEY_INVALID':
      case 'API_KEY_NOT_VALID':
      case 'keyInvalid':
      case 'keyExpired':
        return 'This API key is not valid. Check that you copied the whole key.';

      case 'SERVICE_DISABLED':
      case 'accessNotConfigured':
        return 'The Generative Language API is not enabled on this Google Cloud '
            'project. Enable it in the Google Cloud console, wait a minute, '
            'then test again.';

      case 'PERMISSION_DENIED':
      case 'forbidden':
        return 'This API key is not allowed to use the Gemini API. In Google AI '
            'Studio, create a key for a project with the Generative Language '
            'API enabled.';

      case 'RESOURCE_EXHAUSTED':
      case 'RATE_LIMIT_EXCEEDED':
      case 'rateLimitExceeded':
      case 'quotaExceeded':
      case 'dailyLimitExceeded':
      case 'usageLimits':
        return 'Gemini quota or rate limit reached. Wait a moment and try again, '
            'or check the billing status of the key\'s project.';

      case 'backendError':
        return 'Gemini is temporarily unavailable. Try again shortly.';

      default:
        return null;
    }
  }

  /// Reads Google's machine-readable reason code out of an error envelope.
  ///
  /// Only this enum-like token is read — never the free-form message, which can
  /// echo request details back.
  ///
  /// `error.details[]` is checked first on purpose: it carries the precise
  /// modern code (`API_KEY_INVALID`), whereas the legacy `error.errors[]` next
  /// to it only offers a coarse one (`badRequest`) for the very same failure.
  static String? _errorReason(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final error = decoded['error'];
      if (error is! Map<String, dynamic>) return null;

      for (final source in [error['details'], error['errors']]) {
        final reason = _firstReason(source);
        if (reason != null) return reason;
      }

      final status = error['status'];
      return status is String ? status : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first `reason` string inside [list], if any.
  static String? _firstReason(Object? list) {
    if (list is! List) return null;

    for (final entry in list) {
      if (entry is Map<String, dynamic> && entry['reason'] is String) {
        return entry['reason'] as String;
      }
    }

    return null;
  }

  /// Extracts Google's free-form `error.message`, for debug logging only.
  static String? _googleMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final error = decoded['error'];
      if (error is! Map<String, dynamic>) return null;

      final message = error['message'];
      return message is String ? message : null;
    } catch (_) {
      return null;
    }
  }

  /// Pulls the first candidate's text out of the `generateContent` envelope.
  static String? _parseTranslatedText(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (e) {
      throw TranslationException(
        'Gemini returned a response Veliq could not read.',
        cause: e,
      );
    }

    if (decoded is! Map<String, dynamic>) return null;

    final feedback = decoded['promptFeedback'];
    if (feedback is Map<String, dynamic>) {
      final blockReason = feedback['blockReason'];
      if (blockReason is String && blockReason.isNotEmpty) {
        throw TranslationException(
          'Gemini refused to translate this text (safety filter: '
          '$blockReason).',
        );
      }
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map<String, dynamic>) return null;

    switch (first['finishReason']) {
      case 'SAFETY':
      case 'PROHIBITED_CONTENT':
        throw const TranslationException(
          'Gemini refused to translate this text (safety filter).',
        );
      case 'MAX_TOKENS':
        throw const TranslationException(
          'The text was too long for Gemini to translate in one go.',
        );
    }

    final content = first['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    // A reply can be split across several parts; stitch them back together.
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic> && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }

    final translated = buffer.toString().trim();
    return translated.isEmpty ? null : translated;
  }
}
