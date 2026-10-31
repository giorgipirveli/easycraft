#!/usr/bin/env python3
"""The pictures of the rocket flight (owner #79, spec §25.3; entities/flight/): the Earth, the Moon and Mars as whole
spheres (equirectangular maps, longitude 0 in the middle), the ground under a landing, the nebula's cloud and a noise
map the other planets are painted with (FlightLooks). All original work drawn here, except the Earth's coastlines:

  assets/flight/earth.png   1024 x 512 RGBA  the land and the seas (RGB) with the clouds in alpha (they turn apart)
  assets/flight/moon.png    1024 x 512 L     the Moon's real seas (maria) and craters at their real places
  assets/flight/mars.png    1024 x 512 RGB   Mars's real dark and bright lands, the volcanoes, the canyon, the caps
  assets/flight/mercury.png 1024 x 512 L     Mercury's real basins, smooth plains and rayed craters (owner #87)
  assets/flight/dust.png     256 x 256 L     a tiling ground of little craters and pebbles (tinted per world)
  assets/flight/noise.png    256 x 128 L     soft noise, seamless round a sphere (the other planets' patches)
  assets/flight/cloud.png    128 x 128 LA    a soft cloud puff (the nebula)

The Earth's land, lakes and ice are Natural Earth's 1:50 million land, lakes and glaciated areas (public domain:
https://www.naturalearthdata.com, "No permission is needed to use Natural Earth"), rasterised once into
tools/data/earth_mask.png (R land, G ice, B lakes) by:  python3 tools/make_flight_textures.py --natural-earth <dir>
(<dir> holds ne_50m_land.geojson, ne_50m_lakes.geojson, ne_50m_glaciated_areas.geojson from
https://github.com/nvkelso/natural-earth-vector/tree/master/geojson). The colours of the lands (deserts, forests,
tundra, ice), the seas' depth and every cloud are drawn here.

The Moon's seas and craters, Mars's lands, volcanoes and canyon are placed at their real latitudes and longitudes (the
table below, rounded; sources: the IAU Gazetteer of Planetary Nomenclature, https://planetarynames.wr.usgs.gov) and
drawn here as soft shapes with our own noise.

Run from the project root:  python3 tools/make_flight_textures.py      (needs Pillow + numpy; seed 20260929)
Then:  godot --headless --path . --import      Credits: assets/CREDITS.md.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = "assets/flight/"
MASK = "tools/data/earth_mask.png"
SEED = 20260929

# --- noise -----------------------------------------------------------------------------------------------------------

_rng = np.random.default_rng(SEED)
_PERM = _rng.permutation(4096).astype(np.int64)
_VALS = _rng.random(4096)


def _hash(ix, iy, iz):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791)
    return _VALS[_PERM[h & 4095] ^ ((h >> 12) & 4095) & 4095]


def value3(x, y, z):
    """Smooth value noise in [0, 1] at 3D points (arrays)."""
    ix, iy, iz = np.floor(x).astype(np.int64), np.floor(y).astype(np.int64), np.floor(z).astype(np.int64)
    fx, fy, fz = x - ix, y - iy, z - iz
    ux, uy, uz = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy), fz * fz * (3 - 2 * fz)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (ux if dx else 1 - ux) * (uy if dy else 1 - uy) * (uz if dz else 1 - uz)
                out = out + w * _hash(ix + dx, iy + dy, iz + dz)
    return out


def fbm3(x, y, z, octaves=5, gain=0.5, lac=2.0):
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total = total + amp * value3(x + o * 17.3, y - o * 9.1, z + o * 5.7)
        norm += amp
        amp *= gain
        x, y, z = x * lac, y * lac, z * lac
    return total / norm


def sphere_grid(w, h):
    """Latitude, longitude (degrees) and unit vectors of an equirectangular map's pixel centres."""
    lon = (np.arange(w) + 0.5) / w * 360.0 - 180.0
    lat = 90.0 - (np.arange(h) + 0.5) / h * 180.0
    lon, lat = np.meshgrid(lon, lat)
    la, lo = np.radians(lat), np.radians(lon)
    v = np.stack([np.cos(la) * np.cos(lo), np.cos(la) * np.sin(lo), np.sin(la)], axis=-1)
    return lat, lon, v


