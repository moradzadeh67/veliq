import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/language.dart';
import '../../services/settings_repository.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_state.dart';

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
  /// Languages this device's OCR can read. `null` while loading or when the
  /// capability is unknown — both cases leave every entry enabled.
  Set<String>? _supportedLanguages;

  @override
  void initState() {
    super.initState();
    widget.bloc.load();
    _loadSupportedLanguages();
  }

  Future<void> _loadSupportedLanguages() async {
    final languages = await widget.bloc.supportedOcrLanguages();
    if (!mounted) return;
    setState(() => _supportedLanguages = languages);
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
              supportedLanguages: _supportedLanguages,
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

  /// ISO 639-1 codes this device's OCR can read, or `null` when unknown.
  final Set<String>? supportedLanguages;

  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final ValueChanged<bool> onSaveScreenshotsChanged;
  final ValueChanged<TranslationProvider> onProviderChanged;
  final ValueChanged<String?> onGoogleApiKeyChanged;

  /// Runs a live check against Google. Returns `null` on success.
  final Future<String?> Function(String apiKey) onTestGoogleApiKey;

  const _SettingsForm({
    required this.settings,
    required this.supportedLanguages,
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
    // Android ships Gemini only (T-137): Apple's Translation framework does not
    // exist there, so a stored Apple choice is surfaced as a fixable notice
    // rather than silently kept.
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final storedProvider = settings.translationProvider;
    final provider = isAndroid ? TranslationProvider.google : storedProvider;
    final usesGoogle = provider == TranslationProvider.google;
    final appleNeedsFix =
        isAndroid && storedProvider == TranslationProvider.apple;

    // D-018: a source language is only offered if this device's OCR can read
    // it. `null` means capability is still unknown (loading or failed query), in
    // which case everything stays enabled rather than flickering.
    final supported = supportedLanguages;
    final sourceIsAuto = settings.sourceLanguage == LanguageCatalog.autoCode;
    final sourceUnsupported =
        !sourceIsAuto &&
        supported != null &&
        !supported.contains(settings.sourceLanguage);
    final sameLanguage =
        !sourceIsAuto && settings.sourceLanguage == settings.targetLanguage;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _SectionHeader('Translation'),
        ListTile(
          title: const Text('Provider'),
          subtitle: Text(kTranslationProviderLabels[provider] ?? provider.name),
          trailing: isAndroid
              ? null
              : _ProviderDropdown(
                  value: provider,
                  onChanged: onProviderChanged,
                ),
        ),
        if (appleNeedsFix)
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('Android supports Google Gemini only'),
            subtitle: const Text(
              "Apple's on-device engine isn't available on Android, so Veliq "
              'is using Google Gemini. Your stored choice was Apple.',
            ),
            trailing: TextButton(
              onPressed: () => onProviderChanged(TranslationProvider.google),
              child: const Text('Use Gemini'),
            ),
          ),
        ListTile(
          title: const Text('From'),
          subtitle: Text(LanguageCatalog.displayName(settings.sourceLanguage)),
          trailing: _LanguageDropdown(
            value: settings.sourceLanguage,
            options: LanguageCatalog.sourceOptions,
            supported: supported,
            onChanged: onSourceChanged,
          ),
        ),
        if (sourceUnsupported)
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: Text(
              'This device cannot read '
              '${LanguageCatalog.displayName(settings.sourceLanguage)}',
            ),
            subtitle: const Text(
              "The text recognition on this device does not support that "
              'language, so OCR would find nothing. Auto-detect lets the '
              'platform pick a supported language.',
            ),
            trailing: TextButton(
              onPressed: () => onSourceChanged(LanguageCatalog.autoCode),
              child: const Text('Use auto-detect'),
            ),
          ),
        ListTile(
          title: const Text('To'),
          subtitle: Text(LanguageCatalog.displayName(settings.targetLanguage)),
          trailing: _LanguageDropdown(
            value: settings.targetLanguage,
            options: LanguageCatalog.targetOptions,
            onChanged: onTargetChanged,
          ),
        ),
        if (sameLanguage)
          ListTile(
            leading: Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
            ),
            title: const Text('Source and target language are the same.'),
            subtitle: const Text(
              'Pick a different target language, or use auto-detect as the '
              'source.',
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
              'Only the recognized text is sent — never screenshots. On the '
              'free tier Google may use that text to improve its products, '
              'and human reviewers may read it. Users in the EEA, Switzerland '
              'and the UK are covered by the paid-tier terms. See '
              'docs/PRIVACY.md.',
            ),
          ),
        ],
        const Divider(),
        const _SectionHeader('Privacy'),
        SwitchListTile(
          title: const Text('Keep screenshots'),
          subtitle: Text(
            // Only macOS has a "this Mac"; iOS runs on the iPhone it says.
            isMac
                ? 'Off by default. Screenshots stay on this Mac and are '
                      'never uploaded (see docs/PRIVACY.md).'
                : 'Off by default. Screenshots stay on this device and are '
                      'never uploaded (see docs/PRIVACY.md).',
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
/// Enter and the "Save & test" button both store the key and run the live
/// check (T-129); clicking away stores the raw text without testing, so a
/// half-typed key is never lost and the verdict is never stale.
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
                  onSubmitted: (_) => _saveAndTest(),
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
              // Android keeps the key in flutter_secure_storage (encrypted,
              // T-138); Apple platforms use the Keychain (D-009). Neither is
              // the plain preferences store, so say where it really lives.
              defaultTargetPlatform == TargetPlatform.android
                  ? 'Stored securely in an encrypted store on this device.'
                  : "Stored in this device's Keychain.",
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String value;
  final List<Language> options;

  /// ISO 639-1 codes this device's OCR can read, or `null` when unknown (then
  /// every entry stays selectable). `auto` is always selectable.
  final Set<String>? supported;

  final ValueChanged<String> onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.options,
    this.supported,
    required this.onChanged,
  });

  bool _isSupported(Language language) {
    final supported = this.supported;
    if (supported == null) return true;
    if (language.code == LanguageCatalog.autoCode) return true;
    return supported.contains(language.code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guard against a persisted code that is no longer in the list, which would
    // otherwise make DropdownButton assert.
    final safeValue = options.any((language) => language.code == value)
        ? value
        : null;

    return DropdownButton<String>(
      value: safeValue,
      hint: Text(value),
      // Variable-height items: an unsupported entry carries a reason line.
      itemHeight: null,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      items: options.map((language) {
        final isSupported = _isSupported(language);
        final label = language.code == LanguageCatalog.autoCode
            ? language.englishName
            : '${language.englishName} (${language.nativeName})';

        return DropdownMenuItem<String>(
          value: language.code,
          enabled: isSupported,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: isSupported
                    ? null
                    : TextStyle(color: theme.disabledColor),
              ),
              if (!isSupported)
                Text(
                  "Not supported by this device's text recognition",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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
