#!/usr/bin/env python3
"""Builds the REALISTIC twin of the colony's block page (owner #77, spec §21c) from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layout as the pixel page (tools/make_colony_page.gd):

  data/blocks/pages/colony_albedo.png, colony_normal.png   page 31 (world/colony/colony_blocks.gd)

Tiles are made like tools/make_space_realistic.py (whose Page and helpers it uses): 240 px of texture plus an 8 px
border that continues it. Our own look (spec §3c), the pixel page's design drawn smooth: clear dome glass with a thin
white frame (cut out), white habitat panels with the brand's teal stripe, light floor tiles, dark greenhouse soil with
sprouts under a white planter's rim, pink grow lamps (red and blue lights), a warm light panel, leaves with oranges (cut
out), a tank of blue water, an ice melter with a warm glow, an oxygen maker with bubbling tubes, screens with a graph, a
big map with a globe, teal-and-white airlock chevrons, shiny rocket steel with seams and rivets, printed regolith in
layers and a white table on two legs (cut out).
Sources (all CC0, already used by other pages and credited): Plastic013A (the white panels, the floor tiles, the
machines' casings, the table), Metal034 (the rocket's steel, frames, legs), Ground037 (the greenhouse soil),
Grass001 (the leaves), Plaster001 (the printed regolith, the light panel). Everything else (glass, lamps, water, ice,
coils, tubes, bubbles, screens, the map, stripes, seams) is drawn here.

Run from the project root:  PYTHONDONTWRITEBYTECODE=1 python3 tools/make_colony_realistic.py   (needs Pillow + numpy)
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
RNG = np.random.default_rng(20260931)


def flat(hex_color: str) -> np.ndarray:
    return np.broadcast_to(base.hexcolor(hex_color), (INNER, INNER, 3)).astype(np.float32).copy()


def cyl(color: np.ndarray) -> np.ndarray:
    """A round thing's side: lit a little left of the middle, darker to its edges."""
    u = np.clip(XX / INNER, 0, 1)
    k = 1.0 - 0.22 * ((u - 0.42) * 2.0) ** 2
    return np.clip(color * k[..., None], 0, 1)


