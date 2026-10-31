"""How a volcano erupts (Earth's and Io's): an island volcano as a diorama; its front half sinks away to show the magma
chamber and the pipe; gas pushes the magma up and it erupts; lava pours down the slopes and cools into new rock; then
Jupiter's moon Io and one of its plumes. Link: g4 Volcanoes and earthquakes."""
from reelkit import (arrow, ball, box, cam, disc, model, mv, out, pop, project, pulse, scene, short, sound, starts,
    words)

R = 13              # the cone's foot (blocks)
TOP = 11            # its top layer (the rim, round the crater)
R_TOP = 3.5         # the rim's radius
ISLAND = 15         # the island slab's half width
DEPTH = 12          # how deep the slab goes (rock layers under the grass)
CHAMBER = (0, -8, 0)
CHAMBER_R = 3.4
EDGE = 0.35         # StudioShapes.EDGE


def radius(k):
    """Layer k's radius: wide at the foot, steep near the top (a volcano's concave sides)."""
    return R_TOP + (R - R_TOP) * (1.0 - k / TOP) ** 1.5


def half(front):
    """The island diorama's half (front: z >= 1, else z <= 0): grass, soil and rock layers underground; the cone of old
    lava (basalt) and ash (grey stone) in layers, grass on its lower slopes; the crater with lava in it. The back half has
    the chamber's hollow and the pipe cut through it (the cutaway shows them)."""
    z0, z1 = (1, ISLAND) if front else (-ISLAND, 0)
    f = [box(-ISLAND, -DEPTH, z0, ISLAND, -9, z1, "DEEPSTONE"), box(-ISLAND, -8, z0, ISLAND, -4, z1, "STONE"),
        box(-ISLAND, -3, z0, ISLAND, -2, z1, "DIRT"), box(-ISLAND, -1, z0, ISLAND, -1, z1, "GRASS")]
    for k in range(TOP + 1):
        r = radius(k)
        f.append(disc(0, k, 0, r, "GRASS" if k <= 2 else ("STONE" if k <= 6 else "BASALT")))
        f.append(disc(0, k, 0, max(r - 1.3, 0.5), "BASALT" if k % 2 == 0 else "STONE"))
    f.append(disc(0, TOP, 0, 2.3, "AIR"))
    f.append(disc(0, TOP - 1, 0, 2.0, "HOT_LAVA"))
    if front:
        f.append(box(-ISLAND - 1, -DEPTH - 1, -ISLAND - 1, ISLAND + 1, TOP + 1, 0, "AIR"))
    else:
        f.append(box(-ISLAND - 1, -DEPTH - 1, 1, ISLAND + 1, TOP + 1, ISLAND + 1, "AIR"))
        f.append(ball(CHAMBER[0], CHAMBER[1], CHAMBER[2], CHAMBER_R, "AIR"))
        f.append(box(-1, CHAMBER[1], -1, 0, TOP - 2, 0, "AIR"))
    return f


def top_at(x, z):
    """The volcano's surface height over the cell (x, z): one above its highest layer there (0: the island's grass)."""
    top = 0
    for k in range(TOP + 1):
        if x * x + z * z <= (radius(k) + EDGE) ** 2 and not (k == TOP and x * x + z * z <= (2.3 + EDGE) ** 2):
            top = k + 1
    return top


def flow(x, width):
    """A lava flow down the back slope (-z) from the rim to the grass, lying on the steps; its cells relative to the
    rim's, so a grow from almost nothing pours it out from there."""
    zs = list(range(-3, -R - 4, -1))
    rim = (x, top_at(x, zs[0]), zs[0])
    cells = []
    for z in zs:
        for w in range(width):
            cells.append([x + w - rim[0], top_at(x + w, z) - rim[1], z - rim[2], "HOT_LAVA"])
    return rim, cells


