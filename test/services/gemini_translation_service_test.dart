import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veliq/services/gemini_translation_service.dart';
import 'package:veliq/services/translation_exception.dart';

const String _apiKey = 'test-api-key';

GeminiTranslationService _serviceReturning(
  http.Response response, {
  void Function(http.Request request)? onRequest,
}) {
  return GeminiTranslationService(
    apiKey: _apiKey,
    client: MockClient((request) async {
      onRequest?.call(request);
      return response;
    }),
  );
}

http.Response _jsonResponse(Map<String, Object?> body, int status) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json'},
    );

http.Response _okResponse(String text) => _jsonResponse({
  'candidates': [
    {
      'content': {
        'role': 'model',
        'parts': [
          {'text': text},
        ],
      },
      'finishReason': 'STOP',
    },
  ],
}, 200);

/// An error envelope shaped the way Google actually sends them.
Map<String, Object?> _error(
  int code, {
  String? message,
  String? reason,
  String? legacyReason,
}) => {
  'error': {
    'code': code,
    'message': ?message,
    if (legacyReason != null)
      'errors': [
        {'reason': legacyReason},
      ],
    if (reason != null)
      'details': [
        {
          '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
          'reason': reason,
          'domain': 'googleapis.com',
        },
      ],
  },
};

Future<TranslationException> _expectFailure(
  Future<String?> Function() run,
) async {
  try {
    await run();
  } on TranslationException catch (e) {
    return e;
  }
  fail('Expected a TranslationException');
}

