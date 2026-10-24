import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../models/language.dart';
import 'translation_exception.dart';
import 'translation_service.dart';

/// Translates text through Google Translate's free web endpoint.
///
/// Unlike `GeminiTranslationService` this needs **no API key**, which is the
/// whole point: many users are in Iran, where the Gemini API is only reachable
/// behind a VPN while this endpoint answers directly (verified by the project
/// owner; see D-020 in docs/ARCHITECTURE.md).
///
/// It is an **unofficial** endpoint — the same one Google's own web client
/// calls. It can rate-limit or change without notice, so Gemini stays available
/// as the supported fallback. Errors are translated into short, display-safe
/// [TranslationException]s; the request text and the response body are never
/// put into a message.
///
/// Privacy: only the recognised text is sent — never the image, and there is no
/// key to leak. See docs/PRIVACY.md.
class GoogleTranslateFreeService implements TranslationService {
  /// Budget for a single attempt.
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// How long to wait before the single retry after an HTTP 429.
  static const Duration defaultRateLimitDelay = Duration(seconds: 2);

  /// The endpoint Google's web client uses.
  static const String endpoint =
      'https://translate.googleapis.com/translate_a/single';

  /// Google rejects very long `q` values, so lines are packed up to this many
  /// characters before being split across requests.
  static const int maxChunkChars = 1500;

  /// The `client` parameter that makes the endpoint answer. `gtx` is the web
  /// client's own value; it is the only one this app sends.
  static const String _clientParam = 'gtx';

  final http.Client _client;
  final Duration timeout;
  final Duration rateLimitDelay;

  GoogleTranslateFreeService({
    http.Client? client,
    this.timeout = defaultTimeout,
    this.rateLimitDelay = defaultRateLimitDelay,
  }) : _client = client ?? http.Client();

  /// Message shown when the endpoint rate-limits us (HTTP 429).
  static const String rateLimitedMessage =
      'Google Translate is limiting requests right now. Wait a minute and try '
      'again, or switch to Gemini in Settings.';

  /// Message shown for any other non-200 status.
  static String httpErrorMessage(int statusCode) =>
      'Google Translate returned an error (HTTP $statusCode). Try again later, '
      'or switch to Gemini in Settings.';

  /// Message shown when the request never reached Google.
  static const String unreachableMessage =
      "Can't reach Google Translate. Check your internet connection and try "
      'again.';

  /// Message shown when the reply is not the JSON shape we expect.
  static const String unexpectedReplyMessage =
      'Google Translate returned an unexpected reply. This free service is '
      'unofficial and may have changed — switch to Gemini in Settings.';

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
    // Nothing to translate: don't spend a request on it.
    if (text.trim().isEmpty) return const TranslationOutcome('');

    final detects = sourceLanguage == LanguageCatalog.autoCode;
    final source = _wireCode(sourceLanguage);
    final target = _wireCode(targetLanguage);

    final chunks = _chunk(text);
    final translated = <String>[];
    String? detected;

    // Sequential on purpose: hammering the free endpoint in parallel is exactly
    // what gets an IP rate-limited.
    for (var i = 0; i < chunks.length; i++) {
      final parsed = await _translateChunk(chunks[i], source, target);
      if (i == 0) detected = parsed.detected;
      translated.add(_stripTrailingNewlines(parsed.text));
    }

