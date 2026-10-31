"""Why day turns to night: on a little island the Sun seems to rise in the east; out in space it is Earth that spins,
once a day (24 hours); the half facing the Sun has day; a home riding on the turning Earth is carried from day into
night (the Sun seems to set in the west); back on the island it is night, the windows glow, and it is day on the other
side of Earth. Link: g5 Shadows, days and seasons."""
from reelkit import ball, box, cam, cylinder, model, mv, out, pop, project, scene, short, sound, starts, words

EARTH_AT = (5000, 0, 0)     # out in space, far from the island (the island's Sun lights Earth from the left: -x)
EARTH = 4.0
DAY = 20.0                  # seconds a spin in the reel (24 hours)


def island():
    """A little grass island with a house, a tree and a path; north is -z (SurveyRules), so a camera looking +z faces
    south and the east (+x) is on its left."""
    f = [box(-8, -4, -6, 8, -3, 8, "DIRT"), box(-8, -1, -6, 8, -1, 8, "GRASS"), box(-8, -2, -6, 8, -2, 8, "DIRT"),
        box(-1, -1, -6, 0, -1, 0, "PATH")]
    # the house (its door and windows face the camera, on its -z side)
    f += [box(-6, 0, 1, -2, 2, 4, "PLANKS"), box(-5, 0, 2, -3, 2, 3, "AIR"), box(-4, 0, 1, -4, 1, 1, "DOOR"),
        box(-5, 1, 1, -5, 1, 1, "AIR"), box(-3, 1, 1, -3, 1, 1, "AIR"), box(-7, 3, 0, -1, 3, 5, "ROOF_TILES"),
        box(-6, 4, 1, -2, 4, 4, "ROOF_TILES"), box(-5, 5, 2, -3, 5, 3, "ROOF_TILES")]
    f += [cylinder(-7, 0, 6, 0.3, 3, "LOG"), ball(-7, 4, 6, 1.8, "LEAVES"), box(2, 0, 5, 2, 0, 5, "FLOWERS"),
        box(6, 0, 0, 6, 0, 0, "FLOWERS"), box(-7, 0, -4, -7, 0, -4, "FLOWERS")]
    return f


def home_pin():
    """A tiny house standing on Earth's ground (its up is the model's +y)."""
    return [box(-1, 0, -1, 1, 1, 1, "PAINTED_WHITE"), box(-1, 2, -1, 1, 2, 1, "PAINTED_RED"), box(0, 3, 0, 0, 3, 0, "PAINTED_RED")]