def unit(lat, lon):
    la, lo = math.radians(lat), math.radians(lon)
    return np.array([math.cos(la) * math.cos(lo), math.cos(la) * math.sin(lo), math.sin(la)])


def angle_to(v, lat, lon):
    """Great-circle angle (degrees) from every pixel to a point."""
    return np.degrees(np.arccos(np.clip(v @ unit(lat, lon), -1.0, 1.0)))


def smooth(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


# --- the Earth -------------------------------------------------------------------------------------------------------

def _rings(geom):
    if geom["type"] == "Polygon":
        return [geom["coordinates"]]
    return geom["coordinates"]


def rasterise(paths, size):
    """(land, ice, lakes) masks, each an L image of `size` (4x supersampled), from Natural Earth geojson paths."""
    w, h = size[0] * 4, size[1] * 4

    def xy(p):
        return ((p[0] + 180.0) / 360.0 * w, (90.0 - p[1]) / 180.0 * h)

    out = []
    for path in paths:
        img = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(img)
        with open(path) as f:
            data = json.load(f)
        for feat in data["features"]:
            for poly in _rings(feat["geometry"]):
                d.polygon([xy(p) for p in poly[0]], fill=255)
                for hole in poly[1:]:
                    d.polygon([xy(p) for p in hole], fill=0)
        out.append(img.resize(size, Image.LANCZOS))
    return out


def make_mask(ne_dir):
    names = ["ne_50m_land.geojson", "ne_50m_glaciated_areas.geojson", "ne_50m_lakes.geojson"]
    land, ice, lakes = rasterise([os.path.join(ne_dir, n) for n in names], (2048, 1024))
    os.makedirs(os.path.dirname(MASK), exist_ok=True)
    Image.merge("RGB", (land, ice, lakes)).save(MASK, optimize=True)
    print("wrote", MASK)


# Regions (lat range, lon range, colour weight) whose land is desert, steppe or rainforest (rounded, real places).
DESERTS = [(15, 32, -17, 35), (15, 32, 35, 60), (24, 30, 68, 76), (37, 46, 77, 115), (-32, -19, 116, 142),
           (-28, -17, 12, 25), (-28, -17, -71, -67), (26, 37, -118, -107), (36, 45, 50, 65), (-50, -38, -72, -64)]
RAINFOREST = [(-15, 8, -79, -45), (-6, 6, 9, 30), (-8, 20, 95, 150)]
MOUNTAINS = [(27, 40, 72, 103)]    # the Himalayas and Tibet: brown with snow


def region(lat, lon, boxes, soft=4.0):
    out = np.zeros_like(lat)
    for (la0, la1, lo0, lo1) in boxes:
        a = smooth(la0 - soft, la0 + soft, lat) * (1 - smooth(la1 - soft, la1 + soft, lat))
        b = smooth(lo0 - soft, lo0 + soft, lon) * (1 - smooth(lo1 - soft, lo1 + soft, lon))
        out = np.maximum(out, a * b)
    return out


def make_earth():
    w, h = 1024, 512
    mask = Image.open(MASK).convert("RGB").resize((w, h), Image.LANCZOS)
    m = np.asarray(mask).astype(np.float64) / 255.0
    land = np.clip(m[..., 0] - m[..., 2], 0.0, 1.0)
    ice = m[..., 1]
    lat, lon, v = sphere_grid(w, h)
    n = fbm3(v[..., 0] * 6, v[..., 1] * 6, v[..., 2] * 6, 5)
    n2 = fbm3(v[..., 0] * 18 + 3, v[..., 1] * 18, v[..., 2] * 18, 4)
    alat = np.abs(lat)
    # Land: temperate green, boreal dark green, rainforest, desert sand, tundra, mountains, ice.
    green = np.array([74, 128, 58]) * (0.85 + 0.3 * n2)[..., None]
    boreal = np.array([44, 86, 52])
    tundra = np.array([128, 122, 96])
    sand = np.array([214, 184, 128]) * (0.9 + 0.2 * n2)[..., None]
    jungle = np.array([30, 94, 40])
    rock = np.array([130, 110, 90])
    snow = np.array([236, 240, 245])
    col = green.copy()
    col = col + (boreal - col) * smooth(48, 58, alat)[..., None]
    col = col + (tundra - col) * smooth(60, 68, alat)[..., None]
    desert = np.clip(region(lat, lon, DESERTS) * (0.75 + 0.5 * n), 0, 1)
    col = col + (sand - col) * desert[..., None]
    col = col + (jungle - col) * (region(lat, lon, RAINFOREST) * (1 - desert))[..., None]
    peaks = region(lat, lon, MOUNTAINS)
    col = col + (rock - col) * peaks[..., None] * 0.8
    col = col + (snow - col) * (peaks * smooth(0.55, 0.7, n2))[..., None]
    polar = np.clip(smooth(70, 76, alat) + (lat < -62) * 1.0, 0, 1)
    col = col + (snow - col) * np.clip(np.maximum(ice, polar), 0, 1)[..., None]
    # The seas: deep blue, lighter near the coasts, sea ice at the poles.
    img_land = Image.fromarray((land * 255).astype(np.uint8))
    near = np.asarray(img_land.filter(ImageFilter.GaussianBlur(6))).astype(np.float64) / 255.0
    deep = np.array([18, 52, 120])
    shallow = np.array([40, 110, 170])
    sea = deep + (shallow - deep) * np.clip(near * 2.2 + 0.25 * (n - 0.5), 0, 1)[..., None]
    sea = sea + (np.array([220, 232, 240]) - sea) * smooth(74, 80, alat)[..., None]
    rgb = sea + (col - sea) * land[..., None]
    # Clouds: swirly bands (the rainy belt near the equator and the stormy middle latitudes), few over the deserts.
    wx = fbm3(v[..., 0] * 3 + 11, v[..., 1] * 3, v[..., 2] * 3, 3)
    c = fbm3(v[..., 0] * 5 + wx * 2.5, v[..., 1] * 5 - wx * 2.0, v[..., 2] * 9, 6)
    belt = 0.55 + 0.25 * np.exp(-((lat - 5) / 9) ** 2) + 0.2 * np.exp(-((alat - 55) / 12) ** 2) \
        - 0.18 * np.exp(-((alat - 25) / 8) ** 2)
    clouds = smooth(0.52, 0.72, c * belt + 0.18)
    rgba = np.dstack([np.clip(rgb, 0, 255), clouds * 255]).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(OUT + "earth.png", optimize=True)
    print("wrote", OUT + "earth.png")


# --- the Moon --------------------------------------------------------------------------------------------------------

# The seas (maria): (name, lat, lon, diameter km, stretch east-west). The Moon's radius is 1737 km: 30.3 km a degree.
MARIA = [
    ("Imbrium", 32.8, -15.6, 1146, 1.0), ("Serenitatis", 28.0, 17.5, 707, 1.0),
    ("Tranquillitatis", 8.5, 31.4, 873, 1.1), ("Crisium", 17.0, 59.1, 556, 1.2),
    ("Fecunditatis", -7.8, 51.3, 909, 0.8), ("Nectaris", -15.2, 35.5, 333, 1.0),
    ("Nubium", -21.3, -16.6, 715, 1.1), ("Procellarum N", 30.0, -55.0, 1300, 0.8),
    ("Procellarum S", 5.0, -52.0, 1500, 0.8), ("Insularum", 7.5, -30.9, 513, 1.2),
    ("Cognitum", -10.0, -23.0, 376, 1.0), ("Humorum", -24.4, -38.6, 389, 1.0),
    ("Vaporum", 13.3, 3.6, 245, 1.2), ("Frigoris W", 57.0, -20.0, 500, 3.0), ("Frigoris E", 56.0, 15.0, 500, 3.0),
    ("Orientale", -19.4, -92.8, 300, 1.0), ("Moscoviense", 27.3, 147.9, 277, 1.0), ("Smythii", -1.3, 87.5, 373, 1.0),
    ("Marginis", 13.3, 86.1, 358, 1.0), ("Australe", -38.9, 93.0, 603, 1.0), ("Ingenii", -33.7, 163.5, 318, 1.0),
]
# Craters: (name, lat, lon, diameter km, rays: bright streaks around a young crater, dark floor).
CRATERS = [
    ("Tycho", -43.3, -11.2, 85, 1.0, False), ("Copernicus", 9.6, -20.1, 93, 0.8, False),
    ("Kepler", 8.1, -38.0, 32, 0.6, False), ("Aristarchus", 23.7, -47.4, 40, 0.5, False),
    ("Plato", 51.6, -9.4, 101, 0.0, True), ("Clavius", -58.4, -14.4, 231, 0.0, False),
    ("Grimaldi", -5.2, -68.6, 173, 0.0, True), ("Langrenus", -8.9, 61.1, 132, 0.2, False),
    ("Theophilus", -11.4, 26.4, 100, 0.0, False), ("Ptolemaeus", -9.3, -1.9, 153, 0.0, False),
    ("Tsiolkovskiy", -20.4, 129.1, 185, 0.0, True), ("Petavius", -25.3, 60.4, 188, 0.0, False),
]


def crater(v, img, lat, lon, radius_deg, depth=0.18, rim=0.12):
    a = angle_to(v, lat, lon) / radius_deg
    bowl = (1 - smooth(0.0, 1.0, a)) * depth
    ring = np.exp(-((a - 1.0) / 0.18) ** 2) * rim
    return img - bowl + ring


def make_moon():
    w, h = 1024, 512
    lat, lon, v = sphere_grid(w, h)
    n = fbm3(v[..., 0] * 8, v[..., 1] * 8, v[..., 2] * 8, 6)
    n3 = fbm3(v[..., 0] * 22 + 4, v[..., 1] * 22, v[..., 2] * 22, 4)
    img = 0.64 + 0.16 * (n - 0.5) + 0.08 * (n3 - 0.5)
    # The big dark basin on the far side (South Pole-Aitken): a little darker.
    img = img - 0.07 * (1 - smooth(20, 45, angle_to(v, -53, -169)))
    for (_name, la, lo, d, stretch) in MARIA:
        r = d / 30.3 / 2.0
        # A stretched soft blob: distance with its east-west squeeze, a wobbly edge.
        dla = lat - la
        dlo = ((lon - lo + 180) % 360 - 180) * np.cos(np.radians(la)) / stretch
        dist = np.sqrt(dla ** 2 + dlo ** 2) / r
        edge = 1 - smooth(0.7, 1.15, dist + 0.45 * (n - 0.5) + 0.35 * (n3 - 0.5))
        img = img + (0.36 + 0.12 * (n3 - 0.5) - img) * edge * 0.9
    rng = np.random.default_rng(SEED + 1)
    for _i in range(1400):   # small craters everywhere
        la = math.degrees(math.asin(rng.uniform(-1, 1)))
        lo = rng.uniform(-180, 180)
        r = 0.3 * (rng.pareto(1.8) + 1.0)
        r = min(r, 5.0)
        box = (np.abs(lat - la) < r * 2.2)
        if not box.any():
            continue
        sub = crater(v[box], img[box], la, lo, r, 0.07, 0.035)
        img[box] = sub
    for (_name, la, lo, d, rays, dark) in CRATERS:
        r = d / 30.3 / 2.0
        img = crater(v, img, la, lo, r, 0.12, 0.16)
        if dark:
            img = img - 0.18 * (1 - smooth(0.55, 0.8, angle_to(v, la, lo) / r))
        if rays > 0:
            a = angle_to(v, la, lo)
            # Bright streaks thrown out round a young crater: thin spokes fading with distance.
            to = v - unit(la, lo)
            ang = np.arctan2(to[..., 1], to[..., 0]) + np.arctan2(to[..., 2], 1.0)
            spokes = smooth(0.55, 1.0, np.abs(np.sin(ang * 11 + 1.3)) * fbm3(v[..., 0] * 30, v[..., 1] * 30, v[..., 2] * 30, 2))
            reach = 1 - smooth(r * 2, r * 2 + 40 * rays, a)
            img = img + 0.28 * rays * spokes * reach * (a > r)
            img = img + 0.2 * rays * (1 - smooth(r, r * 1.6, a))
    out = np.clip(img * 255, 0, 255).astype(np.uint8)
    Image.fromarray(out, "L").save(OUT + "moon.png", optimize=True)
    print("wrote", OUT + "moon.png")


# --- Mars ------------------------------------------------------------------------------------------------------------

# (lat, lon, radius degrees, how dark (+) or bright (-)); Mars's radius is 3390 km: 59.2 km a degree.
MARS_AREAS = [
    (8.4, 69.5, 14, 0.55), (46.7, -22.0, 16, 0.45), (-25.0, -40.0, 18, 0.4), (-2.0, 0.0, 10, 0.4),
    (-20.0, 105.0, 16, 0.35), (-20.0, 145.0, 16, 0.35), (-30.0, -155.0, 16, 0.3), (45.0, 110.0, 18, 0.2),
    (-10.0, -10.0, 12, 0.3), (-42.4, 70.5, 19, -0.45), (-49.7, -43.4, 14, -0.3), (20.0, 5.0, 20, -0.25),
    (0.0, -112.0, 26, -0.2),
]
VOLCANOES = [(18.65, -133.8, 5.0), (-8.3, -120.5, 2.2), (0.8, -113.4, 2.0), (11.8, -104.5, 2.0), (24.8, 147.0, 1.6)]


def make_mars():
    w, h = 1024, 512
    lat, lon, v = sphere_grid(w, h)
    n = fbm3(v[..., 0] * 7, v[..., 1] * 7, v[..., 2] * 7, 6)
    n2 = fbm3(v[..., 0] * 24 + 5, v[..., 1] * 24, v[..., 2] * 24, 3)
    n3 = fbm3(v[..., 0] * 3 + 9, v[..., 1] * 3, v[..., 2] * 3, 4)
    rust = np.array([196, 104, 62]) + (np.array([160, 74, 42]) - np.array([196, 104, 62])) * smooth(0.35, 0.65, n)[..., None]
    base = rust * (0.88 + 0.24 * n2)[..., None]
    dark = np.array([88, 52, 38])
    light = np.array([224, 162, 116])
    col = base
    col = col + (dark - col) * (smooth(0.58, 0.75, n3) * 0.45)[..., None]
    for (la, lo, r, k) in MARS_AREAS:
        a = angle_to(v, la, lo) / r
        wgt = (1 - smooth(0.45, 1.25, a + 0.8 * (n - 0.5) + 0.4 * (n2 - 0.5))) * min(abs(k) * 1.5, 0.95)
        col = col + ((dark if k > 0 else light) - col) * wgt[..., None]
    for (la, lo, r) in VOLCANOES:   # shield volcanoes: a pale cone, a dark ring at its foot, a caldera on top
        a = angle_to(v, la, lo) / r
        col = col + (np.array([214, 140, 96]) - col) * (1 - smooth(0.2, 1.0, a))[..., None] * 0.7
        col = col + (np.array([110, 58, 36]) - col) * (np.exp(-((a - 1.05) / 0.12) ** 2) * 0.6)[..., None]
        col = col + (np.array([120, 64, 40]) - col) * (1 - smooth(0.08, 0.16, a))[..., None]
    # Valles Marineris: a long dark gash east-west, ~4000 km (about 68 degrees) just south of the equator.
    t = np.clip((lon + 110.0) / 70.0, 0, 1)
    centre = -6.0 - 8.0 * t
    gash = np.exp(-((lat - centre) / (1.4 + 2.2 * t)) ** 2) * smooth(-114, -108, lon) * (1 - smooth(-44, -36, lon))
    col = col + (np.array([84, 44, 30]) - col) * (gash * 0.85)[..., None]
    col = col + (np.array([214, 150, 108]) - col) * ((np.exp(-((lat - centre) / (2.6 + 3.0 * t)) ** 2) - gash).clip(0) * 0.5
        * smooth(-114, -108, lon) * (1 - smooth(-44, -36, lon)))[..., None]
    # The ice caps: white water ice in the north, the south's smaller cap a little off the pole.
    north = smooth(76, 82, lat + 3 * (n - 0.5))
    south = 1 - smooth(-2, 6, angle_to(v, -87, -30) - 7 - 4 * (n - 0.5))
    col = col + (np.array([240, 236, 230]) - col) * np.clip(north + south, 0, 1)[..., None]
    out = np.clip(col, 0, 255).astype(np.uint8)
    Image.fromarray(out, "RGB").save(OUT + "mars.png", optimize=True)
    print("wrote", OUT + "mars.png")


# --- Mercury (owner #87: "landing on mercury should be done like real landing") ------------------------------------

# (lat, lon, diameter km, kind): basins (a smooth floor and a ring), rayed craters (bright streaks), plains. Mercury's
# radius is 2440 km: 42.6 km a degree.
MERCURY = [
    (31.5, 162.7, 1550, "basin"), (-33.2, 87.7, 715, "basin"), (-20.8, -124.2, 630, "basin"), (-16.3, -164.6, 390, "basin"),
    (57.7, 16.8, 95, "rays"), (-33.9, -12.5, 85, "rays"), (-11.3, -31.2, 62, "rays"), (37.1, -127.5, 60, "rays"),
    (73.4, -79.5, 2600, "plains"),
]


def make_mercury():
    w, h = 1024, 512
    lat, lon, v = sphere_grid(w, h)
    n = fbm3(v[..., 0] * 9 + 7, v[..., 1] * 9, v[..., 2] * 9, 6)
    n3 = fbm3(v[..., 0] * 25, v[..., 1] * 25 + 3, v[..., 2] * 25, 4)
    img = 0.55 + 0.14 * (n - 0.5) + 0.08 * (n3 - 0.5)
    img = img - 0.1 * smooth(0.62, 0.8, fbm3(v[..., 0] * 4 + 1, v[..., 1] * 4, v[..., 2] * 4, 3))   # dark patches
    for (la, lo, d, kind) in MERCURY:
        r = d / 42.6 / 2.0
        a = angle_to(v, la, lo) / r
        if kind == "plains":
            img = img + (0.62 - img) * (1 - smooth(0.6, 1.1, a + 0.3 * (n - 0.5))) * 0.7
        elif kind == "basin":
            img = img + (0.63 + 0.05 * (n3 - 0.5) - img) * (1 - smooth(0.7, 0.95, a)) * 0.8
            img = img + 0.08 * np.exp(-((a - 1.0) / 0.06) ** 2)
    rng = np.random.default_rng(SEED + 3)
    for _i in range(1800):   # craters everywhere: Mercury is covered in them
        la = math.degrees(math.asin(rng.uniform(-1, 1)))
        lo = rng.uniform(-180, 180)
        r = min(0.28 * (rng.pareto(1.7) + 1.0), 4.0)
        box = (np.abs(lat - la) < r * 2.2)
        if box.any():
            img[box] = crater(v[box], img[box], la, lo, r, 0.07, 0.04)
    for (la, lo, d, kind) in MERCURY:
        if kind != "rays":
            continue
        r = d / 42.6 / 2.0
        img = crater(v, img, la, lo, r, 0.1, 0.12)
        a = angle_to(v, la, lo)
        to = v - unit(la, lo)
        ang = np.arctan2(to[..., 1], to[..., 0]) + np.arctan2(to[..., 2], 1.0)
        spokes = smooth(0.55, 1.0, np.abs(np.sin(ang * 13 + 0.7)) * fbm3(v[..., 0] * 30, v[..., 1] * 30, v[..., 2] * 30, 2))
        img = img + 0.3 * spokes * (1 - smooth(r * 2, r * 2 + 30, a)) * (a > r) + 0.2 * (1 - smooth(r, r * 1.8, a))
    Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "L").save(OUT + "mercury.png", optimize=True)
    print("wrote", OUT + "mercury.png")


