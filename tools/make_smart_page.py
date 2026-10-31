#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 9 (M3 Task 7): smart blocks and Game Blocks.

Outputs data/blocks/pages/smart_albedo.png (RGBA) and smart_normal.png (RGB, OpenGL normals), 2048 px, in the
same 8x8 layout as the pixel page data/blocks/pages/smart.png (tools/make_smart_page.gd, which must be run
first: this script paints from its designs).

Each tile is the pixel design smoothed up to 240 px (the shapes children know from the blocky style), with
the look of real materials laid over it: CC0 ambientCG Metal034 on the metal (plates, door, frames), Plastic013A
on the coloured parts (buttons, the Game Blocks' paint), and a height map from the design's light and dark for
the normal map. Glowing tiles (on states, the teleport pad) keep a flat normal (they are drawn unshaded). Cut-out
tiles (the open door, the coin) keep the design's hard alpha edge.
Tiles use the 240 px + 8 px border layout of tools/make_realistic_atlas.py, whose helpers it borrows.

Run from the project root:  python3 tools/make_smart_page.py   (needs Pillow and numpy; downloads cached in
~/.cache/easycraft-textures). Credits are in assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as mra  # noqa: E402  (its helpers: fetch, pad, normal_from_height, Atlas layout)

PIXEL = "data/blocks/pages/smart.png"
OUT_ALBEDO = "data/blocks/pages/smart_albedo.png"
OUT_NORMAL = "data/blocks/pages/smart_normal.png"
N = mra.INNER

# (tile, glows, cut out) for every tile the pixel page draws.
TILES = [
    ((0, 0), False, False), ((1, 0), False, False), ((2, 0), True, False), ((3, 0), True, False),
    ((4, 0), False, False), ((5, 0), False, False), ((6, 0), True, False), ((7, 0), True, False),
    ((0, 1), False, False), ((1, 1), False, True), ((2, 1), False, False), ((3, 1), True, False),
    ((4, 1), False, False), ((5, 1), True, False), ((6, 1), True, False), ((7, 1), False, False),
    ((0, 2), False, False), ((1, 2), False, False), ((2, 2), False, False), ((3, 2), False, False),
    ((4, 2), False, False), ((5, 2), False, False), ((6, 2), False, True), ((7, 2), False, False),
    ((0, 3), False, False), ((1, 3), False, False),
]


def design(page: Image.Image, tile) -> tuple[np.ndarray, np.ndarray]:
    """The 16 px design smoothed to N px (colour) and its hard alpha (nearest)."""
    x, y = tile
    crop = page.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16))
    smooth = np.asarray(crop.convert("RGB").resize((N, N), Image.BICUBIC), np.float32) / 255.0
    alpha = np.asarray(crop.getchannel("A").resize((N, N), Image.NEAREST), np.float32) / 255.0
    return np.clip(smooth, 0, 1), alpha


def detail(tex: np.ndarray) -> np.ndarray:
    """A texture's light and dark around 1.0 (its colour left out), for multiplying over a design."""
    grey = tex.mean(-1)
    return (grey / max(float(grey.mean()), 1e-6))[..., None]


def main() -> None:
    page = Image.open(PIXEL).convert("RGBA")
    metal, metal_n = mra.fetch("Metal034")
    plastic, plastic_n = mra.fetch("Plastic013A")
    metal_d = np.clip(detail(metal), 0.7, 1.3)
    plastic_d = np.clip(detail(plastic), 0.85, 1.15)
    albedo = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 4), np.float32)
    normal = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 3), np.float32)
    normal[...] = mra.FLAT / 255.0
    for tile, glows, cut in TILES:
        color, alpha = design(page, tile)
        sat = color.max(-1) - color.min(-1)
        is_metal = (sat < 0.12)[..., None]                      # the greys are metal, the rest painted plastic
        lit = color * np.where(is_metal, metal_d, plastic_d)
        if glows:
            lit = color * 0.85 + lit * 0.15                     # drawn unshaded: keep it bright and clean
            nrm = mra.flat_normal()
        else:
            h = np.asarray(Image.fromarray((color.mean(-1) * 255).astype(np.uint8)).filter(
                ImageFilter.GaussianBlur(3)), np.float32) / 255.0
            nrm = mra.normal_from_height(h, 5.0) * 0.6 + np.where(is_metal, metal_n, plastic_n) * 0.4
        a = alpha if cut else np.ones((N, N), np.float32)
        rgba = np.concatenate([np.clip(lit, 0, 1), a[..., None]], -1)
        x, y = tile
        albedo[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(rgba, False, False)
        normal[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(nrm, 0, 1), False, False)
    os.makedirs(os.path.dirname(OUT_ALBEDO), exist_ok=True)
    # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
    mra.save_page((albedo * 255 + 0.5).astype(np.uint8), (normal * 255 + 0.5).astype(np.uint8),
                  OUT_ALBEDO, OUT_NORMAL)
    print("SMART_PAGE realistic", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