def frame_mask(width: float) -> np.ndarray:
    return (XX < width) | (YY < width) | (XX >= INNER - width) | (YY >= INNER - width)


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"plastic": "Plastic013A", "metal": "Metal034", "soil": "Ground037",
                                         "leaves": "Grass001", "plaster": "Plaster001"}.items()}
    page = Page("colony")
    plastic, plastic_n = tex["plastic"]
    metal, metal_n = tex["metal"]
    white = shade(plastic, "f4f6f8", 0.93, 1.06)
    white_shade = shade(plastic, "d3dae3", 0.93, 1.06)
    teal = shade(plastic, "139e9b", 0.9, 1.1)
    teal_dark = shade(plastic, "0c7876", 0.9, 1.1)
    silver = shade(metal, "b9c2cc", 0.82, 1.18)
    silver_light = shade(metal, "dfe5ec", 0.86, 1.12)
    silver_dark = shade(metal, "8b95a2", 0.82, 1.18)
    dark = shade(metal, "3b404b", 0.8, 1.25)
    flat_n = base.flat_normal()

    # --- (0,0) dome glass: clear, a thin white frame, a glint (cut out) ---
    frame = (XX < 0.8 * U) | (YY < 0.8 * U)   # two edges: two panes side by side draw one line between them
    glint = (np.abs((XX - 3.5 * U) + (YY - 5.5 * U)) < 0.7 * U) & (XX > 2.5 * U) & (XX < 7 * U) & (YY > 2 * U) & (YY < 7 * U)
    glint |= disc(11.5 * U, 11.5 * U, 0.8 * U)
    glass = np.where(frame[..., None], shade(plastic, "e8f6ff", 0.95, 1.05), flat("ffffff"))
    page.put((0, 0), glass, base.normal_from_height(frame.astype(np.float32), 2.0), (frame | glint).astype(np.float32),
             wrap_x=False, wrap_y=False)

    # --- (1,0) (2,0) habitat panels: white with seams and rivets, the teal stripe on the side; a panel grid on top ---
    side = white.copy()
    seams = (YY < 0.5 * U) | (YY >= 15.5 * U) | (XX < 0.5 * U)
    side[seams] = white_shade[seams]
    band = (YY >= 11 * U) & (YY < 12 * U)
    side[band] = teal[band]
    band2 = (YY >= 12 * U) & (YY < 13 * U)
    side[band2] = teal_dark[band2]
    rivets = np.zeros((INNER, INNER), bool)
    for rx, ry in [(2.5, 2.5), (13.5, 2.5), (2.5, 8.5), (13.5, 8.5)]:
        rivets |= disc(rx * U, ry * U, 0.45 * U)
    side[rivets] = silver[rivets]
    page.put((1, 0), side, base.normal_from_height((rivets * 1.0 - seams * 0.5 - (band | band2) * 0.1).astype(np.float32),
                                                   3.0))
    top = white.copy()
    grid = (np.abs(XX - 7.5 * U) < 0.4 * U) | (np.abs(YY - 7.5 * U) < 0.4 * U) | (XX < 0.5 * U) | (YY < 0.5 * U)
    top[grid] = white_shade[grid]
    trivets = np.zeros((INNER, INNER), bool)
    for rx, ry in [(2.5, 2.5), (12.5, 2.5), (2.5, 12.5), (12.5, 12.5)]:
        trivets |= disc(rx * U, ry * U, 0.45 * U)
    top[trivets] = silver[trivets]
    page.put((2, 0), top, base.normal_from_height((trivets * 1.0 - grid * 0.5).astype(np.float32), 3.0))

    # --- (3,0) (4,0) floor tiles (light grey) with grip dots; the side a tile's edge over grey ---
    tiles = shade(plastic, "c9ced6", 0.94, 1.05)
    lines = (np.mod(XX, 8 * U) < 0.6 * U) | (np.mod(YY, 8 * U) < 0.6 * U)
    ftop = tiles.copy()
    ftop[lines] = np.clip(tiles * 0.84, 0, 1)[lines]
    dots = np.zeros((INNER, INNER), bool)
    for gy in [3.5, 5.5, 11.5, 13.5]:
        for gx in [3.5, 5.5, 11.5, 13.5]:
            dots |= disc(gx * U, gy * U, 0.35 * U)
    ftop[dots] = np.clip(tiles * 0.86, 0, 1)[dots]
    page.put((3, 0), ftop, base.normal_from_height((dots * 0.6 - lines * 0.5).astype(np.float32), 3.0))
    fside = shade(plastic, "9aa1ab", 0.94, 1.05)
    fside[YY < 2 * U] = tiles[YY < 2 * U]
    fside[np.mod(XX, 8 * U) < 0.6 * U] = np.clip(fside * 0.86, 0, 1)[np.mod(XX, 8 * U) < 0.6 * U]
    page.put((4, 0), fside, plastic_n, wrap_x=True, wrap_y=False)

    # --- (5,0) (6,0) greenhouse soil: dark rich crumbs with sprouts; the side under a white planter's rim ---
    soil = tint(tex["soil"][0], "4a3226", 0.25)
    stop = soil.copy()
    sprouts = np.zeros((INNER, INNER), bool)
    for sx, sy in [(3.5, 4.5), (10.5, 3.5), (6.5, 11.5), (12.5, 12.5)]:
        leaf_a = disc((sx - 0.4) * U, sy * U, 0.55 * U)
        leaf_b = disc((sx + 0.5) * U, (sy - 0.3) * U, 0.5 * U)
        sprouts |= leaf_a | leaf_b
    stop[sprouts] = shade(tex["leaves"][0], "6fcf4a", 0.85, 1.15)[sprouts]
    page.put((5, 0), stop, base.normal_from_height((sprouts * 0.8).astype(np.float32), 2.0) * 0.5 + tex["soil"][1] * 0.5)
    sside = soil.copy()
    rim = YY < 3 * U
    sside[rim] = white[rim]
    sside[(YY >= 1 * U) & (YY < 1.7 * U)] = teal[(YY >= 1 * U) & (YY < 1.7 * U)]
    sside[(YY >= 3 * U) & (YY < 3.6 * U)] = white_shade[(YY >= 3 * U) & (YY < 3.6 * U)]
    page.put((6, 0), sside, tex["soil"][1], wrap_x=True, wrap_y=False)

    # --- (7,0) a grow lamp: a dark frame round a pink glow of red and blue LEDs ---
    lamp = flat("e05ad8") * (0.92 + 0.08 * base.smooth_noise(6.0))[..., None]
    for gy in range(2, 14, 3):
        for gx in range(2, 14, 3):
            color = "ff3d6e" if (gx + gy) % 2 == 0 else "5a6bff"
            led = disc((gx + 1.0) * U, (gy + 1.0) * U, 0.95 * U)
            lamp[led] = base.hexcolor(color)
            lamp[disc((gx + 0.8) * U, (gy + 0.8) * U, 0.3 * U)] = np.clip(base.hexcolor(color) + 0.35, 0, 1)
    lframe = frame_mask(U)
    lamp[lframe] = dark[lframe]
    page.put((7, 0), lamp, base.normal_from_height(lframe.astype(np.float32), 2.0))

    # --- (0,1) a warm light panel ---
    d = np.clip(R / (C * 1.41), 0, 1)
    warm = base.hexcolor("fff3d6") * (1 - d[..., None]) + base.hexcolor("ffd98a") * d[..., None]
    warm = np.clip(warm * (0.97 + 0.03 * tint(tex["plaster"][0], "ffffff", 0.0).mean(-1, keepdims=True)), 0, 1)
    wframe = frame_mask(0.7 * U)
    warm[wframe] = silver_light[wframe]
    page.put((0, 1), warm, flat_n)

    # --- (1,1) fruit leaves: leaves with gaps and ripe oranges (cut out) ---
    leaves = tint(tex["leaves"][0], "57a83d", 0.35)
    gaps = base.smooth_noise(3.0) < 0.2
    oranges = np.zeros((INNER, INNER), bool)
    shine = np.zeros((INNER, INNER), bool)
    for ox, oy in [(3, 4), (11, 3), (7, 10), (13, 12)]:
        oranges |= disc(ox * U, oy * U, 1.1 * U)
        shine |= disc((ox - 0.35) * U, (oy - 0.35) * U, 0.35 * U)
    fruit = leaves.copy()
    fruit[oranges] = shade(tex["plastic"][0], "ff9f1c", 0.9, 1.1)[oranges]
    fruit[shine] = base.hexcolor("ffd07a")
    alpha = (~gaps | oranges).astype(np.float32)
    page.put((1, 1), fruit, base.normal_from_height((oranges * 1.0).astype(np.float32), 3.0) * 0.5 + tex["leaves"][1] * 0.5,
             alpha)

    # --- (2,1) (3,1) a water tank: steel frame, glass, clean blue water with bubbles; its lid a round hatch ---
    tank = flat("d6efff")
    level = 4.5 * U + 0.25 * U * np.sin(XX / U * 1.3)
    water = YY >= level
    deep = np.clip((YY - 4 * U) / (12 * U), 0, 1)
    tank[water] = (base.hexcolor("3f8fe0") * (1 - deep[..., None]) + base.hexcolor("2a6fc0") * deep[..., None])[water]
    tank[np.abs(YY - level) < 0.35 * U] = base.hexcolor("9cc9f5")
    bubbles = np.zeros((INNER, INNER), bool)
    for bx, by in [(4.5, 12.5), (5.5, 9.5), (4.5, 6.5), (10.5, 13.5), (11.5, 10.5)]:
        bubbles |= disc(bx * U, by * U, 0.45 * U)
    tank[bubbles] = base.hexcolor("ffffff")
    tframe = frame_mask(U)
    tank[tframe] = silver_dark[tframe]
    page.put((2, 1), tank, base.normal_from_height((tframe * 1.0).astype(np.float32), 3.0), wrap_x=True, wrap_y=False)
    lid = silver.copy()
    lid[R < 5 * U] = silver_dark[R < 5 * U]
    lid[R < 3.8 * U] = base.hexcolor("3f8fe0")
    lid[frame_mask(0.8 * U)] = silver_dark[frame_mask(0.8 * U)]
    page.put((3, 1), lid, base.normal_from_height(np.where(R < 3.8 * U, 0.0, np.where(R < 5 * U, 0.6, 0.3)).astype(np.float32),
                                                  3.0))

    # --- (4,1) (5,1) an ice melter: a white casing, a window of ice over a warm coil; on top a grate over ice ---
    melt = white.copy()
    win = (XX >= 3 * U) & (XX < 13 * U) & (YY >= 3 * U) & (YY < 13 * U)
    melt[win] = dark[win]
    ice = shade(tex["plaster"][0], "d8f0ff", 0.9, 1.1)
    icebox = (XX >= 4 * U) & (XX < 12 * U) & (YY >= 4 * U) & (YY < 9 * U)
    melt[icebox] = ice[icebox]
    cracks = icebox & (np.mod(XX + 0.6 * YY, 3 * U) < 0.3 * U)
    melt[cracks] = base.hexcolor("a9d8f5")
    coil = (XX >= 4 * U) & (XX < 12 * U) & (YY >= 10 * U) & (YY < 12 * U)
    hot = coil & (np.mod(XX, 2 * U) < U)
    melt[coil] = base.hexcolor("ff8a3c")
    melt[hot] = base.hexcolor("ffd23f")
    drips = disc(6.5 * U, 9.5 * U, 0.4 * U) | disc(9.5 * U, 9.5 * U, 0.4 * U)
    melt[drips] = base.hexcolor("3f8fe0")
    melt[(YY >= 14 * U) & (YY < 15 * U)] = teal[(YY >= 14 * U) & (YY < 15 * U)]
    page.put((4, 1), melt, base.normal_from_height((win * -0.5 + icebox * 0.3).astype(np.float32), 3.0))
    grate = ice.copy()
    bars = np.mod(XX, 3 * U) < 0.8 * U
    grate[bars] = dark[bars]
    grate[frame_mask(0.8 * U)] = silver_dark[frame_mask(0.8 * U)]
    page.put((5, 1), grate, base.normal_from_height((bars * 1.0).astype(np.float32), 3.0))

    # --- (6,1) (7,1) an oxygen maker: white and teal, two glass tubes full of bubbles; on top two teal valves ---
    oxy = white.copy()
    tubes = np.zeros((INNER, INNER), bool)
    for tx in [3.0, 9.0]:
        t = (XX >= tx * U) & (XX < (tx + 4) * U) & (YY >= 2 * U) & (YY < 13 * U)
        tubes |= t
        oxy[t] = cyl(flat("b7e3ff"))[t]
        edge = t & ((XX < (tx + 0.5) * U) | (XX >= (tx + 3.5) * U))
        oxy[edge] = silver[edge]
    for bx, by, br in [(5, 11, 0.5), (4.3, 8, 0.4), (5.2, 5, 0.45), (4.5, 3, 0.3), (11, 10, 0.5), (10.3, 7, 0.4),
                       (11.2, 4, 0.35)]:
        oxy[disc(bx * U, by * U, br * U)] = base.hexcolor("ffffff")
    oxy[YY >= 13 * U] = teal[YY >= 13 * U]
    page.put((6, 1), oxy, base.normal_from_height((tubes * 0.6).astype(np.float32), 3.0), wrap_x=True, wrap_y=False)
    otop = white.copy()
    valves = disc(4.5 * U, 5.5 * U, 3 * U) | disc(11.5 * U, 10.5 * U, 3 * U)
    otop[valves] = teal[valves]
    caps = disc(4.5 * U, 5.5 * U, 1.2 * U) | disc(11.5 * U, 10.5 * U, 1.2 * U)
    otop[caps] = base.hexcolor("5fd3cf")
    page.put((7, 1), otop, base.normal_from_height((valves * 0.6 + caps * 0.3).astype(np.float32), 3.0))

    # --- (0,2) screens: a dark bezel, a screen with a green graph and bars; (1,2) a grey casing with vents ---
    scr = dark.copy()
    screen = (XX >= U) & (XX < 15 * U) & (YY >= U) & (YY < 12 * U)
    scr[screen] = base.hexcolor("0f3a4a")
    pts = [(2, 9), (3, 8), (4, 8), (5, 6), (6, 7), (7, 5), (8, 5), (9, 3), (10, 4), (11, 4), (12, 2), (13, 3)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        for s in np.linspace(0, 1, 12):
            scr[disc((x0 + (x1 - x0) * s + 0.5) * U, (y0 + (y1 - y0) * s + 0.5) * U, 0.35 * U)] = base.hexcolor("7be08a")
    for b, color in enumerate(["ffd23f", "6ec6ff", "7be08a", "5fd3cf"]):
        barm = (XX >= (3 + 3 * b) * U) & (XX < (5 + 3 * b) * U) & (YY >= (10 - b) * U) & (YY < 11 * U)
        scr[barm] = base.hexcolor(color)
    scr[(XX >= 2 * U) & (XX < 14 * U) & (YY >= 13 * U) & (YY < 15 * U)] = silver_dark[(XX >= 2 * U) & (XX < 14 * U) & (YY >= 13 * U) & (YY < 15 * U)]
    scr[disc(12.5 * U, 13.5 * U, 0.4 * U)] = base.hexcolor("7be08a")
    scr[disc(13.5 * U, 13.5 * U, 0.4 * U)] = base.hexcolor("e0413a")
    page.put((0, 2), scr, base.normal_from_height((screen * -0.3).astype(np.float32), 2.0))
    case = silver_dark.copy()
    vents = (np.mod(YY, 3 * U) < 0.7 * U) & (XX >= 3 * U) & (XX < 13 * U) & (YY >= 3 * U) & (YY < 13 * U)
    case[vents] = dark[vents]
    case[frame_mask(0.7 * U)] = dark[frame_mask(0.7 * U)]
    page.put((1, 2), case, base.normal_from_height((vents * -0.8).astype(np.float32), 3.0))

    # --- (2,2) the big map: a globe with its grid on a dark blue screen, a red "you are here" and a route ---
    mp = flat("10204a")
    globe = R < 6.5 * U
    mp[globe] = base.hexcolor("1f4a8a")
    dy = (YY - C) / (6.5 * U)
    dx = (XX - C) / (6.5 * U)
    lat = globe & ((np.abs(YY - C) < 0.35 * U) | (np.abs(np.abs(YY - C) - 3.5 * U) < 0.3 * U))
    width = np.sqrt(np.clip(1 - dy ** 2, 0, 1))
    lon = globe & ((np.abs(XX - C) < 0.35 * U) | (np.abs(np.abs(dx) - 0.55 * width) < 0.05))
    mp[lat | lon] = base.hexcolor("6ec6ff")
    mp[(R >= 6.5 * U) & (R < 7.1 * U)] = base.hexcolor("6ec6ff")
    mp[disc(9.8 * U, 5.8 * U, 0.8 * U)] = base.hexcolor("e0413a")
    for i in range(4):
        mp[disc((2.5 + i * 2) * U, (13.5 - i) * U, 0.4 * U)] = base.hexcolor("ffd23f")
    mp[frame_mask(0.7 * U)] = base.hexcolor("262a33")
    page.put((2, 2), mp, flat_n)

    # --- (3,2) (4,2) airlock frames: teal-and-white chevrons, a green light; on top straight stripes ---
    chev = np.mod(XX + YY, 8 * U) < 4 * U
    air = np.where(chev[..., None], teal, white)
    edge = (YY < 2 * U) | (YY >= 14 * U)
    air[edge] = silver_dark[edge]
    light = (XX >= 6 * U) & (XX < 10 * U) & (YY < 2 * U)
    air[light] = base.hexcolor("7be08a")
    page.put((3, 2), air, base.normal_from_height((edge * 0.6).astype(np.float32), 3.0) * 0.5 + plastic_n * 0.5)
    stripes = np.mod(XX, 8 * U) < 4 * U
    atop = np.where(stripes[..., None], teal, white)
    atop[frame_mask(0.7 * U)] = silver_dark[frame_mask(0.7 * U)]
    page.put((4, 2), atop, plastic_n)

    # --- (5,2) (6,2) rocket steel: shiny, seams and rivets, a highlight; its top a round seam ---
    steel = cyl(np.clip(silver * 0.55 + silver_light * 0.45, 0, 1))
    seam = (np.abs(YY - 0.3 * U) < 0.35 * U) | (np.abs(YY - 8 * U) < 0.35 * U)
    steel[seam] = silver_dark[seam]
    hrivets = np.zeros((INNER, INNER), bool)
    for ry in [2.0, 10.0]:
        for rx in range(2, 16, 4):
            hrivets |= disc((rx + 0.5) * U, (ry + 0.5) * U, 0.35 * U)
    steel[hrivets] = silver_dark[hrivets]
    hl = (XX >= 11 * U) & (XX < 11.8 * U) & (YY >= 3 * U) & (YY < 7 * U)
    steel[hl] = base.hexcolor("ffffff")
    page.put((5, 2), steel, base.normal_from_height((hrivets * 1.0 - seam * 0.5).astype(np.float32), 3.0) * 0.5 + metal_n * 0.5,
             wrap_x=True, wrap_y=True)
    stop = np.where((R < 4 * U)[..., None], silver_light, silver)
    stop[np.abs(R - 6 * U) < 0.4 * U] = silver_dark[np.abs(R - 6 * U) < 0.4 * U]
    page.put((6, 2), stop, base.normal_from_height((np.abs(R - 6 * U) < 0.4 * U).astype(np.float32) * -0.6, 3.0))

    # --- (7,2) (0,3) printed regolith: layers printed by a robot (Plaster001 in a warm grey); on top a round path ---
    rego = tint(tex["plaster"][0], "aba69d", 0.2)
    rego_dark = tint(tex["plaster"][0], "948e84", 0.2)
    layer = np.mod(np.floor(YY / (2 * U)), 2) == 0
    rside = np.where(layer[..., None], rego, rego_dark)
    groove = np.mod(YY, 2 * U) < 0.4 * U
    rside[groove] = np.clip(rego_dark * 0.88, 0, 1)[groove]
    page.put((7, 2), rside, base.normal_from_height((layer * 0.5 - groove * 0.5).astype(np.float32), 3.0))
    ring = np.mod(np.floor(R / U), 2) == 0
    rtop = np.where(ring[..., None], rego, rego_dark)
    page.put((0, 3), rtop, base.normal_from_height((ring * 0.5).astype(np.float32), 3.0))

    # --- (1,3) (2,3) (3,3) a table: a white top on two silver legs (cut out); its top with a teal edge; underneath ---
    tside = np.zeros((INNER, INNER, 3), np.float32)
    ttop_band = YY < 3 * U
    tside[ttop_band] = white[ttop_band]
    tside[YY < 0.8 * U] = teal[YY < 0.8 * U]
    tside[(YY >= 2.4 * U) & (YY < 3 * U)] = white_shade[(YY >= 2.4 * U) & (YY < 3 * U)]
    legs = (YY >= 3 * U) & (((XX >= U) & (XX < 3 * U)) | ((XX >= 13 * U) & (XX < 15 * U)))
    tside[legs] = cyl(silver)[legs]
    page.put((1, 3), tside, metal_n, (ttop_band | legs).astype(np.float32), wrap_x=False, wrap_y=False)
    ttop = white.copy()
    tframe = frame_mask(0.9 * U)
    ttop[tframe] = teal[tframe]
    page.put((2, 3), ttop, plastic_n)
    under = white_shade.copy()
    for cx, cy in [(2, 2), (14, 2), (2, 14), (14, 14)]:
        foot = (np.abs(XX - cx * U) < U) & (np.abs(YY - cy * U) < U)
        under[foot] = silver[foot]
    page.put((3, 3), under, plastic_n)

    page.save()


if __name__ == "__main__":
    main()
