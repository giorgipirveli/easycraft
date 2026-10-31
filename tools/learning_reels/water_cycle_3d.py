"""The water cycle in 3D: an island diorama (the sea on the left, a snowy mountain at the back, a river running from it
toward us and into the sea); the Sun warms the sea and vapour rises; it condenses into a cloud (the game's own cloud
blocks) that drifts over the mountain, turns grey and rains (snow on the top); the river carries the water back to the
sea. Link: g6 The water cycle (its four stages are the lesson's own)."""
from reelkit import ball, box, cam, cylinder, disc, model, mv, out, pop, scene, short, sound, starts, words

W = 10                      # the island's half width (x)
Z0, Z1 = -10, 6             # its depth (z)
SEA = -4                    # the sea from the island's left edge to x = SEA
MOUNTAIN = (5, 0, -5)       # the mountain's foot middle
# The river's course (x, z) from its spring at the mountain's foot to the beach; two cells wide.
COURSE = [(4, -1), (3, 0), (2, 1), (1, 2), (0, 3), (-1, 3), (-2, 3), (-3, 3)]
RIVER = sorted({c for (x, z) in COURSE for c in [(x, z), (x, z + 1), (x + 1, z)]})


def mountain_radius(k):
    return 0.6 + 5.2 * (1.0 - k / 9.0) ** 1.25


def island():
    f = [box(-W, -6, Z0, W, -4, Z1, "STONE"),
        box(SEA + 1, -3, Z0, W, -2, Z1, "DIRT"), box(SEA + 1, -1, Z0, W, -1, Z1, "GRASS"),
        box(-W, -4, Z0, SEA, -4, Z1, "SAND"), box(-W, -3, Z0, SEA, -2, Z1, "WATER"),
        box(SEA + 1, -2, Z0, SEA + 2, -2, Z1, "SAND"), box(SEA + 1, -1, Z0, SEA + 2, -1, Z1, "AIR")]
    mx, _, mz = MOUNTAIN
    for k in range(9):
        r = mountain_radius(k)
        f.append(disc(mx, k, mz, r, "GRASS" if k <= 2 else ("STONE" if k <= 5 else "SNOW")))
        if k <= 5:
            f.append(disc(mx, k, mz, max(r - 1.2, 0.5), "STONE"))
    for (x, z) in RIVER:
        f.append(box(x, -2, z, x, -1, z, "WATER"))
    for (tx, tz, h) in [(8, 3, 3), (-1, -6, 3), (1, -8, 2), (7, -9, 3)]:
        f.append(cylinder(tx, 0, tz, 0.3, h, "LOG"))
        f.append(ball(tx, h + 1, tz, 1.5, "LEAVES"))
    return f


def cloud(block):
    """A puffy cloud of blocks round its middle, about 8 m across."""
    return [ball(0, 0, 0, 2.3, block), ball(2.4, -0.3, 0.4, 1.8, block), ball(-2.3, -0.2, -0.3, 1.9, block),
        ball(0.6, 1.2, -0.2, 1.7, block), ball(-0.8, -0.4, 1.4, 1.5, block), box(-4, -3, -3, 4, -2, 3, "AIR")]


