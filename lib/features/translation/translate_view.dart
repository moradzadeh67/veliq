import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/language.dart';
import '../../services/selection_service.dart';
import 'bloc/translate_flow_bloc.dart';
import 'bloc/translate_flow_state.dart';

/// The main capture -> OCR -> translate workflow screen.
///
/// The region is picked with a *native* full-screen overlay (see
/// [SelectionService]) rather than a widget inside this window, so the user can
/// select content belonging to any application. The resulting screen-space
/// rectangle is handed to [TranslateFlowBloc].
class TranslateView extends StatefulWidget {
  final TranslateFlowBloc bloc;
  final SelectionService selectionService;

  const TranslateView({
    super.key,
    required this.bloc,
    required this.selectionService,
  });

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  bool _selecting = false;

  Future<void> _startSelection() async {
    if (_selecting) return;

    setState(() => _selecting = true);
    widget.bloc.startSelection();

    final region = await widget.selectionService.selectRegion();
    if (!mounted) return;

    setState(() => _selecting = false);

    if (region == null) {
      widget.bloc.cancel();
      return;
    }

    await widget.bloc.runForRect(
      x: region.x,
      y: region.y,
      width: region.width,
      height: region.height,
    );
  }

  /// True on the mobile targets (iOS/iPadOS and Android), where there is no
  /// native screen-region overlay: photos are the only input.
  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// True on Android, which never offers the region flow (D-016).
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<void> _pickFromGallery() => widget.bloc.pickImageFromGallery();

  Future<void> _takePhoto() => widget.bloc.takePhoto();

  /// "Start over" action for the failure and result screens.
  ///
  /// iOS/Android have no native region overlay, so they fall back to the
  /// gallery picker; macOS keeps the region selector.
  Future<void> _retryOrSelect() =>
      _isMobile ? _pickFromGallery() : _startSelection();

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Cmd+R: start a capture (macOS region, iOS/Android gallery), when idle or done.
  void _startCapture() {
    final state = widget.bloc.currentState;
    if (state is TranslateFlowIdle ||
        state is TranslateFlowSuccess ||
        state is TranslateFlowFailure) {
      _isMobile ? _pickFromGallery() : _startSelection();
    }
  }

  /// Esc: start over from the result or failure screen.
  void _startOver() {
    final state = widget.bloc.currentState;
    if (state is TranslateFlowSuccess || state is TranslateFlowFailure) {
      _retryOrSelect();
    }
  }

  /// Cmd+C: copy the translation from the result screen.
  void _copyTranslation() {
    final state = widget.bloc.currentState;
    if (state is TranslateFlowSuccess) {
      _copy(state.translatedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
            _startCapture,
        const SingleActivator(LogicalKeyboardKey.escape): _startOver,
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            _copyTranslation,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Translate'),
            actions: [
              if (_isMobile) ...[
                IconButton(
                  tooltip: 'Pick image',
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                ),
                IconButton(
                  tooltip: 'Take photo',
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.photo_camera),
                ),
              ] else
                IconButton(
                  tooltip: 'Select a region',
                  onPressed: _selecting ? null : _startSelection,
                  icon: const Icon(Icons.crop_free),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: StreamBuilder<TranslateFlowState>(
              stream: widget.bloc.stateStream,
              initialData: widget.bloc.currentState,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const TranslateFlowIdle();

                return _buildBody(state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TranslateFlowState state) {
    return switch (state) {
      TranslateFlowIdle() => _IdleState(
        onSelect: _isMobile ? null : _startSelection,
        onPickImage: _isMobile ? _pickFromGallery : null,
        onTakePhoto: _isMobile ? _takePhoto : null,
        hint: _isAndroid ? _IdleState.mobileHint : null,
      ),
      TranslateFlowSelecting() => const _IdleState(
        hint:
            'Drag anywhere on screen to select a region, '
            'or press Esc to cancel.',
      ),
      TranslateFlowCapturing() => const _ProgressState(
        label: 'Capturing screen region...',
        step: 0,
      ),
      TranslateFlowRecognizing() => const _ProgressState(
        label: 'Reading text...',
        step: 1,
      ),
      TranslateFlowTranslating() => const _ProgressState(
        label: 'Translating...',
        step: 2,
      ),
      TranslateFlowFailure(:final stage, :final message) => _FailureState(
        stage: stage,
        message: message,
        onRetry: _retryOrSelect,
      ),
      TranslateFlowSuccess(
        :final originalText,
        :final translatedText,
        :final sourceLanguage,
        :final targetLanguage,
      ) =>
        _ResultState(
          originalText: originalText,
          translatedText: translatedText,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          onCopyTranslated: () => _copy(translatedText),
          onCopyOriginal: () => _copy(originalText),
          onAgain: _retryOrSelect,
        ),
    };
  }
}

class _IdleState extends StatelessWidget {
  final VoidCallback? onSelect;
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final String? hint;

  /// macOS wording: the region-selection flow.
  static const String macHint =
      'Select a region of the screen to read and translate its text.';

  /// Android wording: photos only, no region selection (D-016).
  static const String mobileHint =
      'Pick a photo or take one to read and translate its text.';

  const _IdleState({
    this.onSelect,
    this.onPickImage,
    this.onTakePhoto,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_free, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            hint ?? macHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (onPickImage != null || onTakePhoto != null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick image'),
                ),
                FilledButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take photo'),
                ),
              ],
            )
          else if (onSelect != null)
            FilledButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.add),
              label: const Text('Select region'),
            ),
        ],
      ),
    );
  }
}

