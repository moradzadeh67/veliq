import 'dart:convert';
import 'dart:io';

import '../models/translation_entry.dart';
import 'history_repository.dart';

/// Default location of the history file: the app's folder inside
/// `~/Library/Application Support`, which is local-only and not synced.
String defaultHistoryFilePath() {
  final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
  return '$home/Library/Application Support/veliq/history.json';
}

/// A [HistoryRepository] that persists entries as a JSON array on disk.
///
/// Stored newest-first. The backing file is injectable so tests can point at a
/// temporary directory. Malformed or missing files are treated as empty history
/// rather than throwing, so a corrupted file can never block app startup.
class JsonHistoryRepository implements HistoryRepository {
  final File _file;

  JsonHistoryRepository({File? file})
    : _file = file ?? File(defaultHistoryFilePath());

  /// The backing file, exposed for diagnostics/tests.
  File get file => _file;

  @override
  Future<List<TranslationEntry>> load() async {
    if (!await _file.exists()) {
      return <TranslationEntry>[];
    }

    try {
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) {
        return <TranslationEntry>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <TranslationEntry>[];
      }

      final entries = <TranslationEntry>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            entries.add(
              TranslationEntry.fromJson(Map<String, dynamic>.from(item)),
            );
          } on Object {
            // Skip individual corrupt records instead of failing the whole load.
          }
        }
      }

      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } on FormatException {
      return <TranslationEntry>[];
    } on FileSystemException {
      return <TranslationEntry>[];
    }
  }

  @override
  Future<void> add(TranslationEntry entry) async {
    final entries = await load();
    entries.removeWhere((e) => e.id == entry.id);
    entries.insert(0, entry);
    await _write(entries);
  }

  @override
  Future<void> delete(String id) async {
    final entries = await load();
    final removed = entries.length;
    entries.removeWhere((e) => e.id == id);
    if (entries.length != removed) {
      await _write(entries);
    }
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  Future<void> _write(List<TranslationEntry> entries) async {
    await _file.parent.create(recursive: true);
    final payload = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _file.writeAsString(payload, flush: true);
  }
}
