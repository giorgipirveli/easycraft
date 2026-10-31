#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 19 (spec §23, the Science Lab): the lab bench.

Outputs data/blocks/pages/lab_albedo.png (RGB/RGBA) and lab_normal.png (RGB, OpenGL normals), 2048 px, in the same 8x8
layout as the pixel page data/blocks/pages/lab.png (tools/make_lab_page.gd, which must be run first: this script
paints from its designs, like tools/make_tiny_page.py).

Each tile is the pixel design smoothed up to 240 px with the grain of a real material laid over it: CC0 ambientCG
Plastic013A on the white bench (a smooth lab laminate), Metal034 on the burner's stand; the glass, the liquid and the
flame keep their clean colours. A height map from the design's light and dark gives the normal map (the doors' gap,
the shelf, the worktop's edge). Tiles use the 240 px + 8 px border layout of tools/make_realistic_atlas.py, whose
helpers it borrows.

Run from the project root:  PYTHONDONTWRITEBYTECODE=1 python3 tools/make_lab_page.py   (needs Pillow and numpy;
downloads cached in ~/.cache/easycraft-textures). Credits are in assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as mra  # noqa: E402  (its helpers: fetch, pad, normal_from_height, the layout)

PIXEL = "data/blocks/pages/lab.png"
OUT_ALBEDO = "data/blocks/pages/lab_albedo.png"
OUT_NORMAL = "data/blocks/pages/lab_normal.png"
N = mra.INNER

# every tile the pixel page draws: the bench's top, side and bottom
TILES = [(0, 0), (1, 0), (2, 0)]


def design(page: Image.Image, tile) -> np.ndarray:
    """The 16 px design smoothed to N px (colour), with its hard shapes kept (a pixel-sharp blend)."""
    x, y = tile
    crop = page.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16)).convert("RGB")
    smooth = np.asarray(crop.resize((N, N), Image.BICUBIC), np.float32) / 255.0
    sharp = np.asarray(crop.resize((N, N), Image.NEAREST), np.float32) / 255.0
    return np.clip(smooth * 0.45 + sharp * 0.55, 0, 1)


def detail(tex: np.ndarray, lo: float, hi: float) -> np.ndarray:
    """A texture's light and dark around 1.0 (its colour left out), for multiplying over a design."""
    grey = tex.mean(-1)
    return np.clip(grey / max(float(grey.mean()), 1e-6), lo, hi)[..., None]


def masks(color: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Where the design is clean colour (glass, liquid, flame: saturated or very light blue-green) and where it is
    metal (the burner's grey)."""
    mx = color.max(-1)
    mn = color.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1e-6)
    clean = (sat > 0.35).astype(np.float32)
    grey = ((sat < 0.18) & (mx > 0.3) & (mx < 0.7)).astype(np.float32)
    blur = lambda m: np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2)),
                                np.float32)[..., None] / 255.0
    return blur(clean), blur(grey)


def main() -> None:
    page = Image.open(PIXEL).convert("RGBA")
    plastic, plastic_n = mra.fetch("Plastic013A")
    metal, metal_n = mra.fetch("Metal034")
    albedo = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 4), np.float32)
    normal = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 3), np.float32)
    normal[...] = mra.FLAT / 255.0
    grain_p = detail(plastic, 0.94, 1.06)
    grain_m = detail(metal, 0.8, 1.2)
    for tile in TILES:
        color = design(page, tile)
        clean, grey = masks(color)
        lit = color * grain_p * (1 - grey) + color * grain_m * grey
        lit = np.clip(lit * (1 - clean) + color * clean, 0, 1)
        h = np.asarray(Image.fromarray((color.mean(-1) * 255).astype(np.uint8)).filter(
            ImageFilter.GaussianBlur(2)), np.float32) / 255.0
        nrm = mra.normal_from_height(h, 3.0) * 0.7 + (plastic_n * (1 - grey) + metal_n * grey) * 0.3
        rgba = np.concatenate([lit, np.ones((N, N, 1), np.float32)], -1)
        x, y = tile
        albedo[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(rgba, False, False)
        normal[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(nrm, 0, 1), False, False)
    os.makedirs(os.path.dirname(OUT_ALBEDO), exist_ok=True)
    # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
    mra.save_page((albedo * 255 + 0.5).astype(np.uint8), (normal * 255 + 0.5).astype(np.uint8),
                  OUT_ALBEDO, OUT_NORMAL)
    print("LAB_PAGE realistic", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
