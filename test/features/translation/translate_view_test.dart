import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/ocr/bloc/ocr_bloc.dart';
import 'package:veliq/features/translation/bloc/translate_flow_bloc.dart';
import 'package:veliq/features/translation/bloc/translation_bloc.dart';
import 'package:veliq/features/translation/translate_view.dart';
import 'package:veliq/models/screen_region.dart';
import 'package:veliq/models/translation_entry.dart';
import 'package:veliq/services/capture_service.dart';
import 'package:veliq/services/history_repository.dart';
import 'package:veliq/services/image_source_service.dart';
import 'package:veliq/services/ocr_service.dart';
import 'package:veliq/services/selection_service.dart';
import 'package:veliq/services/settings_repository.dart';
import 'package:veliq/services/translation_service.dart';

class _FakeCaptureService implements CaptureService {
  Uint8List? result = Uint8List.fromList([1, 2, 3]);

  double? lastX;
  double? lastY;
  double? lastWidth;
  double? lastHeight;

  @override
  Future<Uint8List?> captureRegion({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    lastX = x;
    lastY = y;
    lastWidth = width;
    lastHeight = height;
    return result;
  }
}

class _FakeImageSourceService implements ImageSourceService {
  Uint8List? galleryBytes;
  Uint8List? cameraBytes;

  int galleryCalls = 0;

  @override
  Future<Uint8List?> pickFromGallery() async {
    galleryCalls++;
    return galleryBytes;
  }

  @override
  Future<Uint8List?> takePhoto() async => cameraBytes;
}

class _FakeOcrService implements OcrService {
  String? text = 'Hello world';
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
  String? translated = 'سلام دنیا';

  @override
  Future<String?> translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async => translated;
}

class _FakeHistoryRepository implements HistoryRepository {
  final List<TranslationEntry> entries = <TranslationEntry>[];

  @override
  Future<List<TranslationEntry>> load() async => List.of(entries);

  @override
  Future<void> add(TranslationEntry entry) async => entries.add(entry);

  @override
  Future<void> delete(String id) async =>
      entries.removeWhere((e) => e.id == id);

  @override
  Future<void> clear() async => entries.clear();
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

/// Stands in for the native full-screen overlay.
///
/// The picker is exposed as a [Completer] so a test can inspect the app
/// *while* the user is choosing a region, and then decide how the picker ends.
///
/// The [Completer] is created lazily inside [selectRegion] on purpose: this
/// service is constructed in `setUp`, which runs outside the widget test's
/// fake-async zone. A `Completer` captures the zone it was created in, so one
/// built in `setUp` would resume `TranslateView` on the real event loop and
/// `pumpAndSettle` would return before the UI had rebuilt.
class _FakeSelectionService implements SelectionService {
  Completer<ScreenRegion?>? _pending;
  int calls = 0;

  @override
  Future<ScreenRegion?> selectRegion() {
    calls++;
    final completer = Completer<ScreenRegion?>();
    _pending = completer;
    return completer.future;
  }

