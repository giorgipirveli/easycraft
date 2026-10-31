"""How the pyramids were built: the Great Pyramid's first courses by the Nile; a team drags a stone on a wooden sledge
while a worker wets the sand in front (it slides more easily); course after course rises with a ramp; smooth white
casing stone covers the steps; at sunset it stands. The numbers are WonderFacts' (the game's Wonders tour). Link: g4
Ancient Egypt."""
from reelkit import box, cam, count, cylinder, disc, model, mv, out, pop, scene, short, sound, starts, words

HALF = 9            # the base course's half width (cells): courses k = 0..9, each one smaller on every side
COURSES = HALF + 1
SLEDGE_FROM, SLEDGE_TO = (15, 0, 30), (4.5, 0, 30)


def course(k):
    w = HALF - k
    return [box(-w, k, -w, w, k, w, "LIMESTONE")]


def ramp():
    """A mudbrick ramp up the pyramid's south (+z) face, one layer per course, its top sloping 1 in 2; stretched up and
    down as the pyramid rises (its top hides inside the pyramid)."""
    f = []
    for k in range(COURSES):
        f.append(box(-1, k, 10 - k, 1, k, 10 + 2 * (HALF - k), "SANDSTONE"))
    return f


def casing():
    """The casing: smooth white stone over the steps, in half-metre cells (size 0.5) so its faces are nearly smooth;
    a shell two cells thick whose sides run through the steps' outer corners."""
    f = []
    layers = 21
    for j in range(layers):
        top = (j + 1) * 0.5                  # this layer's top (m)
        hw = int((10.5 - top) / 0.5 + 0.5)   # its half width in cells
        if hw < 0:
            break
        f.append(box(-hw, j, -hw, hw, j, hw, "CASING_STONE"))
        if hw > 2:
            f.append(box(-(hw - 2), j, -(hw - 2), hw - 2, j, hw - 2, "AIR"))
    return f


def nile():
    f = [box(-40, 0, -30, 40, 0, -27, "WATER"), box(-40, 0, -32, 40, 0, -31, "GRASS"), box(-40, 0, -26, 40, 0, -24,
        "GRASS")]
    for x in range(-36, 40, 7):
        f.append(cylinder(x, 1, -24 - (x % 2), 0.3, 3, "PALM_LOG"))
        f.append(disc(x, 4, -24 - (x % 2), 1.6, "PALM_LEAVES"))
    return f


