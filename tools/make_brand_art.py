#!/usr/bin/env python3
"""EasyCraft's own brand pictures (owner feedback #43, spec §3c): the buddy mark and the wordmark, our own work.

  icon.png                                 the launcher icon, 512 px, full bleed (the launcher rounds it): the
                                           orange block buddy with googly eyes, waving the wand's star, on teal
  docs/store/graphics/next/icon-512.png    the same for the store page (the lead uploads it)
  assets/brand/splash.png                  the boot splash (project.godot application/boot_splash/*): the buddy
                                           and the wordmark on transparency, drawn at its own size on our teal
  assets/brand/wordmark.png                "EasyCraft" in bubble-block letters for the menu's title (twice the
                                           size it is shown at)

The letters are drawn from a small grid font made here (rounded blocks that melt together), not from a font
file. Everything is drawn 4x larger and scaled down for smooth edges. No randomness: running it again gives
the same files.
Run from the project root:  python3 tools/make_brand_art.py   (needs Pillow and numpy)
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4   # supersampling
TEAL = (19, 158, 155)        # #139e9b: the brand's teal (the splash colour, UiKit.BRAND_TEAL)
TEAL_DEEP = (10, 104, 112)
ORANGE = (255, 138, 52)      # #ff8a34: the buddy
ORANGE_LIGHT = (255, 186, 110)
ORANGE_DARK = (222, 98, 30)
INK = (30, 42, 74)           # #1e2a4a: outlines and pupils
WHITE = (255, 255, 255)
SUN = (255, 216, 74)         # #ffd84a: the star and "Easy"
BLUSH = (255, 128, 140)
MOUTH = (150, 40, 52)
TONGUE = (255, 120, 130)


def _canvas(w: int, h: int, bg=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (w * SS, h * SS), bg)


def _down(img: Image.Image, w: int, h: int) -> Image.Image:
    return img.resize((w, h), Image.LANCZOS)


def _star(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill, outline=None, width=0, points=5,
          inner=0.48, turn=-90.0) -> None:
    pts = []
    for i in range(points * 2):
        a = np.radians(turn + i * 180.0 / points)
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
    d.polygon(pts, fill=fill, outline=outline, width=width)


def _sparkle(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill) -> None:
    _star(d, cx, cy, r, fill, points=4, inner=0.28, turn=-90.0)


def buddy(size: int, ss: int = SS) -> Image.Image:
    """The buddy mark on transparency, `size` px square (before scaling down): a round-cornered orange block
    with a lighter top, googly eyes looking up at the star, a happy mouth, pink cheeks, little feet, and one
    arm up with the wand; the wand's star and two sparkles."""
    s = size * ss
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = s / 100.0   # the mark is drawn on a 100 x 100 grid
    ow = int(3.2 * u)   # outline width

    def rr(x0, y0, x1, y1, r, fill, outline=INK, width=ow):
        d.rounded_rectangle([x0 * u, y0 * u, x1 * u, y1 * u], radius=r * u, fill=fill, outline=outline, width=width)

    # feet and the lowered hand behind the body
    rr(22, 84, 36, 94, 4, ORANGE_DARK)
    rr(50, 84, 64, 94, 4, ORANGE_DARK)
    rr(3, 56, 17, 70, 5, ORANGE)
    # the body: a soft block, lighter on top, a little darker at the bottom
    rr(10, 26, 74, 88, 14, ORANGE)
    d.rounded_rectangle([14 * u, 30 * u, 70 * u, 44 * u], radius=10 * u, fill=ORANGE_LIGHT)
    d.rounded_rectangle([14 * u, 74 * u, 70 * u, 84.5 * u], radius=9 * u, fill=ORANGE_DARK)
    d.rounded_rectangle([10 * u, 26 * u, 74 * u, 88 * u], radius=14 * u, outline=INK, width=ow)
    # the wand, held up in the other hand
    d.line([(81 * u, 44 * u), (88 * u, 19 * u)], fill=INK, width=int(7.0 * u))
    d.line([(81 * u, 44 * u), (88 * u, 19 * u)], fill=(150, 96, 56), width=int(3.4 * u))
    rr(72, 38, 86, 52, 5, ORANGE)
    # googly eyes looking up and right (towards the star)
    for ex in (29, 54):
        d.ellipse([(ex - 10) * u, 41 * u, (ex + 10) * u, 61 * u], fill=WHITE, outline=INK, width=ow)
        d.ellipse([(ex - 2.5) * u, 44 * u, (ex + 7.5) * u, 54 * u], fill=INK)
        d.ellipse([(ex + 1.5) * u, 45.5 * u, (ex + 4.5) * u, 48.5 * u], fill=WHITE)
    # cheeks and a happy open mouth
    for cx in (21, 63):
        d.ellipse([(cx - 4.5) * u, 63 * u, (cx + 4.5) * u, 68 * u], fill=BLUSH)
    d.chord([32 * u, 60 * u, 52 * u, 78 * u], 0, 180, fill=MOUTH, outline=INK, width=int(2.6 * u))
    d.chord([36.5 * u, 69 * u, 47.5 * u, 77 * u], 180, 360, fill=TONGUE)
    # the wand's star and two sparkles
    _star(d, 89 * u, 14 * u, 11.5 * u, SUN, outline=INK, width=int(1.6 * u))
    _sparkle(d, 71 * u, 8 * u, 4.5 * u, WHITE)
    _sparkle(d, 97 * u, 31 * u, 3.2 * u, WHITE)
    return img


