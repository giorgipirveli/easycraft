#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 12, the painted blocks (M3 Task 8), from a CC0 texture
(ambientCG, https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/paint.png
(data/blocks/paint_page.gd: tint t at (t % 8, t // 8)):

  data/blocks/pages/paint_albedo.png (RGBA) and paint_normal.png (RGB, OpenGL normals), 2048 px.

Every tile is ambientCG Plaster001 (CC0) painted in the tint: the plaster's own light and shade over the flat
colour, so white stays white and black stays black, with the plaster's bumps in the normal map. Tiles are made
like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px border that continues it.

Run from the project root:  python3 tools/make_paint_page.py     (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, the Atlas)

OUT_ALBEDO = "data/blocks/pages/paint_albedo.png"
OUT_NORMAL = "data/blocks/pages/paint_normal.png"
SOURCE = "Plaster001"
# PaintRules.TINTS (core/building/paint_rules.gd), in order.
TINTS = ["f2f0ea", "b8bec6", "6d747c", "2a2c31", "875634", "d8363d", "f08622", "f6cf36",
         "8dd13d", "37984a", "24b3ab", "6cc4f0", "3462d4", "8a4dd0", "d24cc0", "f498bd"]


class Page(base.Atlas):
    def save(self) -> None:
        # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
        base.save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                       OUT_ALBEDO, OUT_NORMAL)


def paint(plaster: np.ndarray, target: str) -> np.ndarray:
    """The plaster's light and shade (kept gentle: ±12 %) over the flat tint."""
    lum = plaster.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(base.hexcolor(target) * np.clip(1.0 + (lum - 1.0) * 0.6, 0.88, 1.12), 0, 1)


def main() -> None:
    color, normal = base.fetch(SOURCE)
    # a softer bump than the raw plaster (painted walls are smooth): halfway to flat
    flat = np.array([0.5, 0.5, 1.0], np.float32)
    normal = flat + (normal - flat) * 0.5
    page = Page()
    for t, hexc in enumerate(TINTS):
        page.put((t % 8, t // 8), paint(color, hexc), normal)
    page.save()
    print("wrote", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
