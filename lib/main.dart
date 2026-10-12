import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'features/history/bloc/history_bloc.dart';
import 'features/home/home_shell.dart';
import 'features/ocr/bloc/ocr_bloc.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'features/translation/bloc/translate_flow_bloc.dart';
import 'features/translation/bloc/translation_bloc.dart';
import 'features/translation/translate_view.dart';
import 'services/gemini_translation_service.dart';
import 'services/json_history_repository.dart';
import 'services/pigeon_capture_service.dart';
import 'services/pigeon_ocr_service.dart';
import 'services/pigeon_selection_service.dart';
import 'services/pigeon_translation_service.dart';
import 'services/prefs_settings_repository.dart';
import 'services/selection_service.dart';
import 'services/switching_translation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistence.
  final appSupportDir = await getApplicationSupportDirectory();
  final historyFile = File('${appSupportDir.path}/history.json');
  final historyRepository = JsonHistoryRepository(file: historyFile);
  final settingsRepository = PrefsSettingsRepository();

  // Feature state holders.
  final historyBloc = HistoryBloc(historyRepository: historyRepository);
  final settingsBloc = SettingsBloc(
    settingsRepository: settingsRepository,
    googleApiKeyVerifier: (apiKey, sourceLanguage, targetLanguage) =>
        GeminiTranslationService(
          apiKey: apiKey,
          includeDiagnostics: kDebugMode,
        ).verifyApiKey(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
  );

  // Pipeline stages (native, via Pigeon).
  final ocrBloc = OcrBloc(ocrService: PigeonOcrService());
  final translationBloc = TranslationBloc(
    translationService: SwitchingTranslationService(
      settings: settingsRepository,
      apple: PigeonTranslationService(),
      googleFactory: (apiKey) => GeminiTranslationService(
        apiKey: apiKey,
        includeDiagnostics: kDebugMode,
      ),
    ),
  );

  // End-to-end orchestration: capture -> OCR -> translate -> history.
  final translateFlowBloc = TranslateFlowBloc(
    captureService: PigeonCaptureService(),
    ocrBloc: ocrBloc,
    translationBloc: translationBloc,
    historyRepository: historyRepository,
    settingsRepository: settingsRepository,
  );

  runApp(
    VeliqApp(
      historyBloc: historyBloc,
      settingsBloc: settingsBloc,
      translateFlowBloc: translateFlowBloc,
      selectionService: PigeonSelectionService(),
    ),
  );
}

class VeliqApp extends StatelessWidget {
  final HistoryBloc historyBloc;
  final SettingsBloc settingsBloc;
  final TranslateFlowBloc translateFlowBloc;
  final SelectionService selectionService;

  const VeliqApp({
    super.key,
    required this.historyBloc,
    required this.settingsBloc,
    required this.translateFlowBloc,
    required this.selectionService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veliq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeShell(
        historyBloc: historyBloc,
        settingsBloc: settingsBloc,
        translateView: TranslateView(
          bloc: translateFlowBloc,
          selectionService: selectionService,
        ),
      ),
    );
  }
}
