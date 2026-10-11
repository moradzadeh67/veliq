import 'package:flutter/material.dart';

import '../../services/settings_repository.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_state.dart';

/// Languages offered in the pickers. Codes are ISO 639-1.
const Map<String, String> kSupportedLanguages = {
  'en': 'English',
  'fa': 'Persian (فارسی)',
  'ar': 'Arabic (العربية)',
  'de': 'German',
  'fr': 'French',
  'es': 'Spanish',
  'it': 'Italian',
  'ru': 'Russian',
  'tr': 'Turkish',
  'zh': 'Chinese',
  'ja': 'Japanese',
};

/// Human-readable names for the translation backends.
const Map<TranslationProvider, String> kTranslationProviderLabels = {
  TranslationProvider.apple: 'Apple (on-device)',
  TranslationProvider.google: 'Google Gemini',
};

/// Settings screen: translation backend, language pair and screenshot retention.
class SettingsView extends StatefulWidget {
  final SettingsBloc bloc;

  const SettingsView({super.key, required this.bloc});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    widget.bloc.load();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SettingsState>(
      stream: widget.bloc.stateStream,
      initialData: widget.bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const SettingsInitial();

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: switch (state) {
            SettingsInitial() || SettingsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SettingsFailure(:final message) => Center(
              child: Text('Could not load settings: $message'),
            ),
            SettingsLoaded(:final settings) => _SettingsForm(
              settings: settings,
              onSourceChanged: widget.bloc.setSourceLanguage,
              onTargetChanged: widget.bloc.setTargetLanguage,
              onSaveScreenshotsChanged: widget.bloc.setSaveScreenshots,
              onProviderChanged: widget.bloc.setTranslationProvider,
              onGoogleApiKeyChanged: widget.bloc.setGoogleApiKey,
              onTestGoogleApiKey: widget.bloc.testGoogleApiKey,
            ),
          },
        );
      },
    );
  }
}

class _SettingsForm extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final ValueChanged<bool> onSaveScreenshotsChanged;
  final ValueChanged<TranslationProvider> onProviderChanged;
  final ValueChanged<String?> onGoogleApiKeyChanged;

  /// Runs a live check against Google. Returns `null` on success.
  final Future<String?> Function(String apiKey) onTestGoogleApiKey;

  const _SettingsForm({
    required this.settings,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSaveScreenshotsChanged,
    required this.onProviderChanged,
    required this.onGoogleApiKeyChanged,
    required this.onTestGoogleApiKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usesGoogle =
        settings.translationProvider == TranslationProvider.google;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _SectionHeader('Translation'),
        ListTile(
          title: const Text('Provider'),
          subtitle: Text(
            kTranslationProviderLabels[settings.translationProvider] ??
                settings.translationProvider.name,
          ),
          trailing: _ProviderDropdown(
            value: settings.translationProvider,
            onChanged: onProviderChanged,
          ),
        ),
        ListTile(
          title: const Text('From'),
          subtitle: Text(
            kSupportedLanguages[settings.sourceLanguage] ??
                settings.sourceLanguage,
          ),
          trailing: _LanguageDropdown(
            value: settings.sourceLanguage,
            onChanged: onSourceChanged,
          ),
        ),
        ListTile(
          title: const Text('To'),
          subtitle: Text(
            kSupportedLanguages[settings.targetLanguage] ??
                settings.targetLanguage,
          ),
          trailing: _LanguageDropdown(
            value: settings.targetLanguage,
            onChanged: onTargetChanged,
          ),
        ),
        if (usesGoogle) ...[
          _GoogleApiKeyField(
            apiKey: settings.googleApiKey,
            onChanged: onGoogleApiKeyChanged,
            onTest: onTestGoogleApiKey,
          ),
          if (!settings.hasGoogleApiKey)
            ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
              ),
              title: const Text('No API key yet'),
              subtitle: const Text(
                'Create one at aistudio.google.com/apikey, paste it above and '
                'press "Save & test". Translation fails without it.',
              ),
            ),
          const ListTile(
            leading: Icon(Icons.cloud_upload_outlined),
            title: Text('Text is sent to Google'),
            subtitle: Text(
              'Only the recognized text is sent for translation. '
              'Screenshots never leave this Mac.',
            ),
          ),
        ],
        const Divider(),
        const _SectionHeader('Privacy'),
        SwitchListTile(
          title: const Text('Keep screenshots'),
          subtitle: const Text(
            'Off by default. Screenshots stay on this Mac and are never '
            'uploaded (see docs/PRIVACY.md).',
          ),
          value: settings.saveScreenshots,
          onChanged: onSaveScreenshotsChanged,
        ),
      ],
    );
  }
}

