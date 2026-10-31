#!/usr/bin/env python3
"""Builds the REALISTIC twin of the rocket parts' block page (spec §21d.2; owner #78, #79) from CC0 textures
(ambientCG, https://ambientcg.com), in the same 8x8 layout as the pixel page (tools/make_rocket_page.gd):

  data/blocks/pages/rockets_albedo.png, rockets_normal.png   page 32 (data/blocks/rocket_page.gd)

Tiles are made like tools/make_space_realistic.py (whose Page and helpers it uses): 240 px of texture plus an 8 px
border that continues it. The parts' shapes (the engines' bells, the nose cone, the capsule, the legs, the fins) are the
pixel page's, drawn smooth here; the cut-out tiles keep their alpha. Our own look (spec §3c): white and silver parts with
the brand's teal bands, a red nose and fins, golden space-engine bells, blue solar cells, a concrete pad with
yellow-and-black stripes.
Sources (all CC0, already used by other pages and credited): Plastic013A (white paint, the solar cells), Metal034 (the
metal parts, the golden bells), Fabric004 (the parachute), Ground037 (the heat shield's tiles), Plaster001 (the pad's
concrete). Everything else (bells, tubes, rivets, windows, stripes, lattices) is drawn here.

Run from the project root:  python3 tools/make_rocket_realistic.py   (needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402
from make_space_realistic import Page, shade, tint, XX, YY, U, R, ANG, disc  # noqa: E402

INNER = base.INNER
C = INNER / 2.0


def cyl(color: np.ndarray, x0: float = 0.0, x1: float = INNER) -> np.ndarray:
    """A round part's side: lit in the middle, darker to its edges."""
    u = np.clip((XX - x0) / max(x1 - x0, 1.0), 0, 1)
    k = 1.0 - 0.28 * ((u - 0.42) * 2.0) ** 2
    return np.clip(color * k[..., None], 0, 1)


