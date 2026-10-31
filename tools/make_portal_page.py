#!/usr/bin/env python3
"""Builds the REALISTIC twin of block atlas page 5 (M3 Task 5): the portal frame and the portal core.

Outputs data/blocks/pages/portals_albedo.png (RGBA) and portals_normal.png (RGB, OpenGL normals), 2048 px,
in the same 8x8 layout as the pixel page data/blocks/pages/portals.png (tools/make_portal_page.gd):
  Owner #43 (our own look, spec §3c): golden and rainbow, never purple swirls in dark frames:
  (0, 0) frame side: CC0 ambientCG stone (Rock035) cut into gold-tinted blocks, a column of rainbow gems
  (1, 0) frame top/bottom: the same gold, a ring of rainbow gems
  (2, 0) core side: a rainbow swirl gem in a golden setting (drawn unshaded in the game: flat normal)
  (3, 0) core top/bottom: a four-pointed star of light on rainbow gold
  Row 6 (spec §12.19; crafting_tiles, no randomness; owner #43: the Workbench and the Clay Oven): (0, 6) Workbench
  top (CC0 WoodFloor043: a wooden rim round a teal painted mat, a golden star stamp, three paint pots), (1, 6) its
  side (planks, a teal band with paint drips, two drawers with brass knobs), (2, 6) planks, (3, 6) Clay Oven top
  (CC0 Plaster001 dyed terracotta: rows of tiles round a chimney hole), (4, 6) its side (a clay dome front with a
  round window of fire; the fire has a flat normal)

M3 Task 14a (the action kit):
  (4, 0) zipline post side: CC0 ambientCG bark (Bark014) with a yellow-and-black band and a metal pulley wheel
  (5, 0) zipline post top/bottom: end grain rings under a round metal cap (Metal034)
  (6, 0) launch pad top: orange chevrons on a dark metal plate (Metal034; drawn unshaded in the game)
  (7, 0) launch pad side/bottom: dark metal (Metal034) with orange and black hazard stripes
  (0, 2) saddle top (M3 Task 20a): CC0 ambientCG leather (Leather026) dyed brown, a pommel, a stitched edge,
         brass rivets
  (1, 2) saddle side and bottom: the same leather, a strap with a brass buckle and a steel stirrup
Owner 39: the universe portal cores (unshaded, flat normals), side then top in each universe's colours:
  212 meadows (0, 1)/(1, 1), 213 desert (2, 1)/(3, 1), 214 frost (4, 1)/(5, 1), 215 candy (6, 1)/(7, 1),
  222 dragon (4, 3)/(5, 3)
M3 Task 21b: 217 trophy shelf side (2, 2) (CC0 WoodFloor043 cut into a frame, the openings see-through: alpha 0) and
  top (3, 2); 218 bookshelf side (4, 2) (the frame full of books) and top (5, 2)
Tiles use the 240 px + 8 px border layout of tools/make_realistic_atlas.py, whose helpers it borrows.

Run from the project root:  python3 tools/make_portal_page.py   (needs Pillow and numpy; downloads cached
in ~/.cache/easycraft-textures). Credits are in assets/CREDITS.md.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_realistic_atlas as mra  # noqa: E402  (its helpers: fetch, pad, normal_from_height, Atlas layout)

OUT_ALBEDO = "data/blocks/pages/portals_albedo.png"
OUT_NORMAL = "data/blocks/pages/portals_normal.png"
N = mra.INNER
GOLD = mra.hexcolor("e2a933")          # owner #43: the frame's gold (was violet stone)
HEART = mra.hexcolor("fffbe8")
SETTING = mra.hexcolor("a8701a")       # the cores' golden setting
RAINBOW = [mra.hexcolor(h) for h in ("ff5a5a", "ffa23a", "ffe14d", "5ad66a", "4aa8ff", "ff7ac8")]


def blocks(color: np.ndarray, normal: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Stone cut into two courses of blocks: tinted gold, grooves between the blocks (height map)."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    course = (yy // (N / 2)).astype(int)
    shift = np.where(course == 1, N / 4, 0.0)
    gy = np.minimum(yy % (N / 2), N / 2 - yy % (N / 2))
    gx = np.minimum((xx + shift) % (N / 2), N / 2 - (xx + shift) % (N / 2))
    groove = np.clip(np.minimum(gx, gy) / 7.0, 0.0, 1.0)
    grey = color.mean(-1, keepdims=True)
    grey = np.clip(grey / max(float(grey.mean()), 1e-6) * 0.45, 0.0, 1.0)   # Rock035 is dark: even it out
    tinted = grey * 0.35 + GOLD * (grey * 0.9 + 0.35)
    tinted *= (0.55 + 0.45 * groove)[..., None]
    height = groove * 0.7 + grey[..., 0] * 0.3
    n = mra.normal_from_height(height, 6.0) * 0.5 + normal * 0.5
    return np.clip(tinted, 0, 1), n, height


def _gems(color: np.ndarray, normal: np.ndarray, height: np.ndarray, spots) -> tuple[np.ndarray, np.ndarray]:
    """Round rainbow gems set into the gold at `spots` [(x, y, radius)], each with a light corner."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    bump = np.zeros((N, N), np.float32)
    for i, (cx, cy, r) in enumerate(spots):
        d = np.hypot(xx - cx, yy - cy)
        m = d < r
        gem = RAINBOW[i % len(RAINBOW)]
        shine = np.clip(1 - np.hypot(xx - cx + r * 0.35, yy - cy + r * 0.35) / (r * 0.5), 0, 1)[..., None]
        color = np.where(m[..., None], gem * (1 - shine) + HEART * shine, color)
        bump = np.maximum(bump, np.clip(1 - d / r, 0, 1) * m)
    normal = mra.normal_from_height(height + bump * 0.8, 6.0) * 0.5 + normal * 0.5
    return color, normal


