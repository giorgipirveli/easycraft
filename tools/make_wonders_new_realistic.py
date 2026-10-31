#!/usr/bin/env python3
"""Builds the REALISTIC twins of the New Seven Wonders' block pages (owner #78, spec §24, the second tour) from CC0
textures (ambientCG, https://ambientcg.com), in the same 8x8 layout as the pixel pages (tools/make_wonders_new_page.gd):

  data/blocks/pages/wonders3_albedo.png, wonders3_normal.png   page 36 (world/universes/wonders_blocks.gd TILES_NEW)
  data/blocks/pages/wonders4_albedo.png, wonders4_normal.png   page 37 (TILES_NEW_MORE)

Tiles are made like tools/make_wonders_realistic.py (tools/make_space_realistic.py's Page and helpers): 240 px of
texture plus an 8 px border that continues it. What the New Seven were built of, as real stone looks: the Great Wall's
long grey bricks and its walkway, Petra's rose rock with swirling bands, its smooth carved stone and a column, the
Colosseum's cream travertine with its tiny holes, Chichen Itza's pale limestone, a carved step pattern, the serpent's
head and the red jaguar throne with jade spots, Machu Picchu's fitted granite, Christ the Redeemer's soapstone tiles,
the Taj Mahal's white marble inlaid with a flower of coloured stones; page 37 the Taj Mahal's gate's red sandstone
with white marble lines and page 34's white stone (copied from its realistic page) with a crack. Our own look (spec
§3c): the bonds, joints, bands, holes, patterns, eyes, spots, tiles and flowers are drawn here; the photos only give
the surfaces their grain.
Sources (all CC0, already cached and credited for other pages): Bricks084 (the wall's bricks), Rock030 (the rose rock,
the Maya stone, the Inca granite), Rock029 (the rose rock's grain), Plaster001 (travertine, the carved stone, soapstone,
marble), Ground037 (the jaguar's painted stone), Metal034 (the inlay's shine).

Page 37's rows 1-3 are the third tour's (the Seven Natural Wonders): this script writes a fresh page 37, so run
tools/make_wonders_nature_realistic.py after it.

Run from the project root:  PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_new_realistic.py   (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402
from make_space_realistic import Page, shade, tint, XX, YY, U, R  # noqa: E402

INNER = base.INNER
C = INNER / 2.0
ANG = np.arctan2(YY - C, XX - C)
DIR = "data/blocks/pages/"


def lines(img: np.ndarray, mask: np.ndarray, color: str) -> np.ndarray:
    return np.where(mask[..., None], base.hexcolor(color), img)


def running_bond(rows: int, cols: int, joint: float = 4.0) -> np.ndarray:
    ch = INNER / rows
    cw = INNER / cols
    row = (YY // ch).astype(int)
    off = np.where(row % 2 == 1, cw / 2, 0)
    return (np.mod(YY, ch) < joint) | (np.mod(XX + off, cw) < joint)


def crack(img: np.ndarray, rng) -> np.ndarray:
    out = img.copy()
    x = C * 0.8
    for y in range(int(INNER * 0.2), int(INNER * 0.8)):
        x = float(np.clip(x + rng.normal(0, 1.2), INNER * 0.25, INNER * 0.75))
        out[y, int(x):int(x) + 2] = base.hexcolor("6f6a60")
    return out


def page36(tex: dict, rng) -> None:
    page = Page("wonders3")
    # --- wall brick side (0,0): long grey bricks in lime mortar; top (1,0): the walkway's bricks laid flat ---
    bond = running_bond(4, 2)
    wall = lines(tint(tex["bricks"][0], "8f9296", 0.2), bond, "c3c1ba")
    wall_n = base.normal_from_height((bond * -0.6 + base.smooth_noise(3.0) * 0.2).astype(np.float32), 3.0)
    page.put((0, 0), wall, wall_n)
    flat_bond = running_bond(8, 4, 3.0)
    walk = lines(shade(tex["bricks"][0], "a3a5a8", 0.88, 1.08), flat_bond, "bdbbb4")
    page.put((1, 0), walk, base.normal_from_height((flat_bond * -0.5).astype(np.float32), 3.0))
    page.put((2, 0), crack(wall, rng), wall_n)
    # --- rose rock side (3,0): swirling bands; top (4,0) ---
    w = YY / U + np.sin(XX / U * 2 * np.pi / 16) * 1.6 + np.sin(XX / U * 2 * np.pi / 8 + 1.3) * 0.8   # bands meet across blocks
    band = (np.floor(w / 2.0).astype(int)) % 8
    colors = ["c9786a", "e2a08c", "9c4f47", "ecc9a8", "c9786a", "8a4a5a", "e2a08c", "c9786a"]
    rose = np.zeros((INNER, INNER, 3), np.float32)
    for i, col in enumerate(colors):
        rose = np.where((band == i)[..., None], shade(tex["rock2"][0], col, 0.85, 1.08), rose)
    page.put((3, 0), rose, base.normal_from_height((np.sin(w * np.pi) * 0.15 + base.smooth_noise(2.0) * 0.3)
                                                   .astype(np.float32), 3.0))
    page.put((4, 0), tint(tex["rock2"][0], "c9786a", 0.25), tex["rock2"][1])
    # --- rose stone (5,0): smooth carved stone with chisel strokes ---
    chisel = np.mod(XX + YY * 2, 7 * U) < 0.6 * U
    rs = shade(tex["plaster"][0], "d48d78", 0.9, 1.06)
    rs = np.where(chisel[..., None], rs * 0.95, rs)
    page.put((5, 0), rs, base.normal_from_height((chisel * -0.15).astype(np.float32), 2.0))
    # --- rose column side (6,0): round and shaded, leafy top band; top (7,0): a round section ---
    u = XX / INNER
    col = shade(tex["plaster"][0], "d48d78", 0.92, 1.05)
    leaves = (YY < 3 * U) & (np.mod(XX + YY, 3 * U) < 1.2 * U)
    col = np.where(leaves[..., None], base.hexcolor("e2a08c") * 0.95, col)
    col = np.clip(col * (1.0 - 0.3 * ((u - 0.42) * 2.0) ** 2)[..., None], 0, 1)
    page.put((6, 0), col, base.normal_from_height((leaves * 0.3).astype(np.float32), 3.0), wrap_y=False)
    inside = R < 7.0 * U
    ctop = np.where(inside[..., None], shade(tex["plaster"][0], "d48d78", 0.92, 1.05),
                    shade(tex["plaster"][0], "9c4f47", 0.9, 1.05))
    page.put((7, 0), ctop, base.normal_from_height((inside * 0.3).astype(np.float32), 3.0), wrap_x=False, wrap_y=False)
    # --- travertine side (0,1): cream blocks with tiny holes; top (1,1) ---
    holes = base.smooth_noise(0.9) > 0.8
    tj = (np.mod(YY, INNER / 2) < 3.0) | ((np.mod(XX + np.where(YY >= INNER / 2, INNER / 2, 0), INNER) < 3.0))
    trav = shade(tex["plaster"][0], "e6d9bc", 0.9, 1.06)
    trav = lines(trav, holes, "9c8a66")
    trav = lines(trav, tj, "c9b894")
    trav_n = base.normal_from_height((holes * -0.5 - tj * 0.4).astype(np.float32), 3.0)
    page.put((0, 1), trav, trav_n)
    ttop = lines(shade(tex["plaster"][0], "ebe0c7", 0.9, 1.06), base.smooth_noise(0.9) > 0.82, "9c8a66")
    page.put((1, 1), ttop, trav_n)
    page.put((2, 1), crack(trav, rng), trav_n)
    # --- Maya stone side (3,1), top (4,1) ---
    mj = (np.mod(YY, INNER * 5 / 16) < 3.0) | (np.mod(XX + np.where((YY // (INNER * 5 / 16)).astype(int) % 2 == 1,
                                                                   INNER * 5 / 16, 0), INNER * 10 / 16) < 3.0)
    maya = lines(shade(tex["rock"][0], "cfc9bd", 0.85, 1.08), mj, "a39d91")
    lichen = base.smooth_noise(1.5) > 0.82
    maya = np.where(lichen[..., None], maya * 0.8, maya)
    maya_n = base.normal_from_height((mj * -0.5 + base.smooth_noise(3.0) * 0.2).astype(np.float32), 3.0)
    page.put((3, 1), maya, maya_n)
    page.put((4, 1), shade(tex["rock"][0], "d6d1c6", 0.85, 1.08), tex["rock"][1])
    # --- Maya carving side (5,1): a step-and-hook pattern between two lines ---
    fret = ["........", ".######.", ".#....#.", ".#.##.#.", ".#.#..#.", ".#.####.", ".#......", "##......"]
    kx = (np.mod(XX // U, 8)).astype(int)
    ky = ((YY - 4 * U) // U).astype(int)
    mask = np.zeros((INNER, INNER), bool)
    for yy in range(8):
        for xx in range(8):
            if fret[yy][xx] == "#":
                mask |= (ky == yy) & (kx == xx)
    rules = (np.abs(YY - 1.5 * U) < 0.5 * U) | (np.abs(YY - 14.5 * U) < 0.5 * U)
    carve = lines(lines(shade(tex["rock"][0], "cfc9bd", 0.85, 1.08), mask, "7f7a70"), rules, "7f7a70")
    page.put((5, 1), carve, base.normal_from_height(((mask | rules) * -0.5).astype(np.float32), 3.0), wrap_y=False)
    page.put((6, 1), crack(maya, rng), maya_n)
    # --- serpent head side (7,1): eyes, feathers over them, open jaws with fangs ---
    head = shade(tex["rock"][0], "cfc9bd", 0.85, 1.08)
    hh = np.zeros((INNER, INNER), np.float32)
    feathers = (YY < 2.5 * U) & (np.mod(XX, 3 * U) < 1.5 * U)
    head = lines(head, feathers, "a39d91")
    for ex in (3.5 * U, 12.5 * U):
        eye = np.hypot(XX - ex, YY - 5.5 * U) < 1.6 * U
        pupil = np.hypot(XX - ex, YY - 5.5 * U) < 0.6 * U
        head = lines(lines(head, eye, "f4efe2"), pupil, "2f2a26")
        hh += eye * 0.4
    jaws = (XX > 2 * U) & (XX < 14 * U) & (YY > 9 * U) & (YY < 14 * U)
    head = lines(head, jaws, "b8453a")
    fangs = jaws & (np.mod(XX, 3 * U) < 1.0 * U) & ((YY < 10.8 * U) | (YY > 12.2 * U))
    head = lines(head, fangs, "f4efe2")
    hh -= jaws * 0.5
    page.put((7, 1), head, base.normal_from_height(hh, 3.0), wrap_x=False, wrap_y=False)
    # --- jaguar throne side (0,2): red with jade spots, fangs at the foot; top (1,2) ---
    jag = shade(tex["ground"][0], "b8322a", 0.85, 1.1)
    spots = np.zeros((INNER, INNER), bool)
    for _ in range(9):
        spots |= np.hypot(XX - rng.random() * INNER, YY - rng.random() * INNER) < 0.9 * U
    jag = lines(jag, spots, "3fae7a")
    teeth = (YY > 15 * U) & (np.mod(XX, 2 * U) < U) & (XX > 4 * U) & (XX < 12 * U)
    page.put((0, 2), lines(jag, teeth, "f4efe2"), base.normal_from_height((spots * 0.4).astype(np.float32), 3.0),
             wrap_y=False)
    jt = lines(shade(tex["ground"][0], "a52c25", 0.85, 1.1), spots, "3fae7a")
    page.put((1, 2), jt, base.normal_from_height((spots * 0.4).astype(np.float32), 3.0))
    # --- Inca stone side (2,2): grey granite blocks fitted like a puzzle; top (3,2) ---
    joints = np.zeros((INNER, INNER), bool)
    for (x0, y0, x1, y1) in [(0, 5, 16, 5), (0, 11, 16, 11), (6, 0, 6, 5), (11, 5, 13, 11), (4, 11, 3, 16),
                             (10, 11, 10, 16), (2, 5, 1, 11)]:
        a = np.array([x0, y0], np.float32) * U
        b = np.array([x1, y1], np.float32) * U
        d = b - a
        t = np.clip(((XX - a[0]) * d[0] + (YY - a[1]) * d[1]) / max(float(d @ d), 1e-6), 0, 1)
        joints |= np.hypot(XX - (a[0] + d[0] * t), YY - (a[1] + d[1] * t)) < 0.35 * U
    dist = np.asarray(Image.fromarray((~joints * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5 * U)),
                      np.float32) / 255.0   # rounded faces: high in a stone's middle, low by its joints
    inca = lines(tint(tex["rock"][0], "9d9c96", 0.3), joints, "4f4e4a")
    inca_n = base.normal_from_height((dist * 0.6 - joints * 0.8).astype(np.float32), 4.0)
    page.put((2, 2), inca, inca_n)
    page.put((3, 2), tint(tex["rock"][0], "a9a8a2", 0.3), tex["rock"][1])
    page.put((4, 2), crack(inca, rng), inca_n)
    # --- soapstone (5,2): small pale triangular tiles ---
    cx = (XX // (4 * U)).astype(int)
    cy = (YY // (4 * U)).astype(int)
    lower = np.mod(XX, 4 * U) > np.mod(YY, 4 * U)
    k = np.mod(cx * 7 + cy * 3 + lower.astype(int), 3)
    soap = shade(tex["plaster"][0], "c8cbbc", 0.92, 1.05) * np.where(k == 0, 1.0, np.where(k == 1, 1.06, 0.93))[..., None]
    grout = (np.mod(XX, 4 * U) < 0.5 * U) | (np.mod(YY, 4 * U) < 0.5 * U) | (np.abs(np.mod(XX, 4 * U) - np.mod(YY, 4 * U)) < 0.35 * U)
    soap = lines(np.clip(soap, 0, 1), grout, "9ea291")
    page.put((5, 2), soap, base.normal_from_height((grout * -0.5).astype(np.float32), 3.0))
    # --- inlaid marble side (6,2): white with a flower of coloured stones; top (7,2): white with a green border ---
    marble = shade(tex["plaster"][0], "f4f2ec", 0.94, 1.03)
    border = (np.abs(XX - 1.5 * U) < 0.4 * U) | (np.abs(XX - 14.5 * U) < 0.4 * U) | (np.abs(YY - 1.5 * U) < 0.4 * U) \
        | (np.abs(YY - 14.5 * U) < 0.4 * U)
    side = lines(marble, border, "d8d4ca")
    stem = (np.abs(XX - 8 * U) < 0.4 * U) & (YY > 8.5 * U) & (YY < 13 * U)
    leaf = (np.hypot(XX - 6 * U, YY - 10.5 * U) < 1.0 * U) | (np.hypot(XX - 10.5 * U, YY - 9.8 * U) < 1.0 * U)
    petals = np.zeros((INNER, INNER), bool)
    for a in range(6):
        ang = a * np.pi / 3
        petals |= np.hypot(XX - (8 * U + np.cos(ang) * 1.6 * U), YY - (5.8 * U + np.sin(ang) * 1.6 * U)) < 0.9 * U
    heart = np.hypot(XX - 8 * U, YY - 5.8 * U) < 0.7 * U
    side = lines(lines(lines(lines(side, stem | leaf, "2e8b57"), petals, "c0392b"), heart, "e1b12c"),
                 (np.hypot(XX - 4 * U, YY - 4 * U) < 0.6 * U) | (np.hypot(XX - 12 * U, YY - 4 * U) < 0.6 * U), "2c5f9e")
    inlay = stem | leaf | petals | heart
    page.put((6, 2), side, base.normal_from_height((inlay * -0.1 + border * -0.1).astype(np.float32), 2.0))
    top = lines(marble, (np.abs(YY - 2.5 * U) < 0.4 * U) | (np.abs(YY - 13.5 * U) < 0.4 * U), "2e8b57")
    page.put((7, 2), top, base.flat_normal())
    page.save()


def page37(tex: dict, rng) -> None:
    page = Page("wonders4")
    # --- Mughal red side (0,0): red sandstone with a white marble frame and star; top (1,0) ---
    red = shade(tex["rock"][0], "a8452f", 0.85, 1.1)
    frame = ((np.abs(XX - 1.5 * U) < 0.45 * U) | (np.abs(XX - 14.5 * U) < 0.45 * U) | (np.abs(YY - 1.5 * U) < 0.45 * U)
             | (np.abs(YY - 14.5 * U) < 0.45 * U)) & (XX > U) & (XX < 15 * U) & (YY > U) & (YY < 15 * U)
    star = ((np.abs((XX - C) - (YY - C)) < 0.45 * U) | (np.abs((XX - C) + (YY - C)) < 0.45 * U)) \
        & (np.abs(XX - C) < 3.5 * U) & (np.abs(YY - C) < 3.5 * U)
    side = lines(lines(red, frame, "f4f2ec"), star, "f4f2ec")
    page.put((0, 0), side, base.normal_from_height(((frame | star) * 0.3).astype(np.float32), 3.0))
    page.put((1, 0), tint(tex["rock"][0], "a8452f", 0.3), tex["rock"][1])
    # --- white stone (2,0): page 34's realistic white stone, copied; its side with a crack (3,0) ---
    alb = np.asarray(Image.open(DIR + "wonders2_albedo.png").convert("RGB"), np.float32) / 255.0
    nor = np.asarray(Image.open(DIR + "wonders2_normal.png").convert("RGB"), np.float32) / 255.0
    cell = alb.shape[1] // 8
    ncell = nor.shape[1] // 8
    pad = (cell - INNER) // 2
    white = alb[pad:pad + INNER, 2 * cell + pad:2 * cell + pad + INNER]
    wn = nor[:ncell, 2 * ncell:3 * ncell]
    wn = np.asarray(Image.fromarray((wn * 255).astype(np.uint8)).resize((cell, cell)), np.float32)[pad:pad + INNER,
                                                                                                    pad:pad + INNER] / 255.0
    page.put((2, 0), white, wn)
    page.put((3, 0), crack(white, rng), wn)
    page.save()


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"bricks": "Bricks084", "rock": "Rock030", "rock2": "Rock029",
                                         "plaster": "Plaster001", "ground": "Ground037"}.items()}
    rng = np.random.default_rng(20260936)
    page36(tex, rng)
    page37(tex, rng)


if __name__ == "__main__":
    main()
