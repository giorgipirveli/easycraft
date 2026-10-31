"""The design sketches of Balance Altar (docs/design/games/balance-altar.md, phase A).

Draws every picture as SVG in the game's blocky, friendly look and renders each to PNG with rsvg-convert:

    /usr/bin/python3 -I docs/design/games/balance-altar/make_pictures.py [name ...]

The pictures are sketches for grown-ups (the lead, the owner): their words are labels, not the game's screen (the game
shows no words during play: pictures, numbers and the rune line only). Picture 12's numbers come from the phase A models
(model/hall_model.py, model/sky_room_model.py), run here at 1,000 visits each.
"""
import importlib.util
import math
import os
import subprocess
import sys

sys.dont_write_bytecode = True   # importing the models must leave no __pycache__ in the docs
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "DejaVu Sans, Arial, sans-serif"

# --- The palette (the meanings of §3.8) --------------------------------------------------------------------------------
INK = "#263238"
SOFT_INK = "#4a5a60"
PAPER = "#f7f4ec"
PANEL = "#ffffff"
SKY_DUSK = ("#7fa6e8", "#f7c9a0", "#fff1dc")
SKY_DAY = ("#8ec5f0", "#e9f3fb")
SKY_HIGH = ("#5d8fd8", "#bcd8f5")
STONE, STONE_SHADE, STONE_DARK = "#f6f1e7", "#ddd2bf", "#b9ab94"
TRIM, TRIM_DARK = "#e9b949", "#a9791a"                    # the temple's gold trim and the beam
BRONZE, BRONZE_DARK, BRONZE_LIGHT = "#c78a4e", "#83552a", "#e6b483"
ICE, ICE_MID, ICE_DARK, ICE_GLOW = "#d6f3ff", "#8fd6f6", "#2f8fc4", "#e9fbff"   # a frozen crystal (the unknown)
WARM, WARM_DARK = "#fff0b3", "#d9a521"                    # a freed crystal
GEM, GEM_DARK, GEM_SHINE = "#ffc928", "#c98a00", "#fff3b8"   # a gem: +1
BALLOON, BALLOON_DARK = "#ef5a4c", "#a9281e"              # a balloon: -1
CRYS_BALLOON, CRYS_BALLOON_DARK = "#cdb8ff", "#7a5ad6"    # a crystal balloon: -x
WAIT, FAIR, REFUSE = "#ffae3b", "#3fbf6b", "#e0473a"      # the glows: waiting for the twin, a fair move, refused
GLIMMER_COLOURS = ["#9df0d4", "#ffc2dd", "#d8c6ff", "#ffd3a8", "#b9e6ff", "#fff0a0"]
HOOT, HOOT_LIGHT = "#8a5a35", "#e2c093"
SKIN, SHIRT, PANTS, HAIR = "#f0c8a0", "#2bb3a3", "#3a5fb0", "#5a3b22"
GRASS = "#6abf4b"


# --- SVG helpers -----------------------------------------------------------------------------------------------------
def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}{_markers()}</defs>{body}</svg>')


def _markers():
    out = ""
    for name, colour in (("ink", INK), ("gold", TRIM_DARK), ("grey", "#7a8790"), ("green", FAIR), ("red", REFUSE),
                         ("white", "#ffffff"), ("blue", ICE_DARK), ("amber", WAIT)):
        out += (f'<marker id="arrow-{name}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" '
                f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{colour}"/></marker>')
    return out


def lin_grad(gid, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def rad_grad(gid, stops):
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return f'<radialGradient id="{gid}">{s}</radialGradient>'


def rect(x, y, w, h, fill, stroke=None, sw=3, rx=0, op=1.0, extra=""):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}"{st} '
            f'opacity="{op}" {extra}/>')


def circle(x, y, r, fill, stroke=None, sw=3, op=1.0):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{fill}"{st} opacity="{op}"/>'


def ellipse(x, y, rx, ry, fill, stroke=None, sw=3, rot=0.0, op=1.0):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return (f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}"{st} opacity="{op}" '
            f'transform="rotate({rot:.1f} {x:.1f} {y:.1f})"/>')


def path(d, fill="none", stroke=INK, sw=3, op=1.0, extra=""):
    st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"' if stroke else ""
    return f'<path d="{d}" fill="{fill}"{st} opacity="{op}" {extra}/>'


def poly(points, fill, stroke=INK, sw=3, op=1.0):
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else ""
    return f'<polygon points="{pts}" fill="{fill}"{st} opacity="{op}"/>'


def line(x1, y1, x2, y2, stroke=INK, sw=3, op=1.0, arrow=None, dash=None):
    m = f' marker-end="url(#arrow-{arrow})"' if arrow else ""
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" stroke-width="{sw}" '
            f'stroke-linecap="round" opacity="{op}"{m}{d}/>')


def curve_arrow(x1, y1, cx, cy, x2, y2, stroke, sw=4, arrow="ink", dash=None, op=1.0):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<path d="M{x1:.1f},{y1:.1f} Q{cx:.1f},{cy:.1f} {x2:.1f},{y2:.1f}" fill="none" stroke="{stroke}" '
            f'stroke-width="{sw}" stroke-linecap="round" marker-end="url(#arrow-{arrow})" opacity="{op}"{d}/>')


def text(x, y, s, size=20, anchor="middle", weight="normal", fill=INK, italic=False, op=1.0, family=FONT):
    st = ' font-style="italic"' if italic else ""
    s = str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" font-size="{size}" text-anchor="{anchor}" '
            f'font-weight="{weight}" fill="{fill}"{st} opacity="{op}">{s}</text>')


def lines_of_text(x, y, rows, size=18, anchor="middle", weight="normal", fill=INK, gap=1.3, italic=False):
    return "".join(text(x, y + i * size * gap, r, size, anchor, weight, fill, italic) for i, r in enumerate(rows))


def group(body, tx=0.0, ty=0.0, s=1.0, rot=0.0, op=1.0):
    return f'<g transform="translate({tx:.1f},{ty:.1f}) rotate({rot:.1f}) scale({s:.3f})" opacity="{op}">{body}</g>'


def card(x, y, w, h, fill=PANEL, stroke="#d0d8dc", rx=18, op=0.95):
    return rect(x, y, w, h, fill, stroke, 2, rx, op)


def wrap(s, width):
    words, rows, cur = s.split(" "), [], ""
    for wd in words:
        if cur and len(cur) + 1 + len(wd) > width:
            rows.append(cur)
            cur = wd
        else:
            cur = (cur + " " + wd).strip()
    if cur:
        rows.append(cur)
    return rows


def callout(x, y, rows, ax=None, ay=None, size=16, anchor="start", bold_first=True):
    """A label in a small white box at (x, y) (its top-left, or top-right for anchor end), with a leader to (ax, ay)."""
    wbox = max(len(r) for r in rows) * size * 0.56 + 22
    hbox = len(rows) * size * 1.3 + 14
    bx = x if anchor == "start" else x - wbox
    out = ""
    if ax is not None:
        lx = bx + (wbox if ax > bx + wbox else 0 if ax < bx else wbox / 2)
        ly = y + (hbox if ay > y + hbox else 0 if ay < y else hbox / 2)
        out += line(lx, ly, ax, ay, INK, 2, 0.8) + circle(ax, ay, 4, INK)
    out += rect(bx, y, wbox, hbox, "#ffffff", "#9fb4c2", 1.5, 8, 0.96)
    for i, r in enumerate(rows):
        out += text(bx + 11, y + 7 + size + i * size * 1.3, r, size, "start",
                    "bold" if (i == 0 and bold_first) else "normal")
    return out


def pill(x, y, label, size=22, fill=INK, colour="#ffffff"):
    w = len(label) * size * 0.62 + 28
    return (rect(x - w / 2, y - size * 1.05, w, size * 1.55, fill, None, 0, size * 0.77, 0.92)
            + text(x, y + size * 0.1, label, size, "middle", "bold", colour))


def title_bar(title, subtitle=""):
    out = text(40, 58, title, 34, "start", "bold")
    if subtitle:
        out += text(40, 92, subtitle, 19, "start", "normal", SOFT_INK)
    return out


def note(x, y, s, size=16, anchor="middle"):
    return text(x, y, s, size, anchor, "normal", SOFT_INK, True)


def common_defs():
    return (lin_grad("sky-dusk", [(0, SKY_DUSK[0]), (0.55, SKY_DUSK[1]), (1, SKY_DUSK[2])])
            + lin_grad("sky-day", [(0, SKY_DAY[0]), (1, SKY_DAY[1])])
            + lin_grad("sky-high", [(0, SKY_HIGH[0]), (1, SKY_HIGH[1])])
            + lin_grad("hall-floor", [(0, "#efe6d4"), (1, "#d9ccb2")])
            + lin_grad("beam", [(0, "#ffe08a"), (0.5, TRIM), (1, TRIM_DARK)])
            + lin_grad("fog", [(0, "#ffffff"), (1, "#e3ecf2")])
            + rad_grad("glow-gold", [(0, "#fff3b0", 0.95), (1, "#fff3b0", 0)])
            + rad_grad("glow-ice", [(0, ICE_GLOW, 0.95), (1, ICE_GLOW, 0)])
            + rad_grad("glow-amber", [(0, "#ffd08a", 0.9), (1, "#ffd08a", 0)])
            + rad_grad("glow-green", [(0, "#b8f5c9", 0.9), (1, "#b8f5c9", 0)])
            + rad_grad("glow-red", [(0, "#ffb3aa", 0.9), (1, "#ffb3aa", 0)])
            + rad_grad("glow-white", [(0, "#ffffff", 0.9), (1, "#ffffff", 0)]))


# --- Things ---------------------------------------------------------------------------------------------------------------
def gem(x, y, r, glow=None):
    """A gem (+1): a round faceted gold gem."""
    out = circle(x, y, r * 1.9, f"url(#glow-{glow})") if glow else ""
    out += circle(x, y, r, GEM, GEM_DARK, max(1.5, r * 0.16))
    out += poly([(x - r * 0.45, y - r * 0.1), (x, y - r * 0.6), (x + r * 0.45, y - r * 0.1), (x, y + r * 0.45)],
                "#ffdd66", None, 0, 0.9)
    out += circle(x - r * 0.35, y - r * 0.38, r * 0.2, GEM_SHINE, op=0.95)
    return out


def number_gem(x, y, r, value, glow=None):
    """A number gem (rung 7): one bigger gem that carries its number."""
    out = circle(x, y, r * 1.7, f"url(#glow-{glow})") if glow else ""
    out += circle(x, y, r, GEM, GEM_DARK, max(2, r * 0.12))
    out += circle(x - r * 0.4, y - r * 0.42, r * 0.16, GEM_SHINE)
    out += text(x, y + r * 0.36, str(value), r * 1.0, "middle", "bold", "#6b4300")
    return out


def gem_spots(cx, base_y, n, r, cols=5):
    """Where n gems sit on a pan: rows of five (like a ten-frame), bottom row first, centred on cx."""
    spots = []
    for i in range(n):
        row, col = divmod(i, cols)
        in_row = min(cols, n - row * cols)
        x = cx + (col - (in_row - 1) / 2) * r * 2.15
        y = base_y - r - row * r * 1.95
        spots.append((x, y))
    return spots


def crystal_points(x, y, h):
    """A standing crystal with its foot at (x, y): a long hexagonal prism with pointed ends."""
    w = h * 0.46
    return [(x, y), (x - w / 2, y - h * 0.18), (x - w / 2, y - h * 0.78), (x, y - h), (x + w / 2, y - h * 0.78),
            (x + w / 2, y - h * 0.18)]