def make():
    s = [
        scene(10, "About 4,500 years ago, Egyptians built the Great Pyramid for their king.",
            "About 4,500 years ago, the people of Egypt began the Great Pyramid, a tomb for their king, Khufu.",
            [words("4,500 YEARS AGO", (180, 84), 28, "white", "brown", [pop(1.4)])], [sound(1.4, "pop")]),
        scene(10, "Teams dragged each stone on a wooden sledge. Wet sand helped it slide!",
            "Teams of workers dragged each heavy stone on a wooden sledge. Pouring water on the sand in front made it "
            "slide much more easily.",
            [words("WET SAND: EASIER!", (180, 84), 28, "white", "blue", [pop(5.6)])], [sound(1.0, "thud"),
                sound(5.4, "splash")]),
        scene(10, "Layer by layer it rose: about 2.3 million blocks, dragged up ramps.",
            "Layer by layer, the pyramid rose. About 2.3 million stone blocks were dragged up ramps and set in place.",
            [count(0, 2300000, 1.0, (180, 84), 28, "ink", "yellow", suffix=" BLOCKS", start=1.0, dur=7.0)],
            [sound(0.6, "thud"), sound(2.7, "thud"), sound(4.8, "thud"), sound(6.9, "thud")]),
        scene(10, "Smooth white stone covered the steps, so it shone in the sunshine.",
            "At the end, smooth white stone covered the steps, so the pyramid shone in the sunshine. It was about 146 "
            "metres tall!",
            [words("146 m TALL", (180, 84), 34, "ink", "yellow", [pop(6.6)]),
                words("(the model is smaller)", (180, 132), 20, "ink", "white", [pop(7.4)])],
            [sound(1.2, "sparkle"), sound(6.6, "pop")]),
        scene(10, "For 3,800 years nothing people built was taller! What would you build?",
            "For about 3,800 years, nothing people built was taller. It still stands today! What would you build to "
            "last that long?",
            [words("TALLEST FOR 3,800 YEARS", (180, 84), 24, "white", "brown", [pop(1.0)])],
            [sound(1.0, "pop"), sound(5.0, "fanfare")]),
    ]
    t = starts(s)
    models = [model("ground", "ground", (0, 0, 0), look="sand", size=150), model("nile", "blocks", (0, 0, 0), fill=nile())]
    models.append(model("base", "blocks", (0, 0, 0), fill=course(0) + course(1)))   # the first two courses
    for k in range(2, COURSES):
        models.append(model("course%d" % k, "blocks", (0, 0, 0), fill=course(k),
            moves=[{"do": "drop", "at": t[2] + 0.6 + (k - 2) * 1.05, "height": 6}]))
    models.append(model("ramp", "blocks", (0, 0, 0), fill=ramp(), stretch=[1, 0.2, 1],
        moves=[{"do": "grow", "at": t[2] + 0.4, "dur": 8.4, "to": 1.0, "axis": "y", "ease": "smooth"},
            mv(t[3] + 0.3, (0, -11, 0), 1.6, "in"), out(t[3] + 1.9)]))
    models.append(model("casing", "blocks", (0, 0, 0), fill=casing(), size=0.5,
        moves=[{"do": "grow", "at": 0, "dur": 0.4, "to": 0.9, "ease": "out"}, {"do": "appear", "at": t[3] + 1.0},
            {"do": "grow", "at": t[3] + 1.0, "dur": 2.6, "to": 1.0, "ease": "out"}]))
    # The sledge, its stone, the haulers walking backwards with the rope, a worker wetting the sand ahead.
    sx, sy, sz = SLEDGE_FROM
    tx, _, _ = SLEDGE_TO
    drag = (t[1] + 0.6, 8.6)
    models += [
        model("sledge", "blocks", SLEDGE_FROM, cells=[[-1, 0, 0, "PLANKS"], [0, 0, 0, "PLANKS"]], stretch=[1, 0.35, 1],
            moves=[mv(drag[0], SLEDGE_TO, drag[1])]),
        model("stone", "blocks", (-0.5, 0.35, 0), on="sledge", cells=[[0, 0, 0, "LIMESTONE"]], size=0.95),
        model("hauler1", "avatar", (sx - 4.0, 0, sz - 0.5), look="default", turn=[0, -90, 0],
            moves=[mv(drag[0], (tx - 4.0, 0, sz - 0.5), drag[1]), {"do": "legs", "at": drag[0], "dur": drag[1],
                "arms": "pull", "lean": 16, "steps": 1.6}]),
        model("hauler2", "avatar", (sx - 6.0, 0, sz + 0.5), look="explorer", turn=[0, -90, 0],
            moves=[mv(drag[0], (tx - 6.0, 0, sz + 0.5), drag[1]), {"do": "legs", "at": drag[0], "dur": drag[1],
                "arms": "pull", "lean": 16, "steps": 1.6}]),
        model("waterer", "avatar", (sx - 2.0, 0, sz + 1.6), look="explorer", turn=[0, -90, 0],
            moves=[mv(drag[0], (tx - 2.0, 0, sz + 1.6), drag[1]), {"do": "legs", "at": drag[0], "dur": drag[1],
                "arms": "push", "steps": 1.6}]),
        model("hands1", "mark", (0, 1.15, -0.5), on="hauler1"),
        model("hands2", "mark", (0, 1.15, -0.5), on="hauler2"),
        model("front", "mark", (-1.6, 0.2, 0), on="sledge"),
        model("rope1", "rope", (0, 0, 0), **{"from": "front", "to": "hands1"}, width=0.07, block="HAY"),
        model("rope2", "rope", (0, 0, 0), **{"from": "hands1", "to": "hands2"}, width=0.07, block="HAY"),
        model("me", "avatar", (3, 1, 9.6), look="explorer", turn=[0, 10, 0], moves=[{"do": "emote", "at": t[4] + 1.0,
            "emote": "wave"}, {"do": "emote", "at": t[4] + 5.2, "emote": "cheer"}]),
    ]
    effects = [
        {"kind": "billow", "on": "front", "at": [-0.3, -0.15, 0.4], "from": drag[0] + 0.4, "to": drag[0] + drag[1], "size": 0.12, "speed": 0.5,
            "amount": 40, "color": "#7cc8ff"},
        {"kind": "dust", "at": [0, 1.5, 0], "from": t[2] + 0.6, "to": t[2] + 9.0, "size": 0.35, "amount": 40,
            "color": "#e8d4a8"},
        {"kind": "sparkles", "at": [0, 5, 6], "from": t[3] + 1.0, "to": t[3] + 5.0, "size": 2.6, "amount": 60},
    ]
    camera = [
        cam(0, (26, 18, 44), (0, 1.5, 0), 45),
        cam(t[1] - 0.05, (20, 14, 38), (0, 2.0, 0), 45),
        cam(t[1], (3, 3.2, 9), (-1.5, 1.0, 0), 50, cut=True, follow="sledge"),
        cam(t[2] - 0.05, (2, 3.4, 10), (-1.5, 1.0, 0), 50, follow="sledge"),
        cam(t[2], (32, 15, 44), (0, 5, 3), 45, cut=True),
        cam(t[3] - 0.05, (14, 15, 50), (0, 5.5, 3), 45, path="orbit"),
        cam(t[3], (-24, 9, 32), (0, 5.5, 0), 45, cut=True),
        cam(t[4] - 0.05, (-14, 8, 38), (0, 5.5, 0), 45, path="orbit"),
        cam(t[4], (8, 4.5, 44), (0, 4.5, 0), 45, cut=True),
        cam(t[4] + 10, (11, 4.0, 42), (0, 4.5, 0), 45),
    ]
    stage = {"sky": [{"at": 0, "sky": {"top": "#3a7be8", "horizon": "#f6e7c4", "bottom": "#e2c58f"}},
            {"at": t[4], "dur": 7, "sky": "dusk"}],
        "light": [{"at": 0, "light": "day"}, {"at": t[4], "dur": 7, "light": "dusk"}],
        "sun": [{"at": 0, "sun": [0.5, 0.75, 0.6]}, {"at": t[4], "dur": 7, "sun": [-0.75, 0.25, 0.6]}],
        "models": models, "effects": effects, "camera": camera}
    return short("pyramid_build", "How the pyramids were built", "history", {"unit": "g4.history.ancient_egypt"},
        t[3] + 6, stage, s)
