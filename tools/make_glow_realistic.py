#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 45, universe 6, the Glow Caves (spec §5.1), from CC0 textures
(ambientCG, https://ambientcg.com) already in the cache, in the same 8x8 layout as data/blocks/pages/glow.png
(world/universes/glow_blocks.gd TILES), three rows:

  data/blocks/pages/glow_albedo.png (RGBA: the dripstone pictures are cut out) and glow_normal.png (RGB, OpenGL
  normals), 2048 x 768.

Calm, never scary: lilac-grey limestone, teal glow moss, pastel glowshroom caps, a glow-worm ceiling's blue lights on
silk threads, milky selenite, cream-and-orange flowstone, cream dripstone, blue-grey lake pebbles. Glowing tiles are
for an unshaded material (they shine as drawn, flat normals): dark grounds with bright points; the moss's stone side is
drawn pre-shaded.

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px border that
continues it. Sources (all CC0, all in the cache: nothing is downloaded): Rock030 (cave stone, tinted lilac grey),
Moss002 (glow moss), Bark007 (glowshroom stems), Wood095 (a stem's cut rings), Plastic013A (the caps), Rock035 (the
glow-worms' dark rock), Ice004 (selenite, cave gold's ground), Ground093A (flowstone), Plaster001 (dripstone, pearls),
Rock031 (lake pebbles), WoodFloor043 (fungus planks, the spore lamp's frame), Metal034 (cave gold's nuggets). The
spots, gills, lights, threads, bands, cones, pebbles, the lamp's glow, the pearls and the crack are drawn here.

Run from the project root:  python3 tools/make_glow_realistic.py     (needs Pillow + numpy)
Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
OUT_ALBEDO = "data/blocks/pages/glow_albedo.png"
OUT_NORMAL = "data/blocks/pages/glow_normal.png"
SOURCES = {
    "rock": "Rock030", "moss": "Moss002", "bark": "Bark007", "rings": "Wood095", "plastic": "Plastic013A",
    "dark": "Rock035", "ice": "Ice004", "flow": "Ground093A", "plaster": "Plaster001", "pebble": "Rock031",
    "planks": "WoodFloor043", "metal": "Metal034",
}


def _cached(asset: str) -> tuple[np.ndarray, np.ndarray]:
    path = os.path.join(base.CACHE, f"{asset}_1K-JPG.zip")
    if not os.path.exists(path):
        raise SystemExit(f"{asset} is not in {base.CACHE}: this tool never downloads (choose a cached source)")
    return base.fetch(asset)


class Page(base.Atlas):
    def save(self) -> None:
        # M5 Task 3: the rows under the last drawn tile cropped off (three rows); alpha kept: the dripstone is cut out
        base.save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                       OUT_ALBEDO, OUT_NORMAL)


def lum_of(color: np.ndarray) -> np.ndarray:
    lum = color.mean(-1, keepdims=True)
    return lum / max(float(lum.mean()), 1e-3)


def tint(color: np.ndarray, target: str, keep: float = 0.55) -> np.ndarray:
    """The texture's light and shade in the colour `target` (keep: how much of its own colour stays)."""
    return np.clip(color * keep + base.hexcolor(target) * lum_of(color) * (1 - keep), 0, 1)


def shade(color: np.ndarray, target: str, lo: float = 0.8, hi: float = 1.15) -> np.ndarray:
    """A flat colour lit by the texture's light and shade."""
    return np.clip(base.hexcolor(target) * np.clip(lum_of(color), lo, hi), 0, 1)


