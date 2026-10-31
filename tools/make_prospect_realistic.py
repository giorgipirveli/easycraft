#!/usr/bin/env python3
"""Builds the REALISTIC twin of prospecting's block page (spec §26, owner #80) from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layout as the pixel page (tools/make_prospect_page.gd):

  data/blocks/pages/prospect_albedo.png, prospect_normal.png   page 35 (data/blocks/prospect_page.gd)

Tiles are made like tools/make_space_realistic.py (whose Page and helpers it uses): 240 px of texture plus an 8 px
border that continues it. What a child learns to read, as real rock looks: white quartz with gold specks, river gravel
with gold flakes, grey rock with brassy copper minerals, green malachite, banded iron's red and silver stripes, rusty
rock, grey shale with a fern print, a black glossy oil seep, pink-white rock salt cubes, a white salt crust with
cracks; then copper bars, a sack of table salt, drums of crude oil and kerosene, plastic pellets and the Refinery.
Sources (all CC0, already used by other pages and credited): Rock030 (grey rock, the host rock of the veins), Rock031
(the shale), Rock035 (banded iron's dark bands), Ground079L (sand), Ground103 (rusty earth), Ground097 (the gravel's
pebbles), Snow004 (the salt crust), Ice001 (rock salt), Metal034 (copper, the drums, the refinery), Plastic013A (the
pellets, the drums' paint), Fabric004 (the salt sack). Everything else (specks, flakes, bands, the fern, cracks, cubes,
ribs, valves) is drawn here.

Run from the project root:  python3 tools/make_prospect_realistic.py   (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402
from make_space_realistic import Page, shade, tint, XX, YY, U, R, disc  # noqa: E402

INNER = base.INNER
C = INNER / 2.0


def flat(hex_color: str) -> np.ndarray:
    return np.broadcast_to(base.hexcolor(hex_color), (INNER, INNER, 3)).astype(np.float32).copy()


def specks(img: np.ndarray, rng, n: int, color: str, r_lo: float, r_hi: float, height=None) -> None:
    """Little bright bits (gold, brass) with a lit edge; raises `height` where they are."""
    c = base.hexcolor(color)
    light = np.clip(c * 1.25, 0, 1)
    for _ in range(n):
        cx, cy, r = rng.random() * INNER, rng.random() * INNER, r_lo + rng.random() * (r_hi - r_lo)
        d = np.hypot(XX - cx, YY - cy)
        img[d < r] = c
        img[(d < r * 0.5) & (XX < cx)] = light
        if height is not None:
            height[d < r] += 0.6


def cyl(color: np.ndarray) -> np.ndarray:
    """A drum's side: lit in the middle, darker to its edges."""
    u = XX / INNER
    k = 1.0 - 0.3 * ((u - 0.42) * 2.0) ** 2
    return np.clip(color * k[..., None], 0, 1)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"rock": "Rock030", "shale": "Rock031", "dark": "Rock035", "sand": "Ground079L",
                                         "earth": "Ground103", "pebbles": "Ground097", "snow": "Snow004", "ice": "Ice001",
                                         "metal": "Metal034", "plastic": "Plastic013A", "cloth": "Fabric004"}.items()}
    rng = np.random.default_rng(20260935)
    page = Page("prospect")
    rock = tint(tex["rock"][0], "8a8c8e", 0.35)
    rock_n = tex["rock"][1]

    # --- gold quartz (0,0) side, (1,0) top: milky white quartz, grey host rock at the edges, gold specks ---
    quartz = shade(tex["snow"][0], "ece9e1", 0.86, 1.08)
    streak = base.smooth_noise(6.0)
    quartz = np.where((streak > 0.62)[..., None], quartz * 0.9, quartz)
    host = (streak < 0.12)
    quartz = np.where(host[..., None], rock, quartz)
    for t in [(0, 0), (1, 0)]:
        q = quartz.copy()
        h = streak * 0.3
        specks(q, rng, 22, "f5c542", 2.5, 6.0, h)
        page.put(t, q, base.normal_from_height(h.astype(np.float32), 3.0))

    # --- gold gravel (2,0) top, (3,0) side: rounded pebbles in sand, bright gold flakes ---
    gravel = tint(tex["pebbles"][0], "a89878", 0.5)
    for t in [(2, 0), (3, 0)]:
        g = gravel.copy()
        specks(g, rng, 14 if t == (2, 0) else 9, "f5c542", 2.0, 4.5)
        page.put(t, g, tex["pebbles"][1])

    # --- copper ore (4,0): grey rock with brassy chalcopyrite and a little green ---
    ore = rock.copy()
    h = np.zeros((INNER, INNER), np.float32)
    specks(ore, rng, 26, "d4a93c", 3.0, 8.0, h)
    specks(ore, rng, 6, "2f9a5c", 2.0, 5.0)
    page.put((4, 0), ore, np.clip(rock_n * 0.7 + base.normal_from_height(h, 2.0) * 0.3, 0, 1))

    # --- malachite (5,0) side, (6,0) top: green bands over the rock; rings on top ---
    w = np.sin((XX + YY * 0.6) / U * 0.9) + 0.6 * np.sin(YY / U * 1.7 + XX / U * 0.3)
    green = shade(tex["plastic"][0], "2f9a5c", 0.85, 1.12)
    light = shade(tex["plastic"][0], "5fcf8a", 0.85, 1.12)
    dark = shade(tex["plastic"][0], "1d6b40", 0.85, 1.12)
    side = np.where((w > 1.1)[..., None], light, np.where((w > 0.6)[..., None], dark, green))
    side = np.where((w <= -0.1)[..., None], rock, side)
    page.put((5, 0), side, base.normal_from_height((w * 0.2).astype(np.float32), 2.0))
    ring = np.mod((R / U * 1.3).astype(int), 3)
    top = np.where((ring == 0)[..., None], dark, np.where((ring == 1)[..., None], green, light))
    page.put((6, 0), top, base.normal_from_height((np.sin(R / U * 1.3 * np.pi * 2 / 3) * 0.2).astype(np.float32), 2.0))

    # --- banded iron (7,0) side, (0,1) top: red jasper and silver-black iron bands ---
    red = tint(tex["earth"][0], "a63a28", 0.25)
    silver = shade(tex["metal"][0], "8d9098", 0.8, 1.2)
    black = tint(tex["dark"][0], "3b3c44", 0.3)
    k = ((YY / U + np.sin(XX / U * 0.5) * 1.2) / 2).astype(int) % 8
    bands = np.where(np.isin(k, [2, 6, 7])[..., None], silver, np.where((k == 3)[..., None], black, red))
    page.put((7, 0), bands, base.normal_from_height((np.isin(k, [2, 3, 6, 7]) * 0.4).astype(np.float32), 2.5))
    mottled = np.where((base.smooth_noise(3.0) > 0.7)[..., None], silver, red)
    page.put((0, 1), mottled, tex["earth"][1])

    # --- rusty rock (1,1) top, (2,1) side: rusty red-brown earth and rock ---
    rust = tint(tex["earth"][0], "b95a2c", 0.3)
    page.put((1, 1), rust, tex["earth"][1])
    rust_side = rust.copy()
    rust_side[YY < U] *= 0.78
    page.put((2, 1), rust_side, tex["earth"][1], wrap_y=False)

    # --- fern shale (3,1) side, (4,1) top: grey layers with a fern print ---
    shale = tint(tex["shale"][0], "5f6368", 0.3)
    layers = np.where((np.mod(YY / U, 3.0) < 0.6)[..., None], shale * 1.15, shale)
    fern = np.zeros((INNER, INNER), bool)
    for i in range(12):
        y = (13 - i) * U
        x = (4 + i * 0.55) * U
        fern |= disc(x + U / 2, y + U / 2, U * 0.55)
        if i > 1 and i % 2 == 0:
            for d in range(1, 4 - i // 5):
                fern |= disc(x - d * U + U / 2, y + U - d * U / 2, U * 0.5)
                fern |= disc(x + d * U + U / 2, y + U - d * U / 2, U * 0.5)
    fern_side = np.where(fern[..., None], base.hexcolor("3b3e42"), np.clip(layers, 0, 1))
    page.put((3, 1), fern_side, np.clip(tex["shale"][1] * 0.8 + base.normal_from_height(fern * -0.3, 2.0) * 0.2, 0, 1))
    page.put((4, 1), np.clip(layers, 0, 1), tex["shale"][1])

    # --- oil seep (5,1) top, (6,1) side: black glossy oil soaking the sand ---
    wav = np.sin(XX / U * 0.7 + YY / U * 0.3) + np.cos(YY / U * 0.9 - XX / U * 0.2)
    oil = np.where((wav < 0.9)[..., None], flat("1c1714"), flat("2e231c"))
    shine = base.smooth_noise(4.0)
    oil = np.where((shine > 0.8)[..., None], base.hexcolor("6b5a4a"), oil)
    page.put((5, 1), oil, base.normal_from_height((wav * 0.1).astype(np.float32), 1.5))
    sand = tint(tex["sand"][0], "dcc48e", 0.3)
    wet = np.clip(sand * 0.28, 0, 1)
    edge = YY > (1.5 + np.sin(XX / U * 0.8) * 1.2 + 1) * U
    page.put((6, 1), np.where(edge[..., None], wet, oil), tex["sand"][1], wrap_y=False)

    # --- rock salt (7,1): pink-white halite cubes ---
    salt = shade(tex["ice"][0], "f0e2e2", 0.9, 1.08)
    h = np.zeros((INNER, INNER), np.float32)
    for cx, cy, s in [(1, 1, 4), (8, 2, 5), (3, 8, 4), (10, 9, 5), (6, 12, 3)]:
        box = (XX >= cx * U) & (XX < (cx + s) * U) & (YY >= cy * U) & (YY < (cy + s) * U)
        salt[box] = shade(tex["ice"][0], "e6cccc", 0.9, 1.08)[box]
        edge = box & ((np.abs(XX - cx * U) < 3) | (np.abs(YY - cy * U) < 3))
        salt[edge] = base.hexcolor("fff8f8")
        h[box] += 0.5
    page.put((7, 1), salt, base.normal_from_height(h, 3.0))

    # --- salt crust (0,2) top, (1,2) side: white crust, polygon cracks ---
    crust = shade(tex["snow"][0], "f7f6f2", 0.92, 1.05)
    cracks = np.zeros((INNER, INNER), bool)
    for x0, y0, x1, y1 in [(0, 5, 6, 3), (6, 3, 11, 6), (11, 6, 15, 4), (6, 3, 5, 10), (5, 10, 0, 12), (5, 10, 11, 13),
                           (11, 6, 11, 13), (11, 13, 15, 14), (11, 13, 9, 15)]:
        for i in range(60):
            t = i / 59.0
            cracks |= disc((x0 + (x1 - x0) * t) * U + U / 2, (y0 + (y1 - y0) * t) * U + U / 2, U * 0.35)
    top = np.where(cracks[..., None], base.hexcolor("d2cbbe"), crust)
    page.put((0, 2), top, base.normal_from_height(cracks * -0.4, 2.0))
    side = np.where((YY < 3 * U)[..., None], crust, shade(tex["ice"][0], "e6cccc", 0.9, 1.08))
    page.put((1, 2), side, tex["ice"][1], wrap_y=False)

    # --- copper (2,2) top, (3,2) side: stacked copper bars ---
    copper = shade(tex["metal"][0], "d9803a", 0.82, 1.2)
    copper_light = shade(tex["metal"][0], "f4a867", 0.82, 1.2)
    copper_dark = shade(tex["metal"][0], "a65a26", 0.82, 1.2)
    bar = np.mod(YY / U, 5.0)
    top = np.where((bar < 1)[..., None], copper_light, np.where((bar >= 4)[..., None], copper_dark, copper))
    page.put((2, 2), top, tex["metal"][1])
    row = (YY / U / 4).astype(int)
    bx = np.mod(XX / U + np.where(row % 2 == 1, 4, 0), 8)
    edge = (np.mod(YY / U, 4) < 1) | (bx < 1)
    side = np.where(edge[..., None], copper_dark, np.where((np.mod(YY / U, 4) < 2)[..., None], copper_light, copper))
    page.put((3, 2), side, base.normal_from_height(edge * -0.5, 2.0))

    # --- table salt (4,2) top, (5,2) side: a cloth sack with a blue band ---
    sack = shade(tex["cloth"][0], "f1ede4", 0.88, 1.08)
    top = np.where((R < 7 * U)[..., None], sack, sack * 0.86)
    tie = (np.abs(XX - C) < 2 * U) & (np.abs(YY - C) < 2 * U)
    top[tie] = shade(tex["cloth"][0], "c9b28a", 0.88, 1.08)[tie]
    page.put((4, 2), top, tex["cloth"][1])
    band = (YY >= 6 * U) & (YY < 11 * U)
    side = np.where(band[..., None], shade(tex["cloth"][0], "2f6fd0", 0.88, 1.08), sack)
    for gx in (5, 7, 9):
        side[disc(gx * U + U / 2, 8.5 * U, U * 0.5)] = base.hexcolor("ffffff")
    page.put((5, 2), side, tex["cloth"][1])

    # --- drums: crude oil (6,2) top, (7,2) side; kerosene (0,3) top, (1,3) side ---
    def drum(top_t, side_t, body: str, light: str, band_c: str) -> None:
        paint = shade(tex["plastic"][0], body, 0.85, 1.12)
        lit = shade(tex["plastic"][0], light, 0.85, 1.12)
        band_col = shade(tex["plastic"][0], band_c, 0.85, 1.12)
        yy = YY / U
        s = np.where(((np.abs(yy - 3.5) < 0.6) | (np.abs(yy - 12.5) < 0.6))[..., None], lit, paint)
        s = np.where(((yy >= 6) & (yy < 10))[..., None], band_col, s)
        ribs = (np.abs(yy - 3.5) < 0.6) | (np.abs(yy - 12.5) < 0.6)
        page.put(side_t, cyl(s), base.normal_from_height(ribs * 0.4, 2.0), wrap_y=False)
        t = np.where((R < 7.2 * U)[..., None], np.where((R > 6.2 * U)[..., None], lit, paint), paint * 0.8)
        steel = shade(tex["metal"][0], "b9c2cc", 0.82, 1.18)
        for bx, by in [(3.5, 4.5), (10.5, 10.5)]:
            m = disc(bx * U + U / 2, by * U + U / 2, U * 1.1)
            t[m] = steel[m]
        page.put(top_t, t, base.normal_from_height(((R > 6.2 * U) & (R < 7.2 * U)) * 0.4, 2.0), wrap_x=False, wrap_y=False)

    drum((6, 2), (7, 2), "2a2b30", "45474e", "7a4a24")
    drum((0, 3), (1, 3), "2f6fd0", "5a93ea", "f4f6f8")

    # --- plastic (2,3): little round pellets, bright colours on white ---
    pellets = shade(tex["plastic"][0], "e9f3f3", 0.92, 1.05)
    h = np.zeros((INNER, INNER), np.float32)
    for _ in range(90):
        cx, cy = rng.random() * INNER, rng.random() * INNER
        col = ["139e9b", "f4f6f8", "ffd23f", "e0413a", "5aa9f0"][rng.integers(0, 5)]
        d = np.hypot(XX - cx, YY - cy)
        pellets[d < 6.5] = base.hexcolor(col)
        pellets[(d < 2.5) & (XX < cx)] = np.clip(base.hexcolor(col) * 1.2, 0, 1)
        h[d < 6.5] += np.sqrt(np.clip(1 - (d[d < 6.5] / 6.5) ** 2, 0, 1)) * 0.5
    page.put((2, 3), pellets, base.normal_from_height(h, 3.0))

    # --- the refinery (3,3) top, (4,3) side, (5,3) bottom: a clean silver column, pipes, blue valves ---
    steel = shade(tex["metal"][0], "b9c2cc", 0.82, 1.18)
    steel_light = shade(tex["metal"][0], "dfe5ec", 0.86, 1.12)
    steel_dark = shade(tex["metal"][0], "7d8793", 0.82, 1.18)
    grate = (np.mod((XX + YY) / U, 3.0) < 1.0) & (R < 6.5 * U)
    top = np.where((R < 6.5 * U)[..., None], np.where(grate[..., None], steel_dark, steel), steel_dark)
    top[disc(C, C, U * 0.8)] = base.hexcolor("2a7fd4")
    page.put((3, 3), top, tex["metal"][1], wrap_x=False, wrap_y=False)
    xx = XX / U
    col = (xx >= 4) & (xx < 12)
    k = 1.0 - 0.3 * (((xx - 4) / 8 - 0.42) * 2.0) ** 2
    side = np.where(col[..., None], np.clip(steel_light * k[..., None], 0, 1), steel_dark)
    side = np.where((col & (np.mod(YY / U, 4) < 0.6))[..., None], steel, side)
    pipes = (np.abs(xx - 1.5) < 0.6) | (np.abs(xx - 14.5) < 0.6)
    side = np.where(pipes[..., None], steel, side)
    for vx, vy in [(1, 4), (14, 9), (1, 12)]:
        box = (np.abs(xx - vx - 0.5) < 1.5) & (YY >= vy * U) & (YY < (vy + 2) * U)
        side[box] = base.hexcolor("2a7fd4")
    plate = (xx >= 6) & (xx < 10) & (YY >= 13 * U) & (YY < 15 * U)
    side[plate] = base.hexcolor("139e9b")
    page.put((4, 3), side, base.normal_from_height((col * 0.3 + pipes * 0.2).astype(np.float32), 2.0), wrap_y=False)
    bottom = steel_dark.copy()
    for bx, by in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        bottom[disc(bx * U + U / 2, by * U + U / 2, U * 0.7)] = base.hexcolor("3b3c44")
    page.put((5, 3), bottom, tex["metal"][1])

    page.save()


if __name__ == "__main__":
    main()