def make():
    s = [
        scene(10, "Earth's water goes round and round, from the sea to the sky and back.",
            "Earth's water goes round and round, from the sea to the sky and back. 97 drops in every 100 are in the sea.",
            [words("THE WATER CYCLE", (180, 84), 28, "white", "blue", [pop(1.0)])], [sound(1.0, "pop")]),
        scene(10, "The Sun warms the sea. Water evaporates into vapour, a gas.",
            "The Sun warms the sea. Some of the water evaporates: it turns into water vapour, an invisible gas, and "
            "rises up.",
            [words("1. EVAPORATION", (180, 84), 28, "ink", "yellow", [pop(0.8)]),
                words("vapour is invisible: we drew it", (180, 132), 16, "ink", "white", [pop(4.6)])],
            [sound(0.8, "pop"), sound(2.0, "bubbles")]),
        scene(10, "High up it is cold, so the vapour condenses into tiny drops: clouds!",
            "High up, the air is cold. The vapour cools and condenses into tiny drops of water. Billions of drops make "
            "a cloud.",
            [words("2. CONDENSATION", (180, 84), 28, "white", "teal", [pop(1.0)])], [sound(1.0, "pop"),
                sound(3.0, "wisp_chime")]),
        scene(10, "Drops join and get heavy. They fall as rain, or snow on the mountain.",
            "In the cloud, drops join and grow. When they are too heavy, they fall as rain, or as snow on the cold "
            "mountain top.",
            [words("3. PRECIPITATION", (180, 84), 28, "white", "purple", [pop(2.4)])],
            [sound(2.4, "pop"), sound(2.8, "splash")]),
        scene(10, "Rivers carry it back to the sea. Where will your raindrop go next?",
            "Rivers and streams carry the water back down to the sea, and round it goes again. Where will your raindrop "
            "go next?",
            [words("4. COLLECTION", (180, 84), 28, "white", "green", [pop(1.0)])], [sound(1.0, "pop"),
                sound(3.5, "splash"), sound(7.5, "chime")]),
    ]
    t = starts(s)
    cloud_at = (-7, 10.5, -2)
    rain_at = (4.5, 13, -5)
    flow = [(3.5, 0.2, -0.5), (2.0, 0.2, 1.2), (0.0, 0.2, 3.0), (-2.5, 0.2, 3.6), (-6.0, -0.8, 3.0)]
    drop_moves = [{"do": "appear", "at": t[4] + 0.8}]
    for i, p in enumerate(flow[1:]):
        drop_moves.append(mv(t[4] + 0.8 + i * 1.7, p, 1.7))
    models = [
        model("island", "blocks", (0, 0, 0), fill=island()),
        model("sun", "sun", (-18, 24, -34), size=2.6),
        model("cloud", "blocks", cloud_at, fill=cloud("CLOUD"),
            moves=[{"do": "grow", "at": 0, "dur": 0.4, "to": 0.15, "ease": "out"}, {"do": "appear", "at": t[2] + 0.6},
                {"do": "grow", "at": t[2] + 0.6, "dur": 6.0, "to": 1.0, "ease": "out"},
                mv(t[3] - 0.4, rain_at, 3.0), out(t[3] + 2.7)]),
        model("rain_cloud", "blocks", rain_at, fill=cloud("PAINTED_GREY"), moves=[pop(t[3] + 2.4)]),
        model("drop", "mark", flow[0], moves=drop_moves),
    ]
    effects = [
        # vapour off the whole sea (drawn: it is really invisible), small, rising slowly toward the cloud's height
        {"kind": "steam", "at": [-7, -1.2, -2], "from": t[1] + 0.6, "to": t[3], "size": 0.15, "color": "#eef8ff",
            "amount": 200, "speed": 3.0, "life": 6.5, "area": [6, 15]},
        {"kind": "rain", "at": [rain_at[0], rain_at[1] - 2.5, rain_at[2]], "from": t[3] + 2.6, "to": t[4] + 5,
            "size": 1.0, "amount": 320},
        {"kind": "snow", "at": [MOUNTAIN[0], 11, MOUNTAIN[2]], "from": t[3] + 2.8, "to": t[4] + 5, "size": 0.12,
            "amount": 70},
        {"kind": "sparkles", "on": "drop", "from": t[4] + 0.8, "to": t[4] + 8.0, "size": 1.0, "color": "#ffffff",
            "amount": 90},
    ]
    camera = [
        cam(0, (7, 13, 35), (0, 1.5, -2), 50),
        cam(t[1] - 0.05, (5, 11, 31), (0, 1.5, -2), 50),
        cam(t[1], (-3, 6.5, 13), (-7, 2.0, -2), 50, cut=True),
        cam(t[2] - 0.05, (-3, 7.5, 15), (-7, 4.0, -2), 50),
        cam(t[2], (-4, 6, 24), (-6.5, 6.5, -2), 50, cut=True),
        cam(t[3] - 0.4, (-3, 7, 25), (-6, 8, -2), 50),
        cam(t[3] + 2.4, (8, 8, 22), (4, 7.5, -4), 50),
        cam(t[4] - 0.05, (11, 8, 20), (4, 7, -4), 50, path="orbit"),
        cam(t[4], (7, 9.5, 15), (0.5, 0, 0.5), 50, cut=True),
        cam(t[4] + 6.4, (2, 8.5, 16), (-3, 0, 1.5), 50),
        cam(t[4] + 10, (6, 12, 34), (0, 1.5, -2), 50),
    ]
    stage = {"sky": {"top": "#3a7be8", "horizon": "#cdeeff", "bottom": "#2f78b8"}, "light": "day",
        "sun": [-0.35, 0.85, 0.45], "models": models, "effects": effects, "camera": camera}
    return short("water_cycle_3d", "The water cycle in 3D", "nature", {"unit": "g6.science.water_cycle"}, t[3] + 5,
        stage, s)
