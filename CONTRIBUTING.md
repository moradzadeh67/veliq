# Contributing to Veliq

Thanks for taking the time to look at Veliq. This is a small, deliberately dependency-light
Flutter app, and the same applies to how it is developed.

## Ways to contribute

- **Bug reports and feature ideas** — open an issue on the
  [GitHub Issues](https://github.com/moradzadeh67/veliq/issues) page. Please include your platform
  (macOS / iOS / Android), the app version, and the steps that reproduce the problem.
- **Pull requests** — keep them focused. One concern per PR beats one large mixed change.

## Before you open a PR

The project follows one simple rule: **the checks must be green**.

```bash
flutter analyze   # must report zero issues
flutter test      # must pass, offline (no keys or network needed)
```

Guidelines:

- **Don't hand-edit generated files.** The Pigeon bindings
  (`lib/pigeon/messages.g.dart`, `macos/Runner/Messages.g.swift`, `ios/Runner/Messages.g.swift`,
  the generated Kotlin file) are produced from `pigeons/messages.dart`. Change the interface and
  regenerate.
- **Never commit secrets.** API keys live in the OS keychain/keystore at runtime. No keys, tokens or
  `.env` files belong in the repository.
- **Keep the image on-device.** Screenshots and photos must never be written to disk, logged, or
  uploaded — only the extracted text may be sent to the translation provider.
- **Match the existing style.** Feature-first folders under `lib/features/`, small hand-written
  state classes, and tests next to the code they cover.

## Development notes

- Flutter 3.47.2 / Dart 3.13.2.
- macOS debug rebuilds are treated as a new app by the system: Screen Recording permission must be
  re-granted and the Keychain may re-prompt for the API key after each rebuild.
- Android release builds are debug-signed for now — see the Release Signing section of the README.

## License

By contributing you agree that your contributions are licensed under the
[MIT License](LICENSE).
