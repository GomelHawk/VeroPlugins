#!/usr/bin/env python3
"""Rebuild the catalog's pictures from the plugins' logos (STANDARD.md, section 5).

    scripts/assets.py [--plugins-root DIR]

For every entry of .claude-plugin/marketplace.json it expects the plugin's repository
beside this one, DIR/Vero<Word>/assets/ (DIR defaults to the parent folder), and writes
assets/vero-<word>.png (the horizontal logo, 520 px wide), assets/banner.png and assets/social-preview.png (1280×640).
Needs Pillow and the DejaVu fonts (fonts-dejavu on Debian/Ubuntu).
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'assets') + os.sep
PLUGINS_ROOT = os.path.dirname(ROOT)
if len(sys.argv) == 3 and sys.argv[1] == '--plugins-root':
    PLUGINS_ROOT = sys.argv[2]
elif len(sys.argv) != 1:
    sys.exit(__doc__)
def display_of(key):  # vero-diff -> VeroDiff
    return ''.join(p.capitalize() for p in key.split('-'))
catalog = json.load(open(os.path.join(ROOT, '.claude-plugin', 'marketplace.json')))
plugins = [(e['name'], os.path.join(PLUGINS_ROOT, display_of(e['name']), 'assets') + os.sep) for e in catalog['plugins']]
for name, d in plugins:
    if not os.path.isfile(d + 'logo.png') or not os.path.isfile(d + 'horizontal-logo.png'):
        sys.exit(f'{name}: no logo.png / horizontal-logo.png under {d}')
BG = (11, 11, 15)
FONT_B = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
FONT_R = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

def is_bg(px, thr=40):
    return max(px[:3]) < thr

def bbox_nonbg(im, thr=40):
    g = im.convert('RGB')
    w, h = g.size
    px = g.load()
    rows = [any(not is_bg(px[x, y], thr) for x in range(0, w, 2)) for y in range(h)]
    cols = [any(not is_bg(px[x, y], thr) for y in range(0, h, 2)) for x in range(w)]
    return rows, cols

def flatten(im, thr=40):
    """Replace the logo's own near-black background with BG, so it sits on the banner seamlessly."""
    im = im.convert('RGB')
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if max(px[x, y]) < thr: px[x, y] = BG
    return im

def trim(im, thr=40):
    rows, cols = bbox_nonbg(im, thr)
    ys = [y for y, r in enumerate(rows) if r]; xs = [x for x, c in enumerate(cols) if c]
    return im.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1))


# 1. the table's logos: each plugin's horizontal logo, 520 px wide, served from this repo
for name, d in plugins:
    l = Image.open(d + 'horizontal-logo.png').convert('RGB')
    l.resize((520, round(l.size[1] * 520 / l.size[0])), Image.LANCZOS).save(OUT + name + '.png', optimize=True)

# 2. banner and social preview
def compose(width, height, title_px, sub_px, logo_h, pad):
    im = Image.new('RGB', (width, height), BG)
    dr = ImageDraw.Draw(im)
    ft = ImageFont.truetype(FONT_B, title_px); fs = ImageFont.truetype(FONT_R, sub_px)
    title = 'VeroPlugins'
    tw = dr.textlength(title, font=ft)
    content_h = title_px * 1.25 + sub_px * 2.2 + logo_h
    y = (height - content_h) / 2
    # "Vero" white, "Plugins" accent
    vw = dr.textlength('Vero', font=ft)
    x0 = (width - tw) / 2
    dr.text((x0, y), 'Vero', font=ft, fill=(245, 245, 247))
    dr.text((x0 + vw, y), 'Plugins', font=ft, fill=(120, 170, 255))
    y += title_px * 1.25
    sub = 'One marketplace for every Vero plugin for Claude Code'
    sw = dr.textlength(sub, font=fs)
    dr.text(((width - sw) / 2, y), sub, font=fs, fill=(150, 152, 160))
    y += sub_px * 2.2
    logos = []
    for name, d in plugins:
        l = flatten(trim(Image.open(d + 'horizontal-logo.png').convert('RGB')))
        s = logo_h / l.size[1]
        logos.append(l.resize((int(l.size[0] * s), logo_h), Image.LANCZOS))
    gap = int(width * 0.04)
    total = sum(l.size[0] for l in logos) + gap * (len(logos) - 1)
    if total > width - 2 * pad:
        s = (width - 2 * pad) / total
        logos = [l.resize((int(l.size[0] * s), int(l.size[1] * s)), Image.LANCZOS) for l in logos]
        total = sum(l.size[0] for l in logos) + gap * (len(logos) - 1)
    x = (width - total) // 2
    ly = int(y)
    for l in logos:
        im.paste(l, (x, ly + (logo_h - l.size[1]) // 2)); x += l.size[0] + gap
    return im

compose(1800, 560, 110, 34, 150, 60).save(OUT + 'banner.png', optimize=True)
print('banner.png, social-preview.png and', ', '.join(n + '.png' for n, _ in plugins), 'written to', OUT)
compose(1280, 640, 96, 30, 130, 90).save(OUT + 'social-preview.png', optimize=True)
