"""The design sketches of Fraction Bakery (docs/design/games/fraction-bakery.md, phase A).

Draws every picture as SVG in the game's blocky, friendly look and renders each to PNG with rsvg-convert:

    /usr/bin/python3 -I docs/design/games/fraction-bakery/make_pictures.py [name ...]

The pictures are sketches for grown-ups (the lead, the owner): their words are labels, not the game's screen (the game
shows no words while an order plays: pictures, and numerals once the child's stage has them). Picture 12's numbers come
from the phase A models (model/opening_night_model.py, model/midnight_model.py), run here at 1,000 visits each.
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
NIGHT = ("#1d2b5a", "#3b3f86", "#7a5c9e", "#e9a77a")      # the sky from the top down at dusk
NIGHT_DEEP = ("#141d40", "#25306a")
WALL, WALL_SHADE = "#fbefd8", "#e8d3ad"                     # the bakery's cream walls
TEAL, TEAL_DARK = "#2bb3a3", "#16786e"                      # EasyCraft's teal: the awning, the brand
ROOF, ROOF_DARK = "#c0563a", "#8a3423"
WOOD, WOOD_DARK, WOOD_LIGHT = "#b07a4a", "#7a4f2a", "#d9a877"
BRASS, BRASS_DARK, BRASS_LIGHT = "#e2b23c", "#9c7414", "#ffe08a"   # the Fair Line, its posts
CRUST, CRUST_DARK, CRUST_LIGHT = "#d99a4e", "#9a5f22", "#f2c27e"   # a pie's crust
FILLING = "#c2415a"                                         # berry: a pie's filling seen from above
FILLING_APPLE = "#e8b84a"
FILLING_LEAF = "#7bbf5a"
LIT, LIT_DARK = "#ffcf4d", "#c98a00"                        # a glowing (ordered) part; a lit lantern
FAIR, REFUSE, WAIT = "#3fbf6b", "#e0473a", "#ffae3b"         # fair; not fair yet; waiting
STEEL, STEEL_DARK, STEEL_LIGHT = "#c9d3da", "#7e8c95", "#eef3f6"
KRAFT, KRAFT_DARK = "#d9b98c", "#a07c4e"                    # a takeaway box
TIN, TIN_DARK = "#b9c3ca", "#6f7d86"
OVEN, OVEN_DARK, FIRE = "#b5654a", "#7a3a28", "#ff8a2a"
HOOT, HOOT_LIGHT = "#8a5a35", "#e2c093"
SKIN, SHIRT, PANTS, HAIR = "#f0c8a0", "#2bb3a3", "#3a5fb0", "#5a3b22"
BUDDY_COLOURS = ["#ff9f43", "#6ec6ff", "#b18cff", "#7bd389", "#ff7eb6", "#ffd166"]
CHART = {"surface": "#fcfcfb", "ink": "#0b0b0b", "ink2": "#52514e", "muted": "#898781", "grid": "#e1e0d9",
         "axis": "#c3c2b7", "accent": "#2a78d6", "rest": "#b4b2a9"}


# --- SVG helpers -----------------------------------------------------------------------------------------------------
def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}{_markers()}{common_defs()}</defs>{body}</svg>')


def _markers():
    out = ""
    for name, colour in (("ink", INK), ("brass", BRASS_DARK), ("grey", "#7a8790"), ("green", FAIR), ("red", REFUSE),
                         ("white", "#ffffff"), ("amber", WAIT), ("teal", TEAL_DARK)):
        out += (f'<marker id="arrow-{name}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" '
                f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{colour}"/></marker>')
    return out


def lin_grad(gid, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def rad_grad(gid, stops):
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return f'<radialGradient id="{gid}">{s}</radialGradient>'


def common_defs():
    return (lin_grad("sky-night", [(0, NIGHT[0]), (0.45, NIGHT[1]), (0.75, NIGHT[2]), (1, NIGHT[3])])
            + lin_grad("sky-deep", [(0, NIGHT_DEEP[0]), (1, NIGHT_DEEP[1])])
            + lin_grad("brass", [(0, BRASS_LIGHT), (0.5, BRASS), (1, BRASS_DARK)])
            + lin_grad("blade", [(0, STEEL_LIGHT), (0.6, STEEL), (1, STEEL_DARK)])
            + lin_grad("counter", [(0, "#c48a56"), (1, "#8f5b30")])
            + lin_grad("floor-in", [(0, "#e9d3b0"), (1, "#c9a87c")])
            + lin_grad("wall-in", [(0, "#fff4e0"), (1, "#f2dcb6")])
            + rad_grad("glow-warm", [(0, "#ffd58a", 0.95), (1, "#ffd58a", 0)])
            + rad_grad("glow-fire", [(0, "#ffb347", 0.95), (1, "#ff7a1a", 0)])
            + rad_grad("glow-lit", [(0, "#fff3b0", 0.95), (1, "#fff3b0", 0)])
            + rad_grad("glow-green", [(0, "#b8f5c9", 0.9), (1, "#b8f5c9", 0)])
            + rad_grad("glow-red", [(0, "#ffb3aa", 0.9), (1, "#ffb3aa", 0)])
            + rad_grad("glow-moon", [(0, "#fffbe6", 0.9), (1, "#fffbe6", 0)]))


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


def title_bar(title, subtitle="", colour=INK, sub_colour=SOFT_INK):
    out = text(40, 58, title, 34, "start", "bold", colour)
    if subtitle:
        out += text(40, 92, subtitle, 19, "start", "normal", sub_colour)
    return out


def note(x, y, s, size=16, anchor="middle", colour=SOFT_INK):
    return text(x, y, s, size, anchor, "normal", colour, True)


def star(x, y, r, fill=LIT, stroke=None, sw=1.5, op=1.0):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * 0.45
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return poly(pts, fill, stroke, sw, op)


def sparkle(x, y, s=1.0, colour="#ffffff"):
    d = (f"M{x:.1f},{y - 12 * s:.1f} L{x + 3 * s:.1f},{y - 3 * s:.1f} L{x + 12 * s:.1f},{y:.1f} L{x + 3 * s:.1f},{y + 3 * s:.1f} "
         f"L{x:.1f},{y + 12 * s:.1f} L{x - 3 * s:.1f},{y + 3 * s:.1f} L{x - 12 * s:.1f},{y:.1f} L{x - 3 * s:.1f},{y - 3 * s:.1f} z")
    return path(d, colour, None, 0)


def tick(x, y, s=1.0, colour=FAIR):
    return circle(x, y, 18 * s, colour) + path(f"M{x - 8 * s:.1f},{y:.1f} l{6 * s:.1f},{7 * s:.1f} l{11 * s:.1f},{-13 * s:.1f}",
                                               "none", "#ffffff", 4 * s)


def cross(x, y, s=1.0, colour=REFUSE):
    return circle(x, y, 18 * s, colour) + path(f"M{x - 7 * s:.1f},{y - 7 * s:.1f} l{14 * s:.1f},{14 * s:.1f} "
                                               f"M{x + 7 * s:.1f},{y - 7 * s:.1f} l{-14 * s:.1f},{14 * s:.1f}", "none", "#ffffff", 4 * s)


def notes(x, y, s=1.0, colour=BRASS_DARK):
    """A chime: two music notes."""
    return (circle(x, y, 6 * s, colour) + line(x + 6 * s, y, x + 6 * s, y - 22 * s, colour, 2.5)
            + circle(x + 18 * s, y - 6 * s, 6 * s, colour) + line(x + 24 * s, y - 6 * s, x + 24 * s, y - 28 * s, colour, 2.5)
            + line(x + 6 * s, y - 22 * s, x + 24 * s, y - 28 * s, colour, 4))


# --- Things: pies and pieces ----------------------------------------------------------------------------------------------
def wedge_d(cx, cy, r, a0, a1):
    """An SVG path for a pie wedge from angle a0 to a1 (radians, 0 = up, clockwise)."""
    x0, y0 = cx + r * math.sin(a0), cy - r * math.cos(a0)
    x1, y1 = cx + r * math.sin(a1), cy - r * math.cos(a1)
    large = 1 if (a1 - a0) > math.pi else 0
    if abs(a1 - a0 - 2 * math.pi) < 1e-6:
        return (f"M{cx - r:.1f},{cy:.1f} a{r:.1f},{r:.1f} 0 1,0 {2 * r:.1f},0 a{r:.1f},{r:.1f} 0 1,0 {-2 * r:.1f},0 z")
    return f"M{cx:.1f},{cy:.1f} L{x0:.1f},{y0:.1f} A{r:.1f},{r:.1f} 0 {large},1 {x1:.1f},{y1:.1f} z"


def pie(cx, cy, r, n=1, lit=(), missing=(), filling=FILLING, lit_fill=LIT, explode=0.0, glow_lit=False, crust=True,
        lines=True):
    """A pie seen from above, cut into n equal pieces; `lit` pieces glow (an order), `missing` pieces are gone."""
    out = ""
    if crust:
        out += circle(cx, cy, r + r * 0.03, CRUST_DARK, op=0.25 if missing else 1.0)
    for i in range(n):
        if i in missing:
            continue
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        mid = (a0 + a1) / 2
        dx, dy = explode * math.sin(mid), -explode * math.cos(mid)
        fill_ = lit_fill if i in lit else filling
        if n == 1:
            out += circle(cx, cy, r, CRUST, CRUST_DARK, max(1.5, r * 0.05))
            out += circle(cx, cy, r * 0.78, fill_, None, 0, 0.9)
            out += _lattice(cx, cy, r * 0.78)
            continue
        out += path(wedge_d(cx + dx, cy + dy, r, a0, a1), CRUST, CRUST_DARK if lines else None, max(1.5, r * 0.04))
        out += path(wedge_d(cx + dx, cy + dy, r * 0.8, a0 + 0.02, a1 - 0.02), fill_, None, 0, 0.92)
        if i in lit and glow_lit:
            out += path(wedge_d(cx + dx, cy + dy, r, a0, a1), "none", LIT_DARK, max(2, r * 0.06))
    return out


def _lattice(cx, cy, r):
    out = ""
    for k in (-0.5, 0, 0.5):
        out += line(cx + k * r, cy - r * math.sqrt(1 - k * k) * 0.95, cx + k * r, cy + r * math.sqrt(1 - k * k) * 0.95,
                    CRUST_LIGHT, max(1.5, r * 0.09), 0.85)
        out += line(cx - r * math.sqrt(1 - k * k) * 0.95, cy + k * r, cx + r * math.sqrt(1 - k * k) * 0.95, cy + k * r,
                    CRUST_LIGHT, max(1.5, r * 0.09), 0.85)
    return out


def piece(cx, cy, r, n, rot=0.0, filling=FILLING, lit=False):
    """One loose piece (1/n of a pie) whose tip is at (cx, cy), pointing up by default; rot in degrees."""
    a = math.pi * 2 / n
    body = (path(wedge_d(0, 0, r, -a / 2, a / 2), CRUST, CRUST_DARK, max(1.5, r * 0.05))
            + path(wedge_d(0, 0, r * 0.8, -a / 2 + 0.03, a / 2 - 0.03), LIT if lit else filling, None, 0, 0.92))
    return group(body, cx, cy, 1.0, rot)


def plate(x, y, r, pieces=(), filling=FILLING):
    """A white plate seen from slightly above with pieces on it (each piece is its n)."""
    out = ellipse(x, y + r * 0.08, r * 1.05, r * 0.42, "#d8dde0", None, 0)
    out += ellipse(x, y, r, r * 0.4, "#ffffff", "#b9c3c8", 2)
    k = len(pieces)
    for j, n in enumerate(pieces):
        dx = (j - (k - 1) / 2) * r * 0.42
        out += piece(x + dx, y + r * 0.14, r * 0.55, n, 180, filling)
    return out


def loaf(x, y, w, h, cuts=0, lit=(), gap=0.0):
    """A long loaf (a bar: the number line's object) from x, cut into `cuts` equal lengths."""
    out = ""
    n = max(1, cuts)
    seg = w / n
    for i in range(n):
        sx = x + i * (seg + gap)
        fill = LIT if i in lit else CRUST
        out += rect(sx, y, seg - (2 if n > 1 else 0), h, fill, CRUST_DARK, 2, min(12, h / 2.4))
        out += path(f"M{sx + seg * 0.25:.1f},{y + h * 0.3:.1f} q{seg * 0.12:.1f},{h * 0.2:.1f} {seg * 0.24:.1f},0",
                    "none", CRUST_LIGHT, 2.5, 0.9)
    return out


def tray(x, y, cols, rows, cell, lit=0, filled=None):
    """A cupcake tray (a set): cols x rows moulds; the first `lit` glow."""
    out = rect(x - 8, y - 8, cols * cell + 16, rows * cell + 16, TIN, TIN_DARK, 2.5, 10)
    k = 0
    for r_ in range(rows):
        for c in range(cols):
            cx, cy = x + c * cell + cell / 2, y + r_ * cell + cell / 2
            out += circle(cx, cy, cell * 0.42, TIN_DARK, op=0.5)
            if filled is None or k < filled:
                col = LIT if k < lit else "#f3a7b8"
                out += circle(cx, cy, cell * 0.36, CRUST_LIGHT, CRUST_DARK, 1.5)
                out += path(f"M{cx - cell * 0.3:.1f},{cy:.1f} q{cell * 0.3:.1f},{-cell * 0.5:.1f} {cell * 0.6:.1f},0",
                            col, None, 0)
            k += 1
    return out


def tin(cx, cy, r, n, filled=(), filling=FILLING):
    """A round tin with n moulded sections (dashed); `filled` sections hold a piece."""
    out = circle(cx, cy, r + 8, TIN, TIN_DARK, 3)
    out += circle(cx, cy, r, "#dfe5e9", TIN_DARK, 1.5)
    for i in range(n):
        a = 2 * math.pi * i / n
        out += line(cx, cy, cx + r * math.sin(a), cy - r * math.cos(a), TIN_DARK, 1.8, 0.8, dash="5,4")
    for i in filled:
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        out += path(wedge_d(cx, cy, r - 2, a0, a1), CRUST, CRUST_DARK, 1.5)
        out += path(wedge_d(cx, cy, (r - 2) * 0.8, a0 + 0.03, a1 - 0.03), filling, None, 0, 0.92)
    return out


def scoop(x, y, s, label=None):
    """A measuring scoop (a cup measure) seen from the side."""
    g = (path("M-30,-10 L30,-10 L24,22 Q0,30 -24,22 z", STEEL, STEEL_DARK, 2.5)
         + ellipse(0, -10, 30, 7, STEEL_LIGHT, STEEL_DARK, 2) + rect(28, -14, 46, 9, STEEL_DARK, INK, 2, 4))
    out = group(g, x, y, s)
    if label:
        out += text(x - 2 * s, y + 12 * s, label, 15 * s, "middle", "bold", INK)
    return out


def box(x, y, w, h, closed=True, star_=True):
    """A takeaway box (kraft card), front view; (x, y) its bottom-left."""
    out = rect(x, y - h, w, h, KRAFT, KRAFT_DARK, 2.5, 4)
    if closed:
        out += poly([(x - 3, y - h), (x + w / 2, y - h - h * 0.28), (x + w + 3, y - h)], KRAFT, KRAFT_DARK, 2.5)
        out += path(f"M{x + w * 0.3:.1f},{y - h - h * 0.12:.1f} q{w * 0.2:.1f},{-h * 0.32:.1f} {w * 0.4:.1f},0", "none",
                    KRAFT_DARK, 3)
    if star_:
        out += star(x + w / 2, y - h * 0.5, min(w, h) * 0.18, LIT, LIT_DARK, 1.5)
    return out


# --- Things: the Fair Knife, the Fair Line ---------------------------------------------------------------------------------
def knife(x, y, s=1.0, count=4, rot=0.0, numerals=False):
    """The Fair Knife: a wooden handle and a wide silver blade with a row of 12 dot-lights; `count` dots are lit."""
    g = (rect(-150, -16, 92, 32, WOOD, WOOD_DARK, 3, 12) + circle(-128, 0, 4, BRASS) + circle(-82, 0, 4, BRASS)
         + rect(-62, -20, 10, 40, BRASS, BRASS_DARK, 2.5, 3)
         + path("M-52,-22 L150,-22 Q176,-20 180,6 L170,22 L-52,22 z", "url(#blade)", STEEL_DARK, 3)
         + star(160, -4, 7, LIT, LIT_DARK, 1))
    for k in range(12):
        dx = -36 + k * 15.5
        on = k < count
        g += circle(dx, 6, 5.5, LIT if on else "#dfe6ea", LIT_DARK if on else STEEL_DARK, 1.5)
    if numerals:
        g += text(-104, 7, str(count), 18, "middle", "bold", "#ffffff")
    return group(g, x, y, s, rot)


def fair_line(x0, y, unit, wholes=2, labels=False, marks=0, post_pies=True):
    """The counter's brass rail: posts at 0, 1, 2… (one whole pie apart); optional hairline marks of size 1/marks."""
    out = rect(x0 - 16, y - 7, unit * wholes + 32, 14, "url(#brass)", BRASS_DARK, 2, 7)
    if marks:
        for k in range(1, marks * wholes):
            if k % marks:
                xx = x0 + unit * k / marks
                out += line(xx, y - 10, xx, y + 10, BRASS_DARK, 1.5, 0.75)
    for w in range(wholes + 1):
        xx = x0 + unit * w
        out += rect(xx - 5, y - 30, 10, 40, BRASS, BRASS_DARK, 2, 3) + circle(xx, y - 32, 8, BRASS_LIGHT, BRASS_DARK, 2)
        if labels:
            out += text(xx, y + 34, str(w), 20, "middle", "bold", INK)
        elif post_pies and w > 0:
            for j in range(w):
                out += circle(xx - (w - 1) * 7 + j * 14, y - 52, 6, CRUST, CRUST_DARK, 1.5)
    return out


def flag(x, y, colour=TEAL, h=56):
    return line(x, y, x, y - h, INK, 2.5) + poly([(x, y - h), (x + 26, y - h + 9), (x, y - h + 18)], colour, INK, 2)


# --- Living things ---------------------------------------------------------------------------------------------------------
def buddy(x, y, s=1.0, colour="#ff9f43", kind="pup", happy=True, hop=0.0, look=0.0):
    """A living buddy (a wand-woken block build with googly eyes), feet at (x, y)."""
    dark = "#00000033"
    if kind == "tower":
        g = (rect(-16, -34, 32, 34, colour, INK, 2.5, 4) + rect(-16, -68, 32, 34, colour, INK, 2.5, 4)
             + rect(-14, -98, 28, 30, colour, INK, 2.5, 4))
        eyes_y, ex = -84, 7
    elif kind == "bunny":
        g = (rect(-22, -40, 44, 40, colour, INK, 2.5, 6) + rect(-15, -66, 9, 28, colour, INK, 2.5, 4)
             + rect(6, -66, 9, 28, colour, INK, 2.5, 4) + rect(-12, -62, 3, 18, "#ffd1e0", None, 0, 1)
             + rect(9, -62, 3, 18, "#ffd1e0", None, 0, 1))
        eyes_y, ex = -26, 9
    elif kind == "mouse":
        g = (rect(-14, -22, 28, 22, colour, INK, 2.5, 5) + circle(-12, -24, 7, colour, INK, 2.5)
             + circle(12, -24, 7, colour, INK, 2.5) + path("M14,-6 q16,0 18,12", "none", INK, 2.5))
        eyes_y, ex = -13, 6
    elif kind == "jelly":
        g = rect(-22, -40, 44, 40, colour, INK, 2.5, 10, 0.82) + rect(-16, -34, 10, 10, "#ffffff", None, 0, 3, 0.5)
        eyes_y, ex = -24, 9
    elif kind == "lantern":
        g = (rect(-18, -44, 36, 44, colour, INK, 2.5, 6) + rect(-12, -38, 24, 26, "#fff3b0", None, 0, 4, 0.8)
             + rect(-8, -52, 16, 8, INK, None, 0, 2))
        eyes_y, ex = -26, 7
    else:   # pup
        g = (rect(-26, -30, 52, 30, colour, INK, 2.5, 5) + rect(-30, -58, 32, 30, colour, INK, 2.5, 5)
             + rect(-32, -66, 10, 14, colour, INK, 2.5, 3) + rect(-10, -66, 10, 14, colour, INK, 2.5, 3)
             + rect(22, -36, 14, 6, colour, INK, 2, 3))
        eyes_y, ex = -45, 7
    cx = -14 if kind == "pup" else 0
    for side in (-1, 1):
        g += circle(cx + side * ex, eyes_y, 7, "#ffffff", INK, 2) + circle(cx + side * ex + 2 * look, eyes_y + 1, 3.2, INK)
    if happy:
        g += path(f"M{cx - 5},{eyes_y + 11} q5,5 10,0", "none", INK, 2.2)
    else:
        g += line(cx - 4, eyes_y + 12, cx + 4, eyes_y + 12, INK, 2.2)
    g += rect(-14, -2, 10, 5, dark, None, 0, 2) + rect(4, -2, 10, 5, dark, None, 0, 2)
    return group(g, x, y - hop, s)


def bubble(x, y, w, h, body=""):
    """A thought bubble above a buddy (its order as a picture); (x, y) is the bubble's centre."""
    out = (ellipse(x, y, w / 2, h / 2, "#ffffff", "#9fb4c2", 2.5) + circle(x - w * 0.28, y + h / 2 + 10, 7, "#ffffff",
                                                                           "#9fb4c2", 2)
           + circle(x - w * 0.36, y + h / 2 + 24, 4, "#ffffff", "#9fb4c2", 2))
    return out + body


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
    g += rect(-16, -78, 32, 6, "#ffffff", INK, 2, 2) + rect(-10, -96, 20, 18, "#ffffff", INK, 2, 6)   # a baker's hat
    return group(g, x, y, s)


def avatar(x, y, s, arm_up=False, rot=0):
    """The blocky child, feet at (x, y), in a baker's apron."""
    g = (rect(-10, -40, 20, 26, SHIRT, INK, 2.5, 3) + rect(-8, -36, 16, 24, "#ffffff", INK, 1.5, 2)
         + rect(-9, -14, 8, 14, PANTS, INK, 2.5, 2) + rect(1, -14, 8, 14, PANTS, INK, 2.5, 2)
         + rect(-12, -64, 24, 24, SKIN, INK, 2.5, 3) + rect(-12, -64, 24, 8, HAIR, None, 0, 2)
         + rect(-6, -52, 4, 4, INK) + rect(3, -52, 4, 4, INK) + rect(-4, -45, 8, 2, "#c46a5a"))
    if arm_up:
        g += rect(-18, -40, 8, 22, SKIN, INK, 2, 3) + rect(10, -62, 8, 24, SKIN, INK, 2, 3)
    else:
        g += rect(-18, -40, 8, 22, SKIN, INK, 2, 3) + rect(10, -40, 8, 22, SKIN, INK, 2, 3)
    return group(g, x, y, s, rot)


def robin(x, y, s=1.0):
    g = (ellipse(0, -10, 14, 11, "#8a6a4a", INK, 2) + ellipse(5, -8, 7, 6, "#e8603c", None, 0)
         + circle(9, -16, 7, "#8a6a4a", INK, 2) + circle(11, -18, 1.8, INK) + path("M15,-16 l6,2 l-6,2 z", "#ffb020", INK, 1)
         + path("M-12,-12 l-10,-4 l2,8 z", "#8a6a4a", INK, 1.5) + line(-2, 0, -2, 4, INK, 2) + line(3, 0, 3, 4, INK, 2))
    return group(g, x, y, s)


def lantern(x, y, s=1.0, lit=True):
    g = (line(0, -40, 0, -26, INK, 2) + rect(-9, -26, 18, 24, "#fff3b0" if lit else "#4a5470", INK, 2, 3)
         + rect(-11, -28, 22, 4, INK, None, 0, 1) + rect(-11, -3, 22, 4, INK, None, 0, 1))
    out = circle(x, y - 14 * s, 26 * s, "url(#glow-lit)") if lit else ""
    return out + group(g, x, y, s)


def cottage(x, y, w, h, lit=False, colour="#e9d8c4", roof="#7a5ea8"):
    """A buddy's little house in the lane; (x, y) is its bottom-left."""
    out = rect(x, y - h, w, h, colour, INK, 2.5, 3)
    out += poly([(x - 8, y - h), (x + w / 2, y - h - h * 0.6), (x + w + 8, y - h)], roof, INK, 2.5)
    win = "#ffd96a" if lit else "#3a4566"
    out += rect(x + w * 0.18, y - h * 0.72, w * 0.26, h * 0.3, win, INK, 2, 2)
    out += rect(x + w * 0.56, y - h * 0.55, w * 0.26, h * 0.55, "#6a4a32", INK, 2, 2)
    if lit:
        out += circle(x + w * 0.31, y - h * 0.57, w * 0.35, "url(#glow-lit)", op=0.7)
    return out


def oven(x, y, s=1.0, fire=True):
    """The wood-fired dome oven, (x, y) its base centre."""
    g = (rect(-110, -40, 220, 40, OVEN_DARK, INK, 3, 4)
         + path("M-100,-40 Q-100,-170 0,-170 Q100,-170 100,-40 z", OVEN, INK, 3)
         + path("M-46,-40 Q-46,-104 0,-104 Q46,-104 46,-40 z", "#2a1610", INK, 3)
         + rect(-14, -200, 28, 34, OVEN_DARK, INK, 2.5, 3))
    for k in range(4):
        g += path(f"M{-90 + k * 8},{-60 - k * 26} q{20},-6 40,0", "none", OVEN_DARK, 2, 0.6)
    if fire:
        g += circle(0, -58, 52, "url(#glow-fire)", op=0.9)
        g += path("M-26,-42 Q-20,-80 -6,-60 Q0,-96 10,-62 Q22,-84 26,-42 z", FIRE, None, 0, 0.95)
        g += path("M-12,-42 Q-6,-66 2,-52 Q10,-70 14,-42 z", "#ffd34d", None, 0)
    return group(g, x, y, s)


def bakery_front(x, y, s=1.0, lit=True):
    """The Starlight Bakery seen from the lane, (x, y) the middle of its base."""
    g = ""
    g += rect(-170, -230, 340, 230, WALL, INK, 3, 4)
    g += rect(-170, -40, 340, 40, WALL_SHADE, None, 0, 0, 0.6)
    g += poly([(-190, -230), (0, -330), (190, -230)], ROOF, INK, 3)
    g += rect(70, -330, 40, 80, ROOF_DARK, INK, 2.5, 3)                     # the chimney
    for k in range(7):                                                       # the striped awning
        g += path(f"M{-180 + k * 51.4:.1f},-170 L{-180 + (k + 1) * 51.4:.1f},-170 L{-180 + (k + 1) * 51.4:.1f},-140 "
                  f"Q{-180 + (k + 0.5) * 51.4:.1f},-124 {-180 + k * 51.4:.1f},-140 z", TEAL if k % 2 == 0 else "#ffffff",
                  INK, 2)
    g += circle(-70, -80, 52, "#ffd96a" if lit else "#3a4566", INK, 3)       # the round window
    g += line(-70, -132, -70, -28, INK, 2.5) + line(-122, -80, -18, -80, INK, 2.5)
    g += rect(30, -110, 70, 110, "#6a4a32", INK, 3, 4) + circle(88, -54, 4, BRASS)
    g += rect(-60, -215, 120, 34, WOOD_LIGHT, WOOD_DARK, 2.5, 6)             # the sign: a pie and a star
    g += circle(-18, -198, 12, CRUST, CRUST_DARK, 2) + star(16, -198, 12, LIT, LIT_DARK, 1.5)
    out = ""
    if lit:
        out += circle(x - 70 * s, y - 80 * s, 110 * s, "url(#glow-warm)", op=0.75)
    out += group(g, x, y, s)
    for k, (dx, dy, r) in enumerate([(90, -350, 12), (104, -390, 16), (84, -440, 20)]):   # star-shaped smoke
        out += star(x + dx * s, y + dy * s, r * s, "#fff6d8", None, 0, 0.85 - k * 0.15)
    return out


def counter(x, y, w, h=90):
    """The shop counter (front), (x, y) its top-left."""
    out = rect(x, y, w, h, "url(#counter)", WOOD_DARK, 3, 4)
    for k in range(int(w // 120)):
        out += rect(x + 20 + k * 120, y + 18, 90, h - 36, "none", WOOD_DARK, 2, 6, 0.6)
    return out


# --- 01 the bakery ---------------------------------------------------------------------------------------------------------
def pic_bakery():
    W, H = 1800, 1000
    body = rect(0, 0, W, H, PAPER)
    # left: the lane at dusk
    lx, lw = 30, 880
    body += rect(lx, 120, lw, 840, "url(#sky-night)", None, 0, 22)
    for (sx, sy, sr) in [(90, 170, 3), (220, 210, 2), (330, 160, 2.5), (470, 190, 2), (600, 150, 3), (760, 200, 2),
                         (820, 160, 2.5), (140, 260, 2), (680, 250, 2), (400, 240, 1.8)]:
        body += circle(sx, sy, sr, "#fffbe6", op=0.9)
    body += circle(780, 230, 70, "url(#glow-moon)") + circle(780, 230, 30, "#fff6d0")
    body += rect(lx, 700, lw, 260, "#5b5a6e", None, 0, 0) + rect(lx, 940, lw, 20, PAPER)
    for k in range(18):                                                      # cobbles
        for j in range(4):
            body += ellipse(lx + 30 + k * 48 + (j % 2) * 24, 730 + j * 52, 20, 10, "#6e6d84", None, 0)
    body += cottage(60, 700, 120, 110, lit=True, colour="#efd9c2", roof="#5a7fbf")
    body += lantern(200, 690, 1.2, True)
    body += cottage(700, 700, 110, 100, lit=False, colour="#e6d2c8", roof="#9c5fb0")
    body += lantern(830, 690, 1.2, False)
    body += bakery_front(450, 700, 1.15, True)
    body += hoot(395, 448, 0.75)
    queue = [(300, "pup", 0), (585, "bunny", 1), (660, "mouse", 2), (230, "tower", 3)]
    for bx, kind, c in queue:
        body += buddy(bx, 760 if kind != "tower" else 770, 1.0, BUDDY_COLOURS[c], kind)
    body += bubble(300, 610, 120, 86, pie(300, 610, 30, 4, lit={0, 1, 2}))
    body += bubble(600, 590, 110, 80, pie(600, 590, 28, 3, lit={0, 1}))
    body += callout(50, 140, ["The Starlight Bakery, at dusk", "opens when the sun goes down"], size=17)
    body += callout(560, 300, ["Star-shaped smoke", "(the bakery is open)"], 540, 265, size=15)
    body += callout(48, 820, ["A lantern lights in the lane", "for every buddy fed fairly"], 200, 676, size=15)
    body += callout(600, 820, ["Orders as pictures:", "three quarters; two thirds"], 600, 640, size=15)
    # right: inside
    rx, rw = 930, 840
    body += rect(rx, 120, rw, 840, "url(#wall-in)", None, 0, 22)
    body += rect(rx, 720, rw, 240, "url(#floor-in)", None, 0, 0) + rect(rx, 940, rw, 20, PAPER)
    body += oven(rx + 640, 560, 1.15)
    for k in range(3):                                                       # the leftover shelf
        body += rect(rx + 40, 250 + k * 70, 230, 10, WOOD, WOOD_DARK, 2, 3)
    body += pie(rx + 90, 230, 30, 8, missing={0, 1}) + pie(rx + 190, 230, 30, 3, missing={2})
    body += pie(rx + 90, 300, 30, 6, missing={0, 1, 2}) + pie(rx + 190, 300, 30, 2, missing={1})
    body += pie(rx + 140, 370, 30, 4, missing={0})
    body += rect(rx + 330, 190, 250, 160, "#1d2b5a", INK, 3, 10)            # the window to the lane
    body += buddy(rx + 410, 350, 0.9, BUDDY_COLOURS[0], "pup") + buddy(rx + 520, 350, 0.9, BUDDY_COLOURS[4], "jelly")
    body += circle(rx + 560, 222, 3, "#fffbe6") + circle(rx + 380, 210, 2, "#fffbe6")
    body += counter(rx + 30, 600, rw - 60, 110)
    body += fair_line(rx + 110, 592, 280, 2)
    body += rect(rx + 120, 520, 220, 22, WOOD_LIGHT, WOOD_DARK, 2.5, 6)    # the cutting board
    body += pie(rx + 230, 500, 46, 3, explode=4)
    body += knife(rx + 520, 520, 0.8, 3, -8)
    body += box(rx + 720, 590, 60, 46)
    body += avatar(rx + 690, 900, 2.3, arm_up=True)
    body += callout(rx + 20, 140, ["Inside: the oven, the counter,", "the cutting board, the shelf"], size=17)
    body += callout(rx + 40, 420, ["The leftover shelf", "(pieces kept for later orders)"], rx + 120, 360, size=15)
    body += callout(rx + 560, 300, ["The Fair Knife: set how many", "pieces, slice: always equal"], rx + 560, 505, size=15)
    body += callout(rx + 30, 770, ["The Fair Line: the counter's brass rail,", "one whole pie from post to post"],
                    rx + 300, 592, size=15)
    body += title_bar("The Starlight Bakery",
                      "A night bakery where the buddies order shares. You are the baker: cut fair, give the right "
                      "amount, light the lane")
    return svg(W, H, body)


# --- 02 the verb: cut it fair ---------------------------------------------------------------------------------------------
def _table(cx, y, p, plates_pieces=None, colours=None, kinds=None):
    """A little table with p buddies behind it and p plates on it; (cx, y) the table top's middle."""
    w = max(230, p * 66)
    out = ""
    for i in range(p):
        bx = cx - (p - 1) * 33 + i * 66
        out += buddy(bx, y - 4, 0.62, (colours or BUDDY_COLOURS)[i % 6], (kinds or ["pup", "bunny", "jelly", "mouse",
                                                                                    "tower", "lantern"])[i % 6])
    out += rect(cx - w / 2, y, w, 16, WOOD, WOOD_DARK, 2.5, 4) + rect(cx - w / 2 + 14, y + 16, 10, 50, WOOD_DARK)
    out += rect(cx + w / 2 - 24, y + 16, 10, 50, WOOD_DARK)
    for i in range(p):
        px = cx - (p - 1) * 33 + i * 66
        pcs = plates_pieces[i] if plates_pieces else ()
        out += plate(px, y + 2, 26, pcs)
    return out


def pic_verb():
    W, H = 1800, 1100
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The verb: cut it fair",
                      "Set how many equal pieces, slice, give them out. The knife cuts only equal pieces; the number of "
                      "pieces is the bottom number")
    panels = [("1. Who's hungry?", ["one pie, three buddies: the table", "is the order (nothing to read)"]),
              ("2. Set the knife", ["tap the third dot (in VR: twist the", "handle, three clicks); no lines yet"]),
              ("3. Slice: equal pieces", ["one swipe: three equal pieces,", "a sparkle and a 'ting'. The cut stays"]),
              ("4. Fair!", ["one on each plate, ring the bell: the", "plates slide and stop side by side"])]
    for k, (head, cap) in enumerate(panels):
        x = 34 + k * 436
        body += card(x, 120, 418, 640, "#f6efe1", "#e3d6bf")
        body += pill(x + 209, 168, head, 22)
        body += lines_of_text(x + 209, 700, cap, 17, "middle", "normal", SOFT_INK)
    # 1
    body += rect(34 + 70, 470, 270, 24, WOOD_LIGHT, WOOD_DARK, 2.5, 6) + pie(34 + 205, 450, 54, 1)
    body += _table(34 + 209, 600, 3)
    # 2
    x2 = 34 + 436
    body += knife(x2 + 225, 380, 1.05, 3)
    body += group(rect(-9, -4, 18, 40, "#ffd9b8", INK, 2.5, 8) + rect(-14, 26, 28, 30, "#ffd9b8", INK, 2.5, 10)
                  + circle(0, 0, 14, "none", WAIT, 3, 0.9), x2 + 225 - 36 * 1.05 + 2 * 15.5 * 1.05, 392, 1.0)
    body += pie(x2 + 209, 560, 70, 1)
    body += text(x2 + 209, 470, "three dots lit: three pieces", 16, "middle", "normal", SOFT_INK, True)
    # 3
    x3 = 34 + 872
    body += pie(x3 + 209, 450, 90, 3, explode=10)
    for (sx, sy) in [(x3 + 110, 340), (x3 + 320, 360), (x3 + 300, 560), (x3 + 120, 560)]:
        body += sparkle(sx, sy, 1.3, LIT)
    body += knife(x3 + 260, 300, 0.7, 3, 25)
    # 4
    x4 = 34 + 1308
    body += _table(x4 + 209, 380, 3, [(3,), (3,), (3,)])
    for j in range(3):
        yy = 520 + j * 42
        body += rect(x4 + 50, yy - 4, 270, 8, "url(#brass)", BRASS_DARK, 1.5, 4)
        body += rect(x4 + 46, yy - 14, 6, 20, BRASS, BRASS_DARK, 1.5, 2) + rect(x4 + 318, yy - 14, 6, 20, BRASS, BRASS_DARK,
                                                                                 1.5, 2)
        body += ellipse(x4 + 50 + 90, yy - 9, 18, 7, "#ffffff", "#b9c3c8", 2)
    body += line(x4 + 140, 496, x4 + 140, 616, FAIR, 3, dash="6,5") + tick(x4 + 370, 560, 1.0)
    body += lantern(x4 + 370, 480, 1.2, True)
    body += text(x4 + 170, 645, "all three stop at one third", 15, "middle", "normal", SOFT_INK, True)
    # bottom: not fair; why the cut stays
    body += card(34, 790, 1100, 280, "#fff1ee", "#f0b9b0")
    body += pill(300, 838, "Not fair yet: four pieces for three", 20, REFUSE)
    body += pie(120, 960, 50, 4, missing={0, 1, 2}) + piece(180, 950, 46, 4, 40)
    body += _table(390, 960, 3, [(4,), (4,), (4,)])
    body += buddy(530, 1000, 0.6, BUDDY_COLOURS[1], "bunny", happy=False, look=-1)
    body += lines_of_text(590, 880, [
        "The knife set to four: one piece is left over",
        "(set to two, a buddy has none). Hoot: \"Hmm! Not",
        "fair yet.\" Then: \"One piece for each buddy. All",
        "the same size!\" The cut pie becomes crumbs for",
        "the robin; a fresh pie comes. A miss costs only",
        "that order's first-time star."], 16, "start")
    body += robin(1060, 1040, 1.6)
    body += card(1160, 790, 606, 280, "#eef8f1", "#b9e3c6")
    body += pill(1463, 838, "Why the cut stays", 20, "#2f8a55")
    body += lines_of_text(1188, 880, [
        "A knife with an undo, or lines that show on the pie",
        "before the cut, would let trying every number win:",
        "the model's trial-and-error player then reaches the",
        "bar on 100 % of visits. With the cut final and no",
        "preview, it reaches it on 0 %: the number of pieces",
        "has to be chosen, which is what the bottom number is."], 16, "start")
    return svg(W, H, body)


# --- 03 the Fair Line -------------------------------------------------------------------------------------------------------
def _slide(x0, y, unit, stop, flag_at=None, pieces=(), wholes=1, marks=0, label=None, good=None):
    out = fair_line(x0, y, unit, wholes, marks=marks)
    bx = x0 + unit * stop
    out += box(bx - 26, y - 10, 52, 40, closed=True)
    if flag_at is not None:
        fx = x0 + unit * flag_at
        out += flag(fx, y - 12, TEAL, 70)
        if abs(fx - bx) > 2:
            col = REFUSE
            out += line(min(fx, bx), y + 24, max(fx, bx), y + 24, col, 4)
            out += line(min(fx, bx), y + 16, min(fx, bx), y + 32, col, 3) + line(max(fx, bx), y + 16, max(fx, bx), y + 32, col, 3)
    for j, n in enumerate(pieces):
        out += piece(bx - (len(pieces) - 1) * 16 + j * 32, y - 86, 26, n, 180)
    if label:
        out += text(x0 - 20, y - 40, label, 17, "end", "bold")
    if good is True:
        out += tick(x0 + unit * wholes + 60, y - 14)
    elif good is False:
        out += cross(x0 + unit * wholes + 60, y - 14)
    return out


def pic_line():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Fair Line: every order lands on the number line",
                      "The counter's brass rail: one whole pie from post to post. An order slides piece by piece and "
                      "stops at its amount; then the buddy's flag shows where it should be")
    # row 1: the slide
    body += card(34, 120, 1732, 300, "#fbf6ea", "#e3d6bf")
    body += pill(240, 166, "Three quarters slide", 20)
    x0, unit = 360, 760
    body += fair_line(x0, 330, unit, 1, marks=4)
    for k in range(4):
        bx = x0 + unit * k / 4
        body += box(bx - 26, 320, 52, 40, closed=True, star_=(k == 3)) if k in (0, 3) else ""
    for k in (1, 2, 3):
        xx = x0 + unit * k / 4
        body += text(xx, 395, "tick", 15, "middle", "normal", SOFT_INK, True)
        body += curve_arrow(x0 + unit * (k - 1) / 4 + 12, 300, x0 + unit * (k - 0.5) / 4, 250, xx - 12, 300, BRASS_DARK, 3,
                            "brass")
    body += flag(x0 + unit * 0.75, 318, TEAL, 76) + tick(x0 + unit + 90, 300)
    for j in range(3):
        body += piece(x0 + unit * 0.75 - 32 + j * 32, 210, 26, 4, 180)
    body += lines_of_text(1300, 220, ["each quarter moves the box one", "quarter of the way: three ticks,",
                                      "then the flag pops up right there:", "\"Three quarters!\" and a chime"], 16,
                          "start", "normal", SOFT_INK)
    # row 2: too little, too much
    body += card(34, 440, 856, 250, "#fff1ee", "#f0b9b0")
    body += pill(200, 486, "Too little", 20, REFUSE)
    body += _slide(160, 620, 600, F_(3, 8), F_(3, 4), (8, 8, 8))
    body += text(462, 670, "the gap shows how much more: \"A little more, please!\"", 15, "middle", "normal", SOFT_INK,
                 True)
    body += card(910, 440, 856, 250, "#fff1ee", "#f0b9b0")
    body += pill(1060, 486, "Too much", 20, REFUSE)
    body += _slide(1030, 620, 600, F_(5, 6), F_(2, 3), (6, 6, 6, 6, 6))
    body += text(1330, 670, "past the flag: the buddy hands the extra back", 15, "middle", "normal", SOFT_INK, True)
    # row 3: a table races
    body += card(34, 710, 856, 380, "#eef8f1", "#b9e3c6")
    body += pill(230, 756, "A table: fair is side by side", 20, "#2f8a55")
    for j in range(3):
        y = 820 + j * 70
        body += fair_line(160, y, 600, 1, post_pies=False)
        body += ellipse(160 + 600 * 2 / 3, y - 14, 24, 9, "#ffffff", "#b9c3c8", 2)
        body += buddy(110, y + 6, 0.45, BUDDY_COLOURS[j], ["pup", "bunny", "jelly"][j])
    body += line(160 + 400, 790, 160 + 400, 990, FAIR, 3, dash="6,5") + tick(820, 900)
    body += text(462, 1060, "two pies, three buddies: every plate stops at two thirds", 15, "middle", "normal", SOFT_INK,
                 True)
    body += card(910, 710, 856, 380, "#fbf6ea", "#e3d6bf")
    body += pill(1100, 756, "Past one whole", 20)
    body += _slide(1030, 900, 300, F_(5, 4), F_(5, 4), (4, 4, 4, 4, 4), wholes=2, marks=4)
    body += lines_of_text(1338, 990, ["five quarters: past post 1, one whole and a quarter.",
                                      "Whole numbers are fractions too: 8/4 stops on post 2."], 15, "middle", "normal",
                          SOFT_INK, gap=1.4)
    return svg(W, H, body)


def F_(a, b):
    return a / b


# --- 04 Opening Night, order by order ---------------------------------------------------------------------------------------
OPENING = [("0:20", "taught", "table", 1, 4, "the ghost cuts; you deal"),
           ("0:50", "taught", "table", 1, 3, "the trap: halving fails"),
           ("1:20", "judged", "table", 1, 6, ""),
           ("1:45", "judged", "table", 2, 5, "two pies"),
           ("2:15", "taught", "box", 3, 4, "the ghost's box"),
           ("2:50", "judged", "box", 5, 8, ""),
           ("3:15", "judged", "table", 3, 8, ""),
           ("3:45", "judged", "box", 2, 3, ""),
           ("4:10", "judged", "table", 3, 5, ""),
           ("4:40", "judged", "box", 5, 6, ""),
           ("5:10", "judged", "feast", 4, 6, "the Feast")]


def pic_night():
    W, H = 1800, 860
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Opening Night: the phase B slice, order by order",
                      "Three taught orders (the ghost shows once, or the trap teaches), eight judged ones; every fed "
                      "table or box lights a lantern; about six minutes")
    body += rect(34, 120, 1732, 120, "url(#sky-deep)", None, 0, 16)
    for k in range(11):
        x = 120 + k * 150
        body += cottage(x - 34, 228, 68, 54, lit=True if k < 11 else False, colour="#e9dccb",
                        roof=["#5a7fbf", "#9c5fb0", "#c0563a"][k % 3])
    for k, (t, kind, form, a, b, note_) in enumerate(OPENING):
        x = 52 + k * 156
        judged = kind == "judged"
        body += rect(x, 270, 144, 400, "#fffaf0" if judged else "#ffffff", LIT_DARK if judged else "#9fb4c2",
                     3 if judged else 2, 14, extra='' if judged else 'stroke-dasharray="8,6"')
        body += text(x + 72, 300, f"O{k + 1}", 20, "middle", "bold")
        body += text(x + 72, 324, t, 15, "middle", "normal", SOFT_INK)
        if form == "box":
            body += bubble(x + 72, 400, 112, 84, pie(x + 72, 400, 30, b, lit=set(range(a))))
            body += box(x + 47, 530, 50, 40)
            body += text(x + 72, 570, f"{a}/{b} of a pie", 15, "middle", "bold")
        else:
            step = 44 if a < 4 else 32
            for j in range(a):
                body += pie(x + 72 - (a - 1) * step / 2 + j * step, 395, 19 if a < 4 else 14, 1)
            cols = min(b, 4)
            for j in range(b):
                r_, c_ = divmod(j, cols)
                body += buddy(x + 72 - (cols - 1) * 15 + c_ * 30, 470 + r_ * 44, 0.36, BUDDY_COLOURS[j % 6],
                              ["pup", "bunny", "jelly", "mouse", "lantern", "tower"][j % 6])
            body += text(x + 72, 570, f"{a} pie{'s' if a > 1 else ''}, {b} buddies", 14, "middle", "bold")
            body += text(x + 72, 592, f"each {a}/{b}", 14, "middle", "normal", SOFT_INK)
        body += text(x + 72, 622, kind, 15, "middle", "bold", LIT_DARK if judged else SOFT_INK)
        if note_:
            body += lines_of_text(x + 72, 646, wrap(note_, 18), 13, "middle", "normal", SOFT_INK, italic=True)
    body += card(34, 700, 1732, 136, "#fbf6ea", "#e3d6bf")
    body += lines_of_text(60, 735, [
        "Before: the arrival at dusk (0:00), Hoot's welcome. After O11: the Feast's long table in the lane, every lantern lit, the "
        "buddies cheer (5:40); then midnight (6:10).",
        "Judged orders are drawn new every visit (tables mostly of 5, 6 and 8 buddies, boxes in thirds to eighths, two orders "
        "halving can never make). Each is one SkillShown event for g3.maths.unit_fractions:",
        "right at the first hand-over, no help, at most one cut more than the fewest is SOLVED; the bar is 7 of 8 "
        "(MasteryRules). The numbers above are one example visit."], 16, "start", gap=1.45)
    return svg(W, H, body)