void main() {
  group('GeminiTranslationService', () {
    test('sends a generateContent request with the key in the query', () async {
      http.Request? sent;
      final service = _serviceReturning(
        _okResponse('سلام دنیا'),
        onRequest: (request) => sent = request,
      );

      final result = await service.translateText('Hello World', 'en', 'fa');

      expect(result, equals('سلام دنیا'));
      expect(sent!.method, equals('POST'));
      expect(sent!.url.scheme, equals('https'));
      expect(sent!.url.host, equals('generativelanguage.googleapis.com'));
      expect(sent!.url.path, contains('/v1beta/models/'));
      expect(sent!.url.path, endsWith(':generateContent'));
      expect(sent!.url.queryParameters['key'], equals(_apiKey));
    });

    test('asks the model for nothing but the translation', () async {
      final bodies = <String>[];
      final service = GeminiTranslationService(
        apiKey: _apiKey,
        client: MockClient((request) async {
          bodies.add(request.body);
          return _okResponse('x');
        }),
      );

      await service.translateText('Hello', 'en', 'fa');

      final decoded = jsonDecode(bodies.single) as Map<String, dynamic>;
      final contents = decoded['contents'] as List<Object?>;
      final parts =
          (contents.first as Map<String, dynamic>)['parts'] as List<Object?>;
      final prompt = (parts.first as Map<String, dynamic>)['text'] as String;

      expect(prompt, contains('Hello'));
      expect(prompt, contains('"en"'));
      expect(prompt, contains('"fa"'));
      expect(prompt, contains('only the translation'));
      // The original wording gave the model an escape hatch, and it took it:
      // a region of source code came back untranslated.
      expect(prompt, contains('never echo'));
      expect(prompt, contains('translate the words inside it'));
      expect(
        (decoded['generationConfig'] as Map<String, dynamic>)['temperature'],
        equals(0),
      );
    });

    test('stitches a reply that arrives in several parts', () async {
      final service = _serviceReturning(
        _jsonResponse({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'سلام '},
                  {'text': 'دنیا'},
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        }, 200),
      );

      expect(
        await service.translateText('Hello World', 'en', 'fa'),
        equals('سلام دنیا'),
      );
    });

    test('throws a friendly error when no key is configured', () async {
      var called = false;
      final service = GeminiTranslationService(
        apiKey: '   ',
        client: MockClient((_) async {
          called = true;
          return _okResponse('x');
        }),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('No Google AI API key'));
      expect(called, isFalse);
    });

    test('maps API_KEY_INVALID to an invalid-key message', () async {
      final service = _serviceReturning(
        _jsonResponse(
          _error(400, legacyReason: 'badRequest', reason: 'API_KEY_INVALID'),
          400,
        ),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('not valid'));
      expect(error.message, isNot(contains('badRequest')));
    });

    test('maps CREDENTIALS_MISSING to the AI Studio hint', () async {
      // This is the answer Cloud Translation gives for a plain API key — the
      // exact wall the Cloud backend hit.
      final service = _serviceReturning(
        _jsonResponse(
          _error(
            401,
            message: 'API keys are not supported by this API.',
            reason: 'CREDENTIALS_MISSING',
          ),
          401,
        ),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('aistudio.google.com/apikey'));
    });

    test('maps SERVICE_DISABLED to an enable-the-API message', () async {
      final service = _serviceReturning(
        _jsonResponse(_error(403, reason: 'SERVICE_DISABLED'), 403),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('Generative Language API is not enabled'));
    });

    test('maps a 429 to a rate-limit message', () async {
      final service = _serviceReturning(
        _jsonResponse(_error(429, reason: 'RESOURCE_EXHAUSTED'), 429),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message.toLowerCase(), contains('rate limit'));
    });

    test('names the model when Gemini does not know it', () async {
      final service = _serviceReturning(
        _jsonResponse(_error(404, reason: 'NOT_FOUND'), 404),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains(GeminiTranslationService.defaultModel));
    });

    test("shows Google's code when it is one we do not script", () async {
      final service = _serviceReturning(
        _jsonResponse(_error(403, reason: 'CONSUMER_SUSPENDED'), 403),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('CONSUMER_SUSPENDED'));
    });

    test('never leaks the API key or the free-form message', () async {
      final service = _serviceReturning(
        _jsonResponse(
          _error(
            400,
            message: 'API key not valid: $_apiKey',
            reason: 'API_KEY_INVALID',
          ),
          400,
        ),
      );

      final error = await _expectFailure(
        () => service.translateText('super-secret-text', 'en', 'fa'),
      );

      expect(error.message, isNot(contains(_apiKey)));
      expect(error.message, isNot(contains('super-secret-text')));
      expect(error.message, isNot(contains('not valid:')));
    });

    test('explains a safety block reported up front', () async {
      final service = _serviceReturning(
        _jsonResponse({
          'promptFeedback': {'blockReason': 'SAFETY'},
        }, 200),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message.toLowerCase(), contains('safety filter'));
    });

    test('explains a candidate stopped by the safety filter', () async {
      final service = _serviceReturning(
        _jsonResponse({
          'candidates': [
            {'finishReason': 'SAFETY'},
          ],
        }, 200),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message.toLowerCase(), contains('safety filter'));
    });

    test('explains a reply truncated by the token limit', () async {
      final service = _serviceReturning(
        _jsonResponse({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'partial'},
                ],
              },
              'finishReason': 'MAX_TOKENS',
            },
          ],
        }, 200),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('too long'));
    });

    test('returns null when the response carries no candidate', () async {
      final service = _serviceReturning(_jsonResponse({'candidates': []}, 200));

      expect(await service.translateText('Hello', 'en', 'fa'), isNull);
    });

    test('throws when the response body is not valid JSON', () async {
      final service = _serviceReturning(http.Response('not json', 200));

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error, isA<TranslationException>());
    });

    test('names the status when Gemini fails unexpectedly', () async {
      final service = _serviceReturning(
        _jsonResponse(_error(503, reason: 'UNAVAILABLE'), 503),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      // A bare "temporarily unavailable" is undiagnosable.
      expect(error.message, contains('503'));
    });

    test('retries once when Gemini reports a transient 5xx', () async {
      var calls = 0;
      final service = GeminiTranslationService(
        apiKey: _apiKey,
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? _jsonResponse(_error(503), 503)
              : _okResponse('سلام دنیا');
        }),
      );

      expect(
        await service.translateText('Hello', 'en', 'fa'),
        equals('سلام دنیا'),
      );
      expect(calls, equals(2));
    });

    test('retries once when the first attempt hangs', () async {
      var calls = 0;
      final service = GeminiTranslationService(
        apiKey: _apiKey,
        timeout: const Duration(milliseconds: 40),
        client: MockClient((_) async {
          calls++;
          if (calls == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          }
          return _okResponse('سلام دنیا');
        }),
      );

      expect(
        await service.translateText('Hello', 'en', 'fa'),
        equals('سلام دنیا'),
      );
      expect(calls, equals(2));
    });

    test('gives up after the retry and clears the key of blame', () async {
      final service = GeminiTranslationService(
        apiKey: _apiKey,
        timeout: const Duration(milliseconds: 30),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return _okResponse('x');
        }),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      // A hang says nothing about the key, and the message must not imply it does.
      expect(error.message, contains('not an API-key problem'));
      expect(error.message, contains('retry'));
    });

    test('appends the raw reason when diagnostics are enabled', () async {
      final service = GeminiTranslationService(
        apiKey: _apiKey,
        includeDiagnostics: true,
        client: MockClient(
          (_) async => _jsonResponse(
            _error(
              503,
              message: 'The model is overloaded for key $_apiKey',
              reason: 'UNAVAILABLE',
            ),
            503,
          ),
        ),
      );

      final error = await _expectFailure(
        () => service.translateText('Hello', 'en', 'fa'),
      );

      expect(error.message, contains('503'));
      expect(error.message, contains('UNAVAILABLE'));
      expect(error.message, contains('overloaded'));
      // Even with diagnostics on, the key must never survive into the message.
      expect(error.message, isNot(contains(_apiKey)));
      expect(error.message, contains('<redacted>'));
    });
  });

  group('verifyApiKey', () {
    test('returns null when the key works', () async {
      final service = _serviceReturning(_okResponse('Hola'));

      expect(
        await service.verifyApiKey(sourceLanguage: 'en', targetLanguage: 'fa'),
        isNull,
      );
    });

    test('returns the reason when the key is rejected', () async {
      final service = _serviceReturning(
        _jsonResponse(_error(400, reason: 'API_KEY_INVALID'), 400),
      );

      final result = await service.verifyApiKey(
        sourceLanguage: 'en',
        targetLanguage: 'fa',
      );

      expect(result, contains('not valid'));
    });

    test('reports a blank key without calling Google', () async {
      var called = false;
      final service = GeminiTranslationService(
        apiKey: '',
        client: MockClient((_) async {
          called = true;
          return _okResponse('x');
        }),
      );

      final result = await service.verifyApiKey(
        sourceLanguage: 'en',
        targetLanguage: 'fa',
      );

      expect(result, contains('API key'));
      expect(called, isFalse);
    });
  });
}