def crystal(x, y, h, state="frozen", glimmer=True, glimmer_colour=None, letter=None, chains=True, glow=False, second=False):
    """A crystal (the unknown) with its foot at (x, y). state: frozen (ice blue, a Glimmer asleep inside, chained),
    freed (warm gold, empty), breathing (pulsing rings: a variable). second: the second kind of crystal (rung 8: a
    rose-gold crystal, the second unknown, y)."""
    out = ""
    pts = crystal_points(x, y, h)
    w = h * 0.46
    if glow or state == "breathing":
        out += circle(x, y - h / 2, h * 0.75, "url(#glow-ice)")
    fill, rim = (ICE, ICE_DARK) if state != "freed" else (WARM, WARM_DARK)
    if second:
        fill, rim = "#ffd6c2", "#c0602e"
    out += poly(pts, fill, rim, max(2, h * 0.035))
    out += poly([(x, y), (x, y - h), (x + w / 2, y - h * 0.78), (x + w / 2, y - h * 0.18)],
                "#f4a582" if second else (ICE_MID if state != "freed" else "#ffe27a"), None, 0, 0.55)
    out += line(x - w * 0.18, y - h * 0.7, x - w * 0.18, y - h * 0.3, "#ffffff", max(1.5, h * 0.03), 0.8)
    if glimmer and state != "freed" and not letter:
        out += glimmer_silhouette(x, y - h * 0.45, h * 0.30)
    if letter:
        out += text(x, y - h * 0.36, letter, h * 0.42, "middle", "bold", "#1d4f73", True, family="DejaVu Serif, serif")
    if state == "frozen" and chains:
        for dy in (0.32, 0.64):
            yy = y - h * dy
            out += path(f"M{x - w * 0.62:.1f},{yy + h * 0.06:.1f} Q{x:.1f},{yy - h * 0.06:.1f} {x + w * 0.62:.1f},{yy + h * 0.06:.1f}",
                        "none", ICE_DARK, max(2, h * 0.04), 0.9, extra='stroke-dasharray="6 3"')
    if state == "breathing":
        for k in (0.62, 0.78):
            out += ellipse(x, y - h / 2, w * k * 1.6, h * k * 0.75, "none", ICE_DARK, 2, 0, 0.45)
    return out


def glimmer_silhouette(x, y, s):
    """A Glimmer asleep inside a frozen crystal: a curled little fox, dark and soft."""
    return (ellipse(x, y + s * 0.1, s * 0.55, s * 0.38, "#3b6f93", None, 0, 0, 0.55)
            + circle(x - s * 0.38, y - s * 0.12, s * 0.28, "#3b6f93", None, 0, 0.55)
            + poly([(x - s * 0.58, y - s * 0.3), (x - s * 0.5, y - s * 0.55), (x - s * 0.38, y - s * 0.33)], "#3b6f93", None, 0, 0.55)
            + path(f"M{x + s * 0.45:.1f},{y + s * 0.1:.1f} q{s * 0.35:.1f},{-s * 0.3:.1f} {s * 0.05:.1f},{-s * 0.55:.1f}",
                   "none", "#3b6f93", s * 0.16, 0.55))


def glimmer(x, y, s, colour="#9df0d4", kind="fox", awake=True, flying=False):
    """A Glimmer awake: a small blocky crystal creature, feet at (x, y)."""
    dark = INK
    g = ""
    if kind == "fox":
        g += path("M14,-12 q26,-6 30,-30 q-16,6 -24,16", colour, dark, 2.5)                         # tail
        g += rect(-18, -26, 34, 22, colour, dark, 2.5, 6)                                             # body
        g += rect(-26, -46, 26, 24, colour, dark, 2.5, 6)                                             # head
        g += poly([(-26, -46), (-22, -60), (-15, -46)], colour, dark, 2.5)
        g += poly([(-11, -46), (-6, -60), (-1, -46)], colour, dark, 2.5)
        g += rect(-14, -4, 7, 6, colour, dark, 2, 2) + rect(6, -4, 7, 6, colour, dark, 2, 2)
        g += circle(-18, -36, 2.6, dark) + circle(-8, -36, 2.6, dark)
        g += circle(-30, -30, 3, "#ff8fb1", op=0.7) if False else ""
        g += path("M-16,-29 q3,3 6,0", "none", dark, 2)
    elif kind == "bird":
        g += ellipse(0, -22, 20, 15, colour, dark, 2.5)
        g += circle(-14, -36, 11, colour, dark, 2.5)
        g += poly([(-25, -37), (-33, -34), (-25, -31)], "#ffb347", dark, 2)
        g += path("M4,-28 q18,-22 30,-6 q-14,-2 -22,10", colour, dark, 2.5)
        g += circle(-16, -38, 2.4, dark)
    elif kind == "bunny":
        g += ellipse(0, -18, 18, 15, colour, dark, 2.5)
        g += circle(-10, -36, 12, colour, dark, 2.5)
        g += rect(-18, -66, 7, 24, colour, dark, 2.5, 4) + rect(-8, -66, 7, 24, colour, dark, 2.5, 4)
        g += circle(-14, -38, 2.4, dark) + circle(-6, -38, 2.4, dark)
    g += circle(-4, -40, 26, "url(#glow-white)", op=0.35) if awake else ""
    out = group(g, x, y, s)
    if flying:
        out += path(f"M{x - 30 * s:.1f},{y + 8 * s:.1f} q{-20 * s:.1f},{14 * s:.1f} {-40 * s:.1f},{30 * s:.1f}",
                    "none", "#ffffff", 3, 0.8, extra='stroke-dasharray="2 6"')
    return out


def balloon(x, y, r, tie_x, tie_y, fill=BALLOON, rim=BALLOON_DARK, glow=None):
    """A balloon (-1) floating at (x, y), its string tied at (tie_x, tie_y)."""
    out = circle(x, y, r * 1.8, f"url(#glow-{glow})") if glow else ""
    out += path(f"M{x:.1f},{y + r:.1f} Q{(x + tie_x) / 2 + r * 0.6:.1f},{(y + tie_y) / 2:.1f} {tie_x:.1f},{tie_y:.1f}",
                "none", "#6f7b82", 1.8)
    out += ellipse(x, y, r * 0.9, r, fill, rim, max(1.5, r * 0.12))
    out += poly([(x - r * 0.18, y + r * 1.12), (x + r * 0.18, y + r * 1.12), (x, y + r * 0.95)], fill, rim, 1.5)
    out += ellipse(x - r * 0.32, y - r * 0.36, r * 0.18, r * 0.28, "#ffffff", None, 0, -25, 0.7)
    return out


def crystal_balloon(x, y, h, tie_x, tie_y):
    """A crystal balloon (-x, rung 7): a crystal-shaped balloon that lifts as much as a crystal weighs."""
    out = path(f"M{x:.1f},{y:.1f} Q{(x + tie_x) / 2 + 8:.1f},{(y + tie_y) / 2:.1f} {tie_x:.1f},{tie_y:.1f}", "none", "#6f7b82", 1.8)
    pts = crystal_points(x, y, h)
    out += poly(pts, CRYS_BALLOON, CRYS_BALLOON_DARK, 2.5)
    out += ellipse(x - h * 0.08, y - h * 0.62, h * 0.06, h * 0.12, "#ffffff", None, 0, -20, 0.7)
    return out


PAN_W = 100          # a pan's half width, at scale 1
BEAM_L = 235         # the beam's half length, at scale 1


def chains(x1, y1, x2, y2, colour=BRONZE_DARK, sw=2.4):
    return line(x1, y1, x2, y2, colour, sw, 0.95, dash="7 3")


def pan(px, py, s, spec, side_glow=None, inward=1):
    """A pan whose rim centre is at (px, py), and what it holds. spec keys: crystals, gems, balloons, frozen, letter,
    numerals (a number gem instead of loose gems), cballoons (crystal balloons), box (k, inner gems), glimmer, glow.
    inward: +1 for a left pan (its balloons float towards the pillar, on the right), -1 for a right pan."""
    out = ""
    w = PAN_W * s
    if side_glow:
        out += ellipse(px, py - 40 * s, w * 1.25, 95 * s, f"url(#glow-{side_glow})")
    crystals = spec.get("crystals", 0) + spec.get("crystals2", 0)
    seconds = spec.get("crystals2", 0)
    gems = spec.get("gems", 0)
    balloons = spec.get("balloons", 0)
    cballoons = spec.get("cballoons", 0)
    box = spec.get("box")
    h = spec.get("crystal_h", 84) * s
    cw = h * 0.46
    gap = cw + 5 * s
    others = bool(gems or box or cballoons)
    # what stands on the pan: crystals on its left part, gems (or a number gem, or a box) to their right
    cx_list = []
    if crystals:
        if others:
            first = px - w + cw / 2 + 10 * s
        else:
            first = px - (crystals - 1) * gap / 2
        cx_list = [first + i * gap for i in range(crystals)]
    state = spec.get("state", "frozen" if spec.get("frozen", True) else "freed")
    for k, cxp in enumerate(cx_list):
        out += crystal(cxp, py - 6 * s, h, state, spec.get("glimmer", True), letter=spec.get("letter"),
                       chains=spec.get("frozen", True) and state == "frozen", second=k >= crystals - seconds)
    right_edge = (cx_list[-1] + cw / 2) if cx_list else px - w
    gx = (right_edge + px + w) / 2 if cx_list else px
    room = (px + w) - right_edge - 8 * s
    r = 12 * s
    cols = max(2, min(5, int(room / (2.15 * r)))) if cx_list else 5
    if box:
        k, inner = box
        out += recipe_box(gx, py - 6 * s, s * 0.8, k, inner)
    elif spec.get("numerals") and gems:
        out += number_gem(gx, py - 30 * s, 24 * s, gems)
    elif gems:
        for (x, y) in gem_spots(gx, py - 6 * s, gems, r, cols):
            out += gem(x, y, r, spec.get("gem_glow"))
    for i in range(balloons):
        col, row = i % 3, i // 3
        bx = px + inward * (w * 0.95 + col * 40 * s)
        by = py - 120 * s - row * 48 * s - (col % 2) * 20 * s
        out += balloon(bx, by, 20 * s, px + inward * w * 0.78, py - 4 * s, glow=spec.get("balloon_glow"))
    for i in range(cballoons):
        bx = px + w * 0.1 + i * 40 * s
        out += crystal_balloon(bx, py - 150 * s, 62 * s, px + w * 0.2 + i * 8 * s, py - 4 * s)
    # the bowl itself
    out += path(f"M{px - w:.1f},{py:.1f} Q{px:.1f},{py + 62 * s:.1f} {px + w:.1f},{py:.1f} z", BRONZE, BRONZE_DARK, 3 * s)
    out += ellipse(px, py, w, 13 * s, BRONZE_LIGHT, BRONZE_DARK, 2.5 * s)
    return out


def recipe_box(x, y, s, k, inner_gems, inner_crystal=True, label=True):
    """A recipe box (k equal compartments; what is in one is in all), its foot centred at (x, y)."""
    comp_w, comp_h = 46 * s, 70 * s
    W = comp_w * k
    out = rect(x - W / 2 - 6 * s, y - comp_h - 10 * s, W + 12 * s, comp_h + 10 * s, "#d9b38a", "#7a5530", 3 * s, 6 * s)
    for i in range(k):
        cx0 = x - W / 2 + i * comp_w + comp_w / 2
        out += rect(cx0 - comp_w / 2 + 3 * s, y - comp_h - 4 * s, comp_w - 6 * s, comp_h - 2 * s, "#fff4e3", "#b08a5c", 1.5 * s, 4 * s)
        if inner_crystal:
            out += crystal(cx0 - 9 * s, y - 10 * s, 40 * s, "frozen", False, chains=False)
        for j in range(inner_gems):
            out += gem(cx0 + 10 * s, y - 14 * s - j * 13 * s, 6.5 * s)
    if label:
        out += rect(x - 26 * s, y - comp_h - 40 * s, 52 * s, 26 * s, "#7a5530", None, 0, 6 * s)
        out += text(x, y - comp_h - 21 * s, f"×{k}", 19 * s, "middle", "bold", "#fff4e3")
    return out


