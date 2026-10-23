import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/history/bloc/history_bloc.dart';
import 'package:veliq/features/history/history_view.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/history_repository.dart';

class FakeHistoryRepository implements HistoryRepository {
  final List<TranslationEntry> entries = <TranslationEntry>[];

  @override
  Future<List<TranslationEntry>> load() async {
    final copy = List<TranslationEntry>.from(entries);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  @override
  Future<void> add(TranslationEntry entry) async => entries.add(entry);

  @override
  Future<void> delete(String id) async =>
      entries.removeWhere((e) => e.id == id);

  @override
  Future<void> clear() async => entries.clear();
}

TranslationEntry _entry(
  String id, {
  String sourceLanguage = 'en',
  String targetLanguage = 'fa',
}) => TranslationEntry(
  id: id,
  originalText: 'Hello $id',
  translatedText: 'سلام $id',
  sourceLanguage: sourceLanguage,
  targetLanguage: targetLanguage,
  createdAt: DateTime(2024, 1, 1),
);

Future<void> _pumpView(WidgetTester tester, HistoryBloc bloc) {
  return tester.pumpWidget(MaterialApp(home: HistoryView(bloc: bloc)));
}

void main() {
  group('HistoryView Widget Tests', () {
    late FakeHistoryRepository repository;
    late HistoryBloc bloc;

    setUp(() {
      repository = FakeHistoryRepository();
      bloc = HistoryBloc(historyRepository: repository);
    });

    tearDown(() {
      bloc.dispose();
    });

    testWidgets('shows an empty-state message when there is no history', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('renders one tile per stored entry', (tester) async {
      repository.entries.addAll([_entry('1'), _entry('2')]);

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('Hello 1'), findsOneWidget);
      expect(find.text('Hello 2'), findsOneWidget);
      expect(find.text('سلام 1'), findsOneWidget);
    });

    testWidgets('shows the language pair and timestamp on each tile', (
      tester,
    ) async {
      repository.entries.add(_entry('1'));

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('English → Persian'), findsOneWidget);
      expect(find.textContaining('2024-01-01 00:00'), findsOneWidget);
    });

    testWidgets('an auto-detected entry shows the real source language', (
      tester,
    ) async {
      repository.entries.add(
        _entry('1', sourceLanguage: 'fr', targetLanguage: 'fa'),
      );

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('French → Persian'), findsOneWidget);
      expect(find.textContaining('FR →'), findsNothing);
    });

    testWidgets('translated text is rendered right-to-left', (tester) async {
      repository.entries.add(_entry('1'));

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      final translated = tester.widget<Text>(find.text('سلام 1'));
      expect(translated.textDirection, TextDirection.rtl);
    });

    testWidgets('tapping a row delete button removes that entry', (
      tester,
    ) async {
      repository.entries.addAll([_entry('1'), _entry('2')]);

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(repository.entries, hasLength(1));
    });

    testWidgets('clear-all asks for confirmation before deleting', (
      tester,
    ) async {
      repository.entries.add(_entry('1'));

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Clear history?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.entries, hasLength(1));
    });

    testWidgets('confirming clear-all empties the history', (tester) async {
      repository.entries.add(_entry('1'));

      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(repository.entries, isEmpty);
      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('clear-all action is disabled when history is empty', (
      tester,
    ) async {
      await _pumpView(tester, bloc);
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete_sweep_outlined),
          matching: find.byType(IconButton),
        ),
      );

      expect(button.onPressed, isNull);
    });
  });
}
