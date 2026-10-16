#!/usr/bin/env python3
"""Regenerate every Veliq branding asset from the master geometry.

Outputs (all written into this folder):
    logo.svg            master vector, 512x512, layers: background / brackets / bars
    logo-1024.png       raster master
    favicon.ico         16 / 32 / 48 px
    social-preview.png  1280 x 640
    readme-banner.png   1600 x 600
    github-avatar.png   460 x 460
    about-logo.png      256 x 256

AppIcon.icns is NOT built here - it is packed from the macOS appiconset by
../app_icon/source/generate_icons.sh, which is the only writer of that file.

Requires: rsvg-convert (brew install librsvg) and Pillow (favicon.ico only).
Usage:    python3 assets/branding/generate_branding.py
"""
import math
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "Helvetica Neue, Arial, sans-serif"
NAME = "Veliq"
TAGLINE = "Local-first screen &amp; photo translator"

# ---- readme banner copy (approved 2026-10-15) ----
BADGE = "FLUTTER LOCAL-FIRST"
BANNER_SUBTITLE = "Capture or pick a photo — read it in Persian."
BANNER_DESC1 = "On-device OCR with Apple Vision and ML Kit, translation through Gemini"
BANNER_DESC2 = "with your own key, and a local, deletable history — on macOS, iOS and Android."
CHIPS = [(110, 276, "⚡", "On-device OCR"),
         (410, 312, "📷", "Gallery + Camera"),
         (746, 356, "🔐", "Key stays on-device")]

BANNER_DEFS = '''<defs>
  <linearGradient id="bp-bg" x1="0.08" y1="1" x2="0.92" y2="0">
    <stop offset="0" stop-color="#241A85"/><stop offset="0.35" stop-color="#3B2FBF"/>
    <stop offset="0.72" stop-color="#5737DA"/><stop offset="1" stop-color="#6E3FE0"/>
  </linearGradient>
  <radialGradient id="bp-vignette" cx="0.5" cy="0.62" r="0.80">
    <stop offset="0" stop-color="#05073A" stop-opacity="0"/>
    <stop offset="0.55" stop-color="#05073A" stop-opacity="0.10"/>
    <stop offset="1" stop-color="#04052E" stop-opacity="0.55"/>
  </radialGradient>
  <radialGradient id="bp-highlight" cx="0.72" cy="0.12" r="0.60">
    <stop offset="0" stop-color="#A78BFA" stop-opacity="0.55"/>
    <stop offset="0.42" stop-color="#8B5CF6" stop-opacity="0.28"/>
    <stop offset="1" stop-color="#8B5CF6" stop-opacity="0"/>
  </radialGradient>
  <pattern id="bp-grid" width="80" height="80" patternUnits="userSpaceOnUse">
    <path d="M 80 0 L 0 0 0 80" fill="none" stroke="#FFFFFF" stroke-opacity="0.05" stroke-width="1"/>
  </pattern>
  <radialGradient id="bp-glow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>
    <stop offset="0.55" stop-color="#FFFFFF" stop-opacity="0.08"/>
    <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
  </radialGradient>
  <filter id="bp-card-shadow" x="-10%" y="-20%" width="120%" height="150%" color-interpolation-filters="sRGB">
    <feDropShadow dx="0" dy="20" stdDeviation="30" flood-color="#0A0640" flood-opacity="0.45"/>
  </filter>
  <filter id="bp-icon-shadow" x="-35%" y="-35%" width="170%" height="170%" color-interpolation-filters="sRGB">
    <feDropShadow dx="0" dy="16" stdDeviation="22" flood-color="#0A0640" flood-opacity="0.55"/>
  </filter>
  <filter id="bp-text-shadow" x="-15%" y="-30%" width="130%" height="160%" color-interpolation-filters="sRGB">
    <feDropShadow dx="0" dy="3" stdDeviation="7" flood-color="#1A0E52" flood-opacity="0.40"/>
  </filter>
</defs>'''

# ---- geometry (512 space), approved design: 4 bars, outward factor 1.20 ----
N = 4.3                 # superellipse exponent (squircle)
A = 256.0               # half side
CX = CY = 256.0
T = 35.0                # bracket stroke thickness
LH = 94.0               # horizontal arm length (outer extent)
LV = 96.0               # vertical arm length (outer extent)
HX0 = 170.5             # base outer-corner horizontal offset from centre
HY0 = 151.0             # base outer-corner vertical offset from centre
BAR_H = [27.0, 26.0, 27.0, 26.0]
BAR_W = [205.0, 150.0, 205.0, 110.0]
BAR_Y = [182.0, 223.0, 263.0, 304.0]
FACTOR = 1.20


def se_point(t):
    c, s = math.cos(t), math.sin(t)
    e = 2.0 / N
    x = CX + A * math.copysign(abs(c) ** e, c)
    y = CY + A * math.copysign(abs(s) ** e, s)
    return (x, y)