# --- 05 Midnight Leftovers: the transfer --------------------------------------------------------------------------------
def shelf(x, y, items, w=330):
    """A shelf with leftover pies: items are (n, left) pies."""
    out = rect(x, y, w, 12, WOOD, WOOD_DARK, 2, 3)
    for k, (n, left) in enumerate(items):
        out += pie(x + 50 + k * 110, y - 34, 32, n, missing=set(range(left, n)))
    return out


def pic_midnight():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Midnight Leftovers: the transfer room of phase B",
                      "The oven sleeps: no fresh pies, only the leftover shelf and the knife to re-cut. 'Give three pieces' "
                      "fails; 'three quarters is a size' wins")
    body += rect(34, 120, 1732, 230, "url(#sky-deep)", None, 0, 16)
    body += oven(260, 330, 0.95, fire=False)
    for k, (zx, zy, zs) in enumerate([(330, 230, 20), (360, 205, 26), (396, 176, 32)]):
        body += text(zx, zy, "z", zs, "middle", "bold", "#c9d6ff", op=0.9 - k * 0.2)
    body += circle(1650, 190, 60, "url(#glow-moon)") + circle(1650, 190, 26, "#fff6d0")
    body += shelf(560, 320, [(8, 6), (3, 2), (6, 5), (2, 1), (4, 1)], 600)
    body += text(860, 160, "the leftover shelf glows in the moonlight", 18, "middle", "normal", "#e8ecff", True)
    # left: the habit
    body += card(34, 370, 856, 470, "#fff1ee", "#f0b9b0")
    body += pill(300, 416, "The habit: \"three pieces\"", 20, REFUSE)
    body += bubble(140, 520, 120, 90, pie(140, 520, 32, 4, lit={0, 1, 2}))
    body += buddy(120, 640, 0.9, BUDDY_COLOURS[0], "pup")
    body += pie(330, 520, 46, 8, missing={6, 7}) + text(330, 595, "eighths on the shelf", 15, "middle", "normal",
                                                          SOFT_INK, True)
    body += box(500, 590, 70, 54)
    for j in range(3):
        body += piece(510 + j * 24, 515, 24, 8, 180)
    body += text(535, 620, "three eighths", 15, "middle", "bold")
    body += _slide(220, 760, 560, 3 / 8, 3 / 4, ())
    body += text(462, 820, "stops at three eighths: short of the flag. The model: 0 % of visits", 15, "middle",
                 "normal", SOFT_INK, True)
    # right: the idea
    body += card(910, 370, 856, 470, "#eef8f1", "#b9e3c6")
    body += pill(1180, 416, "The idea: three quarters is a size", 20, "#2f8a55")
    body += bubble(1016, 520, 120, 90, pie(1016, 520, 32, 4, lit={0, 1, 2}))
    body += buddy(996, 640, 0.9, BUDDY_COLOURS[0], "pup")
    body += pie(1210, 520, 46, 8, missing={6, 7}, lit={0, 1, 2, 3, 4, 5})
    body += text(1210, 595, "two eighths fill each quarter", 15, "middle", "normal", SOFT_INK, True)
    body += box(1380, 590, 70, 54)
    for j in range(6):
        body += piece(1378 + (j % 3) * 26, 500 + (j // 3) * 30, 22, 8, 180)
    body += text(1415, 620, "six eighths", 15, "middle", "bold")
    body += _slide(1096, 760, 560, 3 / 4, 3 / 4, ())
    body += tick(1730, 740)
    body += text(1338, 820, "stops at the flag. The model: 100 % (slips 4 %: 97.6 %)", 15, "middle", "normal",
                 SOFT_INK, True)
    # bottom: make it fair
    body += card(34, 860, 1732, 236, "#fbf6ea", "#e3d6bf")
    body += pill(200, 906, "Make it fair", 20)
    body += plate(120, 1000, 40, (4,)) + plate(240, 1000, 40, (8,))
    body += text(120, 1056, "a quarter", 15, "middle") + text(240, 1056, "an eighth", 15, "middle")
    body += text(180, 950, "two buddies, two leftovers", 15, "middle", "normal", SOFT_INK, True)
    body += plate(470, 1000, 40, (4, 8)) + plate(590, 1000, 40, (8,)) + cross(680, 960)
    body += lines_of_text(720, 950, ["Whole-number bias: \"eight is more than four,", "so the eighth is bigger\": "
                                     "it tops up the", "quarter's plate. Not fair. 0 %."], 16, "start")
    body += plate(1150, 1000, 40, (4,)) + plate(1270, 1000, 40, (8, 8)) + tick(1360, 960)
    body += lines_of_text(1400, 950, ["The idea: the eighth is smaller; one more", "eighth makes it a quarter. \"Fair!",
                                      "A quarter is two eighths.\" 100 %."], 16, "start")
    return svg(W, H, body)


# --- 06 the core loop -----------------------------------------------------------------------------------------------------
def pic_loop():
    W, H = 1800, 940
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The core loop", "From one slice to a village that glows: the same verb at four time scales")
    rows = [("every 10 seconds", "one act with the hands", "a cut, a piece onto a plate, a push along the Fair Line",
             "at once: the pie falls into equal pieces with a 'ting'; the box ticks along the rail"),
            ("every minute", "one order", "a table fed fairly, a box filled right",
             "the buddies munch and hop; a lantern lights in the lane; Hoot: \"Fair and square!\""),
            ("every 10 minutes", "one night", "Opening Night's eleven orders, then the Feast",
             "the long table in the lane, every lantern lit, the cheer; then midnight, then dawn"),
            ("days and weeks", "the rungs", "a rung a school year: tins, scoops, the Size Oven, the recipe book",
             "the village grows (new buddies move in); the recipe book fills; your own order for a friend")]
    for k, (when, what, does, answers) in enumerate(rows):
        y = 130 + k * 196
        body += card(34, y, 1732, 178, ["#fffaf0", "#fbf6ea", "#f6efe1", "#f1e8d6"][k], "#e3d6bf")
        body += text(70, y + 50, when, 26, "start", "bold")
        body += text(70, y + 84, what, 19, "start", "normal", SOFT_INK)
        body += lines_of_text(420, y + 50, wrap("The child: " + does, 52), 18, "start")
        body += lines_of_text(420, y + 110, wrap("The world: " + answers, 60), 17, "start", "normal", SOFT_INK)
    # little pictures on the right
    body += knife(1500, 210, 0.55, 4, -10) + pie(1660, 200, 40, 4, explode=4)
    body += buddy(1480, 440, 0.9, BUDDY_COLOURS[3], "bunny", hop=10) + lantern(1600, 430, 1.4, True)
    body += box(1650, 440, 56, 44)
    body += rect(1440, 560, 300, 90, WOOD, WOOD_DARK, 2.5, 6)
    for j in range(6):
        body += buddy(1465 + j * 50, 560, 0.42, BUDDY_COLOURS[j], ["pup", "bunny", "jelly", "mouse", "lantern",
                                                                       "tower"][j])
        body += plate(1465 + j * 50, 590, 16, (6,))
    for j in range(5):
        body += cottage(1440 + j * 62, 860, 50, 44, lit=True, colour="#e9dccb", roof=["#5a7fbf", "#9c5fb0", "#c0563a",
                                                                                       "#7a5ea8", "#5a7fbf"][j])
    body += star(1700, 760, 16, LIT, LIT_DARK)
    return svg(W, H, body)


# --- 07 the ladder ----------------------------------------------------------------------------------------------------------
RUNGS = [
    ("Grade 3", "The Pie Shop", ["3.1 Opening Night (B)", "3.T1 Midnight Leftovers (B)", "3.2 The Baguette Counter",
                                 "3.3 The Leftover Shelf", "3.4 The Tin Oven", "3.5 The Cupcake Tray",
                                 "3.T2 The Picnic"],
     ["unit_fractions", "fractions_number_line", "equivalent_fractions"], "knife"),
    ("Grade 4", "The Cake Kitchen", ["4.1 The Re-Cut", "4.2 The Queue", "4.3 Pies and Pieces", "4.4 Repeat Orders",
                                     "4.5 The Chocolate Slab", "4.T1 The Night Market"],
     ["equal_fractions", "add_fractions", "fraction_times", "decimals"], "tin"),
    ("Grade 5", "The Big Oven", ["5.1 Mixed Tins", "5.2 The Great Feast", "5.3 Half of a Half", "5.4 The Size Oven",
                                 "5.5 The Scoops", "5.6 The Hundred Tray", "5.T1 The Giant's Picnic"],
     ["unlike_fractions", "fractions_as_division", "multiply_fractions", "scaling", "divide_unit_fractions",
      "percent_intro"], "oven"),
    ("Grade 6", "The Recipe Book", ["6.1 Servings", "6.2 The Recipe Book", "6.3 The Big Batch", "6.4 The Sale Jar",
                                    "6.T1 The Rocket's Fuel", "6.5 Your Own Recipe (D)"],
     ["divide_fractions", "ratios", "percent"], "scoop")]


def pic_ladder():
    W, H = 1800, 1080
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The ladder: one bakery, grades 3 to 6",
                      "Each school year a new part of the bakery opens with a new tool; transfer rooms (T) put the idea "
                      "where the old habit fails. Sixteen units become P1")
    for k, (grade, name, rooms, units, tool) in enumerate(RUNGS):
        x = 34 + k * 436
        y0 = 260 - k * 40
        body += card(x, y0, 418, 900 - y0 - 40, ["#fffaf0", "#fbf6ea", "#f6efe1", "#f1e8d6"][k], "#e3d6bf")
        body += text(x + 24, y0 + 44, grade, 20, "start", "bold", SOFT_INK)
        body += text(x + 24, y0 + 78, name, 26, "start", "bold")
        if tool == "knife":
            body += knife(x + 300, y0 + 60, 0.42, 3, -15)
        elif tool == "tin":
            body += tin(x + 360, y0 + 64, 32, 6, filled={0, 1, 2})
        elif tool == "oven":
            body += oven(x + 360, y0 + 98, 0.35)
        else:
            body += scoop(x + 350, y0 + 66, 0.9)
        for j, r in enumerate(rooms):
            t = ".T" in r
            yy = y0 + 130 + j * 42
            body += rect(x + 18, yy - 26, 382, 36, "#e7f6f3" if t else "#ffffff", TEAL if t else "#d0d8dc", 1.5, 8)
            body += text(x + 32, yy - 2, r, 17, "start", "bold" if t else "normal", TEAL_DARK if t else INK)
        uy = y0 + 150 + len(rooms) * 42
        body += text(x + 24, uy, "units (P1 when taught):", 15, "start", "bold", SOFT_INK)
        for j, u in enumerate(units):
            body += text(x + 24, uy + 24 + j * 22, f"{grade[-1]}.maths.{u}", 15, "start", "normal", SOFT_INK)
        if k < 3:
            body += curve_arrow(x + 410, y0 + 40, x + 436, y0 - 20, x + 460, y0 - 10, BRASS_DARK, 4, "brass")
    # the fade
    body += card(34, 900, 1732, 150, "#ffffff", "#d0d8dc")
    body += text(60, 940, "The fade on every order card (the grade sets the start; play moves it):", 19, "start", "bold")
    stages = [("pictures", None), ("pictures and numerals", "3/4"), ("numerals, read aloud", "3/4"),
              ("symbols: sums, products, ratios", "1/2 + 1/3")]
    for k, (lab, num) in enumerate(stages):
        cx = 220 + k * 430
        if k == 0:
            body += pie(cx, 985, 24, 4, lit={0, 1, 2})
        elif k == 1:
            body += pie(cx - 40, 985, 24, 4, lit={0, 1, 2}) + text(cx + 20, 996, num, 28, "middle", "bold")
        else:
            body += text(cx, 996, num, 30, "middle", "bold")
        body += text(cx, 1034, lab, 16, "middle", "normal", SOFT_INK)
        if k < 3:
            body += line(cx + 140, 988, cx + 290, 988, BRASS_DARK, 3, arrow="brass")
    return svg(W, H, body)


# --- 08 things and meanings -------------------------------------------------------------------------------------------------
def pic_things():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Things and what they mean",
                      "Every object is a piece of the maths; shape, motion and sound carry each meaning too, never "
                      "colour alone")
    items = [
        ("a pie", "one whole", "a warm crust, a berry, apple or leek filling", "a soft thump on the board",
         lambda x, y: pie(x, y, 40, 1)),
        ("a piece", "1/n of a whole", "a wedge; its size is its name", "says its name when touched: \"one sixth\"",
         lambda x, y: piece(x, y - 40, 44, 6, 0)),
        ("the Fair Knife", "the bottom number", "12 dot-lights on the blade; lit dots = pieces",
         "a click per dot; a 'ting' when it slices", lambda x, y: knife(x + 10, y, 0.38, 5)),
        ("the Fair Line", "the number line", "the counter's brass rail; posts at 0, 1, 2",
         "a tick for every piece as a box slides", lambda x, y: fair_line(x - 56, y + 10, 52, 2, post_pies=False)),
        ("a takeaway box", "one buddy's order", "kraft card with a star", "a paper rustle when it closes",
         lambda x, y: box(x - 30, y + 26, 60, 46)),
        ("plates at a table", "a share (division)", "white plates, one per buddy", "the plates' race along the line",
         lambda x, y: plate(x - 30, y, 24, (4,)) + plate(x + 30, y, 24, (4,))),
        ("the leftover shelf", "pieces kept: equivalence", "pies already cut, glowing at midnight",
         "a creak of the shelf", lambda x, y: pie(x, y, 36, 8, missing={0, 1, 2})),
        ("a tin", "a common denominator", "moulded sections: a piece fits only its size", "a snap when a piece fits",
         lambda x, y: tin(x, y, 34, 6, filled={0, 1, 2})),
        ("a cupcake tray", "a fraction of a set", "a tray of 12 moulds; a fence splits it",
         "a 'pop' per cupcake", lambda x, y: tray(x - 50, y - 26, 4, 2, 26, lit=6)),
        ("a loaf", "a length: the line's object", "a long baguette along the rail", "a crunch when cut",
         lambda x, y: loaf(x - 70, y - 14, 140, 28, 4, lit={0, 1, 2})),
        ("scoops", "measuring: division", "steel scoops of 1, 1/2, 1/3, 1/4 cup", "a pour, a 'glug'",
         lambda x, y: scoop(x, y, 1.0, "1/4")),
        ("the Size Oven", "× a fraction (scaling)", "the oven's dial with a number tag",
         "a rising or a falling whistle", lambda x, y: oven(x, y + 40, 0.3)),
        ("the Hundred Tray", "hundredths, percent", "a chocolate slab of 10 rows of 10",
         "a snap per row", lambda x, y: tray(x - 55, y - 32, 10, 3, 11, lit=14)),
        ("the recipe card", "a ratio", "two ingredients counted in scoops", "the dough sighs when it is right",
         lambda x, y: scoop(x - 30, y, 0.6) + scoop(x + 30, y, 0.6)),
        ("a lantern in the lane", "a buddy fed fairly", "a warm light in a cottage window",
         "a soft chime", lambda x, y: lantern(x, y + 30, 1.4, True)),
        ("the robin", "a wrong cut, kindly", "crumbs from a pie cut wrong go to the robin",
         "a happy chirp", lambda x, y: robin(x, y + 20, 1.8))]
    for k, (name, means, look, sound, draw) in enumerate(items):
        col, row = k % 4, k // 4
        x, y = 34 + col * 436, 120 + row * 245
        body += card(x, y, 418, 230, "#ffffff", "#e3d6bf")
        body += draw(x + 80, y + 110)
        body += text(x + 160, y + 46, name, 20, "start", "bold")
        body += text(x + 160, y + 76, means, 17, "start", "bold", TEAL_DARK)
        body += lines_of_text(x + 160, y + 108, wrap(look, 30), 15, "start", "normal", SOFT_INK)
        body += lines_of_text(x + 160, y + 170, wrap(sound, 30), 15, "start", "normal", SOFT_INK, italic=True)
    return svg(W, H, body)


