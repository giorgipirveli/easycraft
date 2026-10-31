"""Why things float or sink: a glass tank of water; a wooden block floats half under; a stone the same size sinks; water
pushes up (Archimedes: as hard as the water pushed aside weighs), so what is lighter than the same amount of water
floats; ice floats with about nine tenths under; a lump of iron sinks, but the same iron as a thin hollow boat floats.
Every float depth is worked out from the densities below (the test does it again). Link: g5 Properties of materials."""
from reelkit import arrow, box, cam, model, mv, out, pop, project, scene, short, sound, starts, words

WATER_TOP = 0.0
FLOOR = -3.0                # the tank's floor (the water is 3 m deep in the model)
DENSITY = {"water": 1000.0, "wood": 500.0, "ice": 917.0, "stone": 2700.0, "iron": 7870.0}   # kg per m3 (sources: notes)
BOAT = (3.0, 2.0, 1.2, 0.03)    # the iron boat: length (x), width (z), wall height, plate thickness (m)
X = {"wood": -6.0, "stone": -3.0, "ice": 0.0, "lump": 3.0, "boat": 6.0}


def float_bottom(density, height=1.0):
    """Where a floating block's bottom rests: it sinks until the water it pushes aside weighs as much as it does."""
    return WATER_TOP - height * density / DENSITY["water"]


def boat_iron():
    l, w, h, th = BOAT
    return l * w * th + 2 * (l * h * th) + 2 * (w * h * th)


def boat_draft():
    l, w, _, _ = BOAT
    return boat_iron() * DENSITY["iron"] / DENSITY["water"] / (l * w)


def tank():
    """A long tank cut open at the front (the review: glass panes drew a grid over everything): white walls behind and
    at the ends so what floats and sinks stands out, a sandy floor, water 3 m deep."""
    return [box(-10, -6, -4, 10, -6, 3, "PLANKS"),                        # the table
        box(-9, -5, -3, 9, -4, 1, "SAND"),                                # the tank's floor
        box(-9, -5, -3, 9, 1, -3, "PAINTED_WHITE"),                       # the back wall
        box(-9, -5, -3, -9, 1, 1, "PAINTED_WHITE"), box(9, -5, -3, 9, 1, 1, "PAINTED_WHITE"),   # the ends
        box(-8, -3, -2, 8, -1, 1, "WATER")]


def splash(x, at, size=0.22):
    return {"kind": "billow", "at": [x, WATER_TOP + 0.05, -0.5], "from": at, "to": at + 0.35, "size": size, "speed": 1.2,
        "amount": 40, "color": "#cfeaff"}


