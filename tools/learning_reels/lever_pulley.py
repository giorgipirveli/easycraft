"""Levers and pulleys lift: a plank on a pivot lifts a 60 kg barrel with a 20 kg push three times as far out; a pulley
turns a pull down into a lift up; a second pulley that moves with the load lets two ropes share it (half the pull) but
the rope must be pulled twice as far; cranes use many pulleys. Ropes are drawn between the wheels' rims, the loads and the
pullers' hands as they move. Link: g5 Gears and pulleys."""
import math

from reelkit import arrow, box, cam, count, cylinder, model, mv, out, pop, project, scene, short, sound, starts, words

LOAD_KG, PUSH_KG = 60, 20                      # the lever's load and push (kg)
LOAD_ARM, PUSH_ARM = 1.0, 3.0                  # their distances from the pivot (m)
FULCRUM = (-4, 0, 0)                           # the lever's pivot block (its top is the pivot, y 1)
REST = math.degrees(math.asin(1.0 / 4.5))      # the plank's tilt resting on its load end (4.5 m half-length, 1 m up)
WHEEL = (6, 5.4, 0)                            # the fixed pulley's middle; radius R
R = 0.6
HANDS = (0, 1.15, -0.5)                        # an avatar's hands, in its own frame (it faces -z)
PULLER_FROM = (7.4, 0, -1.6)   # behind the frame's right end; walks back (-z), facing the wheel (the review: walking
                               # sideways took the puller out of the tall frame)


def yard():
    f = [box(-9, -3, -10, 16, -2, 4, "DIRT"), box(-9, -1, -10, 16, -1, 4, "GRASS"),
        box(FULCRUM[0], 0, -1, FULCRUM[0], 0, 1, "STONE"),                      # the pivot
        box(3, 0, -1, 3, 6, -1, "LOG"), box(3, 6, -1, 7, 6, -1, "LOG"), box(3, 6, 0, 7, 6, 0, "LOG")]   # the frame
    return f


def puller_z(lift, ropes):
    """Where a puller stands (z) when the load has risen `lift` m with `ropes` ropes holding it: the rope from the fixed
    wheel's right rim to the hands grows by lift x ropes (a rope's length never changes). The puller faces +z (turned
    half round), so its hands are half a metre in front of it, toward the wheel."""
    rim = (WHEEL[0] + R, WHEEL[1], WHEEL[2])
    hands0 = (PULLER_FROM[0], HANDS[1], PULLER_FROM[2] - HANDS[2])
    dx, dy = rim[0] - hands0[0], rim[1] - hands0[1]
    l0 = math.sqrt(dx * dx + dy * dy + (hands0[2] - rim[2]) ** 2)
    l = l0 + lift * ropes
    return rim[2] - math.sqrt(l * l - dx * dx - dy * dy) + HANDS[2]


def wheel(id_, axle):
    return model(id_, "blocks", (0, 0, 0), on=axle, fill=[cylinder(0, 0, 0, 2.2, 1, "PLANKS")], size=0.25)


def crane():
    return [box(-8, -1, -5, 14, -1, 5, "PAD_CONCRETE"), box(0, 0, 0, 1, 12, 1, "PAINTED_YELLOW"),
        box(-4, 13, 0, 12, 13, 1, "PAINTED_YELLOW"), box(-4, 12, 0, -2, 12, 1, "STONE"), box(0, 14, 0, 1, 15, 1,
        "PAINTED_YELLOW"), box(2, 12, -1, 2, 12, -1, "GLASS"), box(4, 0, -3, 8, 2, -3, "BRICK"), box(4, 0, -3, 4, 2, 1,
        "BRICK"), box(8, 0, -3, 8, 1, 1, "BRICK")]


