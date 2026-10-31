#!/usr/bin/env python3
"""Builds the REALISTIC twins of the space block pages (owner feedback #55, spec §21.2) from CC0 textures (ambientCG,
https://ambientcg.com), in the same 8x8 layouts as the pixel pages (tools/make_space_atlas.gd):

  data/blocks/pages/moon_albedo.png, moon_normal.png         page 15, the Moon (world/universes/moon_blocks.gd)
  data/blocks/pages/mars_albedo.png, mars_normal.png         page 18, Mars (world/universes/mars_blocks.gd; spec §21b.2)
  data/blocks/pages/europa_albedo.png, europa_normal.png     page 20, Europa (world/universes/europa_blocks.gd; §21b.2)
  data/blocks/pages/io_albedo.png, io_normal.png             page 21, Io (world/universes/io_blocks.gd; §21b.2)
  data/blocks/pages/titan_albedo.png, titan_normal.png       page 29, Titan (world/universes/titan_blocks.gd; §21b.2)
  data/blocks/pages/mercury_albedo.png, mercury_normal.png   page 30, Mercury (world/universes/mercury_blocks.gd; §21b.2)
  data/blocks/pages/venus_albedo.png, venus_normal.png       page 38, Venus's cloud city (world/universes/venus_blocks.gd)
  data/blocks/pages/rings_albedo.png, rings_normal.png       page 40, Saturn's rings (world/universes/rings_blocks.gd)
  data/blocks/pages/pluto_albedo.png, pluto_normal.png       page 41, Pluto (world/universes/pluto_blocks.gd)
  data/blocks/pages/triton_albedo.png, triton_normal.png     page 42, Triton (world/universes/triton_blocks.gd)
  data/blocks/pages/ganymede_albedo.png, ganymede_normal.png page 43, Ganymede (world/universes/ganymede_blocks.gd)

Tiles are made like tools/make_realistic_atlas.py (whose helpers it uses): 240 px of texture plus an 8 px border that
continues it; the rows under a page's last drawn tile are cropped (M5 Task 3). Our own look (spec §3c): silvery dust with
sparkles, pale blue crystals, the brand's teal on the landing pad with a golden star.
Sources (all CC0, already used by the other pages): Snow004 (moon dust), Rock030 (moon rock), Rock035 (deep moon rock),
Ice002 (crystals), Ground037 (cheese), Metal034 (the base's panels, star gold), Plastic013A (the landing pad).
Everything else (craters, facets, holes, rivets, windows, stars, glows) is drawn here.

Mars: Ground097 (the dust's wind ripples), Ground103 (regolith), Rock031 (basalt), Rock035 (deep basalt), Ground093A
(layered rock), Snow003 (polar ice), Ice001 (dry ice), Ice002 (gypsum), Plastic013A (the rover's panels and solar cells),
Leather026 (the wheels' tread), Metal034 (the hub, gold foil, the lamp's frame).

Europa: Snow003 (the white ice), Snow004 (the ridges' stained ice), Ground103 (the cracks' reddish stain), Ice002 (deep
ice), Ice003 (glowing ice), Ice001 (sea salt), Rock030 (the seafloor rock), Plastic013A (the lander's panels), Metal034
(the melt probe, the lamp's frame), Bricks084 (ice bricks).

Io: Ground037 (yellow sulphur), Ground103 (orange sulphur), Snow004 (sulphur frost), Ground097 (red sulphur), Rock030
(Io's rock), Rock031 (black lava rock, the lava crust), Ice002 (sulphur crystals), Plastic013A (the heat tiles),
Metal034 (the lander's legs, the camera's frame), Bricks084 (sulphur bricks); the hot lava's swirls, the crust's glowing
cracks and the vent's throat are drawn here.

Titan: Ground103 (its orange-brown soil, the wet shore), Ground097 (the dunes' dark grains), Rock030 (icy rock, the ice
pebbles), Ice002 (shore crystals), Plastic013A (the probe's white shell), Metal034 (its gold foil, the lamp's frame),
Fabric004 (the parachute's cloth), Bricks084 (the station's bricks); the pebbles, stripes and lamps are drawn here.

Mercury: Ground103 (its grey dust), Ground097 (the darker dust), Rock030 (its rock), Snow004 (the rays' bright dust),
Snow003 (the shadowed craters' ice), Ice002 (ice crystals), Fabric004 (the sunshade's cloth), Metal034 (the heat blanket,
the frames, the thermometer's cap), Plastic013A (the mirror panels, the thermometer's board), Bricks084 (the explorers'
bricks); the little craters, streaks, quilting, cells, the thermometer's line and marks and its bulb are drawn here.

Venus's cloud city: Snow004 (the yellow cloud tops), Snow005 (the deeper clouds), Plastic013A (the decks, the gondola),
Metal034 (the float hulls, the frames, the lamps' frames, the telescopes' brass), Grass001 (the gardens' turf),
WoodFloor043 (the bridges' planks), Plaster001 (the homes' panels), Fabric004 (the blimp's skin and stripe), Ice002
(cloud crystals); the puffs, ribs, rivets, trims, the window, the cells and the rings are drawn here.

Saturn's rings: Snow006 (the chunks' frosty tops), Ice002 (clean ring ice), Ice004 (ring crystals), Ground103 (the C
ring's dusty ice, the dust on Pan's ridge), Rock030 (rock bits), Snow003 (Pan's pale ice), Plastic013A (the station's
panels), Metal034 (the radio dish, the truss); the cracks, sparkles, layers, seams, the window, the lamps, the fins, the
beacon's glow and Saturn's bands are drawn here.

Pluto: Snow003 (the heart's nitrogen ice, the cells' edges), Snow006 (methane snow), Rock030 (water ice, red ice,
Charon's grey), Ground103 (the uplands' frost), Ground097 (tholins), Ice004 (frost crystals), Fabric004 (the drag
balloon's film), Bricks084 (the explorers' frost bricks); the swirls, streaks, cracks, caps, folds, the globe and the heart
are drawn here.

Triton: Snow006 (the band's fresh nitrogen frost), Snow003 (the pink polar cap, its mottled patches, the nitrogen ice
under the frost, the ice lava), Ground097 (the geysers' dark dust), Ground103 (the cantaloupe terrain), Ice004 (nitrogen
crystals), Rock030 (the ice lava's layers), Plastic013A (the Hopper Lander's tank), Bricks084 (the explorers' cap
bricks); the dimples, ridges, flow lines, the vent's throat, the gauge, Neptune's bands, spot and clouds and the beacon's
glow are drawn here.

Ganymede: Snow003 (the grooved terrain's pale ice, its groove floors, the crust), Ground097 (the old dark terrain's dark
ice and its old, dusty ice), Snow006 (a young crater's fresh ice, the poles' frost), Ice004 (aurora crystals), Plastic013A
(the magnetometer's box), Bricks084 (the explorers' groove bricks); the grooves, the ridges' crests, the rays' glints,
the frost's drifts, Jupiter's zones, belts and Great Red Spot, the coil and the lamp's glow are drawn here.

Run from the project root:  python3 tools/make_space_realistic.py [moon boing rainbow mars europa io titan mercury venus
rings pluto triton ganymede]
(needs Pillow + numpy)
Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402  (helpers: fetch, pad, smooth noise, normals)

INNER = base.INNER
DIR = "data/blocks/pages/"


class Page(base.Atlas):
    def __init__(self, name: str) -> None:
        super().__init__()
        self.name = name

    def save(self) -> None:
        rows, alpha = base.save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                                     DIR + self.name + "_albedo.png", DIR + self.name + "_normal.png")
        print(f"SPACE_REALISTIC {self.name} rows={rows} alpha={alpha}")


def tint(color: np.ndarray, target: str, keep: float = 0.55) -> np.ndarray:
    """The texture's light and shade in the colour `target` (keep: how much of its own colour stays)."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(color * keep + base.hexcolor(target) * lum * (1 - keep), 0, 1)


def shade(color: np.ndarray, target: str, lo: float = 0.8, hi: float = 1.15) -> np.ndarray:
    """A flat colour lit by the texture's light and shade."""
    lum = color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    return np.clip(base.hexcolor(target) * np.clip(lum, lo, hi), 0, 1)


YY, XX = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
U = INNER / 16.0
R = np.hypot(XX - INNER / 2, YY - INNER / 2)
ANG = np.arctan2(YY - INNER / 2, XX - INNER / 2)


def disc(cx: float, cy: float, r: float) -> np.ndarray:
    return np.hypot(XX - cx, YY - cy) < r


