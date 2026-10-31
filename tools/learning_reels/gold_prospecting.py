"""How gold is found (the game's prospecting, DepositKinds.GOLD and the pan_gold recipe): an old hill with a white
quartz vein glinting in its cliff; rain and the river wash flakes downstream; heavy flakes sink into the gravel at a
bend while sand is carried on; a prospector pans the gravel (sand washes out, the heavy bits stay); then follows the
river upstream to the vein. Link: g7 Earth's resources."""
from reelkit import arrow, ball, box, cam, cone, cylinder, model, mv, out, pop, project, scene, short, sound, starts, words

HILL = (-4, 0, -7)          # the hill's foot middle; its front is cut into a cliff at z = CLIFF
HILL_R, HILL_H = 8.5, 9
CLIFF = -3
EDGE = 0.35
COURSE = [(-2, -2), (-1, -1), (0, 0), (1, 0), (2, 1), (3, 1), (4, 2), (5, 3), (6, 4), (7, 4), (8, 5), (9, 6), (10, 6)]
RIVER = sorted({c for (x, z) in COURSE for c in [(x, z), (x, z + 1)]})
BEND = (4, 0, 1)            # where the gravel bar is (the river's inner side)
GRAVEL = [(3, 2), (3, 3), (4, 3), (2, 2), (5, 1), (4, 1)]


def hill_radius(k):
    return HILL_R * (1.0 - k / HILL_H) ** 0.9


def in_hill(x, y, z):
    hx, _, hz = HILL
    return y < HILL_H and (x - hx) ** 2 + (z - hz) ** 2 <= (hill_radius(y) + EDGE) ** 2 and z <= CLIFF


def land():
    f = [box(-12, -4, -12, 12, -4, 7, "STONE"), box(-12, -3, -12, 12, -2, 7, "DIRT"), box(-12, -1, -12, 12, -1, 7, "GRASS")]
    hx, _, hz = HILL
    for k in range(HILL_H):
        f.append({"disc": [hx, k, hz, hill_radius(k)], "block": "GRASS" if k <= 1 else "STONE"})
        if k <= 1:
            f.append({"disc": [hx, k, hz, max(hill_radius(k) - 1.2, 0.5)], "block": "STONE"})
    f.append(box(-12, 0, CLIFF + 1, 12, HILL_H, 7, "AIR"))          # the cliff: the hill's front cut away
    for (x, z) in RIVER:
        if 2 <= x <= 5:   # at the bend the river slows: its bed is gravel, the water shallow over it
            f += [box(x, -2, z, x, -2, z, "GOLD_GRAVEL"), box(x, -1, z, x, -1, z, "WATER")]
        else:
            f.append(box(x, -2, z, x, -1, z, "WATER"))
    for (x, z) in GRAVEL:
        if (x, z) not in RIVER:
            f.append(box(x, -1, z, x, -1, z, "GOLD_GRAVEL"))
    for (tx, tz) in [(8, -3), (10, 1), (-9, 3)]:
        f += [cylinder(tx, 0, tz, 0.3, 3, "LOG"), ball(tx, 4, tz, 1.6, "LEAVES")]
    return f


def vein():
    """The white quartz vein: a slanting stripe two cells thick through the hill, seen in the cliff."""
    cells = []
    for y in range(0, HILL_H - 1):
        xc = -5 + int(round(y * 0.7))
        for x in (xc, xc + 1):
            for z in range(CLIFF - 3, CLIFF + 1):
                if in_hill(x, y, z):
                    cells.append([x, y, z, "GOLD_QUARTZ"])
    return cells


def bit(id_, block, start, path, step, size=0.22, leave=None):
    moves = [pop(start)]
    for i, p in enumerate(path[1:]):
        moves.append(mv(start + 0.3 + i * step, p, step))
    if leave is not None:
        moves.append(out(leave))
    return model(id_, "blocks", path[0], cells=[[0, 0, 0, block]], size=size, moves=moves)