def frame_side(stone) -> tuple[np.ndarray, np.ndarray]:
    color, normal, height = blocks(*stone)
    spots = [(N / 2, 26 + i * 38, 13) for i in range(6)]
    return _gems(color, normal, height, spots)


def frame_top(stone) -> tuple[np.ndarray, np.ndarray]:
    color, normal, height = blocks(*stone)
    spots = [(N / 2 + 70 * np.cos(a), N / 2 + 70 * np.sin(a), 10) for a in np.linspace(0, 2 * np.pi, 12, endpoint=False)]
    return _gems(color, normal, height, spots)


def _hue(h: np.ndarray) -> np.ndarray:
    """A rainbow colour for a phase (0..1 around the wheel), like the swirl shader's."""
    return np.clip(np.abs(np.mod(h[..., None] + np.array([0.0, 2 / 3, 1 / 3]), 1.0) * 6.0 - 3.0) - 1.0, 0, 1)


def core_side() -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    d = np.hypot(xx - N / 2, yy - N / 2) / (N / 2)
    a = np.arctan2(yy - N / 2, xx - N / 2)
    gem = _hue(a / (2 * np.pi) + d * 0.6) * 0.8 + 0.2
    heart = np.clip(1 - d / 0.25, 0, 1)[..., None]
    gem = gem * (1 - heart) + HEART * heart
    inside = (d < 0.72).astype(np.float32)[..., None]
    rim = np.clip(1 - np.abs(d - 0.76) / 0.05, 0, 1)[..., None]
    out = GOLD * (1 - inside) + gem * inside
    return np.clip(out * (1 - rim) + HEART * rim, 0, 1)


def core_top() -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    dx = np.abs(xx - N / 2) / (N / 2)
    dy = np.abs(yy - N / 2) / (N / 2)
    star = np.clip(1 - (np.minimum(dx, dy) * 10 + np.maximum(dx, dy) * 1.1), 0, 1)
    glow = np.clip(1 - np.hypot(dx, dy) * 1.6, 0, 1) * 0.5
    ring = np.clip(1 - np.abs(np.hypot(dx, dy) - 0.62) / 0.06, 0, 1)[..., None]   # a thin rainbow ring
    base = GOLD * (1 - ring) + _hue(np.arctan2(yy - N / 2, xx - N / 2) / (2 * np.pi)) * ring
    out = base + (HEART - base) * np.clip(star + glow, 0, 1)[..., None]
    edge = ((dx > 0.94) | (dy > 0.94)).astype(np.float32)[..., None]
    return np.clip(out * (1 - edge) + SETTING * edge, 0, 1)