# --- The wordmark: bubble-block letters from a small grid font (our own) -----------------------------------
# Each glyph is rows of cells, top to bottom; row 0 is the top of a capital, row 6 the baseline, rows 7-8 hang
# below it (y). Cells that touch melt into one rounded shape.
GLYPHS = {
    "E": ["####", "#...", "#...", "###.", "#...", "#...", "####"],
    "a": ["....", "....", "####", "...#", "####", "#..#", "####"],
    "s": ["....", "....", "####", "#...", "####", "...#", "####"],
    "y": ["....", "....", "#..#", "#..#", "#..#", "####", "...#", "...#", "####"],
    "C": ["####", "#...", "#...", "#...", "#...", "#...", "####"],
    "r": ["...", "...", "###", "#..", "#..", "#..", "#.."],
    "f": [".##", ".#.", "###", ".#.", ".#.", ".#.", ".#."],
    "t": ["...", ".#.", "###", ".#.", ".#.", ".#.", ".##"],
}


def _glyph_mask(glyph: list[str], cell: int, grow: float) -> Image.Image:
    """A glyph's cells as one shape: each cell a rounded block `grow` cells fatter on every side, touching
    cells joined by a bar, so strokes are fat and round and the letter reads as one piece."""
    rows, cols = len(glyph), max(len(r) for r in glyph)
    pad = int(cell * grow)
    m = Image.new("L", (cols * cell + 2 * pad, rows * cell + 2 * pad), 0)
    d = ImageDraw.Draw(m)
    on = lambda x, y: 0 <= y < rows and 0 <= x < len(glyph[y]) and glyph[y][x] == "#"
    rad = cell * (0.5 + grow)
    for y in range(rows):
        for x in range(cols):
            if not on(x, y):
                continue
            x0, y0 = x * cell, y * cell
            d.rounded_rectangle([x0, y0, x0 + cell + 2 * pad, y0 + cell + 2 * pad], radius=rad, fill=255)
            if on(x + 1, y):
                d.rectangle([x0 + cell / 2 + pad, y0, x0 + cell * 1.5 + pad, y0 + cell + 2 * pad], fill=255)
            if on(x, y + 1):
                d.rectangle([x0, y0 + cell / 2 + pad, x0 + cell + 2 * pad, y0 + cell * 1.5 + pad], fill=255)
    return m


