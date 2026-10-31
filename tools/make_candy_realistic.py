#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 8, the Candy Kingdom (M3 Task 4), from CC0 textures
(ambientCG, https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/candy.png
(world/universes/candy_blocks.gd TILES):

  data/blocks/pages/candy_albedo.png (RGBA) and candy_normal.png (RGB, OpenGL normals), 2048 px.

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px
border that continues it. Sources (all CC0): Snow004 (soft icing: frosting and cotton candy), Snow005 (whipped
cream), Snow003 (sugar crystals on the gumdrops), Plastic013A (the glossy candy: chocolate, candy cane,
lollipop, jam), Ground103 (fine crumb: cake sponge), Ground079L (gingerbread dough), Metal034 (golden candy).
Stripes, spirals, the chocolate bar's squares, air holes, sprinkles, icing lines, the glass and the lamp glow
are drawn here over those textures (the cotton candy's outline from the pixel tile).

Run from the project root:  python3 tools/make_candy_realistic.py     (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/candy_albedo.png"
OUT_NORMAL = "data/blocks/pages/candy_normal.png"
PIXEL_PAGE = "data/blocks/pages/candy.png"
SOURCES = {
    "icing": "Snow004", "cream": "Snow005", "sugar": "Snow003", "plastic": "Plastic013A",
    "crumb": "Ground103", "dough": "Ground079L", "gold": "Metal034",
}


class Page(base.Atlas):
    def save(self) -> None:
        # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
        base.save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                       OUT_ALBEDO, OUT_NORMAL)


def tint(color: np.ndarray, target: str, keep: float = 0.55) -> np.ndarray:
    """The texture's light and shade in the colour `target` (keep: how much of its own colour stays)."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(color * keep + base.hexcolor(target) * lum * (1 - keep), 0, 1)


def shade(color: np.ndarray, target: str, lo: float = 0.8, hi: float = 1.15) -> np.ndarray:
    """A flat colour lit by the texture's light and shade (glossy candy keeps its own colour)."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(base.hexcolor(target) * np.clip(lum, lo, hi), 0, 1)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20260925)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    ang = np.arctan2(yy - INNER / 2, xx - INNER / 2)
    pixel = np.asarray(Image.open(PIXEL_PAGE).convert("RGBA"), np.float32) / 255.0

    def pixel_tile(tx: int, ty: int, smooth: bool = False) -> np.ndarray:
        icon = pixel[ty * 16:(ty + 1) * 16, tx * 16:(tx + 1) * 16]
        img = Image.fromarray((icon * 255).astype(np.uint8), "RGBA")
        return np.asarray(img.resize((INNER, INNER), Image.BILINEAR if smooth else Image.NEAREST), np.float32) / 255.0

    page = Page()
    plastic_c, plastic_n = tex["plastic"]

    # frosting: soft pink icing on top; its side is sponge under a thick dripping icing band
    icing_c = tint(tex["icing"][0], "ff9ec8", 0.25)
    page.put((0, 0), icing_c, tex["icing"][1])
    holes = base.smooth_noise(1.6) > 0.8
    sponge_c = tint(tex["crumb"][0], "f2c46d", 0.25)
    sponge_c[holes] *= 0.72
    sponge_n = np.where(holes[..., None], base.normal_from_height(1 - holes.astype(np.float32), 3.0), tex["crumb"][1])
    page.put((2, 0), sponge_c, sponge_n)                                            # cake sponge
    drip = 4.2 * u + 1.2 * u * np.sin(xx / INNER * 2 * np.pi * 3 + 0.7) + 0.9 * u * np.sin(xx / INNER * 2 * np.pi * 7)
    band = (yy < drip[None, :] if drip.ndim == 1 else yy < drip)
    side_c = np.where(band[..., None], icing_c, sponge_c)
    side_c[np.abs(yy - drip) < 2.5] *= 0.85
    side_n = np.where(band[..., None], tex["icing"][1], sponge_n)
    page.put((1, 0), side_c, side_n, wrap_y=False)

    # chocolate: glossy squares with bevelled grooves (a bar), the plastic's shine
    gx = np.mod(xx, INNER / 2)
    gy = np.mod(yy, INNER / 2)
    edge = np.minimum(np.minimum(gx, INNER / 2 - gx), np.minimum(gy, INNER / 2 - gy))
    bevel = np.clip(edge / (1.2 * u), 0, 1)
    choco_c = shade(plastic_c, "6b3a1f", 0.85, 1.12) * (0.55 + 0.45 * bevel[..., None])
    choco_n = base.normal_from_height(bevel, 5.0)
    page.put((3, 0), choco_c, choco_n)

    # candy cane: red and white stripes going round (diagonal on the side), a spiral on its end
    stripe = np.mod(xx + yy, INNER / 2) < INNER * 0.19
    cane_c = np.where(stripe[..., None], shade(plastic_c, "e8283c"), shade(plastic_c, "fff4f4", 0.9, 1.05))
    page.put((4, 0), cane_c, plastic_n)
    spiral = np.mod(np.floor((ang / (2 * np.pi)) * 6 + r * 0.45 / u), 2) == 0
    cane_top = np.where(spiral[..., None], shade(plastic_c, "e8283c"), shade(plastic_c, "fff4f4", 0.9, 1.05))
    cane_top[r > INNER * 0.45] = shade(plastic_c, "b81d2f")[r > INNER * 0.45]
    page.put((5, 0), cane_top, plastic_n, wrap_x=False, wrap_y=False)

    # lollipop: a swirl of pink, white, yellow, white, blue, white
    bands = ["ff5ca8", "fff4f4", "ffd23f", "fff4f4", "5cc8ff", "fff4f4"]
    k = np.mod(np.floor((ang / (2 * np.pi)) * 6 + r * 0.55 / u), len(bands)).astype(int)
    lolly = np.zeros((INNER, INNER, 3), np.float32)
    for i, h in enumerate(bands):
        lolly[k == i] = shade(plastic_c, h, 0.88, 1.08)[k == i]
    page.put((6, 0), lolly, plastic_n, wrap_x=False, wrap_y=False)

    # gumdrops: jelly under a coat of sugar crystals
    sugar = tex["sugar"][0].mean(-1)
    sparkle = (sugar > np.quantile(sugar, 0.88))[..., None]
    for tile, h in [((7, 0), "46c24a"), ((0, 1), "ff4f6d")]:
        jelly = shade(tex["sugar"][0], h, 0.75, 1.2)
        page.put(tile, np.where(sparkle, np.clip(jelly * 0.5 + 0.55, 0, 1), jelly), tex["sugar"][1])

    page.put((1, 1), shade(tex["cream"][0], "fff4e2", 0.86, 1.06), tex["cream"][1])   # whipped cream
    # jam: glossy red with little seeds
    jam = shade(plastic_c, "d61f3c", 0.8, 1.2)
    seeds = base.smooth_noise(0.8) > 0.93
    jam[seeds] = base.hexcolor("f7d36b")
    page.put((2, 1), jam, plastic_n)

    # sugar glass: a pink sugary frame, two streaks and a few pink specks (the rest clear)
    frame = (xx < 12) | (yy < 12) | (xx > INNER - 13) | (yy > INNER - 13)
    streak = (np.abs((xx - yy) - 40) < 6) | (np.abs((xx - yy) + 30) < 3)
    specks = base.smooth_noise(1.2) > 0.88
    glass_alpha = (frame | streak | specks).astype(np.float32)
    glass_c = np.where(frame[..., None], base.hexcolor("ffb8dc"), base.hexcolor("fff0f8"))
    glass_c[specks & ~frame] = base.hexcolor("ffc6e0")
    page.put((3, 1), glass_c.astype(np.float32), base.flat_normal(), glass_alpha, wrap_x=False, wrap_y=False)

    # gingerbread: fine brown dough with a raised white icing zigzag at the top and bottom, two buttons
    dough = tint(tex["dough"][0], "b86b2e", 0.3)
    zig = u * (1.5 + np.abs(np.mod(xx / u, 4.0) - 2.0) * 0.8)
    icing_line = (np.abs(yy - zig) < 0.55 * u) | (np.abs((INNER - 1 - yy) - zig) < 0.55 * u)
    ginger_side = dough.copy()
    ginger_side[icing_line] = base.hexcolor("ffffff")
    for bx, by in [(7.5, 6.5), (7.5, 9.5)]:
        ginger_side[np.hypot(xx - bx * u, yy - by * u) < 0.8 * u] = base.hexcolor("ff4f6d")
    ginger_h = icing_line.astype(np.float32)
    page.put((4, 1), ginger_side, np.where(icing_line[..., None], base.normal_from_height(ginger_h, 4.0), tex["dough"][1]),
        wrap_y=False)
    ginger_top = dough.copy()
    ginger_top[(yy < 0.8 * u) | (yy > INNER - 0.8 * u)] = base.hexcolor("ffffff")
    page.put((5, 1), ginger_top, tex["dough"][1], wrap_y=False)

    # candy lamp: a warm glowing window in a pink sugar frame (unshaded: no normals needed)
    glow = 1 - np.clip(r / (INNER / 2), 0, 1)
    lamp_c = base.hexcolor("ffb347") + (base.hexcolor("fff3a0") - base.hexcolor("ffb347")) * glow[..., None]
    lamp_frame = (xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u)
    lamp_c[lamp_frame] = shade(plastic_c, "ff7ab8")[lamp_frame]
    page.put((6, 1), np.clip(lamp_c, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = shade(plastic_c, "ff7ab8")
    window = (np.abs(xx - INNER / 2) < 3 * u) & (np.abs(yy - INNER / 2) < 3 * u)
    lamp_top[window] = base.hexcolor("fff3a0")
    page.put((7, 1), lamp_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # cotton candy: the pixel tile's puffs, smoothed, in soft pink fluff (cutout)
    puffs = pixel_tile(0, 2, smooth=True)
    fluff = tint(tex["icing"][0], "ffc6e4", 0.2)
    page.put((0, 2), fluff, tex["icing"][1], (puffs[..., 3] > 0.5).astype(np.float32), wrap_x=False, wrap_y=False)

    # sprinkles: the frosting top covered in little rainbow sprinkles
    sprinkle_c = icing_c.copy()
    sprinkle_h = np.zeros((INNER, INNER), np.float32)
    colours = ["ff3b5c", "ffd23f", "3fb5ff", "5ee05e", "ffffff", "b57bff", "ff8a3d"]
    for i in range(70):
        cx, cy = rng.random() * INNER, rng.random() * INNER
        a = rng.random() * np.pi
        dx, dy = np.cos(a), np.sin(a)
        along = (xx - cx) * dx + (yy - cy) * dy
        across = -(xx - cx) * dy + (yy - cy) * dx
        m = (np.abs(along) < 0.7 * u) & (np.abs(across) < 0.22 * u)
        sprinkle_c[m] = base.hexcolor(colours[i % len(colours)])
        sprinkle_h[m] = 1.0
    page.put((1, 2), sprinkle_c, np.where(sprinkle_h[..., None] > 0, base.normal_from_height(sprinkle_h, 3.0), tex["icing"][1]))

    # golden candy: gold with a bright twist at each end
    gold_c = np.clip(tex["gold"][0] * 1.1, 0, 1)
    twist = ((xx < 2.2 * u) | (xx > INNER - 2.2 * u)) & (np.abs(yy - INNER / 2) < 3 * u)
    gold_c[twist] = np.clip(gold_c[twist] * 1.3, 0, 1)
    page.put((2, 2), gold_c, tex["gold"][1])

    # fake chocolate: the chocolate bar with a faint crack down it
    crack = np.zeros((INNER, INNER), bool)
    path = [(7, 3), (7, 4), (7, 5), (8, 6), (8, 7), (7, 8), (7, 9), (8, 10), (8, 11), (7, 12), (7, 13), (7, 14)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for t in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * t + 0.5) * u, (ay + (by - ay) * t + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.0
    fake_c = choco_c.copy()
    fake_c[crack] *= 0.55
    page.put((3, 2), fake_c, choco_n)
    page.save()
    print("CANDY realistic page saved:", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
