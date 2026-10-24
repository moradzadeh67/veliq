import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veliq/services/google_translate_free_service.dart';
import 'package:veliq/services/translation_exception.dart';

http.Response _jsonResponse(String body, [int status = 200]) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('GoogleTranslateFreeService', () {
    test('empty or whitespace input makes no network call', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return _jsonResponse('[]');
      });

      final service = GoogleTranslateFreeService(client: client);
      final result = await service.translateText('   ', 'auto', 'fa');

      expect(result, equals(''));
      expect(called, isFalse);
    });

    test('parses multi-segment responses in order', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['sl'], equals('en'));
        expect(request.url.queryParameters['tl'], equals('fa'));
        return _jsonResponse(
          '[[["سلام ","Hello "],["دنیا","world"]],null,"en"]',
        );
      });

      final service = GoogleTranslateFreeService(client: client);
      final outcome = await service.translateWithDetection(
        'Hello world',
        'en',
        'fa',
      );

      expect(outcome.text, equals('سلام دنیا'));
      // Explicit source ('en') -> no detected language reported.
      expect(outcome.detectedSourceLanguage, isNull);
    });

    test('reports detected language only when source is auto', () async {
      final client = MockClient((_) async {
        return _jsonResponse('[[["سلام","Hello"]],null,"en"]');
      });

      final service = GoogleTranslateFreeService(client: client);
      final outcome = await service.translateWithDetection(
        'Hello',
        'auto',
        'fa',
      );

      expect(outcome.text, equals('سلام'));
      expect(outcome.detectedSourceLanguage, equals('en'));
    });

    test('normalises detected language zh-CN to zh', () async {
      final client = MockClient((_) async {
        return _jsonResponse('[[["سلام","你好"]],null,"zh-CN"]');
      });

      final service = GoogleTranslateFreeService(client: client);
      final outcome = await service.translateWithDetection('你好', 'auto', 'fa');

      expect(outcome.detectedSourceLanguage, equals('zh'));
    });

    test('maps zh source and target to zh-CN in wire request', () async {
      late String sentSl;
      late String sentTl;
      final client = MockClient((request) async {
        sentSl = request.url.queryParameters['sl']!;
        sentTl = request.url.queryParameters['tl']!;
        return _jsonResponse('[[["你好","Hello"]],null,"en"]');
      });

      final service = GoogleTranslateFreeService(client: client);
      await service.translateText('Hello', 'zh', 'zh');

      expect(sentSl, equals('zh-CN'));
      expect(sentTl, equals('zh-CN'));
    });

    group('unwraps hard-wrapped OCR lines before translating (T-168)', () {
      late List<String> sent;
      late GoogleTranslateFreeService service;

      setUp(() {
        sent = <String>[];
        service = GoogleTranslateFreeService(
          client: MockClient((request) async {
            sent.add(request.bodyFields['q'] ?? '');
            return _jsonResponse('[[["ok","ok"]],null,"fr"]');
          }),
        );
      });

      Future<void> send(String text) async {
        await service.translateText(text, 'fr', 'en');
      }

      test('joins French OCR lines into one sentence', () async {
        await send(
          'En rangeant les\nrayonnages\npoussiéreux, il\n'
          'découvrit un livre\nsans titre.',
        );

        expect(sent, hasLength(1));
        expect(
          sent.single,
          equals(
            'En rangeant les rayonnages poussiéreux, il découvrit un livre '
            'sans titre.',
          ),
        );
      });

      test('keeps the break when every line ends a sentence', () async {
        await send('Première phrase.\nDeuxième phrase.');

        expect(sent.single, equals('Première phrase.\nDeuxième phrase.'));
      });

      test('keeps a blank line as a single paragraph break', () async {
        await send('Une ligne\ndeux lignes\n\nTrois lignes\nquatre lignes');

        expect(
          sent.single,
          equals('Une ligne deux lignes\n\nTrois lignes quatre lignes'),
        );
      });

      test('re-joins a hyphenated word split across lines', () async {
        await send('un fait bien-\nconnu');

        expect(sent.single, equals('un fait bienconnu'));
      });

      test('keeps Persian question lines separate', () async {
        await send('چرا؟\nنمی‌دانم');

        expect(sent.single, equals('چرا؟\nنمی‌دانم'));
      });

      test('leaves a single line unchanged', () async {
        await send('Bonjour le monde');

        expect(sent.single, equals('Bonjour le monde'));
      });
    });

    test(
      'missing data[2] in response reports null detected language',
      () async {
        final client = MockClient((_) async {
          return _jsonResponse('[[["سلام","Hello"]]]');
        });

        final service = GoogleTranslateFreeService(client: client);
        final outcome = await service.translateWithDetection(
          'Hello',
          'auto',
          'fa',
        );

        expect(outcome.text, equals('سلام'));
        expect(outcome.detectedSourceLanguage, isNull);
      },
    );

    test(
      'chunks ~4000 character text into several requests in order',
      () async {
        final requestedTexts = <String>[];
        final client = MockClient((request) async {
          final bodyText = request.bodyFields['q'] ?? '';
          requestedTexts.add(bodyText);
          return _jsonResponse('[[["ترجمه ","trans "]]]');
        });

        // Construct 3 paragraphs of ~1400 chars each.
        final p1 = 'A' * 1400;
        final p2 = 'B' * 1400;
        final p3 = 'C' * 1400;
        final fullText = '$p1\n$p2\n$p3';

        final service = GoogleTranslateFreeService(client: client);
        final result = await service.translateText(fullText, 'en', 'fa');

        expect(requestedTexts.length, greaterThan(1));
        expect(result, isNotNull);
        expect(result!.split('\n').length, equals(3));
      },
    );

    test('retries once on 429 and succeeds if second attempt is 200', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        if (attempts == 1) return http.Response('Rate limited', 429);
        return _jsonResponse('[[["سلام","Hello"]],null,"en"]');
      });

      final service = GoogleTranslateFreeService(
        client: client,
        rateLimitDelay: Duration.zero,
      );
      final result = await service.translateText('Hello', 'en', 'fa');

      expect(attempts, equals(2));
      expect(result, equals('سلام'));
    });

    test('throws rate-limit exception if 429 persists after retry', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        return http.Response('Rate limited', 429);
      });

      final service = GoogleTranslateFreeService(
        client: client,
        rateLimitDelay: Duration.zero,
      );

      await expectLater(
        service.translateText('Hello', 'en', 'fa'),
        throwsA(
          isA<TranslationException>().having(
            (e) => e.message,
            'message',
            equals(GoogleTranslateFreeService.rateLimitedMessage),
          ),
        ),
      );
      expect(attempts, equals(2));
    });

    test('maps non-200 status code to http error message', () async {
      final client = MockClient((_) async {
        return http.Response('Internal error', 500);
      });

      final service = GoogleTranslateFreeService(client: client);

      await expectLater(
        service.translateText('Hello', 'en', 'fa'),
        throwsA(
          isA<TranslationException>().having(
            (e) => e.message,
            'message',
            equals(GoogleTranslateFreeService.httpErrorMessage(500)),
          ),
        ),
      );
    });

    test('maps bad JSON reply to unexpected reply message', () async {
      final client = MockClient((_) async {
        return _jsonResponse('not valid json');
      });

      final service = GoogleTranslateFreeService(client: client);

      await expectLater(
        service.translateText('Hello', 'en', 'fa'),
        throwsA(
          isA<TranslationException>().having(
            (e) => e.message,
            'message',
            equals(GoogleTranslateFreeService.unexpectedReplyMessage),
          ),
        ),
      );
    });
  });
}
