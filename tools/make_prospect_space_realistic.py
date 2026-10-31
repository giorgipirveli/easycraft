#!/usr/bin/env python3
"""Builds the REALISTIC twin of the riches of space's block page (spec §26.5, owner #80) from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layout as the pixel page (tools/make_prospect_space_page.gd):

  data/blocks/pages/prospect_space_albedo.png, prospect_space_normal.png   page 39 (data/blocks/prospect_space_page.gd)

Tiles are made like tools/make_prospect_realistic.py (whose helpers it shares: tools/make_space_realistic.py's Page and
tint/shade): 240 px of texture plus an 8 px border that continues it. What a child learns to read, as the real things
look: the Moon's grey dust frozen with ice (frost glints), the dark seas' bluish-grey dust, black ilmenite blades in
basalt, pale speckled KREEP rock, an iron meteorite's cut face and its dark crust; Mars's white ground ice with red dust,
red dust strewn with grey hematite "blueberries", layered hematite rock, dark sand, a pale cracked salt crust; then an
oxygen tank, a frosty tank of hydrogen fuel, titanium bars, a tray of pastel rare-earth powders, a silver flask of
helium-3 and the Solar Oven (a dish of mirrors, a warm window).
Sources (all CC0, already used by other pages and credited): Snow004 (moon dust, frost), Snow003 (Mars's ice), Rock030
(moon rock, KREEP rock), Rock031 (basalt), Rock035 (the dark seas' dust), Ground103 (Mars's red dust), Ground097 (the
dark sand's grains), Ground079L (hematite's layers), Ice001 (the salt crust), Ice002 (ice veins), Metal034 (the
meteorite's metal, titanium, the flask, the oven's frame and mirrors), Plastic013A (the tanks' paint, the tray).
Everything else (glints, blades, specks, crossing lines, pits, spheres, cracks, bands, the "3", the window) is drawn here.

Run from the project root:  python3 tools/make_prospect_space_realistic.py   (needs Pillow + numpy)
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
ANG = np.arctan2(YY - C, XX - C)


def flat(hex_color: str) -> np.ndarray:
    return np.broadcast_to(base.hexcolor(hex_color), (INNER, INNER, 3)).astype(np.float32).copy()


def specks(img: np.ndarray, rng, n: int, color: str, r_lo: float, r_hi: float, height=None) -> None:
    """Little bits of `color` with a lit edge; raises `height` where they are."""
    c = base.hexcolor(color)
    light = np.clip(c * 1.25, 0, 1)
    for _ in range(n):
        cx, cy, r = rng.random() * INNER, rng.random() * INNER, r_lo + rng.random() * (r_hi - r_lo)
        d = np.hypot(XX - cx, YY - cy)
        img[d < r] = c
        img[(d < r * 0.5) & (XX < cx)] = light
        if height is not None:
            height[d < r] += 0.6


def spheres(img: np.ndarray, height: np.ndarray, spots, r: float, color: str) -> None:
    """Little grey balls (hematite "blueberries") lit from the top left, raised in `height`."""
    c = base.hexcolor(color)
    for sx, sy in spots:
        cx, cy = sx * U + U / 2, sy * U + U / 2
        d = np.hypot(XX - cx, YY - cy)
        m = d < r
        lit = np.clip(1.15 - ((XX - cx) + (YY - cy)) / (r * 2.2), 0.55, 1.3)
        img[m] = np.clip(c * lit[m][..., None], 0, 1)
        height[m] += np.sqrt(np.clip(1 - (d[m] / r) ** 2, 0, 1)) * 0.8


def cyl(color: np.ndarray) -> np.ndarray:
    """A tank's side: lit in the middle, darker to its edges."""
    u = XX / INNER
    k = 1.0 - 0.3 * ((u - 0.42) * 2.0) ** 2
    return np.clip(color * k[..., None], 0, 1)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow004", "ice": "Snow003", "rock": "Rock030", "basalt": "Rock031",
                                         "dark": "Rock035", "red": "Ground103", "pebbles": "Ground097",
                                         "layers": "Ground079L", "salt": "Ice001", "veins": "Ice002",
                                         "metal": "Metal034", "plastic": "Plastic013A"}.items()}
    rng = np.random.default_rng(20260939)
    page = Page("prospect_space")

    # --- icy regolith (0,0) top, (1,0) side: dark grey crater-floor dust frozen with ice, frost glints ---
    grey = tint(tex["snow"][0], "6c7079", 0.25)
    h = np.zeros((INNER, INNER), np.float32)
    top = grey.copy()
    specks(top, rng, 70, "eef6ff", 1.5, 4.0, h)
    specks(top, rng, 30, "cfe4f7", 1.0, 3.0, h)
    page.put((0, 0), top, np.clip(tex["snow"][1] * 0.7 + base.normal_from_height(h, 2.0) * 0.3, 0, 1))
    w = np.sin(XX / U * 0.8 + YY / U * 0.35) + 0.7 * np.sin(YY / U * 1.3 - XX / U * 0.4)
    veins = shade(tex["veins"][0], "cfe4f7", 0.9, 1.1)
    side = np.where((w > 1.05)[..., None], veins, np.where((w > 0.8)[..., None], tint(tex["snow"][0], "b4b8c0", 0.3), grey))
    specks(side, rng, 16, "eef6ff", 1.5, 3.0)
    page.put((1, 0), side, tex["snow"][1])

    # --- mare dust (2,0) top, (3,0) side: the dark seas' fine bluish-grey dust, a few black grains ---
    mare = tint(tex["dark"][0], "4a4f5c", 0.2)
    top = mare.copy()
    specks(top, rng, 12, "1c1d22", 1.0, 2.5)
    page.put((2, 0), top, tex["dark"][1])
    side = np.where((np.mod(YY / U, 5.0) >= 4.0)[..., None], mare * 0.82, mare)
    specks(side, rng, 10, "1c1d22", 1.0, 2.5)
    page.put((3, 0), side, tex["dark"][1])

    # --- ilmenite (4,0): black glossy blades packed in dark basalt ---
    basalt = tint(tex["basalt"][0], "3c3f46", 0.3)
    h = np.zeros((INNER, INNER), np.float32)
    ilm = basalt.copy()
    for _ in range(26):
        cx, cy = rng.random() * INNER, rng.random() * INNER
        horizontal = rng.random() < 0.5
        length = (2 + rng.random() * 3) * U
        wide = U * (0.5 + rng.random() * 0.4)
        m = (np.abs(XX - cx) < (length / 2 if horizontal else wide)) & (np.abs(YY - cy) < (wide if horizontal else length / 2))
        ilm[m] = base.hexcolor("1c1d22")
        glint = m & (np.abs((XX - cx) - (YY - cy)) < U * 0.4)
        ilm[glint] = base.hexcolor("6b6f7e")
        h[m] += 0.5
    page.put((4, 0), ilm, np.clip(tex["basalt"][1] * 0.6 + base.normal_from_height(h, 2.0) * 0.4, 0, 1))

    # --- KREEP rock (5,0): pale speckled rock, rusty-brown and dark bits ---
    kreep = tint(tex["rock"][0], "b9ad98", 0.3)
    h = np.zeros((INNER, INNER), np.float32)
    specks(kreep, rng, 30, "9a6a44", 2.0, 6.0, h)
    specks(kreep, rng, 40, "3e3a36", 1.0, 3.0)
    page.put((5, 0), kreep, np.clip(tex["rock"][1] * 0.8 + base.normal_from_height(h, 2.0) * 0.2, 0, 1))

    # --- iron meteorite (6,0) cut face, (7,0) crust: crossing lines in polished metal; a dark crust with pits ---
    metal = shade(tex["metal"][0], "a9adb4", 0.85, 1.15)
    lines = (np.mod((XX + YY) / U, 5.0) < 0.5) | (np.mod((XX - YY) / U + 32, 6.0) < 0.5)
    face = np.where(lines[..., None], shade(tex["metal"][0], "7d828b", 0.85, 1.15), metal)
    rind = (XX < U) | (YY < U) | (XX > INNER - U) | (YY > INNER - U)
    face[rind] = base.hexcolor("3a2f2a")
    page.put((6, 0), face, base.normal_from_height((lines * -0.2 + rind * -0.5).astype(np.float32), 2.0),
             wrap_x=False, wrap_y=False)
    crust = tint(tex["basalt"][0], "3a2f2a", 0.25)
    h = np.zeros((INNER, INNER), np.float32)
    for sx, sy in [(3, 3), (10, 4), (6, 9), (12, 12), (2, 12), (13, 1)]:
        d = np.hypot(XX - sx * U - U / 2, YY - sy * U - U / 2)
        m = d < 2.2 * U
        crust[m] = np.clip(crust[m] * 0.7, 0, 1)
        h[m] -= np.clip(1 - d[m] / (2.2 * U), 0, 1) * 0.8
    page.put((7, 0), crust, np.clip(tex["basalt"][1] * 0.5 + base.normal_from_height(h, 3.0) * 0.5, 0, 1))

    # --- ground ice (0,1) top, (1,1) side: white ice with red dust; layers with dusty bands ---
    ice = shade(tex["ice"][0], "f2f5f8", 0.9, 1.06)
    dust = tint(tex["red"][0], "d98a58", 0.3)
    top = ice.copy()
    specks(top, rng, 16, "d98a58", 1.5, 4.0)
    page.put((0, 1), top, tex["ice"][1])
    band = np.mod((YY / U + np.sin(XX / U * 0.6) * 0.8), 6.0)
    side = np.where((band < 4)[..., None], ice, np.where((band < 5)[..., None], ice * 0.9, dust))
    page.put((1, 1), side, base.normal_from_height(((band >= 5) * 0.3).astype(np.float32), 2.0))

    # --- blueberry soil (2,1) top, (3,1) side: red dust strewn with grey hematite spheres ---
    red = tint(tex["red"][0], "c46a3c", 0.3)
    h = np.zeros((INNER, INNER), np.float32)
    top = red.copy()
    spheres(top, h, [(2, 2), (7, 1), (12, 3), (4, 7), (10, 8), (1, 12), (6, 12), (13, 13), (8, 5), (14, 8)], U * 1.1, "5b5f6b")
    page.put((2, 1), top, np.clip(tex["red"][1] * 0.5 + base.normal_from_height(h, 3.0) * 0.5, 0, 1))
    h = np.zeros((INNER, INNER), np.float32)
    side = np.where((YY < 2 * U)[..., None], red, red * 0.82)
    spheres(side, h, [(3, 5), (11, 7), (6, 12), (13, 13)], U * 1.1, "5b5f6b")
    page.put((3, 1), side, np.clip(tex["red"][1] * 0.5 + base.normal_from_height(h, 3.0) * 0.5, 0, 1), wrap_y=False)

    # --- hematite (4,1) side, (5,1) top: layered pale-red rock full of grey spheres ---
    layers = tint(tex["layers"][0], "a86a52", 0.25)
    k = np.mod((YY / U + np.sin(XX / U * 0.4)), 4.0)
    side = np.where((k < 2)[..., None], layers, np.where((k < 3)[..., None], layers * 0.84,
                                                          tint(tex["layers"][0], "c8977e", 0.25)))
    h = ((k >= 2) & (k < 3)).astype(np.float32) * -0.2
    spheres(side, h, [(3, 3), (10, 2), (7, 8), (2, 12), (12, 11)], U * 1.1, "5b5f6b")
    page.put((4, 1), side, base.normal_from_height(h, 2.5))
    h = np.zeros((INNER, INNER), np.float32)
    top = layers.copy()
    spheres(top, h, [(2, 3), (8, 2), (13, 5), (5, 8), (11, 11), (3, 13), (9, 14)], U * 1.1, "5b5f6b")
    page.put((5, 1), top, np.clip(tex["layers"][1] * 0.5 + base.normal_from_height(h, 3.0) * 0.5, 0, 1))

    # --- dark sand (6,1) top, (7,1) side: near-black iron-rich grains, a few glints, wind ripples ---
    sand = tint(tex["pebbles"][0], "2c2a2c", 0.2)
    ripple = np.mod(YY / U + np.sin(XX / U * 0.5) * 1.5, 5.0) < 0.8
    top = np.where(ripple[..., None], sand * 1.35, sand)
    specks(top, rng, 30, "8a8a96", 0.8, 2.0)
    page.put((6, 1), np.clip(top, 0, 1), np.clip(tex["pebbles"][1] * 0.7 + base.normal_from_height(ripple * 0.3, 2.0) * 0.3, 0, 1))
    side = sand.copy()
    specks(side, rng, 20, "8a8a96", 0.8, 2.0)
    side[YY > 15 * U] = base.hexcolor("9c4f2c")
    page.put((7, 1), side, tex["pebbles"][1], wrap_y=False)

    # --- Mars salt (0,2) top, (1,2) side: a pale crust with cracks, over the red ground ---
    salt = shade(tex["salt"][0], "f0e6e2", 0.92, 1.05)
    cracks = np.zeros((INNER, INNER), bool)
    for x0, y0, x1, y1 in [(0, 4, 5, 6), (5, 6, 10, 3), (10, 3, 15, 5), (5, 6, 6, 11), (6, 11, 0, 13), (6, 11, 12, 12),
                           (10, 3, 12, 12), (12, 12, 15, 14)]:
        for i in range(60):
            t = i / 59.0
            cracks |= disc((x0 + (x1 - x0) * t) * U + U / 2, (y0 + (y1 - y0) * t) * U + U / 2, U * 0.35)
    page.put((0, 2), np.where(cracks[..., None], base.hexcolor("c9aea4"), salt), base.normal_from_height(cracks * -0.4, 2.0))
    side = np.where((YY < 5 * U)[..., None], salt, np.where((YY < 9 * U)[..., None],
                                                             shade(tex["salt"][0], "e5cfc8", 0.9, 1.06), red * 0.82))
    page.put((1, 2), side, tex["salt"][1], wrap_y=False)

    # --- tanks: oxygen (3,2) top, (2,2) side; hydrogen fuel (5,2) top, (4,2) side (frost on its cold foot) ---
    steel_dark = shade(tex["metal"][0], "7d8793", 0.82, 1.18)

    def tank(top_t, side_t, body: str, shade_c: str, band_c: str, frost: bool) -> None:
        paint = shade(tex["plastic"][0], body, 0.88, 1.1)
        dim = shade(tex["plastic"][0], shade_c, 0.88, 1.1)
        band_col = shade(tex["plastic"][0], band_c, 0.88, 1.1)
        yy = YY / U
        s = np.where(((yy < 2) | (yy >= 14))[..., None], dim, paint)
        s = np.where(((yy >= 6) & (yy < 9))[..., None], band_col, s)
        s = cyl(s)
        if frost:
            fr = (yy > 9) & (base.smooth_noise(2.0) > 0.62)
            s[fr] = base.hexcolor("e3f3fc")
        page.put(side_t, s, base.normal_from_height((((yy >= 6) & (yy < 9)) * 0.2).astype(np.float32), 2.0), wrap_y=False)
        t = np.where((R < 7.2 * U)[..., None], np.where((R > 6.2 * U)[..., None], dim, paint), dim)
        valve = (np.abs(XX - C) < 2 * U) & (np.abs(YY - C) < 2 * U)
        t[valve] = steel_dark[valve]
        cap = (np.abs(XX - C) < U) & (np.abs(YY - C) < U)
        t[cap] = base.hexcolor(band_c)
        page.put(top_t, t, base.normal_from_height(((R > 6.2 * U) & (R < 7.2 * U)) * 0.4 + valve * 0.3, 2.0),
                 wrap_x=False, wrap_y=False)

    tank((3, 2), (2, 2), "eef1f4", "c9cfd6", "139e9b", False)
    tank((5, 2), (4, 2), "bfe0f5", "8fbfe0", "f08a1c", True)

    # --- titanium (6,2) top, (7,2) side: stacked silvery-grey bars ---
    ti = shade(tex["metal"][0], "9ea3ab", 0.84, 1.18)
    ti_light = shade(tex["metal"][0], "c8ccd3", 0.84, 1.18)
    ti_dark = shade(tex["metal"][0], "6e737c", 0.84, 1.18)
    bar = np.mod(YY / U, 4.0)
    page.put((6, 2), np.where((bar < 1)[..., None], ti_light, np.where((bar >= 3)[..., None], ti_dark, ti)), tex["metal"][1])
    row = (YY / U / 4).astype(int)
    bx = np.mod(XX / U + np.where(row % 2 == 1, 4, 0), 8)
    edge = (np.mod(YY / U, 4) < 1) | (bx < 1)
    side = np.where(edge[..., None], ti_dark, np.where((np.mod(YY / U, 4) < 2)[..., None], ti_light, ti))
    page.put((7, 2), side, base.normal_from_height(edge * -0.5, 2.0))

    # --- rare earths (0,3) top, (1,3) side: a tray of pastel powders; a crate of jars ---
    tray_edge = shade(tex["plastic"][0], "a9b0b9", 0.9, 1.08)
    powders = ["c9b6e4", "f2c5d0", "cfe7c4", "f4e3a6", "a9c8ec", "e7e2da"]
    top = tray_edge.copy()
    h = np.zeros((INNER, INNER), np.float32)
    for i, col in enumerate(powders):
        cx0, cy0 = (1 + (i % 3) * 5) * U, (1 + (i // 3) * 7) * U
        m = (XX >= cx0) & (XX < cx0 + 4 * U) & (YY >= cy0) & (YY < cy0 + 6 * U)
        top[m] = shade(tex["snow"][0], col, 0.92, 1.06)[m]
        h[m] += 0.3
    page.put((0, 3), top, base.normal_from_height(h, 2.0), wrap_x=False, wrap_y=False)
    side = shade(tex["plastic"][0], "dfe3e8", 0.9, 1.08)
    side[(YY < U) | (YY > 15 * U)] = base.hexcolor("a9b0b9")
    for i in range(3):
        x0 = (1 + i * 5) * U
        jar = (XX >= x0) & (XX < x0 + 4 * U) & (YY >= 4 * U) & (YY < 13 * U)
        side[jar] = base.hexcolor("f4f7fa")
        fill = jar & (YY >= 7 * U)
        side[fill] = shade(tex["snow"][0], powders[i * 2], 0.92, 1.06)[fill]
        lid = (XX >= x0) & (XX < x0 + 4 * U) & (YY >= 3 * U) & (YY < 4 * U)
        side[lid] = steel_dark[lid]
    page.put((1, 3), side, tex["plastic"][1], wrap_y=False)

    # --- helium-3 (2,3) side, (3,3) top: a silver flask with a teal band and a "3" ---
    flask = shade(tex["metal"][0], "c3c8cf", 0.86, 1.14)
    yy = YY / U
    side = np.where((yy < 2)[..., None], shade(tex["metal"][0], "8d939c", 0.86, 1.14), flask)
    side = np.where(((yy >= 3) & (yy < 5))[..., None], shade(tex["plastic"][0], "139e9b", 0.9, 1.08), side)
    side = cyl(side)
    three = np.zeros((INNER, INNER), bool)
    for px, py in [(6, 7), (7, 7), (8, 7), (9, 8), (7, 9), (8, 9), (9, 10), (6, 11), (7, 11), (8, 11)]:
        three |= (XX >= px * U) & (XX < (px + 1) * U) & (YY >= py * U) & (YY < (py + 1) * U)
    side[three] = base.hexcolor("0c7876")
    page.put((2, 3), side, base.normal_from_height(three * -0.3, 2.0), wrap_y=False)
    top = np.where((R < 7.2 * U)[..., None], np.where((R < 3 * U)[..., None], shade(tex["metal"][0], "e6e9ed", 0.9, 1.1),
                                                       flask), shade(tex["metal"][0], "8d939c", 0.86, 1.14))
    top[(np.abs(XX - C) < U) & (np.abs(YY - C) < U)] = base.hexcolor("139e9b")
    page.put((3, 3), top, base.normal_from_height(((R > 6.2 * U) & (R < 7.2 * U)) * 0.4, 2.0), wrap_x=False, wrap_y=False)

    # --- the Solar Oven (4,3) top, (5,3) side, (6,3) bottom: a dish of mirrors; a white box with a warm window ---
    mirror = shade(tex["metal"][0], "dfe9f2", 0.92, 1.1)
    mirror_dark = shade(tex["metal"][0], "9fb3c4", 0.9, 1.1)
    seg = (((ANG + np.pi) / (2 * np.pi) * 8).astype(int)) % 2
    top = np.where((R < 7.4 * U)[..., None], np.where((seg == 0)[..., None], mirror, mirror_dark),
                   shade(tex["plastic"][0], "aeb6bf", 0.9, 1.08))
    top[R < 1.6 * U] = base.hexcolor("ffffff")
    page.put((4, 3), top, base.normal_from_height(((R < 7.4 * U) * (R / (7.4 * U)) * 0.4).astype(np.float32), 2.0),
             wrap_x=False, wrap_y=False)
    side = shade(tex["plastic"][0], "eceff2", 0.9, 1.06)
    border = (XX < U) | (YY < U) | (XX > 15 * U) | (YY > 15 * U)
    side[border] = base.hexcolor("aeb6bf")
    frame = (XX >= 3 * U) & (XX < 13 * U) & (YY >= 5 * U) & (YY < 12 * U)
    side[frame] = steel_dark[frame]
    window = (XX >= 4 * U) & (XX < 12 * U) & (YY >= 6 * U) & (YY < 11 * U)
    glow = np.clip(1.0 - np.hypot(XX - 6.5 * U, YY - 8 * U) / (7 * U), 0, 1)[..., None]
    warm = np.clip(base.hexcolor("ffb347") * (1 - glow) + base.hexcolor("ffe29a") * glow, 0, 1)
    side[window] = warm[window]
    plate = (XX >= 5 * U) & (XX < 11 * U) & (YY >= 13 * U) & (YY < 14 * U)
    side[plate] = base.hexcolor("139e9b")
    page.put((5, 3), side, base.normal_from_height((frame * 0.3 - window * 0.2 + border * 0.2).astype(np.float32), 2.0),
             wrap_y=False)
    bottom = steel_dark.copy()
    for bx, by in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        bottom[disc(bx * U + U / 2, by * U + U / 2, U * 0.7)] = base.hexcolor("241d1a")
    page.put((6, 3), bottom, tex["metal"][1])

    page.save()


if __name__ == "__main__":
    main()