/// Dropdown for picking the translation backend.
class _ProviderDropdown extends StatelessWidget {
  final TranslationProvider value;
  final ValueChanged<TranslationProvider> onChanged;

  const _ProviderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<TranslationProvider>(
      value: value,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      items: TranslationProvider.values
          .map(
            (provider) => DropdownMenuItem<TranslationProvider>(
              value: provider,
              child: Text(
                kTranslationProviderLabels[provider] ?? provider.name,
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Obscured text field for the Google AI (Gemini) API key, with a live check.
///
/// The value is stored on submit, when focus leaves the field, or when the
/// "Save & test" button is pressed — so a half-typed key is never persisted,
/// and the button both sets the key and reports whether it actually works.
class _GoogleApiKeyField extends StatefulWidget {
  final String? apiKey;
  final ValueChanged<String?> onChanged;
  final Future<String?> Function(String apiKey) onTest;

  const _GoogleApiKeyField({
    required this.apiKey,
    required this.onChanged,
    required this.onTest,
  });

  @override
  State<_GoogleApiKeyField> createState() => _GoogleApiKeyFieldState();
}

class _GoogleApiKeyFieldState extends State<_GoogleApiKeyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _obscured = true;
  bool _checking = false;
  bool _succeeded = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.apiKey ?? '');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _GoogleApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirror external changes (initial load, clearing) but never fight the
    // user while they are typing.
    if (!_focusNode.hasFocus && widget.apiKey != oldWidget.apiKey) {
      final next = widget.apiKey ?? '';
      if (_controller.text != next) {
        _controller.text = next;
      }
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() => widget.onChanged(_controller.text);

  /// Stores the key and then reports whether Google accepts it.
  Future<void> _saveAndTest() async {
    final key = _controller.text.trim();
    _commit();

    setState(() {
      _checking = true;
      _result = null;
      _succeeded = false;
    });

    final problem = await widget.onTest(key);
    if (!mounted) return;

    setState(() {
      _checking = false;
      _succeeded = problem == null;
      _result = problem ?? 'Connected. The API key works.';
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: _obscured,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _commit(),
                  // A stale verdict is worse than none.
                  onChanged: (_) {
                    if (_result != null) {
                      setState(() {
                        _result = null;
                        _succeeded = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Google AI API key',
                    hintText: 'AIza...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscured ? 'Show key' : 'Hide key',
                      icon: Icon(
                        _obscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.tonal(
                  onPressed: _checking ? null : _saveAndTest,
                  child: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & test'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_checking)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Checking the key...', style: theme.textTheme.bodySmall),
              ],
            )
          else if (_result != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _succeeded ? Icons.check_circle : Icons.error_outline,
                  size: 16,
                  color: _succeeded
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _succeeded
                          ? Colors.green.shade800
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              "Stored locally in this Mac's app preferences.",
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Guard against a persisted code that is no longer in the supported list,
    // which would otherwise make DropdownButton assert.
    final safeValue = kSupportedLanguages.containsKey(value) ? value : null;

    return DropdownButton<String>(
      value: safeValue,
      hint: Text(value),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      items: kSupportedLanguages.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text('${entry.value} (${entry.key})'),
            ),
          )
          .toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
