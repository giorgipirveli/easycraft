"""How plants make food: a tree on a slab of soil cut open at the front to show its roots; drops of water (glowing blue)
go from the soil into the roots and up the trunk to the leaves; carbon dioxide (grey) comes in from the air; sunlight
sparkles on the leaves; sugar (glowing gold: food) goes down to the roots; oxygen (light blue) comes out of the leaves
for a child to breathe. Link: g5 Plants grow from air and water.
The review moved the roots up out of the caption's band, made every bit bigger and glowing, and aimed each shot at its
step (the first cut showed a wall of leaves and dots too small to see)."""
from reelkit import arrow, ball, box, cam, model, mv, out, pop, project, scene, short, sound, starts, words

TRUNK_TOP = 4
CANOPY = (0, 7, -1)
# A root's cells (x, y), in the cut face (z 0 and -1): from the trunk's foot down and out.
ROOTS = [(0, -1), (0, -2), (0, -3), (-1, -2), (-2, -3), (-3, -3), (-4, -4), (1, -2), (2, -3), (3, -3), (4, -4),
    (-1, -4), (1, -4)]


def garden():
    f = [box(-8, -6, -6, 8, -2, 0, "DIRT"), box(-8, -1, -6, 8, -1, 0, "GRASS"), box(-8, -6, -6, 8, -6, 0, "STONE")]
    for (x, y) in ROOTS:
        f.append(box(x, y, -1, x, y, 0, "LOG"))
    f.append(box(0, 0, 0, 0, TRUNK_TOP, 0, "LOG"))
    cx, cy, cz = CANOPY
    f += [ball(cx, cy, cz, 2.6, "LEAVES"), ball(cx - 2.0, cy - 0.6, cz, 1.7, "LEAVES"),
        ball(cx + 2.0, cy - 0.5, cz - 0.3, 1.8, "LEAVES"), ball(cx, cy + 1.6, cz - 0.3, 1.6, "LEAVES")]
    f += [box(-6, 0, -4, -6, 0, -4, "FLOWERS"), box(6, 0, -3, 6, 0, -3, "FLOWERS"), box(-4, 0, -1, -4, 0, -1, "FLOWERS")]
    return f


def bit(id_, block, start, path, step, size=0.5, leave=None):
    """A little cube (a drop of water, a bit of gas, some sugar) that appears at `start` and moves along `path`, a leg
    every `step` seconds."""
    moves = [pop(start)]
    for i, p in enumerate(path[1:]):
        moves.append(mv(start + 0.3 + i * step, p, step))
    if leave is not None:
        moves.append(out(leave))
    return model(id_, "blocks", path[0], cells=[[0, 0, 0, block]], size=size, moves=moves)


