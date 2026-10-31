#!/usr/bin/env python3
"""Builds the REALISTIC twins of the Seven Natural Wonders' tiles (owner #78, spec §24, the third tour) from CC0
textures (ambientCG, https://ambientcg.com), into rows 1-3 of page 37's realistic page, keeping its row 0 (the New
Seven's: tools/make_wonders_new_realistic.py draws it; run this one after that one), in the same layout as the pixel
tiles (tools/make_wonders_nature_page.gd):

  data/blocks/pages/wonders4_albedo.png, wonders4_normal.png   page 37 (world/universes/wonders_blocks.gd TILES_NATURE)

Tiles are made like tools/make_wonders_new_realistic.py (tools/make_space_realistic.py's Page and helpers): 240 px of
texture plus an 8 px border that continues it. What nature made them of, as real rock looks: the Grand Canyon's layers
(the pale Kaibab limestone with its beds, the Coconino sandstone's slanting dune lines, the Supai's thin red beds, the
Redwall's grey limestone streaked red from above, the green-grey shale, the dark Vishnu schist with pink granite
veins), a trilobite fossil in grey limestone, brain coral, staghorn coral, a sea fan, Parícutin's cinders, a corn plant
(see-through), prayer flags of cloth on a cord (see-through) and the falls' spray (drops, see-through). Our own look
(spec §3c): the beds, lines, streaks, veins, the fossil, the grooves, branches, net, the plant, the flags and the drops
are drawn here; the photos only give the surfaces their grain.
Sources (all CC0, already cached and credited for other pages): Rock030 and Rock029 (the canyon's rock, the limestone),
Rock035 (the schist), Ground079L (the sandstone's grain), Plaster001 (the corals), Ground037 (the cinders), Fabric004
(the flags' cloth), Grass001 (the corn's leaves).

Run from the project root:  PYTHONDONTWRITEBYTECODE=1 python3 tools/make_wonders_nature_realistic.py   (needs Pillow +
numpy). Downloads are cached in ~/.cache/easycraft-textures. Credits: assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as base  # noqa: E402
from make_space_realistic import Page, shade, tint, XX, YY, U, R  # noqa: E402

INNER = base.INNER
C = INNER / 2.0
DIR = "data/blocks/pages/"


def lines(img: np.ndarray, mask: np.ndarray, color: str) -> np.ndarray:
    return np.where(mask[..., None], base.hexcolor(color), img)


def keep_row0(page: Page) -> None:
    """Page 37's row 0 (the New Seven's), as its realistic page has it now."""
    alb = np.asarray(Image.open(DIR + "wonders4_albedo.png").convert("RGBA"), np.float32) / 255.0
    nor = np.asarray(Image.open(DIR + "wonders4_normal.png").convert("RGB"), np.float32) / 255.0
    t = base.TILE
    page.albedo[:t, :, :] = alb[:t, :, :]
    page.normal[:t, :, :] = nor[:t, :, :]
    pixel = np.asarray(Image.open(DIR + "wonders4.png").convert("RGBA"))
    for c in range(base.GRID):   # the row's undrawn tiles stay clear (the page was written without alpha before)
        if not (pixel[0:16, c * 16:(c + 1) * 16, 3] > 0).any():
            page.albedo[:t, c * t:(c + 1) * t, 3] = 0.0


def page37(tex: dict, rng) -> None:
    page = Page("wonders4")
    keep_row0(page)
    # --- Kaibab limestone side (0,1): pale beds with dark bedding lines; top (1,1) ---
    beds = np.mod(YY, 5 * U) > 4.2 * U
    kaibab = lines(shade(tex["rock"][0], "c9c0a6", 0.85, 1.08), beds, "a99f88")
    kaibab_n = base.normal_from_height((beds * -0.4 + base.smooth_noise(3.0) * 0.2).astype(np.float32), 3.0)
    page.put((0, 1), kaibab, kaibab_n)
    page.put((1, 1), shade(tex["rock"][0], "d2cab2", 0.85, 1.08), tex["rock"][1])
    # --- Coconino sandstone side (2,1): cream with slanting lines in sets; top (3,1) ---
    sets = (YY // (8 * U)).astype(int)
    slant = np.mod(XX + YY * 2 + sets * 5 * U, 6 * U) < 0.8 * U
    base_line = np.mod(YY, 8 * U) > 7.3 * U
    coco = lines(lines(shade(tex["sand"][0], "e4d0a2", 0.9, 1.06), slant, "c7ad80"), base_line, "b79d72")
    page.put((2, 1), coco, base.normal_from_height(((slant | base_line) * -0.25).astype(np.float32), 3.0))
    page.put((3, 1), shade(tex["sand"][0], "e4d0a2", 0.9, 1.06), tex["sand"][1])
    # --- Supai red beds side (4,1): thin red layers, darker mudstone, a pale streak; top (5,1) ---
    colors = ["b5533a", "b5533a", "8e3e2c", "c9704f", "b5533a", "8e3e2c", "b5533a", "d89a76"]
    band = (YY // (2 * U)).astype(int) % 8
    supai = np.zeros((INNER, INNER, 3), np.float32)
    for i, col in enumerate(colors):
        supai = np.where((band == i)[..., None], shade(tex["rock2"][0], col, 0.85, 1.08), supai)
    page.put((4, 1), supai, base.normal_from_height((np.isin(band, [2, 5]) * -0.3).astype(np.float32), 3.0))
    page.put((5, 1), shade(tex["rock2"][0], "bf6245", 0.85, 1.08), tex["rock2"][1])
    # --- Redwall side (6,1): grey limestone, red streaks running down from the top; top (7,1) ---
    stain = np.clip(0.55 - YY / INNER * 0.4, 0, 1)
    for _ in range(6):
        sx = rng.random() * INNER
        stain = stain + np.exp(-((XX - sx) / (0.7 * U)) ** 2) * 0.35
    stain = np.clip(stain, 0, 0.9)[..., None]
    grey = shade(tex["rock"][0], "9a948e", 0.85, 1.08)
    red = shade(tex["rock"][0], "b0654a", 0.85, 1.08)
    page.put((6, 1), grey * (1 - stain) + red * stain, tex["rock"][1])
    page.put((7, 1), shade(tex["rock"][0], "a67c6a", 0.85, 1.08), tex["rock"][1])
    # --- Bright Angel shale side (0,2): thin green-grey flaky layers; top (1,2) ---
    flakes = np.mod(YY, 3 * U) > 2.3 * U
    shale = lines(shade(tex["rock2"][0], "8d9a85", 0.85, 1.08), flakes, "6f7a67")
    page.put((0, 2), shale, base.normal_from_height((flakes * -0.35).astype(np.float32), 3.0))
    page.put((1, 2), shade(tex["rock2"][0], "8d9a85", 0.85, 1.08), tex["rock2"][1])
    # --- Vishnu schist (2,2) side and (3,2) top: dark and wavy, a pink granite vein ---
    for tile in ((2, 2), (3, 2)):
        wave = np.mod(YY + np.sin(XX / U * 0.7) * 1.5 * U, 4 * U) < 0.9 * U
        schist = lines(shade(tex["deep"][0], "3b3b44", 0.8, 1.2), wave, "5d5d6a")
        vx = INNER * (0.3 + rng.random() * 0.4) + np.sin(YY / U * 0.6 + rng.random() * 6) * 1.5 * U
        vein = np.abs(XX - vx) < 0.9 * U
        schist = lines(schist, vein, "e0a190")
        page.put(tile, schist, base.normal_from_height((wave * 0.2 + vein * 0.4).astype(np.float32), 3.0))
    # --- Sea fossil side (4,2): grey limestone with a trilobite; its top (6,3) plain limestone ---
    lime = shade(tex["rock"][0], "9b9890", 0.88, 1.06)
    u = (XX - 7.5 * U) / (4.0 * U)
    v = (YY - 8.0 * U) / (5.5 * U)
    body = u * u + v * v <= 1.0
    rim = (u * u + v * v > 1.0) & (u * u + v * v < 1.35)
    lobe = body & (np.abs(XX - 7.5 * U) < 1.2 * U)
    segs = body & (np.mod(YY, 2 * U) < 0.6 * U) & (YY > 5 * U)
    fossil = lines(lines(lines(lines(lime, body, "6e6a62"), lobe, "5c5852"), segs, "8a857c"), rim, "c4bfb3")
    page.put((4, 2), fossil, base.normal_from_height((body * 0.4 + rim * 0.2 - segs * 0.15).astype(np.float32), 3.0))
    page.put((6, 3), shade(tex["rock"][0], "a9a59c", 0.88, 1.06), tex["rock"][1])
    # --- Brain coral (5,2) side and (6,2) top: gold-green with winding grooves ---
    w = np.sin(XX / U * 0.9 + np.sin(YY / U * 0.6) * 2.0) + np.cos(YY / U * 0.8 + np.sin(XX / U * 0.5) * 1.5)
    groove = np.abs(w) < 0.35
    brain = lines(shade(tex["plaster"][0], "b9b142", 0.85, 1.1), groove, "777722")
    brain_n = base.normal_from_height((groove * -0.6 + w * 0.05).astype(np.float32), 3.0)
    page.put((5, 2), brain, brain_n)
    page.put((6, 2), brain, brain_n)
    # --- Staghorn coral (7,2): pink branches like antlers over darker coral ---
    stag = shade(tex["plaster"][0], "8a3a6a", 0.85, 1.1)
    branch = np.zeros((INNER, INNER), bool)
    for b in range(4):
        x0 = (2.0 + b * 3.8) * U
        lean = (rng.random() - 0.5) * 0.8
        trunk = np.abs(XX - (x0 + (15 * U - YY) * lean)) < 0.8 * U
        branch |= trunk & (YY > 1 * U)
        for k in range(2):
            y0 = (4 + rng.random() * 9) * U
            side = 1 if rng.random() < 0.5 else -1
            arm = (np.abs((XX - (x0 + (15 * U - y0) * lean)) * side - (y0 - YY)) < 0.7 * U) & (YY < y0) & (YY > y0 - 4 * U)
            branch |= arm
    page.put((7, 2), lines(stag, branch, "ef8fb0"), base.normal_from_height((branch * 0.6).astype(np.float32), 3.0))
    # --- Sea fan (0,3): a lacy purple net ---
    net = (np.mod(XX + YY, 4 * U) < 0.7 * U) | (np.mod(XX - YY, 4 * U) < 0.7 * U)
    fan = lines(shade(tex["plaster"][0], "4a2a6a", 0.85, 1.1), net, "b070e0")
    page.put((0, 3), fan, base.normal_from_height((net * 0.5).astype(np.float32), 3.0))
    # --- Cinders (1,3) side and (2,3) top: red-black bits of lava full of holes ---
    holes = base.smooth_noise(0.8) > 0.78
    reds = base.smooth_noise(1.2) > 0.62
    cinder = lines(lines(shade(tex["ground"][0], "3a2622", 0.7, 1.3), reds, "5c3028"), holes, "1a1210")
    cinder_n = base.normal_from_height((holes * -0.7 + base.smooth_noise(1.0) * 0.3).astype(np.float32), 4.0)
    page.put((1, 3), cinder, cinder_n)
    page.put((2, 3), cinder, cinder_n)
    # --- Corn (3,3), see-through: a stalk, long leaves, a yellow cob in its husk, a tassel ---
    stalk = (np.abs(XX - 8 * U) < 1.0 * U) & (YY > 2 * U)
    leaves = np.zeros((INNER, INNER), bool)
    for y0, d in ((13, -1), (10, 1), (7, -1), (4, 1)):
        t = (XX - 8 * U) * d
        leaves |= (t > 0) & (t < 6.5 * U) & (np.abs(YY - (y0 * U - t * 0.5)) < 0.7 * U)
    cob = (np.abs(XX - 11 * U) < 1.2 * U) & (YY > 5 * U) & (YY < 11 * U)
    tassel = (np.abs(YY - 1 * U) < 0.9 * U) & (np.abs(XX - 8 * U) < 3 * U)
    plant = shade(tex["leaves"][0], "5aa040", 0.8, 1.15)
    plant = lines(lines(plant, cob, "e8c840"), tassel, "d8c070")
    alpha = (stalk | leaves | cob | tassel).astype(np.float32)
    page.put((3, 3), plant, base.flat_normal(), alpha, wrap_x=False, wrap_y=False)
    # --- Prayer flags (4,3), see-through: a cord and five cloth flags, blue, white, red, green, yellow ---
    cord = np.abs(YY - (3.5 * U + np.sin(XX / INNER * np.pi) * 0.8 * U)) < 0.4 * U
    flags = np.zeros((INNER, INNER, 3), np.float32)
    mask = cord.copy()
    cloth = tex["fabric"][0]
    for i, col in enumerate(["2f6fd0", "f4f4f0", "d03a30", "3aa040", "f0d030"]):
        x0 = (1 + i * 3) * U
        f = (XX >= x0) & (XX < x0 + 2 * U) & (YY >= 5 * U) & (YY < 11 * U)
        flags = np.where(f[..., None], shade(cloth, col, 0.85, 1.1), flags)
        mask |= f
    flags = np.where(cord[..., None], base.hexcolor("4a3a2a"), flags)
    page.put((4, 3), flags, base.flat_normal(), mask.astype(np.float32), wrap_x=False, wrap_y=False)
    # --- Spray (5,3), see-through: drops scattered, white and pale blue ---
    drops = np.zeros((INNER, INNER), bool)
    for _ in range(150):
        drops |= np.hypot(XX - rng.random() * INNER, YY - rng.random() * INNER) < (0.4 + rng.random() * 0.5) * U
    spray = np.where((base.smooth_noise(2.0) > 0.5)[..., None], base.hexcolor("f4fbff"), base.hexcolor("d6ebff"))
    page.put((5, 3), spray, base.flat_normal(), drops.astype(np.float32))
    page.save()


def main() -> None:
    tex = {k: base.fetch(v) for k, v in {"rock": "Rock030", "rock2": "Rock029", "deep": "Rock035", "sand": "Ground079L",
                                         "plaster": "Plaster001", "ground": "Ground037", "fabric": "Fabric004",
                                         "leaves": "Grass001"}.items()}
    rng = np.random.default_rng(20261001)
    page37(tex, rng)


if __name__ == "__main__":
    main()