def bowls(x, y, n, s=1.0, highlight=0):
    """The sharing bowls on their rack (n bowls)."""
    out = rect(x - 12 * s, y, (n * 46 + 14) * s, 12 * s, "#8a6a4a", INK, 2, 4)
    for i in range(n):
        bx = x + (i * 46 + 18) * s
        fill = "#ffd28a" if i < highlight else BRONZE_LIGHT
        out += path(f"M{bx - 19 * s:.1f},{y - 18 * s:.1f} Q{bx:.1f},{y + 8 * s:.1f} {bx + 19 * s:.1f},{y - 18 * s:.1f} z",
                    fill, BRONZE_DARK, 2)
        out += ellipse(bx, y - 18 * s, 19 * s, 4 * s, "#f3d2a8", BRONZE_DARK, 1.5)
    return out


def gem_bag(x, y, s=1.0):
    """The gem bag (add gems to both pans)."""
    out = path(f"M{x - 30 * s:.1f},{y:.1f} Q{x - 40 * s:.1f},{y - 50 * s:.1f} {x - 12 * s:.1f},{y - 60 * s:.1f} "
               f"L{x + 12 * s:.1f},{y - 60 * s:.1f} Q{x + 40 * s:.1f},{y - 50 * s:.1f} {x + 30 * s:.1f},{y:.1f} z",
               "#7b4bb5", "#3f2367", 3)
    out += rect(x - 16 * s, y - 68 * s, 32 * s, 10 * s, "#e9b949", INK, 2, 3)
    for k in range(3):
        out += gem(x - 12 * s + k * 12 * s, y - 72 * s - (k % 2) * 6 * s, 6 * s)
    return out


def pump(x, y, s=1.0):
    """The balloon pump (add balloons to both pans)."""
    out = rect(x - 14 * s, y - 70 * s, 28 * s, 70 * s, "#c9a46a", INK, 2.5, 6)
    out += rect(x - 22 * s, y - 8 * s, 44 * s, 10 * s, "#8a6a4a", INK, 2, 3)
    out += rect(x - 4 * s, y - 96 * s, 8 * s, 28 * s, "#9aa6ac", INK, 2, 2) + rect(x - 18 * s, y - 102 * s, 36 * s, 8 * s, "#5b6b74", INK, 2, 3)
    out += path(f"M{x + 14 * s:.1f},{y - 30 * s:.1f} q{24 * s:.1f},{-6 * s:.1f} {28 * s:.1f},{-34 * s:.1f}", "none", "#5b6b74", 3)
    out += balloon(x + 46 * s, y - 92 * s, 14 * s, x + 42 * s, y - 64 * s)
    return out


def mirror_tool(x, y, s=1.0):
    """The Keeper's Mirror (rung 7): gems become balloons and back."""
    out = rect(x - 6 * s, y, 12 * s, 60 * s, "#8a6a4a", INK, 2.5, 4)
    out += ellipse(x, y - 40 * s, 38 * s, 46 * s, "#e9b949", INK, 3)
    out += ellipse(x, y - 40 * s, 30 * s, 38 * s, "#dff4ff", "#7aa9c4", 2)
    out += path(f"M{x - 16 * s:.1f},{y - 52 * s:.1f} l{22 * s:.1f},{-14 * s:.1f}", "none", "#ffffff", 4, 0.9)
    return out


def swap_seal(x, y, s=1.0):
    """The swap seal (rung 8): a crystal may be swapped for what a level twin altar shows it weighs."""
    out = circle(x, y, 30 * s, "#e9b949", INK, 3)
    out += curve_arrow(x - 14 * s, y - 6 * s, x, y - 22 * s, x + 14 * s, y - 6 * s, INK, 3)
    out += curve_arrow(x + 14 * s, y + 6 * s, x, y + 22 * s, x - 14 * s, y + 6 * s, INK, 3)
    return out


def chandelier(cx, cy, r, lit, total=11):
    """The hall's chandelier: a ring of crystal sockets; each freed Glimmer lights one."""
    out = line(cx, cy - r * 0.32 - 70, cx, cy - r * 0.32, "#8a6a4a", 3)
    for k in (-1, 1):
        out += line(cx, cy - r * 0.32 - 30, cx + k * r * 0.8, cy - r * 0.2, "#8a6a4a", 2, 0.8)
    out += ellipse(cx, cy, r, r * 0.32, "none", TRIM_DARK, 5)
    for i in range(total):
        a = math.radians(90 + i * 360 / total)
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r * 0.32
        if i < lit:
            out += circle(x, y, 22, "url(#glow-gold)") + poly(crystal_points(x, y + 14, 30), WARM, WARM_DARK, 2)
        else:
            out += poly(crystal_points(x, y + 14, 30), "#e9eef2", "#9aa6ac", 2, 0.85)
    return out


def rune_plaque(cx, y, tokens, size=26, width=None, fill="#fbf3df"):
    """The rune line carved on an altar's plinth. tokens: strings; 'C' = a crystal icon, 'C3' = three crystal icons,
    'G5' = five gem dots, 'B2' = two balloon dots, anything else drawn as text (numerals, letters, + = - x)."""
    pieces = []
    for t in tokens:
        if t.startswith("C") and (len(t) == 1 or t[1:].isdigit()):
            pieces.append(("crystal", int(t[1:] or 1)))
        elif t.startswith("G") and t[1:].isdigit():
            pieces.append(("gems", int(t[1:])))
        elif t.startswith("B") and t[1:].isdigit():
            pieces.append(("balloons", int(t[1:])))
        else:
            pieces.append(("text", t))
    widths = []
    for kind, v in pieces:
        if kind == "crystal":
            widths.append(v * size * 0.55 + 6)
        elif kind in ("gems", "balloons"):
            groups = (min(v, 15) - 1) // 5 + 1
            widths.append(min(v, 15) * size * 0.42 + (groups - 1) * size * 0.3 + 8)
        else:
            widths.append(len(v) * size * 0.6 + 8)
    total = sum(widths) + 30
    W = width or total
    out = rect(cx - W / 2, y - size * 1.05, W, size * 1.75, fill, "#b9a37a", 2.5, 10)
    x = cx - total / 2 + 15
    for (kind, v), wdt in zip(pieces, widths):
        if kind == "crystal":
            for i in range(v):
                out += poly(crystal_points(x + size * 0.27 + i * size * 0.55, y + size * 0.36, size * 0.95), ICE, ICE_DARK, 2)
        elif kind == "gems":
            for i in range(min(v, 15)):
                grp, k = divmod(i, 5)
                out += circle(x + 6 + k * size * 0.42 + grp * (size * 0.42 * 5 + size * 0.3), y - size * 0.05,
                              size * 0.17, GEM, GEM_DARK, 1.5)
        elif kind == "balloons":
            for i in range(v):
                out += circle(x + 6 + i * size * 0.42, y - size * 0.05, size * 0.17, BALLOON, BALLOON_DARK, 1.5)
        else:
            out += text(x + wdt / 2, y + size * 0.36, v, size, "middle", "bold", "#3d2f1f", family="DejaVu Serif, serif")
        x += wdt
    return out


def altar(cx, top, s=1.0, left=None, right=None, tilt=0.0, plinth=True, runes=None, rune_size=24,
          crown=True, beam_glow=None, chain_colour=BRONZE_DARK):
    """A balance altar. (cx, top) is the beam's pivot. tilt in degrees (positive: the right pan goes down)."""
    left, right = left or {}, right or {}
    out = ""
    L = BEAM_L * s
    col_h = 300 * s
    # the pillar and its plinth
    out += rect(cx - 30 * s, top + 8 * s, 60 * s, col_h, STONE, STONE_DARK, 3, 6)
    for k in range(3):
        out += line(cx - 18 * s + k * 18 * s, top + 30 * s, cx - 18 * s + k * 18 * s, top + col_h - 10 * s, STONE_SHADE, 3)
    if plinth:
        out += rect(cx - 120 * s, top + col_h, 240 * s, 40 * s, STONE, STONE_DARK, 3, 8)
        out += rect(cx - 150 * s, top + col_h + 36 * s, 300 * s, 26 * s, STONE_SHADE, STONE_DARK, 3, 6)
    # the crown: the equals sign the beam rests on
    if crown:
        out += rect(cx - 44 * s, top + 10 * s, 88 * s, 12 * s, TRIM, TRIM_DARK, 2.5, 5)
        out += rect(cx - 44 * s, top + 30 * s, 88 * s, 12 * s, TRIM, TRIM_DARK, 2.5, 5)
    # the beam
    a = math.radians(tilt)
    ex, ey = math.cos(a) * L, math.sin(a) * L
    lx, ly, rx, ry = cx - ex, top - ey, cx + ex, top + ey
    if beam_glow:
        out += path(f"M{lx:.1f},{ly:.1f} L{rx:.1f},{ry:.1f}", "none", {"green": "#9ef0b8", "red": "#ffb0a8",
                                                                       "amber": "#ffd08a"}[beam_glow], 26 * s, 0.7)
    out += path(f"M{lx:.1f},{ly:.1f} L{rx:.1f},{ry:.1f}", "none", TRIM_DARK, 18 * s)
    out += path(f"M{lx:.1f},{ly:.1f} L{rx:.1f},{ry:.1f}", "none", TRIM, 12 * s)
    out += circle(cx, top, 15 * s, TRIM, TRIM_DARK, 3) + circle(cx, top, 5 * s, TRIM_DARK)
    for (ex2, ey2) in ((lx, ly), (rx, ry)):
        out += circle(ex2, ey2, 9 * s, TRIM, TRIM_DARK, 2.5)
    # the pans hang straight down
    drop = 150 * s
    for (ex2, ey2, spec, inward) in ((lx, ly, left, 1), (rx, ry, right, -1)):
        py = ey2 + drop
        out += chains(ex2, ey2, ex2 - (PAN_W - 12) * s, py, chain_colour) + chains(ex2, ey2, ex2 + (PAN_W - 12) * s, py, chain_colour)
        out += pan(ex2, py, s, spec, spec.get("glow"), inward)
    if runes:
        out += rune_plaque(cx, top + col_h + 22 * s, runes, rune_size * s)
    return out


def cloud(x, y, s, fill="#ffffff", op=1.0):
    return (ellipse(x, y, 60 * s, 30 * s, fill, "#d6dfe6", 2, 0, op) + circle(x - 28 * s, y - 14 * s, 26 * s, fill, None, 0, op)
            + circle(x + 10 * s, y - 24 * s, 32 * s, fill, None, 0, op) + circle(x + 40 * s, y - 8 * s, 22 * s, fill, None, 0, op))


def avatar(x, y, s, arm_up=False, rot=0):
    """The blocky child, feet at (x, y)."""
    g = (rect(-10, -40, 20, 26, SHIRT, INK, 2.5, 3)
         + rect(-9, -14, 8, 14, PANTS, INK, 2.5, 2) + rect(1, -14, 8, 14, PANTS, INK, 2.5, 2)
         + rect(-12, -64, 24, 24, SKIN, INK, 2.5, 3) + rect(-12, -64, 24, 8, HAIR, None, 0, 2)
         + rect(-6, -52, 4, 4, INK) + rect(3, -52, 4, 4, INK) + rect(-4, -45, 8, 2, "#c46a5a"))
    if arm_up:
        g += rect(-18, -40, 8, 22, SKIN, INK, 2, 3) + rect(10, -62, 8, 24, SKIN, INK, 2, 3)
    else:
        g += rect(-18, -40, 8, 22, SKIN, INK, 2, 3) + rect(10, -40, 8, 22, SKIN, INK, 2, 3)
    return group(g, x, y, s, rot)