def make():
    s = [
        scene(10, "Every morning the Sun seems to rise in the east. Is it really moving?",
            "Every morning the Sun seems to rise in the east, cross the sky, and set in the west. But is the Sun really "
            "moving?",
            [words("EAST", (80, 392), 24, "white", "orange", [pop(1.6)]), words("SUNRISE", (180, 84), 34, "ink", "yellow",
                [pop(3.0)])],
            [sound(3.0, "chime"), sound(5.4, "pop")]),
        scene(10, "No! Earth spins like a top, once every 24 hours.",
            "No! It is Earth that moves. It spins round like a top, once every 24 hours. That is one day.",
            [words("1 SPIN = 1 DAY", (180, 84), 34, "white", "purple", [pop(4.6)]),
                words("24 HOURS", (180, 136), 28, "ink", "yellow", [pop(5.4)])],
            [sound(0.4, "whoosh"), sound(4.6, "pop")], "space"),
        scene(10, "The half facing the Sun has day. The other half has night.",
            "Sunlight shines on the half of Earth that faces the Sun: there it is day. On the other half, it is night.",
            [], [sound(1.0, "pop"), sound(4.0, "pop")], "space"),
        scene(10, "As your home turns away from the Sun, the Sun sets. Night falls!",
            "As Earth turns, your home is carried away from the Sun. The Sun seems to sink in the west, and night falls.",
            [words("SUNSET HERE", (180, 84), 28, "white", "orange", [pop(4.6)])], [sound(4.6, "pop")], "space"),
        scene(10, "When it is night here, it is day on the other side. Who is waking up?",
            "When it is night where you live, it is daytime on the other side of Earth. Someone there is waking up. "
            "Who could it be?",
            [words("GOOD NIGHT!", (180, 84), 34, "white", "ink", [pop(1.0)])], [sound(1.0, "chime"),
                sound(6.0, "wisp_chime")]),
    ]
    t = starts(s)
    ex, ey, ez = EARTH_AT
    space_pos, space_look = (ex, ey + 1.0, ez + 19), (ex, ey - 0.8, ez)
    left = project(space_pos, space_look, 50, (ex - EARTH * 0.6, ey + 0.5, ez + EARTH * 0.8))
    right = project(space_pos, space_look, 50, (ex + EARTH * 0.6, ey + 0.5, ez + EARTH * 0.8))
    s[2]["actors"] = [words("DAY", (left[0], left[1]), 34, "ink", "yellow", [pop(1.0)]),
        words("NIGHT", (right[0], right[1]), 34, "white", "ink", [pop(4.0)])]
    # the Sun's path over the island (east = +x, on the camera's left; it rises, then is out of the sky by night)
    sun_moves = [mv(0.5, (3.6, 8, 42), 4.5, "out"), mv(5.0, (1.5, 14, 43), 5.0), out(t[1] - 0.4)]
    models = [
        model("island", "blocks", (0, 0, 0), fill=island()),
        model("lamps", "blocks", (0, 0, 0), cells=[[-5, 1, 2, "GOLD_LAMP"], [-3, 1, 2, "GOLD_LAMP"]],
            moves=[pop(t[4] + 3.0)]),
        model("sun", "sun", (6, -2, 40), size=3.0, moves=sun_moves),
        model("me", "avatar", (-0.2, 0, -8.5), look="default", turn=[0, -20, 0],
            moves=[{"do": "emote", "at": 3.2, "emote": "wave"}, {"do": "emote", "at": t[4] + 4.4, "emote": "yawn"}]),
        model("earth", "planet", EARTH_AT, body="earth", size=EARTH, night=0.04,
            moves=[{"do": "spin", "at": 0, "rate": 1.0 / DAY}]),
        model("home", "blocks", (EARTH * 1.005, 0, 0), on="earth", turn=[0, 0, -90], fill=home_pin(), size=0.3),
    ]
    effects = [{"kind": "sparkles", "at": [4, 2.0, 2.5], "from": t[4] + 3.0, "to": t[4] + 10, "size": 0.6,
        "color": "#ffe08a", "amount": 20}]
    ground_pos, ground_look = (1.0, 1.2, -15), (-0.5, 2.6, 6)
    camera = [
        cam(0, ground_pos, ground_look, 50),
        cam(t[1] - 0.05, (0.6, 1.3, -14.5), (0, 3.4, 6), 50),
        cam(t[1], (ex + 2, ey + 3, ez + 22), (ex, ey, ez), 45, cut=True),
        cam(t[2] - 0.05, (ex + 1, ey + 2.5, ez + 18), (ex, ey - 0.3, ez), 45),
        cam(t[2], space_pos, space_look, 50, cut=True),
        cam(t[3] - 0.05, (space_pos[0], space_pos[1], space_pos[2] - 1), space_look, 50),
        cam(t[3], (ex + 1.5, ey + 1.6, ez + 12.5), (ex + 0.3, ey - 0.2, ez + 3.5), 40, cut=True),
        cam(t[4] - 0.05, (ex + 0.9, ey + 1.4, ez + 11.8), (ex + 0.3, ey - 0.2, ez + 3.6), 40),
        cam(t[4], (1.0, 1.2, -15), (-1, 2.6, 6), 50, cut=True),
        cam(t[4] + 10, (0.4, 1.3, -14.2), (-1.5, 2.8, 6), 50),
    ]
    stage = {"sky": [{"at": 0, "sky": "dusk"}, {"at": 2.0, "dur": 6.0, "sky": "day"}, {"at": t[1], "sky": "space"},
            {"at": t[4], "sky": "night"}],
        "light": [{"at": 0, "light": "dusk"}, {"at": 2.0, "dur": 6.0, "light": "day"}, {"at": t[1], "light": "space"},
            {"at": t[4], "light": "night"}],
        "sun": [{"at": 0, "sun": [0.85, 0.15, 0.5]}, {"at": 2.0, "dur": 7.0, "sun": [0.45, 0.65, 0.6]},
            {"at": t[1], "sun": [-1, 0.05, 0.1]}, {"at": t[4], "sun": [-0.3, 0.75, -0.5]}],
        "models": models, "effects": effects, "camera": camera}
    return short("day_and_night", "Why day turns to night", "space", {"unit": "g5.science.shadows_seasons"}, t[1] + 5,
        stage, s)
