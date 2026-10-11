import '../../../models/translation_entry.dart';

/// Base class for history states.
///
/// `sealed` so that UI can switch over states exhaustively without a default.
sealed class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  /// Entries, newest first.
  final List<TranslationEntry> entries;

  const HistoryLoaded(this.entries);

  bool get isEmpty => entries.isEmpty;
}

class HistoryFailure extends HistoryState {
  final String message;

  const HistoryFailure(this.message);
}
