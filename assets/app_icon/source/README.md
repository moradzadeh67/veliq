# App icon source

`generate_icons.sh` regenerates every Veliq app icon from one vector master.

| File | Purpose |
| --- | --- |
| `generate_icons.sh` | Regenerates every required size into the two Xcode asset catalogs and rebuilds both `.icns` bundles. |

## Source of truth

`assets/branding/logo.svg` — a pure-vector 512×512 master (squircle background,
four white corner brackets pushed 20 % outward, four gold text bars). Edit that
file, then re-run the script. Never edit the generated PNGs by hand.

## Regenerating

```sh
./assets/app_icon/source/generate_icons.sh
```

## Pipeline

Each size is rendered straight from the vector source with `rsvg-convert`, at the
exact target pixel size — no intermediate raster, so there is no halo and no
resampling step to tune:

1. **macOS** — the squircle clip is kept, so the surround is transparent
   (macOS draws no mask of its own).
2. **iOS** — the clip attribute is stripped with `sed`, giving a full-bleed
   opaque square. The OS applies its own rounded mask, and App Store Connect
   rejects icons that carry an alpha channel. The script asserts this
   (`sips -g hasAlpha`) and fails loudly if it ever regresses.
3. **`.icns`** — the seven macOS PNGs are copied into a temporary `*.iconset`
   under the ten names `iconutil` requires, then packed to
   `assets/app_icon/veliq.icns` and `assets/branding/AppIcon.icns`.

## What it writes

| Destination | Count | Surround |
| --- | --- | --- |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_<N>.png` | 7 | transparent (alpha kept) |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` | 15 | full-bleed, opaque, **no alpha** |
| `assets/app_icon/veliq.icns` | 1 | built from the macOS PNGs |
| `assets/branding/AppIcon.icns` | 1 | identical copy for the branding folder |

File names are intentionally the ones the Flutter templates already use, so the
two `Contents.json` files in the catalogs need no edits.

## Engines

- **`rsvg-convert`** (librsvg) — the only renderer. Install with
  `brew install librsvg`.
- **`sips`** — asserts the iOS master PNG carries no alpha channel (ships with macOS).
- **`iconutil`** — packs the `.icns` bundles (ships with macOS).

No Python, Node or Flutter tooling is required.

## Design decisions (from the designer)

- **macOS**: rounded squircle with a transparent surround, matching the shipped
  Flutter template icons, which also carry alpha.
- **iOS**: full-bleed opaque square — Apple rejects alpha and the OS masks the
  corners itself.
- The artwork is never recoloured, rescaled non-uniformly or redrawn.

## Notes

- `assets/app_icon/` and `assets/branding/` are **not** bundled into the app;
  there is no `assets:` entry in `pubspec.yaml`, so nothing here ships in the
  binary.
- Icon changes are committed as PNGs. Re-running the script is byte-stable for a
  given engine.
