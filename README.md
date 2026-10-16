# 🌐 Veliq

<p align="center">
  <img src="assets/branding/readme-banner.png" width="100%" alt="Veliq Banner">
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License MIT">
  </a>
  <a href="https://flutter.dev/platforms">
    <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20Android-black?style=for-the-badge&logo=flutter" alt="Platform Support">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-3.13.2-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  </a>
</p>

<p align="center">
  <a href="#-installation"><b>🚀 Installation</b></a> •
  <a href="#-demo"><b>🎬 Demo</b></a> •
  <a href="#-screenshots"><b>📸 Screenshots</b></a> •
  <a href="#-features"><b>✨ Features</b></a> •
  <a href="#-architecture"><b>🏗️ Architecture</b></a> •
  <a href="#-troubleshooting--faq"><b>❓ FAQ</b></a>
</p>

---

## 🌍 What is Veliq?

**Veliq** is a fast, local-first utility for **macOS, iOS, and Android** that allows you to select any region of your screen — or pick/take a photo — extract its text on-device using native OCR engines, and read the translation in Persian instantly.

It combines native OS capabilities (**ScreenCaptureKit** and **Apple Vision** on macOS/iOS, **Photo Picker** and **ML Kit** on Android) with a clean Flutter interface, sending only extracted text to Google's **Gemini API** using your own API key.

- ✅ **Local-first OCR** — screenshots and photos are held in memory and processed on-device (no cloud image uploads)
- ✅ **Privacy-focused** — only clean extracted text goes to Gemini; your API key is encrypted in Keychain/Keystore
- ✅ **Native OS Integration** — ScreenCaptureKit region selection on macOS, Photo Picker & Camera on iOS/Android
- ✅ **RTL & Persian First** — justified Persian result layout, copyable original & translated text, persistent local history

---

## 💡 Why I Built This

As a developer working on macOS and mobile devices, I frequently encounter English text on my screen—whether in documents, code comments, design specs, or system dialogs—that I want to extract and translate to Persian instantly. Existing browser-based translation tools require leaving the current app context, manually cropping or uploading screenshots to third-party cloud services, or retyping text by hand.

I built Veliq to solve this with a fast, keyboard-driven, local-first workflow. By combining native screen capture (ScreenCaptureKit on macOS, Photo Picker & Camera on mobile) with on-device Optical Character Recognition (Apple Vision / ML Kit), Veliq extracts on-screen text instantly without writing temporary image files to disk.

Only the clean extracted text is sent to the Gemini API using your own private API key, keeping your workflow private, efficient, and seamlessly integrated into macOS, iOS, and Android.

---

## 🎬 Demo

<p align="center">
  <img src="assets/demo/demo.gif" width="100%" alt="Veliq Demo: Drag-select region on macOS, instant on-device Vision OCR, and Persian Gemini translation">
</p>

> 💡 **30-second workflow:** Select a region on macOS (or pick a photo on mobile) → Instant on-device OCR → Persian translation rendered in RTL layout → Saved to local history.

---

## 📸 Screenshots

### macOS
| Region Selection Overlay | Result & Persian Translation | History | Settings |
|:---:|:---:|:---:|:---:|
| ![Overlay](assets/screenshots/macos/overlay.png) | ![Result](assets/screenshots/macos/result.png) | ![History](assets/screenshots/macos/history.png) | ![Settings](assets/screenshots/macos/settings.png) |

### iOS (simulator-verified UI)

| Home / Translate |
|:---:|
| ![Home](assets/screenshots/ios/home.png) |

> 🚧 Picker / Result / Settings screenshots will be added after the P9 physical-device pass.

### Android
| Translate View | Photo Picker & Camera | Result View | History |
|:---:|:---:|:---:|:---:|
| ![Translate](assets/screenshots/android/translate.png) | ![Picker](assets/screenshots/android/picker.png) | ![Result](assets/screenshots/android/result.png) | ![History](assets/screenshots/android/history.png) |

---

## ✨ Features

### 🪟 Region Capture (macOS)
- Drag-select any region of the screen from a full-screen overlay; press `Esc` to cancel.
- Captured using **ScreenCaptureKit** and processed with **Apple Vision** OCR — 100% on-device.
- Screenshots are processed in memory and immediately discarded; zero image files written to disk.

