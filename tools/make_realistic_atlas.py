#!/usr/bin/env python3
"""Builds the REALISTIC style block atlases from CC0 textures (ambientCG, https://ambientcg.com).

Outputs data/blocks/realistic_albedo.png (RGBA) and data/blocks/realistic_normal.png (RGB,
OpenGL-style normals, as Godot expects), both in the same 8x8 tile layout as data/blocks/atlas.png
(see world/block_library.gd TILES), so switching styles only swaps textures; plus
data/blocks/water_waves.png (tileable wave normals for the realistic water shader).

Each 256 px tile holds the texture at 240 px plus an 8 px border that continues the texture
(wrap-around for tileable textures, edge-clamp where a texture has a top and a bottom), so filtering
and mipmaps never bleed one block's texture into its neighbour.

Run from the project root:  python3 tools/make_realistic_atlas.py
Downloads are cached in ~/.cache/easycraft-textures. Needs Pillow and numpy.
Every source texture is CC0; credits are in assets/CREDITS.md.
"""
import io
import os
import subprocess
import zipfile

import numpy as np
from PIL import Image, ImageFilter

TILE = 256
INNER = 240
PAD = (TILE - INNER) // 2
GRID = 8
CACHE = os.path.expanduser("~/.cache/easycraft-textures")
OUT_ALBEDO = "data/blocks/realistic_albedo.png"
OUT_NORMAL = "data/blocks/realistic_normal.png"
OUT_WAVES = "data/blocks/water_waves.png"   # tileable wave normals for the realistic water shader
BLOCKY_ATLAS = "data/blocks/atlas.png"
RNG = np.random.default_rng(20260923)
FLAT = np.array([128, 128, 255], np.uint8)

# ambientCG assets used (all CC0).
SOURCES = {
    "grass": "Grass005", "dirt": "Ground103", "stone": "Rock030", "sand": "Ground079L",
    "bark": "Bark014", "planks": "WoodFloor043", "brick": "Bricks104", "leaves": "Grass001",
    "plastic": "Plastic013A", "deepstone": "Rock035", "bedrock": "Rock058", "wood": "Wood095",
}


