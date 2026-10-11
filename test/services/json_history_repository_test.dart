import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/json_history_repository.dart';

TranslationEntry _entry({
  required String id,
  String original = 'Hello',
  String translated = 'سلام',
  DateTime? createdAt,
}) {
  return TranslationEntry(
    id: id,
    originalText: original,
    translatedText: translated,
    sourceLanguage: 'en',
    targetLanguage: 'fa',
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  group('TranslationEntry', () {
    test('round-trips through JSON', () {
      final entry = _entry(id: 'a', createdAt: DateTime(2024, 5, 6, 7, 8, 9));

      final restored = TranslationEntry.fromJson(entry.toJson());

      expect(restored, equals(entry));
    });
  });

  group('JsonHistoryRepository', () {
    late Directory tempDir;
    late File file;
    late JsonHistoryRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('veliq_history_test');
      file = File('${tempDir.path}/history.json');
      repository = JsonHistoryRepository(file: file);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('load returns empty list when file does not exist', () async {
      expect(await repository.load(), isEmpty);
    });

    test('add persists an entry and load returns it', () async {
      await repository.add(_entry(id: '1'));

      final entries = await repository.load();

      expect(entries, hasLength(1));
      expect(entries.first.id, equals('1'));
      expect(entries.first.originalText, equals('Hello'));
    });

    test('add creates the parent directory if missing', () async {
      final nested = File('${tempDir.path}/a/b/history.json');
      final nestedRepo = JsonHistoryRepository(file: nested);

      await nestedRepo.add(_entry(id: '1'));

      expect(await nested.exists(), isTrue);
      expect(await nestedRepo.load(), hasLength(1));
    });

    test('load returns entries newest first', () async {
      await repository.add(_entry(id: 'old', createdAt: DateTime(2024, 1, 1)));
      await repository.add(_entry(id: 'new', createdAt: DateTime(2024, 6, 1)));
      await repository.add(_entry(id: 'mid', createdAt: DateTime(2024, 3, 1)));

      final entries = await repository.load();

      expect(entries.map((e) => e.id).toList(), equals(['new', 'mid', 'old']));
    });

    test('add with an existing id replaces instead of duplicating', () async {
      await repository.add(_entry(id: '1', translated: 'first'));
      await repository.add(_entry(id: '1', translated: 'second'));

      final entries = await repository.load();

      expect(entries, hasLength(1));
      expect(entries.first.translatedText, equals('second'));
    });

    test('delete removes only the matching entry', () async {
      await repository.add(_entry(id: '1'));
      await repository.add(_entry(id: '2'));

      await repository.delete('1');

      final entries = await repository.load();
      expect(entries, hasLength(1));
      expect(entries.first.id, equals('2'));
    });

    test('delete of an unknown id is a no-op', () async {
      await repository.add(_entry(id: '1'));

      await repository.delete('nope');

      expect(await repository.load(), hasLength(1));
    });

    test('clear removes all entries and the file', () async {
      await repository.add(_entry(id: '1'));
      await repository.add(_entry(id: '2'));

      await repository.clear();

      expect(await repository.load(), isEmpty);
      expect(await file.exists(), isFalse);
    });

    test('load tolerates a malformed file', () async {
      await file.writeAsString('{ not valid json');

      expect(await repository.load(), isEmpty);
    });

    test('load tolerates a valid JSON file that is not a list', () async {
      await file.writeAsString('{"unexpected": true}');

      expect(await repository.load(), isEmpty);
    });

    test('load skips individually corrupt records', () async {
      final good = _entry(id: 'good').toJson();
      final payload = jsonEncode([
        good,
        {'id': 'broken'}, // missing required fields
      ]);
      await file.writeAsString(payload);

      final entries = await repository.load();

      expect(entries, hasLength(1));
      expect(entries.first.id, equals('good'));
    });

    test('empty file loads as empty history', () async {
      await file.writeAsString('   ');

      expect(await repository.load(), isEmpty);
    });
  });
}
