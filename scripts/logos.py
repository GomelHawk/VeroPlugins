#!/usr/bin/env python3
"""Normalise a Vero plugin's two logos to the standard (STANDARD.md, section 5).

    scripts/logos.py <assets dir>          rewrites <assets dir>/horizontal-logo.png and logo.png in place

The drafts can be any size: the icon and the text are measured, scaled to the standard
heights and centred on the standard canvas over the standard background. Nothing is
redrawn. Needs Pillow (`pip install pillow`).
"""
import sys
from PIL import Image
BG = (3, 4, 9)
FLAT = 26            # pixels darker than this are the logo's own background: flattened to BG
DETECT = 40          # pixels brighter than this count as content when measuring

def load(path):
    im = Image.open(path).convert('RGB'); px = im.load(); w, h = im.size
    for y in range(h):
        for x in range(w):
            if max(px[x, y]) < FLAT: px[x, y] = BG
    return im
def is_bg(p): return max(p) < DETECT
def bbox(im, box=None):
    px = im.load(); w, h = im.size; x0, y0, x1, y1 = box or (0, 0, w, h)
    xs = [x for x in range(x0, x1) if any(not is_bg(px[x, y]) for y in range(y0, y1))]
    ys = [y for y in range(y0, y1) if any(not is_bg(px[x, y]) for x in range(x0, x1))]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
def runs(flags, offset):
    out = []; s = None
    for i, f in enumerate(list(flags) + [False]):
        if f and s is None: s = i
        if not f and s is not None: out.append((offset + s, offset + i)); s = None
    return out
def col_runs(im, box):
    px = im.load(); x0, y0, x1, y1 = box
    return runs([any(not is_bg(px[x, y]) for y in range(y0, y1)) for x in range(x0, x1)], x0)
def row_runs(im, box):
    px = im.load(); x0, y0, x1, y1 = box
    return [r for r in runs([any(not is_bg(px[x, y]) for x in range(x0, x1)) for y in range(y0, y1)], y0) if r[1] - r[0] > 8]
def scaled(part, height):
    s = height / part.size[1]
    return part.resize((max(1, round(part.size[0] * s)), height), Image.LANCZOS)

# --- horizontal: 1024x368, icon 232 tall, wordmark 88 tall, icon-text gap 52, all centred
W, H, ICON_H, WORD_H, GAP = 1024, 368, 232, 88, 52
def horizontal(path):
    im = load(path)
    bb = bbox(im); cr = col_runs(im, bb)
    gaps = [(cr[i + 1][0] - cr[i][1], i) for i in range(len(cr) - 1)]; _, i = max(gaps)
    icon_box = bbox(im, (bb[0], bb[1], cr[i][1], bb[3])); text_box = bbox(im, (cr[i + 1][0], bb[1], bb[2], bb[3]))
    icon = im.crop(icon_box); text = im.crop(text_box)
    word_h = row_runs(im, text_box)[0]; word_h = word_h[1] - word_h[0]
    icon = scaled(icon, ICON_H)
    text = text.resize((round(text.size[0] * WORD_H / word_h), round(text.size[1] * WORD_H / word_h)), Image.LANCZOS)
    total = icon.size[0] + GAP + text.size[0]
    out = Image.new('RGB', (W, H), BG)
    x = (W - total) // 2
    out.paste(icon, (x, (H - icon.size[1]) // 2))
    out.paste(text, (x + icon.size[0] + GAP, (H - text.size[1]) // 2))
    out.save(path, optimize=True)
    print('horizontal-logo.png: icon', icon.size, 'text', text.size, 'side margin', x)

# --- square: 1024x1024, icon 352 tall, wordmark 84 tall, gap 40, block centred
SQ, SICON_H, SWORD_H, SGAP = 1024, 352, 84, 40
def square(path):
    im = load(path)
    bb = bbox(im); rr = row_runs(im, bb)
    icon = im.crop(bbox(im, (bb[0], rr[0][0], bb[2], rr[0][1])))
    word = im.crop(bbox(im, (bb[0], rr[1][0], bb[2], rr[-1][1])))
    icon = scaled(icon, SICON_H); word = scaled(word, SWORD_H)
    block_h = icon.size[1] + SGAP + word.size[1]
    out = Image.new('RGB', (SQ, SQ), BG)
    y = (SQ - block_h) // 2
    out.paste(icon, ((SQ - icon.size[0]) // 2, y))
    out.paste(word, ((SQ - word.size[0]) // 2, y + icon.size[1] + SGAP))
    out.save(path, optimize=True)
    print('logo.png: icon', icon.size, 'wordmark', word.size)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    import os
    d = sys.argv[1]
    horizontal(os.path.join(d, 'horizontal-logo.png'))
    square(os.path.join(d, 'logo.png'))