# --- Survivor games and crafting (spec §12.19): the crafting table and the furnace, row 6 ----------------

WOOD_DARK = mra.hexcolor("4a2f17")
FIRE = mra.hexcolor("ff9a2e")
FIRE_HOT = mra.hexcolor("ffd23f")
FIRE_DEEP = mra.hexcolor("b8380a")
SOOT = mra.hexcolor("3a1c12")
# owner #43: the Workbench's paint and the Clay Oven's terracotta
MAT = mra.hexcolor("1fb5ae")
STAR = mra.hexcolor("ffd23f")
KNOB = mra.hexcolor("f2b632")
PAINTS = [mra.hexcolor(h) for h in ("e8403a", "f7d23e", "3a7be8")]
CLAY = mra.hexcolor("c9653c")
CLAY_DARK = mra.hexcolor("9c4526")
CLAY_LIGHT = mra.hexcolor("e58a5c")


def _grooves(color, normal, lines):
    """Darkens `lines` (a 0..1 mask) as grooves and bends the normal map along them."""
    color = color * (1 - 0.55 * lines[..., None])
    normal = mra.normal_from_height(1 - lines, 5.0) * 0.5 + normal * 0.5
    return color, normal


def _paint(color, mask, paint):
    return color * (1 - mask[..., None]) + paint * mask[..., None]


def _lit(tex_color: np.ndarray, target: np.ndarray, lo: float = 0.8, hi: float = 1.15) -> np.ndarray:
    """A flat colour lit by a texture's light and shade (paint on wood, clay on plaster)."""
    lum = tex_color.mean(-1, keepdims=True)
    lum = lum / max(float(lum.mean()), 1e-6)
    return np.clip(target * np.clip(lum, lo, hi), 0, 1)