def squircle_path():
    # dense uniform-t polyline -> arc-length resample -> catmull-rom cubics
    dense = [se_point(2 * math.pi * i / 512) for i in range(512)]
    cum = [0.0]
    for i in range(1, len(dense) + 1):
        a = dense[i - 1]
        b = dense[i % len(dense)]
        cum.append(cum[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    total = cum[-1]
    M = 48
    pts = []
    j = 0
    for k in range(M):
        target = total * k / M
        while j + 1 < len(cum) and cum[j + 1] < target:
            j += 1
        seg = cum[j + 1] - cum[j]
        f = 0.0 if seg == 0 else (target - cum[j]) / seg
        a, b = dense[j], dense[(j + 1) % len(dense)]
        pts.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f))

    def cr(p0, p1, p2, p3):
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        return c1, c2

    d = "M %.2f %.2f" % pts[0]
    for i in range(M):
        p0 = pts[(i - 1) % M]
        p1 = pts[i]
        p2 = pts[(i + 1) % M]
        p3 = pts[(i + 2) % M]
        c1, c2 = cr(p0, p1, p2, p3)
        d += " C %.2f %.2f %.2f %.2f %.2f %.2f" % (c1[0], c1[1], c2[0], c2[1], p2[0], p2[1])
    d += " Z"
    return d


def bracket_paths(f):
    """f = outward factor. Returns 4 path d-strings (TL, TR, BL, BR)."""
    ox = CX - HX0 * f          # left outer edge x of left brackets
    oy = CY - HY0 * f          # top outer edge y of top brackets
    rx = 2 * CX - ox           # right outer edge
    by = 2 * CY - oy           # bottom outer edge
    h = T / 2.0
    tip_h = LH - h             # inner tip offset from outer corner (horiz)
    tip_v = LV - h

    def bracket(x, y, sx, sy):
        # sx: +1 left brackets (arm points right), -1 right
        # sy: +1 top brackets (arm points down),  -1 bottom
        return "M %.2f %.2f L %.2f %.2f L %.2f %.2f" % (
            x + sx * tip_h, y + sy * h,
            x + sx * h, y + sy * h,
            x + sx * h, y + sy * tip_v)

    return [
        bracket(ox, oy, +1, +1),      # top-left
        bracket(rx, oy, -1, +1),      # top-right
        bracket(ox, by, +1, -1),      # bottom-left
        bracket(rx, by, -1, -1),      # bottom-right
    ]


def build_svg(f):
    d_sq = squircle_path()
    br = bracket_paths(f)
    bars = ""
    for i in range(len(BAR_W)):
        w, h, y = BAR_W[i], BAR_H[i], BAR_Y[i]
        bars += '      <rect id="bar-%d" x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f"/>\n' % (
            i + 1, CX - w / 2, y, w, h, h / 2)
    bpaths = "".join('      <path d="%s"/>\n' % p for p in br)
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <clipPath id="squircle-clip"><path id="squircle" d="%s"/></clipPath>
    <linearGradient id="bg-gradient" x1="0.08" y1="1" x2="0.92" y2="0">
      <stop offset="0" stop-color="#241A85"/>
      <stop offset="0.35" stop-color="#3B2FBF"/>
      <stop offset="0.72" stop-color="#5737DA"/>
      <stop offset="1" stop-color="#6E3FE0"/>
    </linearGradient>
    <radialGradient id="bg-vignette" cx="0.5" cy="0.66" r="0.78">
      <stop offset="0" stop-color="#05073A" stop-opacity="0"/>
      <stop offset="0.55" stop-color="#05073A" stop-opacity="0.10"/>
      <stop offset="1" stop-color="#04052E" stop-opacity="0.62"/>
    </radialGradient>
    <radialGradient id="bg-highlight" cx="0.70" cy="0.13" r="0.62">
      <stop offset="0" stop-color="#A78BFA" stop-opacity="0.62"/>
      <stop offset="0.42" stop-color="#8B5CF6" stop-opacity="0.34"/>
      <stop offset="1" stop-color="#8B5CF6" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="bracket-fill" x1="0.15" y1="0" x2="0.75" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="0.6" stop-color="#FCFCFF"/>
      <stop offset="1" stop-color="#EFEFF8"/>
    </linearGradient>
    <linearGradient id="bar-fill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFE7A6"/>
      <stop offset="0.5" stop-color="#FFD27E"/>
      <stop offset="1" stop-color="#FEB84D"/>
    </linearGradient>
    <filter id="drop-shadow" x="-45%%" y="-45%%" width="190%%" height="190%%" color-interpolation-filters="sRGB">
      <feDropShadow dx="0" dy="6" stdDeviation="12" flood-color="#080442" flood-opacity="0.30"/>
    </filter>
    <filter id="bar-shadow" x="-60%%" y="-60%%" width="220%%" height="220%%" color-interpolation-filters="sRGB">
      <feDropShadow dx="0" dy="5" stdDeviation="9" flood-color="#1A0E52" flood-opacity="0.34"/>
    </filter>
  </defs>
  <g id="background" clip-path="url(#squircle-clip)">
    <rect width="512" height="512" fill="url(#bg-gradient)"/>
    <rect width="512" height="512" fill="url(#bg-vignette)"/>
    <rect width="512" height="512" fill="url(#bg-highlight)"/>
  </g>
  <g id="brackets" fill="none" stroke="url(#bracket-fill)" stroke-width="%.1f"
     stroke-linecap="round" stroke-linejoin="round" filter="url(#drop-shadow)">