def moon() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow004", "rock": "Rock030", "deep": "Rock035", "ice": "Ice002",
                                         "ground": "Ground037", "metal": "Metal034", "plastic": "Plastic013A"}.items()}
    rng = np.random.default_rng(20260955)
    page = Page("moon")

    # moon dust: silvery powder with little craters (a dip and a lit rim) and sparkles
    dust = tint(tex["snow"][0], "cdd1dc", 0.2)
    height = base.smooth_noise(3.0) * 0.3
    for _ in range(7):
        cx, cy, cr = rng.random() * INNER, rng.random() * INNER, 10 + rng.random() * 22
        d = np.hypot(XX - cx, YY - cy) / cr
        height -= np.where(d < 1, 0.8 * (1 - d * d), 0) - np.where((d >= 1) & (d < 1.3), 0.25 * (1.3 - d) / 0.3, 0)
    dust = np.clip(dust * (0.9 + 0.25 * height[..., None]), 0, 1)
    dust_n = base.normal_from_height(height.astype(np.float32), 4.0)
    dust_top = dust.copy()
    for _ in range(16):
        dust_top[disc(rng.random() * INNER, rng.random() * INNER, 1.6)] = base.hexcolor("ffffff")
    page.put((0, 0), dust_top, dust_n)
    rock = tint(tex["rock"][0], "9ea4b5", 0.25)
    page.put((2, 0), rock, tex["rock"][1])
    band = YY < 3.4 * U + 0.9 * U * np.sin(XX / INNER * 2 * np.pi * 4 + 0.5)
    side = np.where(band[..., None], dust, rock)
    page.put((1, 0), side, np.where(band[..., None], dust_n, tex["rock"][1]), wrap_y=False)
    page.put((3, 0), tint(tex["deep"][0], "737a91", 0.25), tex["deep"][1])

    # moon crystal: glowing pale blue facets (unshaded: the colour is the look)
    ice = shade(tex["ice"][0], "8fdcff", 0.97, 1.2)
    facet = np.mod(XX / U, 4.0)
    crystal = ice * (0.84 + 0.3 * (facet < 0.7)[..., None]) * (1.0 - 0.16 * (facet > 3.3)[..., None])
    page.put((4, 0), np.clip(crystal, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    top = ice * (0.8 + 0.25 * (np.mod(ring, 3.0) < 0.8)[..., None])
    top[((np.abs(XX - INNER / 2) < 0.5 * U) | (np.abs(YY - INNER / 2) < 0.5 * U)) & (R < 3 * U)] = base.hexcolor("e2f7ff")
    top[ring > 7.2] *= 0.78
    page.put((5, 0), np.clip(top, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # moon cheese: golden with round holes (dark hollows, a lit lip on top)
    cheese = shade(tex["ground"][0], "ffd45e", 0.88, 1.1)
    h = np.zeros((INNER, INNER), np.float32)
    for _ in range(7):
        cx, cy, cr = 20 + rng.random() * (INNER - 40), 20 + rng.random() * (INNER - 40), 12 + rng.random() * 18
        d = np.hypot(XX - cx, YY - cy) / cr
        h -= np.where(d < 1, np.sqrt(np.clip(1 - d * d, 0, 1)), 0)
        cheese[d < 1] = shade(tex["ground"][0], "d49a2a", 0.85, 1.05)[d < 1]
    cheese_n = base.normal_from_height(h, 5.0)
    page.put((6, 0), cheese, cheese_n)
    page.put((7, 0), cheese, cheese_n)

    # base panel: brushed silver with seams and rivets; the porthole: a warm window in it
    panel = shade(tex["metal"][0], "e7ecf4", 0.9, 1.08)
    seam = (YY < 3) | (XX < 3) | (np.abs(YY - INNER / 2) < 2)
    panel[seam] = base.hexcolor("c3cbd8")
    ph = np.zeros((INNER, INNER), np.float32)
    ph[seam] = -0.5
    for px, py in [(2, 2), (13, 2), (2, 13), (13, 13), (2, 10), (13, 10)]:
        m = disc(px * U + U / 2, py * U + U / 2, 0.6 * U)
        panel[m] = base.hexcolor("9aa5b7")
        ph[m] = 0.6
    panel_n = base.normal_from_height(ph, 3.0)
    page.put((0, 1), panel, panel_n)
    port = panel.copy()
    window = R < 5.2 * U
    glow = 1 - np.clip(R / (5.2 * U), 0, 1)
    port[window] = (base.hexcolor("ffe39a") + (base.hexcolor("fff6d6") - base.hexcolor("ffe39a")) * glow[..., None])[window]
    port[(R >= 5.2 * U) & (R < 6.6 * U)] = base.hexcolor("9aa5b7")
    port[disc(5.5 * U, 5.5 * U, 0.8 * U)] = base.hexcolor("ffffff")
    page.put((1, 1), port, base.flat_normal(), wrap_x=False, wrap_y=False)

    # landing pad: the brand's teal with a golden five-point star in a golden ring (glows)
    teal = shade(tex["plastic"][0], "139e9b", 0.9, 1.1)
    pad = teal.copy()
    pad[(R >= 6.5 * U) & (R <= 7.5 * U)] = base.hexcolor("ffd23f")
    pad[R > 7.5 * U] = shade(tex["plastic"][0], "0c7876", 0.9, 1.1)[R > 7.5 * U]
    spike = (0.5 + 0.5 * np.cos((ANG + np.pi / 2) * 5.0)) ** 2.5
    pad[R <= (1.7 + 4.3 * spike) * U] = base.hexcolor("ffd23f")
    page.put((2, 1), pad, base.flat_normal(), wrap_x=False, wrap_y=False)
    pad_side = shade(tex["plastic"][0], "0c7876", 0.9, 1.1)
    pad_side[(YY >= U) & (YY < 3 * U)] = base.hexcolor("ffd23f")
    pad_side[(np.mod(XX, 4 * U) < 0.8 * U) & (YY > 5 * U) & (YY < 15 * U)] = base.hexcolor("139e9b")
    page.put((3, 1), pad_side, base.flat_normal(), wrap_y=False)

    # star gold: glowing gold with little stars
    gold = shade(tex["metal"][0], "f5c542", 0.9, 1.2)
    for _ in range(7):
        cx, cy, s = 20 + rng.random() * (INNER - 40), 20 + rng.random() * (INNER - 40), 5 + rng.random() * 6
        star = ((np.abs(XX - cx) < s) & (np.abs(YY - cy) < 1.5)) | ((np.abs(YY - cy) < s) & (np.abs(XX - cx) < 1.5))
        gold[star] = base.hexcolor("fff0a8")
    page.put((4, 1), gold, base.flat_normal())

    # fake moon rock: the rock with a hairline door
    fake = rock.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.8
    page.put((5, 1), fake, tex["rock"][1])

    # base light: a soft white-blue lamp in a silver frame (unshaded)
    lamp = base.hexcolor("d8f1ff") + (base.hexcolor("ffffff") - base.hexcolor("d8f1ff")) * glow[..., None] * 0.6
    lamp = np.broadcast_to(lamp, (INNER, INNER, 3)).copy()
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp[frame] = shade(tex["metal"][0], "c3cbd8", 0.9, 1.05)[frame]
    lamp[(np.abs(YY - 7.5 * U) < 0.5 * U) & (XX > 3 * U) & (XX < 13 * U)] = base.hexcolor("ffffff")
    page.put((6, 1), np.clip(lamp, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = np.where((R < 3 * U)[..., None], base.hexcolor("ffffff"),
                        np.where((R < 6.5 * U)[..., None], base.hexcolor("d8f1ff"), shade(tex["metal"][0], "c3cbd8", 0.9, 1.05)))
    page.put((7, 1), np.clip(lamp_top, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    page.save()


def bricks(tex_brick: np.ndarray, hue: str, keep: float = 0.2) -> np.ndarray:
    return tint(tex_brick, hue, keep)


def boing() -> None:
    tex = {k: base.fetch(v) for k, v in {"moss": "Grass005", "soil": "Ground037", "rock": "Rock030", "plastic": "Plastic013A",
                                         "plaster": "Plaster001", "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260956)
    page = Page("boing")

    # boing moss: springy lime moss with little curls; its side: teal soil under a moss band
    lum = tex["moss"][0].mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-3)
    moss = np.clip(base.hexcolor("9be34a") * (0.45 + 0.55 * lum ** 1.5), 0, 1)
    top = moss.copy()
    for _ in range(9):
        cx, cy = 20 + rng.random() * (INNER - 40), 20 + rng.random() * (INNER - 40)
        for a in range(16):
            ang, r = a * 0.6, 3 + a * 1.4
            top[disc(cx + np.cos(ang) * r, cy + np.sin(ang) * r, 2.2)] = base.hexcolor("6fbf2a")
    page.put((0, 0), top, tex["moss"][1])
    soil = tint(tex["soil"][0], "2bb3a0", 0.25)
    page.put((2, 0), soil, tex["soil"][1])
    band = YY < 3.4 * U + 0.9 * U * np.sin(XX / INNER * 2 * np.pi * 5 + 0.3)
    page.put((1, 0), np.where(band[..., None], moss, soil), np.where(band[..., None], tex["moss"][1], tex["soil"][1]),
             wrap_y=False)
    rock = tint(tex["rock"][0], "8a5cc9", 0.25)
    page.put((3, 0), rock, tex["rock"][1])

    # jelly: glossy pink with round shines
    jelly = shade(tex["plastic"][0], "ff7ab8", 0.92, 1.08)
    jelly[disc(0.32 * INNER, 0.32 * INNER, 0.12 * INNER)] = base.hexcolor("ffd1e8")
    jelly[disc(0.72 * INNER, 0.7 * INNER, 0.05 * INNER)] = base.hexcolor("ffd1e8")
    page.put((4, 0), jelly, base.flat_normal())

    # spring stem: white with a pale blue coil; its top: rings
    stem = shade(tex["plaster"][0], "f5f0e6", 0.92, 1.06)
    coil = np.mod(XX + YY * 2, 8 * U) < 2 * U
    stem_side = stem.copy()
    stem_side[coil] = base.hexcolor("a8d8ff")
    page.put((5, 0), stem_side, base.flat_normal())
    stem_top = stem.copy()
    stem_top[np.mod(R / U, 3.0) < 1.0] = base.hexcolor("a8d8ff")
    page.put((6, 0), stem_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # spring cap: orange with yellow spots, a darker rim on its side, cream gills under it
    cap = shade(tex["plastic"][0], "ff9f3a", 0.9, 1.1)
    spots = np.zeros((INNER, INNER), bool)
    for sx, sy, sr in [(4, 4, 2.2), (11, 5, 1.8), (7, 11, 2.4), (13, 12, 1.5), (2, 12, 1.3)]:
        spots |= disc(sx * U, sy * U, sr * U)
    cap_top = cap.copy()
    cap_top[spots] = base.hexcolor("fff07a")
    page.put((7, 0), cap_top, base.flat_normal(), wrap_x=False, wrap_y=False)
    cap_side = cap.copy()
    cap_side[YY > 12 * U] = shade(tex["plastic"][0], "d9771c")[YY > 12 * U]
    for sx, sy, sr in [(3.5, 4.5, 1.2), (10.5, 2.5, 1.1), (13, 7, 0.8), (7.5, 8, 1.0)]:
        cap_side[disc(sx * U, sy * U, sr * U)] = base.hexcolor("fff07a")
    page.put((0, 1), cap_side, base.flat_normal(), wrap_y=False)
    gill = np.mod(np.floor(ANG / (2 * np.pi) * 20.0), 2) == 0
    gills = np.where(gill[..., None], base.hexcolor("f3e2c0"), base.hexcolor("d7c29d")).astype(np.float32)
    gills[R < 2 * U] = base.hexcolor("f5f0e6")
    page.put((1, 1), gills, base.flat_normal(), wrap_x=False, wrap_y=False)

    # glow bulb: a yellow-green light in a dark lilac frame (unshaded)
    glow = 1 - np.clip(R / (6.5 * U), 0, 1)
    bulb = np.where((R < 6.5 * U)[..., None], base.hexcolor("d9ff6b") + (base.hexcolor("f7ffd0") - base.hexcolor("d9ff6b"))
                    * glow[..., None], base.hexcolor("9f7fd6"))
    page.put((2, 1), np.clip(bulb, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # boing brick: lilac bricks; fake boing rock: the rock with a hairline door
    page.put((3, 1), bricks(tex["brick"][0], "c7a6f2"), tex["brick"][1])
    fake = rock.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.75
    page.put((4, 1), fake, tex["rock"][1])
    page.save()


STRIPES = ["ff6b6b", "ffa94d", "ffe066", "69db7c", "4dabf7", "b197fc"]


def rainbow() -> None:
    tex = {k: base.fetch(v) for k, v in {"grass": "Grass001", "rock": "Rock030", "ice": "Ice002", "plaster": "Plaster001",
                                         "brick": "Bricks090"}.items()}
    rng = np.random.default_rng(20260957)
    page = Page("rainbow")

    # prism grass: pastel mint with sparkles in every colour; its side: a band over pale rock
    grass = tint(tex["grass"][0], "aaeec4", 0.2)   # a clear pastel mint (d8f7e2 washed out to white)
    top = grass.copy()
    for i in range(18):
        top[disc(rng.random() * INNER, rng.random() * INNER, 2.0)] = base.hexcolor(STRIPES[i % 6])
    page.put((0, 0), top, tex["grass"][1])
    pale = shade(tex["plaster"][0], "f4eef8", 0.92, 1.06)
    band = YY < 3.4 * U + 0.9 * U * np.sin(XX / INNER * 2 * np.pi * 4 + 1.1)
    # under the grass lip the six rainbow bands (2 game pixels each, red at the top), like the pixel page: every terrace
    # step shows a rainbow (2026-09-29: the pale sides hid the stripes)
    side = pale.copy()
    for i, hue in enumerate(STRIPES):
        rows = (YY >= (4 + 2 * i) * U) & (YY < (6 + 2 * i) * U)
        side[rows] = tint(tex["rock"][0], hue, 0.18)[rows]
    page.put((1, 0), np.where(band[..., None], grass, side), np.where(band[..., None], tex["grass"][1], tex["rock"][1]),
             wrap_y=False)

    # the six stripes: the same rock in each colour of the rainbow
    stripes = []
    for i, hue in enumerate(STRIPES):
        c = tint(tex["rock"][0], hue, 0.18)
        stripes.append(c)
        page.put((2 + i, 0), c, tex["rock"][1])

    # prism crystal: clear glassy white facets with rainbow edges (unshaded)
    ice = shade(tex["ice"][0], "f7fbff", 0.95, 1.1)
    facet = np.mod(XX / U, 5.0) < 0.9
    crystal = ice.copy()
    for i, hue in enumerate(STRIPES):
        crystal[facet & (np.floor(YY / (INNER / 6)) == i)] = base.hexcolor(hue)
    page.put((0, 1), crystal, base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    ctop = ice.copy()
    for i, hue in enumerate(STRIPES):
        ctop[(np.floor(ring) == i * 1.2 // 1) & (np.mod(np.floor(ring), 2) == 0)] = base.hexcolor(hue)
    page.put((1, 1), ctop, base.flat_normal(), wrap_x=False, wrap_y=False)

    # prism brick: white bricks
    page.put((2, 1), bricks(tex["brick"][0], "fbf8ff", 0.15), tex["brick"][1])

    # prism lamp: white with rainbow bands; its top: a white light in rainbow rings (unshaded)
    lamp = np.zeros((INNER, INNER, 3), np.float32)
    for i, hue in enumerate(STRIPES):
        rows = np.floor(YY / (INNER / 6)) == i
        lamp[rows] = np.clip(base.hexcolor(hue) * 0.6 + 0.4, 0, 1)
    lamp[(XX < 2 * U) | (XX >= INNER - 2 * U)] = base.hexcolor("e3d6f5")
    page.put((3, 1), lamp, base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = np.broadcast_to(base.hexcolor("e3d6f5"), (INNER, INNER, 3)).copy()
    for i, hue in enumerate(STRIPES):
        lamp_top[(R >= (3.5 + i * 0.6) * U) & (R < (4.1 + i * 0.6) * U)] = np.clip(base.hexcolor(hue) * 0.7 + 0.3, 0, 1)
    lamp_top[R < 3.5 * U] = base.hexcolor("ffffff")
    page.put((4, 1), lamp_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # fake blue stripe: the blue rock with a hairline door
    fake = stripes[4].copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.7
    page.put((5, 1), fake, tex["rock"][1])
    page.save()


def mars() -> None:
    tex = {k: base.fetch(v) for k, v in {"sand": "Ground097", "dirt": "Ground103", "basalt": "Rock031", "deep": "Rock035",
                                         "pale": "Ground093A", "snow": "Snow003", "frost": "Ice001", "ice": "Ice002",
                                         "plastic": "Plastic013A", "rubber": "Leather026", "metal": "Metal034"}.items()}
    rng = np.random.default_rng(20260919)
    page = Page("mars")

    # Mars dust: rust-red with the sand's wind ripples; regolith: darker rusty pebbles; the side: a dust band over it
    dust = tint(tex["sand"][0], "c8643a", 0.12)
    page.put((0, 0), dust, tex["sand"][1])
    regolith = tint(tex["dirt"][0], "8f4328", 0.15)
    page.put((2, 0), regolith, tex["dirt"][1])
    band = YY < 3.6 * U + 0.8 * U * np.sin(XX / INNER * 2 * np.pi * 3 + 0.7)
    page.put((1, 0), np.where(band[..., None], dust, regolith), np.where(band[..., None], tex["sand"][1], tex["dirt"][1]),
             wrap_y=False)

    # basalt and deep basalt: dark lava rock with a few round gas bubbles (vesicles)
    basalt = tint(tex["basalt"][0], "47403f", 0.35)
    bh = np.zeros((INNER, INNER), np.float32)
    for _ in range(14):
        cx, cy, cr = rng.random() * INNER, rng.random() * INNER, 2 + rng.random() * 4
        d = np.hypot(XX - cx, YY - cy) / cr
        bh -= np.where(d < 1, np.sqrt(np.clip(1 - d * d, 0, 1)), 0)
        basalt[d < 1] *= 0.7
    basalt_n = base.normal_from_height(bh, 3.0) * 0.5 + tex["basalt"][1] * 0.5
    page.put((3, 0), basalt, basalt_n)
    page.put((4, 0), tint(tex["deep"][0], "363032", 0.3), tex["deep"][1])

    # layered rock: pale; its side in thin layers of three shades
    pale = tint(tex["pale"][0], "d9b48f", 0.2)
    page.put((5, 0), pale, tex["pale"][1])
    layer = np.mod(np.floor(YY / U + 0.6 * np.sin(XX / INNER * 2 * np.pi)), 5)
    layered = pale * np.where(layer[..., None] == 0, 1.12, np.where(layer[..., None] == 3, 0.86, 1.0))
    lh = np.where(layer == 3, -0.4, 0.0).astype(np.float32)
    page.put((6, 0), np.clip(layered, 0, 1), base.normal_from_height(lh, 2.0))

    # polar ice: white snow-ice; its side: ice with thin dusty layers (the caps' layered deposits)
    ice = shade(tex["snow"][0], "f2f6fb", 0.92, 1.06)
    page.put((7, 0), ice, tex["snow"][1])
    dusty = (np.mod(YY, 5 * U) >= 2 * U) & (np.mod(YY, 5 * U) < 3 * U)
    ice_side = ice.copy()
    ice_side[dusty] = shade(tex["sand"][0], "d8b89c", 0.9, 1.08)[dusty]
    page.put((0, 1), ice_side, tex["snow"][1], wrap_y=False)

    # dry ice: frosty blue-white crystals with sparkles
    frost = shade(tex["frost"][0], "e2eefc", 0.85, 1.12)
    for _ in range(20):
        frost[disc(rng.random() * INNER, rng.random() * INNER, 1.4)] = base.hexcolor("ffffff")
    page.put((1, 1), frost, tex["frost"][1])

    # gypsum crystal: pale peach-white facets (unshaded: it glows); its end: a gem with a star of light
    gyp = shade(tex["ice"][0], "fff1dc", 0.97, 1.12)
    facet = np.mod(XX / U, 5.0)
    crystal = gyp * (0.88 + 0.2 * (facet < 0.8)[..., None]) * (1.0 - 0.12 * (facet > 4.2)[..., None])
    page.put((2, 1), np.clip(crystal, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    top = gyp * (0.86 + 0.2 * (np.mod(ring, 3.0) < 0.8)[..., None])
    top[((np.abs(XX - INNER / 2) < 0.5 * U) | (np.abs(YY - INNER / 2) < 0.5 * U)) & (R < 3 * U)] = base.hexcolor("ffffff")
    top[ring > 7.2] = base.hexcolor("f5d3b0")
    page.put((3, 1), np.clip(top, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the rover's panel: white with seams and bolts
    panel = shade(tex["plastic"][0], "eef0f2", 0.94, 1.04)
    seam = (YY < 3) | (XX < 3) | (np.abs(XX - INNER / 2) < 2)
    panel[seam] = base.hexcolor("c4c9cf")
    ph = np.zeros((INNER, INNER), np.float32)
    ph[seam] = -0.5
    for bx, by in [(2, 2), (6, 2), (10, 2), (14, 2), (2, 13), (6, 13), (10, 13), (14, 13)]:
        m = disc(bx * U + U / 2, by * U + U / 2, 0.55 * U)
        panel[m] = base.hexcolor("9aa2ab")
        ph[m] = 0.6
    page.put((4, 1), panel, base.normal_from_height(ph, 3.0))

    # the wheel: a dark tread with light chevron cleats; its side: a round tyre, a silver hub and spokes
    tread = tint(tex["rubber"][0], "3b3f45", 0.3)
    cleat = np.mod(YY / U - np.abs(XX / U - 8), 5.0) < 0.9
    tread[cleat] = shade(tex["metal"][0], "9aa0a8", 0.9, 1.05)[cleat]
    page.put((5, 1), tread, base.normal_from_height(np.where(cleat, 0.5, 0.0).astype(np.float32), 3.0))
    hub = tint(tex["rubber"][0], "3b3f45", 0.3)
    spoke = np.mod(np.floor(ANG / (2 * np.pi) * 12.0), 2) == 0
    silver = shade(tex["metal"][0], "c9ced4", 0.9, 1.05)
    spokes = (R < 5.5 * U) & spoke
    hub[spokes] = shade(tex["metal"][0], "9aa0a8", 0.9, 1.05)[spokes]
    hub[R < 2.2 * U] = silver[R < 2.2 * U]
    rim = (R >= 5.5 * U) & (R < 6.3 * U)
    hub[rim] = silver[rim] * 0.8
    page.put((6, 1), hub, base.normal_from_height(-np.clip(R / (6.3 * U), 0, 1).astype(np.float32), 2.0),
             wrap_x=False, wrap_y=False)

    # solar panel: deep blue cells in a silver grid, with a sheen
    solar = shade(tex["plastic"][0], "24479a", 0.9, 1.1)
    solar = solar * (1.0 + 0.25 * (base.smooth_noise(20.0)[..., None] - 0.5))
    grid = (np.mod(XX, 4 * U) < 0.7 * U) | (np.mod(YY, 4 * U) < 0.7 * U)
    solar[grid] = base.hexcolor("c0c8d4")
    page.put((7, 1), np.clip(solar, 0, 1), base.normal_from_height(np.where(grid, 0.4, 0.0).astype(np.float32), 3.0))

    # gold foil: crinkled gold, facets of light and shadow
    crinkle = (np.sin(XX / U * 1.3 + YY / U * 0.4) + np.sin(YY / U * 1.1 - XX / U * 0.6) + np.sin((XX + YY) / U * 0.7)) / 3
    foil = shade(tex["metal"][0], "e8b53a", 0.95, 1.05) * (0.85 + 0.35 * (crinkle[..., None] + 1) / 2)
    page.put((0, 2), np.clip(foil, 0, 1), base.normal_from_height(crinkle.astype(np.float32), 6.0))

    # fake basalt: the basalt with a hairline door
    fake = basalt.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.7
    page.put((1, 2), fake, basalt_n)

    # the rover's light: a warm lamp in a grey frame; its end: a round lens (unshaded: they glow)
    lamp = np.broadcast_to(base.hexcolor("fff4d6"), (INNER, INNER, 3)).copy()
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp[frame] = shade(tex["metal"][0], "8d949c", 0.9, 1.05)[frame]
    lamp[(np.abs(YY - 6.5 * U) < 0.5 * U) & (XX > 4 * U) & (XX < 12 * U)] = base.hexcolor("ffffff")
    page.put((2, 2), lamp, base.flat_normal(), wrap_x=False, wrap_y=False)
    lens = np.where((R < 2.5 * U)[..., None], base.hexcolor("ffffff"),
                    np.where((R < 5.8 * U)[..., None], base.hexcolor("fff4d6"), shade(tex["metal"][0], "8d949c", 0.9, 1.05)))
    page.put((3, 2), np.clip(lens, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    page.save()


def europa() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow003", "snow2": "Snow004", "ice": "Ice002", "ice3": "Ice003",
                                         "frost": "Ice001", "dirt": "Ground103", "rock": "Rock030",
                                         "plastic": "Plastic013A", "metal": "Metal034", "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260920)
    page = Page("europa")

    # Europa ice: smooth white water ice with faint blue hairline cracks; its side: white with a faint blue layer
    ice = shade(tex["snow"][0], "f2f4f8", 0.94, 1.05)
    ice_top = ice.copy()
    for _ in range(3):
        x0, y0, ang = rng.random() * INNER, rng.random() * INNER, rng.random() * np.pi
        d = np.abs((XX - x0) * np.sin(ang) - (YY - y0) * np.cos(ang))
        ice_top[d < 1.2] = base.hexcolor("dde7f1")
    soft = tex["snow"][1] * 0.4 + base.flat_normal() * 0.6
    page.put((0, 0), ice_top, soft)
    ice_side = ice.copy()
    ice_side[(YY > 11 * U) & (YY < 12.2 * U)] = base.hexcolor("dde7f1")
    page.put((1, 0), ice_side, soft, wrap_y=False)

    # reddish ice: a crack's stain (salts and sulphur), streaked along it; its side: darker at the top
    stain = tint(tex["dirt"][0], "a65f40", 0.15)
    streak = np.sin(XX / U * 0.25 + YY / U * 1.3)
    linea = stain * (1.0 + 0.12 * (streak > 0.75)[..., None] - 0.12 * (streak < -0.8)[..., None])
    page.put((2, 0), np.clip(linea, 0, 1), tex["dirt"][1])
    linea_side = stain * np.where((YY < 3 * U)[..., None], 0.85, 1.0)
    fade = np.clip((YY - 11 * U) / (5 * U), 0, 1)[..., None]
    linea_side = linea_side * (1 - fade * 0.5) + base.hexcolor("dcbca4") * fade * 0.5
    page.put((3, 0), np.clip(linea_side, 0, 1), tex["dirt"][1], wrap_y=False)

    # stained ice: the ridges, pale tan-pink; its side: stained on top, white ice underneath
    band = tint(tex["snow2"][0], "dcbca4", 0.2)
    page.put((4, 0), band, tex["snow2"][1])
    top_band = YY < 4.5 * U + 0.5 * U * np.sin(XX / INNER * 2 * np.pi * 3)
    page.put((5, 0), np.where(top_band[..., None], band, ice), tex["snow2"][1], wrap_y=False)

    # deep ice: blue, in thin layers, with bubbles
    deep = tint(tex["ice"][0], "8cb4e2", 0.25)
    layer = np.mod(np.floor(YY / U + 1.2 * np.sin(XX / U * 0.5)), 5)
    deep = deep * np.where(layer[..., None] == 0, 1.12, np.where(layer[..., None] == 3, 0.88, 1.0))
    for _ in range(10):
        deep[disc(rng.random() * INNER, rng.random() * INNER, 1.5 + rng.random() * 2.0)] = base.hexcolor("d6e8fb")
    deep = np.clip(deep, 0, 1)
    page.put((6, 0), deep, tex["ice"][1])

    # seafloor rock: dark grey-brown rock under the ice
    page.put((7, 0), tint(tex["rock"][0], "5b5652", 0.3), tex["rock"][1])

    # glowing blue ice (unshaded: it glows): bright facets; its top: rings of light
    glow = shade(tex["ice3"][0], "9fe8ff", 0.95, 1.1)
    facet = np.mod(XX / U + np.floor(YY / U / 2), 5.0)
    glow_side = glow * (1.0 + 0.18 * (facet < 0.9)[..., None] - 0.1 * (facet > 4.1)[..., None])
    page.put((0, 1), np.clip(glow_side, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    glow_top = glow.copy()
    glow_top[(ring < 2) | (np.mod(np.floor(ring), 3) == 0)] = base.hexcolor("e8fcff")
    page.put((1, 1), glow_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # sea salt: little white and pale-yellow cubes (unshaded: it glows)
    salt = shade(tex["frost"][0], "fff5d6", 0.95, 1.06)
    cube = np.mod(np.floor(XX / (4 * U)) + np.floor(YY / (4 * U)), 2) == 0
    edge = (np.mod(XX, 4 * U) < 0.8 * U) | (np.mod(YY, 4 * U) < 0.8 * U)
    salt_side = np.where(cube[..., None], salt, salt * 0.6 + base.hexcolor("f3dd9c") * 0.4)
    salt_side[edge] = base.hexcolor("f3dd9c")
    page.put((2, 1), np.clip(salt_side, 0, 1).astype(np.float32), base.flat_normal())
    salt_top = salt.copy()
    salt_top[(ring >= 7) | (np.floor(ring) == 3)] = base.hexcolor("f3dd9c")
    page.put((3, 1), salt_top, base.flat_normal(), wrap_x=False, wrap_y=False)

    # the geyser vent (unshaded): deep blue water in the middle, a frosty ring, salt at the rim; its side: a salt crust
    k = np.clip((R / U - 1.5) / 3.5, 0, 1)[..., None]
    water = base.hexcolor("1f5aa0") * (1 - k) + base.hexcolor("9fe8ff") * k
    vent = np.where((R < 5 * U)[..., None], water, np.where((R < 6.5 * U)[..., None], base.hexcolor("d4f1ff"), salt))
    page.put((4, 1), np.clip(vent, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    vent_side = np.where((YY < 3 * U)[..., None], salt, np.where((YY < 8 * U)[..., None], base.hexcolor("d4f1ff"), glow))
    page.put((5, 1), np.clip(vent_side, 0, 1).astype(np.float32), base.flat_normal(), wrap_y=False)

    # the Ice Lander's panel: white with a blue stripe, seams and bolts
    panel = shade(tex["plastic"][0], "f1f4f8", 0.94, 1.04)
    seam = (YY < 3) | (XX < 3)
    panel[seam] = base.hexcolor("c8d0da")
    panel[(YY >= 7 * U) & (YY < 9 * U)] = base.hexcolor("3f7fd8")
    ph = np.zeros((INNER, INNER), np.float32)
    ph[seam] = -0.5
    for bx, by in [(3, 3), (12, 3), (3, 12), (12, 12)]:
        m = disc(bx * U + U / 2, by * U + U / 2, 0.55 * U)
        panel[m] = base.hexcolor("9aa3ad")
        ph[m] = 0.6
    page.put((6, 1), panel, base.normal_from_height(ph, 3.0))

    # the melt probe (and the legs): a metal tube with orange bands; its end: a round cap
    metal = shade(tex["metal"][0], "9aa3ad", 0.9, 1.08)
    probe = metal.copy()
    probe[(XX < 2 * U) | (XX >= 14 * U)] *= 0.72
    orange = (np.mod(YY, 8 * U) >= 2 * U) & (np.mod(YY, 8 * U) < 4 * U)
    probe[orange] = shade(tex["metal"][0], "ffb13b", 0.92, 1.05)[orange]
    tube = -np.abs(XX - INNER / 2) / (INNER / 2)
    page.put((7, 1), np.clip(probe, 0, 1), base.normal_from_height(tube.astype(np.float32), 2.0), wrap_x=False)
    cap = np.where((R < 3 * U)[..., None], metal * 1.2, np.where((R < 6.5 * U)[..., None], metal, metal * 0.72))
    page.put((0, 2), np.clip(cap, 0, 1).astype(np.float32),
             base.normal_from_height(-np.clip(R / (6.5 * U), 0, 1).astype(np.float32), 2.0), wrap_x=False, wrap_y=False)

    # the lander's light (unshaded): a cool lamp in a grey frame; its lens
    lamp = np.broadcast_to(base.hexcolor("e6f6ff"), (INNER, INNER, 3)).copy()
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp[frame] = metal[frame]
    lamp[(np.abs(YY - 6.5 * U) < 0.5 * U) & (XX > 4 * U) & (XX < 12 * U)] = base.hexcolor("ffffff")
    page.put((1, 2), lamp, base.flat_normal(), wrap_x=False, wrap_y=False)
    lens = np.where((R < 2.5 * U)[..., None], base.hexcolor("ffffff"),
                    np.where((R < 5.8 * U)[..., None], base.hexcolor("e6f6ff"), metal))
    page.put((2, 2), np.clip(lens, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # ice bricks: pale blue bricks; fake deep ice: the deep ice with a hairline door
    page.put((3, 2), bricks(tex["brick"][0], "d3e6f8", 0.15), tex["brick"][1])
    fake = deep.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((4, 2), fake, tex["ice"][1])
    page.save()


def io() -> None:
    tex = {k: base.fetch(v) for k, v in {"ground": "Ground037", "dirt": "Ground103", "snow": "Snow004",
                                         "dust": "Ground097", "rock": "Rock030", "basalt": "Rock031", "ice": "Ice002",
                                         "plastic": "Plastic013A", "metal": "Metal034", "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260921)
    page = Page("io")
    layers = np.mod(np.floor(YY / U + 1.2 * np.sin(XX / U * 0.7)), 6) == 0

    # yellow sulphur: soft powder with lighter grains; its side: thin layers, brighter at the top
    sulphur = shade(tex["ground"][0], "f2dc4c", 0.78, 1.16)   # the ground's light and shade: a powdery grain
    grains = sulphur.copy()
    for _ in range(40):
        grains[disc(rng.random() * INNER, rng.random() * INNER, 1.2 + rng.random() * 1.5)] = base.hexcolor("fbef8e")
    page.put((0, 0), grains, tex["ground"][1])
    side = np.where(layers[..., None], sulphur * 0.88, sulphur)
    side[YY < 2 * U] = np.clip(sulphur[YY < 2 * U] * 1.08, 0, 1)
    page.put((1, 0), np.clip(side, 0, 1), tex["ground"][1], wrap_y=False)

    # orange sulphur
    orange = shade(tex["dirt"][0], "eb9a3a", 0.78, 1.16)
    page.put((2, 0), orange, tex["dirt"][1])
    page.put((3, 0), np.where(layers[..., None], orange * 0.88, orange), tex["dirt"][1], wrap_y=False)

    # sulphur frost (frozen sulphur dioxide): white; its side: a white coat over yellow sulphur
    frost = shade(tex["snow"][0], "f4f2e6", 0.94, 1.05)
    page.put((4, 0), frost, tex["snow"][1])
    coat = YY < 4.5 * U + 0.6 * U * np.sin(XX / INNER * 2 * np.pi * 3)
    page.put((5, 0), np.where(coat[..., None], frost, sulphur), tex["snow"][1], wrap_y=False)

    # red sulphur (a plume's ring); its side: a red coat over yellow sulphur
    red = tint(tex["dust"][0], "c9452e", 0.12)
    page.put((6, 0), red, tex["dust"][1])
    page.put((7, 0), np.where(coat[..., None], red, sulphur), tex["dust"][1], wrap_y=False)

    # Io's rock: warm grey-brown; black lava rock
    rock = tint(tex["rock"][0], "8c7c68", 0.25)
    page.put((0, 1), rock, tex["rock"][1])
    black = tint(tex["basalt"][0], "2b2726", 0.2)
    page.put((1, 1), black, tex["basalt"][1])

    # the lava crust (unshaded: it glows): black plates with glowing orange cracks; its side: crust over glowing lava
    seeds = rng.random((5, 2)) * INNER
    d1 = np.full((INNER, INNER), np.inf, np.float32)
    d2 = np.full((INNER, INNER), np.inf, np.float32)
    for sx, sy in seeds:
        for ox in (-INNER, 0, INNER):
            for oy in (-INNER, 0, INNER):
                d = np.hypot(XX - sx - ox, YY - sy - oy)
                d2 = np.where(d < d1, d1, np.minimum(d2, d))
                d1 = np.minimum(d1, d)
    gap = (d2 - d1) / U
    crust = black * 0.8
    crust[gap < 0.95] = base.hexcolor("ff9a2a")
    crust[gap < 0.45] = base.hexcolor("ffd35a")
    page.put((2, 1), np.clip(crust, 0, 1), base.flat_normal())
    swirl = np.sin(XX / U * 0.6 + np.sin(YY / U * 0.5) * 2.0) + np.cos(YY / U * 0.45 - XX / U * 0.2)
    lava = np.where((swirl > 1.5)[..., None], base.hexcolor("fff3b0"),
                    np.where((swirl > 0.4)[..., None], base.hexcolor("ffd84a"),
                             np.where((swirl < -1.3)[..., None], base.hexcolor("f2581a"), base.hexcolor("ff8a1e"))))
    lava = np.clip(lava * (0.92 + 0.16 * base.smooth_noise(6.0)[..., None]), 0, 1).astype(np.float32)
    crust_side = np.where((YY < 5.5 * U)[..., None], black * 0.8, lava)
    page.put((3, 1), np.clip(crust_side, 0, 1).astype(np.float32), base.flat_normal(), wrap_y=False)

    # hot lava (unshaded): bright swirls; its side: glowing bands
    page.put((4, 1), lava, base.flat_normal())
    band = np.mod(np.floor(YY / U + 1.5 * np.sin(XX / U * 0.6)), 5)
    lava_side = np.where((band == 0)[..., None], base.hexcolor("ffd84a"),
                         np.where((band == 3)[..., None], base.hexcolor("f2581a"), base.hexcolor("ff8a1e")))
    page.put((5, 1), lava_side.astype(np.float32), base.flat_normal())

    # the volcano vent (unshaded): a glowing throat ringed with black lava and sulphur; its side: rock glowing below
    vent = np.where((R < 1.8 * U)[..., None], base.hexcolor("fff3b0"),
                    np.where((R < 3.2 * U)[..., None], base.hexcolor("ffd84a"),
                             np.where((R < 4.5 * U)[..., None], base.hexcolor("ff8a1e"),
                                      np.where((R < 6.3 * U)[..., None], black, sulphur))))
    page.put((6, 1), vent.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    vent_side = np.where((YY < 2 * U)[..., None], sulphur, np.where((YY < 8 * U)[..., None], black, lava))
    page.put((7, 1), vent_side.astype(np.float32), base.flat_normal(), wrap_y=False)

    # sulphur crystals (unshaded: they glow): yellow facets; the tip: a bright gem
    gem = shade(tex["ice"][0], "fbef8e", 0.95, 1.1)
    facet = np.mod(XX / U + np.floor(YY / U / 3), 4.0)
    crystal = gem * (1.0 + 0.15 * (facet < 0.9)[..., None] - 0.18 * (facet > 3.1)[..., None])
    page.put((0, 2), np.clip(crystal, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    tip = gem.copy()
    tip[np.mod(np.floor(ring), 3) == 0] = base.hexcolor("ffffff")
    tip[ring >= 7] = base.hexcolor("d9bb2e")
    page.put((1, 2), np.clip(tip, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the heat tiles: white squares with grey seams and a gold stripe
    tile = shade(tex["plastic"][0], "eef0f2", 0.94, 1.04)
    seam = (np.mod(XX, 8 * U) < 0.6 * U) | (np.mod(YY, 8 * U) < 0.6 * U)
    tile[seam] = base.hexcolor("b9bec6")
    tile[(YY >= 11 * U) & (YY < 13 * U)] = base.hexcolor("e8b43a")
    th = np.zeros((INNER, INNER), np.float32)
    th[seam] = -0.6
    page.put((2, 2), tile, base.normal_from_height(th, 3.0))

    # the lander's legs: a metal strut with dark bands; its foot
    metal = shade(tex["metal"][0], "9aa0a8", 0.9, 1.08)
    leg = metal.copy()
    leg[(XX < 3 * U) | (XX >= 13 * U)] *= 0.72
    leg[(np.mod(YY, 8 * U) >= 4 * U) & (np.mod(YY, 8 * U) < 5 * U)] *= 0.72
    tube = -np.abs(XX - INNER / 2) / (INNER / 2)
    page.put((3, 2), np.clip(leg, 0, 1), base.normal_from_height(tube.astype(np.float32), 2.0), wrap_x=False)
    foot = np.where((R < 3 * U)[..., None], metal * 1.2, np.where((R < 6.5 * U)[..., None], metal, metal * 0.72))
    page.put((4, 2), np.clip(foot, 0, 1).astype(np.float32),
             base.normal_from_height(-np.clip(R / (6.5 * U), 0, 1).astype(np.float32), 2.0), wrap_x=False, wrap_y=False)

    # the heat camera (unshaded): a warm glowing lens in a grey frame; its top: a lamp
    lens = np.where((R < 2 * U)[..., None], base.hexcolor("ffc07a"),
                    np.where((R < 6 * U)[..., None], base.hexcolor("ff6a3a"), metal))
    page.put((5, 2), np.clip(lens, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp = np.broadcast_to(base.hexcolor("ffc07a"), (INNER, INNER, 3)).copy()
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp[frame] = metal[frame]
    lamp[(np.abs(YY - 6.5 * U) < 0.5 * U) & (XX > 4 * U) & (XX < 12 * U)] = base.hexcolor("ffffff")
    page.put((6, 2), lamp, base.flat_normal(), wrap_x=False, wrap_y=False)

    # sulphur bricks; fake Io rock: the rock with a hairline door
    page.put((7, 2), bricks(tex["brick"][0], "f2dc4c", 0.15), tex["brick"][1])
    fake = rock.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((0, 3), fake, tex["rock"][1])
    page.save()


def titan() -> None:
    tex = {k: base.fetch(v) for k, v in {"dirt": "Ground103", "ripples": "Ground097", "rock": "Rock030", "ice": "Ice002",
                                         "plastic": "Plastic013A", "metal": "Metal034", "cloth": "Fabric004",
                                         "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260922)
    page = Page("titan")
    layers = np.mod(np.floor(YY / U + 1.3 * np.sin(XX / U * 0.6)), 5) == 0

    # Titan's soil: orange-brown grains; its side: thin layers, lighter at the top
    soil = shade(tex["dirt"][0], "c07a3c", 0.8, 1.15)
    page.put((0, 0), soil, tex["dirt"][1])
    side = np.where(layers[..., None], soil * 0.86, soil)
    side[YY < 2 * U] = np.clip(soil[YY < 2 * U] * 1.08, 0, 1)
    side = np.clip(side, 0, 1)
    page.put((1, 0), side, tex["dirt"][1], wrap_y=False)

    # ice pebbles on the soil: rounded pebbles of water ice, lit from the top left (their own normals)
    ice = tint(tex["rock"][0], "e8e4dc", 0.2)

    def pebbles(base_color: np.ndarray, spots: list) -> tuple:
        color = base_color.copy()
        height = np.zeros((INNER, INNER), np.float32)
        for cx, cy, r in spots:
            d = np.hypot(XX - cx * U, (YY - cy * U) * 1.25) / (r * U)
            inside = d < 1.0
            h = np.sqrt(np.clip(1.0 - d * d, 0, 1))
            lit = np.clip(0.78 + 0.35 * (-(XX - cx * U) - (YY - cy * U)) / (r * U), 0.6, 1.15)
            color[inside] = np.clip(ice[inside] * lit[inside][..., None], 0, 1)
            height = np.maximum(height, np.where(inside, h, 0))
        return color, base.normal_from_height(height, 4.0)

    top, top_n = pebbles(soil, [(3.5, 3.5, 3.0), (10.5, 3.0, 2.6), (7.0, 8.5, 3.4), (13.0, 10.0, 2.8), (3.0, 12.0, 2.8),
                                (9.5, 14.0, 2.2), (14.5, 5.5, 1.8)])
    page.put((2, 0), top, top_n)
    side_p, side_n = pebbles(side, [(2.5, 2.0, 2.4), (7.5, 2.5, 2.8), (12.5, 1.8, 2.4), (5.0, 6.0, 1.6)])
    page.put((3, 0), side_p, side_n, wrap_y=False)

    # the dunes' dark grains: wind ripples; its side: sloping beds
    dune = tint(tex["ripples"][0], "4a3526", 0.12)
    page.put((4, 0), dune, tex["ripples"][1])
    beds = np.mod(np.floor(YY / U + XX / U / 3), 5)
    page.put((5, 0), np.clip(dune * (1.0 - 0.12 * (beds == 0)[..., None] + 0.1 * (beds == 3)[..., None]), 0, 1),
             tex["ripples"][1], wrap_y=False)

    # the wet shore: dark damp soil with glints; its side: a dark wet band over the soil
    wet = shade(tex["dirt"][0], "6e4a2c", 0.8, 1.12)
    for _ in range(30):
        wet[disc(rng.random() * INNER, rng.random() * INNER, 0.8 + rng.random() * 1.0)] = base.hexcolor("c9a06a")
    page.put((6, 0), wet, tex["dirt"][1])
    page.put((7, 0), np.where((YY < 5 * U)[..., None], wet, side), tex["dirt"][1], wrap_y=False)

    # icy rock: pale grey-blue ice as hard as stone
    rock = tint(tex["rock"][0], "b9c6cf", 0.2)
    page.put((0, 1), rock, tex["rock"][1])

    # shore crystals (unshaded: they glow): cream facets; the tip: a bright gem
    gem = shade(tex["ice"][0], "fff4dc", 0.95, 1.08)
    facet = np.mod(XX / U + np.floor(YY / U / 3), 4.0)
    crystal = gem * (1.0 + 0.1 * (facet < 0.9)[..., None] - 0.12 * (facet > 3.1)[..., None])
    page.put((1, 1), np.clip(crystal, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    tip = gem.copy()
    tip[np.mod(np.floor(ring), 3) == 0] = base.hexcolor("ffffff")
    tip[ring >= 7] = base.hexcolor("f1dcb2")
    page.put((2, 1), np.clip(tip, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the probe's shell: white with a band of gold foil (side), rings of white and gold (top)
    white = shade(tex["plastic"][0], "f1f2f4", 0.94, 1.04)
    gold = shade(tex["metal"][0], "e3b23c", 0.85, 1.15)
    band = (YY >= 6 * U) & (YY < 11 * U)
    shell = np.where(band[..., None], gold, white)
    seam = (np.abs(YY - 5.5 * U) < 0.5 * U) | (np.abs(YY - 11.5 * U) < 0.5 * U)
    shell[seam] = base.hexcolor("b9bec6")
    sh = np.where(band, 0.4, 0.0).astype(np.float32)
    sh[seam] = -0.4
    page.put((3, 1), np.clip(shell, 0, 1), base.normal_from_height(sh, 3.0), wrap_y=False)
    rings = np.where((R < 3 * U)[..., None], white,
                     np.where((R < 5 * U)[..., None], gold,
                              np.where((R < 5.8 * U)[..., None], base.hexcolor("b9bec6"), white)))
    page.put((4, 1), np.clip(rings, 0, 1).astype(np.float32),
             base.normal_from_height(-np.clip(R / (8 * U), 0, 1).astype(np.float32), 1.5), wrap_x=False, wrap_y=False)

    # the parachute's cloth: wide orange and white stripes over the cloth's weave
    weave = tex["cloth"][0].mean(-1, keepdims=True)
    weave = np.clip(weave / max(float(weave.mean()), 1e-3), 0.85, 1.12)
    stripe = np.mod(XX / U + YY / U, 8.0) < 4.0
    chute = np.where(stripe[..., None], base.hexcolor("ff7a1f"), base.hexcolor("fbf7f0")) * weave
    page.put((5, 1), np.clip(chute, 0, 1).astype(np.float32), tex["cloth"][1])

    # the probe's lamps (unshaded: they glow): a warm light in a grey frame; the top: round glass
    metal = shade(tex["metal"][0], "8d949c", 0.9, 1.08)
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp = np.where((R < 2.5 * U)[..., None], base.hexcolor("ffffff"), base.hexcolor("fff1c9"))
    lamp = np.broadcast_to(lamp, (INNER, INNER, 3)).copy()
    lamp[frame] = metal[frame]
    page.put((6, 1), lamp.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    glass = np.where((R > 6.8 * U)[..., None], metal,
                     np.where((R < 2.2 * U)[..., None], base.hexcolor("ffffff"), base.hexcolor("fff1c9")))
    page.put((7, 1), np.clip(glass, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the explorers' station bricks; fake icy rock: the rock with a hairline door
    page.put((0, 2), bricks(tex["brick"][0], "e8c08a", 0.15), tex["brick"][1])
    fake = rock.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((1, 2), fake, tex["rock"][1])
    page.save()


def mercury() -> None:
    tex = {k: base.fetch(v) for k, v in {"dirt": "Ground103", "ripples": "Ground097", "rock": "Rock030", "snow": "Snow004",
                                         "white": "Snow003", "ice": "Ice002", "plastic": "Plastic013A",
                                         "metal": "Metal034", "cloth": "Fabric004", "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260923)
    page = Page("mercury")

    # Mercury's grey dust (its little craters: a dip and a lit rim); its side: the rock under a dust band
    height = base.smooth_noise(3.0) * 0.3
    for _ in range(6):
        cx, cy, cr = rng.random() * INNER, rng.random() * INNER, 10 + rng.random() * 20
        d = np.hypot(XX - cx, YY - cy) / cr
        height -= np.where(d < 1, 0.8 * (1 - d * d), 0) - np.where((d >= 1) & (d < 1.3), 0.25 * (1.3 - d) / 0.3, 0)
    dust = shade(tex["dirt"][0], "8e8a85", 0.85, 1.12)
    dust = np.clip(dust * (0.92 + 0.2 * height[..., None]), 0, 1)
    dust_n = base.normal_from_height(height.astype(np.float32), 4.0)
    page.put((0, 0), dust, dust_n)
    rock = tint(tex["rock"][0], "76726d", 0.2)
    page.put((2, 0), rock, tex["rock"][1])

    def banded(top: np.ndarray, top_n: np.ndarray) -> tuple:
        band = YY < 3.4 * U + 0.9 * U * np.sin(XX / INNER * 2 * np.pi * 3 + 0.8)
        return np.where(band[..., None], top, rock), np.where(band[..., None], top_n, tex["rock"][1])

    side, side_n = banded(dust, dust_n)
    page.put((1, 0), side, side_n, wrap_y=False)

    # darker blue-grey dust; its side
    dark = shade(tex["ripples"][0], "575e6a", 0.85, 1.12)
    page.put((3, 0), dark, tex["ripples"][1])
    side, side_n = banded(dark, tex["ripples"][1])
    page.put((4, 0), side, side_n, wrap_y=False)

    # a young crater's bright rays: pale dust in long streaks; its side
    ray = shade(tex["snow"][0], "dcd9d3", 0.9, 1.08)
    streak = np.mod((XX * 2 + YY) / U, 7.0)
    ray = np.clip(ray * (1.0 + 0.06 * (streak < 1.0)[..., None] - 0.05 * ((streak > 4) & (streak < 5))[..., None]), 0, 1)
    page.put((5, 0), ray, tex["snow"][1])
    side, side_n = banded(ray, tex["snow"][1])
    page.put((6, 0), side, side_n, wrap_y=False)

    # the shadowed craters' ice: pale blue-white with sparkles; its side: layers of ice
    ice = tint(tex["white"][0], "e3f2fa", 0.2)
    top = ice.copy()
    for _ in range(18):
        top[disc(rng.random() * INNER, rng.random() * INNER, 1.4)] = base.hexcolor("ffffff")
    page.put((7, 0), np.clip(top, 0, 1), tex["white"][1])
    layers = np.mod(np.floor(YY / U + 1.2 * np.sin(XX / U * 0.5)), 5)
    page.put((0, 1), np.clip(ice * (1.0 - 0.1 * (layers == 0)[..., None] + 0.05 * (layers == 2)[..., None]), 0, 1),
             tex["white"][1], wrap_y=False)

    # ice crystals (unshaded: they glow): pale-blue facets; the tip: a gem with a star of light
    gem = shade(tex["ice"][0], "bfeaff", 0.95, 1.1)
    facet = np.mod(XX / U + np.floor(YY / U / 4), 4.0)
    crystal = gem * (1.0 + 0.12 * (facet < 0.9)[..., None] - 0.14 * (facet > 3.1)[..., None])
    page.put((1, 1), np.clip(crystal, 0, 1), base.flat_normal())
    ring = np.maximum(np.abs(XX - INNER / 2), np.abs(YY - INNER / 2)) / U
    tip = gem.copy()
    tip[np.mod(np.floor(ring), 3) == 0] = base.hexcolor("eefaff")
    tip[((np.abs(XX - INNER / 2) < 0.5 * U) | (np.abs(YY - INNER / 2) < 0.5 * U)) & (R < 3 * U)] = base.hexcolor("ffffff")
    tip[ring >= 7] = base.hexcolor("86cdef")
    page.put((2, 1), np.clip(tip, 0, 1), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the sunshade: white ceramic cloth quilted in squares (the cloth's weave, puffed squares)
    weave = tex["cloth"][0].mean(-1, keepdims=True)
    weave = np.clip(weave / max(float(weave.mean()), 1e-3), 0.9, 1.08)
    fx = np.mod(XX / U, 4.0)
    fy = np.mod(YY / U, 4.0)
    puff = np.sin(fx / 4.0 * np.pi) * np.sin(fy / 4.0 * np.pi)
    cloth = base.hexcolor("f4f1ea") * weave * (0.93 + 0.07 * puff[..., None])
    cloth[(fx < 0.5) | (fy < 0.5)] = base.hexcolor("d9d3c6")
    page.put((3, 1), np.clip(cloth, 0, 1).astype(np.float32), base.normal_from_height(puff.astype(np.float32), 2.0))

    # the heat blanket: silvery crinkled foil
    crinkle = (np.sin(XX / U * 1.3 + YY / U * 0.7) * np.cos(YY / U * 1.1 - XX / U * 0.5)).astype(np.float32)
    foil = shade(tex["metal"][0], "cfd4da", 0.85, 1.15) * (1.0 + 0.1 * crinkle[..., None])
    page.put((4, 1), np.clip(foil, 0, 1), base.normal_from_height(crinkle * 0.5, 3.0))

    # the mirror panels: rows of mirror tiles with a few solar cells between them; the edge: a thin frame
    metal = shade(tex["metal"][0], "8d949c", 0.9, 1.08)
    mirror = shade(tex["plastic"][0], "c9dff0", 0.95, 1.1)
    cells = np.mod(np.floor(XX / U / 4), 3) == 1
    face = np.where(cells[..., None], base.hexcolor("2f4f86"), mirror)
    edge = (np.mod(XX / U, 4.0) > 3.0) | (np.mod(YY / U, 4.0) > 3.0)
    face = np.where(edge[..., None], metal, face)
    page.put((5, 1), np.clip(face, 0, 1).astype(np.float32), base.flat_normal())
    rim = np.where(((YY >= 6 * U) & (YY < 10 * U))[..., None], np.where(cells[..., None], base.hexcolor("2f4f86"), mirror),
                   metal)
    page.put((6, 1), np.clip(rim, 0, 1).astype(np.float32), base.flat_normal(), wrap_y=False)

    # the explorer lamps (unshaded: they glow): a warm light in a grey frame; the top: round glass
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    lamp = np.where((R < 2.5 * U)[..., None], base.hexcolor("ffffff"), base.hexcolor("fff4d6"))
    lamp = np.broadcast_to(lamp, (INNER, INNER, 3)).copy()
    lamp[frame] = metal[frame]
    page.put((7, 1), lamp.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    glass = np.where((R > 6.8 * U)[..., None], metal,
                     np.where((R < 2.2 * U)[..., None], base.hexcolor("ffffff"), base.hexcolor("fff4d6")))
    page.put((0, 2), np.clip(glass, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the thermometer: a white board, a glass tube with the red line up it, marks on both sides; its silver cap
    board = shade(tex["plastic"][0], "f2f0ea", 0.95, 1.04)
    cap = shade(tex["metal"][0], "b8bec6", 0.9, 1.1)
    col = np.floor(XX / U)
    row = np.floor(YY / U)
    tube = np.where(((col >= 2) & (col <= 13))[..., None], board, cap)
    tube[(col >= 6) & (col <= 9)] = base.hexcolor("dfe9ee")
    tube[(col == 7) | (col == 8)] = base.hexcolor("e8352b")
    marks = (((col == 4) | (col == 11)) & (np.mod(row, 3) == 1)) | (((col == 3) | (col == 12)) & (np.mod(row, 6) == 1))
    tube[marks] = base.hexcolor("2b2b2f")
    th = np.where((col >= 6) & (col <= 9), 0.5, 0.0).astype(np.float32)
    page.put((1, 2), np.clip(tube, 0, 1).astype(np.float32), base.normal_from_height(th, 2.0), wrap_y=False)
    top = np.where((R < 1.6 * U)[..., None], base.hexcolor("e8352b"),
                   np.where((R < 3.0 * U)[..., None], base.hexcolor("dfe9ee"), cap))
    page.put((2, 2), np.clip(top, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the thermometer's bulb (unshaded: it glows): a round red glow with a highlight; its top: red glass in silver
    bulb = np.where((np.hypot(XX - 7.5 * U, YY - 8.5 * U) < 6.5 * U)[..., None], base.hexcolor("ff4b3a"),
                    base.hexcolor("d8321f"))
    bulb = np.broadcast_to(bulb, (INNER, INNER, 3)).copy()
    bulb[np.hypot(XX - 5.0 * U, YY - 5.5 * U) < 1.8 * U] = base.hexcolor("ffb3a8")
    page.put((3, 2), bulb.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    bt = np.where((R > 6.8 * U)[..., None], cap,
                  np.where((R < 2.0 * U)[..., None], base.hexcolor("ffb3a8"), base.hexcolor("ff4b3a")))
    page.put((4, 2), np.clip(bt, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the explorers' bricks; fake Mercury rock: the rock with a hairline door
    page.put((5, 2), bricks(tex["brick"][0], "d6ccbd", 0.15), tex["brick"][1])
    fake = rock.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((6, 2), fake, tex["rock"][1])
    page.save()


def venus() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow004", "deep": "Snow005", "plastic": "Plastic013A",
                                         "metal": "Metal034", "grass": "Grass001", "wood": "WoodFloor043",
                                         "plaster": "Plaster001", "cloth": "Fabric004", "ice": "Ice002"}.items()}
    rng = np.random.default_rng(20260924)
    page = Page("venus")
    col = np.floor(XX / U)
    row = np.floor(YY / U)

    # the yellow cloud tops: soft puffs (their own height, lit from above); their side: puffs along the top, shaded below
    puffs = np.zeros((INNER, INNER), np.float32)
    for _ in range(14):
        cx, cy, cr = rng.random() * INNER, rng.random() * INNER, 24 + rng.random() * 40
        d = np.hypot(XX - cx, YY - cy) / cr
        puffs = np.maximum(puffs, np.sqrt(np.clip(1.0 - d * d, 0, 1)))
    puffs = (puffs * 0.7 + base.smooth_noise(4.0) * 0.3).astype(np.float32)
    cloud = shade(tex["snow"][0], "f4df8e", 0.9, 1.08) * (0.88 + 0.2 * puffs[..., None])
    page.put((0, 0), np.clip(cloud, 0, 1), base.normal_from_height(puffs, 3.0))
    edge = YY < (2.5 + 2.0 * np.abs(np.sin(XX / U * 0.45 + 0.7))) * U
    fade = np.clip((YY / U - 8.0) / 8.0, 0, 1)[..., None]
    side = np.where(edge[..., None], base.hexcolor("fdf2c4"), cloud * (1.0 - 0.12 * fade))
    page.put((1, 0), np.clip(side, 0, 1), tex["snow"][1], wrap_y=False)

    # the deeper clouds: ochre swirls
    deep = shade(tex["deep"][0], "d6a954", 0.85, 1.12)
    swirl = (np.sin(XX / U * 0.4 + YY / U * 0.7) + np.cos(YY / U * 0.35 - XX / U * 0.8)).astype(np.float32)
    deep = np.clip(deep * (1.0 + 0.06 * swirl[..., None]), 0, 1)
    page.put((2, 0), deep, tex["deep"][1])

    # the deck: cream panels with seams and teal rivets; its edge: a cream lip, the teal trim, the hull below
    panel = shade(tex["plastic"][0], "f4efe3", 0.95, 1.04)
    seam = (np.mod(XX / U, 8.0) < 0.5) | (np.mod(YY / U, 8.0) < 0.5)
    deck = np.where(seam[..., None], base.hexcolor("d9d1c0"), panel)
    for cx, cy in ((2.5, 2.5), (10.5, 2.5), (2.5, 10.5), (10.5, 10.5)):
        deck[disc(cx * U, cy * U, 0.6 * U)] = base.hexcolor("139e9b")
    dh = np.where(seam, -0.5, 0.0).astype(np.float32)
    page.put((3, 0), np.clip(deck, 0, 1).astype(np.float32), base.normal_from_height(dh, 2.0))
    hull = shade(tex["metal"][0], "e3e8ef", 0.92, 1.06)
    rib = np.mod(XX / U, 4.0) < 0.6
    hull = np.where(rib[..., None], base.hexcolor("c1c9d4"), hull)
    hh = np.where(rib, -0.4, 0.0).astype(np.float32)
    trim = np.where((YY < 2 * U)[..., None], base.hexcolor("fbf8f1"),
                    np.where((YY < 3 * U)[..., None], base.hexcolor("139e9b"),
                             np.where((YY < 4 * U)[..., None], base.hexcolor("0c7876"), hull)))
    page.put((4, 0), np.clip(trim, 0, 1).astype(np.float32), base.normal_from_height(hh, 2.0), wrap_y=False)
    page.put((5, 0), np.clip(hull, 0, 1).astype(np.float32), base.normal_from_height(hh, 2.0))

    # the garden turf: short grass with a few tiny flowers; its side: a grass fringe over the planter's cream wall
    grass = tint(tex["grass"][0], "69bd48", 0.35)
    turf = grass.copy()
    for _ in range(10):
        turf[disc(rng.random() * INNER, rng.random() * INNER, 0.9 * U)] = base.hexcolor(
            "fff6c9" if rng.random() < 0.5 else "ff9ecb")
    page.put((6, 0), np.clip(turf, 0, 1), tex["grass"][1])
    fringe = YY < (3.0 + (np.mod(col, 3) == 0)) * U
    wall = np.where(((row == 15) | (np.abs(YY - (3.5 + (np.mod(col, 3) == 0)) * U) < 0.5 * U))[..., None],
                    base.hexcolor("d9d1c0"), panel)
    page.put((7, 0), np.clip(np.where(fringe[..., None], grass, wall), 0, 1).astype(np.float32),
             np.where(fringe[..., None], tex["grass"][1], base.flat_normal()), wrap_y=False)

    # the bridges' honey planks; their edge: the boards' ends over a white frame beam
    wood = shade(tex["wood"][0], "dca55b", 0.8, 1.15)
    gap = np.mod(YY / U, 4.0) > 3.3
    planks = np.where(gap[..., None], base.hexcolor("b07a3a"), wood)
    ph = np.where(gap, -0.6, 0.0).astype(np.float32)
    page.put((0, 1), np.clip(planks, 0, 1).astype(np.float32), base.normal_from_height(ph, 2.5))
    frame = shade(tex["metal"][0], "d8dee6", 0.9, 1.08)
    ends = np.where(((row == 6) | ((row < 6) & (np.mod(col, 5) == 0)))[..., None], base.hexcolor("b07a3a"), wood)
    beam = np.where((row == 15)[..., None], base.hexcolor("a9b2be"), frame)
    page.put((1, 1), np.clip(np.where((row <= 6)[..., None], ends, beam), 0, 1).astype(np.float32), base.flat_normal(),
             wrap_y=False)

    # the cloud lamps (unshaded: they glow): round warm glass in a white frame; the side: a warm pane
    lamp_top = np.where((R > 6.8 * U)[..., None], frame,
                        np.where((R < 2.4 * U)[..., None], base.hexcolor("fffaf0"), base.hexcolor("ffe6a0")))
    page.put((2, 1), np.clip(lamp_top, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    pane = np.where((R < 3.0 * U)[..., None], base.hexcolor("fffaf0"), base.hexcolor("ffe6a0"))
    pane = np.broadcast_to(pane, (INNER, INNER, 3)).copy()
    border = (XX < 2 * U) | (YY < 2 * U) | (XX >= INNER - 2 * U) | (YY >= INNER - 2 * U)
    pane[border] = frame[border]
    page.put((3, 1), pane.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the white frame: a bevelled beam with rivets
    bevel = frame.copy()
    bevel[(XX < 2 * U) | (YY < 2 * U)] = np.clip(bevel[(XX < 2 * U) | (YY < 2 * U)] * 1.08, 0, 1)
    bevel[(XX >= 14 * U) | (YY >= 14 * U)] = base.hexcolor("a9b2be")
    for cx, cy in ((4.5, 4.5), (11.5, 4.5), (4.5, 11.5), (11.5, 11.5)):
        bevel[disc(cx * U, cy * U, 0.7 * U)] = base.hexcolor("a9b2be")
    page.put((4, 1), np.clip(bevel, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the homes' peach panels: siding boards
    plaster = shade(tex["plaster"][0], "f6c9a9", 0.9, 1.08)
    board = np.mod(YY / U, 5.0)
    siding = np.where((board > 4.2)[..., None], base.hexcolor("e5b08c"), plaster)
    sh = np.where(board > 4.2, -0.5, 0.0).astype(np.float32)
    page.put((5, 1), np.clip(siding, 0, 1).astype(np.float32), base.normal_from_height(sh, 2.0))

    # the blimp's skin: white cloth in long gores; its stripe: the brand's teal with a thin orange line
    weave = tex["cloth"][0].mean(-1, keepdims=True)
    weave = np.clip(weave / max(float(weave.mean()), 1e-3), 0.92, 1.06)
    gore = np.mod(YY / U, 8.0) > 7.2
    skin = np.where(gore[..., None], base.hexcolor("d3d9e0"), base.hexcolor("f1f3f6") * weave)
    page.put((6, 1), np.clip(skin, 0, 1).astype(np.float32), tex["cloth"][1])
    stripe = base.hexcolor("139e9b") * weave
    stripe = np.where(((row == 7) | (row == 8))[..., None], base.hexcolor("f28c28") * weave, stripe)
    stripe = np.where(((row == 0) | (row == 15))[..., None], base.hexcolor("0c7876"), stripe)
    page.put((7, 1), np.clip(stripe, 0, 1).astype(np.float32), tex["cloth"][1])

    # the gondola's side: a white wall with a round blue window
    wall = shade(tex["plastic"][0], "f6f7f9", 0.95, 1.04)
    dw = np.hypot(XX - 7.5 * U, YY - 7.0 * U)
    gondola = np.where((dw > 5.6 * U)[..., None], wall,
                       np.where((dw > 4.4 * U)[..., None], base.hexcolor("aeb6c2"), base.hexcolor("7cc6f0")))
    gondola[(np.hypot(XX - 6.0 * U, YY - 5.5 * U) < 1.6 * U)] = base.hexcolor("c9ecff")
    gondola[row >= 14] = base.hexcolor("a9b2be")
    gh = np.where(dw < 4.4 * U, -0.4, np.where(dw < 5.6 * U, 0.3, 0.0)).astype(np.float32)
    page.put((0, 2), np.clip(gondola, 0, 1).astype(np.float32), base.normal_from_height(gh, 2.0), wrap_x=False,
             wrap_y=False)

    # solar film: dark blue cells in a light grid; its edge: a thin frame with a row of cells
    line = (np.mod(XX / U, 4.0) < 0.6) | (np.mod(YY / U, 4.0) < 0.6)
    cells = np.where(line[..., None], base.hexcolor("8d949c"), base.hexcolor("2f4f86"))
    cells[(np.mod(XX / U, 4.0) > 0.8) & (np.mod(XX / U, 4.0) < 1.6) & (np.mod(YY / U, 4.0) > 0.8)
          & (np.mod(YY / U, 4.0) < 1.6)] = base.hexcolor("4a6fae")
    page.put((1, 2), np.clip(cells, 0, 1).astype(np.float32), base.flat_normal())
    band = (row >= 4) & (row <= 11) & (np.mod(XX / U, 4.0) >= 0.6)
    page.put((2, 2), np.where(band[..., None], base.hexcolor("2f4f86"), base.hexcolor("8d949c")).astype(np.float32),
             base.flat_normal(), wrap_y=False)

    # cloud crystals (unshaded: they glow): pale golden facets
    gem = shade(tex["ice"][0], "ffe7a0", 0.95, 1.08)
    facet = np.mod(XX / U + np.floor(YY / U / 3), 4.0)
    crystal = gem * (1.0 + 0.1 * (facet < 0.9)[..., None] - 0.12 * (facet > 3.1)[..., None])
    page.put((3, 2), np.clip(crystal, 0, 1), base.flat_normal())

    # the telescopes' brass: a round tube lit above and shaded below, two dark rings
    brass = shade(tex["metal"][0], "cc9a44", 0.85, 1.15)
    light = np.clip(1.15 - 0.3 * (YY / INNER), 0.8, 1.15)[..., None]
    tube = brass * light
    rings = (col == 2) | (col == 3) | (col == 12) | (col == 13)
    tube[rings] = base.hexcolor("94692a")
    th = (np.cos((YY / INNER - 0.5) * np.pi) * 0.5 - np.where(rings, 0.2, 0.0)).astype(np.float32)
    page.put((4, 2), np.clip(tube, 0, 1).astype(np.float32), base.normal_from_height(th, 2.0), wrap_x=False,
             wrap_y=False)

    # a fake float hull: the hull with a hairline door
    fake = hull.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((5, 2), np.clip(fake, 0, 1).astype(np.float32), base.normal_from_height(hh, 2.0))
    page.save()


def rings() -> None:
    tex = {k: base.fetch(v) for k, v in {"ice": "Ice002", "clear": "Ice004", "snow": "Snow006", "dust": "Ground103",
                                         "rock": "Rock030", "pale": "Snow003", "plastic": "Plastic013A",
                                         "metal": "Metal034"}.items()}
    rng = np.random.default_rng(20260925)
    page = Page("rings")
    col = np.floor(XX / U)
    row = np.floor(YY / U)

    # frost on a chunk's top: bright white grains with sparkles; the clean water ice: white with a cool tint and cracks
    frost = shade(tex["snow"][0], "f5f9ff", 0.9, 1.06)
    for _ in range(40):
        frost[disc(rng.random() * INNER, rng.random() * INNER, 0.35 * U)] = base.hexcolor("ffffff")
    page.put((0, 0), np.clip(frost, 0, 1), tex["snow"][1])
    ice = shade(tex["ice"][0], "e6eff8", 0.88, 1.08)
    crack = base.smooth_noise(6.0)
    ice = np.where((np.abs(crack - 0.5) < 0.012)[..., None], base.hexcolor("b5cde6"), ice)
    page.put((1, 0), np.clip(ice, 0, 1).astype(np.float32), tex["ice"][1])
    rim = YY < (2.0 + 2.0 * np.abs(np.sin(XX / U * 0.8 + 0.3))) * U
    page.put((2, 0), np.clip(np.where(rim[..., None], frost, ice), 0, 1).astype(np.float32), tex["ice"][1], wrap_y=False)

    # the C ring's dusty ice: grey-tan grains; its side in soft layers
    dusty = shade(tex["dust"][0], "a9a39a", 0.85, 1.12)
    page.put((3, 0), np.clip(dusty, 0, 1), tex["dust"][1])
    layer = np.mod(YY / U + np.sin(XX / U * 0.5) * 1.5, 5.0) < 0.9
    page.put((4, 0), np.clip(np.where(layer[..., None], dusty * 0.86, dusty), 0, 1).astype(np.float32), tex["dust"][1])

    # rock bits
    page.put((5, 0), np.clip(shade(tex["rock"][0], "6e665f", 0.8, 1.2), 0, 1), tex["rock"][1])

    # Pan's pale ice and its faint bands; the ring dust on its ridge
    moonlet = shade(tex["pale"][0], "ebe3d2", 0.9, 1.08)
    page.put((6, 0), np.clip(moonlet, 0, 1), tex["pale"][1])
    bands = np.mod(YY / U + XX / U / 5.0, 6.0) < 0.8
    page.put((7, 0), np.clip(np.where(bands[..., None], moonlet * 0.92, moonlet), 0, 1).astype(np.float32),
             tex["pale"][1])
    ridge = shade(tex["dust"][0], "d9ccb0", 0.9, 1.1)
    page.put((0, 1), np.clip(ridge, 0, 1), tex["dust"][1])
    dust_line = YY < (5.0 + 3.0 * np.abs(np.sin(XX / U * 0.6))) * U
    page.put((1, 1), np.clip(np.where(dust_line[..., None], ridge, moonlet), 0, 1).astype(np.float32), tex["dust"][1],
             wrap_y=False)

    # ring crystals (unshaded: they glow): pale blue facets
    gem = shade(tex["clear"][0], "bfe8ff", 0.95, 1.08)
    facet = np.mod(XX / U + np.floor(YY / U / 3), 4.0)
    crystal = gem * (1.0 + 0.1 * (facet < 0.9)[..., None] - 0.12 * (facet > 3.1)[..., None])
    page.put((2, 1), np.clip(crystal, 0, 1), base.flat_normal())

    # the station's white panels: seams, rivets, a teal trim along the bottom
    panel = shade(tex["plastic"][0], "eef2f5", 0.95, 1.04)
    seam = (np.mod(XX / U, 8.0) < 0.5) | (row == 0)
    plate = np.where(seam[..., None], base.hexcolor("cfd6dd"), panel)
    plate = np.where((row >= 14)[..., None], base.hexcolor("139e9b"), plate)
    for cx, cy in ((2.5, 2.5), (13.5, 2.5), (2.5, 11.5), (13.5, 11.5)):
        plate[disc(cx * U, cy * U, 0.5 * U)] = base.hexcolor("cfd6dd")
    ph = np.where(seam, -0.5, 0.0).astype(np.float32)
    page.put((3, 1), np.clip(plate, 0, 1).astype(np.float32), base.normal_from_height(ph, 2.0), wrap_y=False)
    dw = np.hypot(XX - 7.5 * U, YY - 7.0 * U)
    window = np.where((dw > 5.6 * U)[..., None], panel,
                      np.where((dw > 4.4 * U)[..., None], base.hexcolor("cfd6dd"), base.hexcolor("5aa7e0")))
    window[np.hypot(XX - 6.0 * U, YY - 5.5 * U) < 1.6 * U] = base.hexcolor("bfe3ff")
    window[row >= 14] = base.hexcolor("139e9b")
    wh = np.where(dw < 4.4 * U, -0.4, np.where(dw < 5.6 * U, 0.3, 0.0)).astype(np.float32)
    page.put((4, 1), np.clip(window, 0, 1).astype(np.float32), base.normal_from_height(wh, 2.0), wrap_x=False,
             wrap_y=False)

    # the station's lamps (unshaded: they glow): a warm pane in a white frame; a round warm light on top
    lamp = np.where((R < 3.5 * U)[..., None], base.hexcolor("fffbf0"), base.hexcolor("ffe9b0"))
    lamp = np.broadcast_to(lamp, (INNER, INNER, 3)).copy()
    border = (XX < U) | (YY < U) | (XX >= INNER - U) | (YY >= INNER - U)
    lamp[border] = panel[border]
    page.put((5, 1), lamp.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    lamp_top = np.where((R > 7.0 * U)[..., None], panel,
                        np.where((R < 3.0 * U)[..., None], base.hexcolor("fffbf0"), base.hexcolor("ffe9b0")))
    page.put((6, 1), np.clip(lamp_top, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the radio dish: white rings round a grey feed; its edge: a white rim over a shaded back
    metal = shade(tex["metal"][0], "f4f6f8", 0.92, 1.05)
    ringed = np.where((np.mod(R / U, 3.0) > 2.0)[..., None], base.hexcolor("d5dbe2"), metal)
    ringed[R < 1.6 * U] = base.hexcolor("6b747f")
    dh = (np.cos(np.clip(R / (7.5 * U), 0, 1) * np.pi) * -0.5).astype(np.float32)
    page.put((7, 1), np.clip(ringed, 0, 1).astype(np.float32), base.normal_from_height(dh, 2.0), wrap_x=False,
             wrap_y=False)
    page.put((0, 2), np.clip(np.where((YY < 6 * U)[..., None], metal, metal * 0.86), 0, 1).astype(np.float32),
             base.flat_normal(), wrap_y=False)

    # the power pack (glows): orange fins round a warm core; its top a glowing core in a dark ring
    fin = np.mod(XX / U, 4.0)
    power = np.where((fin < 0.8)[..., None], base.hexcolor("d9642a"),
                     np.where(((fin > 1.6) & (fin < 2.6))[..., None], base.hexcolor("ffd27a"), base.hexcolor("ff9c4a")))
    power = np.broadcast_to(power, (INNER, INNER, 3)).copy()
    power[(row == 0) | (row == 15)] = base.hexcolor("4a525c")
    page.put((1, 2), power.astype(np.float32), base.flat_normal(), wrap_y=False)
    core = np.where((R > 6.5 * U)[..., None], base.hexcolor("4a525c"),
                    np.where((R < 3.0 * U)[..., None], base.hexcolor("ffd27a"), base.hexcolor("ff9c4a")))
    page.put((2, 2), np.clip(core, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # a dark metal truss: a frame with a cross brace
    dark = shade(tex["metal"][0], "4a525c", 0.85, 1.15)
    frame = (XX < 2 * U) | (YY < 2 * U) | (XX >= 14 * U) | (YY >= 14 * U) | (np.abs(XX - YY) < 0.8 * U) \
        | (np.abs(XX - (INNER - YY)) < 0.8 * U)
    truss = np.where(frame[..., None], dark * 1.35, dark * 0.8)
    th = np.where(frame, 0.4, -0.3).astype(np.float32)
    page.put((3, 2), np.clip(truss, 0, 1).astype(np.float32), base.normal_from_height(th, 2.0), wrap_x=False,
             wrap_y=False)

    # the teal beacon (glows): a teal light in a white frame; its top a teal glow
    beacon = np.where((R < 2.5 * U)[..., None], base.hexcolor("c8fffb"), base.hexcolor("3fd6cf"))
    beacon = np.broadcast_to(beacon, (INNER, INNER, 3)).copy()
    edge = (XX < 2 * U) | (YY < 2 * U) | (XX >= 14 * U) | (YY >= 14 * U)
    beacon[edge] = panel[edge]
    page.put((4, 2), beacon.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    glow = np.where((R < 3.0 * U)[..., None], base.hexcolor("c8fffb"), base.hexcolor("3fd6cf"))
    page.put((5, 2), np.broadcast_to(glow, (INNER, INNER, 3)).astype(np.float32), base.flat_normal())

    # Saturn's clouds: pale gold zones and tan belts, a little wavy
    w = np.mod(YY / U + np.sin(XX / U * 0.7) * 1.2, 8.0)
    band = np.where((w >= 5.0)[..., None], base.hexcolor("c9a46a"),
                    np.where((w < 1.0)[..., None], base.hexcolor("f6e9c4"), base.hexcolor("ead7a4")))
    swirl = (0.94 + 0.08 * base.smooth_noise(5.0))[..., None]
    page.put((6, 2), np.clip(band * swirl, 0, 1).astype(np.float32), base.flat_normal())

    # a fake ring ice: the ice with a hairline door
    fake = ice.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.8
    page.put((7, 2), np.clip(fake, 0, 1).astype(np.float32), tex["ice"][1])
    page.save()


def pluto() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow006", "pale": "Snow003", "clear": "Ice004", "dirt": "Ground103",
                                         "ripples": "Ground097", "rock": "Rock030", "cloth": "Fabric004",
                                         "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260926)
    page = Page("pluto")

    # the heart's nitrogen ice: creamy and smooth with faint swirls; its side in faint layers
    n2 = shade(tex["pale"][0], "f3ece0", 0.92, 1.06)
    swirl = base.smooth_noise(5.0)
    n2 = np.clip(n2 * (0.97 + 0.06 * swirl)[..., None], 0, 1)
    page.put((0, 0), n2.astype(np.float32), tex["pale"][1])
    layers = np.mod(YY / U + np.sin(XX / U * 0.4) * 1.5, 6.0) < 0.9
    page.put((1, 0), np.clip(np.where(layers[..., None], n2 * 0.93, n2), 0, 1).astype(np.float32), tex["pale"][1])

    # a cell's edge: grey-tan ice with dark streaks along it
    edge = shade(tex["pale"][0], "b8a792", 0.88, 1.1)
    streak = (np.sin(XX / U * 0.35 + YY / U * 1.3) + 0.4 * np.sin(XX / U * 1.7)) > 0.9
    edge = np.where(streak[..., None], edge * 0.82, edge)
    page.put((2, 0), np.clip(edge, 0, 1).astype(np.float32), tex["pale"][1])

    # water ice as hard as rock: pale blue-grey with facets and cracks
    water = tint(tex["rock"][0], "aab9c9", 0.18)
    crack = base.smooth_noise(6.0)
    water = np.where((np.abs(crack - 0.5) < 0.012)[..., None], base.hexcolor("7d8ca0"), water)
    page.put((3, 0), np.clip(water, 0, 1).astype(np.float32), tex["rock"][1])

    # the uplands' peach-tan frost; its side: a crust of frost over water ice
    frost = shade(tex["dirt"][0], "d6a888", 0.86, 1.1)
    for _ in range(30):
        frost[disc(rng.random() * INNER, rng.random() * INNER, 0.4 * U)] = base.hexcolor("e6c3a4")
    page.put((4, 0), np.clip(frost, 0, 1).astype(np.float32), tex["dirt"][1])
    crust = YY < (3.0 + 2.0 * np.abs(np.sin(XX / U * 0.7 + 0.4))) * U
    page.put((5, 0), np.clip(np.where(crust[..., None], frost, water), 0, 1).astype(np.float32), tex["rock"][1],
             wrap_y=False)

    # tholins: dark red-brown grains; their side in soft layers
    tholin = tint(tex["ripples"][0], "7a3f2c", 0.12)
    page.put((6, 0), np.clip(tholin, 0, 1).astype(np.float32), tex["ripples"][1])
    soft = np.mod(YY / U + np.sin(XX / U * 0.5) * 1.5, 5.0) < 0.9
    page.put((7, 0), np.clip(np.where(soft[..., None], tholin * 0.84, tholin), 0, 1).astype(np.float32),
             tex["ripples"][1])

    # water ice stained red
    red = tint(tex["rock"][0], "b9846f", 0.18)
    page.put((0, 1), np.clip(red, 0, 1).astype(np.float32), tex["rock"][1])

    # methane snow: bright white with sparkles; its side a white cap over water ice
    snow = shade(tex["snow"][0], "f8f9fb", 0.92, 1.05)
    for _ in range(40):
        snow[disc(rng.random() * INNER, rng.random() * INNER, 0.35 * U)] = base.hexcolor("ffffff")
    page.put((1, 1), np.clip(snow, 0, 1).astype(np.float32), tex["snow"][1])
    cap = YY < (4.0 + 3.0 * np.abs(np.sin(XX / U * 0.9 + 0.2))) * U
    page.put((2, 1), np.clip(np.where(cap[..., None], snow, water), 0, 1).astype(np.float32), tex["rock"][1],
             wrap_y=False)

    # frost crystals (unshaded: they glow): pale blue facets
    gem = shade(tex["clear"][0], "c8ecff", 0.95, 1.08)
    facet = np.mod(XX / U + np.floor(YY / U / 3), 4.0)
    crystal = gem * (1.0 + 0.1 * (facet < 0.9)[..., None] - 0.12 * (facet > 3.1)[..., None])
    page.put((3, 1), np.clip(crystal, 0, 1).astype(np.float32), base.flat_normal())

    # the drag balloon's silvery film: folds over the cloth's weave, a gold seam
    weave = tex["cloth"][0].mean(-1, keepdims=True)
    weave = np.clip(weave / max(float(weave.mean()), 1e-3), 0.9, 1.08)
    fold = np.sin(XX / U * 0.9 + YY / U * 0.35)
    film = np.where((fold > 0.85)[..., None], base.hexcolor("fbfcfe"),
                    np.where((fold < -0.8)[..., None], base.hexcolor("b9c0cc"), base.hexcolor("dde2ea"))) * weave
    film = np.broadcast_to(film, (INNER, INNER, 3)).copy()
    film[np.abs(YY - 7.5 * U) < 0.5 * U] = base.hexcolor("e7c35a")
    fh = (fold * 0.5).astype(np.float32)
    page.put((4, 1), np.clip(film, 0, 1).astype(np.float32), base.normal_from_height(fh, 2.0))

    # a globe of Charon: a grey ball with craters and its red cap, on a dark stand; its top: the cap in a grey ring
    grey = shade(tex["rock"][0], "9b9894", 0.85, 1.12)
    ball = R < 7.2 * U
    globe = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    globe[ball] = grey[ball]
    globe[ball & (YY < 4 * U)] = base.hexcolor("8e4a33")
    for cx, cy, cr in ((5.0, 9.0, 1.6), (10.0, 11.0, 1.2), (9.0, 6.0, 1.1)):
        globe[disc(cx * U, cy * U, cr * U) & (YY >= 4 * U)] = base.hexcolor("85827e")
    gh = np.sqrt(np.clip(1.0 - (R / (7.2 * U)) ** 2, 0, 1)).astype(np.float32)
    page.put((5, 1), np.clip(globe, 0, 1).astype(np.float32), base.normal_from_height(gh, 3.0), wrap_x=False,
             wrap_y=False)
    top = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    top[ball] = grey[ball]
    top[R < 4.5 * U] = base.hexcolor("8e4a33")
    page.put((6, 1), np.clip(top, 0, 1).astype(np.float32), base.normal_from_height(gh, 3.0), wrap_x=False,
             wrap_y=False)

    # the heart beacon (glows): a pink heart on a pale pink pane; its top a pink glow
    u = (XX / U - 7.5) / 6.0
    v = (8.5 - YY / U) / 6.0
    inside = (u * u + v * v - 1.0) ** 3 - u * u * v ** 3 <= 0.0
    heart = np.where(inside[..., None], base.hexcolor("ff7fbf"), base.hexcolor("ffb3d9"))
    heart = np.broadcast_to(heart, (INNER, INNER, 3)).copy()
    heart[disc(5.5 * U, 5.5 * U, 1.5 * U) & inside] = base.hexcolor("ffe0ef")
    page.put((7, 1), heart.astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)
    glow = np.where((R < 3 * U)[..., None], base.hexcolor("ffe0ef"),
                    np.where((R < 6 * U)[..., None], base.hexcolor("ff7fbf"), base.hexcolor("ffb3d9")))
    page.put((0, 2), np.broadcast_to(glow, (INNER, INNER, 3)).astype(np.float32), base.flat_normal(), wrap_x=False,
             wrap_y=False)

    # the explorers' frost bricks; fake water ice: the ice with a hairline door
    page.put((1, 2), bricks(tex["brick"][0], "e9e4dc", 0.15), tex["brick"][1])
    fake = water.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.72
    page.put((2, 2), np.clip(fake, 0, 1).astype(np.float32), tex["rock"][1])
    page.save()


def triton() -> None:
    tex = {k: base.fetch(v) for k, v in {"snow": "Snow006", "pale": "Snow003", "clear": "Ice004", "dirt": "Ground103",
                                         "ripples": "Ground097", "rock": "Rock030", "plastic": "Plastic013A",
                                         "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260927)
    page = Page("triton")

    # the band's fresh nitrogen frost: bright and a little bluish, with sparkles; its side a crust over nitrogen ice
    frost = shade(tex["snow"][0], "eef3fb", 0.92, 1.05)
    for _ in range(40):
        frost[disc(rng.random() * INNER, rng.random() * INNER, 0.35 * U)] = base.hexcolor("ffffff")
    page.put((0, 0), np.clip(frost, 0, 1).astype(np.float32), tex["snow"][1])
    n2 = shade(tex["pale"][0], "f3ece0", 0.92, 1.06)
    layers = np.mod(YY / U + np.sin(XX / U * 0.4) * 1.5, 6.0) < 0.9
    n2 = np.where(layers[..., None], n2 * 0.93, n2)
    crust = YY < (3.0 + 2.0 * np.abs(np.sin(XX / U * 0.8 + 0.3))) * U
    page.put((1, 0), np.clip(np.where(crust[..., None], frost, n2), 0, 1).astype(np.float32), tex["pale"][1],
             wrap_y=False)

    # the polar cap's pink ice with paler swirls; its side in faint layers; its mottled patches
    pink = shade(tex["pale"][0], "f0c9c6", 0.9, 1.07)
    swirl = base.smooth_noise(5.0)
    pink = np.clip(pink * (0.97 + 0.06 * swirl)[..., None], 0, 1)
    page.put((2, 0), pink.astype(np.float32), tex["pale"][1])
    soft = np.mod(YY / U + np.sin(XX / U * 0.45) * 1.4, 5.0) < 0.9
    pink_side = np.clip(np.where(soft[..., None], pink * 0.93, pink), 0, 1).astype(np.float32)
    page.put((3, 0), pink_side, tex["pale"][1])
    blots = base.smooth_noise(3.0) > 0.45
    mottled = np.where(blots[..., None], shade(tex["pale"][0], "cf9f9b", 0.88, 1.08), pink * 0.95)
    page.put((4, 0), np.clip(mottled, 0, 1).astype(np.float32), tex["pale"][1])

    # the geysers' dark dust, streaked the way the wind blew it; its side a skin of dust over pink ice
    dust = tint(tex["ripples"][0], "6a5f63", 0.12)
    page.put((5, 0), np.clip(dust, 0, 1).astype(np.float32), tex["ripples"][1])
    skin = YY < (2.0 + 2.0 * np.abs(np.sin(XX / U * 0.9 + 0.5))) * U
    dust_side = np.where(skin[..., None], dust, pink_side)
    page.put((6, 0), np.clip(dust_side, 0, 1).astype(np.float32), tex["pale"][1], wrap_y=False)

    # a geyser's vent (glows): a dark throat in a ring of dust, a glint of rising frost; its side a throat down the ice
    vent = np.where((R < 5.0 * U)[..., None], base.hexcolor("2b2a33"), dust)
    vent = np.where((R < 1.6 * U)[..., None], base.hexcolor("cfd8ff"), vent)
    page.put((7, 0), np.clip(vent, 0, 1).astype(np.float32), base.normal_from_height((-np.clip(1.0 - R / (5 * U), 0, 1))
             .astype(np.float32), 2.0), wrap_x=False, wrap_y=False)
    throat = dust_side.copy()
    throat[(np.abs(XX - 7.5 * U) < 1.5 * U) & (YY > 2 * U)] = base.hexcolor("2b2a33")
    page.put((0, 1), np.clip(throat, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the cantaloupe terrain: greyish-green ice in dimples with pale rims; its side in soft layers; a pale double ridge
    melon = tint(tex["dirt"][0], "b3b79a", 0.15)
    mh = np.zeros((INNER, INNER), np.float32)
    for cx, cy, cr in ((4, 4, 3.2), (12, 3, 2.8), (8, 10, 3.5), (2, 12, 2.6), (14, 12, 2.6)):
        d = np.hypot(XX - cx * U, YY - cy * U) / (cr * U)
        mh -= np.clip(1.0 - d * d, 0, 1)
        melon = np.where(((d > 0.8) & (d < 1.15))[..., None], base.hexcolor("c9ccb0"), melon)
    melon = np.clip(melon * (1.0 + 0.12 * mh)[..., None], 0, 1)
    page.put((1, 1), melon.astype(np.float32), base.normal_from_height(mh, 2.5))
    rind = np.mod(YY / U + np.sin(XX / U * 0.5) * 1.2, 5.0) < 0.9
    page.put((2, 1), np.clip(np.where(rind[..., None], melon * 0.9, melon), 0, 1).astype(np.float32), tex["dirt"][1])
    ridge = shade(tex["dirt"][0], "d2d4bf", 0.9, 1.08)
    seam = (np.abs(XX - 4.5 * U) < 0.6 * U) | (np.abs(XX - 11.5 * U) < 0.6 * U)
    ridge = np.where(seam[..., None], ridge * 1.08, ridge)
    rh = (np.exp(-((XX - 4.5 * U) / U) ** 2) + np.exp(-((XX - 11.5 * U) / U) ** 2)).astype(np.float32)
    page.put((3, 1), np.clip(ridge, 0, 1).astype(np.float32), base.normal_from_height(rh, 2.0))

    # frozen ice lava: smooth pale blue-grey with faint flow lines; its side the layers that flowed and froze
    lava = shade(tex["pale"][0], "c5d0da", 0.93, 1.05)
    flow = np.sin(YY / U * 0.6 + np.sin(XX / U * 0.3) * 2.0) > 0.92
    lava = np.where(flow[..., None], base.hexcolor("dbe3ea"), lava)
    page.put((4, 1), np.clip(lava, 0, 1).astype(np.float32), tex["pale"][1])
    flows = np.mod(YY / U + np.sin(XX / U * 0.35) * 1.2, 4.0) < 0.9
    page.put((5, 1), np.clip(np.where(flows[..., None], lava * 0.88, lava), 0, 1).astype(np.float32), tex["rock"][1])

    # nitrogen crystals (unshaded: they glow): pale pink-white facets
    gem = shade(tex["clear"][0], "fbe7ef", 0.95, 1.06)
    facet = np.mod(np.floor(XX / U / 2) + YY / U, 5.0)
    crystal = gem * (1.0 + 0.05 * (facet < 0.9)[..., None] - 0.06 * (facet > 4.1)[..., None])
    page.put((6, 1), np.clip(crystal, 0, 1).astype(np.float32), base.flat_normal())

    # the Hopper Lander's white tank: a blue band and a gauge; its top a white dome with a blue valve
    tank = shade(tex["plastic"][0], "eef1f5", 0.92, 1.05)
    tank = np.where(((XX < 2 * U) | (XX > 14 * U))[..., None], tank * 0.9, tank)
    tank[(YY > 7 * U) & (YY < 9 * U)] = base.hexcolor("4a78c8")
    tank[(XX > 9 * U) & (XX < 12 * U) & (YY > 11 * U) & (YY < 14 * U)] = base.hexcolor("f5c542")
    tank[disc(10.5 * U, 12.5 * U, 0.6 * U)] = base.hexcolor("2f3440")
    page.put((7, 1), np.clip(tank, 0, 1).astype(np.float32), tex["plastic"][1], wrap_x=False, wrap_y=False)
    dome = shade(tex["plastic"][0], "eef1f5", 0.92, 1.05)
    dome = np.where((R > 6 * U)[..., None], dome * 0.9, dome)
    dome[R < 1.8 * U] = base.hexcolor("4a78c8")
    dh = np.sqrt(np.clip(1.0 - (R / (7.5 * U)) ** 2, 0, 1)).astype(np.float32)
    page.put((0, 2), np.clip(dome, 0, 1).astype(np.float32), base.normal_from_height(dh, 2.0), wrap_x=False,
             wrap_y=False)

    # a globe of Neptune: deep blue with paler bands, its dark spot and white clouds, on a dark stand; its top a blue disc
    ball = R < 7.2 * U
    band = np.mod(YY / U, 5.0) < 1.0
    blue = np.where(band[..., None], base.hexcolor("5b7ff0"), base.hexcolor("3f63e0"))
    globe = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    globe[ball] = np.broadcast_to(blue, (INNER, INNER, 3))[ball]
    globe[ball & (np.hypot((XX - 9.0 * U) / 2.6, (YY - 9.0 * U) / 1.5) < U)] = base.hexcolor("1d2a6e")
    globe[ball & (np.abs(YY - 11.5 * U) < 0.5 * U) & (XX > 7 * U) & (XX < 12 * U)] = base.hexcolor("e6ecff")
    gh = np.sqrt(np.clip(1.0 - (R / (7.2 * U)) ** 2, 0, 1)).astype(np.float32)
    page.put((1, 2), np.clip(globe, 0, 1).astype(np.float32), base.normal_from_height(gh, 3.0), wrap_x=False,
             wrap_y=False)
    top = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    top[ball] = base.hexcolor("5b7ff0")
    top[R < 5.0 * U] = base.hexcolor("3f63e0")
    page.put((2, 2), np.clip(top, 0, 1).astype(np.float32), base.normal_from_height(gh, 3.0), wrap_x=False,
             wrap_y=False)

    # the blue beacon (glows): a glowing lamp in a darker blue frame; its top a blue glow
    edge = (XX < 2 * U) | (XX > 14 * U) | (YY < 2 * U) | (YY > 14 * U)
    lamp = np.where(edge[..., None], base.hexcolor("3f6fe0"),
                    np.where((R < 3 * U)[..., None], base.hexcolor("e0ecff"), base.hexcolor("8fb8ff")))
    page.put((3, 2), np.broadcast_to(lamp, (INNER, INNER, 3)).astype(np.float32), base.flat_normal(), wrap_x=False,
             wrap_y=False)
    glow = np.where((R < 3 * U)[..., None], base.hexcolor("e0ecff"),
                    np.where((R < 6.5 * U)[..., None], base.hexcolor("8fb8ff"), base.hexcolor("3f6fe0")))
    page.put((4, 2), np.broadcast_to(glow, (INNER, INNER, 3)).astype(np.float32), base.flat_normal(), wrap_x=False,
             wrap_y=False)

    # the explorers' pale pink cap bricks; fake pink ice: the ice with a hairline door
    page.put((5, 2), bricks(tex["brick"][0], "f2e1de", 0.15), tex["brick"][1])
    fake = pink_side.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.74
    page.put((6, 2), np.clip(fake, 0, 1).astype(np.float32), tex["pale"][1])
    page.save()


def ganymede() -> None:
    tex = {k: base.fetch(v) for k, v in {"pale": "Snow003", "snow": "Snow006", "clear": "Ice004", "dust": "Ground097",
                                         "plastic": "Plastic013A", "brick": "Bricks084"}.items()}
    rng = np.random.default_rng(20260928)
    page = Page("ganymede")

    # the grooved terrain's pale ice: fine parallel grooves with lit crests; its side the pale crust in faint layers
    grooves = np.mod(XX / U + np.floor(YY / U / 6.0), 5.0)
    gh = (np.cos(grooves / 5.0 * 2 * np.pi) * 0.5).astype(np.float32)
    pale = shade(tex["pale"][0], "cfd2d8", 0.9, 1.06)
    grooved = np.clip(pale * (0.93 + 0.12 * gh[..., None]), 0, 1)
    page.put((0, 0), grooved.astype(np.float32), base.normal_from_height(gh, 2.0))
    layers = np.mod(YY / U + np.sin(XX / U * 0.4) * 1.3, 5.0) < 0.9
    crust = np.clip(np.where(layers[..., None], pale * 0.94, pale), 0, 1).astype(np.float32)
    page.put((1, 0), crust, tex["pale"][1])

    # a groove's floor: blue-grey ice
    trough = shade(tex["pale"][0], "aab1bc", 0.9, 1.06)
    trough = np.clip(trough * (0.98 + 0.04 * gh[..., None]), 0, 1)
    page.put((2, 0), trough.astype(np.float32), base.normal_from_height(gh * 0.6, 2.0))

    # the old dark terrain: brownish-grey ice mixed with dust; its side a dark skin over old, dusty ice; old ice itself
    dark = tint(tex["dust"][0], "6f6559", 0.15)
    for _ in range(9):
        dark[disc(rng.random() * INNER, rng.random() * INNER, 0.3 * U)] = base.hexcolor("b8bcc2")
    page.put((3, 0), np.clip(dark, 0, 1).astype(np.float32), tex["dust"][1])
    old = tint(tex["dust"][0], "948a7e", 0.2)
    old_layers = np.mod(YY / U + np.sin(XX / U * 0.5) * 1.2, 4.0) < 0.8
    old = np.clip(np.where(old_layers[..., None], old * 0.92, old), 0, 1).astype(np.float32)
    skin = YY < (3.0 + 2.0 * np.abs(np.sin(XX / U * 0.7 + 0.4))) * U
    page.put((4, 0), np.clip(np.where(skin[..., None], dark, old), 0, 1).astype(np.float32), tex["dust"][1],
             wrap_y=False)
    page.put((5, 0), old, tex["dust"][1])

    # a young crater's fresh ice: brilliant white with glints; its side fresh ice over the crust
    fresh = shade(tex["snow"][0], "f7f9fc", 0.94, 1.04)
    fresh_top = fresh.copy()
    for _ in range(30):
        fresh_top[disc(rng.random() * INNER, rng.random() * INNER, 0.3 * U)] = base.hexcolor("ffffff")
    page.put((6, 0), np.clip(fresh_top, 0, 1).astype(np.float32), tex["snow"][1])
    rim = YY < (3.0 + 2.0 * np.abs(np.sin(XX / U * 0.8))) * U
    page.put((7, 0), np.clip(np.where(rim[..., None], fresh, crust), 0, 1).astype(np.float32), tex["pale"][1],
             wrap_y=False)

    # the poles' frost: white with a violet tint, soft drifts; its side a skin of frost over the crust
    frost = shade(tex["snow"][0], "eeebf8", 0.92, 1.05)
    drift = np.sin(XX / U * 0.6 + np.sin(YY / U * 0.5) * 1.4) < -0.85
    frost_top = np.where(drift[..., None], shade(tex["snow"][0], "ddd7ef", 0.92, 1.05), frost)
    page.put((0, 1), np.clip(frost_top, 0, 1).astype(np.float32), tex["snow"][1])
    fskin = YY < (3.0 + 2.0 * np.abs(np.sin(XX / U * 0.6 + 0.2))) * U
    page.put((1, 1), np.clip(np.where(fskin[..., None], frost, crust), 0, 1).astype(np.float32), tex["pale"][1],
             wrap_y=False)

    # an aurora crystal (unshaded: it glows): green facets low down, red-pink higher up
    gem = shade(tex["clear"][0], "ffffff", 0.95, 1.05)
    up = np.clip((11.0 * U - YY) / (8.0 * U), 0, 1)[..., None]
    colour = base.hexcolor("8affb8") * (1 - up) + base.hexcolor("ff9ccc") * up
    facet = np.mod(np.floor(XX / U / 2) + YY / U, 5.0)
    crystal = gem * colour * (1.0 + 0.12 * (facet < 0.9)[..., None] - 0.08 * (facet > 4.1)[..., None])
    page.put((2, 1), np.clip(crystal, 0, 1).astype(np.float32), base.flat_normal())

    # a globe of Jupiter: cream zones, brown belts and its Great Red Spot on a dark stand; its top cream in brown
    ball = R < 7.2 * U
    yb = np.mod(YY / U, 4.0)
    belt = ((yb >= 1.0) & (yb < 2.0)) | ((yb >= 2.0) & (yb < 3.0) & (YY > 8 * U))
    zone = np.where(belt[..., None], base.hexcolor("b0714a"), base.hexcolor("efe2c4"))
    globe = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    globe[ball] = np.broadcast_to(zone, (INNER, INNER, 3))[ball]
    globe[ball & (np.hypot((XX - 10.0 * U) / 2.2, (YY - 10.0 * U) / 1.3) < U)] = base.hexcolor("d4573a")
    hb = np.sqrt(np.clip(1.0 - (R / (7.2 * U)) ** 2, 0, 1)).astype(np.float32)
    page.put((3, 1), np.clip(globe, 0, 1).astype(np.float32), base.normal_from_height(hb, 3.0), wrap_x=False,
             wrap_y=False)
    top = np.broadcast_to(base.hexcolor("1c2233"), (INNER, INNER, 3)).copy()
    top[ball] = base.hexcolor("b0714a")
    top[R < 4.5 * U] = base.hexcolor("efe2c4")
    page.put((4, 1), np.clip(top, 0, 1).astype(np.float32), base.normal_from_height(hb, 3.0), wrap_x=False,
             wrap_y=False)

    # the aurora lamp (glows): a green lamp in a darker green frame; its top a green glow
    edge = (XX < 2 * U) | (XX > 14 * U) | (YY < 2 * U) | (YY > 14 * U)
    lamp = np.where(edge[..., None], base.hexcolor("2f9e6a"),
                    np.where((R < 3 * U)[..., None], base.hexcolor("e6fff0"), base.hexcolor("6df2a2")))
    page.put((5, 1), np.broadcast_to(lamp, (INNER, INNER, 3)).astype(np.float32), base.flat_normal(), wrap_x=False,
             wrap_y=False)
    glow = np.where((R < 3 * U)[..., None], base.hexcolor("e6fff0"),
                    np.where((R < 6.5 * U)[..., None], base.hexcolor("6df2a2"), base.hexcolor("2f9e6a")))
    page.put((6, 1), np.broadcast_to(glow, (INNER, INNER, 3)).astype(np.float32), base.flat_normal(), wrap_x=False,
             wrap_y=False)

    # the magnetometer: a white box with a copper coil round its middle; its top a white lid with a copper ring
    box = shade(tex["plastic"][0], "eef1f5", 0.92, 1.05)
    box = np.where(((XX < 2 * U) | (XX > 14 * U) | (YY < 2 * U) | (YY > 14 * U))[..., None], box * 0.88, box)
    coil = (YY >= 5 * U) & (YY < 11 * U) & (XX >= 3 * U) & (XX < 13 * U)
    wind = np.mod(YY / U, 2.0) < 1.0
    box[coil & wind] = base.hexcolor("c87533")
    box[coil & ~wind] = base.hexcolor("e09a5c")
    ch = np.where(coil, 0.4 + 0.3 * wind, 0.0).astype(np.float32)
    page.put((7, 1), np.clip(box, 0, 1).astype(np.float32), base.normal_from_height(ch, 2.0), wrap_x=False, wrap_y=False)
    lid = shade(tex["plastic"][0], "eef1f5", 0.92, 1.05)
    lid[(R > 3.5 * U) & (R < 5.0 * U)] = base.hexcolor("c87533")
    lid[R >= 7.0 * U] *= 0.88
    page.put((0, 2), np.clip(lid, 0, 1).astype(np.float32), base.flat_normal(), wrap_x=False, wrap_y=False)

    # the explorers' pale groove bricks; fake grooved ice: the crust with a hairline door
    page.put((1, 2), bricks(tex["brick"][0], "e6e3dc", 0.15), tex["brick"][1])
    fake = crust.copy()
    for x in (3, 12):
        fake[(np.abs(XX - x * U) < 1.2) & (YY > 3 * U)] *= 0.74
    page.put((2, 2), np.clip(fake, 0, 1).astype(np.float32), tex["pale"][1])
    page.save()

PAGES = {"moon": moon, "boing": boing, "rainbow": rainbow, "mars": mars, "europa": europa, "io": io, "titan": titan,
         "mercury": mercury, "venus": venus, "rings": rings,
         "pluto": pluto, "triton": triton, "ganymede": ganymede}


def main() -> None:
    names = sys.argv[1:] or list(PAGES)
    for n in names:
        PAGES[n]()


if __name__ == "__main__":
    main()
