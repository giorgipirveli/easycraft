#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 2, Frostpeak (M3 Task 3), from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/frost.png
(world/universes/frost_blocks.gd TILES):

  data/blocks/pages/frost_albedo.png (RGBA) and frost_normal.png (RGB, OpenGL normals), 2048 px.

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px
border that continues it. Sources (all CC0): Snow004 (snow), Snow003 (packed snow), Ice002 (ice), Ice003
(blue ice), Ground103 (frozen dirt), Bark001 (pine bark), Wood095 (pine log end), Grass001 (pine needles),
Rock030 (the frozen ore's stone), Bricks084 (snow bricks). The ice crystals, the lantern's glow, frosted
glass and the fake floor's crack are drawn here, like the page 0 tool's glass.

Run from the project root:  python3 tools/make_frost_realistic.py     (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/frost_albedo.png"
OUT_NORMAL = "data/blocks/pages/frost_normal.png"
PIXEL_PAGE = "data/blocks/pages/frost.png"
SOURCES = {
    "snow": "Snow004", "packed": "Snow003", "ice": "Ice002", "blue": "Ice003", "dirt": "Ground103",
    "bark": "Bark001", "wood": "Wood095", "needles": "Grass001", "rock": "Rock030", "bricks": "Bricks084",
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


def soften(normal: np.ndarray, amount: float) -> np.ndarray:
    """A normal map made flatter (snow and ice are smooth)."""
    return base.flat_normal() * (1 - amount) + normal * amount


def main() -> None:
    tex = {k: base.fetch(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20260925)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    page = Page()

    snow_c = tint(tex["snow"][0], "f4f8fc", 0.5)
    snow_n = soften(tex["snow"][1], 0.6)
    page.put((0, 0), snow_c, snow_n)                                              # snow
    dirt_c = tint(tex["dirt"][0], "8a6446", 0.5)
    page.put((2, 0), dirt_c, tex["dirt"][1])                                      # frozen dirt
    # snowy grass: the dirt under a thick, uneven lip of snow
    lip = (4.5 + 1.2 * np.sin(np.arange(INNER) / INNER * 2 * np.pi * 3) + 1.6 * base.smooth_noise(2.0)[0]) * u
    under = yy < lip[None, :]
    side_c = np.where(under[..., None], snow_c, dirt_c)
    side_n = np.where(under[..., None], snow_n, tex["dirt"][1])
    page.put((1, 0), side_c, side_n, wrap_y=False)
    packed_c = tint(tex["packed"][0], "e2ebf4", 0.5)
    page.put((3, 0), packed_c, soften(tex["packed"][1], 0.8))                     # packed snow

    # ice: the cracked ice texture in pale blue, glassy (a soft normal); blue ice deeper and darker
    ice_c = tint(tex["ice"][0], "a9d4f2", 0.2)
    page.put((4, 0), np.clip(ice_c * 1.05, 0, 1), soften(tex["ice"][1], 0.5))
    blue_c = tint(tex["blue"][0], "4f93e0", 0.3)
    page.put((5, 0), blue_c, soften(tex["blue"][1], 0.5))

    # pine: dark furrowed bark; the log's end shows the wood's rings with a bark rim
    page.put((6, 0), tint(tex["bark"][0], "5b4030", 0.45), tex["bark"][1])
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    rings = 0.5 + 0.5 * np.sin(r * 0.5 + 3.0 * base.smooth_noise(10))
    end_c = tint(tex["wood"][0], "d2a676", 0.5) * (0.8 + 0.25 * rings[..., None])
    rim = (r > INNER * 0.44)[..., None]
    page.put((7, 0), np.where(rim, tint(tex["bark"][0], "5b4030", 0.45), end_c),
        np.where(rim, tex["bark"][1], base.normal_from_height(rings, 1.5)), wrap_x=False, wrap_y=False)

    # pine needles: the grass texture as dense dark-green needles with gaps (cutout); the top has snow on it
    needles = ((np.mod(xx * 3 + yy * 5, INNER / 3) < INNER / 4.2) | (base.smooth_noise(1.5) > 0.35)).astype(np.float32)
    holes = (base.smooth_noise(2.2) > 0.3).astype(np.float32)
    needle_c = tint(tex["needles"][0], "2f6b45", 0.45)
    page.put((0, 1), needle_c, tex["needles"][1], needles * holes)
    snowy = base.smooth_noise(3.0) > 0.45
    top_c = np.where(snowy[..., None], snow_c, needle_c)
    page.put((1, 1), top_c, np.where(snowy[..., None], snow_n, tex["needles"][1]), np.clip(needles * holes + snowy, 0, 1))

    # frozen ore: grey rock with glittering ice crystals pressed in
    rock_c = tint(tex["rock"][0], "8d949c", 0.5)
    crystals = np.zeros((INNER, INNER), bool)
    for _ in range(9):
        cx, cy, s = rng.random() * INNER * 0.8 + INNER * 0.1, rng.random() * INNER * 0.8 + INNER * 0.1, rng.random() * 8 + 7
        crystals |= (np.abs(xx - cx) + np.abs(yy - cy)) < s
    ore_c = rock_c.copy()
    shine = 0.75 + 0.25 * np.sin((xx + yy) * 0.3)[..., None]
    ore_c[crystals] = (base.hexcolor("8fe9ff") * shine)[crystals]
    ore_h = np.where(crystals, 1.0, 0.4).astype(np.float32)
    page.put((2, 1), np.clip(ore_c, 0, 1), np.where(crystals[..., None], base.normal_from_height(ore_h, 3.0), tex["rock"][1]))

    # snow bricks: the brick relief in snow white, blue-grey joints
    bricks_c = tint(tex["bricks"][0], "f0f5fa", 0.25)
    page.put((3, 1), np.clip(bricks_c * 1.08, 0, 1), soften(tex["bricks"][1], 0.8))

    # ice lantern: a cold glow in a packed-snow frame (unshaded: no normals needed)
    glow = 1 - np.clip(np.hypot(xx - INNER / 2, yy - INNER / 2) / (INNER / 2), 0, 1)
    lamp_c = base.hexcolor("7fd8ff") + (base.hexcolor("f0fcff") - base.hexcolor("7fd8ff")) * glow[..., None]
    frame = (xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u)
    lamp_c[frame] = packed_c[frame] * 0.85
    page.put((4, 1), np.clip(lamp_c, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = packed_c * 0.85
    window = (np.abs(xx - INNER / 2) < 3 * u) & (np.abs(yy - INNER / 2) < 3 * u)
    lamp_top[window] = base.hexcolor("c8f4ff")
    page.put((5, 1), lamp_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # frosted glass: a white frame and a frosty haze towards the corners (the rest clear)
    edge = np.minimum(np.minimum(xx, INNER - 1 - xx), np.minimum(yy, INNER - 1 - yy))
    haze = base.smooth_noise(1.0) * 0.5 + 0.5
    frost = (edge < 12) | ((edge < 3.5 * u) & (haze > edge / (3.5 * u)))
    streak = np.abs((xx - yy) + 20) < 3
    glass_alpha = (frost | streak).astype(np.float32)
    glass_c = np.where(frost[..., None], base.hexcolor("e8f2fa"), base.hexcolor("ffffff")).astype(np.float32)
    page.put((6, 1), glass_c, base.flat_normal(), glass_alpha, wrap_x=False, wrap_y=False)

    # fake packed snow (a hidden way down): packed snow with a faint crack
    crack = np.zeros((INNER, INNER), bool)
    path = [(5, 3), (5, 4), (5, 5), (6, 6), (6, 7), (6, 8), (5, 9), (5, 10), (6, 11), (6, 12), (5, 13)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for t in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * t + 0.5) * u, (ay + (by - ay) * t + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.2
    for t in np.linspace(0.0, 1.0, 60):
        crack |= np.hypot(xx - (5.5 + 4 * t) * u, yy - 8.5 * u) < 2.0
    fake_c = packed_c.copy()
    fake_c[crack] *= 0.78
    page.put((7, 1), fake_c, soften(tex["packed"][1], 0.8))
    page.save()
    print("FROST realistic page saved:", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