def hoot(x, y, s, wing_up=False):
    """Professor Hoot, the blocky owl, feet at (x, y)."""
    g = (rect(-22, -60, 44, 56, HOOT, INK, 2.5, 8) + rect(-14, -36, 28, 28, HOOT_LIGHT, None, 0, 6)
         + path("M-22,-60 L-26,-74 L-10,-60 z M22,-60 L26,-74 L10,-60 z", HOOT, INK, 2.5)
         + circle(-10, -46, 9, "#ffffff", INK, 2) + circle(10, -46, 9, "#ffffff", INK, 2)
         + circle(-9, -45, 4, INK) + circle(11, -45, 4, INK)
         + circle(-10, -46, 12, "none", "#3b3b3b", 1.8) + circle(10, -46, 12, "none", "#3b3b3b", 1.8)
         + line(-1, -46, 1, -46, "#3b3b3b", 1.8)
         + path("M-4,-36 L4,-36 L0,-29 z", "#ff9f1c", INK, 1.5)
         + line(-8, -4, -8, 2, "#ff9f1c", 4) + line(8, -4, 8, 2, "#ff9f1c", 4))
    if wing_up:
        g += path("M-22,-40 Q-44,-62 -40,-34 Q-34,-28 -22,-30 z", HOOT, INK, 2.5)
        g += path("M22,-40 Q44,-62 40,-34 Q34,-28 22,-30 z", HOOT, INK, 2.5)
    else:
        g += rect(-28, -44, 8, 26, HOOT, INK, 2.5, 4) + rect(20, -44, 8, 26, HOOT, INK, 2.5, 4)
    return group(g, x, y, s)


def speech(x, y, w, rows, size=17):
    """Hoot's spoken line (a sketch for grown-ups: in the game it is heard, not read)."""
    h = len(rows) * size * 1.35 + 18
    out = rect(x, y, w, h, "#ffffff", "#9fb4c2", 2, 14)
    out += path(f"M{x + 26},{y + h} l-10,18 l26,-18 z", "#ffffff", "#9fb4c2", 2)
    out += rect(x + 12, y + h - 3, 34, 6, "#ffffff")
    out += circle(x + 22, y + 22, 8, "#6c8a96") + path(f"M{x + 32},{y + 16} q6,6 0,12", "none", "#6c8a96", 2)
    for i, r in enumerate(rows):
        out += text(x + 42, y + 24 + i * size * 1.35, r, size, "start", "normal", INK, True)
    return out


def vr_hand(x, y, s, rot=0, grip=True, fill="#ffd9b8"):
    g = rect(-22, -10, 44, 50, fill, INK, 3, 14)
    if grip:
        g += rect(-24, -24, 48, 18, fill, INK, 3, 9)
    else:
        for k in range(4):
            g += rect(-20 + k * 11, -44, 9, 36, fill, INK, 2.5, 4)
        g += rect(20, -10, 14, 28, fill, INK, 2.5, 6)
    g += rect(-26, 36, 52, 18, "#3a4a52", INK, 2.5, 6)
    return group(g, x, y, s, rot)


def finger(x, y, s, rot=0):
    """A tapping finger (flat play)."""
    g = (rect(-9, -4, 18, 40, "#ffd9b8", INK, 2.5, 8) + rect(-14, 26, 28, 30, "#ffd9b8", INK, 2.5, 10)
         + circle(0, 0, 14, "none", WAIT, 3, 0.9))
    return group(g, x, y, s, rot)


def notes(x, y, s=1.0, colour=TRIM_DARK):
    """A little chime: two music notes."""
    return (circle(x, y, 6 * s, colour) + line(x + 6 * s, y, x + 6 * s, y - 22 * s, colour, 2.5)
            + circle(x + 18 * s, y - 6 * s, 6 * s, colour) + line(x + 24 * s, y - 6 * s, x + 24 * s, y - 28 * s, colour, 2.5)
            + line(x + 6 * s, y - 22 * s, x + 24 * s, y - 28 * s, colour, 4))


def rattle(x, y, s=1.0):
    """The chains rattling: zig-zags (a rule break: refused, calmly)."""
    out = ""
    for dx in (-1, 1):
        out += path(f"M{x + dx * 20 * s:.1f},{y - 20 * s:.1f} l{dx * 8 * s:.1f},{6 * s:.1f} l{-dx * 8 * s:.1f},{6 * s:.1f} "
                    f"l{dx * 8 * s:.1f},{6 * s:.1f}", "none", REFUSE, 3)
    return out


def tick(x, y, s=1.0, colour=FAIR):
    return circle(x, y, 18 * s, colour) + path(f"M{x - 8 * s:.1f},{y:.1f} l{6 * s:.1f},{7 * s:.1f} l{11 * s:.1f},{-13 * s:.1f}",
                                               "none", "#ffffff", 4 * s)


def cross(x, y, s=1.0, colour=REFUSE):
    return circle(x, y, 18 * s, colour) + path(f"M{x - 7 * s:.1f},{y - 7 * s:.1f} l{14 * s:.1f},{14 * s:.1f} "
                                               f"M{x + 7 * s:.1f},{y - 7 * s:.1f} l{-14 * s:.1f},{14 * s:.1f}", "none", "#ffffff", 4 * s)


def temple(cx, base, s=1.0, door_open=False, lit=0.0):
    """The Sky Temple on its cloud bank: base steps, columns, a pediment with a balance relief, a dome."""
    out = ""
    # cloud bank under it
    for k in range(9):
        out += cloud(cx - 330 * s + k * 82 * s, base + 50 * s + (k % 2) * 16 * s, 1.15 * s, "#ffffff", 0.97)
    # steps
    for k in range(3):
        w = (620 - k * 50) * s
        out += rect(cx - w / 2, base - (k + 1) * 22 * s, w, 22 * s, STONE, STONE_DARK, 2.5, 3)
    top = base - 66 * s
    # columns
    for i in range(6):
        x = cx - 230 * s + i * 92 * s
        out += rect(x - 18 * s, top - 230 * s, 36 * s, 230 * s, STONE, STONE_DARK, 2.5, 4)
        out += rect(x - 26 * s, top - 244 * s, 52 * s, 16 * s, STONE_SHADE, STONE_DARK, 2.5, 3)
        out += line(x - 6 * s, top - 222 * s, x - 6 * s, top - 10 * s, STONE_SHADE, 3)
    # the great door between the middle columns
    dw, dh = 120 * s, 170 * s
    out += rect(cx - dw / 2, top - dh, dw, dh, "#ffe9a8" if door_open else "#9a7b52", INK, 3, 50 * s)
    if door_open:
        out += circle(cx, top - dh / 2, 120 * s, "url(#glow-gold)")
    else:
        out += line(cx, top - dh + 16 * s, cx, top, "#6e5536", 3)
    # entablature and pediment with a balance relief
    out += rect(cx - 290 * s, top - 280 * s, 580 * s, 40 * s, STONE, STONE_DARK, 2.5, 3)
    out += rect(cx - 290 * s, top - 266 * s, 580 * s, 8 * s, TRIM, None, 0, 2)
    out += poly([(cx - 300 * s, top - 280 * s), (cx, top - 380 * s), (cx + 300 * s, top - 280 * s)], STONE, STONE_DARK, 2.5)
    out += line(cx - 70 * s, top - 318 * s, cx + 70 * s, top - 318 * s, TRIM_DARK, 6 * s)
    out += line(cx, top - 318 * s, cx, top - 292 * s, TRIM_DARK, 6 * s)
    out += path(f"M{cx - 92 * s:.1f},{top - 300 * s:.1f} q22,14 44,0 z M{cx + 48 * s:.1f},{top - 300 * s:.1f} q22,14 44,0 z",
                TRIM, TRIM_DARK, 2)
    # dome
    out += rect(cx - 150 * s, top - 420 * s, 300 * s, 46 * s, STONE, STONE_DARK, 2.5, 4)
    out += path(f"M{cx - 140 * s:.1f},{top - 420 * s:.1f} Q{cx:.1f},{top - 600 * s:.1f} {cx + 140 * s:.1f},{top - 420 * s:.1f} z",
                "#f0e6d2", STONE_DARK, 3)
    for k in (-2, -1, 0, 1, 2):
        out += path(f"M{cx + k * 48 * s:.1f},{top - 420 * s:.1f} Q{cx + k * 20 * s:.1f},{top - 540 * s:.1f} {cx:.1f},{top - 552 * s:.1f}",
                    "none", STONE_SHADE, 2)
    out += circle(cx, top - 560 * s, 16 * s, "#fff3b0" if lit else "#c9d6de", TRIM_DARK, 3)
    if lit:
        out += circle(cx, top - 560 * s, 60 * s * lit, "url(#glow-gold)")
    return out


def cloud_stair(x0, y0, n, dx, dy, s=1.0):
    out = ""
    for k in range(n):
        out += cloud(x0 + k * dx, y0 - k * dy, 0.55 * s, "#ffffff", 0.98)
    return out


def number_line(x0, y, x1, lo, hi, lit_from=None, lit_dir=None, stone_at=None, stone_filled=False, size=16):
    """The floor's number line: tiles from lo to hi; the solution lit (from a boundary in a direction)."""
    out = line(x0, y, x1, y, INK, 3)
    n = hi - lo
    step = (x1 - x0) / n
    for i in range(n + 1):
        v = lo + i
        x = x0 + i * step
        lit = lit_from is not None and ((lit_dir == "<" and v < lit_from) or (lit_dir == ">" and v > lit_from))
        out += rect(x - step * 0.42, y - 16, step * 0.84, 32, "#fff1b0" if lit else "#efe6d4", "#b9ab94", 1.5, 5)
        out += text(x, y + 6, str(v).replace("-", "−"), size, "middle", "bold", INK)
    if stone_at is not None:
        x = x0 + (stone_at - lo) * step
        out += circle(x, y - 34, 12, INK if stone_filled else "#ffffff", INK, 3)
        if lit_dir:
            out += line(x + (-12 if lit_dir == "<" else 12), y - 34, x + (-step * 3 if lit_dir == "<" else step * 3), y - 34,
                        WAIT, 5, 1, "amber")
    return out


