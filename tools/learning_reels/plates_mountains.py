"""How mountains grow: a slice of Earth's crust (two plates with their rock layers, hot soft rock below); the plates
creep together; where they push, the layers crumple and fold up into a mountain range (its bands are the same layers,
bent); the Himalayas and Everest; a child on the top. Link: g6 Plate tectonics."""
from reelkit import arrow, box, cam, model, mv, pop, project, scene, short, sound, starts, words

HALF = 12               # the slice's half width (x); the two plates meet at x = 0
Z0, Z1 = -5, 0          # its depth (the front face at z = 0.5 is the cross-section)
PEAK = 9                # the range's highest point above the plain (m, in the model)
LAYERS = [("GRASS", -1, -1), ("SANDSTONE", -3, -2), ("LIMESTONE", -5, -4), ("STONE", -7, -6), ("DEEPSTONE", -9, -8)]


def plate(x0, x1):
    return [box(x0, lo, Z0, x1, hi, Z1, block) for (block, lo, hi) in LAYERS]


def height(x):
    return max(0, int(round(PEAK * max(0.0, 1.0 - (abs(x) / 9.5) ** 1.35))))


def band(depth, y):
    if depth == 0:
        return "SNOW" if y >= 6 else ("STONE" if y >= 4 else "GRASS")
    for (block, lo, hi) in LAYERS[1:]:
        if depth <= -lo - 1:
            return block
    return "DEEPSTONE"


def range_fill():
    """The fold: above the plain, the same rock layers bent up into an arch (each cell's layer from its depth under the
    top), snow on the high tops; a ridge running away from us, so each column's bands are boxes through its depth."""
    f = []
    for x in range(-9, 10):
        h = height(x)
        y = 0
        while y < h:
            block = band(h - 1 - y, y)
            top = y
            while top + 1 < h and band(h - 2 - top, top + 1) == block:
                top += 1
            f.append(box(x, y, Z0, x, top, Z1, block))
            y = top + 1
    return f


