"""Volume with blocks: one cube is 1 cubic unit; 4 in a row, 3 rows make a layer of 12; 2 layers make 24 (length x
width x height); a 3 x 3 x 3 cube holds 27; and a puzzle: double every side of a 2 x 2 x 2 cube. Each row and layer drops
in, coloured so it can be counted. Link: g5 Volume with cubes."""
from reelkit import box, cam, count, model, out, pop, project, scene, short, sound, starts, words

L, W, H = 4, 3, 2           # the cuboid: length (x), width (z), height (y)
BIG = 3                     # the big cube's side
SMALL = 2                   # the puzzle's cube's side
ORIGIN = (-1.5, 0, -1)      # the cuboid's first cube (its rows run along x, then back along z)
BIG_AT = (-1, 0, -1)


def drop(at, height=3.0):
    return {"do": "drop", "at": at, "height": height}


def make():
    s = [
        scene(9, "This cube is 1 long, 1 wide and 1 high. Its volume is 1 cube.",
            "Here is one cube. It is 1 unit long, 1 unit wide and 1 unit high. Its volume is 1 cubic unit.",
            [words("1 CUBIC UNIT", (180, 84), 28, "ink", "yellow", [pop(4.2)])], [sound(1.3, "thud"), sound(4.2, "pop")],
            "lab"),
        scene(10, "A row of 4, then 3 rows: 4 × 3 = 12 cubes make one layer.",
            "Put 4 cubes in a row. Make 3 rows. That is 4 times 3: 12 cubes in one layer.",
            [{"kind": "count", "from": 1, "to": L, "at": [180, 84], "size": 28, "color": "ink", "box": "yellow",
                "suffix": " IN A ROW", "moves": [pop(0.3), {"do": "value", "at": 1.0, "dur": 0.4, "to": 2},
                {"do": "value", "at": 1.8, "dur": 0.4, "to": 3}, {"do": "value", "at": 2.6, "dur": 0.4, "to": 4}]},
                words("4 × 3 = 12", (180, 136), 34, "white", "blue", [pop(7.0)])],
            [sound(0.6, "thud"), sound(1.4, "thud"), sound(4.0, "thud"), sound(5.6, "thud")], "lab"),
        scene(10, "Stack 2 layers: 12 × 2 = 24 cubes. Volume = length × width × height!",
            "Now stack a second layer on top: 12 times 2 is 24 cubes. Volume is length times width times height!",
            [words("12 × 2 = 24", (180, 84), 34, "white", "blue", [pop(2.6)]),
                words("VOLUME = L × W × H", (180, 136), 28, "ink", "yellow", [pop(5.4)])],
            [sound(1.2, "thud"), sound(2.6, "pop"), sound(5.4, "ding")], "lab"),
        scene(11, "A cube 3 long, 3 wide and 3 high holds 3 × 3 × 3 = 27 cubes.",
            "Try a big cube: 3 long, 3 wide and 3 high. Each layer has 9 cubes, and 3 layers make 27.",
            [{"kind": "count", "from": 0, "to": BIG ** 3, "at": [180, 84], "size": 34, "color": "ink", "box": "yellow",
                "prefix": "CUBES: ", "moves": [pop(1.4), {"do": "value", "at": 2.2, "dur": 0.6, "to": 9},
                {"do": "value", "at": 4.2, "dur": 0.6, "to": 18}, {"do": "value", "at": 6.2, "dur": 0.6, "to": 27}]},
                words("3 × 3 × 3 = 27", (180, 146), 34, "white", "green", [pop(8.0)])],
            [sound(1.6, "thud"), sound(3.6, "thud"), sound(5.6, "thud"), sound(8.0, "ding")], "lab"),
        scene(10, "A 2 × 2 × 2 cube holds 8. Double every side: how many cubes now?",
            "This small cube is 2 by 2 by 2, so it holds 8 cubes. If you double every side, how many cubes will it hold?",
            [words("2 × 2 × 2 = 8", (180, 84), 34, "white", "purple", [pop(1.4)]),
                words("4 × 4 × 4 = ?", (180, 146), 34, "ink", "yellow", [pop(5.6)])],
            [sound(1.0, "thud"), sound(1.4, "pop"), sound(5.6, "pop")], "lab"),
    ]
    t = starts(s)
    ox, oy, oz = ORIGIN
    gone = t[3] + 0.3
    models = [
        model("table", "blocks", (0, 0, 0), fill=[box(-6, -1, -5, 6, -1, 5, "PAINTED_WHITE")]),
        model("c1", "blocks", ORIGIN, cells=[[0, 0, 0, "PAINTED_RED"]], moves=[drop(1.0), out(gone)]),
    ]
    for i in range(1, L):
        models.append(model("c%d" % (i + 1), "blocks", (ox + i, oy, oz), cells=[[0, 0, 0, "PAINTED_RED"]],
            moves=[drop(t[1] + 0.3 + (i - 1) * 0.8), out(gone)]))
    for r, colour in [(1, "PAINTED_ORANGE"), (2, "PAINTED_YELLOW")]:
        models.append(model("row%d" % (r + 1), "blocks", (ox, oy, oz + r), fill=[box(0, 0, 0, L - 1, 0, 0, colour)],
            moves=[drop(t[1] + 2.4 + r * 1.6), out(gone)]))
    models.append(model("layer2", "blocks", (ox, oy + 1, oz), fill=[box(0, 0, 0, L - 1, 0, W - 1, "PAINTED_BLUE")],
        moves=[drop(t[2] + 0.9), out(gone)]))
    for k, colour in enumerate(["PAINTED_GREEN", "PAINTED_LIME", "PAINTED_TEAL"]):
        models.append(model("big%d" % (k + 1), "blocks", (BIG_AT[0], k, BIG_AT[2]),
            fill=[box(0, 0, 0, BIG - 1, 0, BIG - 1, colour)], moves=[drop(t[3] + 1.4 + k * 2.0), out(t[4] + 0.2)]))
    models.append(model("small", "blocks", (-0.5, 0, -0.5), fill=[box(0, 0, 0, SMALL - 1, SMALL - 1, SMALL - 1,
        "PAINTED_PURPLE")], moves=[drop(t[4] + 0.6)]))
    # Labels on the cuboid's edges in scene 3 (its length, width and height).
    cub_pos, cub_look = (6.5, 5.5, 8.5), (0, 0.6, 0)
    p_len = project(cub_pos, cub_look, 45, (0, 0, oz + W - 0.5 + 0.2))
    p_wid = project(cub_pos, cub_look, 45, (ox + L - 0.5 + 0.2, 0, 0))
    p_hei = project(cub_pos, cub_look, 45, (ox + L - 0.3, 1.0, oz + W - 0.3))
    clamp = lambda p, dx, dy: (max(60, min(290, p[0] + dx)), min(p[1] + dy, 410))
    s[2]["actors"] += [words("4 LONG", clamp(p_len, -20, 26), 20, "white", "red", [pop(6.4)]),
        words("3 WIDE", clamp(p_wid, 26, 18), 20, "white", "orange", [pop(6.8)]),
        words("2 HIGH", clamp(p_hei, 40, -10), 20, "white", "blue", [pop(7.2)])]
    camera = [
        cam(0, (4.5, 3.2, 6), (ox, 0.4, oz), 45),
        cam(t[1] - 0.05, (4.2, 4.0, 6.5), (-0.6, 0.4, -0.4), 45),
        cam(t[1] + 2.0, (5.5, 5.0, 8.0), (0, 0.4, 0), 45),
        cam(t[2] - 0.05, (6.0, 5.4, 8.4), (0, 0.6, 0), 45),
        cam(t[2] + 1.0, cub_pos, cub_look, 45),
        cam(t[3] - 0.05, (7.0, 5.5, 8.0), cub_look, 45, path="orbit"),
        cam(t[3], (6.5, 6.0, 8.5), (0.0, 1.2, 0), 45, cut=True),
        cam(t[4] - 0.05, (-5.5, 6.0, 9.0), (0.0, 1.4, 0), 45, path="orbit"),
        cam(t[4], (4.5, 3.6, 6.0), (0.5, 0.8, 0.5), 45, cut=True),
        cam(t[4] + 10, (-4.5, 4.0, 6.5), (0.5, 0.9, 0.5), 45, path="orbit"),
    ]
    stage = {"sky": "studio", "light": "studio", "models": models, "camera": camera}
    return short("volume_blocks", "Volume with blocks", "maths", {"unit": "g5.maths.volume"}, t[2] + 8, stage, s)