# --- 01: the Sky Temple, outside and inside ----------------------------------------------------------------------------
def pic_temple():
    W, H = 1800, 1040
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Sky Temple", "Above your world floats a temple whose crystals are frozen on balance altars; "
                      "a Glimmer sleeps in each one")
    # left: arriving
    body += rect(40, 120, 900, 870, "url(#sky-dusk)", "#d8cfc0", 2, 22)
    body += circle(520, 300, 230, "url(#glow-gold)")
    for (x, y, sc) in ((150, 230, 0.8), (800, 210, 0.6), (700, 320, 0.45), (230, 360, 0.5)):
        body += cloud(x, y, sc, "#ffffff", 0.85)
    body += temple(520, 800, 0.92, door_open=False, lit=0.0)
    for k, (x, y) in enumerate(((78, 972), (128, 948), (178, 924), (226, 900))):
        body += ellipse(x, y, 34, 13, "#ffffff", "#c9d6de", 2) + circle(x - 10, y - 8, 12, "#ffffff") + circle(x + 9, y - 10, 14, "#ffffff")
    body += avatar(420, 818, 1.15, arm_up=True)
    body += hoot(735, 735, 0.9, wing_up=True)
    body += speech(600, 590, 300, ["Welcome to the Sky Temple!", "Its crystals are frozen."], 17)
    for (x, y) in ((300, 520), (835, 540), (820, 420)):
        body += gem(x, y, 8, "gold")
    body += callout(480, 905, ["A stair of clouds", "up from your world"], 190, 918, 16)
    body += callout(62, 555, ["The great door", "opens for a new Keeper"], 470, 660, 16)
    # right: inside the hall
    body += rect(970, 120, 790, 870, "#f3ead8", "#d8cfc0", 2, 22)
    body += text(1365, 160, "Inside: the Hall of Frozen Crystals", 22, "middle", "bold")
    body += rect(1050, 360, 630, 110, "#e8dcc4", STONE_DARK, 2.5, 8)                                  # the far wall
    body += path("M1330,470 L1330,410 Q1365,372 1400,410 L1400,470 z", "#9a7b52", INK, 2.5)         # the great door
    body += ellipse(1365, 545, 340, 104, "url(#hall-floor)", STONE_DARK, 3)
    body += chandelier(1365, 300, 150, 2, 11)
    spots = []
    for i in range(10):
        a = math.radians(90 + 360 * (i + 0.5) / 10)
        spots.append((1365 + math.cos(a) * 285, 545 + math.sin(a) * 86, math.sin(a)))
    for (x, y, depth) in sorted(spots, key=lambda t: t[1]):
        sc = 0.12 + 0.05 * (depth + 1) / 2
        body += altar(x, y - 66 * (sc / 0.15), sc, {"crystals": 1, "gems": 2}, {"gems": 5}, plinth=False, crown=False)
    body += ellipse(1365, 545, 46, 14, "#d9ccb2", STONE_DARK, 2, 0, 0.9)
    body += callout(985, 215, ["Ten altars in a ring", "each with a frozen crystal;", "the Great Altar rises in the middle"],
                    1100, 470, 16)
    body += callout(1745, 215, ["The chandelier", "each freed Glimmer lights", "one of its crystals"], 1505, 300, 16, "end")
    body += callout(1745, 380, ["The great door", "opens when the hall is lit"], 1400, 430, 16, "end")
    # one altar close up
    body += rect(1000, 660, 730, 310, "#fbf6ea", "#d8cfc0", 2, 16)
    body += text(1030, 694, "Close up", 18, "start", "bold", SOFT_INK)
    body += altar(1300, 735, 0.68, {"crystals": 1, "gems": 3}, {"gems": 7}, plinth=False)
    body += callout(1715, 690, ["A frozen crystal", "a Glimmer asleep inside;", "free it and it wakes"], 1158, 818, 16, "end")
    body += glimmer(1620, 950, 0.9, GLIMMER_COLOURS[1], "bunny") + glimmer(1685, 950, 0.9, GLIMMER_COLOURS[2], "bird")
    return svg(W, H, body, common_defs())


# --- 02: one altar, named ----------------------------------------------------------------------------------------------
def pic_altar():
    W, H = 1800, 1180
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("One altar", "The beam rests on an equals sign; the pans weigh the same; the crystal's weight is "
                      "the unknown")
    body += rect(40, 120, 1720, 1020, "#f3ead8", "#d8cfc0", 2, 22)
    cx, top = 900, 400
    body += altar(cx, top, 1.25, {"crystals": 1, "gems": 3}, {"gems": 7}, runes=["C", "+", "G3", "=", "G7"], rune_size=26)
    body += bowls(1300, 960, 6, 1.0)
    body += gem_bag(470, 980, 1.2)
    body += hoot(1680, 1110, 0.9)
    body += callout(980, 170, ["The crown is an equals sign", "the beam rests on two gold bars"], cx, top + 26, 17)
    body += callout(70, 170, ["The beam stays level", "the frozen crystal's chains hold it:",
                              "an unfair move rattles them and springs back"], 700, top, 17)
    body += callout(70, 420, ["A frozen crystal", "its weight is the number to find;", "a Glimmer sleeps inside"],
                    517, 527, 17)
    body += callout(70, 660, ["Gems: one each", "in rows of five, easy to count"], 636, 566, 17)
    body += callout(1730, 330, ["Seven gems", "the same weight as the left pan"], 1194, 540, 17, "end")
    body += callout(1100, 1010, ["The rune line", "the altar's equation, carved; it changes",
                                 "with every move and Hoot reads it aloud"], cx + 40, 802, 17)
    body += callout(1730, 800, ["Sharing bowls", "split both pans into equal shares"], 1420, 948, 17, "end")
    body += callout(70, 1010, ["The gem bag", "put the same on both pans"], 470, 920, 17)
    body += note(900, 1120, "Free the crystal: get it alone on its pan with fair moves. The other pan then shows "
                 "what it weighs (here: four gems).", 18)
    return svg(W, H, body, common_defs())


# --- 03: the verb: the twin move, the free, and the refused move --------------------------------------------------------
def pic_twin():
    W, H = 1800, 1080
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The verb: keep the balance", "Take the same off both pans; the altar takes a move only when it "
                      "is done to both. Free the crystal and it shows its weight")
    panels = [
        ("1. Lift a gem", "it glows; the altar waits for its twin (the twins glow on the other pan)",
         {"crystals": 1, "gems": 2, "gem_glow": "amber"}, {"gems": 7, "gem_glow": "amber"}, "amber", ["C", "+", "G3", "=", "G7"]),
        ("2. Lift its twin", "the same on both pans: both float off with a chime, the chains glow green",
         {"crystals": 1, "gems": 2}, {"gems": 6}, "green", ["C", "+", "G2", "=", "G6"]),
        ("3. Again, and again", "the crystal stands alone; nothing waits",
         {"crystals": 1}, {"gems": 4}, None, ["C", "=", "G4"]),
        ("4. Free!", "the chains snap, the Glimmer wakes; the gems count: one, two, three, four",
         {"crystals": 1, "frozen": False, "glimmer": False}, {"gems": 4, "gem_glow": "gold"}, "green", ["C", "=", "G4"]),
    ]
    s = 0.6
    for i, (name, desc, l, r, glow, runes) in enumerate(panels):
        px = 35 + i * 435
        cx = px + 212
        body += rect(px, 130, 425, 620, "#f3ead8", "#d8cfc0", 2, 18)
        body += pill(cx, 178, name, 20)
        body += altar(cx, 360, s, l, r, beam_glow=glow, runes=runes, rune_size=40)
        body += lines_of_text(cx, 668, wrap(desc, 40), 16)
        lpx, rpx, py = cx - BEAM_L * s, cx + BEAM_L * s, 360 + 150 * s
        if i == 0:
            body += gem(lpx + 30, py - 70, 9, "amber") + finger(lpx + 40, py - 52, 0.75, -15)
        if i == 1:
            body += gem(lpx + 30, py - 120, 9) + gem(rpx + 10, py - 120, 9) + notes(cx - 12, py - 150, 1.1, FAIR)
            body += line(lpx + 30, py - 40, lpx + 30, py - 100, FAIR, 3, 1, "green")
            body += line(rpx + 10, py - 40, rpx + 10, py - 100, FAIR, 3, 1, "green")
        if i == 3:
            body += circle(lpx - 34, py - 30, 44, "url(#glow-gold)")
            body += glimmer(lpx + 40, py - 150, 1.0, GLIMMER_COLOURS[0], "fox", True, True)
            body += notes(lpx + 90, py - 190, 1.0)
            for k, (gx, gy) in enumerate(gem_spots(rpx, py - 6 * s, 4, 12 * s)):
                body += text(gx, gy - 22, str(k + 1), 16, "middle", "bold", TRIM_DARK)
    # the refused move
    body += rect(40, 780, 1100, 260, "#fff1ee", "#f0c4bd", 2, 18)
    body += pill(240, 826, "Not fair: one pan only", 20, REFUSE)
    body += altar(300, 920, 0.33, {"crystals": 1, "gems": 2, "glow": "red"}, {"gems": 7}, plinth=False, beam_glow="red")
    body += gem(225, 880, 6) + curve_arrow(222, 872, 200, 850, 214, 905, REFUSE, 3, "red")
    body += rattle(300, 940, 1.0)
    body += lines_of_text(500, 860, ["A gem taken from the crystal's pan alone, then the crystal tapped:",
                                     "the chains rattle softly, the gem springs back, nothing changes.",
                                     "Hoot: \"The altar wants fair moves. The same on both pans!\"",
                                     "Carrying a gem across to the other pan is refused the same way."],
                          18, "start")
    body += rect(1170, 780, 590, 260, "#eef8f0", "#bfe3c8", 2, 18)
    body += pill(1465, 826, "Why the beam is held", 20, "#2f7a4a")
    body += lines_of_text(1195, 870, ["A free-swinging beam would show which pan is heavier,",
                                      "and a child could find the crystal by weighing it",
                                      "(lift things off until it looks level): no algebra.",
                                      "The frozen crystal's chains hold the beam level, so",
                                      "the only way to free it is to keep the balance."], 17, "start")
    return svg(W, H, body, common_defs())


# --- 04: the Entrance Hall, the phase B slice, as a map -----------------------------------------------------------------
HALL_ALTARS = [
    ("1", "T", "x + 2 = 5", "the ghost shows a twin move", "0:20"),
    ("2", "T", "x + 3 = 7", "the trap: one pan only is refused", "0:55"),
    ("3", "J", "x + a = b", "take the gems off both pans", "1:20"),
    ("4", "J", "b = x + a", "the crystal on the right pan", "1:45"),
    ("5", "T", "2x = 6", "the ghost shows the sharing bowls", "2:10"),
    ("6", "J", "c x = b", "share by the crystal count", "2:40"),
    ("7", "J", "x + a = b", "mixed: which move undoes it?", "3:05"),
    ("8", "J", "b = c x", "mixed, the crystal on the right", "3:30"),
    ("9", "J", "b = x + a", "mixed", "3:55"),
    ("10", "J", "c x = b", "mixed", "4:20"),
    ("11", "J", "2x + 1 = 7", "the Great Altar: take, then share", "4:50"),
]


def _top_altar(x, y, s, big=False, done=False):
    """An altar seen from above: the beam, two pans, the pillar."""
    out = circle(x, y, 46 * s, "url(#glow-gold)") if done else ""
    out += line(x - 34 * s, y, x + 34 * s, y, TRIM_DARK, 8 * s) + line(x - 34 * s, y, x + 34 * s, y, TRIM, 5 * s)
    for dx in (-36, 36):
        out += circle(x + dx * s, y, 17 * s, BRONZE_LIGHT, BRONZE_DARK, 2.5)
    out += poly(crystal_points(x - 36 * s, y + 9 * s, 18 * s), ICE, ICE_DARK, 1.5)
    out += circle(x, y, 8 * s, STONE, STONE_DARK, 2)
    if big:
        out += circle(x, y, 70 * s, "none", TRIM_DARK, 3, 0.6)
    return out


