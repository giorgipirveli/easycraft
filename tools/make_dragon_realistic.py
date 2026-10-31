#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 11, the Dragon Realm (owner feedback #39), from CC0 textures
(ambientCG, https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/dragon.png
(world/universes/dragon_blocks.gd TILES):

  data/blocks/pages/dragon_albedo.png (RGBA) and dragon_normal.png (RGB, OpenGL normals), 2048 px.

Owner #43 (our own look, spec §3c): a sunrise over a sea of clouds, never black and purple: coral moss,
pearl-white and apricot floatstone, golden crystal spires, a coral starglass frame, blush-white bricks (only the
tints changed: every other tile is byte-identical).

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px
border that continues it. Sources (all CC0): Grass005 (sky grass: moss, tinted violet-blue), Rock030 (floatstone,
tinted lavender), Rock035 (deep floatstone), Ice002 (the amethyst of crystal spires), Bark001 (mushroom stems),
Wood095 (a stem's cut rings), Plastic013A (the glowing caps), Leather026 (dragon and ember scales, under a scale
pattern), Snow004 (clouds), Bark014 (nest twigs), Bricks084 (floatstone bricks), Metal034 (dragon gold, the moon
lamp's silver). The scales, facets, spots, gills, stars, the moon, the weave, the cracks and every glow are drawn
here over those textures (the cloud's outline from the pixel tile).

Run from the project root:  python3 tools/make_dragon_realistic.py     (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/dragon_albedo.png"
OUT_NORMAL = "data/blocks/pages/dragon_normal.png"
PIXEL_PAGE = "data/blocks/pages/dragon.png"
SOURCES = {
    "moss": "Grass005", "rock": "Rock030", "deep": "Rock035", "ice": "Ice002", "bark": "Bark001",
    "rings": "Wood095", "plastic": "Plastic013A", "leather": "Leather026", "snow": "Snow004", "twig": "Bark014",
    "brick": "Bricks084", "metal": "Metal034",
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
    """A flat colour lit by the texture's light and shade."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(base.hexcolor(target) * np.clip(lum, lo, hi), 0, 1)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20260939)
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

    # sky grass: sunrise coral moss with a few sparkles; its side is floatstone under a hanging moss band
    lum = tex["moss"][0].mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    clumps = (0.8 + 0.35 * base.smooth_noise(5.0))[..., None]
    moss_c = np.clip(base.hexcolor("f28b82") * (0.35 + 0.65 * lum ** 1.8) * clumps, 0, 1)
    moss_top = moss_c.copy()
    for _ in range(14):                      # a few twinkling sparkles
        cx, cy = rng.random() * INNER, rng.random() * INNER
        moss_top[np.hypot(xx - cx, yy - cy) < 2.2] = base.hexcolor("eef8ff")
    page.put((0, 0), moss_top, tex["moss"][1])
    rock_c = tint(tex["rock"][0], "f3e2dc", 0.25)
    page.put((2, 0), rock_c, tex["rock"][1])                                          # floatstone
    hang = 3.6 * u + 1.3 * u * np.sin(xx / INNER * 2 * np.pi * 5 + 0.4) + 0.8 * u * np.sin(xx / INNER * 2 * np.pi * 11)
    band = yy < hang
    side_c = np.where(band[..., None], moss_c, rock_c)
    side_c[np.abs(yy - hang) < 2.5] *= 0.8
    side_n = np.where(band[..., None], tex["moss"][1], tex["rock"][1])
    page.put((1, 0), side_c, side_n, wrap_y=False)

    # deep floatstone: apricot rock with streaks
    streak = 0.5 + 0.5 * np.sin(yy / u * 0.9 + np.sin(xx / u * 0.5) * 1.5)
    deep_c = tint(tex["deep"][0], "e3a37f", 0.25) * (0.85 + 0.15 * streak[..., None])
    page.put((3, 0), deep_c, tex["deep"][1])

    # crystal spire: glowing golden crystal in long facets (unshaded: the colour is the look)
    facet = np.mod(xx / u, 5.0)
    ice = shade(tex["ice"][0], "ffc94d", 0.97, 1.2)
    spire = ice * (0.82 + 0.3 * (facet < 0.8)[..., None]) * (1.0 - 0.18 * (facet > 4.2)[..., None])
    page.put((4, 0), np.clip(spire, 0, 1), base.flat_normal(), wrap_y=True)
    ring = np.maximum(np.abs(xx - INNER / 2), np.abs(yy - INNER / 2)) / u
    spire_top = ice * (0.8 + 0.25 * (np.mod(ring, 3.0) < 0.8)[..., None])
    star = ((np.abs(xx - INNER / 2) < 0.5 * u) | (np.abs(yy - INNER / 2) < 0.5 * u)) & (r < 3 * u)
    spire_top[star] = base.hexcolor("fff3c4")
    spire_top[ring > 7.2] *= 0.75
    page.put((5, 0), np.clip(spire_top, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # mushroom stem: a pale fibrous stalk; its top: soft rings
    page.put((6, 0), tint(tex["bark"][0], "eee4cf", 0.15), tex["bark"][1])
    rings = tint(tex["rings"][0], "e4d8bc", 0.2) * (0.9 + 0.1 * np.cos(r / u * 2.1))[..., None]
    rings[r > INNER * 0.47] *= 0.85
    page.put((7, 0), rings, tex["rings"][1], wrap_x=False, wrap_y=False)

    # glow cap: a glowing turquoise cap with pale spots, a darker lip on its side, gills underneath
    cap = shade(tex["plastic"][0], "35cfc0", 0.9, 1.1)
    spots = np.zeros((INNER, INNER), bool)
    for sx, sy, sr in [(4, 4, 2.2), (11, 5, 1.8), (7, 11, 2.4), (13, 12, 1.5), (2, 12, 1.3)]:
        spots |= np.hypot(xx - sx * u, yy - sy * u) < sr * u
    cap_top = cap.copy()
    cap_top[spots] = base.hexcolor("d4fff8")
    page.put((0, 1), cap_top, base.flat_normal(), wrap_x=False, wrap_y=False)
    cap_side = cap.copy()
    cap_side[yy > 12 * u] = shade(tex["plastic"][0], "1f9c93")[yy > 12 * u]
    for sx, sy, sr in [(3.5, 4.5, 1.2), (10.5, 2.5, 1.1), (13, 7, 0.8), (7.5, 8, 1.0)]:
        m = np.hypot(xx - sx * u, yy - sy * u) < sr * u
        cap_side[m] = base.hexcolor("d4fff8")
    page.put((1, 1), cap_side, base.flat_normal(), wrap_y=False)
    gill = np.mod(np.floor(ang / (2 * np.pi) * 24.0), 2) == 0
    gills = np.where(gill[..., None], base.hexcolor("1f9c93"), base.hexcolor("2ab6aa"))
    gills = gills * np.clip(tex["plastic"][0].mean(-1, keepdims=True) * 1.6, 0.85, 1.1)
    gills[r < 2 * u] = base.hexcolor("eee4cf")
    page.put((2, 1), np.clip(gills, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # scales: overlapping rows of round scales (each row half a scale over), leather's grain in them
    row = np.floor(yy / (4 * u))
    sx = np.mod(xx + (row % 2) * 4 * u, 8 * u) / (8 * u) - 0.5         # -0.5..0.5 across a scale
    ly = np.mod(yy, 4 * u) / (4 * u)                                   # 0..1 down a row
    arc = 0.25 + 0.75 * np.sqrt(np.clip(1 - (2 * sx) ** 2, 0, 1))      # where each scale's edge runs
    inside = ly < arc
    edge = np.abs(ly - arc) < 0.12
    height = np.where(inside, 1.0 - (ly / np.maximum(arc, 1e-3)) * 0.6, 0.25)
    scale_n = base.normal_from_height(height.astype(np.float32), 6.0)
    for tile, hue, dark, light in [((3, 1), "1fa36a", "0f6b44", "63dba0"), ((4, 1), "e2552a", "a1301a", "ffa45c")]:
        c = shade(tex["leather"][0], hue, 0.85, 1.15)
        c[~inside] = shade(tex["leather"][0], dark, 0.85, 1.1)[~inside]
        c[edge] = base.hexcolor(dark)
        c[inside & (ly < 0.12) & (np.abs(sx) < 0.25)] = base.hexcolor(light)
        page.put(tile, c, scale_n)

    # starglass: a coral frame round clear glass with little stars (the rest clear)
    frame = (xx < 12) | (yy < 12) | (xx > INNER - 13) | (yy > INNER - 13)
    stars = np.zeros((INNER, INNER), bool)
    for _ in range(9):
        cx, cy = 20 + rng.random() * (INNER - 40), 20 + rng.random() * (INNER - 40)
        s = 2.5 + rng.random() * 3.5
        stars |= ((np.abs(xx - cx) < s) & (np.abs(yy - cy) < 1.2)) | ((np.abs(yy - cy) < s) & (np.abs(xx - cx) < 1.2))
    streak_g = np.abs((xx - yy) - 60) < 5
    glass_alpha = (frame | stars | streak_g).astype(np.float32)
    glass_c = np.where(frame[..., None], base.hexcolor("e89a7e"), base.hexcolor("fff4c2"))
    glass_c[streak_g & ~frame] = base.hexcolor("f4f0ff")
    page.put((5, 1), glass_c.astype(np.float32), base.flat_normal(), glass_alpha, wrap_x=False, wrap_y=False)

    # moon lamp: a silver frame round a pale moonlight with a crescent moon (unshaded)
    silver = shade(tex["metal"][0], "b9b4d6", 0.85, 1.1)
    glow = 1 - np.clip(r / (INNER / 2), 0, 1)
    lamp = base.hexcolor("9fb6ff") + (base.hexcolor("dfeaff") - base.hexcolor("9fb6ff")) * glow[..., None]
    lamp_frame = (xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u)
    lamp[lamp_frame] = silver[lamp_frame]
    crescent = (r < 3.6 * u) & (np.hypot(xx - 9.0 * u, yy - 6.5 * u) > 3.0 * u)
    lamp[crescent] = base.hexcolor("fffbe6")
    page.put((6, 1), np.clip(lamp, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = silver.copy()
    window = (np.abs(xx - INNER / 2) < 4 * u) & (np.abs(yy - INNER / 2) < 4 * u)
    lamp_top[window] = (base.hexcolor("9fb6ff") + (base.hexcolor("dfeaff") - base.hexcolor("9fb6ff")) * glow[..., None])[window]
    page.put((7, 1), np.clip(lamp_top, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # cloud: the pixel tile's puffs, smoothed, in soft white snow (cutout)
    puffs = pixel_tile(0, 2, smooth=True)
    fluff = tint(tex["snow"][0], "f4f1ff", 0.35)
    page.put((0, 2), fluff, tex["snow"][1], (puffs[..., 3] > 0.5).astype(np.float32), wrap_x=False, wrap_y=False)

    # nest: woven golden twigs, round on top (a hollow in the middle), in bands on its side
    twig_c = tint(tex["twig"][0], "c39646", 0.3)
    weave = np.mod(np.floor(ang / (2 * np.pi) * 16.0 + r / u * 0.8), 3)
    nest_top = twig_c * (0.8 + 0.15 * weave[..., None])
    nest_top[r < 3.5 * u] *= 0.55
    page.put((1, 2), np.clip(nest_top, 0, 1), tex["twig"][1], wrap_x=False, wrap_y=False)
    bands = np.mod(np.floor(yy / u) + np.floor(xx / (4 * u)) % 2, 3)
    page.put((2, 2), np.clip(twig_c * (0.8 + 0.15 * bands[..., None]), 0, 1), tex["twig"][1])

    # floatstone brick: blush-white bricks
    page.put((3, 2), tint(tex["brick"][0], "e8cfc4", 0.2), tex["brick"][1])

    # dragon gold: shining gold with the scale pattern pressed in (glows)
    gold = np.clip(tex["metal"][0] * 1.15, 0, 1)
    gold = tint(gold, "f5c542", 0.35)
    gold[edge] *= 0.7
    page.put((4, 2), np.clip(gold, 0, 1), scale_n)

    # fake floatstone: floatstone with a faint crack down it
    crack = np.zeros((INNER, INNER), bool)
    path = [(8, 2), (8, 3), (7, 4), (7, 5), (8, 6), (8, 7), (9, 8), (8, 9), (8, 10), (7, 11), (7, 12), (8, 13), (8, 14)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for t in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * t + 0.5) * u, (ay + (by - ay) * t + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.0
    fake_c = rock_c.copy()
    fake_c[crack] *= 0.6
    page.put((5, 2), fake_c, tex["rock"][1])
    page.save()
    print("DRAGON realistic page saved:", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