def _star_mask(cx: float, cy: float, r: float) -> np.ndarray:
    """A five-pointed star (the wand's stamp)."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    a = np.arctan2(yy - cy, xx - cx) + np.pi / 2
    d = np.hypot(xx - cx, yy - cy)
    k = np.abs(np.mod(a, 2 * np.pi / 5) - np.pi / 5) / (np.pi / 5)   # 0 at a point, 1 between points
    return (d < r * (0.45 + 0.55 * (1 - k))).astype(np.float32)


def crafting_tiles() -> dict:
    planks_c, planks_n = mra.fetch("WoodFloor043")
    clay_c, clay_n = mra.fetch("Plaster001")
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    tiles = {(2, 6): (planks_c, planks_n)}
    # the Workbench's top: a wooden rim, a teal painted mat, a golden star stamp, three paint pots at the back
    rim = ((xx < 26) | (yy < 26) | (xx > N - 27) | (yy > N - 27)).astype(np.float32)
    top_c = _paint(_lit(planks_c, MAT, 0.85, 1.1), rim, planks_c * 0.8)
    top_c = _paint(top_c, ((xx < 8) | (yy < 8) | (xx > N - 9) | (yy > N - 9)).astype(np.float32), planks_c * 0.45)
    star = _star_mask(N / 2, N / 2, 52)
    top_c = _paint(top_c, star, STAR)
    pots = np.zeros((N, N), np.float32)
    for i, paint in enumerate(PAINTS):
        pot = (np.hypot(xx - (58 + i * 62), yy - 44) < 13).astype(np.float32)
        top_c = _paint(top_c, pot, paint)
        pots += pot
    top_n = mra.normal_from_height(rim * 0.4 + star * 0.15 + pots * 0.5, 4.0) * 0.5 + planks_n * 0.5
    tiles[(0, 6)] = (top_c, top_n)
    # the Workbench's side: planks, a teal band with paint drips, two drawers with brass knobs
    band = (yy < 30).astype(np.float32)
    drips = np.zeros((N, N), np.float32)
    for dx, length in ((50, 26), (70, 14), (160, 30), (190, 18)):
        drip = ((np.abs(xx - dx) < 5) & (yy < 30 + length)) | (np.hypot(xx - dx, yy - (30 + length)) < 6)
        drips = np.maximum(drips, drip.astype(np.float32))
    side_c = _paint(planks_c, band, _lit(planks_c, MAT, 0.85, 1.1))
    for i, (dx, length) in enumerate(((50, 26), (70, 14), (160, 30), (190, 18))):
        drip = (((np.abs(xx - dx) < 5) & (yy >= 30) & (yy < 30 + length)) | (np.hypot(xx - dx, yy - (30 + length)) < 6))
        side_c = _paint(side_c, drip.astype(np.float32), PAINTS[i % len(PAINTS)])
    drawers = np.zeros((N, N), np.float32)
    knobs = np.zeros((N, N), np.float32)
    for top in (70, 160):
        box = (xx > 30) & (xx < N - 30) & (yy > top) & (yy < top + 70)
        edge = box & ~((xx > 38) & (xx < N - 38) & (yy > top + 8) & (yy < top + 62))
        side_c = _paint(side_c, edge.astype(np.float32), planks_c * 0.45)
        drawers = np.maximum(drawers, box.astype(np.float32))
        knob = (np.hypot(xx - N / 2, yy - (top + 35)) < 11).astype(np.float32)
        side_c = _paint(side_c, knob, KNOB)
        knobs = np.maximum(knobs, knob)
    side_n = mra.normal_from_height(drawers * 0.3 + knobs * 0.5 + band * 0.2 + drips * 0.1, 4.0) * 0.5 + planks_n * 0.5
    tiles[(1, 6)] = (side_c, side_n)
    # the Clay Oven's top: rows of rounded terracotta tiles round a dark chimney hole
    clay = _lit(clay_c, CLAY, 0.8, 1.2)
    row = np.floor(yy / (N / 4))
    sx = np.mod(xx + np.where(np.mod(row, 2) == 1, N / 8, 0), N / 4) / (N / 4)
    ly = np.mod(yy, N / 4) / (N / 4)
    tile_h = np.clip(1 - np.abs(sx - 0.5) * 1.6, 0, 1) * np.clip(1 - ly, 0.2, 1)
    oven_top = clay * (0.72 + 0.4 * tile_h[..., None])
    oven_top[ly > 0.9] = (clay * 0.6)[ly > 0.9]
    hole_d = np.hypot(xx - N / 2, yy - N / 2)
    oven_top[hole_d < 44] = CLAY_DARK * 0.8
    oven_top[hole_d < 30] = SOOT
    top_n = mra.normal_from_height(tile_h * 0.8 - (hole_d < 30) * 0.6, 5.0) * 0.6 + clay_n * 0.4
    tiles[(3, 6)] = (np.clip(oven_top, 0, 1), top_n)
    # the Clay Oven's side: a clay dome front, rounded shoulders, a round window of fire, a ledge
    side = clay.copy()
    shoulder = (np.hypot(np.maximum(40 - xx, xx - (N - 41)).clip(0), np.maximum(40 - yy, 0)) > 40) & (yy < 40) & \
        ((xx < 40) | (xx > N - 41))
    side[shoulder] = CLAY_DARK
    wd = np.hypot(xx - N / 2, yy - N * 0.58)
    window = wd < 56
    ring = window & (wd > 45)
    heat = np.clip(1 - wd / 45, 0, 1)[..., None]
    fire = FIRE_DEEP * (1 - heat) + FIRE * heat
    fire = np.where((heat > 0.55), FIRE_HOT * np.ones_like(fire), fire)
    side = np.where(window[..., None], fire, side)
    side[ring] = SOOT
    ledge = yy > N - 30
    side[ledge] = (clay * 1.15)[ledge]
    side[yy > N - 12] = CLAY_DARK
    side_n = mra.normal_from_height((window & ~ring) * -0.5 + ring * 0.4 + ledge * 0.3, 5.0) * 0.6 + clay_n * 0.4
    side_n[window & ~ring] = mra.FLAT / 255.0
    tiles[(4, 6)] = (np.clip(side, 0, 1), side_n)
    return tiles

# --- M3 Task 14a: the zipline post and the launch pad ---

HAZARD_Y = mra.hexcolor("ffd23f")
HAZARD_K = mra.hexcolor("2b2f3a")
ORANGE = mra.hexcolor("ff8a1c")
ORANGE_LIGHT = mra.hexcolor("ffd28a")
PLATE = mra.hexcolor("33384a")


def _grey(color: np.ndarray, level: float) -> np.ndarray:
    g = color.mean(-1, keepdims=True)
    return np.clip(g / max(float(g.mean()), 1e-6) * level, 0, 1)


def _disc(cx: float, cy: float, r: float) -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    return np.hypot(xx - cx, yy - cy) <= r


def post_side(bark, metal) -> tuple[np.ndarray, np.ndarray]:
    color, normal = bark[0].copy(), bark[1].copy()
    color = np.clip(color * 1.15, 0, 1)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    band = (yy >= 30) & (yy < 75)
    stripe = (((xx + yy) // 30) % 2 == 0)
    color[band & stripe] = HAZARD_Y
    color[band & ~stripe] = HAZARD_K
    normal[band] = mra.FLAT / 255.0
    steel = _grey(metal[0], 0.7)
    wheel = _disc(N / 2, 150, 55)
    hub = _disc(N / 2, 150, 18)
    rim = wheel & ~_disc(N / 2, 150, 40)
    color = np.where(wheel[..., None], steel * 0.8 + 0.1, color)
    color = np.where(rim[..., None] | hub[..., None], steel * 0.45, color)
    height = wheel.astype(np.float32) * 0.6 + rim.astype(np.float32) * 0.3
    normal = np.where(wheel[..., None], mra.normal_from_height(height, 4.0), normal)
    return color, normal


def post_top(bark, metal) -> tuple[np.ndarray, np.ndarray]:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    r = np.hypot(xx - N / 2, yy - N / 2)
    base = bark[0].mean(-1, keepdims=True) * np.array([1.25, 0.85, 0.55], np.float32)
    rings = (np.sin(r / 6.0) * 0.5 + 0.5)[..., None]
    color = np.clip(base * (0.75 + 0.35 * rings), 0, 1)
    cap = r <= 70
    steel = _grey(metal[0], 0.75)
    color = np.where(cap[..., None], steel, color)
    color = np.where(((r > 58) & (r <= 70))[..., None], steel * 0.55, color)
    height = np.clip(1.0 - np.abs(r - 64) / 8.0, 0, 1) * cap
    return color, mra.normal_from_height(height + (np.sin(r / 6.0) * 0.1) * ~cap, 3.0)


def pad_top(metal) -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    color = np.clip(_grey(metal[0], 0.5) * 0.5 + PLATE * 0.6, 0, 1)
    for k in range(3):
        top = 30 + k * 62
        d = yy - (top + np.abs(xx - N / 2) * 0.9)
        color = np.where(((d >= 0) & (d < 14) & (np.abs(xx - N / 2) < 100))[..., None], ORANGE, color)
        color = np.where(((d >= 14) & (d < 22) & (np.abs(xx - N / 2) < 100))[..., None], ORANGE_LIGHT, color)
    edge = (xx < 8) | (yy < 8) | (xx >= N - 8) | (yy >= N - 8)
    return np.where(edge[..., None], PLATE * 0.6, color)


def pad_side(metal) -> tuple[np.ndarray, np.ndarray]:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    color = np.clip(_grey(metal[0], 0.55) * 0.5 + PLATE * 0.6, 0, 1)
    band = (yy >= 75) & (yy < 165)
    stripe = (((xx + yy) // 45) % 2 == 0)
    color[band & stripe] = ORANGE
    color[band & ~stripe] = HAZARD_K
    normal = metal[1].copy()
    normal[band] = mra.FLAT / 255.0
    return color, normal

# --- M3 Task 20a: the saddle ---

BROWN = mra.hexcolor("8b5a2b")
BROWN_DARK = mra.hexcolor("5e3a1a")
BROWN_LIGHT = mra.hexcolor("b07a42")
STITCH = mra.hexcolor("e6c48a")
BRASS = mra.hexcolor("ffd23f")
STEEL = mra.hexcolor("c3c7d2")


def leather(tex) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Leather026 (black leather) as grain: its brightness dyes it brown; a darker rim."""
    color, normal = tex
    grey = color.mean(-1)
    grey = np.clip(grey / max(float(grey.mean()), 1e-6), 0.0, 2.0)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    edge = np.minimum(np.minimum(xx, N - 1 - xx), np.minimum(yy, N - 1 - yy))
    rim = np.clip(1 - edge / 10.0, 0, 1)
    base = BROWN * (1 - rim[..., None]) + BROWN_DARK * rim[..., None]
    dyed = base * (0.7 + 0.3 * grey[..., None])
    height = 0.5 + 0.1 * (grey - 1.0) - rim * 0.2
    return np.clip(dyed, 0, 1), normal, height


