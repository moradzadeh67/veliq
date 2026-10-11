import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/history/bloc/history_bloc.dart';
import 'package:veliq/features/history/bloc/history_state.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/history_repository.dart';

class InMemoryHistoryRepository implements HistoryRepository {
  final List<TranslationEntry> entries = <TranslationEntry>[];
  bool shouldThrow = false;

  @override
  Future<List<TranslationEntry>> load() async {
    if (shouldThrow) throw Exception('load failed');
    final copy = List<TranslationEntry>.from(entries);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  @override
  Future<void> add(TranslationEntry entry) async {
    if (shouldThrow) throw Exception('add failed');
    entries.removeWhere((e) => e.id == entry.id);
    entries.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    if (shouldThrow) throw Exception('delete failed');
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    if (shouldThrow) throw Exception('clear failed');
    entries.clear();
  }
}

TranslationEntry _entry(String id, {DateTime? createdAt}) {
  return TranslationEntry(
    id: id,
    originalText: 'Hello $id',
    translatedText: 'سلام $id',
    sourceLanguage: 'en',
    targetLanguage: 'fa',
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  group('HistoryBloc Tests', () {
    late InMemoryHistoryRepository repository;
    late HistoryBloc historyBloc;

    setUp(() {
      repository = InMemoryHistoryRepository();
      historyBloc = HistoryBloc(historyRepository: repository);
    });

    tearDown(() {
      historyBloc.dispose();
    });

    test('initial state is HistoryInitial', () {
      expect(historyBloc.currentState, isA<HistoryInitial>());
    });

    test(
      'load emits HistoryLoaded with an empty list when there is no data',
      () async {
        await historyBloc.load();

        expect(historyBloc.currentState, isA<HistoryLoaded>());
        expect((historyBloc.currentState as HistoryLoaded).entries, isEmpty);
      },
    );

    test('load returns stored entries newest first', () async {
      repository.entries.addAll([
        _entry('old', createdAt: DateTime(2024, 1, 1)),
        _entry('new', createdAt: DateTime(2024, 6, 1)),
      ]);

      await historyBloc.load();

      final entries = (historyBloc.currentState as HistoryLoaded).entries;
      expect(entries.map((e) => e.id).toList(), equals(['new', 'old']));
    });

    test('add persists the entry and refreshes state', () async {
      await historyBloc.add(_entry('1'));

      expect(repository.entries, hasLength(1));
      expect((historyBloc.currentState as HistoryLoaded).entries, hasLength(1));
    });

    test('delete removes the entry and refreshes state', () async {
      await historyBloc.add(_entry('1'));
      await historyBloc.add(_entry('2'));

      await historyBloc.delete('1');

      final entries = (historyBloc.currentState as HistoryLoaded).entries;
      expect(entries.map((e) => e.id).toList(), equals(['2']));
    });

    test('clear removes everything and refreshes state', () async {
      await historyBloc.add(_entry('1'));
      await historyBloc.add(_entry('2'));

      await historyBloc.clear();

      expect((historyBloc.currentState as HistoryLoaded).entries, isEmpty);
    });

    test('load emits HistoryFailure when the repository throws', () async {
      repository.shouldThrow = true;

      await historyBloc.load();

      expect(historyBloc.currentState, isA<HistoryFailure>());
    });

    test('add emits HistoryFailure when the repository throws', () async {
      repository.shouldThrow = true;

      await historyBloc.add(_entry('1'));

      expect(historyBloc.currentState, isA<HistoryFailure>());
    });

    test('stateStream forwards each transition', () async {
      final states = <HistoryState>[];
      final subscription = historyBloc.stateStream.listen(states.add);

      await historyBloc.load();
      // Let the broadcast controller flush its pending deliveries.
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states, hasLength(2));
      expect(states[0], isA<HistoryLoading>());
      expect(states[1], isA<HistoryLoaded>());
    });
  });
}