def pic_hall():
    W, H = 1800, 1160
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Entrance Hall: the first six minutes",
                      "Eleven altars: three teach (the ghost shows, nothing is judged), eight are judged, the last is the "
                      "Great Altar under the chandelier")
    cx, cy, R = 560, 640, 400
    body += circle(cx, cy, R + 30, "#e8dcc4", STONE_DARK, 3)
    body += circle(cx, cy, R - 40, "url(#hall-floor)", STONE_DARK, 2)
    for k in range(8):
        a = math.radians(k * 45)
        body += line(cx + math.cos(a) * 120, cy + math.sin(a) * 120, cx + math.cos(a) * (R - 40), cy + math.sin(a) * (R - 40),
                     STONE_SHADE, 2)
    body += circle(cx, cy, 120, "none", STONE_SHADE, 2)
    # the great door at the top, the entrance at the bottom
    body += rect(cx - 60, cy - R - 46, 120, 40, "#9a7b52", INK, 3, 10) + text(cx, cy - R - 60, "the great door", 16, "middle", "bold", SOFT_INK)
    body += rect(cx - 60, cy + R + 8, 120, 34, "#ffffff", STONE_DARK, 2, 8) + text(cx, cy + R + 64, "the entrance", 16, "middle", "bold", SOFT_INK)
    # the ring: clock positions 7..11 then 1..5 (the left side up, the right side down)
    clock = [7, 8, 9, 10, 11, 1, 2, 3, 4, 5]
    pts = []
    for i, c in enumerate(clock):
        a = math.radians(c * 30 - 90)
        pts.append((cx + math.cos(a) * (R - 95), cy + math.sin(a) * (R - 95), a))
    # the walk
    walk = [(cx, cy + R - 10)] + [(x, y) for x, y, _ in pts] + [(cx, cy + 40)]
    d = "M" + " L".join(f"{x:.0f},{y:.0f}" for x, y in walk)
    body += path(d, "none", "#9fb4c2", 3, 0.9, extra='stroke-dasharray="3 9"')
    for i, (x, y, a) in enumerate(pts):
        num, kind, eq, what, t = HALL_ALTARS[i]
        body += _top_altar(x, y, 1.0, done=False)
        colour = "#5b6b74" if kind == "T" else "#2a6f9a"
        body += circle(x + 30, y - 30, 15, colour) + text(x + 30, y - 24, num, 15, "middle", "bold", "#ffffff")
        body += text(x, y + 38, eq, 15, "middle", "bold", colour)
    # the Great Altar under the chandelier
    body += chandelier(cx, cy - 6, 150, 10, 11)
    body += _top_altar(cx, cy + 40, 1.6, big=True)
    body += circle(cx + 52, cy + 4, 17, "#2a6f9a") + text(cx + 52, cy + 10, "11", 15, "middle", "bold", "#ffffff")
    body += text(cx, cy + 165, "the Great Altar: 2x + 1 = 7", 17, "middle", "bold", "#2a6f9a")
    body += avatar(cx - 30, cy + R + 4, 0.9) + hoot(cx + 30, cy + R, 0.6)
    # the list
    lx0 = 1110
    body += card(lx0, 140, 650, 980)
    body += text(lx0 + 30, 186, "In order", 22, "start", "bold")
    for i, (num, kind, eq, what, t) in enumerate(HALL_ALTARS):
        y = 236 + i * 74
        colour = "#5b6b74" if kind == "T" else "#2a6f9a"
        body += circle(lx0 + 46, y - 6, 17, colour) + text(lx0 + 46, y, num, 15, "middle", "bold", "#ffffff")
        body += text(lx0 + 78, y, f"{kind}  {eq}", 19, "start", "bold", colour)
        body += text(lx0 + 300, y, t, 16, "start", "normal", SOFT_INK)
        body += text(lx0 + 78, y + 24, what, 16, "start", "normal", INK)
    body += text(lx0 + 30, 1060, "T: taught (the ghost shows; not judged)", 16, "start", "normal", "#5b6b74")
    body += text(lx0 + 30, 1086, "J: judged (one SkillShown event for g6.maths.equations)", 16, "start", "normal", "#2a6f9a")
    body += note(900, 1146, "Numbers are new every visit (the crystal weighs 1-8; at most 12-15 gems on a pan). "
                 "5:40: the chandelier blazes, the door opens onto the Sky Room.", 16)
    return svg(W, H, body, common_defs())


# --- 05: the Sky Room, the transfer ---------------------------------------------------------------------------------------
def pic_sky():
    W, H = 1800, 1060
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Sky Room: where the old habit fails",
                      "A balloon pulls its pan up. Beside the crystal there is a balloon, and no balloon on the other pan "
                      "to take: what frees it?")
    # the scene
    body += rect(40, 130, 560, 860, "url(#sky-high)", "#c9d6de", 2, 22)
    for (x, y, sc) in ((140, 220, 0.7), (480, 190, 0.5), (420, 310, 0.4)):
        body += cloud(x, y, sc, "#ffffff", 0.9)
    body += ellipse(320, 860, 250, 50, "#ffffff", "#c9d6de", 2)
    for k in range(5):
        body += cloud(150 + k * 85, 880 + (k % 2) * 12, 0.7, "#ffffff", 0.95)
    body += altar(320, 520, 0.62, {"crystals": 1, "balloons": 3}, {"gems": 5}, plinth=False,
                  runes=None)
    body += gem_bag(150, 845, 0.9) + pump(480, 850, 0.8)
    body += hoot(110, 470, 0.8, True)
    body += speech(150, 330, 290, ["Balloons pull pans up.", "Gems pull them down."], 17)
    body += rune_plaque(320, 760, ["C", "−", "3", "=", "5"], 30)
    body += note(320, 970, "x − 3 = 5: the crystal and three balloons weigh the same as five gems", 15)
    # the habit
    body += rect(630, 130, 540, 860, "#fff1ee", "#f0c4bd", 2, 22)
    body += pill(900, 182, "The hall's habit: take it away", 20, REFUSE)
    body += altar(900, 420, 0.6, {"crystals": 1, "balloons": 3, "balloon_glow": "amber"}, {"gems": 5}, plinth=False)
    body += cross(1080, 560, 1.2)
    body += lines_of_text(900, 700, ["It lifts a balloon off the crystal's pan:",
                                     "the altar waits for its twin, but the other",
                                     "pan has no balloon. Whatever it does next",
                                     "is refused. Stuck."], 18)
    body += text(900, 870, "frees 0 of 4 balloon altars", 22, "middle", "bold", REFUSE)
    body += text(900, 900, "the model: reaches 5 of 6 in 0 % of 1,000 visits", 16, "middle", "normal", SOFT_INK)
    # the rule
    body += rect(1200, 130, 560, 860, "#eef8f0", "#bfe3c8", 2, 22)
    body += pill(1480, 182, "The rule: the same on both pans", 20, "#2f7a4a")
    body += altar(1480, 400, 0.6, {"crystals": 1, "gems": 3, "balloons": 3, "gem_glow": "green"},
                  {"gems": 8, "gem_glow": "green"}, plinth=False, beam_glow="green")
    body += lines_of_text(1480, 650, ["Put three gems on BOTH pans. Each gem",
                                      "catches a balloon and the pair floats off;",
                                      "the crystal stands alone, the other pan",
                                      "holds eight gems: it weighs eight."], 18)
    body += rune_plaque(1480, 800, ["C", "=", "8"], 30)
    body += tick(1680, 560, 1.2)
    body += text(1480, 900, "the model: reaches 5 of 6 in 100 % of 1,000 visits", 16, "middle", "normal", SOFT_INK)
    return svg(W, H, body, common_defs())


# --- 06: the core loop -----------------------------------------------------------------------------------------------------
def pic_loop():
    W, H = 1500, 1080
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The core loop", "Every 10 seconds a fair move, every minute a crystal freed, every 10 minutes a hall "
                      "lit, across days the temple's wings")
    cx, cy = 540, 590
    for r, fill in ((430, "#e7f2dc"), (320, "#d6ecf7"), (215, "#fff1c9"), (110, "#ffe0d6")):
        body += circle(cx, cy, r, fill, "#b9c6cc", 3)

    def at(radius, deg):
        a = math.radians(deg)
        return cx + math.cos(a) * radius, cy + math.sin(a) * radius

    for r_mid in (162, 267, 375):
        x1, y1 = at(r_mid, -60)
        x2, y2 = at(r_mid, -30)
        xc, yc = at(r_mid + 18, -45)
        body += curve_arrow(x1, y1, xc, yc, x2, y2, INK, 3)
    body += pill(cx, cy - 66, "10 s: a fair move", 15, "#c0563b")
    body += gem(cx - 40, cy + 6, 13) + gem(cx + 40, cy + 6, 13) + vr_hand(cx - 62, cy + 30, 0.45, 20) + vr_hand(cx + 62, cy + 30, 0.45, -20)
    body += text(cx, cy + 62, "one off each pan", 14, "middle", "bold")
    body += pill(cx, cy - 162, "1 min: a crystal freed", 15, "#b07d00")
    x, y = at(162, 205)
    body += crystal(x, y + 24, 44, "frozen", True)
    x, y = at(162, 150)
    body += _top_altar(x, y, 0.7)
    x, y = at(162, 95)
    body += glimmer(x + 8, y + 18, 0.6, GLIMMER_COLOURS[0], "fox", True, True)
    x, y = at(162, 35)
    body += gem(x - 12, y, 7) + gem(x, y, 7) + gem(x + 12, y, 7) + text(x, y - 14, "= 3", 14, "middle", "bold")
    body += pill(cx, cy - 267, "10 min: a hall lit", 15, "#2a6f9a")
    x, y = at(267, 210)
    body += chandelier(x, y + 6, 34, 3, 8)
    x, y = at(267, 150)
    body += chandelier(x, y + 6, 34, 8, 8)
    x, y = at(267, 95)
    body += path(f"M{x - 22},{y + 22} L{x - 22},{y - 8} Q{x},{y - 30} {x + 22},{y - 8} L{x + 22},{y + 22} z", "#ffe9a8", INK, 2.5)
    body += circle(x, y, 30, "url(#glow-gold)")
    x, y = at(267, 30)
    body += text(x, y + 6, "♪ ♪ ♪", 22, "middle", "bold", TRIM_DARK)
    body += pill(cx, cy - 375, "days: the temple's wings", 15, "#2f6b2f")
    for k, deg in enumerate((125, 105, 85, 65)):
        x, y = at(375, deg)
        body += circle(x, y, 24, "#ffffff", INK, 2.5) + text(x, y + 7, str(5 + k), 18, "middle", "bold")
    x, y = at(375, 165)
    body += recipe_box(x, y + 30, 0.55, 2, 2)
    x, y = at(375, 205)
    body += balloon(x, y - 6, 14, x, y + 26)
    x, y = at(375, 25)
    body += mirror_tool(x, y + 12, 0.6)
    x, y = at(375, -15)
    body += swap_seal(x, y, 0.8)
    lx = 1010
    body += card(lx, 170, 450, 820)
    rows = [("10 s", "#c0563b", "one fair move with the hands: the same off both pans, shared out, or put on both; the "
                                "altar answers at once (a chime, the chains glow; or they rattle and it springs back)"),
            ("1 min", "#b07d00", "one altar: the crystal freed, its Glimmer wakes and sings, the gems count its weight "
                                 "aloud, the rune line shows it"),
            ("10 min", "#2a6f9a", "one hall: the chandelier fills, the Glimmers sing their tune together, the great door "
                                  "opens onto the next room"),
            ("days", "#2f6b2f", "a wing a grade: the Recipe Kitchen (5), the Hall and the Sky Room (6), the Mirror Halls "
                                "(7), the Twin Altars and the Star Floor (8); your own altar for a friend (phase D)")]
    for i, (k, colour, v) in enumerate(rows):
        yy = 230 + i * 190
        body += text(lx + 30, yy, k, 28, "start", "bold", colour)
        body += lines_of_text(lx + 30, yy + 36, wrap(v, 40), 17, "start")
    body += note(W / 2, H - 22, "Never timed, never lost: an altar waits as long as the child thinks; a refused move "
                 "changes nothing.", 18)
    return svg(W, H, body, common_defs())


