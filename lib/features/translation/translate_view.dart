import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate'),
        actions: [
          IconButton(
            tooltip: 'Select a region',
            onPressed: _selecting ? null : _startSelection,
            icon: const Icon(Icons.crop_free),
          ),
        ],
      ),
      body: StreamBuilder<TranslateFlowState>(
        stream: widget.bloc.stateStream,
        initialData: widget.bloc.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? const TranslateFlowIdle();

          return _buildBody(state);
        },
      ),
    );
  }

  Widget _buildBody(TranslateFlowState state) {
    return switch (state) {
      TranslateFlowIdle() => _IdleState(onSelect: _startSelection),
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
        onRetry: _startSelection,
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
          onAgain: _startSelection,
        ),
    };
  }
}

class _IdleState extends StatelessWidget {
  final VoidCallback? onSelect;
  final String hint;

  const _IdleState({
    this.onSelect,
    this.hint = 'Select a region of the screen to read and translate its text.',
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
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (onSelect != null)
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

  String get _title => switch (stage) {
    TranslateFlowStage.capture => 'Could not capture the screen',
    TranslateFlowStage.recognize => 'No text found',
    TranslateFlowStage.translate => 'Translation failed',
    TranslateFlowStage.save => 'Could not save to history',
  };

  String get _guidance => switch (stage) {
    TranslateFlowStage.capture =>
      'Open System Settings > Privacy & Security > Screen Recording '
          'and enable Veliq, then restart the app.',
    TranslateFlowStage.recognize =>
      'Try selecting a region that contains printed, clearly readable text.',
    TranslateFlowStage.translate =>
      'Check the translation provider and language pair in Settings. '
          "Apple's on-device engine needs macOS 26 or later and doesn't "
          'support Persian; Google Gemini needs a valid API key.',
    TranslateFlowStage.save =>
      'Check that Veliq can write to your Application Support folder.',
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
                  label: 'Original (${sourceLanguage.toUpperCase()})',
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
                    icon: const Icon(Icons.crop_free),
                    label: const Text('Select another region'),
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
            'Saved to history · $sourceLanguage → $targetLanguage',
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
