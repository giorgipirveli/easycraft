#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 14 (M3 Task 21c, the wonder pack): the pumpkin, the jack-o-lantern,
the snowman's head and the mice's tiny cheese.

Outputs data/blocks/pages/tiny_albedo.png (RGBA) and tiny_normal.png (RGB, OpenGL normals), 2048 px, in the same
8x8 layout as the pixel page data/blocks/pages/tiny.png (tools/make_tiny_page.gd, which must be run first: this
script paints from its designs, like tools/make_smart_page.py).

Each tile is the pixel design smoothed up to 240 px (the shapes children know from the blocky style) with the grain
of a real material laid over it: CC0 ambientCG Plaster001 on the pumpkin's skin and the cheese, Snow003 on the
snowman's head; a height map from the design's light and dark gives the normal map (the pumpkin's ribs, the carved
face, the cheese's holes). The jack-o-lantern is drawn unshaded (it glows): it keeps a flat normal.
Tiles use the 240 px + 8 px border layout of tools/make_realistic_atlas.py, whose helpers it borrows.

Run from the project root:  python3 tools/make_tiny_page.py   (needs Pillow and numpy; downloads cached in
~/.cache/easycraft-textures). Credits are in assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as mra  # noqa: E402  (its helpers: fetch, pad, normal_from_height, the layout)

PIXEL = "data/blocks/pages/tiny.png"
OUT_ALBEDO = "data/blocks/pages/tiny_albedo.png"
OUT_NORMAL = "data/blocks/pages/tiny_normal.png"
N = mra.INNER

# (tile, material, glows) for every tile the pixel page draws.
TILES = [
    ((0, 0), "plaster", False), ((1, 0), "plaster", False), ((2, 0), "plaster", False),   # the pumpkin
    ((3, 0), "plaster", True), ((4, 0), "plaster", True),                                  # the jack-o-lantern
    ((5, 0), "snow", False), ((6, 0), "snow", False), ((7, 0), "snow", False),             # the snowman's head
    ((0, 1), "plaster", False), ((1, 1), "plaster", False),                                # the cheese
]


def design(page: Image.Image, tile) -> np.ndarray:
    """The 16 px design smoothed to N px (colour), with its hard shapes kept a little (a pixel-sharp blend)."""
    x, y = tile
    crop = page.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16)).convert("RGB")
    smooth = np.asarray(crop.resize((N, N), Image.BICUBIC), np.float32) / 255.0
    sharp = np.asarray(crop.resize((N, N), Image.NEAREST), np.float32) / 255.0
    return np.clip(smooth * 0.6 + sharp * 0.4, 0, 1)


def detail(tex: np.ndarray, lo: float, hi: float) -> np.ndarray:
    """A texture's light and dark around 1.0 (its colour left out), for multiplying over a design."""
    grey = tex.mean(-1)
    return np.clip(grey / max(float(grey.mean()), 1e-6), lo, hi)[..., None]


def main() -> None:
    page = Image.open(PIXEL).convert("RGBA")
    plaster, plaster_n = mra.fetch("Plaster001")
    snow, snow_n = mra.fetch("Snow003")
    looks = {"plaster": (detail(plaster, 0.85, 1.15), plaster_n), "snow": (detail(snow, 0.92, 1.08), snow_n)}
    albedo = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 4), np.float32)
    normal = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 3), np.float32)
    normal[...] = mra.FLAT / 255.0
    for tile, material, glows in TILES:
        color = design(page, tile)
        grain, grain_n = looks[material]
        lit = np.clip(color * grain, 0, 1)
        if glows:
            lit = color * 0.85 + lit * 0.15          # drawn unshaded: keep it bright and clean
            nrm = mra.flat_normal()
        else:
            h = np.asarray(Image.fromarray((color.mean(-1) * 255).astype(np.uint8)).filter(
                ImageFilter.GaussianBlur(3)), np.float32) / 255.0
            nrm = mra.normal_from_height(h, 4.0) * 0.6 + grain_n * 0.4
        rgba = np.concatenate([lit, np.ones((N, N, 1), np.float32)], -1)
        x, y = tile
        albedo[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(rgba, False, False)
        normal[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(nrm, 0, 1), False, False)
    os.makedirs(os.path.dirname(OUT_ALBEDO), exist_ok=True)
    # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
    mra.save_page((albedo * 255 + 0.5).astype(np.uint8), (normal * 255 + 0.5).astype(np.uint8),
                  OUT_ALBEDO, OUT_NORMAL)
    print("TINY_PAGE realistic", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