# --- 07: the ladder ---------------------------------------------------------------------------------------------------------
def pic_ladder():
    W, H = 1800, 1180
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The ladder: a wing of the temple for each grade",
                      "The same verb all the way (keep the balance); new tools each year; the pictures fade into numbers "
                      "and letters")
    wings = [
        ("5", "The Recipe Kitchen", "#f6d9c4", ["recipe boxes: what is in one", "compartment is in all;",
                                                "brackets are a box's walls"],
         ["g5 expressions (5.OA.1-2)"], ["the market scale"]),
        ("6", "The Hall of Frozen Crystals", "#d6ecf7", ["take and share on both pans;", "balloons; the leaning altar;",
                                                         "breathing crystals; the rule"],
         ["g6 equations, equivalent", "expressions, exponents,", "variables (6.EE.1-9)"], ["the Sky Room (phase B)", "the fog altar"]),
        ("7", "The Mirror Halls", "#e7dcff", ["two moves; crystal balloons;", "the Mirror flips gems and",
                                              "balloons (and the tip)"],
         ["g7 equations, expressions,", "inequalities (7.EE.1-4)"], ["the wind garden's mobiles", "the rocket's scale"]),
        ("8", "The Twin Altars and the Star Floor", "#dff2dc", ["crystals on both pans; one,", "none or many; two crystal kinds;",
                                                                "the swap seal; crystal tiles"],
         ["g8 linear equations, systems,", "expand and factorise"], ["twin crystals in the fog", "the star map"]),
    ]
    for i, (grade, name, fill, verbs, units, transfer) in enumerate(wings):
        x = 60 + i * 425
        y = 570 - i * 95
        h = 400
        body += rect(x, y, 400, h, fill, "#b9c6cc", 3, 14)
        body += circle(x + 44, y + 44, 30, "#ffffff", INK, 3) + text(x + 44, y + 54, grade, 28, "middle", "bold")
        body += lines_of_text(x + 88, y + 40, wrap(name, 24), 21, "start", "bold")
        yy = y + 112
        body += text(x + 20, yy, "verbs", 15, "start", "bold", SOFT_INK)
        body += lines_of_text(x + 20, yy + 24, verbs, 16, "start")
        body += text(x + 20, yy + 104, "units", 15, "start", "bold", SOFT_INK)
        body += lines_of_text(x + 20, yy + 128, units, 15, "start", "normal", INK)
        body += text(x + 20, yy + 200, "transfer rooms", 15, "start", "bold", SOFT_INK)
        body += lines_of_text(x + 20, yy + 224, transfer, 15, "start", "normal", "#2f6b2f")
        # a small picture of the wing
        if i == 0:
            body += recipe_box(x + 300, y - 20, 0.75, 3, 2)
        elif i == 1:
            body += altar(x + 300, y - 110, 0.22, {"crystals": 2, "gems": 1}, {"gems": 7}, plinth=False)
        elif i == 2:
            body += mirror_tool(x + 250, y - 20, 0.8) + crystal_balloon(x + 330, y - 60, 50, x + 330, y - 4)
        else:
            body += altar(x + 210, y - 100, 0.16, {"crystals": 2, "gems": 1}, {"crystals": 1, "gems": 4}, plinth=False)
            body += altar(x + 330, y - 100, 0.16, {"crystals": 1}, {"crystals": 1, "gems": 3}, plinth=False)
    # the fade along the bottom
    body += rect(60, 1010, 1690, 130, "#ffffff", "#d0d8dc", 2, 14)
    body += text(90, 1046, "The fade (concreteness fading): the same altar, seen more abstractly as the child grows", 18,
                 "start", "bold")
    stages = [(["C", "+", "G3", "=", "G7"], "pictures: count the gems"), (["C", "+", "3", "=", "7"], "numbers on the runes"),
              (["x", "+", "3", "=", "7"], "the crystal's rune becomes x"), (["x + 3 = 7"], "runes only: the pans in mist")]
    for k, (toks, label) in enumerate(stages):
        x = 280 + k * 410
        body += rune_plaque(x, 1092, toks, 26)
        body += text(x, 1132, label, 15, "middle", "normal", SOFT_INK, True)
        if k < 3:
            body += line(x + 120, 1088, x + 270, 1088, "#9fb4c2", 3, 1, "grey")
    return svg(W, H, body, common_defs())


# --- 08: things and colours --------------------------------------------------------------------------------------------------
def pic_things():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Things and what they mean", "Every thing in the temple is a piece of algebra; shape and motion "
                      "carry each meaning too, never colour alone")
    items = [
        ("a frozen crystal", "the unknown, x: one weight", "we don't know yet", lambda x, y: crystal(x, y + 40, 80, "frozen", True)),
        ("a breathing crystal", "a variable: any weight;", "it grows and shrinks", lambda x, y: crystal(x, y + 40, 80, "breathing", False)),
        ("a freed crystal", "x's value: the other pan", "shows what it weighs", lambda x, y: crystal(x, y + 40, 80, "freed", False)),
        ("a gem", "+1 (in rows of five)", "", lambda x, y: gem(x - 26, y, 14) + gem(x, y, 14) + gem(x + 26, y, 14)),
        ("a number gem (grade 7)", "one gem that carries", "its number: +7", lambda x, y: number_gem(x, y, 26, 7)),
        ("a balloon", "−1: it pulls its pan up;", "a gem and a balloon cancel", lambda x, y: balloon(x, y - 10, 22, x, y + 40)),
        ("a crystal balloon (7)", "−x: lifts as much", "as a crystal weighs", lambda x, y: crystal_balloon(x, y + 10, 64, x, y + 44)),
        ("a recipe box", "k × ( ): what is in one", "compartment is in all", lambda x, y: recipe_box(x, y + 44, 0.7, 3, 2)),
        ("sharing bowls", "split both pans into n", "equal shares, keep one", lambda x, y: bowls(x - 80, y + 20, 4, 0.9)),
        ("the gem bag", "put the same on", "both pans", lambda x, y: gem_bag(x, y + 40, 0.8)),
        ("the balloon pump", "put balloons on", "both pans", lambda x, y: pump(x - 10, y + 44, 0.65)),
        ("the Mirror (7)", "× (−1): gems become", "balloons and back", lambda x, y: mirror_tool(x, y + 10, 0.8)),
        ("the swap seal (8)", "substitution: swap a crystal", "for what its twin altar shows", lambda x, y: swap_seal(x, y, 1.1)),
        ("crystal tiles (8)", "x², x and 1 as tiles:", "rectangles multiply", lambda x, y: (rect(x - 60, y - 30, 56, 56, ICE, ICE_DARK, 2, 4)
                                                                                   + rect(x + 4, y - 30, 16, 56, ICE_MID, ICE_DARK, 2, 3)
                                                                                   + rect(x + 26, y + 10, 16, 16, GEM, GEM_DARK, 2, 3))),
        ("the rune line", "the equation, carved; it", "changes with every move", lambda x, y: rune_plaque(x, y + 6, ["C", "+", "3", "=", "7"], 22)),
        ("the glows", "amber: waiting for a twin; green:", "fair; a soft red shimmer: refused",
         lambda x, y: circle(x - 40, y, 18, WAIT) + circle(x, y, 18, FAIR) + circle(x + 40, y, 18, REFUSE)),
    ]
    cols = 4
    for i, (name, l1, l2, draw) in enumerate(items):
        r, c = divmod(i, cols)
        x = 60 + c * 430
        y = 130 + r * 240
        body += card(x, y, 410, 222)
        body += draw(x + 205, y + 78)
        body += text(x + 205, y + 160, name, 18, "middle", "bold")
        body += text(x + 205, y + 184, l1, 15, "middle", "normal", SOFT_INK)
        if l2:
            body += text(x + 205, y + 204, l2, 15, "middle", "normal", SOFT_INK)
    return svg(W, H, body, common_defs())


# --- 09: VR ------------------------------------------------------------------------------------------------------------------
def pic_vr():
    W, H = 1800, 860
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("In VR the hands do the algebra", "Both hands, both pans: the gesture that helps learning last "
                      "(Cook, Mitchell & Goldin-Meadow 2008); the altar comes to the child, who stands still")
    panels = [("Both hands, both pans", "each hand lifts a gem off its own pan at the same time; the two vanish with a "
                                        "chime and a buzz in both hands"),
              ("Share", "pull bowls from the rack (one pull, one bowl), then press the altar's seal; the pans sort "
                        "themselves into the bowls"),
              ("Put the same on both", "in the Sky Room take a gem from the bag in each hand and drop one on each pan; "
                                       "gem and balloon float off together")]
    for i, (name, desc) in enumerate(panels):
        px = 40 + i * 590
        body += rect(px, 130, 560, 620, "url(#sky-dusk)", "#d8cfc0", 3, 20)
        body += pill(px + 280, 182, name, 22)
        if i == 0:
            body += altar(px + 280, 330, 0.5, {"crystals": 1, "gems": 2}, {"gems": 6}, plinth=False, beam_glow="green")
            body += vr_hand(px + 150, 470, 1.15, -15) + gem(px + 150, 430, 10)
            body += vr_hand(px + 410, 470, 1.15, 15) + gem(px + 410, 430, 10)
            body += line(px + 150, 520, px + 150, 600, "#ffffff", 4, 0.9) + line(px + 410, 520, px + 410, 600, "#ffffff", 4, 0.9)
            body += notes(px + 270, 440, 1.1, FAIR)
        elif i == 1:
            body += altar(px + 280, 320, 0.5, {"crystals": 3}, {"gems": 9}, plinth=False)
            body += bowls(px + 140, 610, 3, 1.2, 3)
            body += vr_hand(px + 380, 560, 1.15, -40) + line(px + 330, 610, px + 280, 610, "#ffffff", 4, 0.9, "white")
        else:
            body += altar(px + 280, 330, 0.5, {"crystals": 1, "gems": 2, "balloons": 2}, {"gems": 7}, plinth=False)
            body += vr_hand(px + 140, 450, 1.1, -10) + gem(px + 140, 410, 10)
            body += vr_hand(px + 420, 450, 1.1, 10) + gem(px + 420, 410, 10)
            body += gem_bag(px + 280, 640, 0.9)
        body += lines_of_text(px + 280, 790, wrap(desc, 56), 16)
    return svg(W, H, body, common_defs())


