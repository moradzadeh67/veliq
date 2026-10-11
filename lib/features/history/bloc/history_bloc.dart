import 'dart:async';

import '../../../models/translation_entry.dart';
import '../../../services/history_repository.dart';
import 'history_state.dart';

/// BLoC / state controller for the translation history feature.
///
/// Owns no persistence logic itself; it delegates to a [HistoryRepository]
/// so it stays testable with an in-memory fake.
class HistoryBloc {
  final HistoryRepository _repository;

  final _stateController = StreamController<HistoryState>.broadcast();
  Stream<HistoryState> get stateStream => _stateController.stream;

  HistoryState _currentState = const HistoryInitial();
  HistoryState get currentState => _currentState;

  HistoryBloc({required HistoryRepository historyRepository})
    : _repository = historyRepository;

  void _emit(HistoryState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Loads all stored entries, emitting [HistoryLoading] then [HistoryLoaded].
  Future<void> load() async {
    _emit(const HistoryLoading());
    await Future.microtask(() {});
    try {
      final entries = await _repository.load();
      _emit(HistoryLoaded(entries));
    } catch (e) {
      _emit(HistoryFailure(e.toString()));
    }
  }

  /// Records a new [entry] and refreshes the list.
  Future<void> add(TranslationEntry entry) async {
    try {
      await _repository.add(entry);
      await load();
    } catch (e) {
      _emit(HistoryFailure(e.toString()));
    }
  }

  /// Removes the entry with [id] and refreshes the list.
  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
    } catch (e) {
      _emit(HistoryFailure(e.toString()));
    }
  }

  /// Removes every entry.
  Future<void> clear() async {
    try {
      await _repository.clear();
      await load();
    } catch (e) {
      _emit(HistoryFailure(e.toString()));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
