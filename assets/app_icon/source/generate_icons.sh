#!/usr/bin/env bash
#
# Regenerates every Veliq app-icon size for macOS and iOS from icon_master.png.
#
# Single source of truth: assets/app_icon/source/icon_master.png
# Outputs:
#   macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_<N>.png   (7 files)
#   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png      (15 files)
#   assets/app_icon/veliq.icns
#
# Pipeline, per size:
#   1. key the master's opaque black surround OUT (transparent).
#   2. crop away the empty margin so the artwork fills the canvas edge to edge.
#   3. resize. Because step 2 removes the transparent border band, the resampler no
#      longer blends transparent black into the icon edge, so the downscaled sizes
#      do not pick up a dark halo. (ffmpeg's premultiply/unpremultiply filters are
#      two-input filters in this build, so they cannot be used in a simple -vf
#      graph; ImageMagick, when present, resizes alpha-aware on its own.)
#   4. macOS keeps the alpha; iOS is flattened onto the palette background,
#      fully opaque, because Apple rejects icons with an alpha channel.
#
# Engines:
#   sips                             - pixel-size inspection
#   ImageMagick ("magick"/"convert") - preferred engine (alpha-aware resize)
#   ffmpeg                           - fallback engine
#   iconutil                         - packs veliq.icns
# No Python, Node or Flutter tooling is used.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"

MASTER="$HERE/icon_master.png"
MAC_DIR="$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"
IOS_DIR="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ICNS_OUT="$ROOT/assets/app_icon/veliq.icns"

# The master is 1024x1024 and its artwork does NOT reach the canvas edges:
# opaque pixels start at x=11 / y=7 and end at x=1012 / y=1015. Cropping with the
# smallest of those insets (7) makes the artwork span the canvas with no clipping
# at all, instead of leaving a ~1% empty band around it.
# Re-measure after replacing the master:
#   ffmpeg -i icon_master.png -vf cropdetect -f null -
CROP_INSET=7
CROP_SIZE=1010 # 1024 - 2 * CROP_INSET

# Palette background used for the iOS surround (Concept B).
IOS_BG_HEX="2B1F5C"
# Black-key tuning for the ffmpeg engine.
KEY_SIM=0.20
KEY_BLEND=0.08
# Black-key tolerance for the ImageMagick flood fill.
MAGICK_FUZZ="12%"

if [[ ! -f "$MASTER" ]]; then
  echo "error: master icon not found: $MASTER" >&2
  exit 1
fi

MAGICK=""
for candidate in magick convert; do
  if command -v "$candidate" >/dev/null 2>&1; then
    MAGICK="$candidate"
    break
  fi
done
HAS_FFMPEG=0
command -v ffmpeg >/dev/null 2>&1 && HAS_FFMPEG=1

if [[ -z "$MAGICK" && "$HAS_FFMPEG" -eq 0 ]]; then
  echo "error: need ImageMagick (magick) or ffmpeg to key the surround" >&2
  exit 1
fi

# macOS variant: transparent surround.
mac_png() { # $1 = pixel size, $2 = output path
  if [[ -n "$MAGICK" ]]; then
    "$MAGICK" "$MASTER" -alpha set -fuzz "$MAGICK_FUZZ" -fill none \
      -floodfill +0+0 black \
      -crop "${CROP_SIZE}x${CROP_SIZE}+${CROP_INSET}+${CROP_INSET}" +repage \
      -resize "${1}x${1}" -strip "$2"
  else
    ffmpeg -v error -y -i "$MASTER" \
      -vf "format=rgba,colorkey=0x000000:${KEY_SIM}:${KEY_BLEND},crop=${CROP_SIZE}:${CROP_SIZE}:${CROP_INSET}:${CROP_INSET},scale=${1}:${1}:flags=lanczos" \
      -frames:v 1 "$2"
  fi
}