def make():
    s = [
        scene(10, "Gold forms in white quartz veins, deep inside old hills.",
            "Gold forms in veins of white quartz rock, deep inside old hills. Can you see the sparkly stripe?",
            [], [sound(1.2, "pop"), sound(4.0, "sparkle")]),
        scene(10, "Rain and rivers wear the rock away and wash tiny flakes downstream.",
            "Over thousands of years, rain and rivers wear the rock away, and wash tiny flakes of gold down the stream.",
            [words("WASHED DOWNSTREAM", (180, 84), 28, "white", "blue", [pop(3.0)])], [sound(0.8, "rock_crash"),
                sound(3.0, "splash")]),
        scene(10, "Gold is very heavy, so the flakes sink and hide in the river's gravel.",
            "Gold is very heavy: 19 times heavier than the same amount of water. So the flakes sink and hide in the "
            "gravel.",
            [words("19 × HEAVIER THAN WATER", (180, 84), 20, "ink", "yellow", [pop(1.6)])], [sound(1.6, "pop"),
                sound(4.4, "bubbles")]),
        scene(10, "Prospectors swirl gravel in a pan. Light sand washes out; gold stays!",
            "Prospectors swirl the gravel in a pan of water. The light sand washes out, and the heavy gold stays at the "
            "bottom.",
            [words("PANNING", (180, 84), 34, "white", "teal", [pop(1.0)])], [sound(1.2, "splash"), sound(4.0, "splash"),
                sound(7.6, "sparkle")]),
        scene(10, "Follow the flakes upstream to find the vein. Where would you dig?",
            "Find flakes? Follow the river upstream, testing as you go, until you find the vein in the hill. Where would "
            "you dig?",
            [words("UPSTREAM TO THE VEIN", (180, 84), 24, "white", "brown", [pop(1.2)])], [sound(1.2, "pop"),
                sound(7.0, "chime")]),
    ]
    t = starts(s)
    cliff_pos, cliff_look = (1.5, 4.0, 9.0), (-3.5, 3.4, CLIFF)
    vein_px = project(cliff_pos, cliff_look, 50, (-2.0, 4.0, CLIFF + 0.5))
    s[0]["actors"] = [words("QUARTZ VEIN", (110, 120), 28, "ink", "white", [pop(1.2)]),
        arrow((110, 142), (vein_px[0] - 4, vein_px[1] - 6), 1.6, "white", 6, 0.2)]
    flow = [(-1.8, 0.15, -1.2), (0.5, 0.15, 0.6), (2.6, 0.15, 1.6), (4.6, 0.15, 2.8), (7.0, 0.15, 4.6), (10.0, 0.15, 6.4)]
    flake_moves = [{"do": "appear", "at": t[1] + 1.0}]
    for i, p in enumerate(flow[1:]):
        flake_moves.append(mv(t[1] + 1.0 + i * 1.6, p, 1.6))
    models = [model("land", "blocks", (0, 0, 0), fill=land()), model("vein", "blocks", (0, 0, 0), cells=vein()),
        model("flake", "mark", flow[0], moves=flake_moves)]
    # Rock crumbling off the cliff into the river.
    for i, (x, y) in enumerate([(-2.6, 5.0), (-1.4, 3.4)]):
        models.append(bit("pebble%d" % i, "STONE", t[1] + 0.4 + i * 0.5, [(x, y, CLIFF + 0.8), (x + 0.4, 0.2, CLIFF + 1.6)],
            0.8, size=0.4, leave=t[2]))
    # At the bend: flakes sink into the gravel, sand drifts on.
    bx, _, bz = BEND
    for i in range(3):   # heavy flakes drop through the water onto the gravel bed (its top is y -1)
        models.append(bit("gold%d" % i, "GOLD_LAMP", t[2] + 1.0 + i * 0.7, [(bx - 1.2 + i * 0.6, 0.3, bz + 0.5 + i * 0.3),
            (bx - 0.9 + i * 0.6, -1.0, bz + 0.7 + i * 0.3)], 1.6, size=0.3, leave=t[3]))
    for i in range(3):   # light sand is carried on down the river
        models.append(bit("sand%d" % i, "SAND", t[2] + 1.3 + i * 0.7, [(bx - 1.2 + i * 0.6, 0.3, bz + 0.3 + i * 0.3),
            (bx + 1.4 + i * 0.3, -0.4, bz + 1.8), (bx + 3.6 + i * 0.4, -0.4, bz + 3.4)], 2.0, size=0.28, leave=t[3]))
    # The prospector pans at the bend, then walks upstream to the cliff.
    stand = (bx + 1.4, 0, bz - 0.6)
    me_moves = [{"do": "emote", "at": t[3] + 8.0, "emote": "cheer"},
        mv(t[4] + 1.0, (-0.8, 0, -1.4), 6.0), {"do": "legs", "at": t[4] + 1.0, "dur": 6.0},
        {"do": "turn", "at": t[4] + 0.4, "dur": 0.6, "to": [0, 60, 0]}, {"do": "emote", "at": t[4] + 7.4, "emote": "think"}]
    models += [
        model("me", "avatar", stand, look="explorer", turn=[0, 200, 0], moves=me_moves),
        model("pan", "blocks", (0, 0.95, -0.55), on="me", fill=[cylinder(0, 0, 0, 3.2, 1, "PAINTED_SILVER"),
            cylinder(0, 1, 0, 3.2, 1, "PAINTED_SILVER"), cylinder(0, 1, 0, 2.2, 1, "AIR")], size=0.11,
            moves=[pop(t[3] + 0.6), {"do": "spin", "at": t[3] + 1.0, "dur": 6.0, "turns": 5, "ease": "smooth"},
                out(t[4] + 0.6)]),
        model("pan_mark", "mark", (0, 1.1, -0.55), on="me"),
    ]
    vx = -3.0
    effects = [
        {"kind": "sparkles", "at": [vx, 4.0, CLIFF + 0.6], "from": 0, "to": t[2], "size": 1.0, "area": [4, 1],
            "amount": 40, "color": "#ffe27a"},
        {"kind": "sparkles", "at": [bx - 0.3, 0.15, bz + 1.0], "from": t[2] + 2.6, "to": t[3], "size": 0.45, "amount": 30},
        {"kind": "sparkles", "on": "flake", "from": t[1] + 1.0, "to": t[1] + 9.0, "size": 0.7, "amount": 50,
            "color": "#ffd23a"},
        {"kind": "billow", "on": "pan_mark", "from": t[3] + 1.0, "to": t[3] + 7.0, "size": 0.07, "speed": 0.6,
            "amount": 40, "color": "#8cd0ff"},
        {"kind": "dust", "on": "pan_mark", "from": t[3] + 1.2, "to": t[3] + 6.5, "size": 0.08, "amount": 30,
            "color": "#e4cf9c"},
        {"kind": "sparkles", "on": "pan_mark", "from": t[3] + 6.6, "to": t[4] + 0.6, "size": 0.25, "amount": 24},
        {"kind": "sparkles", "at": [vx, 4.0, CLIFF + 0.6], "from": t[4] + 5.0, "to": t[4] + 10, "size": 1.2,
            "area": [4, 1], "amount": 50, "color": "#ffe27a"},
    ]
    camera = [
        cam(0, cliff_pos, cliff_look, 50),
        cam(t[1] - 0.05, (0.5, 4.4, 8.2), cliff_look, 50),
        cam(t[1], (11, 9, 15), (1.5, 0, 1), 50, cut=True),
        cam(t[2] - 0.05, (12, 8, 13), (3, 0, 2), 50),
        cam(t[2], (bx + 0.6, 3.6, bz + 3.8), (bx - 0.3, -1.0, bz + 1.2), 45, cut=True),
        cam(t[3] - 0.05, (bx + 0.4, 3.3, bz + 3.4), (bx - 0.3, -1.0, bz + 1.2), 45),
        cam(t[3], (stand[0] - 1.0, 2.2, stand[2] + 4.6), (stand[0], 1.0, stand[2]), 45, cut=True),
        cam(t[4] - 0.05, (stand[0] - 1.8, 2.0, stand[2] + 4.0), (stand[0], 0.9, stand[2]), 45),
        cam(t[4] + 1.0, (stand[0] + 2.0, 4.0, stand[2] + 7.0), (stand[0] - 2.0, 2.0, stand[2]), 50),
        cam(t[4] + 10, (2.0, 5.0, 8.0), (-2.5, 3.0, CLIFF), 50),
    ]
    stage = {"sky": {"top": "#3a7be8", "horizon": "#cdeeff", "bottom": "#8fb86a"}, "light": "day", "sun": [0.45, 0.8, 0.45],
        "models": models, "effects": effects, "camera": camera}
    return short("gold_prospecting", "How gold is found", "science", {"unit": "g7.science.resources"}, t[3] + 7,
        stage, s)