# --- 10: the fade --------------------------------------------------------------------------------------------------------
def pic_fade():
    W, H = 1800, 900
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The fade: from gems to x", "One altar, 3x + 2 = 14, as it looks at each stage; the voice reads "
                      "the rune line, and every rune says its name when touched")
    stages = [
        ("Pictures", "grades 5-6", {"crystals": 3, "gems": 2}, {"gems": 14}, ["C3", "+", "G2", "=", "G14"],
         "count the gems; Hoot: \"Three crystals and two gems weigh fourteen gems.\""),
        ("Numbers", "grade 6", {"crystals": 3, "gems": 2, "numerals": True}, {"gems": 14, "numerals": True}, ["C3", "+", "2", "=", "14"],
         "number gems carry their numbers"),
        ("Letters", "grade 7", {"crystals": 3, "gems": 2, "numerals": True, "letter": "x"},
         {"gems": 14, "numerals": True}, ["3x", "+", "2", "=", "14"], "the crystal's rune is x; Hoot: \"Three x plus two equals fourteen.\""),
        ("Runes only", "grades 7-8", None, None, ["3x + 2 = 14"], "the pans are in mist; the same fair moves on the runes"),
    ]
    for i, (name, grade, l, r, runes, desc) in enumerate(stages):
        px = 40 + i * 435
        body += rect(px, 130, 415, 680, "#f3ead8", "#d8cfc0", 2, 18)
        body += pill(px + 207, 180, name, 22)
        body += text(px + 207, 222, grade, 16, "middle", "normal", SOFT_INK)
        if l is not None:
            body += altar(px + 207, 330, 0.58, l, r, plinth=False)
        else:
            body += rect(px + 30, 260, 355, 260, "url(#fog)", "#c9d6de", 2, 20, 0.95)
            for k in range(6):
                body += cloud(px + 80 + (k % 3) * 120, 330 + (k // 3) * 110, 0.6, "#ffffff", 0.8)
            body += rune_plaque(px + 230, 575, ["3x + 2 = 14"], 28)
            body += rune_plaque(px + 230, 645, ["3x = 12"], 28)
            body += rune_plaque(px + 230, 715, ["x = 4"], 28)
            body += text(px + 24, 616, "−2 on both", 14, "start", "bold", "#2f7a4a")
            body += text(px + 24, 686, "÷3 on both", 14, "start", "bold", "#2f7a4a")
        if l is not None:
            body += rune_plaque(px + 207, 640, runes, 30)
        body += lines_of_text(px + 207, 760, wrap(desc, 44), 15)
    body += note(900, 860, "The pace adapts: the grade sets the first stage; three altars freed in a row without help "
                 "bring the next one (two helped in a row, back one). The Book always shows the symbols.", 16)
    return svg(W, H, body, common_defs())


# --- 11: the later altars ------------------------------------------------------------------------------------------------
def pic_later():
    W, H = 1800, 1000
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Later wings: the same verb, deeper ideas",
                      "A crystal that breathes (variables and equivalent expressions), the Mirror (inequalities), twin "
                      "altars (systems)")
    # (a) breathing crystal
    px = 40
    body += rect(px, 130, 560, 820, "#eef6fb", "#c9dbe6", 2, 18)
    body += pill(px + 280, 180, "The breathing crystal (6-7)", 20, "#2a6f9a")
    body += lines_of_text(px + 280, 222, ["left pan: a recipe box 3 × [crystal + 4 gems];",
                                         "the child builds the right pan, pulls the lever,",
                                         "and the crystal breathes through sizes 2, 5 and 8"], 15)
    body += recipe_box(px + 280, 400, 1.0, 3, 4)
    # left minus right at sizes 2, 5, 8: 3(x + 4) against each build
    rows = [("3 crystals + 12 gems", [0, 0, 0], True), ("3 crystals + 4 gems", [8, 8, 8], False),
            ("7 crystals", [4, -8, -20], False)]
    for k, (label, diffs, ok) in enumerate(rows):
        y = 470 + k * 110
        body += text(px + 30, y + 10, label, 17, "start", "bold")
        for j, (size, dlt) in enumerate(zip((2, 5, 8), diffs)):
            x = px + 300 + j * 80
            tilt = max(-14, min(14, -dlt))
            a = math.radians(tilt)
            body += line(x - 30 * math.cos(a), y - 30 * math.sin(a), x + 30 * math.cos(a), y + 30 * math.sin(a), TRIM_DARK, 6)
            body += poly([(x, y), (x - 8, y + 18), (x + 8, y + 18)], STONE_SHADE, STONE_DARK, 1.5)
            body += text(x, y + 40, f"size {size}", 12, "middle", "normal", SOFT_INK)
        body += (tick if ok else cross)(px + 525, y + 4, 0.9)
    body += lines_of_text(px + 280, 810, ["only the equivalent pan stays level at every size",
                                         "(7 crystals balance it at size 3 alone: one solution);",
                                         "Küchemann's 'which is larger, 2n or n + 2?' (6 % right",
                                         "at 14) is an altar that tips, levels, then tips back"], 15)
    # (b) the Mirror and the leaning altar
    px = 620
    body += rect(px, 130, 560, 820, "#f6f0ff", "#d9cdf2", 2, 18)
    body += pill(px + 280, 180, "The leaning altar and the Mirror (7)", 20, "#6a4fc4")
    body += lines_of_text(px + 280, 222, ["−2x + 5 > 11: the see-saw stays tipped, left pan down;",
                                         "take five gems off both: −2x > 6, still left down"], 15)
    body += altar(px + 150, 330, 0.36, {"cballoons": 2}, {"gems": 6}, tilt=-10, plinth=False)
    body += mirror_tool(px + 300, 360, 0.8)
    body += line(px + 340, 340, px + 380, 340, INK, 3, 1, "ink")
    body += altar(px + 450, 330, 0.36, {"crystals": 2, "frozen": False, "state": "breathing", "glimmer": False},
                  {"balloons": 6}, tilt=10, plinth=False)
    body += lines_of_text(px + 280, 560, ["the Mirror turns every gem into a balloon and back:",
                                         "the heavier pan becomes the lighter, the tip flips",
                                         "(now right down): 2x < −6; share by two: x < −3"], 15)
    body += number_line(px + 60, 700, px + 500, -6, 2, -3, "<", -3, False, 14)
    body += lines_of_text(px + 280, 780, ["the floor lights the answer: every size below −3",
                                         "(a floaty crystal); the stone at −3 stays dark",
                                         "because > never counts level"], 15)
    # (c) twin altars
    px = 1200
    body += rect(px, 130, 560, 820, "#eef8f0", "#bfe3c8", 2, 18)
    body += pill(px + 280, 180, "Twin altars and the swap seal (8)", 20, "#2f7a4a")
    body += lines_of_text(px + 280, 222, ["blue + rose = 9 gems, and blue = rose + 3 gems:",
                                         "no fair move on one altar alone frees either"], 15)
    body += altar(px + 150, 300, 0.3, {"crystals": 1, "crystals2": 1}, {"gems": 9}, plinth=False)
    body += altar(px + 420, 300, 0.3, {"crystals": 1}, {"crystals2": 1, "gems": 3}, plinth=False)
    body += swap_seal(px + 285, 470, 1.0)
    body += lines_of_text(px + 280, 540, ["the swap seal: a blue crystal may be swapped for",
                                         "what the other altar shows it weighs (rose + 3):",
                                         "2 rose + 3 = 9, so rose = 3 and blue = 6"], 15)
    # the star floor
    gx0, gy0, cell = px + 120, 905, 30
    for k in range(10):
        body += line(gx0 + k * cell, gy0, gx0 + k * cell, gy0 - 9 * cell, "#cfe3d3", 1.5)
        body += line(gx0, gy0 - k * cell, gx0 + 9 * cell, gy0 - k * cell, "#cfe3d3", 1.5)
    body += line(gx0, gy0 - 9 * cell, gx0 + 9 * cell, gy0, WAIT, 4)                     # blue + rose = 9
    body += line(gx0 + 3 * cell, gy0, gx0 + 9 * cell, gy0 - 6 * cell, "#6a4fc4", 4)       # blue = rose + 3
    body += circle(gx0 + 6 * cell, gy0 - 3 * cell, 10, INK) + avatar(gx0 + 6 * cell + 22, gy0 - 3 * cell + 12, 0.45)
    body += text(gx0 + 9 * cell + 14, gy0 - 8 * cell, "the Star Floor:", 14, "start", "bold")
    body += text(gx0 + 9 * cell + 14, gy0 - 8 * cell + 20, "east: blue's weight,", 14, "start")
    body += text(gx0 + 9 * cell + 14, gy0 - 8 * cell + 40, "north: rose's;", 14, "start")
    body += text(gx0 + 9 * cell + 14, gy0 - 8 * cell + 60, "stand where both", 14, "start")
    body += text(gx0 + 9 * cell + 14, gy0 - 8 * cell + 80, "altars level: (6, 3)", 14, "start")
    return svg(W, H, body, common_defs())


# --- 12: the cheat test, from the models ----------------------------------------------------------------------------------
def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, "model", name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _rates(mod, rooms, n):
    R = mod.R
    out = []
    for name, bot in mod.PLAYERS:
        visits = [mod.visit(bot, seed) for seed in range(n)]
        solved = [sum(1 for v in vv if v[1].outcome() == R.SOLVED) for vv in visits]
        out.append((name, 100.0 * sum(1 for sv in solved if R.mastered(sv, rooms)) / n))
    return out


KNOWS = {"knows the rule", "knows it, slips 4 %", "keeps balance, greedy"}
CHART = {"surface": "#fcfcfb", "ink": "#0b0b0b", "ink2": "#52514e", "muted": "#898781", "grid": "#e1e0d9",
         "axis": "#c3c2b7", "accent": "#2a78d6", "rest": "#b4b2a9"}


def _bars(x0, y0, w, rows, title, subtitle):
    """One small multiple: horizontal bars, 0-100 % on one shared axis (dataviz: emphasis, thin bars, hairline grid)."""
    out = text(x0, y0, title, 22, "start", "bold", CHART["ink"])
    out += text(x0, y0 + 26, subtitle, 15, "start", "normal", CHART["ink2"])
    label_w = 300
    bx0, bw = x0 + label_w, w - label_w - 70
    top = y0 + 60
    row_h = 38
    for t in (0, 25, 50, 75, 100):
        x = bx0 + bw * t / 100
        out += line(x, top - 6, x, top + row_h * len(rows), CHART["grid"], 1)
        out += text(x, top + row_h * len(rows) + 22, f"{t} %", 13, "middle", "normal", CHART["muted"])
    out += line(bx0, top - 6, bx0, top + row_h * len(rows), CHART["axis"], 1)
    for k, (name, value) in enumerate(rows):
        y = top + k * row_h + row_h / 2
        colour = CHART["accent"] if name in KNOWS else CHART["rest"]
        out += text(bx0 - 12, y + 5, name, 15, "end", "normal", CHART["ink"])
        length = bw * value / 100
        if length >= 4:
            out += path(f"M{bx0:.1f},{y - 9:.1f} L{bx0 + length - 4:.1f},{y - 9:.1f} Q{bx0 + length:.1f},{y - 9:.1f} "
                        f"{bx0 + length:.1f},{y - 5:.1f} L{bx0 + length:.1f},{y + 5:.1f} Q{bx0 + length:.1f},{y + 9:.1f} "
                        f"{bx0 + length - 4:.1f},{y + 9:.1f} L{bx0:.1f},{y + 9:.1f} z", colour, None, 0)
        elif value > 0:
            out += rect(bx0, y - 9, 2, 18, colour, None, 0, 0)
        label = f"{value:.1f} %".replace(".0 %", " %")
        out += text(bx0 + length + 8, y + 5, label, 14, "start", "bold" if name in KNOWS else "normal", CHART["ink2"])
    return out


def pic_cheat():
    hall = _load("hall_model")
    sky = _load("sky_room_model")
    n = 1000
    hall_rows = _rates(hall, len(hall.HALL), n)
    sky_rows = _rates(sky, len(sky.SKY), n)
    W, H = 1800, 860
    body = rect(0, 0, W, H, CHART["surface"])
    body += title_bar("The cheat test: only the knowledge wins",
                      f"Share of {n:,} visits that reach the mastery bar (5 of every 6 judged altars freed with no rule "
                      "break, no help, within the move budget)")
    body += rect(40, 112, 18, 12, CHART["accent"], None, 0, 3) + text(66, 123, "players who know the rule", 15, "start", "normal", CHART["ink2"])
    body += rect(300, 112, 18, 12, CHART["rest"], None, 0, 3) + text(326, 123, "players who try without it", 15, "start", "normal", CHART["ink2"])
    body += _bars(40, 170, 860, hall_rows, "The Entrance Hall (phase B)", "eight judged altars; the bar is 7 of 8")
    body += _bars(920, 170, 860, sky_rows, "The Sky Room (the transfer)", "six judged altars with balloons; the bar is 5 of 6")
    body += note(W / 2, H - 26, "From model/hall_model.py and model/sky_room_model.py. 'Weighs (free beam)' is a beam we do "
                 "not build: it shows why the frozen crystal's chains hold the beam level.", 15)
    return svg(W, H, body, "")


PICTURES = [("01-the-temple", pic_temple), ("02-one-altar", pic_altar), ("03-the-twin-move", pic_twin),
            ("04-the-hall", pic_hall), ("05-the-sky-room", pic_sky), ("06-core-loop", pic_loop),
            ("07-the-ladder", pic_ladder), ("08-things-and-meanings", pic_things), ("09-vr", pic_vr),
            ("10-the-fade", pic_fade), ("11-later-wings", pic_later), ("12-cheat-test", pic_cheat)]


def main():
    only = sys.argv[1:]
    for name, fn in PICTURES:
        if only and name not in only:
            continue
        svg_path = os.path.join(HERE, name + ".svg")
        with open(svg_path, "w") as f:
            f.write(fn())
        subprocess.run(["rsvg-convert", "-o", os.path.join(HERE, name + ".png"), svg_path], check=True)
        print("wrote", name)


if __name__ == "__main__":
    main()