# --- 09 VR ---------------------------------------------------------------------------------------------------------------
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


def pic_vr():
    W, H = 1800, 1000
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("In VR: the hands do the maths",
                      "The child stands at the counter; the board, the plates and the rail are within both hands' reach")
    panels = [("Twist to set", ["hold the knife, twist the handle:", "a click and a buzz per dot"]),
              ("Slice", ["swing it through the pie:", "it falls into equal pieces"]),
              ("Deal with your hands", ["pick a piece, drop it on a plate;", "the plate glows when you're over it"]),
              ("Push it along the line", ["an open hand shoves the box;", "it glides and ticks to its amount"])]
    for k, (head, cap) in enumerate(panels):
        x = 34 + k * 436
        body += card(x, 120, 418, 560, "#f6efe1", "#e3d6bf")
        body += pill(x + 209, 168, head, 21)
        body += lines_of_text(x + 209, 620, cap, 17, "middle", "normal", SOFT_INK)
    body += knife(34 + 230, 380, 0.9, 6, -20) + vr_hand(34 + 120, 420, 1.3, -20)
    body += curve_arrow(34 + 90, 300, 34 + 60, 360, 34 + 100, 470, TEAL_DARK, 4, "teal")
    body += text(34 + 320, 470, "six", 22, "middle", "bold", LIT_DARK)
    x2 = 34 + 436
    body += pie(x2 + 220, 470, 90, 6, explode=6) + knife(x2 + 230, 330, 0.6, 6, 40) + vr_hand(x2 + 340, 260, 1.1, 30)
    body += curve_arrow(x2 + 120, 280, x2 + 200, 230, x2 + 330, 330, TEAL_DARK, 4, "teal", dash="8,6")
    x3 = 34 + 872
    body += plate(x3 + 140, 470, 44, (6,)) + plate(x3 + 290, 470, 44, ()) + piece(x3 + 290, 340, 40, 6, 180)
    body += vr_hand(x3 + 300, 290, 1.1, 0, grip=True)
    body += circle(x3 + 290, 470, 56, "url(#glow-green)")
    x4 = 34 + 1308
    body += fair_line(x4 + 50, 470, 300, 1, marks=4) + box(x4 + 104, 460, 52, 40) + vr_hand(x4 + 60, 420, 1.1, 80,
                                                                                               grip=False)
    body += line(x4 + 170, 430, x4 + 290, 430, TEAL_DARK, 4, arrow="teal")
    body += card(34, 700, 1732, 270, "#eef6f8", "#b9d6e0")
    body += pill(300, 746, "Later (grade 6): pour with two hands", 20, TEAL_DARK)
    body += scoop(260, 880, 1.3, "flour") + scoop(560, 880, 1.3, "butter")
    body += vr_hand(200, 830, 1.0, -30) + vr_hand(620, 830, 1.0, 30)
    body += ellipse(410, 930, 120, 30, "#e8d3ad", WOOD_DARK, 3) + circle(410, 920, 60, "url(#glow-warm)")
    body += lines_of_text(760, 800, [
        "Each hand pours one ingredient; the dough turns golden only while the two flows keep the recipe's ratio",
        "(2 : 1), as in Abrahamson's two-hand ratio trainer, where the screen turns green only at the right ratio.",
        "Played as a 'feel it' warm-up (not judged); the judged recipe orders are scoops counted and poured.",
        "One-handed play stays possible everywhere: a trigger sets the knife, a trigger cuts, a trigger picks."],
                          16, "start", gap=1.5)
    return svg(W, H, body)