### 📷 Photos & Camera (iOS)
- Pick a photo from the library (`PHPickerViewController`, no permissions needed) or take a new photo with the camera.
- On-device Apple Vision OCR and Gemini Persian translation.
- `SafeArea`-aware layout with a native iOS bottom `NavigationBar`.

### 🤖 Photos & Camera (Android)
- Pick a photo with the system **Photo Picker** (no permissions required) or capture via camera (`ACTION_IMAGE_CAPTURE`).
- On-device OCR using bundled **ML Kit Text Recognition** (Latin script).
- **Gemini REST API** as the primary translation provider.
- Full Android Keystore encryption for secure API key storage.

### 🔍 OCR & Translation
- On-device OCR: **Apple Vision** on macOS/iOS, **ML Kit** on Android.
- Translation via **Google Gemini API** using **your own private API key**.
- Beautiful right-to-left (RTL), justified Persian result view with copy actions for both original and translated text.

### 📚 History & Settings
- Local, deletable translation history stored in Application Support (`history.json`).
- API key stored in the **macOS Keychain** (legacy keychain for non-paid dev accounts) / **Android Keystore**.
- Persistent language pair and provider preferences via `shared_preferences`.

### ⌨️ Keyboard Shortcuts (macOS)
- `Cmd+1` / `Cmd+2` / `Cmd+3` — Switch tabs (Translate, History, Settings).
- `Cmd+R` — Start capture (region selection overlay on macOS, gallery picker on mobile).
- `Esc` — Cancel selection overlay or reset from result/failure view.
- `Cmd+C` — Copy translation text.
- `Enter` — Save and test key in Settings.

---

## 🌐 Localization & Language Support

Veliq is designed with first-class Persian (Farsi) localization:
- **RTL Layout:** Fully adaptive Right-To-Left (RTL) text container with justified paragraph alignment for Persian text.
- **Bi-directional Text Support:** Clean separation and side-by-side view for English source text and Persian translation.
- **Font & Glyph Rendering:** Uses native system typography with fallback for Persian/Arabic glyphs to ensure crisp rendering across macOS, iOS, and Android.

---

## 🛠️ Key Dependencies & Tech Stack

| Package | Version | Purpose |
|---|:---:|---|
| `pigeon` | `^29.0.8` | Type-safe code generator for Dart ↔ Swift / Kotlin native IPC |
| `flutter_secure_storage` | `^11.0.0` | Encrypted API key storage in macOS Keychain and Android Keystore |
| `shared_preferences` | `^2.3.3` | Persistent storage for app preferences and provider settings |
| `http` | `^1.2.2` | Minimal HTTP client for Google Gemini REST API requests |
| `path_provider` | `^2.1.5` | Locates app-private directory for local `history.json` storage |

### Technical Decisions

- **Hand-written BLoC Architecture:** Built with pure Dart classes (`TranslateFlowBloc`, `OcrBloc`, `HistoryBloc`, `SettingsBloc`) without external `flutter_bloc` dependencies. This guarantees lightweight, predictable, and testable state management.
- **Pigeon IPC Bridge:** Replaces loose string-based `MethodChannel`s with compile-time type-checked interface definitions generated for Swift and Kotlin.
- **On-Device OCR:** Apple Vision and ML Kit handle text recognition locally before any network call is initiated. Screenshots are held only in RAM.
- **Secure Key Storage:** Avoids plain-text `SharedPreferences` for sensitive credentials by utilizing `flutter_secure_storage` backed by platform keystores.

---

## 🏗️ Architecture

Dart owns the UI, state, orchestration, and storage layers; Swift (macOS/iOS) and Kotlin (Android) handle platform-native capabilities. They communicate over a type-safe, Pigeon-generated interface.

### System Data Flow

```text
macOS:   Select Region (Swift Overlay) -> Capture (ScreenCaptureKit) -> OCR (Vision, On-Device)
           -> Extracted Text -> Gemini REST API -> RTL Persian View + Local History
iOS:     Pick/Take Photo (Swift) -> OCR (Vision, On-Device)
           -> Extracted Text -> Gemini REST API -> RTL Persian View + Local History
Android: Pick/Take Photo (Kotlin) -> OCR (ML Kit, On-Device)
           -> Extracted Text -> Gemini REST API -> RTL Persian View + Local History
```

### Project Structure

