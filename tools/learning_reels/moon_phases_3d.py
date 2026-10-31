"""The Moon's phases in 3D: from above, the Sun lights one half of the Moon as it goes round Earth; then the camera
stands on Earth and keeps the Moon in its middle (it rides round with it, looking out) while the lit half turns toward
us: new, crescent, first quarter, gibbous, full. Link: g8 Moon phases, eclipses and seasons."""
import math

from reelkit import cam, model, out, pop, project, scene, short, sound, starts, words

SUN = (300, 0, 0)       # far off along +x: sunlight comes from there
ORBIT = 11.0            # the Moon's orbit's radius (not to scale)
EYE = (0, 0.2, 0)       # where the camera stands: in Earth (its sphere is seen from outside only), looking out
EARTH, MOON = 3.0, 1.8


def orbit_moves(radius_of_period):
    """The Moon's orbit: once round in 20 s (scenes 1-2), half round in 20 s (3-4: new to full), half
    round in 10 s (5: back to new)."""
    return [{"do": "orbit", "at": 0, "around": [0, 0, 0], "period": 20, "dir": 1, "dur": 20},
        {"do": "orbit", "at": 20, "around": [0, 0, 0], "period": 40, "dir": 1, "dur": 20},
        {"do": "orbit", "at": 40, "around": [0, 0, 0], "period": 20, "dir": 1, "dur": 10}]


def at_angle(deg, r, y=0.0):
    a = math.radians(deg)
    return (r * math.cos(a), y, -r * math.sin(a))


def make():
    s = [
        scene(10, "The Moon makes no light of its own. Sunlight lights up one half.",
            "The Moon makes no light of its own. The Sun always lights up one half of it: the half facing the Sun.",
            [], [sound(1.0, "pop")], "space"),
        scene(10, "As the Moon goes round Earth, its sunlit half always faces the Sun.",
            "As the Moon goes round Earth, its sunlit half always faces the Sun. But from Earth, we see it from different "
            "sides.",
            [], [sound(0.6, "whoosh")], "space"),
        scene(10, "From Earth: a new moon we can't see, then a crescent, then half!",
            "Watch from Earth. At new moon, the lit half faces away from us. Then a thin crescent grows, until half the "
            "face is lit.",
            [], [sound(0.4, "whoosh"), sound(3.6, "pop"), sound(8.6, "pop")], "space"),
        scene(10, "Then a gibbous moon, then a full moon: all of the lit half faces us!",
            "It keeps growing into a gibbous moon, and then a full moon, when all of the lit half faces us. Then it "
            "shrinks again.",
            [], [sound(3.4, "pop"), sound(8.4, "sparkle")], "space"),
        scene(10, "New moon to new moon takes about 29½ days. Which phase is it tonight?",
            "From one new moon to the next takes about 29 and a half days. Which phase will the Moon be tonight?",
            [words("ABOUT 29½ DAYS", (180, 84), 34, "white", "purple", [pop(1.2)])], [sound(1.2, "pop"),
                sound(6.0, "wisp_chime")], "space"),
    ]
    t = starts(s)
    top_pos, top_look, top_fov = (-7, 54, 0), (2, 0, 0), 46
    # Scenes 1-2: sunlight from the top of the frame; the four phases' places labelled round the orbit.
    sun_words = [words("SUNLIGHT", (180, 84), 28, "ink", "gold", [pop(1.2)])]
    for x in (90, 180, 270):
        sun_words.append({"kind": "arrow", "from": [x, 104], "to": [x, 164], "color": "gold", "width": 7,
            "moves": [{"do": "draw", "at": 1.6}]})
    s[0]["actors"] = sun_words + [words("EARTH", (180, 300), 20, "white", "blue", [pop(4.0)])]
    labels = []
    for (name, deg, colour, when, dy) in [("NEW", 0, "ink", 0.6, 0), ("FIRST QUARTER", 90, "purple", 3.1, -30),
            ("FULL", 180, "orange", 5.6, 0), ("LAST QUARTER", 270, "purple", 8.1, 30)]:
        p = project(top_pos, top_look, top_fov, at_angle(deg, ORBIT + 3.6))
        labels.append(words(name, (p[0], p[1] + dy), 20, "white", colour, [pop(when)]))
    s[1]["actors"] = labels
    # Scenes 3-4: the phase as seen from Earth, named as it comes.
    phases = [("NEW MOON", 0.5, 3.3, "ink"), ("CRESCENT", 3.6, 8.3, "teal"), ("FIRST QUARTER", 8.6, 10.0, "purple")]
    s[2]["actors"] = [words(n, (180, 84), 28, "white", c, [pop(a), out(b)] if b < 10 else [pop(a)]) for n, a, b, c in phases]
    s[2]["actors"].append(words("(the Sun is behind it)", (180, 136), 20, "ink", "white", [pop(1.0), out(3.3)]))
    s[3]["actors"] = [words("GIBBOUS", (180, 84), 28, "white", "teal", [pop(3.4), out(8.2)]),
        words("FULL MOON", (180, 84), 34, "ink", "yellow", [pop(8.4)])]
    models = [
        model("sun", "sun", SUN, size=16),
        model("earth", "planet", (0, 0, 0), body="earth", size=EARTH, night=0.05,
            moves=[{"do": "spin", "at": 0, "rate": 0.06}]),
        model("path", "orbit_line", (0, 0, 0), radius=ORBIT, width=0.1, color="#ffffff45",
            moves=[out(t[2]), pop(t[4])]),
        model("moon", "planet", (ORBIT, 0, 0), body="moon", size=MOON, night=0.02, moves=orbit_moves(ORBIT)),
        model("eye", "mark", EYE),
    ]
    camera = [
        cam(0, top_pos, top_look, top_fov),
        cam(t[2] - 0.05, (-6, 55, 3), top_look, top_fov),
        cam(t[2], (0, 0, 0), (0, -0.9, 0), 36, cut=True, follow="eye", aim="moon"),
        cam(t[4] - 0.05, (0, 0, 0), (0, -0.9, 0), 36, follow="eye", aim="moon"),
        cam(t[4], (-4, 48, 4), top_look, top_fov, cut=True),
        cam(t[4] + 10, top_pos, top_look, top_fov),
    ]
    stage = {"sky": "space", "light": "space", "sun": [1, 0.0, 0.0], "models": models, "camera": camera}
    return short("moon_phases_3d", "The Moon's phases in 3D", "space", {"unit": "g8.science.moon_seasons"}, t[3] + 3,
        stage, s)