def main() -> None:
    tex = {k: _cached(v) for k, v in SOURCES.items()}
    rng = np.random.default_rng(20261017)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    ang = np.arctan2(yy - INNER / 2, xx - INNER / 2)
    flat = base.flat_normal()
    page = Page()

    def dots(n: int, rad: tuple[float, float], area=None) -> list:
        out = []
        for _ in range(n):
            cx, cy = rng.random() * INNER, rng.random() * INNER
            if area is not None and not area(cx, cy):
                continue
            out.append((cx, cy, rad[0] + rng.random() * (rad[1] - rad[0])))
        return out

    def glow_points(c: np.ndarray, points: list, color: str, halo: str, halo_k: float = 2.6) -> np.ndarray:
        out = c.copy()
        for cx, cy, s in points:
            d = np.hypot(xx - cx, yy - cy)
            k = np.clip(1 - d / (s * halo_k), 0, 1)[..., None] ** 2
            out = out * (1 - k * 0.7) + base.hexcolor(halo) * k * 0.7
            out[d < s] = base.hexcolor(color)
        return np.clip(out, 0, 1)

    # cave stone: limestone, lilac grey, a few pale calcite flecks and bedding lines
    stone = tint(tex["rock"][0], "8d92ab", 0.2)
    bed = 1 - 0.12 * np.exp(-((np.mod(yy + 6 * np.sin(xx / INNER * 2 * np.pi), 5.5 * u) - 2.7 * u) / (0.35 * u)) ** 2)
    stone = stone * bed[..., None]
    for cx, cy, s in dots(10, (1.2, 2.4)):
        stone[np.hypot(xx - cx, yy - cy) < s] = base.hexcolor("d8dbe8")
    page.put((0, 0), stone, tex["rock"][1])

    # glow moss: deep teal tufts with glowing tips (unshaded); its side: a glowing fringe over pre-shaded limestone
    moss = np.clip(base.hexcolor("1f6e64") * (0.55 + 0.45 * lum_of(tex["moss"][0]) ** 1.5), 0, 1)
    moss_top = glow_points(moss, dots(40, (1.4, 2.6)), "c9ffef", "5ff2c4")
    page.put((1, 0), moss_top, flat)
    hang = 3.0 * u + 1.2 * u * np.abs(np.sin(xx / INNER * 2 * np.pi * 4 + 0.4)) + 0.6 * u * np.sin(xx / INNER * 2 * np.pi * 9)
    band = yy < hang
    side = np.where(band[..., None], moss, stone * 0.42)
    side = glow_points(side, [(x * u + 0.5 * u, float(hang[0, int(x * u)]) - 2, 1.6) for x in range(1, 16, 3)],
                       "c9ffef", "5ff2c4")
    page.put((2, 0), side, flat, wrap_y=False)

    # glowshroom stem: a pale fibrous stalk with a lilac blush; its top: soft growth rings
    page.put((3, 0), tint(tex["bark"][0], "ece6f2", 0.12), tex["bark"][1])
    rings = tint(tex["rings"][0], "ece6f2", 0.15) * (0.92 + 0.08 * np.cos(r / u * 2.1))[..., None]
    rings[r > INNER * 0.47] *= 0.86
    page.put((4, 0), rings, tex["rings"][1], wrap_x=False, wrap_y=False)

    # the caps (unshaded): a pastel dome with soft spots, a darker lip, glowing gills underneath
    for (top, side_t, gill_t), hue, dark, spot, gill_c in [
            (((5, 0), (6, 0), (7, 0)), "39b9d9", "1f82a8", "d2fbff", "8fe3f0"),
            (((0, 1), (1, 1), (2, 1)), "f283b8", "c3558f", "ffe6f3", "ffb8da")]:
        cap = shade(tex["plastic"][0], hue, 0.92, 1.08)
        rim = np.clip((r - 5 * u) / (6 * u), 0, 0.7)[..., None]
        cap_top = cap * (1 - rim) + base.hexcolor(dark) * rim
        for sx, sy, sr in [(3.5, 3.5, 1.6), (10.5, 2.6, 1.3), (7.5, 7.6, 1.8), (12.5, 9.5, 1.2), (4.5, 11.5, 1.4),
                           (9.5, 13.2, 1.1)]:
            cap_top[np.hypot(xx - sx * u, yy - sy * u) < sr * u] = base.hexcolor(spot)
        page.put(top, np.clip(cap_top, 0, 1), flat, wrap_x=False, wrap_y=False)
        cap_side = cap.copy()
        lip = yy > 11 * u
        cap_side[lip] = shade(tex["plastic"][0], dark)[lip]
        under = yy > 14 * u
        cap_side[under] = (base.hexcolor(gill_c) * 0.6 + base.hexcolor(hue) * 0.4)
        for sx, sy, sr in [(2.5, 3.5, 1.1), (8.5, 2.5, 1.0), (12.5, 6.5, 0.8), (5.5, 7.5, 0.9), (10.5, 9.0, 0.8)]:
            cap_side[np.hypot(xx - sx * u, yy - sy * u) < sr * u] = base.hexcolor(spot)
        page.put(side_t, np.clip(cap_side, 0, 1), flat, wrap_y=False)
        gill = np.abs(np.sin(ang * 12.0)) > 0.7
        gills = np.where(gill[..., None], base.hexcolor(gill_c), base.hexcolor(dark) * 0.7 + base.hexcolor(gill_c) * 0.3)
        gills = gills * np.clip(lum_of(tex["plastic"][0]), 0.9, 1.1)
        gills[r < 2 * u] = base.hexcolor("ece6f2")
        page.put(gill_t, np.clip(gills, 0, 1), flat, wrap_x=False, wrap_y=False)

    # glow-worm ceiling (unshaded): dark rock under a starry field of blue-green lights; its side: silk threads
    dark = np.clip(tint(tex["dark"][0], "1c2038", 0.3) * 0.9, 0, 1)
    worms = glow_points(dark, dots(60, (0.9, 1.9)), "d6f6ff", "4fb8ef", 3.2)
    page.put((3, 1), worms, flat)
    worm_side = dark * (0.85 + 0.15 * (1 - yy / INNER))[..., None]
    for x in [1, 4, 6.5, 9, 11.5, 14.2]:
        length = (4 + rng.random() * 5) * u
        thread = (np.abs(xx - x * u) < 1.1) & (yy > INNER - length)
        worm_side[thread] = base.hexcolor("3d4f7f")
    worm_side = glow_points(worm_side, [(x * u, INNER - 3, 2.2) for x in [1, 4, 6.5, 9, 11.5, 14.2]], "d6f6ff", "4fb8ef")
    page.put((4, 1), worm_side, flat, wrap_y=False)

    # selenite (unshaded): milky, pale blue crystal in long straight facets
    facet = np.mod((xx + yy * 2.0) / u, 9.0)
    sel = shade(tex["ice"][0], "d9e7f4", 0.9, 1.08)
    sel = sel * (1.0 + 0.12 * (facet < 0.9)[..., None]) * (1.0 - 0.12 * ((facet > 4) & (facet < 5.6))[..., None])
    page.put((5, 1), np.clip(sel, 0, 1), flat)

    # flowstone: wavy cream and orange bands of calcite
    wave = yy / u + np.sin(xx / u * 0.7) * 1.4
    bands = np.mod(wave, 5.0)
    flow = tint(tex["flow"][0], "e7cd9f", 0.25)
    flow = np.where(((bands > 1) & (bands < 2))[..., None], tint(tex["flow"][0], "d79c63", 0.25), flow)
    flow = np.where(((bands > 3) & (bands < 3.8))[..., None], tint(tex["flow"][0], "f6e8c8", 0.25), flow)
    flow_n = base.normal_from_height((0.5 + 0.5 * np.sin(wave * np.pi * 2 / 5)).astype(np.float32), 3.0)
    page.put((6, 1), flow, flow_n)

    # dripstone (cut out): a cream cone hanging to a point with a drop; a rounded cone rising from the floor
    cream = tint(tex["plaster"][0], "e3d3b3", 0.2)
    banded = cream * (1 - 0.1 * (np.mod(yy / u, 4) < 0.6))[..., None]
    t = yy / (14 * u)
    half = (5.5 * (1 - t) + 0.6) * u
    cone = (np.abs(xx - INNER / 2) <= half) & (yy < 14 * u)
    dx = (xx - INNER / 2) / np.maximum(half, 1)
    light = np.clip(0.8 + 0.35 * dx, 0.65, 1.15)[..., None]
    tite = banded * light
    drop = np.hypot(xx - INNER / 2, yy - 14.6 * u) < 0.9 * u
    tite[drop] = base.hexcolor("a8e8ff")
    page.put((7, 1), np.clip(tite, 0, 1), flat, (cone | drop).astype(np.float32), wrap_x=False, wrap_y=False)
    k = np.clip((yy - 3 * u) / (12 * u), 0, 1)
    half_m = (6.5 * np.sqrt(k) + 0.6) * u
    mite = (np.abs(xx - INNER / 2) <= half_m) & (yy >= 3 * u)
    dxm = (xx - INNER / 2) / np.maximum(half_m, 1)
    mite_c = banded * np.clip(0.8 + 0.35 * dxm, 0.65, 1.15)[..., None]
    page.put((0, 2), np.clip(mite_c, 0, 1), flat, mite.astype(np.float32), wrap_x=False, wrap_y=False)

    # cave lake stone: rounded blue-grey pebbles, dark gaps
    height = np.zeros((INNER, INNER), np.float32)
    pebble = tint(tex["pebble"][0], "55607b", 0.25) * 0.55
    for cx, cy, s in [(3, 3, 3), (10, 2, 3), (6, 8, 3), (13, 9, 2.4), (2, 12, 2.4), (9, 13, 3), (14.5, 14.5, 2.2),
                      (1, 7, 2.2), (14, 4, 2.2), (11, 6, 1.6), (5, 14.5, 1.8)]:
        for ox in (-INNER, 0, INNER):
            for oy in (-INNER, 0, INNER):
                d = np.hypot(xx - cx * u - ox, yy - cy * u - oy) / (s * u)
                height = np.maximum(height, np.sqrt(np.clip(1 - d ** 2, 0, 1)))
    stones = tint(tex["pebble"][0], "6c7894", 0.3) * (0.75 + 0.35 * height)[..., None]
    lake = np.where((height > 0.05)[..., None], stones, pebble)
    page.put((1, 2), np.clip(lake, 0, 1), base.normal_from_height(height, 6.0))

    # fungus planks: mauve mushroom wood
    page.put((2, 2), tint(tex["planks"][0], "9d7c9c", 0.25), tex["planks"][1])

    # spore lamp (unshaded): a mushroom-wood frame round a warm glow with twinkling spores
    frame_c = tint(tex["planks"][0], "5c4560", 0.25)
    frame = (xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u)
    bars = (np.abs(xx - 5.5 * u) < 0.5 * u) | (np.abs(xx - 10.5 * u) < 0.5 * u)
    glow = 1 - np.clip(r / (INNER * 0.42), 0, 1)
    lamp = base.hexcolor("ffd98a") + (base.hexcolor("fff8dc") - base.hexcolor("ffd98a")) * glow[..., None]
    lamp = glow_points(lamp, dots(9, (1.0, 1.8), lambda x, y: 2.5 * u < x < INNER - 2.5 * u and 2.5 * u < y < INNER - 2.5 * u),
                       "e8fffa", "b6fff0", 1.8)
    lamp[bars] = lamp[bars] * 0.5 + frame_c[bars] * 0.5
    lamp[frame] = frame_c[frame]
    page.put((3, 2), np.clip(lamp, 0, 1), flat, wrap_x=False, wrap_y=False)
    lamp_top = frame_c.copy() * 0.9
    window = (np.abs(xx - INNER / 2) < 3 * u) & (np.abs(yy - INNER / 2) < 3 * u)
    lamp_top[window] = (base.hexcolor("ffe7a3") + (base.hexcolor("fff8dc") - base.hexcolor("ffe7a3")) * glow[..., None])[window]
    page.put((4, 2), np.clip(lamp_top, 0, 1), flat, wrap_x=False, wrap_y=False)

    # cave pearls (unshaded): round pale stones with a pink sheen in a shallow blue drip pool
    pool = np.clip(base.hexcolor("3c7ea6") * (0.85 + 0.25 * base.smooth_noise(6.0))[..., None], 0, 1)
    pearls = pool.copy()
    for cx, cy, s in [(4, 4, 2.2), (11, 4, 2.0), (7.5, 9.5, 3.0), (3, 12.5, 1.4), (12.5, 12, 2.1)]:
        d = np.hypot(xx - cx * u, yy - cy * u) / (s * u)
        inside = d < 1
        sheen = np.clip(1 - np.hypot(xx - (cx - 0.35 * s) * u, yy - (cy - 0.35 * s) * u) / (0.5 * s * u), 0, 1)
        pc = base.hexcolor("efe6dc") * (0.85 + 0.15 * (1 - d))[..., None] + base.hexcolor("ffd9e6") * 0.15 * (xx > cx * u)[..., None]
        pc = pc + sheen[..., None] * 0.4
        pearls[inside] = pc[inside]
    page.put((5, 2), np.clip(pearls, 0, 1), flat)

    # cave gold (unshaded): gold nuggets set in milky selenite
    gold = sel.copy()
    metal = tint(np.clip(tex["metal"][0] * 1.1, 0, 1), "f5c542", 0.4)
    for cx, cy, s in [(3.5, 3.5, 1.6), (11, 4.5, 1.5), (7, 9.5, 1.9), (12.5, 12.5, 1.4), (3.5, 13, 1.3)]:
        m = np.hypot((xx - cx * u) * 0.8, yy - cy * u) < s * u
        gold[m] = metal[m]
        gold[m & (yy < cy * u - 0.4 * s * u)] = base.hexcolor("fff0a6")
    page.put((6, 2), np.clip(gold, 0, 1), flat)

    # fake cave stone: limestone with a faint crack down it
    crack = np.zeros((INNER, INNER), bool)
    path = [(7, 2), (7, 3), (8, 4), (8, 5), (7, 6), (7, 7), (8, 8), (8, 9), (7, 10), (7, 11), (8, 12), (8, 13)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for s in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * s + 0.5) * u, (ay + (by - ay) * s + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.0
    fake = stone.copy()
    fake[crack] *= 0.6
    page.put((7, 2), fake, tex["rock"][1])
    page.save()
    print("GLOW_REALISTIC", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