```text
lib/
├── main.dart                          → Entry point & service dependency wiring
├── features/                          → Feature-first UI and BLoC implementations
│   ├── home/                          → Navigation shell (Rail / Bottom Bar, Cmd+1/2/3)
│   ├── capture/                       → Screen region-selection overlay
│   ├── translation/                   → Translate flow: capture -> OCR -> Gemini -> save
│   ├── ocr/                           → OCR state management
│   ├── history/                       → History view & entry deletion
│   └── settings/                      → API key management & provider selection
├── services/                          → Interfaces + Pigeon native impls + Gemini REST client
│   ├── selection/capture/ocr/...      → Service abstractions (faked in test suite)
│   ├── pigeon_*.dart                  → Pigeon Swift/Kotlin implementations
│   ├── gemini_translation_service.dart→ Gemini REST client
│   ├── json_history_repository.dart   → history.json in Application Support
│   └── keychain_api_key_store.dart    → Keychain / Keystore secure storage
├── models/                            → Pure Dart data models (ScreenRegion, TranslationEntry)
└── pigeon/messages.g.dart             → Generated Pigeon bindings (do not edit)

macos/Runner/                          → Swift: ScreenCaptureKit, Vision OCR, Overlay Window
ios/Runner/                            → Swift: PHPicker, Camera ImageSourceHandler, Vision OCR
android/app/                           → Kotlin: Photo Picker, Camera FileProvider, ML Kit OCR
pigeons/messages.dart                  → Pigeon interface definitions
test/                                  → Offline unit and widget test suite
```

---

## 📱 Platform Support

| Platform | Status | Notes |
|---|:---:|---|
| 🖥️ macOS | ✅ Works end to end | macOS 14.6+ — region select → Vision OCR → Gemini → history |
| 📱 iOS | 🔜 In progress | P7–P9; simulator-verified (iPhone 17 Pro Max), awaiting physical device test |
| 🤖 Android | ✅ v1 Done (P12) | Photo Picker + ML Kit OCR (Latin) + Gemini; emulator-verified |
| 🪟 Windows | ❌ Out of scope | Desktop target limited to macOS |
| 🐧 Linux | ❌ Out of scope | Out of scope |

---

## 🔐 Permissions

> [!IMPORTANT]
> **macOS Screen Recording Permission**
> Veliq requires **Screen Recording** permission on macOS to capture selected screen regions.
> If the system prompt was dismissed, grant it manually:
> **System Settings → Privacy & Security → Screen Recording → enable Veliq**
> Fully quit and reopen Veliq after granting permissions.

> [!NOTE]
> - **iOS & Android Photos:** Picking photos via `PHPickerViewController` or Android Photo Picker requires **zero permissions**.
> - **Camera:** Camera runtime permission is requested only when tapping *Take photo*.
> - Veliq does **not** require Accessibility or Full Disk Access permissions.

---

## 🔒 Privacy

> [!IMPORTANT]
> - **In-Memory Image Processing:** Captured screenshots and selected photos are kept solely in RAM and discarded immediately after OCR extraction.
> - **Text-Only Cloud Transmission:** Only the recognized text string is sent to Google's Gemini API over HTTPS using your personal API key. No image files are ever uploaded.
> - **Encrypted Credentials:** Your Gemini API key is stored securely in macOS Keychain / Android Keystore — never in plain text.
> - **Local Data:** Translation history is saved locally in Application Support (`history.json`) and can be cleared at any time from the History tab.

Details: [docs/PRIVACY.md](docs/PRIVACY.md).

---

## 🚀 Installation & Building