def make():
    s = [
        scene(10, "Earth's rocky skin is cracked into giant pieces called plates.",
            "Earth's rocky outer skin is cracked into giant pieces, called plates. They float on hot, soft rock deep "
            "below.",
            [], [sound(1.0, "pop"), sound(3.0, "pop"), sound(6.0, "pop")]),
        scene(10, "Plates move slowly: a few cm a year, as fast as your fingernails grow!",
            "The plates move very slowly, just a few centimetres a year. That is about as fast as your fingernails grow!",
            [words("A FEW cm A YEAR", (180, 84), 28, "ink", "yellow", [pop(1.4)])], [sound(1.4, "pop")], "sky"),
        scene(10, "When two plates push together, the rock layers crumple up into mountains!",
            "When two plates push into each other, the rock has nowhere to go. Its layers crumple and fold upward into "
            "mountains!",
            [words("MOUNTAINS RISE", (180, 84), 28, "white", "brown", [pop(5.0)])],
            [sound(1.0, "rock_crash"), sound(5.0, "pop"), sound(7.0, "rock_crash")]),
        scene(10, "India pushed into Asia and made the Himalayas, with Mount Everest.",
            "This is how the Himalayas grew, as India pushed into Asia. Their top, Mount Everest, is 8,849 metres high: "
            "the highest on Earth!",
            [words("INDIA", (70, 300), 28, "white", "orange", [pop(1.0)]), words("ASIA", (290, 300), 28, "white", "green",
                [pop(1.6)]), words("EVEREST: 8,849 m", (180, 84), 28, "ink", "white", [pop(5.4)])],
            [sound(1.0, "pop"), sound(1.6, "pop"), sound(5.4, "fanfare")]),
        scene(10, "The Himalayas still grow about 1 cm a year! Which mountain would you climb?",
            "India is still pushing, so the Himalayas still grow, by about a centimetre a year. Which mountain would you "
            "like to climb?",
            [words("STILL GROWING", (180, 84), 28, "white", "purple", [pop(1.4)]),
                words("1 cm A YEAR", (180, 136), 24, "ink", "yellow", [pop(2.2)])], [sound(1.4, "pop"),
                sound(5.0, "chime")]),
    ]
    t = starts(s)
    wide_pos, wide_look = (1.0, -6.0, 23), (0, -7.3, 0)
    left_px = project(wide_pos, wide_look, 50, (-3.5, -4, 0.5))
    right_px = project(wide_pos, wide_look, 50, (3.5, -4, 0.5))
    hot_px = project(wide_pos, wide_look, 50, (0, -10.5, 0.5))
    s[0]["actors"] = [words("PLATE", (left_px[0], left_px[1]), 28, "white", "blue", [pop(1.0)]),
        words("PLATE", (right_px[0], right_px[1]), 28, "white", "green", [pop(3.0)]),
        words("HOT, SOFT ROCK", (180, hot_px[1] - 4), 24, "ink", "yellow", [pop(6.0)])]
    near_pos, near_look = (0.5, -6.0, 22), (0, -7.0, 0)
    seam = project(near_pos, near_look, 50, (0, -1, 0.5))
    s[1]["actors"].append(arrow((40, seam[1] + 40), (seam[0] - 34, seam[1] + 40), 3.0, "white", 9))
    s[1]["actors"].append(arrow((320, seam[1] + 40), (seam[0] + 34, seam[1] + 40), 3.0, "white", 9))
    creep = (t[1] + 2.6, t[3] - (t[1] + 2.6))
    models = [
        model("mantle", "blocks", (0, 0, 0), fill=[box(-HALF, -11, Z0, HALF, -10, Z1, "HOT_LAVA")]),
        model("left", "blocks", (0, 0, 0), fill=plate(-HALF, -1), moves=[mv(creep[0], (0.5, 0, 0), creep[1])]),
        model("right", "blocks", (0, 0, 0), fill=plate(1, HALF), moves=[mv(creep[0], (-0.5, 0, 0), creep[1])]),
        model("range", "blocks", (0, 0, 0), fill=range_fill(), stretch=[1, 0.03, 1], moves=[
            {"do": "appear", "at": t[2] + 0.8},
            {"do": "grow", "at": t[2] + 0.8, "dur": 7.6, "to": 1.0, "axis": "y", "ease": "smooth"}]),
        model("me", "avatar", (0, PEAK, -2.0), look="explorer", turn=[0, 20, 0], moves=[{"do": "drop", "at": t[4] + 0.6,
            "height": 4}, {"do": "emote", "at": t[4] + 1.8, "emote": "cheer"}, {"do": "emote", "at": t[4] + 5.0,
            "emote": "wave"}]),
    ]
    effects = [{"kind": "dust", "at": [0, 0.3, -2], "from": t[2] + 0.8, "to": t[2] + 8.4, "size": 0.5, "amount": 60,
        "color": "#d9cdb4"}]
    camera = [
        cam(0, wide_pos, wide_look, 50),
        cam(t[1] - 0.05, (0.6, -6.0, 22.5), (0, -7.3, 0), 50),
        cam(t[1], near_pos, near_look, 50, cut=True),
        cam(t[2] - 0.05, (0.3, -6.0, 21), (0, -7.0, 0), 50),
        cam(t[2], (4, 2, 30), (0, 1.5, 0), 50, cut=True, shake=0.08),
        cam(t[3] - 0.05, (6, 3, 31), (0, 2.0, 0), 50, shake=0.0),
        cam(t[3], (-10, 6, 40), (0, 1.5, 0), 50, cut=True),
        cam(t[4] - 0.05, (-4, 6, 42), (0, 1.5, 0), 50, path="orbit"),
        cam(t[4], (5, 11.5, 13), (0, 10.0, -2), 50, cut=True),
        cam(t[4] + 10, (-6, 11.5, 12), (0, 10.0, -2), 50, path="orbit"),
    ]
    stage = {"sky": {"top": "#3a7be8", "horizon": "#d6eeff", "bottom": "#cfe4f2"}, "light": "day", "sun": [0.4, 0.8, 0.5],
        "models": models, "effects": effects, "camera": camera}
    return short("plates_mountains", "How mountains grow", "science", {"unit": "g6.science.plates"}, t[3] + 6, stage, s)