# --- small ones ------------------------------------------------------------------------------------------------------

def tiling_noise(size, scale, octaves, seed_shift=0.0):
    """Noise that tiles both ways (a torus in 4D, folded into 3D noise on two circles)."""
    w, hgt = size
    x = np.arange(w) / w * 2 * math.pi
    y = np.arange(hgt) / hgt * 2 * math.pi
    x, y = np.meshgrid(x, y)
    r = scale / (2 * math.pi)
    return fbm3(np.cos(x) * r + seed_shift, np.sin(x) * r + np.cos(y) * r, np.sin(y) * r, octaves)


def make_dust():
    s = 256
    img = 0.74 + 0.3 * (tiling_noise((s, s), 8, 5) - 0.5) + 0.14 * (tiling_noise((s, s), 48, 2, 7.0) - 0.5)
    rng = np.random.default_rng(SEED + 2)
    yy, xx = np.mgrid[0:s, 0:s]
    for _i in range(70):   # little craters and pebbles, wrapped round the edges so the tile repeats
        cx, cy = rng.uniform(0, s), rng.uniform(0, s)
        r = rng.uniform(2.0, 14.0) if rng.random() < 0.5 else rng.uniform(1.0, 2.5)
        dx = (xx - cx + s / 2) % s - s / 2
        dy = (yy - cy + s / 2) % s - s / 2
        a = np.sqrt(dx * dx + dy * dy) / r
        if r > 2.5:
            img = img - (1 - smooth(0.0, 1.0, a)) * 0.14 + np.exp(-((a - 1.0) / 0.2) ** 2) * 0.1 * (dy < 0)
        else:
            img = img + (1 - smooth(0.6, 1.0, a)) * 0.18
    Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8), "L").save(OUT + "dust.png", optimize=True)
    print("wrote", OUT + "dust.png")


