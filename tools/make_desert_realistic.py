#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 1, the Sandstorm Desert (M3 Task 2), from CC0 textures
(ambientCG, https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/desert.png
(world/universes/desert_blocks.gd TILES):

  data/blocks/pages/desert_albedo.png (RGBA) and desert_normal.png (RGB, OpenGL normals), 2048 px.

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px
border that continues it. Sources (all CC0): Ground096B (layered desert ground: sandstone sides),
Ground093A (desert sand: sandstone tops), Bricks084 (sandstone bricks), Tiles144 (sandstone tiles), Ground097
(desert ground: red sand), Rock029 (red desert cliff: red sandstone), Bark014 and Wood095 (palm), Grass001
(palm fronds), Metal034 (gold), Ground079L (page 0's sand, for the sand pit's lid). Cactus, glass, the dry
bush and the lamp glow are drawn here (the dry bush from the pixel tile), like the page 0 tool's glass.

Run from the project root:  python3 tools/make_desert_realistic.py     (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/desert_albedo.png"
OUT_NORMAL = "data/blocks/pages/desert_normal.png"
PIXEL_PAGE = "data/blocks/pages/desert.png"
SOURCES = {
    "layers": "Ground096B", "dune": "Ground093A", "bricks": "Bricks084", "tiles": "Tiles144",
    "red": "Ground097", "cliff": "Rock029", "bark": "Bark014", "wood": "Wood095", "fronds": "Grass001",
    "gold": "Metal034", "sand": "Ground079L",
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


def main() -> None:
    tex = {k: base.fetch(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20260924)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    pixel = np.asarray(Image.open(PIXEL_PAGE).convert("RGBA"), np.float32) / 255.0

    def pixel_tile(tx: int, ty: int, smooth: bool = False) -> np.ndarray:
        icon = pixel[ty * 16:(ty + 1) * 16, tx * 16:(tx + 1) * 16]
        img = Image.fromarray((icon * 255).astype(np.uint8), "RGBA")
        return np.asarray(img.resize((INNER, INNER), Image.BILINEAR if smooth else Image.NEAREST), np.float32) / 255.0

    page = Page()
    sand_top = tint(tex["dune"][0], "ecd39a")
    side_c = tint(tex["layers"][0], "e2c27c")
    page.put((0, 0), sand_top, tex["dune"][1])                                   # sandstone top
    page.put((1, 0), side_c, tex["layers"][1])                                   # sandstone side (layers)
    page.put((2, 0), side_c * 0.85, tex["layers"][1])                            # sandstone bottom
    bricks_c = tint(tex["bricks"][0], "e0c07a", 0.7)
    page.put((3, 0), bricks_c, tex["bricks"][1])                                 # cut sandstone

    # carved sandstone: the tiles with the pixel tile's carving pressed in
    carving = pixel_tile(4, 0, smooth=True)[..., :3].mean(-1)
    groove = np.clip((carving.mean() - carving) * 4.0, 0, 1)
    carved_c = tint(tex["tiles"][0], "e3c37e", 0.6) * (1 - 0.45 * groove[..., None])
    page.put((4, 0), carved_c, base.normal_from_height(1 - groove, 4.0))
    top_carving = pixel_tile(6, 2, smooth=True)[..., :3].mean(-1)
    top_groove = np.clip((top_carving.mean() - top_carving) * 4.0, 0, 1)
    page.put((6, 2), tint(tex["tiles"][0], "ecd39a", 0.6) * (1 - 0.4 * top_groove[..., None]),
        base.normal_from_height(1 - top_groove, 4.0))

    page.put((5, 0), tint(tex["red"][0], "d9793e", 0.4), tex["red"][1])          # red sand
    # red sandstone: the red cliff in horizontal bands (a mesa's stripes); its top is the cliff, flatter
    bands = np.array([1.0, 1.18, 0.86, 1.08])[(yy // (INNER / 4)).astype(int) % 4]
    cliff_c = tint(tex["cliff"][0], "b8552c", 0.6)
    page.put((6, 0), np.clip(cliff_c * bands[..., None], 0, 1), tex["cliff"][1], wrap_y=False)
    page.put((7, 0), np.clip(cliff_c * 1.1, 0, 1), tex["cliff"][1])

    # cactus: green with raised ribs and pale spines
    ribs = 0.5 + 0.5 * np.cos((xx / INNER) * 4 * 2 * np.pi)
    grain = base.smooth_noise(2.0)
    cactus = base.hexcolor("4f9a3c") * (0.75 + 0.3 * ribs[..., None] + 0.1 * grain[..., None])
    spines = np.zeros((INNER, INNER), bool)
    for _ in range(26):
        cx, cy = rng.integers(0, 4) * INNER / 4 + INNER / 8, rng.random() * INNER
        spines |= (np.abs(xx - cx) < 2.0) & (np.abs(yy - cy) < 5.0)
    cactus[spines] = base.hexcolor("f3eed5")
    page.put((1, 1), np.clip(cactus, 0, 1), base.normal_from_height(ribs * 0.8 + 0.2 * grain, 3.0), wrap_y=False)
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    top = base.hexcolor("5fae47") * (0.8 + 0.2 * np.cos(np.arctan2(yy - INNER / 2, xx - INNER / 2) * 8)[..., None])
    top[r < 0.07 * INNER] = base.hexcolor("ff7aa8")                               # a pink flower
    page.put((0, 1), np.clip(top, 0, 1), base.normal_from_height(np.clip(1 - r / INNER, 0, 1), 2.0), wrap_x=False, wrap_y=False)
    page.put((2, 1), np.clip(base.hexcolor("36722a") * (0.8 + 0.3 * grain[..., None]), 0, 1), base.normal_from_height(grain, 1.5))

    # dry bush: the pixel twigs, smoothed, on see-through (cutout)
    bush = pixel_tile(3, 1, smooth=False)
    wood_lum = tex["wood"][0].mean(-1, keepdims=True)
    bush_c = np.clip(bush[..., :3] * (0.8 + 0.4 * wood_lum), 0, 1)
    page.put((3, 1), bush_c, base.flat_normal(), (bush[..., 3] > 0.5).astype(np.float32), wrap_x=False, wrap_y=False)

    # desert glass: a warm frame, two streaks and a few sand-coloured specks (the rest clear)
    frame = (xx < 12) | (yy < 12) | (xx > INNER - 13) | (yy > INNER - 13)
    streak = (np.abs((xx - yy) - 40) < 6) | (np.abs((xx - yy) + 30) < 3)
    specks = base.smooth_noise(1.2) > 0.86
    glass_alpha = (frame | streak | specks).astype(np.float32)
    glass_c = np.where(frame[..., None], base.hexcolor("f0d9a0"), base.hexcolor("fff4d6"))
    glass_c[specks & ~frame] = base.hexcolor("f3dca0")
    page.put((4, 1), glass_c.astype(np.float32), base.flat_normal(), glass_alpha, wrap_x=False, wrap_y=False)

    # palm: a lighter bark in rings; the top shows the wood's rings
    rings_side = 0.8 + 0.25 * (np.mod(yy, INNER / 4) < 6)[..., None]
    palm_side = tint(tex["bark"][0], "a47c4a", 0.5) * np.where(np.mod(yy, INNER / 4) < 6, 0.7, 1.0)[..., None]
    page.put((5, 1), np.clip(palm_side, 0, 1), tex["bark"][1])
    rings = 0.5 + 0.5 * np.sin(r * 0.45 + 3.0 * base.smooth_noise(10))
    palm_top = tint(tex["wood"][0], "d8ae72", 0.5) * (0.8 + 0.25 * rings[..., None])
    rim = (r > INNER * 0.44)[..., None]
    page.put((6, 1), np.where(rim, tint(tex["bark"][0], "7a5a36", 0.5), palm_top),
        np.where(rim, tex["bark"][1], base.normal_from_height(rings, 1.5)), wrap_x=False, wrap_y=False)
    del rings_side
    # palm fronds: the grass texture in long diagonal fronds with gaps (cutout)
    fronds = (np.mod(xx + yy, INNER / 5) < INNER / 8).astype(np.float32)
    holes = base.smooth_noise(2.5) > 0.3
    page.put((7, 1), tint(tex["fronds"][0], "5fb33a", 0.5), tex["fronds"][1], (fronds * holes).astype(np.float32))

    page.put((0, 2), np.clip(tex["gold"][0] * 1.1, 0, 1), tex["gold"][1])        # pyramid gold
    # desert lamp: a warm glowing window in a sandstone brick frame (unshaded: no normals needed)
    glow = 1 - np.clip(np.hypot(xx - INNER / 2, yy - INNER / 2) / (INNER / 2), 0, 1)
    lamp_c = base.hexcolor("ff9a3a") + (base.hexcolor("ffe3a0") - base.hexcolor("ff9a3a")) * glow[..., None]
    lamp_frame = (xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u)
    lamp_c[lamp_frame] = bricks_c[lamp_frame] * 0.8
    page.put((1, 2), np.clip(lamp_c, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = bricks_c * 0.8
    window = (np.abs(xx - INNER / 2) < 3 * u) & (np.abs(yy - INNER / 2) < 3 * u)
    lamp_top[window] = base.hexcolor("ffd27a")
    page.put((2, 2), lamp_top, base.flat_normal(), wrap_x=False, wrap_y=False)
    # arrow slit: the sandstone bricks with a dark slit down the middle
    slit = (np.abs(xx - INNER / 2) < u) & (yy > 3 * u) & (yy < 13 * u)
    slit_c = bricks_c.copy()
    slit_c[slit] = base.hexcolor("2a1d10")
    slit_h = np.where(slit, 0.0, 1.0).astype(np.float32)
    page.put((3, 2), slit_c, np.where(slit[..., None], base.normal_from_height(slit_h, 4.0), tex["bricks"][1]), wrap_x=False, wrap_y=False)
    # trap sand: page 0's sand with faint ripples a sharp-eyed child can spot
    ripple = 0.5 + 0.5 * np.sin((xx + 2 * yy) / INNER * 2 * np.pi * 6)
    trap_c = np.clip(tex["sand"][0] * (0.96 + 0.05 * ripple[..., None]), 0, 1)
    page.put((4, 2), trap_c, base.normal_from_height(ripple * 0.5 + 0.5 * base.smooth_noise(3), 1.0))
    # fake sandstone: the sandstone side with a faint crack
    crack = np.zeros((INNER, INNER), bool)
    path = [(6, 4), (6, 5), (6, 6), (7, 7), (7, 8), (7, 9), (6, 10), (6, 11), (7, 12), (7, 13), (6, 14)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for t in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * t + 0.5) * u, (ay + (by - ay) * t + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.2
    fake_c = side_c.copy()
    fake_c[crack] *= 0.65
    page.put((5, 2), fake_c, tex["layers"][1])
    page.save()
    print("DESERT realistic page saved:", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
