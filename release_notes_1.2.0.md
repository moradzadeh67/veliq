## Veliq 1.2.0

**Translates without an API key, and stops showing junk as a translation.**

Veliq now works on a fresh install with no setup at all: the default translation provider is Google
Translate's free endpoint, which needs no account and no key — and, unlike Gemini, it is reachable
from Iran without a VPN. On Android, the two on-device OCR engines now compare their confidence, so a
Persian, Arabic or Russian photo either comes out as real text or as a clear "this photo was probably
misread" message, never as gibberish.

### What's new

- **No API key needed.** Google Translate (free) is the default for new installs. Existing installs
  keep whatever provider they already had, and you can still switch to **Gemini** with your own key or
  to **Apple's on-device engine** (macOS 26+) in Settings.
- **Safer Android OCR.** With the source set to **Auto-detect**, ML Kit reads first; when it is not
  confident, Tesseract (Persian/Arabic/Russian) also reads the photo and the better result wins. A
  reading below the acceptance threshold is refused instead of being translated, and a short
  confident fragment can no longer beat a correct paragraph.
- **Better multi-line translation.** Line breaks from OCR are rejoined before Google Translate, so a
  wrapped paragraph is translated as a paragraph instead of sentence by sentence.
- **Clearer Settings.** The Gemini key fields appear only when Gemini is selected.

### Fixed

- A Persian, Arabic or Russian photo on Auto-detect used to be "read" as look-alike Latin letters and
  shown as a nonsense translation; it now produces real text or a readable error.
- Choosing the same language as source and target now stops before OCR with a clear message.

### Source languages your device can read

| Platform | Languages |
|---|---|
| macOS / iOS (Apple Vision) | whatever the OS reports at runtime — typically en, fr, de, es, it, pt, nl, tr, plus other scripts such as Russian, Chinese, Japanese and Korean on recent versions. Settings lists exactly what your device supports. |
| Android (bundled ML Kit Latin **and** Tesseract) | `en`, `de`, `fr`, `es`, `it`, `pt`, `nl`, `tr` — plus **Persian, Arabic and Russian** through a second on-device engine (Tesseract). Both engines run offline; the photo never leaves the phone. |

### Known limits

- **Handwriting and blackletter (Fraktur)** are not supported by either Android engine.
- **Printed Russian accuracy depends on the photo** — shadows, skew and low resolution hurt Tesseract.
  Image preprocessing is planned.
- **Chinese, Japanese and Korean stay macOS/iOS-only** — those models are not bundled on Android.
- **iOS camera capture has not been tested on a physical iPhone** (the gallery picker has).
- **Apple's on-device translation** needs a concrete source language, so it cannot be combined with
  Auto-detect, and it has no Persian.
- The free Google Translate endpoint is unofficial: it can be rate-limited or changed by Google.
  Gemini with your own key remains the supported fallback.
- **macOS is not notarized** (no Apple Developer account behind the build): the first launch needs
  right-click → **Open**. **iOS has no binary release** — it runs from source with your own Apple
  Developer team, because installing on a device needs a provisioning profile.
- **Intel Macs:** the DMG is a universal binary (every framework ships `x86_64` as well as `arm64`) and
  the Intel slice was verified to launch under Rosetta on Apple Silicon. It has not been run on a
  physical Intel Mac yet, so please report anything that misbehaves.

### Downloads

| File | Platform | Use it for |
|---|---|---|
| `app-arm64-v8a-release.apk` | Android | any recent phone (recommended) |
| `app-armeabi-v7a-release.apk` | Android | older 32-bit devices |
| `app-x86_64-release.apk` | Android | emulators |
| `Veliq-1.2.0-macos-universal.dmg` | macOS 14+ | one file for **both** Intel and Apple Silicon Macs |

Install the APK over a previous GitHub build of `com.moradzadeh67.veliq`; the APKs are signed with the
same upload key, so your history and settings survive the update.

The macOS DMG is ad-hoc signed: open it, drag **veliq** into *Applications*, then right-click the app →
**Open** the first time. If macOS still refuses, run `xattr -dr com.apple.quarantine /Applications/veliq.app`.
