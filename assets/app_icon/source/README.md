# App icon source

This folder is the **single source of truth** for every Veliq app icon.

| File | Purpose |
| --- | --- |
| `icon_master.png` | The master artwork. 1024×1024, square, **opaque** (no alpha channel). Every generated size is derived from this one file. Never edit the generated PNGs by hand — edit the master and re-run the script. |
| `generate_icons.sh` | Regenerates every required size into the two Xcode asset catalogs and rebuilds `veliq.icns`. |

## Regenerating

```sh
./assets/app_icon/source/generate_icons.sh
```

## Pipeline

Every size is produced from the master in four steps:

1. **Key** — the master's opaque black surround is keyed out (becomes transparent).
2. **Crop** — the empty margin is removed. In the master the artwork's opaque pixels
   start at `x=11 / y=7` and end at `x=1012 / y=1015`, so the script crops to
   `CROP_SIZE=1010` at `CROP_INSET=7`. This makes the artwork span the canvas instead
   of sitting inside a ~1 % empty band, and it stops the downscaler from blending
   transparent black into the icon edge — without it, the smaller sizes pick up a
   visible dark halo (measured: a 256 px edge pixel was `#0f0d38` at 42 % alpha
   instead of `#2b15b5`; after the crop it is `#2b15b5` at full alpha).
3. **Resize** — Lanczos downscale to the target pixel size.
4. **Flatten** — iOS only (`-alpha remove` / `-alpha off`), because Apple rejects
   icons that carry an alpha channel.

Re-measure the crop after replacing the master:

```sh
ffmpeg -i icon_master.png -vf cropdetect -f null -
```

A **~0.4 % transparent margin remains on the left/right** (4 px at 1024) because the
artwork is very slightly narrower than it is tall. The script deliberately keeps the
crop square rather than distorting the artwork or clipping its straight edges.

## What it writes

| Destination | Count | Surround |
| --- | --- | --- |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_<N>.png` | 7 | **transparent** — the master's black surround is keyed out |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` | 15 | flattened onto `#2B1F5C`, **opaque**, no alpha |
| `assets/app_icon/veliq.icns` | 1 | built from the macOS PNGs via `iconutil` |

File names are intentionally the ones the Flutter templates already use, so the
two `Contents.json` files in the catalogs need no edits.

## Engines

The master is a 24-bit RGB PNG whose artwork sits on an **opaque black field**.
Backgrounds must be reworked per platform, so a resize-only tool is not enough:

- **`sips`** — pixel-size inspection and plain resizing (ships with macOS).
- **ImageMagick** (`magick` / `convert`) — preferred engine: flood-fills the black
  surround from the corners (`-fuzz 12% -fill none -floodfill +0+0 black`) so the
  artwork's soft glow is preserved exactly.
- **`ffmpeg`** — fallback used when ImageMagick is absent: `colorkey` with a soft
  blend ramp, then the crop and the scale. Its `premultiply` / `unpremultiply` filters
  take **two inputs** in this build and so cannot be used in a simple `-vf` graph;
  the crop is what removes the halo.
- **`iconutil`** — packs `veliq.icns`.

No Python, Node or Flutter tooling is required.

## Design decisions (from the designer)

- **macOS**: icons keep the platform convention of a rounded squircle with a
  transparent surround (the shipped Flutter template icons also carry alpha).
  The master's black surround is therefore keyed out.
- **iOS**: Apple rejects icons with an alpha channel, and the OS applies its own
  squircle mask, so every iOS PNG is a full-bleed opaque square. The surround is
  flattened onto the palette background `#2B1F5C`, taken from the Concept B palette.
- The artwork itself is never recoloured, rescaled non-uniformly or redrawn.

## Notes

- `assets/app_icon/` is **not** bundled into the app; there is no `assets:`
  entry in `pubspec.yaml`, so nothing here ships in the binary.
- Icon changes are committed as PNGs. Re-running the script must be byte-stable
  for a given engine.
