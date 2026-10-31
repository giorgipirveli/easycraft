#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 13, the wild meadows (owner feedback #45b), from CC0 textures
(ambientCG, https://ambientcg.com), in the same 8x8 layout as data/blocks/pages/meadows.png
(world/universes/meadows_blocks.gd TILES):

  data/blocks/pages/meadows_albedo.png (RGBA) and meadows_normal.png (RGB, OpenGL normals), 2048 px.

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px
border that continues it. Sources (all CC0): Bark007 (the birch's pale bark), Bark001 (dark oak bark), Wood095
(log ends), Grass001 (leaves), Rock029 (mud), Bricks084 (stone bricks), Moss002 (moss on the mossy bricks),
Plaster001 (white plaster), Tiles144 (clay roof tiles), Ground097 (hay and wheat straw), Fabric004 (sail cloth),
Ground093A (the dirt path), Ground103 (dirt). The birch's black marks, the brick joints, the tile rows, the hay's
string, the sail's seam and the glowing mushroom's spots are drawn here over those textures; flowers, wheat and
the lily pad take their outlines from the pixel page.

Run from the project root:  python3 tools/make_meadows_realistic.py     (needs Pillow + numpy; run
godot --headless --path . --script res://tools/make_meadows_page.gd first). Downloads are cached in
~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/meadows_albedo.png"
OUT_NORMAL = "data/blocks/pages/meadows_normal.png"
PIXEL_PAGE = "data/blocks/pages/meadows.png"
SOURCES = {
    "birch": "Bark007", "darkbark": "Bark001", "wood": "Wood095", "leaves": "Grass001", "mud": "Rock029",
    "bricks": "Bricks084", "moss": "Moss002", "plaster": "Plaster001", "tiles": "Tiles144", "straw": "Ground097",
    "fabric": "Fabric004", "path": "Ground093A", "dirt": "Ground103",
}


class Page(base.Atlas):
    def save(self) -> None:
        # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
        base.save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                       OUT_ALBEDO, OUT_NORMAL)


def tint(color: np.ndarray, target: str, keep: float = 0.4) -> np.ndarray:
    """The texture's light and shade in the colour `target` (keep: how much of its own colour stays)."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(color * keep + base.hexcolor(target) * lum * (1 - keep), 0, 1)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20260970)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    pixel = np.asarray(Image.open(PIXEL_PAGE).convert("RGBA"), np.float32) / 255.0

    def pixel_tile(tx: int, ty: int, smooth: bool = False) -> np.ndarray:
        icon = pixel[ty * 16:(ty + 1) * 16, tx * 16:(tx + 1) * 16]
        img = Image.fromarray((icon * 255).astype(np.uint8), "RGBA")
        return np.asarray(img.resize((INNER, INNER), Image.BILINEAR if smooth else Image.NEAREST), np.float32) / 255.0

    page = Page()

    def log_end(bark_c: np.ndarray, bark_n: np.ndarray, wood_hex: str) -> tuple:
        rings = 0.5 + 0.5 * np.sin(r * 0.45 + 3.0 * base.smooth_noise(10))
        wood = tint(tex["wood"][0], wood_hex, 0.35) * (0.8 + 0.25 * rings[..., None])
        mask = (r > INNER * 0.44)[..., None]
        return np.where(mask, bark_c, wood), np.where(mask, bark_n, base.normal_from_height(rings, 1.5))

    # birch: pale, almost white bark with black marks across it
    birch_c = np.clip(tint(tex["birch"][0], "ece8de", 0.15) * 1.08, 0, 1)
    marks = np.zeros((INNER, INNER), bool)
    for _ in range(11):
        cx, cy = rng.random() * INNER, rng.random() * INNER
        w, h = (0.8 + rng.random() * 2.2) * u, (0.15 + rng.random() * 0.3) * u
        marks |= (np.abs(xx - cx) < w) & (np.abs(yy - cy) < h)
    birch_c[marks] = base.hexcolor("27221e") * (0.8 + 0.4 * base.smooth_noise(2)[marks][..., None])
    birch_n = np.where(marks[..., None], base.normal_from_height(marks.astype(np.float32), 2.0), tex["birch"][1])
    page.put((0, 0), birch_c, birch_n)
    page.put((1, 0), *log_end(birch_c, birch_n, "e3cf9a"), wrap_x=False, wrap_y=False)

    # leaves: the grass texture with holes, light spring green (birch) and deep green (dark oak)
    holes = base.smooth_noise(3)
    page.put((2, 0), tint(tex["leaves"][0], "8fc94a", 0.35), tex["leaves"][1], (holes > 0.38).astype(np.float32))
    dark_c = np.clip(tint(tex["darkbark"][0], "4a3222", 0.25) * 0.85, 0, 1)
    page.put((3, 0), dark_c, tex["darkbark"][1])
    page.put((4, 0), *log_end(dark_c, tex["darkbark"][1], "7a5536"), wrap_x=False, wrap_y=False)
    holes2 = base.smooth_noise(3)
    page.put((5, 0), tint(tex["leaves"][0], "2f6b2a", 0.3) * 0.9, tex["leaves"][1], (holes2 > 0.3).astype(np.float32))

    # flowers, the lily pad and wheat: the pixel tiles' shapes, smoothed, lit a little by a texture
    for tile, src in [((6, 0), "leaves"), ((7, 0), "leaves"), ((7, 1), "straw")]:
        pic = pixel_tile(*tile, smooth=True)
        light = tex[src][0].mean(-1, keepdims=True)
        light = 0.85 + 0.3 * (light - light.mean())
        page.put(tile, np.clip(pic[..., :3] * light, 0, 1), base.flat_normal(), (pic[..., 3] > 0.5).astype(np.float32),
            wrap_x=False, wrap_y=False)

    # mud: dark wet earth with shiny puddles
    mud_c = tint(tex["mud"][0], "5b4a3a", 0.3)
    puddles = base.smooth_noise(8) > 0.72
    mud_c[puddles] = mud_c[puddles] * 0.7 + 0.08
    page.put((0, 1), mud_c, np.where(puddles[..., None], base.flat_normal(), tex["mud"][1]))

    # stone bricks: grey stone blocks in a running bond, dark joints (the texture's own stones lit in grey)
    stone = tint(tex["bricks"][0], "9a9a96", 0.2)
    row = np.floor(yy / (INNER / 4))
    off = np.where(np.mod(row, 2) == 1, INNER / 4, 0)
    joint = (np.mod(yy, INNER / 4) < 0.55 * u) | (np.mod(xx + off, INNER / 2) < 0.55 * u)
    brick_c = np.where(joint[..., None], base.hexcolor("555553"), stone)
    brick_h = 1.0 - joint.astype(np.float32)
    brick_n = base.normal_from_height(brick_h, 3.0)
    page.put((1, 1), brick_c, brick_n)
    moss = base.smooth_noise(6) > 0.55
    mossy_c = brick_c.copy()
    mossy_c[moss] = tint(tex["moss"][0], "5d8f2f", 0.5)[moss]
    page.put((2, 1), mossy_c, np.where(moss[..., None], tex["moss"][1], brick_n))

    page.put((3, 1), tint(tex["plaster"][0], "f2eee4", 0.3), tex["plaster"][1])            # white plaster

    # roof tiles: red clay rows, each row's bottom edge in shadow
    clay = tint(tex["tiles"][0], "c4492f", 0.25)
    in_row = np.mod(yy, INNER / 4) / (INNER / 4)
    roof_c = clay * (1.1 - 0.45 * in_row[..., None])
    roof_row = np.floor(yy / (INNER / 4))
    roof_off = np.where(np.mod(roof_row, 2) == 1, INNER / 8, 0)
    seam = np.mod(xx + roof_off, INNER / 4) < 0.5 * u
    roof_c[seam] *= 0.6
    page.put((4, 1), np.clip(roof_c, 0, 1), base.normal_from_height(1 - in_row - seam * 0.5, 2.5))

    # hay: golden straw with fine stalk lines; the side has a string round it
    straw = tint(tex["straw"][0], "e3c05a", 0.2)
    stalks = np.mod(xx * 0.9 + 7.0 * base.smooth_noise(4), 9.0) < 1.2
    hay_side = straw.copy()
    hay_side[stalks] *= 0.78
    string = (np.abs(yy - 4.5 * u) < 0.5 * u) | (np.abs(yy - 11.5 * u) < 0.5 * u)
    hay_side[string] = base.hexcolor("8c5e28")
    page.put((5, 1), hay_side, base.normal_from_height(stalks.astype(np.float32) * 0.5 + string, 2.0))
    hay_top = straw.copy()
    swirl = np.mod(np.arctan2(yy - INNER / 2, xx - INNER / 2) * 5 + r * 0.2, 2.0) < 0.5
    hay_top[swirl] *= 0.8
    page.put((6, 1), hay_top, base.normal_from_height(swirl.astype(np.float32), 1.5))

    # sail cloth: cream canvas with a seam across it
    sail_c = np.clip(0.35 * tint(tex["fabric"][0], "f4efe2", 0.15) + 0.65 * tint(tex["plaster"][0], "f4efe2", 0.2), 0, 1)
    sail_seam = np.abs(yy - INNER / 2) < 0.6 * u
    sail_c[sail_seam] *= 0.88
    page.put((0, 2), sail_c, tex["fabric"][1] * 0.35 + base.flat_normal() * 0.65)

    # glowing mushroom cap: bright blue with pale spots (unshaded: no normals needed)
    cap = base.hexcolor("45e0ff") * (0.85 + 0.25 * base.smooth_noise(5))[..., None]
    spots = np.zeros((INNER, INNER), bool)
    for _ in range(9):
        cx, cy = rng.random() * INNER, rng.random() * INNER
        spots |= np.hypot(xx - cx, yy - cy) < (0.8 + rng.random()) * u
    cap[spots] = base.hexcolor("d8fdff")
    page.put((1, 2), np.clip(cap, 0, 1), base.flat_normal())

    # dirt path: light packed earth; its side is dirt with the path's top band
    path_c = tint(tex["path"][0], "b89a67", 0.35)
    page.put((2, 2), path_c, tex["path"][1])
    dirt_c, dirt_n = tex["dirt"]
    band = yy < 2.5 * u
    page.put((3, 2), np.where(band[..., None], path_c, dirt_c), np.where(band[..., None], tex["path"][1], dirt_n),
        wrap_y=False)
    page.put((4, 2), dirt_c, dirt_n)
    page.save()
    print("MEADOWS realistic page saved:", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