def flat(hex_color: str) -> np.ndarray:
    return np.broadcast_to(base.hexcolor(hex_color), (INNER, INNER, 3)).astype(np.float32).copy()


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"plastic": "Plastic013A", "metal": "Metal034", "cloth": "Fabric004",
                                         "ground": "Ground037", "plaster": "Plaster001"}.items()}
    page = Page("rockets")
    white = shade(tex["plastic"][0], "f4f6f8", 0.93, 1.06)
    silver = shade(tex["metal"][0], "b9c2cc", 0.82, 1.18)
    silver_light = shade(tex["metal"][0], "dfe5ec", 0.86, 1.12)
    silver_dark = shade(tex["metal"][0], "8b95a2", 0.82, 1.18)
    dark = shade(tex["metal"][0], "3b404b", 0.8, 1.25)
    gold = shade(tex["metal"][0], "f0cf7a", 0.82, 1.18)
    gold_dark = shade(tex["metal"][0], "c99a3c", 0.82, 1.18)
    teal = shade(tex["plastic"][0], "139e9b", 0.9, 1.1)
    red = shade(tex["plastic"][0], "e0413a", 0.9, 1.1)
    metal_n = tex["metal"][1]
    plastic_n = tex["plastic"][1]
    ones = np.ones((INNER, INNER), np.float32)

    # --- engines (row 0): a plate on top, the bell on the side, the bell's mouth below ---
    def plate(ring: np.ndarray, rim: np.ndarray) -> np.ndarray:
        out = rim.copy()
        out[R < 97.5] = ring[R < 97.5]
        out[R < 37.5] = silver[R < 37.5]
        for bx, by in [(37, 37), (203, 37), (37, 203), (203, 203)]:
            out[disc(bx, by, 9)] = base.hexcolor("262a33")
        return out

    def bell(housing: float, throat: float, color: np.ndarray, box: np.ndarray, band: np.ndarray) -> tuple:
        k = np.clip((YY - housing) / (INNER - housing), 0, 1)
        half = throat + (C - throat) * k ** 1.6
        inside = (YY >= housing) & (np.abs(XX - C + 0.5) < half)
        x0 = C - half
        col = color * (1.0 - 0.28 * (((XX - x0) / np.maximum(2 * half, 1) - 0.42) * 2.0) ** 2)[..., None]
        col = np.where((np.mod(XX - x0, 3 * U) < 4)[..., None] & inside[..., None], col * 0.86, col)
        col = np.where((YY >= INNER - U)[..., None], np.clip(band * 1.15, 0, 1), col)
        top = YY < housing
        pipes = np.mod(XX, 5 * U) < U
        box_c = np.where(pipes[..., None], band, box)
        out = np.where(top[..., None], box_c, col)
        alpha = (top | inside).astype(np.float32)
        height = np.where(inside, np.cos((XX - C) / np.maximum(half, 1) * np.pi / 2) * 0.6, 0.3).astype(np.float32)
        height -= np.where(inside & (np.mod(XX - x0, 3 * U) < 4), 0.15, 0)
        return np.clip(out, 0, 1), base.normal_from_height(height, 3.0), alpha

    def mouth(rim: np.ndarray, inside: np.ndarray, ring: np.ndarray) -> tuple:
        out = rim.copy()
        out[R < 97.5] = ring[R < 97.5]
        out[R < 82.5] = inside[R < 82.5]
        height = np.where(R < 82.5, 0.0, np.where(R < 97.5, 0.5, 0.8)).astype(np.float32)
        return out, base.normal_from_height(height, 3.0), (R < 120).astype(np.float32)

    page.put((0, 0), plate(dark, silver_dark), metal_n)
    c, n, a = bell(4 * U, 3 * U, dark, silver, silver_dark)
    page.put((1, 0), c, n, a, wrap_x=False, wrap_y=False)
    c, n, a = mouth(dark, flat("1b1e25"), silver_dark)
    page.put((2, 0), c, n, a, wrap_x=False, wrap_y=False)
    page.put((3, 0), plate(gold, gold_dark), metal_n)
    c, n, a = bell(2 * U, 2 * U, gold, silver_light, gold_dark)
    page.put((4, 0), c, n, a, wrap_x=False, wrap_y=False)
    c, n, a = mouth(gold, flat("1b1e25"), gold_dark)
    page.put((5, 0), c, n, a, wrap_x=False, wrap_y=False)

    # --- the fuel tank: a white dome with a fitting; a white round side with the brand's teal band and rivets ---
    top = shade(tex["plastic"][0], "d3dae3", 0.93, 1.06)
    dome = np.clip(white * (1.0 - 0.12 * np.clip(R / 112, 0, 1))[..., None], 0, 1)
    top[R < 112] = dome[R < 112]
    top[R < 24] = silver_dark[R < 24]
    page.put((6, 0), top, base.normal_from_height(np.clip(1 - R / 112, 0, 1).astype(np.float32), 2.0))
    side = cyl(white)
    band = (YY >= 11 * U) & (YY < 13 * U)
    side[band] = cyl(teal)[band]
    seam = (YY < U) | (YY >= 15 * U)
    side[seam] = cyl(shade(tex["plastic"][0], "d3dae3", 0.93, 1.06))[seam]
    rivets = (np.abs(YY - 5.5 * U) < 5) & (np.mod(XX - U, 4 * U) < 10)
    side[rivets] = silver_dark[rivets]
    height = np.where(rivets, 1.0, 0.0) + np.where(seam, -0.4, 0.0)
    page.put((7, 0), side, base.normal_from_height(height.astype(np.float32), 3.0), wrap_x=True, wrap_y=False)

    # --- the nose cone (row 1): a cone, red at the tip ---
    half = 0.9 * U + (C - 0.9 * U) * (YY / (INNER - 1))
    cone = np.abs(XX - C + 0.5) < half
    x0 = C - half
    shade_k = (1.0 - 0.28 * (((XX - x0) / np.maximum(2 * half, 1) - 0.42) * 2.0) ** 2)[..., None]
    nose = np.where((YY < 5 * U)[..., None], red, white) * shade_k
    nose[(YY >= 5 * U) & (YY < 6 * U)] = np.clip(red * 0.78, 0, 1)[(YY >= 5 * U) & (YY < 6 * U)]
    page.put((0, 1), np.clip(nose, 0, 1), plastic_n, cone.astype(np.float32), wrap_x=False, wrap_y=False)
    page.put((1, 1), red, plastic_n, (R < 27).astype(np.float32), wrap_x=False, wrap_y=False)
    page.put((2, 1), shade(tex["plastic"][0], "d3dae3", 0.93, 1.06), plastic_n)

    # --- the crew capsule: a cone with a round window; its hatch on top; the heat shield under it ---
    shield_c = shade(tex["ground"][0], "5b3a28", 0.8, 1.2)
    half = 4 * U + 4 * U * (YY / (INNER - 1))
    body = np.abs(XX - C + 0.5) < half
    x0 = C - half
    k = (1.0 - 0.28 * (((XX - x0) / np.maximum(2 * half, 1) - 0.42) * 2.0) ** 2)[..., None]
    cap = np.clip(silver_light * k, 0, 1)
    cap[(YY >= 2 * U) & (YY < 3 * U)] = (teal * k)[(YY >= 2 * U) & (YY < 3 * U)]
    cap[YY >= 14 * U] = shield_c[YY >= 14 * U]
    wd = np.hypot(XX - C, YY - 8.0 * U - U / 2)
    cap[wd < 3.2 * U] = silver_dark[wd < 3.2 * U]
    glass = np.clip(base.hexcolor("5aa9f0") * (0.85 + 0.3 * (1 - wd / (2.3 * U)))[..., None], 0, 1)
    cap[wd < 2.3 * U] = glass[wd < 2.3 * U]
    cap[disc(C - 0.9 * U, 7.2 * U, 0.8 * U)] = base.hexcolor("d6efff")
    height = np.where(wd < 2.3 * U, 0.2, np.where(wd < 3.2 * U, 0.9, 0.5)).astype(np.float32)
    page.put((3, 1), cap, base.normal_from_height(height, 3.0), body.astype(np.float32), wrap_x=False, wrap_y=False)
    hatch = silver_light.copy()
    ring = (R > 1.6 * U) & (R < 2.6 * U)
    hatch[ring] = silver_dark[ring]
    page.put((4, 1), hatch, base.normal_from_height(np.where(ring, 0.0, 0.6).astype(np.float32), 2.0),
             (R < 4.2 * U).astype(np.float32), wrap_x=False, wrap_y=False)
    page.put((5, 1), shield_c, tex["ground"][1])

    # --- the service module: silver with radiator panels, the teal band, two thruster quads; its top ---
    sm = cyl(silver)
    sm[YY < 2 * U] = cyl(teal)[YY < 2 * U]
    radiators = (np.mod(XX - U, 4 * U) < U) & (YY > 3 * U) & (YY < 14 * U)
    sm[radiators] = np.clip(sm[radiators] * 1.18, 0, 1)
    sm[YY >= 15 * U] = cyl(silver_dark)[YY >= 15 * U]
    quads = np.zeros((INNER, INNER), bool)
    for qx, qy in [(3.5 * U, 6.5 * U), (12.5 * U, 6.5 * U)]:
        quads |= (np.abs(XX - qx) < 1.5 * U) & (np.abs(YY - qy) < 1.5 * U)
    sm[quads] = dark[quads]
    height = np.where(radiators, 0.6, 0.3) + np.where(quads, 0.5, 0.0)
    page.put((6, 1), sm, base.normal_from_height(height.astype(np.float32), 3.0), wrap_x=True, wrap_y=False)
    smt = silver_dark.copy()
    smt[R < 112] = silver[R < 112]
    marks = (R > 60) & (R < 75) & (np.mod(np.round(ANG * 4 / np.pi), 2) == 0)
    smt[marks] = dark[marks]
    page.put((7, 1), smt, metal_n)

    # --- the heat shield (row 2): a silver ring over dark tiles in a lattice; its face ---
    lattice = (np.mod(XX + YY, 4 * U) < 10) | (np.mod(XX - YY, 4 * U) < 10)
    tiles_c = np.where(lattice[..., None], np.clip(shield_c * 1.3, 0, 1), shield_c)
    hs = tiles_c.copy()
    hs[YY < 4 * U] = cyl(silver)[YY < 4 * U]
    lat_h = np.where(lattice, 0.0, 0.7).astype(np.float32)
    page.put((0, 2), hs, base.normal_from_height(np.where(YY < 4 * U, 0.5, lat_h).astype(np.float32), 3.0),
             wrap_x=True, wrap_y=False)
    face = tiles_c.copy()
    face[R > 108] = np.clip(shield_c * 0.8, 0, 1)[R > 108]
    page.put((1, 2), face, base.normal_from_height(lat_h, 3.0))

    # --- landing legs: a hinge, a strut with its shock absorber, a golden footpad; seen from above ---
    t = np.clip(((XX - 1.5 * U) + (YY - 2.5 * U)) / 2 / (12 * U), 0, 1)
    px, py = 1.5 * U + t * 12 * U, 2.5 * U + t * 12 * U
    strut = np.hypot(XX - px, YY - py) < 1.0 * U
    hinge = (XX < 4 * U) & (YY < 3 * U)
    absorber = (XX >= 6 * U) & (XX < 9 * U) & (YY >= 7 * U) & (YY < 10 * U)
    pad = (XX >= 9 * U) & (YY >= 14 * U)
    pad_rim = (XX >= 10 * U) & (XX < 15 * U) & (YY >= 13 * U) & (YY < 14 * U)
    legs = np.zeros((INNER, INNER, 3), np.float32)
    legs[strut] = silver_light[strut]
    legs[hinge] = dark[hinge]
    legs[absorber] = silver_dark[absorber]
    legs[pad | pad_rim] = gold[pad | pad_rim]
    legs[pad_rim] = gold_dark[pad_rim]
    alpha = (strut | hinge | absorber | pad | pad_rim).astype(np.float32)
    page.put((2, 2), legs, metal_n, alpha, wrap_x=False, wrap_y=False)
    bar = (XX >= U) & (XX < 15 * U) & (YY >= 7 * U) & (YY < 9 * U)
    foot = (XX >= 11 * U) & (XX < 15 * U) & (YY >= 6 * U) & (YY < 10 * U)
    ltop = np.zeros((INNER, INNER, 3), np.float32)
    ltop[bar] = silver[bar]
    ltop[foot] = gold[foot]
    page.put((3, 2), ltop, metal_n, (bar | foot).astype(np.float32), wrap_x=False, wrap_y=False)

    # --- fins: a red swept fin with white edges; seen from above, a cross of thin plates ---
    half = 0.8 * U + (C - 0.8 * U) * np.clip((YY - 2 * U) / (13 * U), 0, 1)
    fin = (YY >= 2 * U) & (np.abs(XX - C + 0.5) < half)
    edge = fin & (np.abs(XX - C + 0.5) > half - 0.9 * U)
    fins = np.where(fin[..., None], red, 0)
    fins[fin & (YY >= 14 * U)] = np.clip(red * 0.78, 0, 1)[fin & (YY >= 14 * U)]
    fins[edge] = white[edge]
    page.put((4, 2), np.clip(fins, 0, 1).astype(np.float32), plastic_n, fin.astype(np.float32), wrap_x=False, wrap_y=False)
    cross = (np.abs(YY - C) < U) | (np.abs(XX - C) < U)
    page.put((5, 2), red, plastic_n, cross.astype(np.float32), wrap_x=False, wrap_y=False)

    # --- the stage separator: a silver ring with a band of warning stripes and bolts; seen from above, a hollow ring ---
    sep = cyl(silver)
    warn = (YY >= 6 * U) & (YY < 10 * U)
    stripes = np.mod(np.floor((XX + YY) / (2 * U)), 2) == 0
    sep[warn & stripes] = shade(tex["plastic"][0], "ffd23f", 0.9, 1.1)[warn & stripes]
    sep[warn & ~stripes] = shade(tex["plastic"][0], "25262b", 0.9, 1.1)[warn & ~stripes]
    bolts = ((np.abs(YY - 3.5 * U) < 6) | (np.abs(YY - 12.5 * U) < 6)) & (np.mod(XX - U, 3 * U) < 12)
    sep[bolts] = dark[bolts]
    page.put((6, 2), sep, base.normal_from_height(np.where(bolts, 1.0, np.where(warn, 0.2, 0.4)).astype(np.float32), 3.0),
             wrap_x=True, wrap_y=False)
    sept = silver_dark.copy()
    sept[R < 114] = silver[R < 114]
    sept[R < 81] = dark[R < 81]
    yring = (R < 81) & (R > 66)
    sept[yring] = base.hexcolor("ffd23f")
    page.put((7, 2), sept, base.normal_from_height(np.where(R < 66, 0.0, 0.6).astype(np.float32), 3.0))

    # --- the solar array (row 3): blue cells in a golden frame; its sunny face a little lighter ---
    for tile, hue in [((0, 3), "2b4c9b"), ((1, 3), "4a78d8")]:
        cells = shade(tex["plastic"][0], hue, 0.9, 1.12)
        lines = (np.mod(XX, 5 * U) < 8) | (np.mod(YY, 5 * U) < 8)
        cells[lines] = base.hexcolor("262a33")
        frame = (XX < U) | (YY < U) | (XX >= 15 * U) | (YY >= 15 * U)
        cells[frame] = gold[frame]
        for gx, gy in [(3.5 * U, 3.5 * U), (8.5 * U, 8.5 * U), (13 * U, 3 * U)]:
            cells[disc(gx, gy, 0.6 * U)] = base.hexcolor("d6efff")
        page.put(tile, cells, base.normal_from_height(np.where(lines | frame, 0.6, 0.2).astype(np.float32), 2.0))

    # --- the parachute pack: a white canister with orange and white gores, a silver lid; its top, the folded canopy ---
    cloth = tex["cloth"][0].mean(-1, keepdims=True)
    cloth = np.clip(cloth / max(float(cloth.mean()), 1e-3), 0.88, 1.1)
    orange = np.clip(base.hexcolor("f08a1c") * cloth, 0, 1)
    wcloth = np.clip(base.hexcolor("f4f6f8") * cloth, 0, 1)
    pack = cyl(white)
    gores = (YY >= 4 * U) & (YY < 13 * U)
    stripe = np.mod(np.floor(XX / (2 * U)), 2) == 0
    pack[gores & stripe] = cyl(orange)[gores & stripe]
    pack[gores & ~stripe] = cyl(wcloth)[gores & ~stripe]
    pack[YY < 3 * U] = cyl(silver)[YY < 3 * U]
    page.put((2, 3), pack, tex["cloth"][1], wrap_x=True, wrap_y=False)
    wedge = np.mod(np.floor((ANG + np.pi) / (np.pi / 4)), 2) == 0
    canopy = silver_dark.copy()
    inside = R < 114
    canopy[inside & wedge] = orange[inside & wedge]
    canopy[inside & ~wedge] = wcloth[inside & ~wedge]
    canopy[R < 22] = silver[R < 22]
    page.put((3, 3), canopy, tex["cloth"][1])

    # --- the pad: concrete slabs; the ring's yellow-and-black stripes on top and at the top of its side ---
    concrete = tint(tex["plaster"][0], "b9b8b1", 0.25)
    joints = (XX >= INNER - 6) | (YY >= INNER - 6)
    slab = concrete.copy()
    slab[joints] = np.clip(concrete * 0.82, 0, 1)[joints]
    page.put((4, 3), slab, base.normal_from_height(np.where(joints, 0.0, 0.5).astype(np.float32), 2.0))
    lum = concrete.mean(-1, keepdims=True) / max(float(concrete.mean()), 1e-3)
    yellow = np.clip(base.hexcolor("ffd23f") * np.clip(lum, 0.85, 1.12), 0, 1)
    black = np.clip(base.hexcolor("25262b") * np.clip(lum, 0.85, 1.12), 0, 1)
    diag = np.mod(np.floor((XX + YY) / (4 * U)), 2) == 0
    page.put((5, 3), np.where(diag[..., None], yellow, black), tex["plaster"][1])
    stripe_side = concrete.copy()
    band = YY < 4 * U
    stripe_side[band & diag] = yellow[band & diag]
    stripe_side[band & ~diag] = black[band & ~diag]
    page.put((6, 3), stripe_side, tex["plaster"][1], wrap_x=True, wrap_y=False)
    plinth = concrete.copy()
    plinth[YY > 12 * U] = np.clip(concrete * 0.84, 0, 1)[YY > 12 * U]
    page.put((7, 3), plinth, tex["plaster"][1], wrap_x=True, wrap_y=False)

    del ones
    page.save()


if __name__ == "__main__":
    main()