def make():
    s = [
        scene(10, "Drop a wooden block into water. It floats, about half under the water.",
            "Drop a wooden block into water. It bobs up and floats, with about half of it under the water.",
            [words("WOOD: FLOATS", (180, 84), 28, "ink", "yellow", [pop(4.4)])], [sound(2.6, "splash"), sound(4.4, "pop")],
            "lab"),
        scene(10, "A stone the same size sinks to the bottom! Why?",
            "Now drop a stone the same size. Down it goes, all the way to the bottom! Why does one float and one sink?",
            [words("STONE: SINKS", (180, 84), 28, "white", "grey", [pop(4.8)])], [sound(2.1, "splash"),
                sound(3.0, "bubbles"), sound(4.8, "thud")], "lab"),
        scene(10, "Water pushes up. Things lighter than the water they push aside float!",
            "Water pushes up on everything in it. If something is lighter than the same amount of water, the push wins and "
            "it floats.",
            [], [sound(1.0, "pop"), sound(3.0, "pop"), sound(6.0, "ding")], "lab"),
        scene(10, "Ice is a little lighter than water, so 9/10 of an iceberg hides under it!",
            "Ice is only a little lighter than water. It floats very low: nine tenths of an iceberg hides under the sea!",
            [words("9/10 UNDER WATER", (180, 84), 28, "white", "blue", [pop(4.0)])], [sound(1.6, "splash"),
                sound(4.0, "ice_crackle")], "lab"),
        scene(10, "Iron sinks, but thin iron shaped into a boat floats! What else will float?",
            "A lump of iron sinks. But the same iron as a thin, hollow boat pushes aside lots of water, and floats! What "
            "else will float?",
            [words("IRON LUMP: SINKS", (110, 84), 20, "white", "grey", [pop(3.2)]),
                words("IRON BOAT: FLOATS", (236, 136), 20, "ink", "yellow", [pop(7.2)])],
            [sound(1.6, "splash"), sound(3.2, "thud"), sound(6.4, "splash")], "lab"),
    ]
    t = starts(s)
    wood_y = float_bottom(DENSITY["wood"])
    ice_y = float_bottom(DENSITY["ice"])
    lump = boat_iron() ** (1.0 / 3.0)          # the same iron as the boat, in one lump
    draft = boat_draft()
    l, w, h, th = BOAT
    models = [
        model("tank", "blocks", (0, 0, 0), fill=tank()),
        model("wood", "blocks", (X["wood"], 5, -0.5), cells=[[0, 0, 0, "PLANKS"]], moves=[{"do": "appear", "at": 2.0},
            mv(2.0, (X["wood"], wood_y - 0.55, -0.5), 0.7, "in"), mv(2.7, (X["wood"], wood_y, -0.5), 1.4, "back")]),
        model("stone", "blocks", (X["stone"], 5, -0.5), cells=[[0, 0, 0, "STONE"]], moves=[{"do": "appear", "at": t[1] + 1.4},
            mv(t[1] + 1.4, (X["stone"], -0.4, -0.5), 0.7, "in"), mv(t[1] + 2.1, (X["stone"], FLOOR, -0.5), 2.6, "out")]),
        model("ice", "blocks", (X["ice"], 5, -0.5), cells=[[0, 0, 0, "ICE"]], moves=[{"do": "appear", "at": t[3] + 0.9},
            mv(t[3] + 0.9, (X["ice"], ice_y - 0.4, -0.5), 0.7, "in"), mv(t[3] + 1.6, (X["ice"], ice_y, -0.5), 1.4, "back")]),
        model("lump", "blocks", (X["lump"], 5, -0.5), cells=[[0, 0, 0, "PAINTED_GREY"]], size=lump,
            moves=[{"do": "appear", "at": t[4] + 0.9}, mv(t[4] + 0.9, (X["lump"], -0.4, -0.5), 0.7, "in"),
                mv(t[4] + 1.6, (X["lump"], FLOOR, -0.5), 2.2, "out")]),
        model("boat", "mark", (X["boat"], 4, -0.5), moves=[mv(t[4] + 4.0, (X["boat"], -draft, -0.5), 2.6, "out")]),
    ]
    for (id_, at, stretch) in [("floor", (0, 0, 0), [l, th, w]), ("side_a", (0, 0, w / 2 - th / 2), [l, h, th]),
            ("side_b", (0, 0, -w / 2 + th / 2), [l, h, th]), ("end_a", (l / 2 - th / 2, 0, 0), [th, h, w]),
            ("end_b", (-l / 2 + th / 2, 0, 0), [th, h, w])]:
        models.append(model(id_, "blocks", at, on="boat", cells=[[0, 0, 0, "PAINTED_GREY"]], stretch=stretch,
            moves=[{"do": "appear", "at": t[4] + 4.0}]))
    effects = [splash(X["wood"], 2.6), splash(X["stone"], t[1] + 2.0),
        {"kind": "steam", "at": [X["stone"], -2.0, -0.5], "from": t[1] + 2.2, "to": t[1] + 4.6, "size": 0.12,
            "amount": 24, "color": "#ffffff"},
        splash(X["ice"], t[3] + 1.5), splash(X["lump"], t[4] + 1.5), splash(X["boat"], t[4] + 6.2, 0.3)]
    # Scene 3: the push and the weight on the wood, and on the stone.
    mid_pos, mid_look = (-4.5, 0.2, 11.0), (-4.5, -1.5, -0.5)
    wood_top = project(mid_pos, mid_look, 50, (X["wood"], wood_y + 1.0, 1.0))
    wood_bot = project(mid_pos, mid_look, 50, (X["wood"], wood_y, 1.0))
    stone_top = project(mid_pos, mid_look, 50, (X["stone"], FLOOR + 1.0, 1.0))
    s[2]["actors"] = [
        words("WEIGHT", (wood_top[0] + 64, wood_top[1] - 48), 20, "white", "red", [pop(1.0), out(5.0)]),
        arrow((wood_top[0], wood_top[1] - 74), (wood_top[0], wood_top[1] - 8), 1.2, "red", 8),
        words("WATER PUSHES UP", (wood_bot[0] + 90, wood_bot[1] + 60), 20, "ink", "lime", [pop(3.0), out(5.0)]),
        arrow((wood_bot[0], wood_bot[1] + 76), (wood_bot[0], wood_bot[1] + 10), 3.2, "lime", 8),
        words("WOOD: LIGHTER THAN WATER", (180, 84), 20, "ink", "yellow", [pop(5.2)]),
        words("STONE: HEAVIER THAN WATER", (180, 136), 20, "white", "grey", [pop(6.6)]),
    ]
    camera = [
        cam(0, (-6.0, 0.7, 7.0), (-6.0, -0.4, -0.5), 45),
        cam(t[1] - 0.05, (-5.6, 0.5, 6.6), (-6.0, -0.5, -0.5), 45),
        cam(t[1], (-3.0, 0.6, 10.0), (-3.0, -0.9, -0.5), 50, cut=True),
        cam(t[1] + 3.0, (-3.0, 0.4, 10.0), (-3.0, -1.0, -0.5), 50),
        cam(t[2] - 0.05, (-3.0, 0.0, 10.0), (-3.0, -1.8, -0.5), 50),
        cam(t[2], mid_pos, mid_look, 50, cut=True),
        cam(t[3] - 0.05, (-4.2, 0.0, 10.6), (-4.5, -1.5, -0.5), 50),
        cam(t[3], (0.0, 0.7, 7.0), (0.0, -0.5, -0.5), 45, cut=True),
        cam(t[4] - 0.05, (0.4, 0.5, 6.6), (0.0, -0.6, -0.5), 45),
        cam(t[4], (4.5, 0.4, 11.0), (4.5, -1.5, -0.5), 50, cut=True),
        cam(t[4] + 10, (4.9, 0.2, 10.4), (4.6, -1.4, -0.5), 50),
    ]
    stage = {"sky": {"top": "#cfdcea", "horizon": "#eef3f8", "bottom": "#b8c4d2"}, "light": "studio",
        "sun": [0.35, 0.8, 0.5], "models": models, "effects": effects, "camera": camera}
    return short("float_or_sink", "Why things float or sink", "science", {"unit": "g5.science.properties"}, t[4] + 8,
        stage, s)