# iOS variant: opaque square, surround flattened onto the palette background.
ios_png() { # $1 = pixel size, $2 = output path
  if [[ -n "$MAGICK" ]]; then
    "$MAGICK" "$MASTER" -alpha set -fuzz "$MAGICK_FUZZ" -fill none \
      -floodfill +0+0 black \
      -crop "${CROP_SIZE}x${CROP_SIZE}+${CROP_INSET}+${CROP_INSET}" +repage \
      -background "#${IOS_BG_HEX}" -alpha remove -alpha off \
      -resize "${1}x${1}" -strip "$2"
  else
    ffmpeg -v error -y -f lavfi -i "color=c=0x${IOS_BG_HEX}:s=${1}x${1}" -i "$MASTER" \
      -filter_complex "[1]format=rgba,colorkey=0x000000:${KEY_SIM}:${KEY_BLEND},crop=${CROP_SIZE}:${CROP_SIZE}:${CROP_INSET}:${CROP_INSET},scale=${1}:${1}:flags=lanczos[k];[0][k]overlay=format=auto,format=rgb24" \
      -frames:v 1 "$2"
  fi
}

mac_count=0
for size in 16 32 64 128 256 512 1024; do
  mac_png "$size" "$MAC_DIR/app_icon_${size}.png"
  mac_count=$((mac_count + 1))
done

# Base name -> pixel size, exactly matching ios/Runner/.../Contents.json.
ios_sizes="
Icon-App-20x20@1x.png 20
Icon-App-20x20@2x.png 40
Icon-App-20x20@3x.png 60
Icon-App-29x29@1x.png 29
Icon-App-29x29@2x.png 58
Icon-App-29x29@3x.png 87
Icon-App-40x40@1x.png 40
Icon-App-40x40@2x.png 80
Icon-App-40x40@3x.png 120
Icon-App-60x60@2x.png 120
Icon-App-60x60@3x.png 180
Icon-App-76x76@1x.png 76
Icon-App-76x76@2x.png 152
Icon-App-83.5x83.5@2x.png 167
Icon-App-1024x1024@1x.png 1024
"

ios_count=0
while read -r name size; do
  [[ -z "$name" ]] && continue
  ios_png "$size" "$IOS_DIR/$name"
  ios_count=$((ios_count + 1))
done <<< "$ios_sizes"

# --- veliq.icns: iconutil needs the 10 canonical names inside a *.iconset ---
TMP_ICONSET="$(mktemp -d)/veliq.iconset"
mkdir -p "$TMP_ICONSET"
trap 'rm -rf "$(dirname "$TMP_ICONSET")"' EXIT

cp "$MAC_DIR/app_icon_16.png"   "$TMP_ICONSET/icon_16x16.png"
cp "$MAC_DIR/app_icon_32.png"   "$TMP_ICONSET/icon_16x16@2x.png"
cp "$MAC_DIR/app_icon_32.png"   "$TMP_ICONSET/icon_32x32.png"
cp "$MAC_DIR/app_icon_64.png"   "$TMP_ICONSET/icon_32x32@2x.png"
cp "$MAC_DIR/app_icon_128.png"  "$TMP_ICONSET/icon_128x128.png"
cp "$MAC_DIR/app_icon_256.png"  "$TMP_ICONSET/icon_128x128@2x.png"
cp "$MAC_DIR/app_icon_256.png"  "$TMP_ICONSET/icon_256x256.png"
cp "$MAC_DIR/app_icon_512.png"  "$TMP_ICONSET/icon_256x256@2x.png"
cp "$MAC_DIR/app_icon_512.png"  "$TMP_ICONSET/icon_512x512.png"
cp "$MAC_DIR/app_icon_1024.png" "$TMP_ICONSET/icon_512x512@2x.png"

mkdir -p "$(dirname "$ICNS_OUT")"
iconutil -c icns "$TMP_ICONSET" -o "$ICNS_OUT"

echo "generated ${mac_count} macOS PNGs, ${ios_count} iOS PNGs and 1 .icns"
