# Veliq branding assets

Everything a README, GitHub profile, App Store page or About dialog needs, all
derived from one vector master.

| File | Size | Purpose |
| --- | --- | --- |
| `logo.svg` | vector, 512×512 | **Master artwork.** Layers: `background`, `brackets`, `bars`. Edit the generator (below), never this file by hand. |
| `logo-1024.png` | 1024×1024 | Raster master, referenced by the composite previews below. |
| `readme-banner.png` | 1600×400 | Header banner for `README.md`. |
| `social-preview.png` | 1280×640 | Open Graph / social card (logo, name, tagline). |
| `github-avatar.png` | 460×460 | GitHub organisation/user avatar. |
| `about-logo.png` | 256×256 | Logo block for an in-app About dialog. |
| `favicon.ico` | 16/32/48 | Browser favicon for the project page. |
| `AppIcon.icns` | — | macOS app icon. **Not built by this folder** — it is packed from the macOS appiconset by `../app_icon/source/generate_icons.sh`. |
| `generate_branding.py` | — | Regenerates every file above (everything except `AppIcon.icns`). |

## Regenerating

```sh
python3 assets/branding/generate_branding.py
```

Requires `rsvg-convert` (`brew install librsvg`) and Pillow (`favicon.ico` only).
Output is byte-stable: re-running on an unchanged master changes nothing.

## Source of truth

`generate_branding.py` holds the approved design constants and writes `logo.svg`
from them — so `logo.svg` is generated, not hand-edited:

| Constant | Value | Meaning |
| --- | --- | --- |
| Outward factor | `1.20` | Brackets sit 20 % further out than the original artwork |
| `BAR_W` | 205, 150, 205, 110 | Four text bars (the design converged on **4 lines**, not 5) |
| `N` | 4.3 | Superellipse exponent of the squircle background (max path deviation 0.178 px) |
| Name / tagline | `Veliq` / `Local-first screen & photo translator` | Wordmark used in composites |

Palette: background `#241A85 → #3B2FBF → #5737DA → #6E3FE0`, highlight
`#8B5CF6`/`#A78BFA`, brackets `#FFFFFF → #EFEFF8`, bars `#FFE7A6 → #FFD27E → #FEB84D`.
Type: Helvetica Neue.

## Composites

The composite SVGs (banner, card, avatar, About block) are written to a temp
directory next to a copy of `logo-1024.png` and reference it with a *relative*
href — librsvg does not resolve absolute `file://` URLs.

## Notes

- Nothing in `assets/branding/` is bundled into the app: there is no `assets:`
  entry in `pubspec.yaml`, so no branding file ships in the binary.
- Rebuild order: run `../app_icon/source/generate_icons.sh` to refresh the app
  icons and `AppIcon.icns`; run `generate_branding.py` for everything else.