> [!NOTE]
> Official pre-built release binaries are currently unsigned and pending release checklist verification ([docs/RELEASE.md](docs/RELEASE.md)). Follow the instructions below to build from source.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.47.2)
- Dart SDK (^3.13.2)
- Xcode 15+ (for macOS & iOS builds)
- Android Studio / Android SDK 24+ (for Android builds)
- A Google Gemini API Key (get one from [Google AI Studio](https://aistudio.google.com/apikey))

### Build from Source

```bash
# 1. Clone the repository
git clone https://github.com/moradzadeh67/veliq.git
cd veliq

# 2. Install dependencies
flutter pub get

# 3. Run on your target platform
flutter run -d macos
flutter run -d "iPhone 17 Pro Max"
flutter run -d <android-device-id>

# 4. Build release artifacts
flutter build macos --release
flutter build ios --no-codesign
flutter build apk --debug
```

> [!IMPORTANT]
> **First Launch on macOS:**
> On unsigned developer builds, macOS Gatekeeper may block double-clicking the app bundle. Right-click `Veliq.app` and choose **Open** once to bypass the Gatekeeper warning.

---

## 🧪 Testing & Quality Assurance

The test suite runs 100% offline using service interface fakes. No permissions, network calls, or API keys are required during test execution.

```bash
# 1. Run static analysis (must report zero issues)
flutter analyze

# 2. Run unit and widget tests (199 passing tests)
flutter test

# 3. Verify iOS build configuration
flutter build ios --no-codesign

# 4. Verify Android debug build
flutter build apk --debug
```

---

## 🗺️ Roadmap

- [x] **P0 — Scaffold:** Base Flutter project & directory structure
- [x] **P1 — Research:** Native API & Pigeon channel feasibility
- [x] **P2 — Capture MVP:** ScreenCaptureKit region selection on macOS
- [x] **P3 — OCR:** Apple Vision integration on macOS
- [x] **P4 — Translation:** Gemini REST client & RTL result rendering
- [x] **P5 — History & Settings:** Keychain storage & local JSON history
- [x] **P6 — Polish & Release Setup:** Shortcuts & error handling
- [x] **P7 — iOS Research:** Mobile native capabilities
- [x] **P8 — iOS Image Input:** PHPicker & Camera handlers
- [ ] **P9 — iOS UI & Storage:** SafeArea navigation & simulator verification
- [x] **P10 — Branding & Icons:** App icons & branding assets
- [ ] **P11 — Shortcuts:** System-wide capture hotkey
- [x] **P12 — Android v1:** Photo Picker, Camera, ML Kit OCR & Keystore
- [ ] **Public Release:** Signed builds & GitHub Releases ([docs/RELEASE.md](docs/RELEASE.md))

The active task list is tracked in [TASKS.md](TASKS.md).

---

## ⚠️ Known Limitations

- **iOS Camera in Simulator:** The iOS Simulator does not support camera capture hardware; camera workflows require a physical iPhone.
- **Android OCR Scope:** The bundled ML Kit model currently supports Latin script OCR; non-Latin script models are planned for future updates.
- **Unsigned Builds:** macOS Gatekeeper flags unsigned developer builds on first double-click launch.

---

## ❓ Troubleshooting & FAQ

<details>
<summary><b>1. How do I fix "Screen Recording Permission Denied" on macOS?</b></summary>

Go to **System Settings → Privacy & Security → Screen Recording**, enable **Veliq**, and fully restart the app.
</details>

<details>
<summary><b>2. Are my screenshots or photos uploaded to cloud servers?</b></summary>

No. Screenshots and photos are held in system RAM during local OCR text extraction and discarded immediately. Only the extracted plain-text string is sent to the Gemini API.
</details>

<details>
<summary><b>3. How do I get a free Google Gemini API Key?</b></summary>

Visit [Google AI Studio](https://aistudio.google.com/apikey), log in with a Google account, create an API key, and paste it into Veliq's **Settings** tab.
</details>

<details>
<summary><b>4. Where is my translation history stored?</b></summary>

History is stored locally in `history.json` within your OS Application Support directory (`~/Library/Containers/com.moradzadeh67.veliq/Data/Library/Application Support/veliq/history.json` on macOS; `/data/data/com.moradzadeh67.veliq/files/history.json` on Android). It can be deleted from the History tab.
</details>

<details>
<summary><b>5. Why does camera capture fail on the iOS Simulator?</b></summary>

Apple's iOS Simulator does not emulate camera hardware (`UIImagePickerControllerSourceTypeCamera`). Use the photo library picker in the simulator or test on a physical iOS device.
</details>

---

## 🤖 Development Approach

Architecture, technical decisions, and code reviews are maintained directly by the author. Implementation tasks follow strict rules documented in [`AGENTS.md`](AGENTS.md) and [`TASKS.md`](TASKS.md): one task at a time, strictly verified with `flutter analyze` and `flutter test`.

---

## 🤝 Contributing

Contributions and issue reports are welcome on the [GitHub Issues](https://github.com/moradzadeh67/veliq/issues) page.

---

## 🙏 Credits & Attribution

Veliq is built with:
- [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- [Pigeon](https://pub.dev/packages/pigeon)
- [Apple Vision](https://developer.apple.com/documentation/vision) & [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2)
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage)
- [Google Gemini API](https://ai.google.dev/)

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

Copyright © 2026 Mohammadreza Moradzadeh ([@moradzadeh67](https://github.com/moradzadeh67))