  /// Simulates a completed drag of [region].
  void completeWith(ScreenRegion? region) {
    _pending?.complete(region);
    _pending = null;
  }
}

/// [testWidgets] pinned to macOS: on a desktop test host the default target
/// platform is Android, but this suite exercises the desktop flow (T-132).
void testWidgetsMac(String description, WidgetTesterCallback body) {
  testWidgets(
    description,
    body,
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

void main() {
  group('TranslateView Widget Tests', () {
    late _FakeCaptureService captureService;
    late _FakeOcrService ocrService;
    late _FakeTranslationService translationService;
    late _FakeSelectionService selectionService;
    late OcrBloc ocrBloc;
    late TranslationBloc translationBloc;
    late TranslateFlowBloc flowBloc;

    const region = ScreenRegion(x: 100, y: 200, width: 300, height: 150);

    setUp(() {
      captureService = _FakeCaptureService();
      ocrService = _FakeOcrService();
      translationService = _FakeTranslationService();
      selectionService = _FakeSelectionService();
      ocrBloc = OcrBloc(ocrService: ocrService);
      translationBloc = TranslationBloc(translationService: translationService);
      flowBloc = TranslateFlowBloc(
        captureService: captureService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: _FakeHistoryRepository(),
        settingsRepository: _FakeSettingsRepository(),
      );
    });

    tearDown(() {
      flowBloc.dispose();
      ocrBloc.dispose();
      translationBloc.dispose();
    });

    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: TranslateView(bloc: flowBloc, selectionService: selectionService),
      ),
    );

    /// Taps "Select region" and waits for the native picker to be presented.
    Future<void> openPicker(WidgetTester tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select region'));
      await tester.pumpAndSettle();
    }

    /// Ends the pending picker with [region] and lets the UI settle.
    ///
    /// The extra `pump` matters: completing the picker only resolves a future,
    /// which schedules no frame of its own, so `pumpAndSettle` on its own can
    /// return before [TranslateView] has resumed from its `await`.
    Future<void> closePicker(WidgetTester tester, ScreenRegion? result) async {
      selectionService.completeWith(result);
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgetsMac('shows the idle prompt with a select action', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Select region'), findsOneWidget);
      expect(find.textContaining('Select a region of the screen'), findsOne);
    });

    testWidgetsMac('tapping Select region asks the native picker to open', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(selectionService.calls, isZero);

      await tester.tap(find.text('Select region'));
      await tester.pumpAndSettle();

      expect(selectionService.calls, equals(1));
      // The in-app hint stands in for the native overlay while it is up.
      expect(find.textContaining('Drag anywhere on screen'), findsOneWidget);
    });

    testWidgetsMac(
      'the screen-space region is forwarded to the capture service',
      (tester) async {
        await openPicker(tester);
        await closePicker(tester, region);

        expect(captureService.lastX, equals(100));
        expect(captureService.lastY, equals(200));
        expect(captureService.lastWidth, equals(300));
        expect(captureService.lastHeight, equals(150));
      },
    );

    testWidgetsMac('completing a selection shows the translation', (
      tester,
    ) async {
      await openPicker(tester);
      await closePicker(tester, region);

      expect(find.text('سلام دنیا'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgetsMac('cancelling the picker returns to the idle state', (
      tester,
    ) async {
      await openPicker(tester);
      await closePicker(tester, null);

      expect(find.text('Select region'), findsOneWidget);
      expect(find.textContaining('Select a region of the screen'), findsOne);
    });

    testWidgetsMac('renders the translation right-to-left', (tester) async {
      await openPicker(tester);
      await closePicker(tester, region);

      final directionality = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.text('سلام دنیا'),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgetsMac('an empty capture shows the permission guidance', (
      tester,
    ) async {
      captureService.result = null;

      await openPicker(tester);
      await closePicker(tester, region);

      expect(find.text('Could not capture the screen'), findsOneWidget);
      expect(find.textContaining('Screen Recording'), findsWidgets);
    });

    testWidgetsMac('no OCR text shows the no-text guidance', (tester) async {
      ocrService.text = null;

      await openPicker(tester);
      await closePicker(tester, region);

      expect(find.text('No text found'), findsOneWidget);
    });

    testWidgetsMac('a failed translation mentions the macOS requirement', (
      tester,
    ) async {
      translationService.translated = null;

      await openPicker(tester);
      await closePicker(tester, region);

      expect(find.text('Translation failed'), findsOneWidget);
      expect(find.textContaining('macOS 26'), findsOneWidget);
    });

    testWidgetsMac('the failure state offers a retry action', (tester) async {
      ocrService.text = null;

      await openPicker(tester);
      await closePicker(tester, region);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(selectionService.calls, equals(2));
      expect(find.textContaining('Drag anywhere on screen'), findsOneWidget);
    });

    testWidgetsMac('the result screen can start another selection', (
      tester,
    ) async {
      await openPicker(tester);
      await closePicker(tester, region);

      await tester.tap(find.text('Select another region'));
      await tester.pumpAndSettle();

      expect(selectionService.calls, equals(2));
      expect(find.textContaining('Drag anywhere on screen'), findsOneWidget);
    });

    testWidgetsMac('the success state notes that the entry was saved', (
      tester,
    ) async {
      await openPicker(tester);
      await closePicker(tester, region);

      expect(find.textContaining('Saved to history'), findsOneWidget);
    });

    testWidgetsMac('Cmd+R asks the native picker to open (T-129)', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(selectionService.calls, equals(1));
      expect(find.textContaining('Drag anywhere on screen'), findsOneWidget);
    });

    testWidgetsMac('Cmd+C copies the translated text (T-129)', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await openPicker(tester);
      await closePicker(tester, region);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();

      expect(copied, equals('سلام دنیا'));
      expect(find.text('Copied to clipboard'), findsOneWidget);
      // Let the snackbar dismiss so its timer does not leak past the test.
      await tester.pumpAndSettle();
    });

    testWidgetsMac('Esc on the result screen starts over (T-129)', (
      tester,
    ) async {
      await openPicker(tester);
      await closePicker(tester, region);
      expect(selectionService.calls, equals(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(selectionService.calls, equals(2));
      expect(find.textContaining('Drag anywhere on screen'), findsOneWidget);
    });
  });

  group('TranslateView iOS Widget Tests', () {
    late _FakeImageSourceService imageSourceService;
    late _FakeOcrService ocrService;
    late OcrBloc ocrBloc;
    late TranslationBloc translationBloc;
    late _FakeSelectionService selectionService;
    late TranslateFlowBloc flowBloc;

    setUp(() {
      imageSourceService = _FakeImageSourceService()
        ..galleryBytes = Uint8List.fromList([1, 2, 3])
        ..cameraBytes = Uint8List.fromList([4, 5, 6]);
      selectionService = _FakeSelectionService();
      ocrService = _FakeOcrService();
      ocrBloc = OcrBloc(ocrService: ocrService);
      translationBloc = TranslationBloc(
        translationService: _FakeTranslationService(),
      );
      flowBloc = TranslateFlowBloc(
        captureService: _FakeCaptureService(),
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: _FakeHistoryRepository(),
        settingsRepository: _FakeSettingsRepository(),
      );
    });

    tearDown(() {
      flowBloc.dispose();
      ocrBloc.dispose();
      translationBloc.dispose();
    });

    /// Pumps the view under the current (variant-provided) platform.
    ///
    /// iOS is simulated with
    /// [TargetPlatformVariant.only], which sets and restores
    /// `debugDefaultTargetPlatformOverride` itself — doing it by hand in
    /// `setUp`/`tearDown` trips Flutter's "debug variable was changed"
    /// invariant assertion.
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: TranslateView(bloc: flowBloc, selectionService: selectionService),
      ),
    );

    testWidgets('shows Pick image and Take photo on iOS', (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Pick image'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Select region'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('Pick image runs the pipeline with gallery bytes', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('سلام دنیا'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('Take photo runs the pipeline with camera bytes', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();

      expect(find.text('سلام دنیا'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a cancelled pick returns to the idle state', (tester) async {
      imageSourceService.galleryBytes = null;

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('Pick image'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('Try again on iOS opens the gallery picker', (tester) async {
      // A null OCR result forces the failure state.
      ocrService.text = null;

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
      expect(imageSourceService.galleryCalls, equals(1));

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(imageSourceService.galleryCalls, equals(2));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('Select another region on iOS opens the gallery picker', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('Select another region'), findsOneWidget);
      expect(imageSourceService.galleryCalls, equals(1));

      await tester.tap(find.text('Select another region'));
      await tester.pumpAndSettle();

      expect(imageSourceService.galleryCalls, equals(2));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('Cmd+R opens the gallery picker on iOS (T-129)', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(imageSourceService.galleryCalls, equals(1));
      expect(find.text('سلام دنیا'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('TranslateView Android Widget Tests', () {
    late _FakeImageSourceService imageSourceService;
    late _FakeOcrService ocrService;
    late OcrBloc ocrBloc;
    late TranslationBloc translationBloc;
    late _FakeSelectionService selectionService;
    late TranslateFlowBloc flowBloc;

    setUp(() {
      imageSourceService = _FakeImageSourceService()
        ..galleryBytes = Uint8List.fromList([1, 2, 3])
        ..cameraBytes = Uint8List.fromList([4, 5, 6]);
      selectionService = _FakeSelectionService();
      ocrService = _FakeOcrService();
      ocrBloc = OcrBloc(ocrService: ocrService);
      translationBloc = TranslationBloc(
        translationService: _FakeTranslationService(),
      );
      flowBloc = TranslateFlowBloc(
        captureService: _FakeCaptureService(),
        imageSourceService: imageSourceService,
        ocrBloc: ocrBloc,
        translationBloc: translationBloc,
        historyRepository: _FakeHistoryRepository(),
        settingsRepository: _FakeSettingsRepository(),
      );
    });

    tearDown(() {
      flowBloc.dispose();
      ocrBloc.dispose();
      translationBloc.dispose();
    });

    /// Pumps the view under the Android platform variant (T-132 / D-016:
    /// Android is photo-input only, no region selection).
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: TranslateView(bloc: flowBloc, selectionService: selectionService),
      ),
    );

    testWidgets(
      'shows Pick image and Take photo on Android, no Select region',
      (tester) async {
        await pump(tester);
        await tester.pumpAndSettle();

        expect(find.text('Pick image'), findsOneWidget);
        expect(find.text('Take photo'), findsOneWidget);
        expect(find.text('Select region'), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('the idle prompt never mentions the region flow', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Pick a photo or take one'), findsOneWidget);
      expect(find.textContaining('Select a region'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('Pick image runs the pipeline with gallery bytes', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('سلام دنیا'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('Take photo runs the pipeline with camera bytes', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();

      expect(find.text('سلام دنیا'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('the result screen says "Choose another photo" (T-138)', (
      tester,
    ) async {
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('سلام دنیا'), findsOneWidget);
      // The "again" action reopens the gallery, so no region wording.
      expect(find.text('Choose another photo'), findsOneWidget);
      expect(find.text('Select another region'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('the OCR failure guidance never mentions a region (T-138)', (
      tester,
    ) async {
      // A null OCR result forces the "No text found" failure state.
      ocrService.text = null;

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick image'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('Try a photo with printed'), findsOneWidget);
      expect(find.textContaining('region'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