def make():
    s = [
        scene(10, "A lever turns on a pivot. A small push far away lifts a big load!",
            "A lever is a bar that turns on a pivot. Load near the pivot, push far away: a small push lifts a big load.",
            [], [sound(4.6, "whoosh"), sound(6.6, "ding")]),
        scene(10, "A pulley is a wheel with a rope. Pull down, and the load goes up!",
            "A pulley is a wheel with a rope over it. Pull down on one end, and the load on the other end goes up.",
            [], [sound(1.0, "pop"), sound(4.0, "whoosh")]),
        scene(10, "Add a pulley that moves with the load: two ropes share it. Half the pull!",
            "Now add a pulley that moves up with the load. Two ropes hold it and share the weight: you pull with half "
            "the force.",
            [], [sound(1.0, "pop"), sound(5.0, "whoosh")]),
        scene(10, "But you pull twice as much rope: 2 m of rope lifts it 1 m.",
            "But there is a catch: you must pull twice as much rope. Pull 2 metres of rope, and the load rises 1 metre.",
            [], [sound(2.6, "whoosh"), sound(7.2, "ding")]),
        scene(10, "Cranes use many pulleys to lift huge loads. Where have you seen a pulley?",
            "Building-site cranes use lots of pulleys, so their motors can lift huge loads. Where have you seen a pulley?",
            [words("CRANE: MANY PULLEYS", (180, 84), 24, "ink", "yellow", [pop(1.2)])], [sound(1.2, "pop"),
                sound(3.0, "whoosh")], "sky"),
    ]
    t = starts(s)
    fx, fy, fz = FULCRUM
    pivot = (fx, fy + 1, fz)
    push = (t[0] + 4.4, 2.2)
    lift2 = (t[1] + 3.6, 4.6)
    lift3 = (t[2] + 4.2, 4.0)
    lift4 = (t[3] + 2.6, 4.4)
    p2_end = puller_z(2.5, 1)
    p3_mid = puller_z(1.0, 2)
    p3_end = puller_z(2.0, 2)
    load_b = (WHEEL[0] - 2 * R, 0, 0)          # under the moving pulley (its right rim under the fixed wheel's left)
    models = [
        model("yard", "blocks", (0, 0, 0), fill=yard()),
        # The lever
        model("plank", "blocks", pivot, fill=[box(-4, 0, 0, 4, 0, 0, "PLANKS")], stretch=[1, 0.3, 1.3], turn=[0, 0, REST],
            moves=[{"do": "turn", "at": push[0], "dur": push[1], "to": [0, 0, -REST]}]),
        model("barrel", "blocks", (-LOAD_ARM, 0.3, 0), on="plank", cells=[[0, 0, 0, "BARREL"]], size=0.9),
        model("pusher", "avatar", (PUSH_ARM, 0, 0), look="explorer"),
        # One pulley: a barrel lifted by a pull down
        model("axle", "mark", WHEEL, turn=[90, 0, 0]),
        wheel("wheel", "axle"),
        model("load_a", "blocks", (WHEEL[0] - R, 0, 0), cells=[[0, 0, 0, "BARREL"]],
            moves=[mv(lift2[0], (WHEEL[0] - R, 2.5, 0), lift2[1]), out(t[2] - 0.2)]),
        model("puller_a", "avatar", PULLER_FROM, look="default", turn=[0, 180, 0],
            moves=[mv(lift2[0], (PULLER_FROM[0], 0, p2_end), lift2[1]), {"do": "legs", "at": lift2[0], "dur": lift2[1],
                "arms": "pull", "lean": 14, "steps": 1.4}, out(t[2] - 0.2)]),
        model("rope_a1", "rope", (0, 0, 0), **{"from": "axle", "to": "load_a"}, from_at=[-R, 0, 0], to_at=[0, 1, 0],
            width=0.06, block="HAY"),
        model("rope_a2", "rope", (0, 0, 0), **{"from": "axle", "to": "puller_a"}, from_at=[R, 0, 0], to_at=list(HANDS),
            width=0.06, block="HAY"),
        # Two pulleys: the second moves up with the load; two ropes hold it
        model("load_b", "blocks", load_b, cells=[[0, 0, 0, "BARREL"]], moves=[{"do": "appear", "at": t[2]},
            mv(lift3[0], (load_b[0], 1.0, 0), lift3[1]), mv(lift4[0], (load_b[0], 2.0, 0), lift4[1]), out(t[4] - 0.2)]),
        model("axle_m", "mark", (0, 1.9, 0), on="load_b", turn=[90, 0, 0]),
        wheel("wheel_m", "axle_m"),
        model("puller_b", "avatar", PULLER_FROM, look="default", turn=[0, 180, 0], moves=[{"do": "appear", "at": t[2]},
            mv(lift3[0], (PULLER_FROM[0], 0, p3_mid), lift3[1]), {"do": "legs", "at": lift3[0], "dur": lift3[1],
                "arms": "pull", "lean": 8, "steps": 1.4},
            mv(lift4[0], (PULLER_FROM[0], 0, p3_end), lift4[1]), {"do": "legs", "at": lift4[0], "dur": lift4[1],
                "arms": "pull", "lean": 8, "steps": 1.4}, out(t[4] - 0.2)]),
        model("rope_b0", "rope", (0, 0, 0), **{"from": "axle_m", "to": "load_b"}, from_at=[0, 0, R], to_at=[0, 1, 0],
            width=0.06, block="HAY"),
        model("rope_b1", "rope", (0, 0, 0), **{"from": "yard", "to": "axle_m"}, from_at=[load_b[0] - R, 6.0, 0],
            to_at=[-R, 0, 0], width=0.06, block="HAY"),
        model("rope_b2", "rope", (0, 0, 0), **{"from": "axle_m", "to": "axle"}, from_at=[R, 0, 0], to_at=[-R, 0, 0],
            width=0.06, block="HAY"),
        model("rope_b3", "rope", (0, 0, 0), **{"from": "axle", "to": "puller_b"}, from_at=[R, 0, 0], to_at=list(HANDS),
            width=0.06, block="HAY"),
        # The crane
        model("crane", "blocks", (40, 0, 0), fill=crane()),
        model("pallet", "blocks", (49, 0, 0.5), fill=[box(-1, 0, -1, 0, 0, 0, "PLANKS"), box(-1, 1, -1, 0, 2, 0, "BRICK")],
            moves=[mv(t[4] + 2.0, (49, 8, 0.5), 6.5)]),
        model("rope_c", "rope", (0, 0, 0), **{"from": "crane", "to": "pallet"}, from_at=[9.0, 13, 0.5], to_at=[-0.5, 3, -0.5],
            width=0.08, block="PAINTED_BLACK"),
    ]
    # The pusher hops onto the plank's far end (its weight is the push) and rides it down, kept upright: in the
    # plank's frame its turn about z undoes the plank's (a half turn about y, then the plank's tilt the other way).
    end_rest = (fx + PUSH_ARM * math.cos(math.radians(REST)), 1 + PUSH_ARM * math.sin(math.radians(REST)) + 0.3, 0)
    models[3]["at"] = [PUSH_ARM, 0.3, 0]
    models[3]["on"] = "plank"
    models[3]["turn"] = [0, 180, REST]
    models[3]["moves"] = [{"do": "drop", "at": push[0] - 1.3, "dur": 0.9, "height": 3},
        {"do": "turn", "at": push[0], "dur": push[1], "to": [0, 180, -REST]},
        {"do": "emote", "at": t[1] - 3.0, "emote": "cheer"}]
    # Wheels turn as their ropes run: the fixed wheel by the rope's run over it, the moving one by half (it climbs).
    models[5]["moves"] = [{"do": "spin", "at": lift2[0], "dur": lift2[1], "turns": -2.5 / (2 * math.pi * R), "ease": "smooth"},
        {"do": "spin", "at": lift3[0], "dur": lift3[1], "turns": -2.0 / (2 * math.pi * R), "ease": "smooth"},
        {"do": "spin", "at": lift4[0], "dur": lift4[1], "turns": -2.0 / (2 * math.pi * R), "ease": "smooth"}]
    models[12]["moves"] = [{"do": "spin", "at": lift3[0], "dur": lift3[1], "turns": 1.0 / (2 * math.pi * R), "ease": "smooth"},
        {"do": "spin", "at": lift4[0], "dur": lift4[1], "turns": 1.0 / (2 * math.pi * R), "ease": "smooth"}]
    # Stickers on the lever (the shot's start), the pulleys, the counts.
    lever_pos, lever_look = (-2.6, 3.2, 17.5), (-3.6, 1.7, 0)
    barrel_px = project(lever_pos, lever_look, 50, (fx - LOAD_ARM, 1.6, 0))
    push_px = project(lever_pos, lever_look, 50, (end_rest[0], end_rest[1] + 1.0, 0))
    pivot_px = project(lever_pos, lever_look, 50, (fx, 0.5, 0.5))
    s[0]["actors"] = [
        words("LOAD %d kg" % LOAD_KG, (barrel_px[0], barrel_px[1] - 70), 24, "white", "red", [pop(1.0)]),
        arrow((barrel_px[0], barrel_px[1] - 52), (barrel_px[0], barrel_px[1] - 8), 1.3, "white", 5),
        words("PUSH %d kg" % PUSH_KG, (push_px[0] + 10, push_px[1] - 64), 24, "ink", "yellow", [pop(2.4)]),
        words("PIVOT", (pivot_px[0], pivot_px[1] + 46), 20, "white", "ink", [pop(3.4)]),
        words("%d × %d = %d × %d" % (LOAD_KG, LOAD_ARM, PUSH_KG, PUSH_ARM), (180, 84), 28, "ink", "white", [pop(7.0)]),
    ]
    pul_pos, pul_look = (6.6, 3.2, 17.0), (6.6, 2.7, 0)
    load_px = project(pul_pos, pul_look, 50, (WHEEL[0] - R, 1.4, 0))
    s[1]["actors"] = [
        words("LOAD GOES UP", (96, 84), 24, "white", "green", [pop(4.4)]),
        words("PULL DOWN", (272, 136), 24, "ink", "yellow", [pop(3.8)]),
    ]
    s[2]["actors"] = [
        words("2 ROPES HOLD IT", (180, 84), 28, "white", "teal", [pop(2.4)]),
        words("LOAD %d kg" % LOAD_KG, (96, 136), 20, "white", "red", [pop(4.0)]),
        words("PULL %d kg" % (LOAD_KG // 2), (270, 184), 20, "ink", "yellow", [pop(6.2)]),
    ]
    s[3]["actors"] = [
        count(0, 2, 0, (110, 100), 28, "ink", "yellow", suffix=" m PULLED", start=2.4, dur=4.4, decimals=1),
        count(0, 1, 0, (250, 150), 28, "white", "green", suffix=" m UP", start=2.4, dur=4.4, decimals=1),
    ]
    camera = [
        cam(0, lever_pos, lever_look, 50),
        cam(t[1] - 0.05, (-2.2, 3.0, 16.6), (-3.6, 1.7, 0), 50),
        cam(t[1], pul_pos, pul_look, 50, cut=True),
        cam(t[2] - 0.05, (7.0, 3.2, 17.0), (7.0, 2.7, 0), 50),
        cam(t[2], pul_pos, pul_look, 50, cut=True),
        cam(t[3] - 0.05, (6.9, 3.2, 17.2), (6.9, 2.7, 0), 50),
        cam(t[3] + 2.0, (7.0, 3.2, 17.4), (7.0, 2.7, 0), 50),
        cam(t[4] - 0.05, (7.3, 3.2, 17.6), (7.3, 2.7, 0), 50),
        cam(t[4], (58, 5, 26), (44, 7.5, 0), 50, cut=True),
        cam(t[4] + 10, (54, 4, 30), (44, 8, 0), 50, path="orbit"),
    ]
    stage = {"sky": {"top": "#3a7be8", "horizon": "#cdeeff", "bottom": "#8fb86a"}, "light": "day", "sun": [0.4, 0.8, 0.55],
        "models": models, "camera": camera}
    return short("lever_pulley", "Levers and pulleys lift", "science", {"unit": "g5.design_tech.gears_pulleys"}, t[2] + 6,
        stage, s)