def make():
    s = [
        scene(9, "A volcano looks like a mountain, but deep below it the rock has melted!",
            "A volcano looks like a mountain. But deep under it, it is so hot that the rock has melted.",
            [words("VOLCANO", (180, 84), 34, "white", "red", [pop(1.2)])], [sound(1.2, "pop")]),
        scene(10, "Melted rock under the ground is called magma. It gathers in a chamber.",
            "Let's look inside! Melted rock under the ground is called magma. It rises and gathers in a magma chamber.",
            [], [sound(0.6, "whoosh"), sound(4.4, "pop"), sound(6.6, "pop")]),
        scene(10, "Gas bubbles in the magma push harder and harder... until it erupts!",
            "Gas bubbles in the magma push harder and harder, like a shaken fizzy drink, until the magma bursts out. "
            "The volcano erupts!",
            [words("ERUPTION!", (180, 84), 40, "ink", "yellow", [pop(6.6), pulse(7.6)])],
            [sound(1.0, "bubbles"), sound(6.5, "rock_crash"), sound(6.7, "rocket_whoosh")]),
        scene(10, "Out in the air it is called lava. It is often over 1,000 °C!",
            "Out in the open, magma is called lava. It is often hotter than 1,000 degrees Celsius! As it cools, it "
            "hardens into new rock.",
            [words("LAVA", (180, 84), 34, "white", "orange", [pop(1.4), out(6.5)]),
                words("OFTEN OVER 1,000 °C", (180, 136), 24, "ink", "yellow", [pop(2.2), out(6.5)]),
                words("NEW ROCK!", (180, 84), 34, "white", "ink", [pop(7.0)])],
            [sound(1.4, "pop"), sound(6.9, "ice_crackle")]),
        scene(11, "Jupiter's moon Io has about 400 erupting volcanoes! Which would you visit?",
            "Far away, Jupiter's moon Io has about 400 volcanoes that erupt. Jupiter's pull squeezes Io and keeps its "
            "inside hot. Which volcano would you visit?",
            [words("IO", (180, 84), 40, "ink", "yellow", [pop(1.0)]),
                words("ABOUT 400 VOLCANOES", (180, 140), 24, "white", "orange", [pop(2.0)])],
            [sound(0.3, "whoosh"), sound(2.0, "sparkle")], "space"),
    ]
    t = starts(s)
    erupt = t[2] + 6.5
    cool = t[3] + 6.8
    io = (6000, 0, 0)
    # The cutaway's shot, and the stickers' arrows on the chamber and the pipe (placed by projecting them).
    cut_pos, cut_look, cut_fov = (0, 0.5, 44), (0, -4.0, 0), 50
    chamber = project(cut_pos, cut_look, cut_fov, (CHAMBER[0] - 1.8, CHAMBER[1] + 2.2, 0.5))
    pipe = project(cut_pos, cut_look, cut_fov, (0.6, 2.0, 0.5))
    s[1]["actors"] = [
        words("MAGMA", (64, 100), 28, "white", "red", [pop(4.4)]),
        arrow((64, 124), chamber, 4.8, "white", 6, 0.3),
        words("PIPE", (300, 96), 24, "ink", "yellow", [pop(6.6)]),
        arrow((300, 116), pipe, 7.0, "white", 6, -0.25),
    ]
    rim_l, cells_l = flow(-4, 2)
    rim_r, cells_r = flow(2, 2)

    def lava_flow(id_, rim, cells, start, dur):
        return model(id_, "blocks", rim, cells=cells, moves=[{"do": "grow", "at": 0, "dur": 0.4, "to": 0.02, "ease": "out"},
            {"do": "appear", "at": start}, {"do": "grow", "at": start, "dur": dur, "to": 1.0, "ease": "out"},
            {"do": "out", "at": cool, "dur": 0}])

    models = [
        model("back", "blocks", (0, 0, 0), fill=half(False)),
        model("front", "blocks", (0, 0, 0), fill=half(True), moves=[mv(t[1] + 0.6, (0, -40, 0), 2.6, "in"),
            out(t[1] + 3.2)]),
        model("chamber", "blocks", CHAMBER, fill=[ball(0, 0, 0, CHAMBER_R - 0.4, "HOT_LAVA"), box(-5, -5, 1, 5, 5, 5, "AIR")],
            moves=[{"do": "grow", "at": t[2] + 0.5, "dur": 5.5, "to": 1.12, "ease": "in"},
                {"do": "grow", "at": erupt, "dur": 1.2, "to": 1.0, "ease": "out"}]),
        model("magma", "blocks", (0, CHAMBER[1] + 2, 0), fill=[box(-1, 0, -1, 0, TOP - 2 - (CHAMBER[1] + 2), 0, "HOT_LAVA")],
            stretch=[1, 0.05, 1], moves=[{"do": "grow", "at": t[2] + 0.8, "dur": 5.6, "to": 1.0, "axis": "y", "ease": "in"}]),
        lava_flow("flow_l", rim_l, cells_l, t[3] + 0.5, 5.0),
        lava_flow("flow_r", rim_r, cells_r, t[3] + 1.3, 4.6),
        model("rock_l", "blocks", rim_l, cells=[c[:3] + ["BLACK_LAVA"] for c in cells_l], moves=[{"do": "appear", "at": cool}]),
        model("rock_r", "blocks", rim_r, cells=[c[:3] + ["BLACK_LAVA"] for c in cells_r], moves=[{"do": "appear", "at": cool}]),
        model("jupiter", "planet", (io[0] + 95, io[1] + 34, io[2] - 300), body="jupiter", size=100, turn=[6, 40, 0],
            moves=[{"do": "spin", "at": 0, "rate": 0.006}]),
        model("io", "planet", io, body="io", size=6, moves=[{"do": "spin", "at": 0, "rate": 0.012}]),
    ]
    effects = [
        {"kind": "steam", "at": [-0.5, TOP + 0.4, -0.5], "from": 0, "to": t[1] + 2.0, "size": 0.5, "color": "#d6d6dc"},
        {"kind": "sparkles", "at": [CHAMBER[0] - 0.5, CHAMBER[1] + 0.5, 0.7], "from": t[2] + 0.6, "to": erupt + 0.4,
            "size": 0.9, "color": "#ffc070"},
        {"kind": "lava", "at": [-0.5, TOP, -0.5], "from": erupt, "to": t[4] - 0.2, "size": 1.3, "amount": 140},
        {"kind": "smoke", "at": [-0.5, TOP + 1.5, -0.5], "from": erupt + 0.2, "to": t[4] - 0.2, "size": 0.55,
            "color": "#55504e", "dir": [0, 1, 0], "amount": 70},
        {"kind": "steam", "at": [-0.5, 4, -10], "from": cool - 0.2, "to": cool + 2.2, "size": 0.45, "color": "#eeeef2",
            "amount": 30},
        {"kind": "lava", "at": [io[0], io[1] + 5.95, io[2]], "from": t[4], "to": t[4] + 11, "size": 0.45, "speed": 0.45,
            "gravity": -1.1, "color": "#fff0a0", "amount": 80},
    ]
    camera = [
        cam(0, (34, 24, 62), (0, 2, 0), 40),
        cam(t[1] - 0.05, (22, 13, 40), (0, 3.5, 0), 42),
        cam(t[1], (0, 4, 48), (0, 2, 0), 50, cut=True),
        cam(t[1] + 3.6, cut_pos, cut_look, cut_fov),
        cam(t[2] - 0.05, (0, 0.5, 43), cut_look, cut_fov),
        cam(t[2] + 5.6, (0, 0.5, 41), (0, -2.5, 0), cut_fov, shake=0.04),
        cam(erupt, (0, 1.5, 42), (0, -1.0, 0), cut_fov, shake=0.3),
        cam(t[3] - 0.05, (0, 9, 56), (0, 7, 0), 50, shake=0.12),
        cam(t[3], (-14, 10, -46), (0, 7, -2), 50, cut=True, shake=0),
        cam(t[4] - 0.05, (12, 12, -45), (0, 7, -2), 50, path="orbit"),
        cam(t[4], (io[0] + 5, io[1] + 3, io[2] + 40), (io[0], io[1] + 3.5, io[2]), 45, cut=True),
        cam(t[4] + 11, (io[0] - 7, io[1] + 4, io[2] + 39), (io[0], io[1] + 3.5, io[2]), 45, path="orbit"),
    ]
    sky_day = {"top": "#3a7be8", "horizon": "#cdeeff", "bottom": "#2f78b8"}
    stage = {"sky": [{"at": 0, "sky": sky_day}, {"at": t[4], "sky": "space"}],
        "light": [{"at": 0, "light": "day"}, {"at": t[4], "light": "space"}],
        "sun": [{"at": 0, "sun": [0.45, 0.8, 0.5]}, {"at": t[4], "sun": [-0.6, 0.35, 0.75]}],
        "models": models, "effects": effects, "camera": camera}
    return short("volcano_erupts", "How a volcano erupts", "science", {"unit": "g4.geography.volcanoes_earthquakes"},
        t[2] + 7.5, stage, s)