/// Shows which stage is running, with a simple three-dot step indicator.
class _ProgressState extends StatelessWidget {
  final String label;
  final int step;

  const _ProgressState({required this.label, required this.step});

  static const List<String> _steps = ['Capture', 'Read', 'Translate'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 20),
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Text(
            _steps
                .asMap()
                .entries
                .map((e) {
                  final marker = e.key <= step ? '●' : '○';
                  return '$marker ${e.value}';
                })
                .join('   '),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  final TranslateFlowStage stage;
  final String message;
  final VoidCallback onRetry;

  const _FailureState({
    required this.stage,
    required this.message,
    required this.onRetry,
  });

  /// True on Android: the wording below must never mention the macOS-only
  /// flows (region capture, Screen Recording, Application Support) (T-138).
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  String get _title => switch (stage) {
    TranslateFlowStage.capture =>
      _isAndroid ? 'Could not open the photo' : 'Could not capture the screen',
    TranslateFlowStage.recognize => 'No text found',
    TranslateFlowStage.translate => 'Translation failed',
    TranslateFlowStage.save => 'Could not save to history',
  };

  String get _guidance => switch (stage) {
    TranslateFlowStage.capture =>
      _isAndroid
          ? 'The photo could not be opened. Pick another image or retake the '
                'photo.'
          : 'Open System Settings > Privacy & Security > Screen Recording '
                'and enable Veliq, then restart the app.',
    TranslateFlowStage.recognize =>
      _isAndroid
          // Android ships the ML Kit Latin model only, so a Persian, Arabic,
          // Cyrillic or CJK photo legitimately comes back empty. Say why
          // instead of blaming the photo (T-161).
          ? 'Nothing readable was found. Android reads Latin script by '
                'default; for a Persian, Arabic or Russian photo, choose that '
                'language in Settings and try again (Chinese, Japanese and '
                'Korean are only readable on macOS/iOS).'
          : 'Try selecting a region that contains printed, clearly readable '
                'text.',
    TranslateFlowStage.translate =>
      _isAndroid
          ? 'Check the language pair in Settings and make sure a valid '
                'Google Gemini API key is set.'
          : 'Check the translation provider and language pair in Settings. '
                "Apple's on-device engine needs macOS 26 or later and doesn't "
                'support Persian; Google Gemini needs a valid API key.',
    TranslateFlowStage.save =>
      _isAndroid
          ? 'Check that Veliq can write to its local storage.'
          : 'Check that Veliq can write to your Application Support folder.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(_title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _guidance,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final VoidCallback onCopyTranslated;
  final VoidCallback onCopyOriginal;
  final VoidCallback onAgain;

  const _ResultState({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onCopyTranslated,
    required this.onCopyOriginal,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // On Android the "again" action reopens the gallery, so the label must
    // not mention the macOS region overlay (T-138).
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The translated text is emphasized: it is what the user wants.
                _TextCard(
                  label: 'Translation',
                  text: translatedText,
                  textDirection: TextDirection.rtl,
                  emphasized: true,
                  onCopy: onCopyTranslated,
                ),
                const SizedBox(height: 16),
                _TextCard(
                  label:
                      'Original (${LanguageCatalog.displayName(sourceLanguage)})',
                  text: originalText,
                  onCopy: onCopyOriginal,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAgain,
                    icon: Icon(
                      isAndroid
                          ? Icons.photo_library_outlined
                          : Icons.crop_free,
                    ),
                    label: Text(
                      isAndroid
                          ? 'Choose another photo'
                          : 'Select another region',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: 'Copy translation',
                  onPressed: onCopyTranslated,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Saved to history · '
            '${LanguageCatalog.displayName(sourceLanguage)} → '
            '${LanguageCatalog.displayName(targetLanguage)}',
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  final String label;
  final String text;
  final TextDirection? textDirection;
  final bool emphasized;
  final VoidCallback onCopy;

  const _TextCard({
    required this.label,
    required this.text,
    required this.onCopy,
    this.textDirection,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    // The translation is the payload, so it keeps the tinted surface and the
    // roomier type; the source text recedes into the background.
    final background = emphasized
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: emphasized
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Directionality(
              textDirection: textDirection ?? Directionality.of(context),
              child: SelectionArea(
                child: Text(
                  text,
                  textAlign: TextAlign.justify,
                  style:
                      (emphasized
                              ? theme.textTheme.bodyLarge
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            color: foreground,
                            // Arabic-script lines need more air than the Material
                            // defaults allow, and `headlineSmall` was simply too big
                            // for a block of prose.
                            height: emphasized ? 1.8 : 1.6,
                            fontWeight: emphasized ? FontWeight.w500 : null,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