%s  </g>
  <g id="bars" fill="url(#bar-fill)" filter="url(#bar-shadow)">
%s  </g>
</svg>
''' % (d_sq, T, bpaths, bars)


# ---------------------------------------------------------------- rendering
def render(svg_path, out_path, w=None, h=None):
    cmd = ["rsvg-convert"]
    if w and h:
        cmd += ["-w", str(w), "-h", str(h)]
    cmd += ["-o", out_path, svg_path]
    subprocess.run(cmd, check=True)
    return out_path


def svg_doc(w, h, body, defs=""):
    return ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'
            ' viewBox="0 0 %d %d" width="%d" height="%d">%s%s</svg>' % (w, h, w, h, defs, body))


ICON_SHADOW = ('<filter id="icon-shadow" x="-25%%" y="-25%%" width="150%%" height="150%%"'
               ' color-interpolation-filters="sRGB">'
               '<feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#2E1F8E" flood-opacity="0.20"/>'
               '</filter>')
# librsvg does not resolve absolute file:// URLs, so composite SVGs are written
# into a workdir next to a copy of logo-1024.png and use a relative href.
ICON_HREF = 'xlink:href="logo-1024.png"'


def image(x, y, size, shadow=True):
    f = ' filter="url(#icon-shadow)"' if shadow else ''
    return ('<g%s><image %s x="%d" y="%d" width="%d" height="%d"/></g>'
            % (f, ICON_HREF, x, y, size, size))


def text(s, x, y, size, weight, fill, anchor="start", spacing=None):
    ls = ' letter-spacing="%s"' % spacing if spacing else ''
    an = ' text-anchor="%s"' % anchor if anchor != "start" else ''
    return ('<text x="%d" y="%d" font-family="%s" font-size="%d" font-weight="%s"%s%s fill="%s">%s</text>'
            % (x, y, FONT, size, weight, an, ls, fill, s))


def main():
    if not shutil.which("rsvg-convert"):
        sys.exit("error: rsvg-convert not found. Install it with: brew install librsvg")

    # ---------------------------------------------------------------- 1. master SVG
    logo_svg_path = os.path.join(HERE, "logo.svg")
    with open(logo_svg_path, "w") as fh:
        fh.write(build_svg(FACTOR))

    # ---------------------------------------------------------------- 2. master PNG
    # rendered before any composite so the composites reference the current art
    logo_png = os.path.join(HERE, "logo-1024.png")
    render(logo_svg_path, logo_png, w=1024, h=1024)

    workdir = tempfile.mkdtemp(prefix="veliq-branding-")
    try:
        shutil.copyfile(logo_png, os.path.join(workdir, "logo-1024.png"))

        # ------------------------------------------------------- 3. social preview
        social = svg_doc(1280, 640,
                         '<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
                         '<stop offset="0" stop-color="#F8F8FC"/><stop offset="1" stop-color="#ECE9FB"/>'
                         '</linearGradient>%s</defs>'
                         '<rect width="1280" height="640" fill="url(#bg)"/>'
                         '%s%s%s' % (
                             ICON_SHADOW,
                             image(205, 170, 300),
                             text(NAME, 575, 332, 96, "700", "#3B2FBF", spacing="-2"),
                             text(TAGLINE, 577, 388, 30, "400", "#6E6E73")))
        p = os.path.join(workdir, "social-preview.svg")
        with open(p, "w") as fh:
            fh.write(social)
        render(p, os.path.join(HERE, "social-preview.png"), w=1280, h=640)

        # ------------------------------------------------------- 4. readme banner
        # Approved 2026-10-15: glass card over the brand gradient — badge,
        # title, gold subtitle, two-line description, three chips, and the
        # logo in a rounded panel with two orbit rings. Replaces the old
        # 1600x400 white banner.
        badge = ('<g><rect x="110" y="92" width="402" height="54" rx="27" fill="#241A85" fill-opacity="0.5" '
                 'stroke="#FFFFFF" stroke-opacity="0.30"/>'
                 '<circle cx="142" cy="119" r="7" fill="#FFD27E"/>%s</g>'
                 % text(BADGE, 164, 128, 22, "600", "#FFE7A6", spacing="3"))
        chips = ""
        for x, w, icon, label in CHIPS:
            chips += ('<g><rect x="%d" y="452" width="%d" height="58" rx="29" fill="#241A85" fill-opacity="0.45" '
                      'stroke="#FFE7A6" stroke-opacity="0.35"/>%s%s</g>'
                      % (x, w, text(icon, x + 22, 490, 24, "400", "#FFFFFF"),
                         text(label, x + 58, 490, 25, "500", "#F2EEFF")))
        orbits = ('<g fill="none" stroke-width="2">'
                  '<ellipse cx="1300" cy="300" rx="230" ry="104" transform="rotate(-24 1300 300)"'
                  ' stroke="#FFFFFF" stroke-opacity="0.35"/>'
                  '<ellipse cx="1300" cy="300" rx="212" ry="82" transform="rotate(22 1300 300)"'
                  ' stroke="#FFE7A6" stroke-opacity="0.30"/>'
                  '</g>')
        banner = svg_doc(1600, 600,
                         BANNER_DEFS
                         + '<rect width="1600" height="600" fill="url(#bp-bg)"/>'
                         + '<rect width="1600" height="600" fill="url(#bp-vignette)"/>'
                         + '<rect width="1600" height="600" fill="url(#bp-highlight)"/>'
                         '<g filter="url(#bp-card-shadow)"><rect x="40" y="36" width="1520" height="528" rx="36" '
                         'fill="#1A1055" fill-opacity="0.28"/></g>'
                         '<g><rect x="40" y="36" width="1520" height="528" rx="36" fill="url(#bp-grid)"/></g>'
                         '<rect x="40" y="36" width="1520" height="528" rx="36" fill="none" stroke="#FFFFFF" '
                         'stroke-opacity="0.22" stroke-width="1.5"/>'
                         + badge
                         + '<g filter="url(#bp-text-shadow)">%s</g>' % text(NAME, 110, 252, 96, "700", "#FFFFFF", spacing="-3")
                         + text(BANNER_SUBTITLE, 112, 318, 38, "600", "#FFD27E")
                         + text(BANNER_DESC1, 112, 372, 26, "400", "#D8D2F5")
                         + text(BANNER_DESC2, 112, 408, 26, "400", "#D8D2F5")
                         + chips
                         + '<circle cx="1300" cy="300" r="250" fill="url(#bp-glow)"/>'
                         + orbits
                         + '<g filter="url(#bp-icon-shadow)"><rect x="1140" y="140" width="320" height="320" rx="72" '
                         'fill="#FFFFFF" fill-opacity="0.10" stroke="#FFFFFF" stroke-opacity="0.30" stroke-width="1.5"/></g>'
                         + image(1176, 176, 248, shadow=False))
        p = os.path.join(workdir, "readme-banner.svg")
        with open(p, "w") as fh:
            fh.write(banner)
        render(p, os.path.join(HERE, "readme-banner.png"), w=1600, h=600)

        # ------------------------------------------------------- 5. favicon
        try:
            from PIL import Image
        except ImportError:
            sys.exit("error: Pillow is required to build favicon.ico (pip install Pillow)")
        fav_paths = []
        for size in (16, 32, 48):
            fp = os.path.join(workdir, "favicon-%d.png" % size)
            render(logo_svg_path, fp, w=size, h=size)
            fav_paths.append(fp)
        base = Image.open(fav_paths[-1]).convert("RGBA")
        base.save(os.path.join(HERE, "favicon.ico"), format="ICO",
                  sizes=[(16, 16), (32, 32), (48, 48)])

        # ------------------------------------------------------- 6. github avatar
        avatar = svg_doc(460, 460, image(14, 14, 432, shadow=False))
        p = os.path.join(workdir, "github-avatar.svg")
        with open(p, "w") as fh:
            fh.write(avatar)
        render(p, os.path.join(HERE, "github-avatar.png"), w=460, h=460)

        # ------------------------------------------------------- 7. about logo
        about = svg_doc(256, 256,
                        '<defs>%s</defs>'
                        '%s%s' % (
                            ICON_SHADOW,
                            image(53, 36, 150),
                            text(NAME, 128, 238, 46, "700", "#3B2FBF", anchor="middle", spacing="-1")))
        p = os.path.join(workdir, "about-logo.svg")
        with open(p, "w") as fh:
            fh.write(about)
        render(p, os.path.join(HERE, "about-logo.png"), w=256, h=256)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    print("generated logo.svg, logo-1024.png, favicon.ico, social-preview.png,"
          " readme-banner.png, github-avatar.png, about-logo.png")


if __name__ == "__main__":
    main()