# --- 10 the fade -----------------------------------------------------------------------------------------------------------
def order_card(x, y, w, h, body_, stage):
    return rect(x, y, w, h, "#fffaf0", LIT_DARK, 3, 16) + body_ + text(x + w / 2, y + h - 16, stage, 15, "middle",
                                                                        "normal", SOFT_INK, True)


def pic_fade():
    W, H = 1800, 850
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The fade: from pictures to numerals to symbols",
                      "The same order card grows up with the child; Hoot always reads it aloud, so a numeral is heard "
                      "before it is read")
    xs = [60, 480, 900, 1320]
    body += order_card(xs[0], 140, 380, 360, pie(xs[0] + 190, 300, 100, 4, lit={0, 1, 2}), "stage 1: pictures")
    body += order_card(xs[1], 140, 380, 360, pie(xs[1] + 120, 300, 80, 4, lit={0, 1, 2})
                       + text(xs[1] + 290, 320, "3/4", 64, "middle", "bold"), "stage 2: the picture and its numeral")
    body += order_card(xs[2], 140, 380, 360, text(xs[2] + 190, 330, "3/4", 110, "middle", "bold"),
                       "stage 3: the numeral (heard too)")
    syms = ["1/2 + 1/3", "3 × 2/3", "6 ÷ 3/4", "2 : 1", "0.75 = 75%"]
    body += order_card(xs[3], 140, 420, 360, "".join(text(xs[3] + 210, 210 + j * 54, s_, 36, "middle", "bold")
                                                     for j, s_ in enumerate(syms)), "stage 4: symbols (rungs 4-6)")
    for k in range(3):
        body += line(xs[k] + 390, 320, xs[k + 1] - 12, 320, BRASS_DARK, 4, arrow="brass")
    body += card(34, 540, 1732, 280, "#ffffff", "#d0d8dc")
    body += text(60, 584, "How the voice carries the numerals (reading them is part of the skill at the top)", 20,
                 "start", "bold")
    body += lines_of_text(60, 624, [
        "1.  Every order is spoken when the buddy arrives, in words: \"Three quarters of a pie, please!\" (never a written "
        "question).",
        "2.  From stage 2 the card shows the numeral under the picture; a touch on it says it again; the knife's dots get "
        "numerals too.",
        "3.  At stage 3 the picture is gone: the child acts on the numeral, still read aloud; the Fair Line's posts show 0, 1, "
        "2 and the box's amount is said when it stops.",
        "4.  At stage 4 (rungs 4-6) the cards carry the sums, products, divisions, ratios and percents the rooms play; "
        "every symbol says its name when touched (\"plus\", \"times\", \"to\").",
        "5.  The grade sets the starting stage (3: pictures, 4: pictures and numerals, 5-6: numerals); three orders in a row "
        "right with no help move it on, two helped in a row move it back.",
        "6.  On screen during play there are no words: only pictures and these numerals and symbols, which are the subject.",
        "    Without a voice (Read to me off, or no English voice) Hoot's lines show as words (G0's ruling 28)."],
                          17, "start", gap=1.55)
    return svg(W, H, body)