    return TranslationOutcome(
      translated.join('\n'),
      // An explicit source choice always wins over what Google reports.
      detectedSourceLanguage: detects ? detected : null,
    );
  }

  /// Sends one chunk, retrying once after [rateLimitDelay] when Google answers
  /// 429 before giving up with [rateLimitedMessage].
  Future<_ParsedReply> _translateChunk(
    String text,
    String source,
    String target,
  ) async {
    var response = await _send(text, source, target);

    if (response.statusCode == 429) {
      await Future<void>.delayed(rateLimitDelay);
      response = await _send(text, source, target);
    }

    if (response.statusCode == 429) {
      throw const TranslationException(rateLimitedMessage);
    }
    if (response.statusCode != 200) {
      throw TranslationException(httpErrorMessage(response.statusCode));
    }

    try {
      return _parse(response.body);
    } on FormatException catch (e) {
      throw TranslationException(unexpectedReplyMessage, cause: e);
    }
  }

  /// Performs one POST, mapping transport failures onto a readable message.
  Future<http.Response> _send(String text, String source, String target) async {
    final uri = Uri.parse(
      '$endpoint?client=$_clientParam&sl=$source&tl=$target&dt=t',
    );
    try {
      // POST keeps the text out of the URL, so there is no length ceiling.
      return await _client.post(uri, body: {'q': text}).timeout(timeout);
    } on TimeoutException catch (e) {
      throw TranslationException(unreachableMessage, cause: e);
    } on SocketException catch (e) {
      throw TranslationException(unreachableMessage, cause: e);
    } on http.ClientException catch (e) {
      throw TranslationException(unreachableMessage, cause: e);
    }
  }

  /// Parses `[[[translated, original, ...], ...], null, "detected", ...]`.
  ///
  /// Every segment's element `0` is a translated piece; they are joined in the
  /// order Google returned them, which already carries the original line
  /// breaks.
  static _ParsedReply _parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException('reply is not a list');
    }

    final segments = decoded[0];
    if (segments is! List) {
      throw const FormatException('reply has no segment list');
    }

    final buffer = StringBuffer();
    for (final segment in segments) {
      if (segment is List && segment.isNotEmpty && segment[0] is String) {
        buffer.write(segment[0] as String);
      }
    }

    // Element 2 is the detected source language; it may be absent.
    final rawDetected = decoded.length > 2 ? decoded[2] : null;
    return _ParsedReply(
      buffer.toString(),
      detected: rawDetected is String ? _normalizeCode(rawDetected) : null,
    );
  }

  /// Maps a catalog code onto the value Google expects.
  static String _wireCode(String code) {
    if (code == LanguageCatalog.autoCode) return 'auto';
    // Google wants the regional form for Chinese.
    if (code == 'zh') return 'zh-CN';
    return code;
  }

  /// Reduces a reported code to its base ISO 639-1 form: `zh-CN` -> `zh`.
  static String? _normalizeCode(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    return value.split(RegExp(r'[-_]')).first;
  }

  static String _stripTrailingNewlines(String value) =>
      value.replaceFirst(RegExp(r'\n+$'), '');

  /// Splits [text] into requests of at most [maxChunkChars] characters.
  ///
  /// Lines are kept whole where possible so the sentence context survives;
  /// a single over-long line is broken at the last space before the limit, or
  /// hard-split when it has no space at all.
  static List<String> _chunk(String text) {
    final units = <String>[];
    for (final line in text.split('\n')) {
      units.addAll(_splitLongLine(line));
    }

    final chunks = <String>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        chunks.add(buffer.toString());
        buffer.clear();
      }
    }

    for (final unit in units) {
      if (buffer.isEmpty) {
        buffer.write(unit);
      } else if (buffer.length + 1 + unit.length <= maxChunkChars) {
        buffer.write('\n');
        buffer.write(unit);
      } else {
        flush();
        buffer.write(unit);
      }
    }
    flush();
    return chunks;
  }

  static List<String> _splitLongLine(String line) {
    if (line.length <= maxChunkChars) return [line];

    final pieces = <String>[];
    var rest = line;
    while (rest.length > maxChunkChars) {
      var cut = rest.lastIndexOf(' ', maxChunkChars);
      if (cut <= 0) cut = maxChunkChars;
      pieces.add(rest.substring(0, cut));
      rest = rest.substring(cut).trimLeft();
    }
    pieces.add(rest);
    return pieces;
  }
}

/// One parsed response: the translated text plus any detected source language.
class _ParsedReply {
  final String text;
  final String? detected;

  const _ParsedReply(this.text, {this.detected});
}
