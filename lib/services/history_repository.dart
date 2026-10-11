import '../models/translation_entry.dart';

/// Abstract interface for persisting and reading the translation history.
///
/// Implementations must be local-only (see docs/PRIVACY.md): no cloud sync.
abstract class HistoryRepository {
  /// Loads all stored entries, newest first.
  Future<List<TranslationEntry>> load();

  /// Persists [entry]; existing entries with the same id are replaced.
  Future<void> add(TranslationEntry entry);

  /// Removes the entry with [id], if present.
  Future<void> delete(String id);

  /// Removes every stored entry.
  Future<void> clear();
}