def fetch(asset: str) -> tuple[np.ndarray, np.ndarray]:
    """Colour (RGB) and OpenGL normal (RGB) maps of an ambientCG asset at 1K, as float arrays 0..1."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{asset}_1K-JPG.zip")
    if not os.path.exists(path):
        url = f"https://ambientcg.com/get?file={asset}_1K-JPG.zip"
        subprocess.run(["curl", "-s", "-f", "-L", "-A", "Mozilla/5.0", "-m", "120", "-o", path, url], check=True)
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        color = next(n for n in names if n.endswith("_Color.jpg"))
        normal = next(n for n in names if n.endswith("_NormalGL.jpg"))
        c = Image.open(io.BytesIO(z.read(color))).convert("RGB")
        n = Image.open(io.BytesIO(z.read(normal))).convert("RGB")
    return _fit(c), _fit(n)


def _fit(img: Image.Image) -> np.ndarray:
    return np.asarray(img.resize((INNER, INNER), Image.LANCZOS), np.float32) / 255.0


def smooth_noise(scale: float, size: int = INNER) -> np.ndarray:
    """Tileable smooth noise 0..1 (random field blurred with wrap-around)."""
    base = RNG.random((size, size)).astype(np.float32)
    big = np.tile(base, (3, 3))
    img = Image.fromarray((big * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(scale))
    out = np.asarray(img, np.float32)[size:2 * size, size:2 * size] / 255.0
    return (out - out.min()) / max(out.max() - out.min(), 1e-6)


def normal_from_height(h: np.ndarray, strength: float) -> np.ndarray:
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    n = np.stack([-dx, dy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def flat_normal() -> np.ndarray:
    return np.broadcast_to(FLAT / 255.0, (INNER, INNER, 3)).copy()


def pad(a: np.ndarray, wrap_x: bool = True, wrap_y: bool = True) -> np.ndarray:
    """INNER -> TILE: continue the texture into an 8 px border (wrap or clamp per axis)."""
    widths_y = ((PAD, PAD), (0, 0)) + ((0, 0),) * (a.ndim - 2)
    widths_x = ((0, 0), (PAD, PAD)) + ((0, 0),) * (a.ndim - 2)
    a = np.pad(a, widths_y, mode="wrap" if wrap_y else "edge")
    return np.pad(a, widths_x, mode="wrap" if wrap_x else "edge")


class Atlas:
    def __init__(self) -> None:
        self.albedo = np.zeros((TILE * GRID, TILE * GRID, 4), np.float32)
        self.normal = np.zeros((TILE * GRID, TILE * GRID, 3), np.float32)
        self.normal[...] = FLAT / 255.0

    def put(self, tile, color, normal, alpha=None, wrap_x=True, wrap_y=True) -> None:
        x, y = tile
        rgba = np.concatenate([color, (np.ones(color.shape[:2]) if alpha is None else alpha)[..., None]], -1)
        self.albedo[y * TILE:(y + 1) * TILE, x * TILE:(x + 1) * TILE] = pad(np.clip(rgba, 0, 1), wrap_x, wrap_y)
        self.normal[y * TILE:(y + 1) * TILE, x * TILE:(x + 1) * TILE] = pad(np.clip(normal, 0, 1), wrap_x, wrap_y)

    def save(self) -> None:
        save_page((self.albedo * 255 + 0.5).astype(np.uint8), (self.normal * 255 + 0.5).astype(np.uint8),
                  OUT_ALBEDO, OUT_NORMAL)


def save_page(albedo: np.ndarray, normal: np.ndarray, out_albedo: str, out_normal: str) -> tuple[int, bool]:
    """Writes a realistic page (uint8 RGBA albedo, RGB normal, 8 x 8 tiles of TILE px) the way the game ships it
    (M5 Task 3, the APK size pass). The rows under the last drawn tile are cropped off: the game stretches the 8 x 8
    page's UVs over the rows a texture keeps (BlockLibrary.texture_rows). A page with no see-through tile is written
    without alpha (half the size once VRAM-compressed). Every drawn tile stays exactly as drawn; the normal map is
    imported at half size (process/size_limit in its .import). Returns (rows kept, alpha kept)."""
    alpha = albedo[..., 3]
    drawn = [r for r in range(GRID) if (alpha[r * TILE:(r + 1) * TILE] > 0).any()]
    rows = max(drawn) + 1 if drawn else 1
    albedo = albedo[:rows * TILE]
    normal = normal[:rows * TILE]
    see_through = False
    for r in range(rows):
        for c in range(GRID):
            a = alpha[r * TILE:(r + 1) * TILE, c * TILE:(c + 1) * TILE]
            see_through = see_through or bool((a > 0).any() and (a < 255).any())
    if see_through:
        Image.fromarray(np.ascontiguousarray(albedo), "RGBA").save(out_albedo, optimize=True)
    else:
        Image.fromarray(np.ascontiguousarray(albedo[..., :3]), "RGB").save(out_albedo, optimize=True)
    Image.fromarray(np.ascontiguousarray(normal), "RGB").save(out_normal, optimize=True)
    return rows, see_through


def hexcolor(h: str) -> np.ndarray:
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def main() -> None:
    tex = {k: fetch(v) for k, v in SOURCES.items()}
    at = Atlas()
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)

    at.put((0, 0), *tex["grass"])                                        # grass top
    # grass side: dirt with a ragged grass fringe along the top (clamped vertically)
    fringe = 38 + 22 * smooth_noise(6)[0]
    grass_mask = (yy < fringe[None, :]).astype(np.float32)[..., None]
    side_c = tex["dirt"][0] * (1 - grass_mask) + tex["grass"][0] * grass_mask
    edge = np.abs(yy - fringe[None, :]) < 3
    side_c[edge] *= 0.7
    side_n = tex["dirt"][1] * (1 - grass_mask) + tex["grass"][1] * grass_mask
    at.put((1, 0), side_c, side_n, wrap_y=False)
    at.put((2, 0), *tex["dirt"])                                          # dirt
    at.put((3, 0), *tex["stone"])                                         # stone
    at.put((4, 0), *tex["sand"])                                          # sand
    at.put((5, 0), *tex["bark"])                                          # log side
    # log top: rings of light wood inside a bark border
    r = np.hypot(xx - INNER / 2, yy - INNER / 2)
    rings = 0.5 + 0.5 * np.sin(r * 0.45 + 3.0 * smooth_noise(10))
    wood = tex["wood"][0] * (0.8 + 0.25 * rings[..., None])
    bark_mask = (r > INNER * 0.44)[..., None]
    at.put((6, 0), np.where(bark_mask, tex["bark"][0], wood), np.where(bark_mask, tex["bark"][1], normal_from_height(rings, 1.5)), wrap_x=False, wrap_y=False)
    at.put((7, 0), *tex["planks"])                                        # planks
    # leaves: darker grass texture with clustered holes (cutout material)
    holes = smooth_noise(3)
    leaves_alpha = (holes > 0.36).astype(np.float32)
    at.put((0, 1), tex["leaves"][0] * np.array([0.75, 1.0, 0.7]), tex["leaves"][1], leaves_alpha)
    # glass: a light frame and two streaks; the rest is fully clear (alpha scissor)
    frame = (xx < 12) | (yy < 12) | (xx > INNER - 13) | (yy > INNER - 13)
    streak = (np.abs((xx - yy) - 40) < 6) | (np.abs((xx - yy) + 30) < 3)
    glass_alpha = (frame | (streak & ~frame)).astype(np.float32)
    glass_c = np.where(frame[..., None], np.array([0.85, 0.93, 0.98]), np.array([0.95, 0.98, 1.0]))
    at.put((1, 1), glass_c.astype(np.float32), flat_normal(), glass_alpha, wrap_x=False, wrap_y=False)
    at.put((2, 1), *tex["brick"])                                         # brick
    # light: warm glowing panel
    glow = 1 - np.clip(np.maximum(np.abs(xx - INNER / 2), np.abs(yy - INNER / 2)) / (INNER / 2), 0, 1)
    light_c = hexcolor("fff4c8") * (0.75 + 0.25 * glow[..., None])
    light_c[frame] = hexcolor("c9a24a")
    at.put((3, 1), light_c, flat_normal(), wrap_x=False, wrap_y=False)
    # water: deep blue with soft caustics (the realistic water shader animates its own waves)
    wn = smooth_noise(8)
    at.put((4, 1), hexcolor("1f5fa8") * (0.8 + 0.4 * wn[..., None]), normal_from_height(wn, 2.0))
    # toy blocks: tinted plastic
    for tile, h in [((5, 1), "e8403a"), ((6, 1), "f7d23e"), ((7, 1), "3cc45a"), ((0, 2), "3a7be8"), ((1, 2), "9b4de0")]:
        lum = tex["plastic"][0].mean(-1, keepdims=True)
        at.put(tile, np.clip(lum / max(lum.mean(), 1e-3), 0.7, 1.2) * hexcolor(h), tex["plastic"][1])
    at.put((2, 2), *tex["deepstone"])                                     # deep stone
    bed_c = tex["bedrock"][0] * 0.33
    bed_c[smooth_noise(1.5) > 0.8] *= 0.4
    at.put((3, 2), bed_c, tex["bedrock"][1])                              # bedrock
    # ores: stone with raised blobs of ore
    for tile, ore, shine in [((4, 2), "1e1e22", "3a3a40"), ((5, 2), "d8a27a", "f1c7a3"),
                             ((6, 2), "f7c52b", "fff08a"), ((7, 2), "35e0e0", "b9fff8")]:
        blob = smooth_noise(4)
        mask = (blob > 0.72).astype(np.float32)
        height = np.clip((blob - 0.72) * 6, 0, 1)
        c = tex["stone"][0] * (1 - mask[..., None]) + hexcolor(ore) * (0.8 + 0.3 * height[..., None]) * mask[..., None]
        c[(height > 0.6)] = hexcolor(shine)
        n = np.where(mask[..., None] > 0, normal_from_height(height, 3.0), tex["stone"][1])
        at.put(tile, c, n)
    # crystal: purple facets (Voronoi cells) with bright edges
    seeds = RNG.random((14, 2)) * INNER
    d = np.stack([np.hypot(xx - sx, yy - sy) for sx, sy in seeds], -1)
    order = np.sort(d, -1)
    cell = np.argmin(d, -1)
    shade = RNG.random(14)[cell]
    crys = hexcolor("7d4ff0") * (0.7 + 0.5 * shade[..., None])
    crys[(order[..., 1] - order[..., 0]) < 2.5] = hexcolor("e3d6ff")
    tilt = (RNG.random((14, 2)) - 0.5) * 0.6
    cn = np.stack([tilt[cell, 0], tilt[cell, 1], np.ones_like(shade)], -1)
    cn /= np.linalg.norm(cn, axis=-1, keepdims=True)
    at.put((6, 3), crys, cn * 0.5 + 0.5, wrap_x=False, wrap_y=False)
    # item icons (row 3): the pixel icons, upscaled (the HUD always uses the pixel atlas)
    icons = np.asarray(Image.open(BLOCKY_ATLAS).convert("RGBA"), np.float32) / 255.0
    for x in range(6):
        icon = icons[48:64, x * 16:(x + 1) * 16]
        big = np.asarray(Image.fromarray((icon * 255).astype(np.uint8), "RGBA").resize((INNER, INNER), Image.NEAREST), np.float32) / 255.0
        at.put((x, 3), big[..., :3], flat_normal(), big[..., 3], wrap_x=False, wrap_y=False)
    put_beds(at, tex)                                                     # row 4 (M1b Task 10)

    # weapon, tool and target icons (row 5, M1b Task 11), the same way
    for x in range(8):
        icon = icons[80:96, x * 16:(x + 1) * 16]
        big = np.asarray(Image.fromarray((icon * 255).astype(np.uint8), "RGBA").resize((INNER, INNER), Image.NEAREST), np.float32) / 255.0
        at.put((x, 5), big[..., :3], flat_normal(), big[..., 3], wrap_x=False, wrap_y=False)
    put_hiding_spots(at, tex)                                             # row 6, (0..5, 6) (M2 Task 5)
    put_secrets(at, tex, icons)                                           # (6..7, 6) and row 7 (M2 Task 16)
    put_defenses(at, tex)                                                 # (3..7, 4) and (7, 3) (M2 Task 8)
    at.save()
    waves = normal_from_height(0.6 * smooth_noise(5, 256) + 0.4 * smooth_noise(2, 256), 1.2)
    Image.fromarray((waves * 255 + 0.5).astype(np.uint8), "RGB").save(OUT_WAVES, optimize=True)
    print("REALISTIC atlas saved:", OUT_ALBEDO, OUT_NORMAL, OUT_WAVES)


def put_beds(at: Atlas, tex: dict) -> None:
    """Bed tiles (M1b Task 10), row 4: procedural cloth on the CC0 wood. Laid out like the pixel
    tiles (16 rows of 15 px). The bed is 0.5625 high, so a side face only shows the bottom 9 rows.
    Uses its own RNG, so the tiles before it and the water waves after it never change."""
    rng = np.random.default_rng(2026092410)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0

    def noise(scale: float) -> np.ndarray:
        base = np.tile(rng.random((INNER, INNER)).astype(np.float32), (3, 3))
        img = Image.fromarray((base * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(scale))
        out = np.asarray(img, np.float32)[INNER:2 * INNER, INNER:2 * INNER] / 255.0
        return (out - out.min()) / max(out.max() - out.min(), 1e-6)

    cloth = 0.88 + 0.06 * np.sin(xx * 2.1) * np.sin(yy * 2.1) + 0.08 * noise(1.2)
    red, sheet, pillow = hexcolor("d23f35"), hexcolor("f1ede4"), hexcolor("fbf8f0")
    wood_c, wood_n = tex["wood"]
    plank_c, plank_n = tex["planks"]

    # top: wooden rim, pillow at the top rows (the +Z end), folded sheet, quilted blanket
    seam_x = np.abs(np.mod(xx - u, 5 * u) - 2.5 * u) / (2.5 * u)
    seam_y = np.abs(np.mod(yy - 7 * u, 4 * u) - 2 * u) / (2 * u)
    puff = np.sqrt(np.clip(1 - np.maximum(seam_x, seam_y) ** 4, 0, 1))
    color = red * (cloth * (0.72 + 0.28 * puff))[..., None]
    height = puff * 0.6
    fold = (yy >= 5 * u) & (yy < 7 * u)
    color[fold] = (sheet * cloth[..., None] * (1.0 - 0.12 * ((yy - 5 * u) / (2 * u)))[..., None])[fold]
    height[fold] = 0.5 + 0.3 * np.sin((yy[fold] - 5 * u) / (2 * u) * np.pi)
    under = yy < 5 * u
    color[under] = (sheet * 0.88 * cloth[..., None])[under]
    height[under] = 0.2
    px, py = np.clip(np.abs(xx - 8 * u) / (6 * u), 0, 1), np.clip(np.abs(yy - 3 * u) / (2 * u), 0, 1)
    in_pillow = np.maximum(px, py) < 1.0
    bump = np.sqrt(np.clip(1 - px ** 3, 0, 1) * np.clip(1 - py ** 3, 0, 1))
    color[in_pillow] = (pillow * (0.78 + 0.22 * bump)[..., None] * cloth[..., None])[in_pillow]
    height[in_pillow] = 0.4 + 0.6 * bump[in_pillow]
    normal = normal_from_height(height, 6.0)
    rim = (xx < u) | (xx >= INNER - u) | (yy < u) | (yy >= INNER - u)
    color[rim] = (wood_c * 0.8)[rim]
    normal[rim] = wood_n[rim]
    at.put((0, 4), color, normal, wrap_x=False, wrap_y=False)

    # side: blanket (lighter top edge), mattress, wooden frame with legs at the corners
    color = red * cloth[..., None] * np.where(yy < 8 * u, 1.12, 0.92)[..., None]
    height = np.where(yy < 10 * u, 0.6, 0.4)
    mattress = (yy >= 10 * u) & (yy < 12 * u)
    color[mattress] = (sheet * cloth[..., None] * np.where(yy >= 11 * u, 0.86, 1.0)[..., None])[mattress]
    frame = yy >= 12 * u
    legs = frame & (yy >= 13 * u) & ((xx < 2 * u) | (xx >= 14 * u))
    color[frame] = (wood_c * np.where(yy < 12.6 * u, 1.1, 0.9)[..., None])[frame]
    color[legs] *= 0.6
    normal = normal_from_height(height, 3.0)
    normal[frame] = wood_n[frame]
    at.put((1, 4), color, normal, wrap_x=False, wrap_y=False)

    # bottom: planks and four legs
    color = plank_c * 0.8
    corner = ((xx < 3 * u) | (xx >= 13 * u)) & ((yy < 3 * u) | (yy >= 13 * u))
    color[corner] *= 0.55
    at.put((2, 4), color, plank_n, wrap_x=False, wrap_y=False)


def put_secrets(at: Atlas, tex: dict, icons: np.ndarray) -> None:
    """Secrets and treasures (M2 Task 16): fake wall, pressure plate, golden trophy, golden lamp and the
    treasure map icon, in (6..7, 6) and row 7 like the pixel atlas. Uses its own RNG, so the tiles before
    it and the water waves after it never change."""
    rng = np.random.default_rng(2026092416)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0
    stone_c, stone_n = tex["stone"]

    def pixel_tile(tx: int, ty: int, smooth: bool = False) -> np.ndarray:
        icon = icons[ty * 16:(ty + 1) * 16, tx * 16:(tx + 1) * 16]
        img = Image.fromarray((icon * 255).astype(np.uint8), "RGBA")
        return np.asarray(img.resize((INNER, INNER), Image.BILINEAR if smooth else Image.NEAREST), np.float32) / 255.0

    def blur_noise(scale: float) -> np.ndarray:
        base = np.tile(rng.random((INNER, INNER)).astype(np.float32), (3, 3))
        img = Image.fromarray((base * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(scale))
        out = np.asarray(img, np.float32)[INNER:2 * INNER, INNER:2 * INNER] / 255.0
        return (out - out.min()) / max(out.max() - out.min(), 1e-6)

    # fake wall: the stone texture with a faint crack (the pixel tile's crack path, scaled)
    crack = np.zeros((INNER, INNER), bool)
    path = [(9, 2), (8, 3), (8, 4), (7, 5), (7, 6), (8, 7), (8, 8), (7, 9), (6, 10), (6, 11), (7, 12)]
    for (ax, ay), (bx, by) in zip(path, path[1:]):
        for t in np.linspace(0.0, 1.0, 40):
            cx, cy = (ax + (bx - ax) * t + 0.5) * u, (ay + (by - ay) * t + 0.5) * u
            crack |= np.hypot(xx - cx, yy - cy) < 2.2
    fake_c = stone_c.copy()
    fake_c[crack] *= 0.62
    at.put((6, 6), fake_c, stone_n)

    # pressure plate: lighter stone with a dark edge and a raised rim; its side is the plate's edge
    edge = (xx < u) | (yy < u) | (xx >= INNER - u) | (yy >= INNER - u)
    rim = ~edge & ((xx < 2 * u) | (yy < 2 * u) | (xx >= INNER - 2 * u) | (yy >= INNER - 2 * u))
    plate_c = np.clip(stone_c * 1.18, 0, 1)
    plate_c[rim] = np.clip(stone_c[rim] * 1.4, 0, 1)
    plate_c[edge] = stone_c[edge] * 0.6
    height = np.where(edge, 0.0, np.where(rim, 1.0, 0.7)).astype(np.float32)
    at.put((7, 6), plate_c, normal_from_height(height, 4.0), wrap_x=False, wrap_y=False)
    side_c = np.clip(stone_c * 1.18, 0, 1)
    side_c[yy >= 15 * u] = stone_c[yy >= 15 * u] * 0.6
    at.put((0, 7), side_c, stone_n, wrap_x=False, wrap_y=False)

    # golden trophy and lamp: brushed gold with the pixel tile's relief
    metal = 0.85 + 0.25 * blur_noise(1.0)
    for tile in [(1, 7), (2, 7)]:
        big = pixel_tile(*tile)
        lum = big[..., :3].mean(-1)
        color = np.clip(big[..., :3] * metal[..., None], 0, 1)
        at.put(tile, color, normal_from_height(lum, 5.0), wrap_x=False, wrap_y=False)
    lamp = pixel_tile(3, 7, smooth=True)
    at.put((3, 7), lamp[..., :3], flat_normal(), wrap_x=False, wrap_y=False)

    # treasure map icon (the HUD uses the pixel atlas; kept here so both layouts match)
    icon = pixel_tile(4, 7)
    at.put((4, 7), icon[..., :3], flat_normal(), icon[..., 3], wrap_x=False, wrap_y=False)

def put_hiding_spots(at: Atlas, tex: dict) -> None:
    """Hiding spots (M2 Task 5), row 6, laid out like the pixel tiles: bush side (0, 6) and top (1, 6),
    barrel side (2, 6) and lid (3, 6), closet front (4, 6) and top (5, 6). The CC0 grass, wood and
    planks with procedural berries, hoops, doors and knobs. Its own RNG, so nothing else changes."""
    rng = np.random.default_rng(2026092450)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0

    def noise(scale: float) -> np.ndarray:
        base = np.tile(rng.random((INNER, INNER)).astype(np.float32), (3, 3))
        img = Image.fromarray((base * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(scale))
        out = np.asarray(img, np.float32)[INNER:2 * INNER, INNER:2 * INNER] / 255.0
        return (out - out.min()) / max(out.max() - out.min(), 1e-6)

    leaf_c, leaf_n = tex["leaves"]
    wood_c, wood_n = tex["wood"]
    plank_c, plank_n = tex["planks"]
    berry = hexcolor("d23f35")
    metal = hexcolor("7d848c")

    # bush: dense dark leaves with a few gaps (cutout) and red berries; the side's top corners round off
    holes = noise(2.5)
    green = leaf_c * np.array([0.62, 0.92, 0.58])
    dots = noise(4.0)
    berries = dots > 0.86
    shine_dots = dots > 0.95
    for tile, rounded in (((0, 6), True), ((1, 6), False)):
        alpha = (holes > 0.2).astype(np.float32)
        if rounded:
            cx = np.minimum(xx, INNER - 1 - xx)
            corner = (yy < 4 * u) & (cx < 4 * u) & (np.hypot(cx - 4 * u, yy - 4 * u) > 4 * u)
            alpha[corner] = 0.0
        color = green.copy()
        color[berries] = berry
        color[shine_dots] = berry * 1.6
        alpha[berries] = 1.0
        at.put(tile, color, leaf_n, alpha, wrap_x=False, wrap_y=False)

    # barrel side: vertical staves of CC0 wood, dark seams, two iron hoops, darker at the edges
    stave = np.mod(xx, 4 * u)
    color = wood_c * (0.85 + 0.15 * (np.floor(xx / (4 * u)) % 2))[..., None]
    color[stave < 0.35 * u] *= 0.55
    edge = np.minimum(xx, INNER - 1 - xx) / (2 * u)
    color *= np.clip(0.7 + 0.3 * edge, 0.7, 1.0)[..., None]
    height = np.where(stave < 0.35 * u, 0.2, 0.6)
    hoop = ((yy >= 3 * u) & (yy < 5 * u)) | ((yy >= 12 * u) & (yy < 14 * u))
    shine = ((yy >= 3 * u) & (yy < 3.6 * u)) | ((yy >= 12 * u) & (yy < 12.6 * u))
    color[hoop] = metal * 0.8
    color[shine] = metal * 1.35
    height = np.where(hoop, 0.9, height)
    normal = normal_from_height(height, 4.0)
    normal[~hoop] = (normal[~hoop] + wood_n[~hoop]) * 0.5
    at.put((2, 6), color, normal, wrap_x=False, wrap_y=False)

    # barrel lid: planks inside an iron rim, a dark bung, stave ends in the corners
    r = np.hypot(xx - INNER / 2, yy - INNER / 2) / u
    color = plank_c * 0.9
    color[r > 7.6] = wood_c[r > 7.6] * 0.45
    rim = (r > 6.2) & (r <= 7.6)
    color[rim] = metal * np.where(r[rim] < 6.9, 1.3, 0.85)[..., None]
    bung = (np.abs(xx - 10.5 * u) < u) & (np.abs(yy - 6.5 * u) < u)
    color[bung] = hexcolor("3b2a1a")
    height = np.where(rim, 0.9, np.where(bung, 0.0, 0.5))
    normal = normal_from_height(height, 4.0)
    inside = ~rim & ~bung & (r <= 7.6)
    normal[inside] = plank_n[inside]
    at.put((3, 6), color, normal, wrap_x=False, wrap_y=False)

    # closet front: a dark frame, two doors with raised panels, air slits and gold knobs
    color = wood_c * 0.8
    frame = (xx < u) | (xx >= INNER - u) | (yy < u) | (yy >= INNER - u)
    gap = (xx >= 7 * u) & (xx < 9 * u)
    px = np.where(xx < 7 * u, xx - u, xx - 9 * u)
    panel = ~frame & ~gap & (px >= u) & (px < 5 * u) & (yy >= 2 * u) & (yy < 14 * u) & ~((yy >= 7 * u) & (yy < 9 * u))
    color[panel] = (plank_c * 1.05)[panel]
    color[frame] = (wood_c * 0.45)[frame]
    color[gap & (xx < 8 * u)] = (wood_c * 0.35)[gap & (xx < 8 * u)]
    slits = np.zeros_like(frame)
    for sx in (2, 4, 11, 13):
        slits |= (xx >= sx * u) & (xx < (sx + 1) * u) & (yy >= 3 * u) & (yy < 5 * u)
    color[slits] = hexcolor("2a1c10")
    knobs = (np.hypot(xx - 6.5 * u, yy - 8.8 * u) < 0.8 * u) | (np.hypot(xx - 9.5 * u, yy - 8.8 * u) < 0.8 * u)
    color[knobs] = hexcolor("f2b632")
    height = np.where(panel, 0.7, np.where(frame, 0.5, 0.4))
    height = np.where(slits, 0.0, np.where(knobs, 1.0, height))
    normal = normal_from_height(height, 5.0)
    at.put((4, 6), color, normal, wrap_x=False, wrap_y=False)

    # closet top: planks with a dark frame
    color = plank_c * 0.8
    top_frame = (xx < u) | (xx >= INNER - u) | (yy < u) | (yy >= INNER - u)
    color[top_frame] = (wood_c * 0.45)[top_frame]
    at.put((5, 6), color, plank_n, wrap_x=False, wrap_y=False)

def put_defenses(at: Atlas, tex: dict) -> None:
    """Defense tiles (M2 Task 8), laid out like the pixel tiles (16 rows of 15 px): the door's side
    (3, 4; its top and bottom are the planks tile), the lantern's top and bottom (4, 4), the open door
    (5, 4, cut out), the spike trap's top (6, 4) and side (7, 4), the lantern's side (7, 3). The wood is
    the CC0 planks texture turned upright; iron, brass, the warning stripes and the glow are painted
    here. Uses its own RNG, so the tiles before it and the water waves after it never change."""
    rng = np.random.default_rng(2026092480)
    yy, xx = np.mgrid[0:INNER, 0:INNER].astype(np.float32)
    u = INNER / 16.0

    def noise(scale: float) -> np.ndarray:
        base = np.tile(rng.random((INNER, INNER)).astype(np.float32), (3, 3))
        img = Image.fromarray((base * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(scale))
        out = np.asarray(img, np.float32)[INNER:2 * INNER, INNER:2 * INNER] / 255.0
        return (out - out.min()) / max(out.max() - out.min(), 1e-6)

    grain = noise(1.0)
    iron = hexcolor("4a4f57") * (0.8 + 0.35 * noise(2.5))[..., None] * (0.95 + 0.1 * grain)[..., None]
    iron_light = hexcolor("9aa3ad") * (0.9 + 0.15 * grain)[..., None]
    wood_c = np.rot90(tex["planks"][0]).copy()                            # upright planks
    wood_n = np.rot90(tex["planks"][1]).copy()
    wood_n = np.stack([1.0 - wood_n[..., 1], wood_n[..., 0], wood_n[..., 2]], -1)   # turn the normals with it
    wood_dark = wood_c * 0.55
    hazard = np.where((np.floor((xx + yy) / (2 * u)) % 2) == 0, 1.0, 0.0)[..., None]
    hazard_c = hexcolor("f7c52b") * hazard + hexcolor("1d2430") * (1 - hazard)

    def disc(cx: float, cy: float, r: float) -> np.ndarray:
        return np.clip(1 - np.hypot(xx - cx, yy - cy) / r, 0, 1)

    # door side: framed upright planks, two iron bands with rivets, a brass knob on a plate
    color = wood_c * 1.05
    height = 0.5 + 0.1 * grain
    seams = (np.abs(xx - 5 * u) < 0.25 * u) | (np.abs(xx - 10 * u) < 0.25 * u)
    color[seams] *= 0.55
    height[seams] = 0.3
    frame = (xx < u) | (xx >= INNER - u)
    color[frame] = wood_dark[frame]
    for band in (2, 12):
        b = (yy >= band * u) & (yy < (band + 2) * u) & ~frame
        color[b] = iron[b]
        height[b] = 0.8
        top = b & (yy < band * u + 0.25 * u)
        color[top] = iron_light[top]
        for rx in (3.5, 12.5):
            rivet = disc(rx * u, (band + 1.5) * u, 0.55 * u)
            color[rivet > 0] = (iron_light * (0.8 + 0.4 * rivet[..., None]))[rivet > 0]
            height = np.maximum(height, 0.8 + 0.2 * rivet)
    plate = (xx >= 11 * u) & (xx < 14 * u) & (yy >= 6 * u) & (yy < 10 * u)
    color[plate] = iron[plate]
    height[plate] = 0.75
    knob = disc(12.6 * u, 7.8 * u, 1.0 * u)
    color[knob > 0] = (hexcolor("f2c037") * (0.6 + 0.6 * knob[..., None]))[knob > 0]
    height = np.maximum(height, 0.75 + 0.25 * knob)
    normal = normal_from_height(height, 4.0)
    wood_area = ~(plate | (knob > 0)) & (height < 0.7)
    normal[wood_area] = (0.5 * normal + 0.5 * wood_n)[wood_area]
    at.put((3, 4), color, normal, wrap_x=False, wrap_y=False)

    # open door: the posts and the swung-open leaf, edge-on; the rest cut out
    alpha = ((xx < 5 * u) | (xx >= 14 * u)).astype(np.float32)
    color = wood_c * 1.05
    posts = (xx < 2 * u) | (xx >= 14 * u)
    color[posts] = (wood_dark * np.where((xx < u) | (xx >= 15 * u), 0.8, 1.0)[..., None])[posts]
    height = np.where(posts, 0.6, 0.5)
    for band in (2, 12):
        b = (yy >= band * u) & (yy < (band + 2) * u) & (xx >= 2 * u) & (xx < 5 * u)
        color[b] = iron[b]
        height[b] = 0.8
    at.put((5, 4), color, normal_from_height(height, 4.0), alpha, wrap_x=False, wrap_y=False)

    # spike trap, top: a worn iron plate, a warning border and nine shiny spikes
    color = iron * 0.8
    height = 0.2 + 0.05 * grain
    border = (xx < 2 * u) | (xx >= 14 * u) | (yy < 2 * u) | (yy >= 14 * u)
    color[border] = (hazard_c * (0.85 + 0.2 * grain[..., None]))[border]
    for sy in (4.5, 8.5, 12.5):
        for sx in (4.5, 8.5, 12.5):
            cone = disc(sx * u, sy * u, 1.45 * u)
            lit = np.clip(0.55 + 0.45 * ((sx * u - xx) + (sy * u - yy)) / (1.45 * u * 1.4), 0.15, 1.0)
            spike = hexcolor("c8d0d8") * lit[..., None]
            ring = disc(sx * u + 0.4 * u, sy * u + 0.4 * u, 1.7 * u) > 0
            color[ring & ~(cone > 0) & ~border] *= 0.6                    # its shadow
            color[cone > 0] = spike[cone > 0]
            color[cone > 0.85] = hexcolor("f1f5f9")
            height = np.maximum(height, cone)
    at.put((6, 4), color, normal_from_height(height, 7.0), wrap_x=False, wrap_y=False)

    # spike trap, side: three spikes over a warning band and a riveted iron base
    color = hexcolor("23272e") * (0.9 + 0.2 * grain)[..., None]
    height = 0.2 + 0.0 * grain
    for cx in (2.5, 7.5, 12.5):
        half = 0.35 * u + (yy - u) * 0.42
        inside = (yy >= u) & (yy < 7 * u) & (np.abs(xx - cx * u) <= half)
        shade = np.where(xx < cx * u, 1.0, 0.62)
        color[inside] = (hexcolor("c8d0d8") * shade[..., None])[inside]
        height = np.where(inside, 0.5 + 0.5 * (1 - np.abs(xx - cx * u) / np.maximum(half, 1)), height)
    band = (yy >= 7 * u) & (yy < 10 * u)
    color[band] = hazard_c[band]
    height[band] = 0.6
    base = yy >= 10 * u
    color[base] = iron[base]
    height[base] = 0.5
    for rx in (2.5, 13.5):
        rivet = disc(rx * u, 12.5 * u, 0.55 * u)
        color[rivet > 0] = (iron_light * (0.8 + 0.4 * rivet[..., None]))[rivet > 0]
        height = np.maximum(height, 0.5 + 0.3 * rivet)
    at.put((7, 4), color, normal_from_height(height, 4.0), wrap_x=False, wrap_y=False)

    # lantern (drawn unshaded: the glass glows): iron cap and base, a dark frame, two bars, a flame
    glow_d = np.hypot(xx - 8 * u, (yy - 8.5 * u) * 0.8) / (6.5 * u)
    flicker = 0.92 + 0.08 * noise(6)
    color = (hexcolor("fff7d6") * (1 - np.clip(glow_d, 0, 1))[..., None]
             + hexcolor("f0a030") * np.clip(glow_d, 0, 1)[..., None]) * flicker[..., None]
    flame = disc(8 * u, 8.2 * u, 1.3 * u)
    color = color * (1 - flame[..., None]) + np.ones(3) * flame[..., None]
    bars = (xx < u) | (xx >= 15 * u) | (np.abs(xx - 5.5 * u) < 0.5 * u) | (np.abs(xx - 10.5 * u) < 0.5 * u)
    color[bars] = (iron * 0.6)[bars]
    capbase = (yy < 3 * u) | (yy >= 13 * u)
    color[capbase] = iron[capbase]
    rims = ((yy >= 2 * u) & (yy < 3 * u)) | ((yy >= 13 * u) & (yy < 14 * u))
    color[rims] = iron_light[rims]
    at.put((7, 3), color, flat_normal(), wrap_x=False, wrap_y=False)

    # lantern top and bottom: an iron plate with rivets round a glowing opening
    d = np.hypot(xx - 8 * u, yy - 8 * u) / u
    color = iron.copy()
    hole = d < 4
    color[hole] = (hexcolor("fff7d6") * (1 - d / 4)[..., None] + hexcolor("f0a030") * (d / 4)[..., None])[hole]
    rim = (d >= 4) & (d < 5)
    color[rim] = iron_light[rim]
    edge = (xx < 0.6 * u) | (xx >= INNER - 0.6 * u) | (yy < 0.6 * u) | (yy >= INNER - 0.6 * u)
    color[edge] = (iron * 0.55)[edge]
    for cx, cy in ((2.5, 2.5), (13.5, 2.5), (2.5, 13.5), (13.5, 13.5)):
        rivet = disc(cx * u, cy * u, 0.55 * u)
        color[rivet > 0] = (iron_light * (0.8 + 0.4 * rivet[..., None]))[rivet > 0]
    at.put((4, 4), color, flat_normal(), wrap_x=False, wrap_y=False)


if __name__ == "__main__":
    main()
