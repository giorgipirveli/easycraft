"""Why we have seasons: Earth goes round the Sun with its axis tilted (23.4 degrees) and always pointing the same way;
in June the north leans toward the Sun (summer), in December away (winter); and Earth is nearest the Sun in January.
A camera that rides with Earth without turning shows the axis keeping its direction while the sunlight goes round.
Link: g5 Shadows, days and seasons."""
from reelkit import arrow, box, cam, model, out, pop, project, scene, short, sound, starts, words

ORBIT = 12.0            # the orbit's radius (not to scale)
EARTH = 2.8             # Earth's radius
TILT = 23.4             # degrees (NASA: 23.44)
YEAR = 10.0             # seconds a year round the Sun
JAN_DEG = 13.0          # 3-4 January (perihelion) and 4 July (aphelion) are about 13 days past the solstices


def orbit_at(deg):
    """Where Earth is `deg` round its orbit from June (+x), anticlockwise seen from above (StudioMotion's dir 1)."""
    import math
    a = math.radians(deg)
    return (ORBIT * math.cos(a), 0.0, -ORBIT * math.sin(a))


def orbit(at, turns):
    return {"do": "orbit", "at": at, "around": [0, 0, 0], "period": YEAR, "dir": 1, "dur": turns * YEAR}


def make():
    s = [
        scene(10, "Earth goes round the Sun once a year, and its axis is tilted!",
            "Earth goes round the Sun once a year. And look: Earth does not spin upright. Its axis is tilted, by "
            "about 23 degrees.",
            [words("TILTED 23.4°", (180, 84), 34, "white", "purple", [pop(6.6)])], [sound(6.6, "pop")], "space"),
        scene(10, "All year, the axis keeps pointing the same way: at the North Star.",
            "All year round, the axis keeps pointing the same way in space, toward the North Star. Watch the sunlight "
            "move round.",
            [], [sound(0.5, "whoosh"), sound(2.0, "sparkle")], "space"),
        scene(10, "June: the north leans toward the Sun. Long, sunny days: summer!",
            "In June, the northern half leans toward the Sun. The Sun climbs high, days are long, and it is summer in "
            "the north.",
            [], [sound(0.6, "pop"), sound(5.0, "ding")], "space"),
        scene(10, "December: the north leans away. Short, cold days: winter!",
            "Half a year later, Earth is on the other side of the Sun. The north leans away: days are short, and it is "
            "winter.",
            [], [sound(0.4, "whoosh"), sound(6.0, "ice_crackle")], "space"),
        scene(10, "Surprise: Earth is closest to the Sun in January! So, distance or tilt?",
            "Surprise: Earth is closest to the Sun in early January, in northern winter! So what makes the seasons: the "
            "distance, or the tilt?",
            [], [sound(0.6, "pop"), sound(4.0, "pop")], "space"),
    ]
    t = starts(s)
    june = orbit_at(0)
    december = orbit_at(180)
    wide_pos, wide_look, wide_fov = (0, 30, 58), (0, 1.5, 0), 44
    # Scene 1: June and December's places round the orbit, labelled where the wide shot shows them.
    def label(text, deg, box_colour, at_t, dy=-34):
        p = project(wide_pos, wide_look, wide_fov, orbit_at(deg))
        return words(text, (max(60, min(300, p[0])), p[1] + dy), 20, "white", box_colour, [pop(at_t)])
    # Scene 2's follow shot: the camera rides with Earth without turning, from above its orbit so it never looks
    # through the Sun; the axis's tip is labelled.
    follow_off, follow_look = (0, 7, 15), (0, 0.4, 0)
    s[1]["actors"] = [words("TO THE NORTH STAR", (112, 112), 20, "ink", "yellow", [pop(2.0)])]
    tip = project(follow_off, follow_look, 40, (-4.0 * 0.397, 4.0 * 0.917, 0))
    s[1]["actors"].append({"kind": "arrow", "from": [112, 130], "to": [round(tip[0]), round(tip[1])], "color": "white",
        "width": 6, "bend": 0.2, "moves": [{"do": "draw", "at": 2.4}]})
    # Scenes 3-4: close enough to see the whole Earth, its axis and the line between day and night, from a little
    # above (the north pole's side shows).
    close_pos, close_look, close_fov = (0, 4.5, 15.5), (0, 0.3, 0), 40
    north = project(close_pos, close_look, close_fov, (-EARTH * 0.397 * 0.8, EARTH * 0.917 * 0.8, 0.6))
    s[2]["actors"] = [
        words("JUNE", (180, 84), 34, "ink", "yellow", [pop(0.6)]),
        words("SUNLIGHT", (70, 140), 20, "ink", "gold", [pop(1.6)]),
        {"kind": "arrow", "from": [30, 166], "to": [120, 166], "color": "gold", "width": 8, "moves": [{"do": "draw", "at": 1.8}]},
        words("NORTH: SUMMER", (240, 150), 20, "white", "red", [pop(5.0)]),
        {"kind": "arrow", "from": [240, 170], "to": [round(north[0]) + 8, round(north[1]) - 6], "color": "white", "width": 6,
            "bend": -0.2, "moves": [{"do": "draw", "at": 5.3}]},
    ]
    north_dec = north
    s[3]["actors"] = [
        words("DECEMBER", (180, 84), 34, "white", "blue", [pop(5.6)]),
        words("SUNLIGHT", (290, 140), 20, "ink", "gold", [pop(5.8)]),
        {"kind": "arrow", "from": [330, 166], "to": [240, 166], "color": "gold", "width": 8, "moves": [{"do": "draw", "at": 6.0}]},
        words("NORTH: WINTER", (110, 150), 20, "white", "blue", [pop(6.6)]),
        {"kind": "arrow", "from": [110, 170], "to": [round(north_dec[0]), round(north_dec[1]) - 4], "color": "white",
            "width": 6, "bend": 0.2, "moves": [{"do": "draw", "at": 6.9}]},
    ]
    jan = project(wide_pos, wide_look, wide_fov, orbit_at(180 + JAN_DEG))
    jul = project(wide_pos, wide_look, wide_fov, orbit_at(JAN_DEG))
    s[4]["actors"] = [
        words("JANUARY: 147 MILLION km", (180, 392), 20, "white", "blue", [pop(1.0)]),
        arrow((150, 376), (jan[0] + 6, jan[1] + 10), 1.3, "white", 5, 0.2),
        words("JULY: 152 MILLION km", (180, 150), 20, "white", "red", [pop(4.0)]),
        arrow((220, 166), (jul[0] - 6, jul[1] - 10), 4.3, "white", 5, 0.2),
        words("NOT TO SCALE", (180, 84), 20, "white", "ink", [pop(6.0)]),
    ]
    s[0]["actors"].append(label("JUNE", 0, "red", 1.6))
    s[0]["actors"][-1]["moves"].append(out(4.4))
    s[0]["actors"].append(label("DECEMBER", 180, "blue", 2.2))
    s[0]["actors"][-1]["moves"].append(out(4.4))
    axis_moves = [orbit(0, 2), orbit(t[3], 0.5), orbit(t[4], 1)]
    models = [
        model("sun", "sun", (0, 0, 0), size=3.2, moves=[{"do": "spin", "at": 0, "rate": 0.03}]),
        model("path", "orbit_line", (0, 0, 0), radius=ORBIT, width=0.12, color="#ffffff50"),
        model("axis", "blocks", june, fill=[box(0, -4, 0, 0, 3, 0, "PAINTED_WHITE")], stretch=[0.12, 1, 0.12],
            turn=[0, 0, TILT], moves=axis_moves),
        model("north", "blocks", (0, 4.0, 0), on="axis", cells=[[0, 0, 0, "PAINTED_RED"]], size=0.36),
        model("earth", "planet", (0, 0, 0), on="axis", body="earth", size=EARTH, night=0.04,
            moves=[{"do": "spin", "at": 0, "rate": 0.25}]),
    ]
    camera = [
        cam(0, wide_pos, wide_look, wide_fov),
        cam(4.4, (3, 29, 57), wide_look, wide_fov),
        cam(t[1] - 0.05, (-13, 5, 8), (0, 0.6, 0), 40, follow="axis"),
        cam(t[1], follow_off, follow_look, 40, cut=True, follow="axis"),
        cam(t[2] - 0.05, follow_off, follow_look, 40, follow="axis"),
        cam(t[2], (june[0] + close_pos[0], close_pos[1], close_pos[2]), (june[0], close_look[1], 0), close_fov, cut=True),
        cam(t[3] - 0.05, (june[0] + 0.8, close_pos[1] + 0.3, close_pos[2] - 0.6), (june[0], close_look[1], 0), close_fov),
        cam(t[3], follow_off, follow_look, 40, cut=True, follow="axis"),
        cam(t[3] + 5.2, close_pos, close_look, close_fov, follow="axis"),
        cam(t[4] - 0.05, (close_pos[0] - 0.8, close_pos[1] + 0.3, close_pos[2] - 0.6), close_look, close_fov,
            follow="axis"),
        cam(t[4], wide_pos, wide_look, wide_fov, cut=True),
        cam(t[4] + 10, (-6, 28, 56), wide_look, wide_fov),
    ]
    stage = {"sky": "space", "light": "orrery", "models": models, "camera": camera}
    return short("seasons_tilt", "Why we have seasons", "space", {"unit": "g5.science.shadows_seasons"}, t[2] + 6,
        stage, s)