def stitches(mask_line: np.ndarray, along: np.ndarray, period: float = 16.0) -> np.ndarray:
    """A dashed line: `mask_line` where `along` falls in the first half of each stitch."""
    return mask_line & ((along % period) < period * 0.55)


def saddle_top(tex) -> tuple[np.ndarray, np.ndarray]:
    color, normal, height = leather(tex)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    inset = np.minimum(np.minimum(xx, N - 1 - xx), np.minimum(yy, N - 1 - yy))
    stitch = stitches(np.abs(inset - 18) < 2.2, xx + yy).astype(np.float32)
    pommel = np.clip(1 - np.hypot((xx - N / 2) / 34, (yy - 58) / 30), 0, 1)
    dip = np.clip(1 - np.hypot((xx - N / 2) / 62, (yy - 160) / 42), 0, 1)
    rivets = np.zeros((N, N), np.float32)
    for cx, cy in ((34, 34), (N - 34, 34), (34, N - 34), (N - 34, N - 34)):
        rivets = np.maximum(rivets, (np.hypot(xx - cx, yy - cy) < 9).astype(np.float32))
    color = color * (1 - 0.35 * dip[..., None]) + (BROWN_LIGHT - color) * (np.clip(pommel * 2, 0, 1) * 0.6)[..., None]
    for layer, tint in ((stitch, STITCH), (rivets, BRASS)):
        color = color * (1 - layer[..., None]) + tint * layer[..., None]
    height = height + pommel * 0.5 - dip * 0.3 - stitch * 0.08 + rivets * 0.15
    normal = mra.normal_from_height(height, 5.0) * 0.6 + normal * 0.4
    return np.clip(color, 0, 1), np.clip(normal, 0, 1)