def wordmark(cell: int) -> Image.Image:
    """'EasyCraft' in bubble-block letters: "Easy" sun yellow, "Craft" orange, on one ink backing (a sticker),
    with a white shine; `cell` is one grid cell in final pixels."""
    c = cell * SS
    grow = 0.18
    gap = int(c * 0.45)
    outline = int(c * 0.34)
    letters = "EasyCraft"
    masks = [_glyph_mask(GLYPHS[ch], c, grow) for ch in letters]
    xs = []
    x = outline
    for i, m in enumerate(masks):
        if i == 4:
            x += int(c * 0.9)   # the space between the two words
        xs.append(x)
        x += m.width + gap
    width = x - gap + outline
    height = max(m.height for m in masks) + 2 * outline
    fills = Image.new("L", (width, height), 0)
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for m, x0 in zip(masks, xs):
        fills.paste(m, (x0, outline), m)
    backing = fills.filter(ImageFilter.MaxFilter(_odd(outline * 2)))
    out.paste(Image.new("RGBA", out.size, INK + (255,)), (0, 0), backing)
    for i, (m, x0) in enumerate(zip(masks, xs)):
        layer = Image.new("L", out.size, 0)
        layer.paste(m, (x0, outline), m)
        out.paste(Image.new("RGBA", out.size, (SUN if i < 4 else ORANGE) + (255,)), (0, 0), layer)
        shine = ImageChopsLite.shift_and_subtract(layer, int(c * 0.26)).point(lambda v: v * 0.55)
        white = Image.new("RGBA", out.size, (255, 255, 255, 0))
        white.putalpha(shine)
        out.alpha_composite(white)
    return out


def _odd(n: int) -> int:
    return n + 1 if n % 2 == 0 else n


class ImageChopsLite:
    @staticmethod
    def shift_and_subtract(mask: Image.Image, by: int) -> Image.Image:
        """The band of `mask` that is not covered by itself moved down by `by`: its top edge (a shine), thinned."""
        a = np.asarray(mask, np.int16)
        moved = np.zeros_like(a)
        moved[by:] = a[:-by]
        band = np.clip(a - moved, 0, 255).astype(np.uint8)
        return Image.fromarray(band).filter(ImageFilter.MinFilter(_odd(max(3, by // 2))))


def icon(size: int = 512, mark: float = 0.64) -> Image.Image:
    """The launcher and store icon: the buddy on a teal glow, full bleed. The launcher's copy keeps the buddy
    inside the middle two thirds (an adaptive icon's safe zone: launchers crop the rest); the store's is bigger."""
    s = size * SS
    yy, xx = np.mgrid[0:s, 0:s].astype(np.float32) / s
    glow = np.clip(1.0 - np.hypot(xx - 0.5, yy - 0.42) * 1.35, 0, 1)[..., None]
    base = np.array(TEAL_DEEP, np.float32) * (1 - glow) + np.array(TEAL, np.float32) * glow
    base = np.clip(base * (1.0 + 0.18 * glow), 0, 255)
    bg = Image.fromarray(np.dstack([base, np.full((s, s, 1), 255.0)]).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(bg)
    for cx, cy, r in ((0.16, 0.2, 0.035), (0.84, 0.78, 0.028), (0.2, 0.8, 0.022)):   # soft sparkles
        _sparkle(d, cx * s, cy * s, r * s, (255, 255, 255, 170))
    m = buddy(int(size * mark))
    bg.alpha_composite(m, (int(s * (0.5 - mark * 0.47)), int(s * (0.5 - mark * 0.48))))
    return _down(bg, size, size)


def splash() -> Image.Image:
    """The boot splash: the buddy on the left, the wordmark beside it, on transparency (the splash colour shows)."""
    w, h = 720, 300
    img = _canvas(w, h)
    img.alpha_composite(buddy(240), (int(10 * SS), int(30 * SS)))
    wm = wordmark(12)
    scale = min((w - 290) * SS / wm.width, (h - 60) * SS / wm.height)
    wm = wm.resize((int(wm.width * scale), int(wm.height * scale)), Image.LANCZOS)
    img.alpha_composite(wm, (int(265 * SS), int((h * SS - wm.height) / 2)))
    return _down(img, w, h)


def main() -> None:
    os.makedirs("assets/brand", exist_ok=True)
    os.makedirs("docs/store/graphics/next", exist_ok=True)
    icon(512).convert("RGB").save("icon.png", optimize=True)
    icon(512, 0.8).convert("RGB").save("docs/store/graphics/next/icon-512.png", optimize=True)
    sp = splash()
    sp.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(
        "assets/brand/splash.png", optimize=True)
    wm = wordmark(24)   # twice the menu's size (492 x 120 in the 1280 x 720 design space): sharp on phones
    wm = _down(wm, wm.width // SS, wm.height // SS)
    wm.quantize(colors=96, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(
        "assets/brand/wordmark.png", optimize=True)
    for path in ("icon.png", "docs/store/graphics/next/icon-512.png", "assets/brand/splash.png",
                 "assets/brand/wordmark.png"):
        im = Image.open(path)
        print("BRAND", path, im.size, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main()
