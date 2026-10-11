# Veliq

Select any region of your screen, extract its text locally, and translate it to Persian.

Veliq is a small, local-first macOS desktop utility. Screenshots never leave your
machine and are never written to disk: capture and OCR both run on-device using
Apple's ScreenCaptureKit and Vision frameworks. Only the extracted **text** is
handed to the translation provider.

## Requirements

- macOS (Apple Silicon or Intel)
- **Screen Recording** permission — required to capture the selected region
- Native translation requires **macOS 26 or later** (Apple's programmatic
  Translation API). On earlier versions the capture and OCR stages still work,
  but the translation stage will report that translation is unavailable.

## Permissions

Veliq asks for **Screen Recording** only. On first capture macOS shows a prompt;
if you dismiss it, grant access manually:

> System Settings → Privacy & Security → Screen Recording → enable **Veliq**

Fully quit and reopen Veliq after changing this setting — macOS applies Screen
Recording changes only to newly launched processes.

Veliq does **not** request Accessibility, Full Disk Access, or any other
permission. See [docs/MACOS_PERMISSIONS.md](docs/MACOS_PERMISSIONS.md).

## Privacy

- Capture and OCR are entirely on-device.
- Screenshots are held in memory and discarded; they are not saved.
- Only the recognized text is sent to the translation provider.
- Translation history is stored locally at
  `~/Library/Application Support/veliq/history.json` and can be cleared at any
  time from the History screen.
- No account, no analytics, no backend.

See [docs/PRIVACY.md](docs/PRIVACY.md) for details.

## Using Veliq

1. Open Veliq and stay on the **Translate** tab.
2. Click **Select region** (or the crop icon in the toolbar).
3. Drag to draw a rectangle over the text you want to read. Press `Esc` to cancel.
4. Veliq captures the region, reads the text, translates it, and shows the result.
   The translation is displayed right-to-left; the original is shown below it.
5. Copy either block individually, or click **Select another region** to repeat.
6. Completed translations are saved automatically. Review or clear them on the
   **History** tab. Change the language pair on the **Settings** tab.

## Development

```bash
flutter pub get
flutter test          # unit + widget tests
flutter analyze       # static analysis
flutter run -d macos
```

### Project layout

```
lib/core/                     cross-cutting helpers
lib/features/capture/         region selection overlay
lib/features/ocr/             OCR state
lib/features/translation/     translation state + the capture->OCR->translate->save flow
lib/features/history/         saved translations
lib/features/settings/        language pair + retention preference
lib/features/home/            navigation shell
lib/services/                 service interfaces + Pigeon/native implementations
lib/models/                   data models
lib/pigeon/                   generated Pigeon bindings (do not edit)
macos/                        Swift native code (capture, OCR, translation)
test/                         mirrors lib/
```

## Architecture

Dart owns the UI, state, orchestration and storage. Swift owns the three native
capabilities. The boundary is a Pigeon-generated interface, kept deliberately
small. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## License

MIT. See [LICENSE](LICENSE).