def saddle_side(tex) -> tuple[np.ndarray, np.ndarray]:
    color, normal, height = leather(tex)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    hem = stitches((np.abs(yy - 30) < 2.2) | (np.abs(yy - (N - 31)) < 2.2), xx).astype(np.float32)
    strap = ((np.abs(xx - N / 2) < 16) & (yy < 146)).astype(np.float32)
    ring_d = np.hypot((xx - N / 2) / 1.0, (yy - 176) / 1.15)
    stirrup = (np.abs(ring_d - 34) < 7).astype(np.float32)
    bx = np.abs(xx - N / 2)
    by = np.abs(yy - 92)
    buckle = (((bx < 28) & (by < 20)) & ~((bx < 20) & (by < 12))).astype(np.float32)
    color = color * (1 - strap[..., None] * 0.4)
    for layer, tint in ((hem, STITCH), (buckle, BRASS), (stirrup, STEEL)):
        color = color * (1 - layer[..., None]) + tint * layer[..., None]
    height = height + strap * 0.25 - hem * 0.08 + buckle * 0.3 + stirrup * 0.35
    normal = mra.normal_from_height(height, 5.0) * 0.6 + normal * 0.4
    return np.clip(color, 0, 1), np.clip(normal, 0, 1)


# --- Owner feedback #39: the universe portal cores (the core's gem in each universe's colours) ---
UNIVERSE_CORES = [
    ((0, 1), (1, 1), mra.hexcolor("14521f"), mra.hexcolor("a8ff9e")),   # 212 Green Meadows
    ((2, 1), (3, 1), mra.hexcolor("7a3a0a"), mra.hexcolor("ffd27a")),   # 213 the Sandstorm Desert
    ((4, 1), (5, 1), mra.hexcolor("173c78"), mra.hexcolor("c6efff")),   # 214 Frostpeak
    ((6, 1), (7, 1), mra.hexcolor("7a1f5a"), mra.hexcolor("ffc2e5")),   # 215 the Candy Kingdom
    ((4, 3), (5, 3), mra.hexcolor("d9546e"), mra.hexcolor("ffe7b8")),   # 222 the Dragon Realm (owner #43: sunrise)
    ((6, 3), (7, 3), mra.hexcolor("0f4c5c"), mra.hexcolor("8ff7e8")),   # 223 the Glow Caves (teal glow, never purple)
]


