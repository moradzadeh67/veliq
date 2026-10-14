#!/usr/bin/env bash
#
# Regenerates every VelIQ app-icon size for macOS and iOS from logo.svg.
#
# Single source of truth: assets/branding/logo.svg  (pure vector, 4-line design)
# Outputs:
#   macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_<N>.png   (7 files)
#   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png       (15 files)
#   assets/app_icon/veliq.icns
#   assets/branding/AppIcon.icns
#
# Two renders per size, both straight from the vector source:
#   macOS keeps the squircle clip  -> transparent surround (macOS draws no mask).
#   iOS drops the clip             -> full-bleed opaque square. The OS applies its
#      own rounded mask, and App Store Connect rejects icons that carry alpha.
#
# Engines:
#   rsvg-convert (librsvg) - SVG -> PNG at the exact pixel size (alpha-aware)
#   sips                   - asserts the iOS PNGs carry no alpha channel
#   iconutil               - packs the .icns bundles (ships with macOS)
# No Python, Node or Flutter tooling is used.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"

SVG="$ROOT/assets/branding/logo.svg"
MAC_DIR="$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"
IOS_DIR="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ICNS_APP="$ROOT/assets/app_icon/veliq.icns"
ICNS_BRANDING="$ROOT/assets/branding/AppIcon.icns"

# Only the background group is clipped; iOS must fill the whole square.
CLIP_ATTR=' clip-path="url(#squircle-clip)"'

if [[ ! -f "$SVG" ]]; then
  echo "error: master vector not found: $SVG" >&2
  exit 1
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "error: rsvg-convert not found. Install it with: brew install librsvg" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
FULL_BLEED="$WORKDIR/logo-full-bleed.svg"
sed "s/$CLIP_ATTR//" "$SVG" > "$FULL_BLEED"

if grep -q 'clip-path' "$FULL_BLEED"; then
  echo "error: failed to strip the squircle clip for the iOS variant" >&2
  exit 1
fi

# macOS: squircle kept, transparent surround.
mac_count=0
for size in 16 32 64 128 256 512 1024; do
  rsvg-convert -w "$size" -h "$size" -o "$MAC_DIR/app_icon_${size}.png" "$SVG"
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
  rsvg-convert -w "$size" -h "$size" -o "$IOS_DIR/$name" "$FULL_BLEED"
  ios_count=$((ios_count + 1))
done <<< "$ios_sizes"

# Apple rejects icons that carry an alpha channel; assert the flattening held.
if sips -g hasAlpha "$IOS_DIR/Icon-App-1024x1024@1x.png" | grep -q "hasAlpha: yes"; then
  echo "error: iOS 1024 icon still carries an alpha channel" >&2
  exit 1
fi

# --- .icns: iconutil needs the 10 canonical names inside a *.iconset ---
ICONSET="$WORKDIR/AppIcon.iconset"
mkdir -p "$ICONSET"

cp "$MAC_DIR/app_icon_16.png"   "$ICONSET/icon_16x16.png"
cp "$MAC_DIR/app_icon_32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$MAC_DIR/app_icon_32.png"   "$ICONSET/icon_32x32.png"
cp "$MAC_DIR/app_icon_64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$MAC_DIR/app_icon_128.png"  "$ICONSET/icon_128x128.png"
cp "$MAC_DIR/app_icon_256.png"  "$ICONSET/icon_128x128@2x.png"
cp "$MAC_DIR/app_icon_256.png"  "$ICONSET/icon_256x256.png"
cp "$MAC_DIR/app_icon_512.png"  "$ICONSET/icon_256x256@2x.png"
cp "$MAC_DIR/app_icon_512.png"  "$ICONSET/icon_512x512.png"
cp "$MAC_DIR/app_icon_1024.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$ICNS_APP"
iconutil -c icns "$ICONSET" -o "$ICNS_BRANDING"

echo "generated ${mac_count} macOS PNGs, ${ios_count} iOS PNGs and 2 .icns bundles"
