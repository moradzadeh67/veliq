import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/history/bloc/history_bloc.dart';
import 'package:veliq/features/ocr/bloc/ocr_bloc.dart';
import 'package:veliq/features/settings/bloc/settings_bloc.dart';
import 'package:veliq/features/translation/bloc/translate_flow_bloc.dart';
import 'package:veliq/features/translation/bloc/translation_bloc.dart';
import 'package:veliq/main.dart';
import 'package:veliq/models/screen_region.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/capture_service.dart';
import 'package:veliq/services/history_repository.dart';
import 'package:veliq/services/ocr_service.dart';
import 'package:veliq/services/selection_service.dart';
import 'package:veliq/services/settings_repository.dart';
import 'package:veliq/services/translation_service.dart';

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<TranslationEntry>> load() async => <TranslationEntry>[];

  @override
  Future<void> add(TranslationEntry entry) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => AppSettings.defaults;

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeCaptureService implements CaptureService {
  @override
  Future<Uint8List?> captureRegion({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async => null;
}

class _FakeSelectionService implements SelectionService {
  @override
  Future<ScreenRegion?> selectRegion() async => null;
}

class _FakeOcrService implements OcrService {
  @override
  Future<String?> recognizeText(Uint8List imageBytes) async => null;
}

class _FakeTranslationService implements TranslationService {
  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async => null;
}

void main() {
  testWidgets('Veliq app boots into the shell with the translate workflow', (
    WidgetTester tester,
  ) async {
    final historyRepository = _FakeHistoryRepository();
    final ocrBloc = OcrBloc(ocrService: _FakeOcrService());
    final translationBloc = TranslationBloc(
      translationService: _FakeTranslationService(),
    );

    final historyBloc = HistoryBloc(historyRepository: historyRepository);
    final settingsBloc = SettingsBloc(
      settingsRepository: _FakeSettingsRepository(),
    );
    final translateFlowBloc = TranslateFlowBloc(
      captureService: _FakeCaptureService(),
      ocrBloc: ocrBloc,
      translationBloc: translationBloc,
      historyRepository: historyRepository,
      settingsRepository: _FakeSettingsRepository(),
    );

    addTearDown(() {
      translateFlowBloc.dispose();
      ocrBloc.dispose();
      translationBloc.dispose();
      historyBloc.dispose();
      settingsBloc.dispose();
    });

    await tester.pumpWidget(
      VeliqApp(
        historyBloc: historyBloc,
        settingsBloc: settingsBloc,
        translateFlowBloc: translateFlowBloc,
        selectionService: _FakeSelectionService(),
      ),
    );
    await tester.pumpAndSettle();

    // The translate workflow is now the landing screen, not a placeholder.
    // Pinned to macOS: the idle landing on Android offers the photo flow (T-132).
    expect(find.text('Select region'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