def universe_core_side(deep: np.ndarray, bright: np.ndarray) -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    d = np.hypot(xx - N / 2, yy - N / 2) / (N / 2)
    a = np.arctan2(yy - N / 2, xx - N / 2)
    swirl = np.clip(np.sin(a * 2.0 + d * 9.0) * 0.5 + 0.5, 0, 1)
    base = deep * 0.55 + bright * 0.45
    gem = base * (1 - swirl[..., None]) + bright * swirl[..., None]
    heart = np.clip(1 - d / 0.25, 0, 1)[..., None]
    gem = gem * (1 - heart) + (bright * 0.4 + 0.6) * heart
    inside = (d < 0.72).astype(np.float32)[..., None]
    rim = np.clip(1 - np.abs(d - 0.76) / 0.05, 0, 1)[..., None]
    out = SETTING * (1 - inside) + gem * inside
    return np.clip(out * (1 - rim) + bright * rim, 0, 1)


def universe_core_top(deep: np.ndarray, bright: np.ndarray) -> np.ndarray:
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    dx = np.abs(xx - N / 2) / (N / 2)
    dy = np.abs(yy - N / 2) / (N / 2)
    star = np.clip(1 - (np.minimum(dx, dy) * 10 + np.maximum(dx, dy) * 1.1), 0, 1)
    glow = np.clip(1 - np.hypot(dx, dy) * 1.6, 0, 1) * 0.5
    base = deep * 0.65 + bright * 0.35
    light = bright * 0.4 + 0.6
    out = base + (light - base) * np.clip(star + glow, 0, 1)[..., None]
    edge = ((dx > 0.94) | (dy > 0.94)).astype(np.float32)[..., None]
    return np.clip(out * (1 - edge) + SETTING * edge, 0, 1)


# --- M3 Task 21b: the trophy shelf (217) and the bookshelf (218) ---
BOOK_COLORS = [mra.hexcolor(h) for h in ("c62828", "1565c0", "2e7d32", "f9a825", "6a1b9a", "ef6c00", "00838f", "ad1457")]
SHELF_BACK = mra.hexcolor("2a1a0c")


def _frame_masks() -> tuple[np.ndarray, np.ndarray]:
    """The cabinet's frame as the pixel tile has it: posts 2 of 16 wide, rails at the top, middle and bottom."""
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    unit = N / 16.0
    post = (xx < 2 * unit) | (xx >= 14 * unit)
    rail = (yy < 2 * unit) | ((yy >= 7 * unit) & (yy < 9 * unit)) | (yy >= 14 * unit)
    return post, rail


def shelf_side(wood, books: bool) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """CC0 WoodFloor043 cut into a frame; the openings are see-through (the trophy shelf) or full of books."""
    color, normal = wood[0].copy(), wood[1].copy()
    post, rail = _frame_masks()
    frame = post | rail
    color = np.where(post[..., None], color * 0.7, color)
    height = frame.astype(np.float32) * 0.6
    alpha = frame.astype(np.float32)
    if books:
        rng = np.random.default_rng(20260941)
        yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
        unit = N / 16.0
        inside = ~frame
        color = np.where(inside[..., None], SHELF_BACK, color)
        for top_row, bottom_row in ((2, 7), (9, 14)):
            x = 2 * unit
            while x < 14 * unit - 1:
                w = unit * (1 + rng.integers(0, 2)) * 0.95
                col = BOOK_COLORS[rng.integers(0, len(BOOK_COLORS))]
                top = (top_row + rng.integers(0, 2) * 0.8) * unit
                book = (xx >= x) & (xx < min(x + w, 14 * unit)) & (yy >= top) & (yy < bottom_row * unit)
                band = book & (yy >= top + unit * 1.0) & (yy < top + unit * 1.6)
                color = np.where(book[..., None], col * (0.85 + 0.15 * np.sin(xx / 3.0))[..., None], color)
                color = np.where(band[..., None], np.clip(col + 0.35, 0, 1), color)
                height = np.where(book, 0.4 - 0.2 * np.abs((xx - x) / max(w, 1) - 0.5), height)
                x += w + unit * 0.05
        alpha = np.ones((N, N), np.float32)
    nrm = mra.normal_from_height(height, 5.0) * 0.6 + normal * 0.4
    return np.clip(color, 0, 1), np.clip(nrm, 0, 1), alpha


