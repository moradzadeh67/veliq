import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/ocr/bloc/ocr_bloc.dart';
import 'package:veliq/features/translation/bloc/translate_flow_bloc.dart';
import 'package:veliq/features/translation/bloc/translate_flow_state.dart';
import 'package:veliq/features/translation/bloc/translation_bloc.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/capture_service.dart';
import 'package:veliq/services/history_repository.dart';
import 'package:veliq/services/image_source_service.dart';
import 'package:veliq/services/ocr_service.dart';
import 'package:veliq/services/settings_repository.dart';
import 'package:veliq/services/translation_service.dart';

class _FakeCaptureService implements CaptureService {
  Uint8List? result;
  Object? error;
  int calls = 0;

  @override
  Future<Uint8List?> captureRegion({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeImageSourceService implements ImageSourceService {
  Uint8List? galleryBytes;
  Uint8List? cameraBytes;

  @override
  Future<Uint8List?> pickFromGallery() async => galleryBytes;

  @override
  Future<Uint8List?> takePhoto() async => cameraBytes;
}

class _FakeOcrService implements OcrService {
  String? text;
  String? lastLanguageHint;

  @override
  Future<String?> recognizeText(
    Uint8List imageBytes, {
    String? languageHint,
  }) async {
    lastLanguageHint = languageHint;
    return text;
  }

  @override
  Future<Set<String>> supportedLanguages() async => const {'en'};
}

class _FakeTranslationService implements TranslationService {
  String? translated;

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async => translated;
}

class _FakeHistoryRepository implements HistoryRepository {
  final List<TranslationEntry> entries = <TranslationEntry>[];
  bool shouldThrow = false;

  @override
  Future<List<TranslationEntry>> load() async => List.of(entries);

  @override
  Future<void> add(TranslationEntry entry) async {
    if (shouldThrow) throw Exception('disk full');
    entries.add(entry);
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

void main() {
  group('TranslateFlowBloc Tests', () {
    late _FakeCaptureService captureService;
    late _FakeOcrService ocrService;
    late _FakeTranslationService translationService;
    late _FakeHistoryRepository historyRepository;
    late _FakeSettingsRepository settingsRepository;
    late OcrBloc ocrBloc;
    late TranslationBloc translationBloc;
    late TranslateFlowBloc flowBloc;

    setUp(() {
      captureService = _FakeCaptureService()
        ..result = Uint8List.fromList([1, 2, 3]);
      ocrService = _FakeOcrService()..text = 'Hello world';
      translationService = _FakeTranslationService()..translated = 'سلام دنیا';
      historyRepository = _FakeHistoryRepository();
      settingsRepository = _FakeSettingsRepository();

      ocrBloc = OcrBloc(ocrService: ocrService);
      translationBloc = TranslationBloc(translationService: translationService);

      flowBloc = TranslateFlowBloc(
        captureService: captureService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: historyRepository,
        settingsRepository: settingsRepository,
        idGenerator: () => 'test-id',
        clock: () => DateTime(2024, 5, 1, 12, 30),
      );
    });

    tearDown(() {
      flowBloc.dispose();
      ocrBloc.dispose();
      translationBloc.dispose();
    });

    Future<void> run() =>
        flowBloc.runForRect(x: 0, y: 0, width: 100, height: 50);

    test('initial state is idle', () {
      expect(flowBloc.currentState, isA<TranslateFlowIdle>());
    });

    test('startSelection emits TranslateFlowSelecting', () {
      flowBloc.startSelection();
      expect(flowBloc.currentState, isA<TranslateFlowSelecting>());
    });

    test('cancel returns to idle', () {
      flowBloc.startSelection();
      flowBloc.cancel();
      expect(flowBloc.currentState, isA<TranslateFlowIdle>());
    });

    test('happy path ends in success with both texts', () async {
      await run();

      final state = flowBloc.currentState;
      expect(state, isA<TranslateFlowSuccess>());
      final success = state as TranslateFlowSuccess;
      expect(success.originalText, equals('Hello world'));
      expect(success.translatedText, equals('سلام دنیا'));
      expect(success.sourceLanguage, equals('auto'));
      expect(success.targetLanguage, equals('fa'));
    });

    test('happy path saves exactly one history entry', () async {
      await run();

      expect(historyRepository.entries, hasLength(1));
      final entry = historyRepository.entries.single;
      expect(entry.id, equals('test-id'));
      expect(entry.originalText, equals('Hello world'));
      expect(entry.translatedText, equals('سلام دنیا'));
      expect(entry.createdAt, equals(DateTime(2024, 5, 1, 12, 30)));
    });

    test('the capture rect is forwarded to the capture service', () async {
      await flowBloc.runForRect(x: 5, y: 10, width: 200, height: 300);

      expect(captureService.calls, equals(1));
    });

    test('uses the persisted language pair from settings', () async {
      settingsRepository.stored = const AppSettings(
        sourceLanguage: 'de',
        targetLanguage: 'fr',
      );

      await run();

      final success = flowBloc.currentState as TranslateFlowSuccess;
      expect(success.sourceLanguage, equals('de'));
      expect(success.targetLanguage, equals('fr'));
    });

    test('passes the source language to OCR as a hint', () async {
      settingsRepository.stored = const AppSettings(sourceLanguage: 'fr');

      await run();

      expect(ocrService.lastLanguageHint, equals('fr'));
    });

    test('hints auto-detect on a fresh install', () async {
      await run();

      expect(ocrService.lastLanguageHint, equals('auto'));
    });

    test('emits each processing stage in order', () async {
      final states = <TranslateFlowState>[];
      final subscription = flowBloc.stateStream.listen(states.add);

      await run();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states, [
        isA<TranslateFlowCapturing>(),
        isA<TranslateFlowRecognizing>(),
        isA<TranslateFlowTranslating>(),
        isA<TranslateFlowSuccess>(),
      ]);
    });

    test(
      'null capture result fails at the capture stage with a hint',
      () async {
        captureService.result = null;

        await run();

        final state = flowBloc.currentState as TranslateFlowFailure;
        expect(state.stage, equals(TranslateFlowStage.capture));
        expect(state.message, contains('Screen Recording'));
      },
    );

    test('empty capture result also fails at the capture stage', () async {
      captureService.result = Uint8List(0);

      await run();

      final state = flowBloc.currentState as TranslateFlowFailure;
      expect(state.stage, equals(TranslateFlowStage.capture));
    });

    test('a thrown capture error fails at the capture stage', () async {
      captureService.error = Exception('permission denied');

      await run();

      final state = flowBloc.currentState as TranslateFlowFailure;
      expect(state.stage, equals(TranslateFlowStage.capture));
      expect(state.message, contains('permission denied'));
    });

    test('no OCR text fails at the recognize stage', () async {
      ocrService.text = null;

      await run();

      final state = flowBloc.currentState as TranslateFlowFailure;
      expect(state.stage, equals(TranslateFlowStage.recognize));
    });

    test('whitespace-only OCR text fails at the recognize stage', () async {
      ocrService.text = '   \n  ';

      await run();

      final state = flowBloc.currentState as TranslateFlowFailure;
      expect(state.stage, equals(TranslateFlowStage.recognize));
    });

    test('a null translation fails at the translate stage', () async {
      translationService.translated = null;

      await run();

      final state = flowBloc.currentState as TranslateFlowFailure;
      expect(state.stage, equals(TranslateFlowStage.translate));
    });

    test('nothing is saved to history when the pipeline fails', () async {
      ocrService.text = null;

      await run();

      expect(historyRepository.entries, isEmpty);
    });

    test('a history write failure still surfaces the translation', () async {
      historyRepository.shouldThrow = true;

      await run();

      expect(flowBloc.currentState, isA<TranslateFlowSuccess>());
    });

    test('pickFromGallery happy path ends in success', () async {
      final imageSourceService = _FakeImageSourceService()
        ..galleryBytes = Uint8List.fromList([1, 2, 3]);

      final localBloc = TranslateFlowBloc(
        captureService: captureService,
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: historyRepository,
        settingsRepository: settingsRepository,
      );

      await localBloc.pickFromGallery();

      expect(localBloc.currentState, isA<TranslateFlowSuccess>());
      localBloc.dispose();
    });

    test('pickFromGallery null bytes returns to idle', () async {
      final imageSourceService = _FakeImageSourceService();

      final localBloc = TranslateFlowBloc(
        captureService: captureService,
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: historyRepository,
        settingsRepository: settingsRepository,
      );

      await localBloc.pickFromGallery();

      expect(localBloc.currentState, isA<TranslateFlowIdle>());
      localBloc.dispose();
    });

    test('takePhoto happy path ends in success', () async {
      final imageSourceService = _FakeImageSourceService()
        ..cameraBytes = Uint8List.fromList([4, 5, 6]);

      final localBloc = TranslateFlowBloc(
        captureService: captureService,
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: historyRepository,
        settingsRepository: settingsRepository,
      );

      await localBloc.takePhoto();

      expect(localBloc.currentState, isA<TranslateFlowSuccess>());
      localBloc.dispose();
    });

    test('takePhoto null bytes returns to idle', () async {
      final imageSourceService = _FakeImageSourceService();

      final localBloc = TranslateFlowBloc(
        captureService: captureService,
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: historyRepository,
        settingsRepository: settingsRepository,
      );

      await localBloc.takePhoto();

      expect(localBloc.currentState, isA<TranslateFlowIdle>());
      localBloc.dispose();
    });
  });
}