# --- 11 later rungs --------------------------------------------------------------------------------------------------------
def pic_later():
    W, H = 1800, 1180
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Later rungs: the same knife, new tools",
                      "Each room's verb is its idea; the model's misconception for each fails every time (§3.9)")
    cells = [
        ("Mixed tins (5.NF.1)", "a half and a third into one tin: pick the sixths tin, re-cut both; the 'add the tops and "
         "bottoms' tin (fifths) fits neither"),
        ("The Queue (4.NF.2)", "line the buddies up by what they ordered; every queue hides 2/5 vs 2/3 and 1/2 vs 3/8"),
        ("The Size Oven (5.NF.5)", "three cakes go in at once; put each where it will fit after baking: ×3/4 shrinks, "
         "×5/4 grows, ×4/4 stays"),
        ("The Scoops (6.NS.1)", "6 cups of batter, a 3/4-cup scoop: set out the moulds first (8), then pour; every "
         "mould full, nothing left"),
        ("The Hundred Tray (4.NF.6)", "0.45 is four rows and five squares; line up 0.4, 0.405, 0.45 (longer is not "
         "larger)"),
        ("The Recipe Book (6.RP.3)", "2 scoops of flour to 1 of butter; a triple batch: 6 to 3. Adding the same "
         "amount (6 to 5) makes a flat cake")]
    for k, (head, cap) in enumerate(cells):
        col, row = k % 3, k // 3
        x, y = 34 + col * 581, 120 + row * 530
        body += card(x, y, 563, 510, ["#fbf6ea", "#fffaf0", "#f6efe1"][col], "#e3d6bf")
        body += pill(x + 281, y + 46, head, 20)
        body += lines_of_text(x + 281, y + 430, wrap(cap, 54), 16, "middle", "normal", SOFT_INK)
    # mixed tins
    x, y = 34, 120
    body += piece(x + 120, y + 160, 70, 2, 90) + piece(x + 120, y + 290, 70, 3, 90)
    body += line(x + 230, y + 230, x + 300, y + 230, BRASS_DARK, 4, arrow="brass")
    body += tin(x + 420, y + 240, 100, 6, filled={0, 1, 2, 3, 4})
    # queue
    x = 34 + 581
    body += fair_line(x + 70, y + 360, 420, 1, post_pies=False)
    for j, (a, b) in enumerate([(3, 8), (2, 5), (1, 2), (2, 3)]):
        bx = x + 120 + j * 110
        body += buddy(bx, y + 270, 0.7, BUDDY_COLOURS[j], ["mouse", "jelly", "pup", "bunny"][j])
        body += rect(bx - 30, y + 170, 60, 34, "#fffaf0", LIT_DARK, 2, 6) + text(bx, y + 195, f"{a}/{b}", 20, "middle",
                                                                                   "bold")
        tx = x + 70 + 420 * a / b
        body += line(bx, y + 280, tx, y + 346, SOFT_INK, 1.5, 0.7) + circle(tx, y + 352, 4, TEAL_DARK)
    # size oven
    x = 34 + 1162
    body += oven(x + 160, y + 330, 0.55)
    for j, (lab, sc, shelf_y) in enumerate([("×3/4", 0.75, 170), ("×4/4", 1.0, 250), ("×5/4", 1.25, 330)]):
        body += rect(x + 300, y + shelf_y, 220, 8, WOOD, WOOD_DARK, 2, 3)
        body += pie(x + 410, y + shelf_y - 30 * sc, 28 * sc, 1)
        body += text(x + 330, y + shelf_y - 14, lab, 18, "start", "bold")
    # scoops
    x, y = 34, 650
    body += ellipse(x + 130, y + 260, 90, 30, "#e8d3ad", WOOD_DARK, 3) + text(x + 130, y + 210, "6 cups", 18, "middle",
                                                                               "bold")
    body += scoop(x + 270, y + 200, 1.2, "3/4")
    for j in range(8):
        body += circle(x + 330 + (j % 4) * 50, y + 290 + (j // 4) * 56, 20, TIN, TIN_DARK, 2.5)
        body += circle(x + 330 + (j % 4) * 50, y + 290 + (j // 4) * 56, 14, "#e9c38a")
    # hundred tray
    x = 34 + 581
    body += tray(x + 90, y + 120, 10, 10, 22, lit=45)
    body += text(x + 430, y + 200, "0.45", 40, "middle", "bold")
    body += text(x + 430, y + 260, "0.4 < 0.405 < 0.45", 20, "middle", "normal", SOFT_INK)
    # recipe book
    x = 34 + 1162
    body += rect(x + 70, y + 110, 200, 240, "#fffaf0", WOOD_DARK, 3, 10)
    body += scoop(x + 130, y + 170, 0.6) + scoop(x + 200, y + 170, 0.6) + text(x + 170, y + 230, "2 : 1", 30, "middle",
                                                                                 "bold")
    body += text(x + 170, y + 300, "× 3 = 6 : 3", 22, "middle", "normal", SOFT_INK)
    body += ellipse(x + 410, y + 300, 90, 26, "#e8d3ad", WOOD_DARK, 3) + path(
        f"M{x + 330},{y + 300} Q{x + 410},{y + 190} {x + 490},{y + 300} z", CRUST_LIGHT, CRUST_DARK, 3)
    body += tick(x + 500, y + 200)
    return svg(W, H, body)


# --- 12 the cheat test -----------------------------------------------------------------------------------------------------
def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, "model", name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _rates(mod, players, night_len, visit, n):
    R = mod.R
    out = []
    for name, player in players:
        solved = [sum(1 for _, res in visit(player, seed) if res == R.SOLVED) for seed in range(n)]
        out.append((name, 100.0 * sum(1 for s in solved if R.mastered(s, night_len)) / n))
    return out


KNOWS = {"knows what a fraction is", "knows it, slips 4 %", "greedy (biggest piece first)"}


def _bars(x0, y0, w, rows, title, subtitle):
    """One small multiple: horizontal bars, 0-100 % on one shared axis (emphasis, thin bars, hairline grid)."""
    out = text(x0, y0, title, 22, "start", "bold", CHART["ink"])
    out += text(x0, y0 + 26, subtitle, 15, "start", "normal", CHART["ink2"])
    label_w = 320
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
    opening = _load("opening_night_model")
    midnight = _load("midnight_model")
    n = 1000
    o_rows = _rates(opening, opening.R.PLAYERS_OPENING, len(opening.FINAL),
                    lambda pl, sd: opening.visit(pl, sd, opening.FINAL), n)
    m_players = list(midnight.R.PLAYERS_MIDNIGHT)
    m_rows = _rates(midnight, m_players, len(midnight.ROOM), lambda pl, sd: midnight.visit(pl, sd), n)
    W, H = 1800, 760
    body = rect(0, 0, W, H, CHART["surface"])
    body += title_bar("The cheat test: only the knowledge wins",
                      f"Share of {n:,} visits that reach the mastery bar (5 of every 6 judged orders right at the first "
                      "hand-over, no help, within the cut budget)")
    body += rect(40, 112, 18, 12, CHART["accent"], None, 0, 3) + text(66, 123, "players who know what a fraction is", 15,
                                                                       "start", "normal", CHART["ink2"])
    body += rect(360, 112, 18, 12, CHART["rest"], None, 0, 3) + text(386, 123, "players who try without it", 15,
                                                                      "start", "normal", CHART["ink2"])
    body += _bars(40, 170, 880, o_rows, "Opening Night (phase B)", "eight judged orders; the bar is 7 of 8")
    body += _bars(930, 170, 840, m_rows, "Midnight Leftovers (the transfer)",
                  "six judged orders from the leftover shelf; the bar is 5 of 6")
    body += note(W / 2, H - 46, "From model/opening_night_model.py and model/midnight_model.py. Whole-number bias passes "
                 "Opening Night because nothing there compares two amounts; Midnight is where it fails.", 15)
    body += note(W / 2, H - 22, "'Trial and error (undo)' is a knife we do not build: it shows why a cut is final. "
                 "'Always halves' knows sizes, so it passes Midnight; Opening Night's thirds and fifths stop it.", 15)
    return svg(W, H, body)


PICTURES = [("01-the-bakery", pic_bakery), ("02-the-fair-knife", pic_verb), ("03-the-fair-line", pic_line),
            ("04-opening-night", pic_night), ("05-midnight-leftovers", pic_midnight), ("06-core-loop", pic_loop),
            ("07-the-ladder", pic_ladder), ("08-things-and-meanings", pic_things), ("09-vr", pic_vr),
            ("10-the-fade", pic_fade), ("11-later-rungs", pic_later), ("12-cheat-test", pic_cheat)]


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