def shelf_top(wood) -> tuple[np.ndarray, np.ndarray]:
    color, normal = wood[0].copy(), wood[1].copy()
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    rim = (xx < 12) | (yy < 12) | (xx >= N - 12) | (yy >= N - 12)
    color = np.where(rim[..., None], color * 0.6, color)
    nrm = mra.normal_from_height(rim.astype(np.float32) * 0.5, 4.0) * 0.5 + normal * 0.5
    return np.clip(color, 0, 1), np.clip(nrm, 0, 1)


def main() -> None:
    stone = mra.fetch("Rock035")
    albedo = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 4), np.float32)
    normal = np.zeros((mra.TILE * mra.GRID, mra.TILE * mra.GRID, 3), np.float32)
    normal[...] = mra.FLAT / 255.0

    def put(tile, color, nrm, wrap_y=True) -> None:
        x, y = tile
        rgba = np.concatenate([color, np.ones(color.shape[:2])[..., None]], -1)
        albedo[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(rgba, 0, 1), True, wrap_y)
        normal[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(nrm, 0, 1), True, wrap_y)

    put((0, 0), *frame_side(stone))
    put((1, 0), *frame_top(stone))
    put((2, 0), core_side(), mra.flat_normal())
    put((3, 0), core_top(), mra.flat_normal())
    for tile, (color, nrm) in crafting_tiles().items():   # spec §12.19: row 6
        put(tile, color, nrm, tile not in ((1, 6), (4, 6)))   # owner #43: a side's top band never wraps to its foot
    bark = mra.fetch("Bark014")
    metal = mra.fetch("Metal034")
    put((4, 0), *post_side(bark, metal))
    put((5, 0), *post_top(bark, metal))
    put((6, 0), pad_top(metal), mra.flat_normal())
    put((7, 0), *pad_side(metal))
    hide = mra.fetch("Leather026")   # M3 Task 20a: the saddle
    put((0, 2), *saddle_top(hide))
    put((1, 2), *saddle_side(hide))
    for side, top, deep, bright in UNIVERSE_CORES:   # owner 39: the universe portal cores (unshaded: flat normals)
        put(side, universe_core_side(deep, bright), mra.flat_normal())
        put(top, universe_core_top(deep, bright), mra.flat_normal())

    def put_cut(tile, color, nrm, alpha) -> None:   # M3 Task 21b: a cut-out tile keeps its see-through parts
        x, y = tile
        rgba = np.concatenate([color, alpha[..., None]], -1)
        albedo[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(rgba, 0, 1))
        normal[y * mra.TILE:(y + 1) * mra.TILE, x * mra.TILE:(x + 1) * mra.TILE] = mra.pad(np.clip(nrm, 0, 1))

    wood = mra.fetch("WoodFloor043")   # M3 Task 21b: the trophy shelf and the bookshelf
    put_cut((2, 2), *shelf_side(wood, False))
    put((3, 2), *shelf_top(wood))
    put_cut((4, 2), *shelf_side(wood, True))
    put((5, 2), *shelf_top(wood))
    os.makedirs(os.path.dirname(OUT_ALBEDO), exist_ok=True)
    # M5 Task 3: the rows under the last drawn tile cropped off, no alpha when nothing is see-through
    mra.save_page((albedo * 255 + 0.5).astype(np.uint8), (normal * 255 + 0.5).astype(np.uint8),
                  OUT_ALBEDO, OUT_NORMAL)
    print("PORTAL_PAGE realistic", OUT_ALBEDO, OUT_NORMAL)


if __name__ == "__main__":
    main()