def make_noise():
    w, h = 256, 128
    lat, lon, v = sphere_grid(w, h)
    n = fbm3(v[..., 0] * 5 + 2, v[..., 1] * 5, v[..., 2] * 5, 6)
    n = (n - n.min()) / (n.max() - n.min())
    Image.fromarray((n * 255).astype(np.uint8), "L").save(OUT + "noise.png", optimize=True)
    print("wrote", OUT + "noise.png")


def make_cloud():
    s = 128
    yy, xx = np.mgrid[0:s, 0:s]
    d = np.sqrt((xx - s / 2 + 0.5) ** 2 + (yy - s / 2 + 0.5) ** 2) / (s / 2)
    n = fbm3(xx / 20.0, yy / 20.0, np.full_like(xx, 3.3, dtype=np.float64), 5)
    a = np.clip((1 - smooth(0.2, 1.0, d + 0.45 * (n - 0.5))) * (0.6 + 0.8 * (n - 0.3)), 0, 1)
    lum = np.clip(0.75 + 0.5 * (n - 0.5), 0, 1)
    la = np.dstack([lum * 255, a * 255]).astype(np.uint8)
    Image.fromarray(la, "LA").save(OUT + "cloud.png", optimize=True)
    print("wrote", OUT + "cloud.png")


def main(argv):
    if len(argv) >= 2 and argv[0] == "--natural-earth":
        make_mask(argv[1])
        return
    os.makedirs(OUT, exist_ok=True)
    only = set(argv)
    for name, fn in [("earth", make_earth), ("moon", make_moon), ("mars", make_mars), ("mercury", make_mercury), ("dust", make_dust),
                     ("noise", make_noise), ("cloud", make_cloud)]:
        if not only or name in only:
            fn()


if __name__ == "__main__":
    main(sys.argv[1:])