def make():
    s = [
        scene(9, "Plants don't eat food like we do. They make their own!",
            "Plants don't eat food the way we do. A plant makes its own food, using sunlight. Let's look inside!",
            [words("HOW PLANTS MAKE FOOD", (180, 84), 24, "white", "leaf", [pop(1.0)])], [sound(1.0, "pop")]),
        scene(10, "Roots drink water from the soil. Tiny tubes carry it up to the leaves.",
            "Roots drink water from the soil. Tiny tubes inside the stem carry it all the way up to the leaves.",
            [], [sound(0.8, "bubbles"), sound(5.0, "pop")]),
        scene(10, "Leaves take in carbon dioxide from the air, through tiny holes.",
            "The leaves take in a gas from the air, called carbon dioxide, through tiny holes underneath them.",
            [words("CARBON DIOXIDE", (180, 84), 28, "white", "grey", [pop(1.2)]),
                words("in through tiny holes", (180, 136), 20, "ink", "white", [pop(4.0)])],
            [sound(1.2, "pop"), sound(4.0, "whoosh")]),
        scene(11, "Green chlorophyll catches sunlight and makes sugar: the plant's food!",
            "Green chlorophyll in the leaves catches the sunlight. Its energy turns the water and carbon dioxide into "
            "sugar: food for the plant.",
            [words("SUNLIGHT", (250, 84), 28, "ink", "gold", [pop(0.8)]),
                words("SUGAR = FOOD", (120, 140), 28, "ink", "yellow", [pop(5.6)])],
            [sound(0.8, "sparkle"), sound(5.6, "ding")]),
        scene(10, "Oxygen comes out of the leaves for us to breathe. What will you grow?",
            "Oxygen comes out of the leaves for us to breathe. A big oak drinks over 100,000 litres of water a year! "
            "What will you grow?",
            [words("OXYGEN", (180, 84), 34, "ink", "sky", [pop(0.8)]),
                words("A BIG OAK: OVER 100,000 LITRES A YEAR", (180, 136), 16, "ink", "white", [pop(4.6)])],
            [sound(0.8, "pop"), sound(4.6, "pop")]),
    ]
    t = starts(s)
    roots_pos, roots_look = (1.5, -1.2, 14.5), (0, -3.0, -0.5)
    roots_px = project(roots_pos, roots_look, 50, (-2.0, -2.5, 0.5))
    trunk_px = project((1.5, 2.2, 15.5), (0, 1.6, -0.5), 50, (0.6, 1.0, 0.6))
    s[1]["actors"] = [words("ROOTS", (70, 160), 28, "white", "brown", [pop(1.0), out(4.6)]),
        arrow((70, 182), (roots_px[0], roots_px[1] - 6), 1.3, "white", 6, 0.25, leave=4.6),
        words("WATER GOES UP", (236, 110), 24, "white", "blue", [pop(6.0)]),
        arrow((236, 130), (trunk_px[0] + 10, trunk_px[1]), 6.3, "white", 6, -0.2)]
    # Water: from the soil into a root, along it to the trunk, up the trunk (in front of it) and into the leaves.
    drops = []
    for i, (sx, side) in enumerate([(-3.4, -1), (3.4, 1), (-2.2, -1), (2.2, 1)]):
        path = [(sx, -3.9, 0.7), (side * 1.5, -2.2, 0.75), (0.0, -0.8, 0.8), (0.0, 3.4, 0.8), (side * 1.0, 6.0, 0.8)]
        drops.append(bit("water%d" % i, "WATER_TANK", t[1] + 1.2 + i * 1.0, path, 1.4, leave=t[3] + 1.0))
    co2 = []
    for i, (fx, fy, fz) in enumerate([(-8.5, 8.0, 0.4), (-7.5, 6.0, 1.2), (-8.0, 9.6, -0.6)]):
        co2.append(bit("co2_%d" % i, "PAINTED_GREY", t[2] + 1.6 + i * 1.1, [(fx, fy, fz), (-2.6, fy - 0.4, fz * 0.5)],
            2.6, leave=t[3] + 3.0))
    sugar = [bit("sugar%d" % i, "GOLD_LAMP", t[3] + 5.4 + i * 1.3, [(0.0, 5.2, 0.8), (0.0, 0.2, 0.8),
        (i * 3.0 - 1.5, -2.4, 0.75)], 2.0, size=0.45) for i in range(2)]
    oxygen = []
    for i, (ox, oy) in enumerate([(1.5, 7.5), (2.4, 8.6), (2.0, 6.2)]):
        oxygen.append(bit("oxygen%d" % i, "PAINTED_SKY", t[4] + 0.6 + i * 0.8, [(ox, oy, 0.3), (ox + 1.6, oy - 1.0, 0.0),
            (4.3, 2.0, -1.2)], 2.0, size=0.45, leave=t[4] + 9.5))
    models = [model("garden", "blocks", (0, 0, 0), fill=garden()), model("sun", "sun", (14, 20, -22), size=2.4)]
    models += drops + co2 + sugar + oxygen
    models.append(model("me", "avatar", (4.5, 0, -1.4), look="explorer", turn=[0, 60, 0],
        moves=[{"do": "emote", "at": t[4] + 5.0, "emote": "stretch"}, {"do": "emote", "at": t[4] + 7.6, "emote": "wave"}]))
    effects = [{"kind": "sparkles", "at": [CANOPY[0], CANOPY[1] + 1.4, CANOPY[2] + 1.0], "from": t[3] + 0.6,
        "to": t[3] + 11, "size": 1.0, "area": [6, 3], "amount": 80, "color": "#fff4a0"}]
    camera = [
        cam(0, (6, 4, 28), (0, 0.4, -1), 50),
        cam(t[1] - 0.05, (4.5, 2.5, 22), (0, -0.2, -1), 50),
        cam(t[1], roots_pos, roots_look, 50, cut=True),
        cam(t[1] + 6.0, (1.5, 2.2, 15.5), (0, 1.6, -0.5), 50),
        cam(t[2] - 0.05, (1.6, 2.4, 15.6), (0, 1.7, -0.5), 50),
        cam(t[2], (-9.0, 7.0, 14.0), (-3.0, 7.0, -1), 50, cut=True),
        cam(t[3] - 0.05, (-8.0, 7.2, 13.5), (-2.6, 7.0, -1), 50),
        cam(t[3], (4.0, 6.0, 17.5), (0, 5.4, -0.5), 50, cut=True),
        cam(t[3] + 5.0, (3.5, 3.5, 17.5), (0, 2.2, -0.5), 50),
        cam(t[4] - 0.05, (3.0, 1.5, 16.5), (0, 0.2, -0.5), 50),
        cam(t[4], (9.5, 5.5, 13.5), (2.8, 3.6, -1), 50, cut=True),
        cam(t[4] + 10, (10.5, 4.5, 11.5), (3.4, 2.8, -1), 50, path="orbit"),
    ]
    stage = {"sky": {"top": "#3a7be8", "horizon": "#cdeeff", "bottom": "#8fb86a"}, "light": "day",
        "sun": [0.45, 0.8, 0.4], "models": models, "effects": effects, "camera": camera}
    return short("plants_food", "How plants make food", "nature", {"unit": "g5.science.plants_air_water"}, t[3] + 6,
        stage, s)
