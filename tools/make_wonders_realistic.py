#!/usr/bin/env python3
"""Builds the REALISTIC twins of the world's wonders' block pages (owner #78, spec §24) from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layout as the pixel pages (tools/make_wonders_page.gd):

  data/blocks/pages/wonders_albedo.png, wonders_normal.png     page 33 (world/universes/wonders_blocks.gd TILES)
  data/blocks/pages/wonders2_albedo.png, wonders2_normal.png   page 34 (TILES_MORE)

Tiles are made like tools/make_space_realistic.py (whose Page and helpers it uses): 240 px of texture plus an 8 px
border that continues it. What the ancient wonders were built of, as real stone, metal and wood look: golden limestone
in big stones, the smooth white casing, pink granite with black and white specks, white marble with grey veins, a fluted
column and its scrolled top, a carved key-pattern band, shiny bronze, ivory, gold leaf, ebony, Babylon's yellow and blue
glazed bricks; the Lighthouse's fire, white stone blocks, paving slabs, the plaque's bronze plate, a wooden water screw
and olive leaves (cut out). Our own look (spec §3c): the patterns, joints, veins, flutes, scrolls, flowers and flames
are drawn here; the photos only give the surfaces their grain.
Sources (all CC0, already cached and credited for other pages): Rock030 (the limestone, the granite's grain, Babylon's
bricks, the paving, the plaque's stone), Plaster001 (the casing, marble, ivory, the white stone), Metal034 (bronze,
gold leaf), Wood095 (ebony, the screw), Plastic013A (the blue glaze, the fire's glow), Grass001 (the olive leaves).

Run from the project root:  PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_realistic.py   (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402
from make_space_realistic import Page, shade, tint, XX, YY, U, R  # noqa: E402

INNER = base.INNER
C = INNER / 2.0
ANG = np.arctan2(YY - C, XX - C)


def lines(img: np.ndarray, mask: np.ndarray, color: str) -> np.ndarray:
    return np.where(mask[..., None], base.hexcolor(color), img)


def joints_courses(course: float, offset_cols: list[float]) -> np.ndarray:
    """Big stones: horizontal joints every `course` px and vertical joints at x offsets per course."""
    h = np.zeros((INNER, INNER), bool)
    h |= (np.mod(YY, course) < 3.0)
    row = (YY // course).astype(int)
    for i, off in enumerate(offset_cols):
        h |= (row % len(offset_cols) == i) & (np.abs(XX - off) < 1.6)
    return h


def running_bond(rows: int, cols: int) -> np.ndarray:
    ch = INNER / rows
    cw = INNER / cols
    row = (YY // ch).astype(int)
    off = np.where(row % 2 == 1, cw / 2, 0)
    return (np.mod(YY, ch) < 4.0) | (np.mod(XX + off, cw) < 4.0)


def crack(img: np.ndarray, rng) -> np.ndarray:
    out = img.copy()
    x = C * 0.8
    for y in range(int(INNER * 0.2), int(INNER * 0.8)):
        x = float(np.clip(x + rng.normal(0, 1.2), INNER * 0.25, INNER * 0.75))
        out[y, int(x):int(x) + 2] = base.hexcolor("8f8a80")
    return out


def marble_field(tex: np.ndarray, rng) -> tuple[np.ndarray, np.ndarray]:
    img = shade(tex, "f1f0ec", 0.92, 1.05)
    height = np.zeros((INNER, INNER), np.float32)
    for v in range(4):
        y0 = rng.random() * INNER
        slope = 0.3 + rng.random() * 0.6
        yy = y0 + XX * slope + np.sin(XX / U * 0.5 + v) * U * 1.2
        d = np.abs(np.mod(YY - yy, INNER))
        vein = d < (1.5 if v else 2.5)
        img = np.where(vein[..., None], base.hexcolor("a9a9ac" if v else "8f9095"), img)
        height -= vein * 0.1
    return img, base.normal_from_height(height, 1.5)


def page33(tex: dict, rng) -> None:
    page = Page("wonders")
    # --- limestone side (0,0), top (1,0): golden rough stones with deep joints ---
    lime = tint(tex["rock"][0], "dcc58f", 0.25)
    j = joints_courses(INNER / 2, [INNER * 5 / 16, INNER * 11 / 16])
    side = lines(lime, j, "8f7a50")
    h = base.smooth_noise(4.0) * 0.4 - j * 0.8
    page.put((0, 0), side, base.normal_from_height(h.astype(np.float32), 3.0))
    top = tint(tex["rock"][0], "ead7a6", 0.25)
    jt = (np.abs(YY - C) < 1.6) | (np.abs(XX - C) < 1.6)
    page.put((1, 0), lines(top, jt, "9f8a60"), base.normal_from_height((base.smooth_noise(4.0) * 0.4 - jt * 1.0).astype(np.float32), 3.0))
    # --- casing (2,0): smooth creamy white ---
    casing = shade(tex["plaster"][0], "f3ecdc", 0.96, 1.03)
    casing = lines(casing, YY > INNER - 3, "e4dac4")
    page.put((2, 0), casing, base.flat_normal())
    # --- granite (3,0): pink with black and white crystals ---
    gran = tint(tex["rock"][0], "c9837a", 0.2)
    spots = base.smooth_noise(0.8)
    gran = np.where((spots > 0.78)[..., None], base.hexcolor("3a3032"), gran)
    gran = np.where((spots < 0.16)[..., None], base.hexcolor("efe3dc"), gran)
    page.put((3, 0), gran, base.normal_from_height((spots * 0.2).astype(np.float32), 1.5))
    # --- fake limestone side (4,0): the side with a faint crack ---
    page.put((4, 0), crack(side, rng), base.normal_from_height(h.astype(np.float32), 3.0))
    # --- marble (5,0) ---
    marble, marble_n = marble_field(tex["plaster"][0], rng)
    page.put((5, 0), marble, marble_n)
    # --- column side (6,0): flutes; top (7,0): a round section ---
    fl = np.mod(XX, INNER / 4) / (INNER / 4)
    groove = np.cos(fl * np.pi * 2) * 0.5 + 0.5
    col = shade(tex["plaster"][0], "f1f0ec", 0.95, 1.03) * (0.78 + 0.22 * groove[..., None])
    u = XX / INNER
    col = np.clip(col * (1.0 - 0.28 * ((u - 0.42) * 2.0) ** 2)[..., None], 0, 1)
    page.put((6, 0), col, base.normal_from_height((groove * 0.5).astype(np.float32), 4.0), wrap_y=True)
    ctop = shade(tex["plaster"][0], "dcdad4", 0.95, 1.03)
    inside = R < 7.0 * U
    notch = (R > 6.0 * U) & inside & (np.mod(((ANG / (2 * np.pi)) * 16 + 16).astype(int), 2) == 0)
    ctop = np.where(inside[..., None], shade(tex["plaster"][0], "f1f0ec", 0.95, 1.03), ctop)
    ctop = lines(ctop, notch, "b7b7b8")
    page.put((7, 0), ctop, base.normal_from_height((inside * 0.3 - notch * 0.2).astype(np.float32), 3.0),
             wrap_x=False, wrap_y=False)
    # --- capital side (0,1): a slab, two scrolls, the flutes below ---
    cap = shade(tex["plaster"][0], "f1f0ec", 0.95, 1.03)
    hcap = np.zeros((INNER, INNER), np.float32)
    slab = YY < 2 * U
    cap = np.where(slab[..., None], cap * 0.9, cap)
    for cx in (3.0 * U, 12.5 * U):
        cy = 6.0 * U
        d = np.hypot(XX - cx, YY - cy)
        a = np.arctan2(YY - cy, XX - cx)
        inside = d < 3.4 * U
        spiral = inside & (np.mod(d / U - a / (2 * np.pi) * 2.2, 2.2) < 0.8)
        cap = lines(cap, spiral, "9d9ea3")
        hcap += inside * 0.3 - spiral * 0.3
    below = YY > 11 * U
    cap = np.where(below[..., None], col, cap)
    page.put((0, 1), cap, base.normal_from_height(hcap, 3.0), wrap_y=False)
    # --- frieze (1,1): a key pattern between two lines ---
    fr = shade(tex["plaster"][0], "f1f0ec", 0.95, 1.03)
    key = ["########", "#......#", "#.####.#", "#.#..#.#", "#.#.##.#", "#.#....#", "#.######", "#......."]
    kx = (np.mod(XX // U, 8)).astype(int)
    ky = ((YY - 4 * U) // U).astype(int)
    mask = np.zeros((INNER, INNER), bool)
    for yy in range(8):
        for xx in range(8):
            if key[yy][xx] == "#":
                mask |= (ky == yy) & (kx == xx)
    rules = (np.abs(YY - 2.5 * U) < 0.6 * U) | (np.abs(YY - 13.5 * U) < 0.6 * U)
    fr = lines(fr, mask, "b7b7b8")
    fr = lines(fr, rules, "9d9ea3")
    page.put((1, 1), fr, base.normal_from_height((mask * 0.4 + rules * 0.2).astype(np.float32), 3.0), wrap_y=False)
    # --- fake marble side (2,1) ---
    page.put((2, 1), crack(marble, rng), marble_n)
    # --- bronze (3,1): golden-brown metal with a sheen ---
    br = tint(tex["metal"][0], "c98f3c", 0.25)
    sheen = np.exp(-((XX - 0.35 * INNER - YY * 0.25) / (0.12 * INNER)) ** 2)
    br = np.clip(br * (0.85 + 0.45 * sheen[..., None]), 0, 1)
    page.put((3, 1), br, tex["metal"][1])
    # --- ivory (4,1) ---
    iv = shade(tex["plaster"][0], "f4e8cc", 0.95, 1.04)
    page.put((4, 1), iv, base.flat_normal())
    # --- gold leaf (5,1): bright gold with folds ---
    folds = np.mod(XX + YY * 0.5, INNER / 2.6) / (INNER / 2.6)
    gold = shade(tex["metal"][0], "f2c53d", 0.85, 1.15) * (0.8 + 0.35 * np.sin(folds * np.pi)[..., None])
    page.put((5, 1), np.clip(gold, 0, 1), base.normal_from_height((np.sin(folds * np.pi) * 0.4).astype(np.float32), 3.0))
    # --- ebony side (6,1), top (7,1) ---
    eb = tint(tex["wood"][0], "2c2522", 0.15)
    page.put((6, 1), eb, tex["wood"][1])
    rings = np.sin(R / U * 2.4) * 0.5 + 0.5
    ebt = np.clip(shade(tex["wood"][0], "2c2522", 0.9, 1.1) * (0.8 + 0.4 * rings[..., None]), 0, 1)
    page.put((7, 1), ebt, base.normal_from_height((rings * 0.2).astype(np.float32), 2.0))
    # --- Babylon brick (0,2): yellow bricks in dark bitumen ---
    bond = running_bond(4, 2)
    bb = lines(shade(tex["rock"][0], "d8b56a", 0.9, 1.08), bond, "3d342c")
    bb_n = base.normal_from_height((bond * -0.5).astype(np.float32), 3.0)
    page.put((0, 2), bb, bb_n)
    # --- glazed brick side (1,2) with a flower, top (2,2) plain ---
    glaze = shade(tex["plastic"][0], "2457b8", 0.85, 1.2)
    gz = lines(glaze, bond, "10306a")
    petals = np.zeros((INNER, INNER), bool)
    for k in range(8):
        a = k * np.pi / 4
        petals |= np.hypot(XX - (C + np.cos(a) * 1.6 * U), YY - (C + np.sin(a) * 1.6 * U)) < 1.0 * U
    heart = R < 0.9 * U
    flower = lines(gz, petals, "f6e27a")
    flower = lines(flower, heart, "fbf6e6")
    page.put((1, 2), flower, bb_n)
    page.put((2, 2), gz, bb_n)
    # --- fake Babylon brick side (3,2) ---
    page.put((3, 2), crack(bb, rng), bb_n)
    page.save()


def page34(tex: dict, rng) -> None:
    page = Page("wonders2")
    # --- beacon fire side (0,0): flames; top (1,0): a bright heart ---
    hgt = (INNER - YY) / U
    tongue = np.sin(XX / U * 1.1) * 2.5 + np.sin(XX / U * 2.3 + 1.0) * 1.2
    fire = np.where((hgt < 9 + tongue)[..., None], base.hexcolor("ff9a1f"), base.hexcolor("e0621a"))
    fire = np.where((hgt < 5 + tongue * 0.6)[..., None], base.hexcolor("ffd23f"), fire)
    fire = np.where((hgt < 2)[..., None], base.hexcolor("fff6c8"), fire)
    glow = shade(tex["plastic"][0], "ffffff", 0.9, 1.08)
    page.put((0, 0), np.clip(fire * glow, 0, 1), base.flat_normal(), wrap_y=False)
    ft = np.where((R < 3 * U)[..., None], base.hexcolor("fff6c8"),
                  np.where((R < 5.5 * U)[..., None], base.hexcolor("ffd23f"), base.hexcolor("ff9a1f")))
    page.put((1, 0), np.clip(ft * glow, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    # --- white stone blocks (2,0) ---
    wj = running_bond(2, 1)
    ws = lines(shade(tex["plaster"][0], "f0ede4", 0.92, 1.05), wj, "c8c2b3")
    page.put((2, 0), ws, base.normal_from_height((wj * -0.5).astype(np.float32), 3.0))
    # --- paving top (3,0), side (4,0) ---
    pave = shade(tex["rock"][0], "d8cfbd", 0.9, 1.06)
    pj = (np.abs(YY - 9 * U) < 0.5 * U) | (XX > INNER - 0.8 * U) | ((np.abs(XX - 7 * U) < 0.5 * U) & (YY < 9 * U))
    page.put((3, 0), lines(pave, pj, "aea38c"), base.normal_from_height((pj * -0.5).astype(np.float32), 3.0))
    ps = shade(tex["rock"][0], "c3b8a2", 0.9, 1.08)
    ps = lines(ps, YY < 0.8 * U, "e6ddcb")
    page.put((4, 0), ps, tex["rock"][1], wrap_y=False)
    # --- plaque side (5,0): a bronze plate with lines and a star on grey stone; top (6,0): stone ---
    stone = tint(tex["rock"][0], "a9a8a2", 0.3)
    plate = (np.abs(XX - C) < 5.5 * U) & (np.abs(YY - C) < 5.5 * U)
    rim = plate & ~((np.abs(XX - C) < 4.8 * U) & (np.abs(YY - C) < 4.8 * U))
    pl = np.where(plate[..., None], tint(tex["metal"][0], "c98f3c", 0.25), stone)
    pl = lines(pl, rim, "8f5f25")
    writing = plate & ~rim & ((np.abs(YY - 8.5 * U) < 0.4 * U) | (np.abs(YY - 10.5 * U) < 0.4 * U)) & (np.abs(XX - C) < 3.8 * U)
    pl = lines(pl, writing, "6f4a1c")
    star = (np.hypot(XX - C, YY - 5 * U) < 1.2 * U)
    pl = lines(pl, star, "efc06a")
    page.put((5, 0), pl, base.normal_from_height((plate * 0.4 - writing * 0.3).astype(np.float32), 3.0),
             wrap_x=False, wrap_y=False)
    page.put((6, 0), stone, tex["rock"][1])
    # --- water screw side (7,0), end (0,1) ---
    band = np.mod(XX + YY * 1.3, INNER * 6 / 16) < INNER * 2 / 16
    wood = tint(tex["wood"][0], "a4733f", 0.3)
    sc = np.where(band[..., None], wood * 0.65, wood)
    uu = XX / INNER
    sc = np.clip(sc * (1.0 - 0.3 * ((uu - 0.42) * 2.0) ** 2)[..., None], 0, 1)
    page.put((7, 0), sc, base.normal_from_height((band * 0.5).astype(np.float32), 3.0))
    arm = np.mod(ANG / (2 * np.pi) * 3.0 + R / U * 0.25, 1.0) < 0.3
    end = np.where((R < 7 * U)[..., None], np.where(arm[..., None], wood * 0.6, tint(tex["wood"][0], "c28d52", 0.3)),
                   wood * 0.6)
    page.put((0, 1), end, base.flat_normal(), wrap_x=False, wrap_y=False)
    # --- olive leaves (1,1): silvery-green leaves with gaps (cut out), a few olives ---
    holes = base.smooth_noise(2.0)
    leaves = tint(tex["leaves"][0], "8fa77a", 0.35) * np.array([0.95, 1.0, 0.9])
    silver = (base.smooth_noise(1.2) > 0.6)
    leaves = np.where(silver[..., None], leaves * 1.2, leaves)
    alpha = (holes > 0.4).astype(np.float32)
    olives = np.zeros((INNER, INNER), bool)
    for _ in range(6):
        olives |= np.hypot(XX - rng.random() * INNER, YY - rng.random() * INNER) < 0.8 * U
    leaves = lines(leaves, olives, "3f4a2c")
    alpha[olives] = 1.0
    page.put((1, 1), np.clip(leaves, 0, 1), tex["leaves"][1], alpha)
    page.save()


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"rock": "Rock030", "plaster": "Plaster001", "metal": "Metal034",
                                         "wood": "Wood095", "plastic": "Plastic013A",
                                         "leaves": "Grass001"}.items()}
    rng = np.random.default_rng(20260933)
    page33(tex, rng)
    page34(tex, rng)


if __name__ == "__main__":
    main()
