"""The design sketches of Word Magic (docs/design/games/word-magic.md, phase A).

Draws every picture as SVG in the game's blocky, friendly look and renders each to PNG with rsvg-convert:

    /usr/bin/python3 -I docs/design/games/word-magic/make_pictures.py [name ...]

The pictures are sketches for grown-ups (the lead, the owner): their labels are not the game's screen (the game shows
no words while a wish plays but the cards' and the frame's words, which are the subject and speak when touched).
Picture 12's numbers come from the phase A models (model/first_page_model.py, model/sleepy_dragons_model.py), run here
at 1,000 visits each. The generic helpers follow Fraction Bakery's make_pictures.py, so the games look like one family.
"""
import importlib.util
import math
import os
import random
import subprocess
import sys

sys.dont_write_bytecode = True   # importing the models must leave no __pycache__ in the docs
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "DejaVu Sans, Arial, sans-serif"
CARD_FONT = "DejaVu Sans, Arial, sans-serif"

# --- The palette (the meanings of §3.8) --------------------------------------------------------------------------------
INK = "#263238"
SOFT_INK = "#4a5a60"
PAPER = "#f7f4ec"
PANEL = "#ffffff"
NIGHT, NIGHT2, NIGHT3 = "#141d40", "#25306a", "#3b3f86"
STAR = "#ffd75e"
STONE, STONE_DARK = "#f1e8d4", "#cdbf9e"
WOOD, WOOD_DARK, WOOD_LIGHT = "#9a6a40", "#6e4726", "#c99a66"
PARCH, PARCH_EDGE = "#fbf3dc", "#cdb98a"
WORD_INK = "#2b2118"
GOLD, GOLD_DARK, GOLD_LIGHT = "#e2b23c", "#9c7414", "#ffe08a"
PENCIL, PENCIL_LINE = "url(#pencil)", "#a3a3a3"
WATER, GRASS, HILL, HILL2, TREE = "#5fa8d3", "#9fd17c", "#a9d68b", "#7fbf6a", "#4e9a52"
WALL, ROOF, PATH = "#f3dcc0", "#c0563a", "#ead2a0"
TEAL, TEAL_DARK = "#2bb3a3", "#16786e"
FAIR, LILAC, WAIT = "#3fbf6b", "#b79ad6", "#ffae3b"
JUMBLE = "#1f1a2e"
HOOT, HOOT_LIGHT = "#8a5a35", "#e2c093"
HAT, HAT_DARK = "#6a4fb3", "#4a3486"
SKIN, SHIRT, PANTS, HAIR = "#f0c8a0", "#2bb3a3", "#3a5fb0", "#5a3b22"
DRAGON = ["#7bd389", "#6ec6ff", "#ff9f43", "#b18cff", "#ff7eb6"]
BUDDY_COLOURS = ["#ff9f43", "#6ec6ff", "#b18cff", "#7bd389", "#ff7eb6", "#ffd166"]
CHART = {"surface": "#fcfcfb", "ink": "#0b0b0b", "ink2": "#52514e", "muted": "#898781", "grid": "#e1e0d9",
         "axis": "#c3c2b7", "accent": "#2a78d6", "rest": "#b4b2a9"}


# --- SVG helpers -------------------------------------------------------------------------------------------------------
def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}{_markers()}{common_defs()}</defs>{body}</svg>')


def _markers():
    out = ""
    for name, colour in (("ink", INK), ("gold", GOLD_DARK), ("grey", "#7a8790"), ("green", FAIR), ("lilac", LILAC),
                         ("white", "#ffffff"), ("teal", TEAL_DARK)):
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
    return (lin_grad("sky-night", [(0, NIGHT), (0.6, NIGHT2), (1, NIGHT3)])
            + lin_grad("dome", [(0, "#101839"), (1, "#2a3778")])
            + lin_grad("gold", [(0, GOLD_LIGHT), (0.5, GOLD), (1, GOLD_DARK)])
            + lin_grad("parch", [(0, "#fffaf0"), (1, PARCH)])
            + lin_grad("wood", [(0, "#b07a4a"), (1, WOOD_DARK)])
            + lin_grad("floor", [(0, "#cfb487"), (1, "#a8895c")])
            + lin_grad("wall-in", [(0, "#2d3a7a"), (1, "#1b2452")])
            + lin_grad("stone", [(0, "#fbf4e4"), (1, STONE_DARK)], 0, 0, 1, 0)
            + rad_grad("glow-warm", [(0, "#ffd58a", 0.95), (1, "#ffd58a", 0)])
            + rad_grad("glow-gold", [(0, "#fff3b0", 0.95), (1, "#fff3b0", 0)])
            + rad_grad("glow-green", [(0, "#b8f5c9", 0.9), (1, "#b8f5c9", 0)])
            + rad_grad("glow-lilac", [(0, "#e7d9ff", 0.9), (1, "#e7d9ff", 0)])
            + rad_grad("glow-moon", [(0, "#fffbe6", 0.9), (1, "#fffbe6", 0)])
            + rad_grad("glow-teal", [(0, "#b9f2ea", 0.9), (1, "#b9f2ea", 0)])
            + '<pattern id="pencil" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(35)">'
              '<rect width="9" height="9" fill="#f1efe9"/><line x1="0" y1="0" x2="0" y2="9" stroke="#b9b6ad" '
              'stroke-width="1.4"/></pattern>')


def rect(x, y, w, h, fill, stroke=None, sw=3, rx=0, op=1.0, extra=""):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}"{st} '
            f'opacity="{op}" {extra}/>')


def circle(x, y, r, fill, stroke=None, sw=3, op=1.0, extra=""):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{fill}"{st} opacity="{op}" {extra}/>'


def ellipse(x, y, rx, ry, fill, stroke=None, sw=3, rot=0.0, op=1.0, extra=""):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return (f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}"{st} opacity="{op}" '
            f'transform="rotate({rot:.1f} {x:.1f} {y:.1f})" {extra}/>')


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


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text(x, y, s, size=20, anchor="middle", weight="normal", fill=INK, italic=False, op=1.0, family=FONT):
    st = ' font-style="italic"' if italic else ""
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" font-size="{size}" text-anchor="{anchor}" '
            f'font-weight="{weight}" fill="{fill}"{st} opacity="{op}">{esc(s)}</text>')


def spans(x, y, parts, size=20, anchor="middle", weight="bold", family=CARD_FONT, op=1.0):
    """One line of text in several colours: parts = [(text, colour), ...]."""
    inner = "".join(f'<tspan fill="{c}">{esc(t)}</tspan>' for t, c in parts if t)
    return (f'<text xml:space="preserve" x="{x:.1f}" y="{y:.1f}" font-family="{family}" font-size="{size}" '
            f'text-anchor="{anchor}" font-weight="{weight}" opacity="{op}">{inner}</text>')


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


def star(x, y, r, fill=STAR, stroke=None, sw=1.5, op=1.0):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * 0.45
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return poly(pts, fill, stroke, sw, op)


def sparkle(x, y, s=1.0, colour="#ffffff", op=1.0):
    d = (f"M{x:.1f},{y - 12 * s:.1f} L{x + 3 * s:.1f},{y - 3 * s:.1f} L{x + 12 * s:.1f},{y:.1f} L{x + 3 * s:.1f},{y + 3 * s:.1f} "
         f"L{x:.1f},{y + 12 * s:.1f} L{x - 3 * s:.1f},{y + 3 * s:.1f} L{x - 12 * s:.1f},{y:.1f} L{x - 3 * s:.1f},{y - 3 * s:.1f} z")
    return path(d, colour, None, 0, op)


def tick(x, y, s=1.0, colour=FAIR):
    return circle(x, y, 18 * s, colour) + path(f"M{x - 8 * s:.1f},{y:.1f} l{6 * s:.1f},{7 * s:.1f} l{11 * s:.1f},{-13 * s:.1f}",
                                               "none", "#ffffff", 4 * s)


def hmm(x, y, s=1.0):
    """'Not yet': a soft lilac circle with a wavy line (never a red cross)."""
    return circle(x, y, 18 * s, LILAC) + path(f"M{x - 9 * s:.1f},{y:.1f} q{4.5 * s:.1f},{-6 * s:.1f} {9 * s:.1f},0 "
                                              f"t{9 * s:.1f},0", "none", "#ffffff", 3.5 * s)


def zzz(x, y, s=1.0, colour="#ffffff", op=0.9):
    out = ""
    for i, k in enumerate((1.0, 0.8, 0.6)):
        xx, yy, w = x + i * 12 * s, y - i * 14 * s, 9 * s * k
        out += path(f"M{xx - w:.1f},{yy - w:.1f} L{xx + w:.1f},{yy - w:.1f} L{xx - w:.1f},{yy + w:.1f} L{xx + w:.1f},{yy + w:.1f}",
                    "none", colour, 2.4 * s, op)
    return out


def notes_glyph(x, y, s=1.0, colour=INK):
    return (circle(x, y, 5 * s, colour) + line(x + 5 * s, y, x + 5 * s, y - 18 * s, colour, 2.2)
            + circle(x + 15 * s, y - 5 * s, 5 * s, colour) + line(x + 20 * s, y - 5 * s, x + 20 * s, y - 23 * s, colour, 2.2)
            + line(x + 5 * s, y - 18 * s, x + 20 * s, y - 23 * s, colour, 3.5))


def ripple(x, y, s=1.0, colour=GOLD_DARK):
    """A card speaking: three little arcs."""
    out = ""
    for i in range(3):
        r = (10 + i * 8) * s
        out += path(f"M{x + r * 0.5:.1f},{y - r * 0.87:.1f} A{r:.1f},{r:.1f} 0 0 1 {x + r * 0.5:.1f},{y + r * 0.87:.1f}",
                    "none", colour, 2.4, 0.85 - i * 0.2)
    return out


# --- Things: cards, the ribbon, the star, runes -----------------------------------------------------------------------
def badge(x, y, r, kind):
    """A picture badge: a small ink sketch in a cream circle (what the word is about, never its grammar)."""
    out = circle(x, y, r, "#fffdf6", PARCH_EDGE, 1.5)
    s = r / 18.0
    if kind in ("fox", "wolf", "dog", "cat"):
        col = {"fox": "#e58a3a", "wolf": "#8e9aa6", "dog": "#c58a5a", "cat": "#f2b54a"}[kind]
        out += path(f"M{x - 9 * s},{y - 2 * s} L{x - 7 * s},{y - 12 * s} L{x - 2 * s},{y - 6 * s} L{x + 2 * s},{y - 6 * s} "
                    f"L{x + 7 * s},{y - 12 * s} L{x + 9 * s},{y - 2 * s} Q{x},{y + 12 * s} {x - 9 * s},{y - 2 * s} z", col, INK,
                    1.4)
        out += circle(x - 3.5 * s, y - 1 * s, 1.5 * s, INK) + circle(x + 3.5 * s, y - 1 * s, 1.5 * s, INK)
    elif kind in ("mouse",):
        out += ellipse(x, y + 2 * s, 9 * s, 6 * s, "#b9a7d9", INK, 1.4) + circle(x - 6 * s, y - 5 * s, 3.5 * s, "#b9a7d9", INK, 1.2)
        out += circle(x + 6 * s, y - 5 * s, 3.5 * s, "#b9a7d9", INK, 1.2) + circle(x, y + 1 * s, 1.4 * s, INK)
    elif kind in ("frog",):
        out += ellipse(x, y + 3 * s, 10 * s, 6 * s, "#7bd389", INK, 1.4) + circle(x - 5 * s, y - 4 * s, 3.5 * s, "#7bd389", INK, 1.2)
        out += circle(x + 5 * s, y - 4 * s, 3.5 * s, "#7bd389", INK, 1.2) + circle(x - 5 * s, y - 4 * s, 1.3 * s, INK)
        out += circle(x + 5 * s, y - 4 * s, 1.3 * s, INK)
    elif kind in ("duck", "goose"):
        col = "#ffd166" if kind == "duck" else "#ffffff"
        out += ellipse(x + 2 * s, y + 4 * s, 9 * s, 5.5 * s, col, INK, 1.4)
        out += circle(x - 5 * s, y - 4 * s if kind == "duck" else y - 8 * s, 4 * s, col, INK, 1.2)
        if kind == "goose":
            out += line(x - 4 * s, y - 4 * s, x - 1 * s, y + 2 * s, INK, 1.4)
        by = y - 4 * s if kind == "duck" else y - 8 * s
        out += poly([(x - 9 * s, by), (x - 14 * s, by + 1.5 * s), (x - 9 * s, by + 2.5 * s)], "#ff9f1c", INK, 1)
    elif kind == "sheep":
        for dx, dy in ((-5, -2), (0, -5), (5, -2), (-3, 3), (3, 3)):
            out += circle(x + dx * s, y + dy * s, 4.5 * s, "#ffffff", INK, 1.1)
        out += ellipse(x - 8 * s, y, 3 * s, 3.8 * s, "#4a4a4a", None, 0)
    elif kind in ("pony",):
        out += path(f"M{x - 8 * s},{y + 8 * s} L{x - 6 * s},{y - 6 * s} Q{x + 2 * s},{y - 12 * s} {x + 8 * s},{y - 4 * s} "
                    f"L{x + 4 * s},{y + 1 * s} L{x + 1 * s},{y + 8 * s} z", "#c58a5a", INK, 1.4)
        out += path(f"M{x - 6 * s},{y - 6 * s} Q{x - 9 * s},{y} {x - 7 * s},{y + 4 * s}", "none", "#6e4726", 2.2)
    elif kind in ("bunny",):
        out += ellipse(x, y + 4 * s, 7 * s, 6 * s, "#6ec6ff", INK, 1.4)
        out += ellipse(x - 3 * s, y - 7 * s, 2 * s, 6 * s, "#6ec6ff", INK, 1.2) + ellipse(x + 3 * s, y - 7 * s, 2 * s, 6 * s,
                                                                                         "#6ec6ff", INK, 1.2)
    elif kind in ("child",):
        out += circle(x, y - 5 * s, 5 * s, SKIN, INK, 1.2) + rect(x - 5 * s, y, 10 * s, 9 * s, SHIRT, INK, 1.2, 2)
        out += path(f"M{x - 5 * s},{y - 7 * s} Q{x},{y - 13 * s} {x + 5 * s},{y - 7 * s}", HAIR, None, 0)
    elif kind in ("leaf",):
        out += path(f"M{x - 9 * s},{y + 7 * s} Q{x - 9 * s},{y - 9 * s} {x + 9 * s},{y - 9 * s} Q{x + 9 * s},{y + 7 * s} "
                    f"{x - 9 * s},{y + 7 * s} z", "#e8963a", INK, 1.4) + line(x - 9 * s, y + 7 * s, x + 4 * s, y - 4 * s, INK, 1)
    elif kind in ("box",):
        out += rect(x - 8 * s, y - 5 * s, 16 * s, 13 * s, "#ff7eb6", INK, 1.4, 1) + rect(x - 1.5 * s, y - 5 * s, 3 * s, 13 * s,
                                                                                        GOLD, None, 0)
        out += path(f"M{x},{y - 5 * s} q-5,-6 -7,-2 M{x},{y - 5 * s} q5,-6 7,-2", "none", GOLD_DARK, 1.4)
    elif kind in ("dragon",):
        out += ellipse(x, y + 2 * s, 9 * s, 7 * s, "#7bd389", INK, 1.4) + circle(x - 6 * s, y - 5 * s, 4.5 * s, "#7bd389", INK, 1.2)
        out += poly([(x + 2 * s, y - 4 * s), (x + 9 * s, y - 11 * s), (x + 8 * s, y - 2 * s)], "#5bb86a", INK, 1)
    elif kind in ("jump", "dance", "sleep", "fly", "snore", "sneeze", "swim", "laugh", "eat"):
        out += action_glyph(x, y, s, kind)
    elif kind in ("big", "tiny", "purple", "golden"):
        if kind == "big":
            out += rect(x - 8 * s, y - 8 * s, 16 * s, 16 * s, "#cfd8dc", INK, 1.4, 2)
        elif kind == "tiny":
            out += rect(x - 3 * s, y - 3 * s, 6 * s, 6 * s, "#cfd8dc", INK, 1.2, 1)
        else:
            out += circle(x, y, 8 * s, "#9b6ad6" if kind == "purple" else GOLD, INK, 1.4)
    else:
        out += star(x, y, 9 * s, GOLD, INK, 1)
    return out


def action_glyph(x, y, s, kind):
    if kind == "jump":
        return path(f"M{x - 9 * s},{y + 8 * s} Q{x},{y - 16 * s} {x + 9 * s},{y + 8 * s}", "none", INK, 2, 1,
                    'stroke-dasharray="3 3"') + circle(x, y - 4 * s, 3 * s, INK)
    if kind == "dance":
        return notes_glyph(x - 8 * s, y + 6 * s, s * 0.8, INK)
    if kind in ("sleep", "snore"):
        return zzz(x - 6 * s, y + 6 * s, s * 0.7, INK, 1)
    if kind == "fly":
        return path(f"M{x - 9 * s},{y} q4.5,-7 9,0 q4.5,-7 9,0", "none", INK, 2)
    if kind == "sneeze":
        return (circle(x - 2 * s, y, 3 * s, "#ffb347", None, 0) + circle(x + 4 * s, y - 3 * s, 2.4 * s, "#ff8a2a", None, 0)
                + circle(x + 7 * s, y + 3 * s, 2 * s, "#ffb347", None, 0))
    if kind == "swim":
        return path(f"M{x - 9 * s},{y + 2 * s} q3,-4 6,0 t6,0 t6,0", "none", WATER, 2.4)
    if kind == "laugh":
        return path(f"M{x - 6 * s},{y - 2 * s} q6,9 12,0 z", "#ffffff", INK, 1.6)
    if kind == "eat":
        return path(f"M{x - 8 * s},{y + 5 * s} L{x + 8 * s},{y + 5 * s} L{x + 4 * s},{y - 6 * s} z", GOLD, INK, 1.4)
    return ""


def word_card(x, y, word, ending="", w=None, h=62, size=26, badge_kind=None, lit=False, speaking=False, ghost=False,
              held=False, rot=0.0):
    """A word card centred at (x, y): parchment, the word in ink with its ending in gold, a badge at the top-left."""
    w = w or max(96, (len(word) + 1) * size * 0.62 + (34 if badge_kind else 22))
    body = ""
    if lit:
        body += ellipse(0, 0, w * 0.75, h * 0.95, "url(#glow-gold)", None, 0)
    body += rect(-w / 2 + 3, -h / 2 + 5, w, h, "#00000022", None, 0, 12)
    body += rect(-w / 2, -h / 2, w, h, "url(#parch)", PARCH_EDGE, 2.2, 12, 0.55 if ghost else 1.0)
    stem = word[:len(word) - len(ending)] if ending else word
    tx = 10 if badge_kind else 0
    body += spans(tx, size * 0.36, [(stem, WORD_INK), (ending, GOLD_DARK)], size)
    if badge_kind:
        body += badge(-w / 2 + 6, -h / 2 + 6, 15, badge_kind)
    if speaking:
        body += ripple(w / 2 + 6, -h / 2 + 6, 0.8)
    if held:
        body += hand_pointer(w * 0.2, h * 0.45)
    return group(body, x, y, 1.0, rot)


def hand_pointer(x, y, s=1.0):
    g = (rect(-7, -2, 14, 26, "#ffd9b8", INK, 2, 6) + rect(-18, 14, 36, 26, "#ffd9b8", INK, 2, 9))
    return group(g, x, y, s)


def ribbon(x, y, slots, gap_w=150, h=74, star_lit=True, star_ring=False):
    """The Spell Ribbon: a golden band from x; slots are strings (frame words in ink), ('gap', None) empty gaps, or
    ('card', word, ending, badge) filled ones. Ends with the star seal. Returns (svg, end_x)."""
    pieces, cx = [], x + 24
    for s in slots:
        if isinstance(s, str):
            wpx = len(s) * 15 + 18
            pieces.append(("word", s, cx, wpx))
            cx += wpx
        elif s[0] == "gap":
            pieces.append(("gap", None, cx, gap_w))
            cx += gap_w + 10
        else:
            wd, end, bd = s[1], s[2], s[3] if len(s) > 3 else None
            wpx = max(gap_w, (len(wd) + 1) * 26 * 0.62 + (34 if bd else 22))
            pieces.append(("card", (wd, end, bd), cx, wpx))
            cx += wpx + 10
    end_x = cx + 70
    out = rect(x - 4, y - h / 2 + 4, end_x - x + 8, h, "#00000018", None, 0, 16)
    out += path(f"M{x},{y - h / 2} L{end_x},{y - h / 2} L{end_x - 14},{y} L{end_x},{y + h / 2} L{x},{y + h / 2} "
                f"L{x + 14},{y} z", "url(#gold)", GOLD_DARK, 2.5)
    out += line(x + 20, y - h / 2 + 7, end_x - 22, y - h / 2 + 7, GOLD_LIGHT, 2, 0.8)
    for kind, val, px, pw in pieces:
        if kind == "word":
            out += text(px + pw / 2, y + 9, val, 26, "middle", "bold", WORD_INK, family=CARD_FONT)
        elif kind == "gap":
            out += rect(px, y - h / 2 + 9, pw, h - 18, "#b38a1e", GOLD_DARK, 1.5, 10, 0.45)
            out += rect(px + 4, y - h / 2 + 13, pw - 8, h - 26, "none", "#fff2c2", 1.5, 8, 0.6,
                        'stroke-dasharray="6 5"')
        else:
            wd, end, bd = val
            out += word_card(px + pw / 2, y, wd, end, w=pw, h=h - 16, badge_kind=bd)
    sx = end_x - 50
    if star_lit:
        out += circle(sx, y, 36, "url(#glow-teal)", None, 0)
    out += star(sx, y, 26, GOLD if star_lit else "#d8c892", GOLD_DARK, 2)
    if star_ring:
        out += circle(sx, y, 34, "none", TEAL, 3, 0.9, 'stroke-dasharray="5 5"')
    return out, end_x


def rune_tile(x, y, label, kind="prefix", size=24):
    w = len(label) * size * 0.62 + 26
    shape = (f"M{-w / 2},{-24} L{w / 2 - 10},{-24} L{w / 2},0 L{w / 2 - 10},24 L{-w / 2},24 z" if kind == "prefix" else
             f"M{-w / 2 + 10},{-24} L{w / 2},{-24} L{w / 2},24 L{-w / 2 + 10},24 L{-w / 2},0 z")
    body = path(shape, "url(#gold)", GOLD_DARK, 2.2) + text(0, 9, label, size, "middle", "bold", WORD_INK, family=CARD_FONT)
    return group(body, x, y)


# --- Things: the valley (the pop-up book) --------------------------------------------------------------------------
def open_book(x, y, w, h):
    """The Great Book lying open (seen from a little above), centre (x, y)."""
    out = rect(x - w / 2 - 16, y - h / 2 + 10, w + 32, h + 18, "#5a2f2a", INK, 3, 10)        # the cover
    out += path(f"M{x - w / 2},{y - h / 2} Q{x - w / 4},{y - h / 2 - 14} {x},{y - h / 2 + 6} L{x},{y + h / 2 + 6} "
                f"Q{x - w / 4},{y + h / 2 - 8} {x - w / 2},{y + h / 2} z", "#fffaf0", "#cdbf9e", 2)
    out += path(f"M{x + w / 2},{y - h / 2} Q{x + w / 4},{y - h / 2 - 14} {x},{y - h / 2 + 6} L{x},{y + h / 2 + 6} "
                f"Q{x + w / 4},{y + h / 2 - 8} {x + w / 2},{y + h / 2} z", "#fffaf0", "#cdbf9e", 2)
    out += line(x, y - h / 2 + 6, x, y + h / 2 + 6, "#cdbf9e", 2)
    return out


def valley(x, y, w, colours=1.0, s=1.0, with_pond=True):
    """The pop-up valley standing on the book, base line at y, width w. colours: 0 (pencil) .. 1 (all in colour), as the
    fraction of patches coloured from left to right."""
    def col(c, k):
        return c if k < colours else PENCIL

    def stroke(k):
        return INK if k < colours else PENCIL_LINE

    out = ""
    # back hills
    out += path(f"M{x - w / 2},{y} Q{x - w / 3},{y - 150 * s} {x - w / 8},{y - 60 * s} Q{x + w / 10},{y - 170 * s} "
                f"{x + w / 2},{y - 40 * s} L{x + w / 2},{y} z", col(HILL, 0.2), stroke(0.2), 2.4)
    out += path(f"M{x - w / 2},{y} Q{x - w / 6},{y - 90 * s} {x + w / 6},{y - 50 * s} Q{x + w / 3},{y - 30 * s} "
                f"{x + w / 2},{y - 60 * s} L{x + w / 2},{y} z", col(HILL2, 0.55), stroke(0.55), 2.4)
    # the ground strip
    out += rect(x - w / 2, y - 18 * s, w, 18 * s, col(GRASS, 0.35), stroke(0.35), 2)
    # the path
    out += path(f"M{x - w / 2 + 30 * s},{y} Q{x - w / 6},{y - 30 * s} {x + w / 10},{y - 10 * s} T{x + w / 2 - 20 * s},"
                f"{y - 28 * s}", "none", col(PATH, 0.9), 10 * s, 1)
    if with_pond:
        out += ellipse(x - w / 4, y - 12 * s, 70 * s, 16 * s, col(WATER, 0.1), stroke(0.1), 2)
    # a tree on the hill
    tx, ty = x + 0.14 * w, y - 136 * s
    out += rect(tx - 4 * s, ty + 6 * s, 8 * s, 22 * s, col(WOOD, 0.7), stroke(0.7), 1.6, 2)
    out += circle(tx, ty, 22 * s, col(TREE, 0.7), stroke(0.7), 2)
    # cottages
    for i, cx in enumerate((x + w / 4, x + w / 2.6)):
        k = 0.75 + 0.1 * i
        out += rect(cx - 16 * s, y - 50 * s, 32 * s, 30 * s, col(WALL, k), stroke(k), 2, 2)
        out += poly([(cx - 21 * s, y - 50 * s), (cx, y - 70 * s), (cx + 21 * s, y - 50 * s)], col(ROOF, k), stroke(k), 2)
        out += rect(cx - 5 * s, y - 34 * s, 10 * s, 14 * s, col(WOOD_DARK, k), None, 0)
    return out


def hatch(x, y, w, h, op=0.35):
    """Pencil hatching over an area (the unwritten valley)."""
    out = ""
    for k in range(int((w + h) / 14)):
        x0 = x + k * 14
        out += line(x0, y + h, x0 - h, y, PENCIL_LINE, 1, op)
    return f'<g clip-path="none">{out}</g>'


# --- Creatures -----------------------------------------------------------------------------------------------------
def buddy(x, y, s=1.0, colour="#ff9f43", kind="pup", happy=True, hop=0.0, look=0.0, eyes=True):
    """A living buddy (a wand-woken block build with googly eyes), feet at (x, y)."""
    dark = "#00000033"
    cx = 0
    if kind == "bunny":
        g = (rect(-22, -40, 44, 40, colour, INK, 2.5, 6) + rect(-15, -66, 9, 28, colour, INK, 2.5, 4)
             + rect(6, -66, 9, 28, colour, INK, 2.5, 4))
        eyes_y, ex = -26, 9
    elif kind == "mouse":
        g = (rect(-14, -22, 28, 22, colour, INK, 2.5, 5) + circle(-12, -24, 7, colour, INK, 2.5)
             + circle(12, -24, 7, colour, INK, 2.5) + path("M14,-6 q16,0 18,12", "none", INK, 2.5))
        eyes_y, ex = -13, 6
    elif kind == "frog":
        g = (rect(-24, -24, 48, 24, colour, INK, 2.5, 8) + circle(-12, -26, 9, colour, INK, 2.5)
             + circle(12, -26, 9, colour, INK, 2.5))
        eyes_y, ex = -26, 12
    elif kind == "duck":
        g = (rect(-22, -26, 40, 26, colour, INK, 2.5, 8) + rect(-28, -48, 22, 24, colour, INK, 2.5, 6)
             + poly([(-28, -38), (-42, -34), (-28, -30)], "#ff9f1c", INK, 2))
        eyes_y, ex, cx = -40, 5, -17
    elif kind == "goose":
        g = (rect(-24, -28, 46, 28, colour, INK, 2.5, 9) + rect(-26, -62, 12, 36, colour, INK, 2.5, 5)
             + rect(-34, -72, 22, 16, colour, INK, 2.5, 5) + poly([(-34, -66), (-48, -62), (-34, -58)], "#ff9f1c", INK, 2))
        eyes_y, ex, cx = -66, 4, -23
    elif kind == "sheep":
        g = ""
        for dx, dy in ((-16, -26), (0, -32), (16, -26), (-10, -14), (10, -14)):
            g += circle(dx, dy, 13, colour, INK, 2.2)
        g += rect(-38, -40, 18, 22, "#4a4a4a", INK, 2, 6) + rect(-14, -6, 6, 8, "#4a4a4a", None, 0) + rect(8, -6, 6, 8, "#4a4a4a",
                                                                                                          None, 0)
        eyes_y, ex, cx = -31, 4, -29
    elif kind == "pony":
        g = (rect(-26, -40, 50, 26, colour, INK, 2.5, 6) + rect(-36, -66, 22, 34, colour, INK, 2.5, 6)
             + rect(-22, -14, 8, 14, colour, INK, 2, 2) + rect(12, -14, 8, 14, colour, INK, 2, 2)
             + path("M-18,-64 q8,10 4,24", "none", "#6e4726", 5))
        eyes_y, ex, cx = -54, 5, -25
    elif kind == "fox" or kind == "wolf":
        g = (rect(-26, -30, 52, 30, colour, INK, 2.5, 5) + rect(-30, -58, 32, 30, colour, INK, 2.5, 5)
             + poly([(-30, -58), (-26, -72), (-18, -58)], colour, INK, 2.5) + poly([(-10, -58), (-4, -72), (2, -58)], colour, INK,
                                                                                    2.5)
             + path("M24,-26 q22,-8 20,-30", "none", colour, 9) + path("M24,-26 q22,-8 20,-30", "none", INK, 2))
        if kind == "fox":
            g += rect(-26, -40, 20, 10, "#ffffff", None, 0, 3)
        eyes_y, ex, cx = -45, 7, -14
    elif kind == "child":
        g = (rect(-10, -38, 20, 24, SHIRT, INK, 2.5, 3) + rect(-9, -14, 8, 14, PANTS, INK, 2, 2) + rect(1, -14, 8, 14, PANTS, INK,
                                                                                                      2, 2)
             + rect(-12, -62, 24, 24, SKIN, INK, 2.5, 4) + rect(-12, -64, 24, 8, HAIR, INK, 2, 3))
        eyes_y, ex = -50, 5
    elif kind == "dragon":
        g = (path("M20,-18 q26,4 30,-18 q-2,10 -12,14", colour, INK, 2.5)                       # the tail
             + rect(-30, -36, 60, 36, colour, INK, 2.5, 16)                                       # the round body
             + poly([(-14, -36), (-8, -46), (-2, -36)], GOLD, INK, 1.6) + poly([(2, -36), (8, -46), (14, -36)], GOLD, INK, 1.6)
             + path("M-2,-30 Q12,-62 30,-52 Q22,-40 28,-30 Q14,-34 -2,-30 z", "#ffffff99", INK, 2)   # a little wing
             + rect(-46, -60, 36, 28, colour, INK, 2.5, 10)                                        # the head
             + rect(-58, -48, 18, 16, colour, INK, 2.5, 7)                                         # the snout
             + circle(-54, -42, 1.8, INK) + circle(-48, -42, 1.8, INK)
             + poly([(-40, -60), (-36, -72), (-32, -60)], GOLD, INK, 1.8) + poly([(-24, -60), (-20, -72), (-16, -60)], GOLD,
                                                                                   INK, 1.8))
        eyes_y, ex, cx = -48, 7, -28
    else:   # pup
        g = (rect(-26, -30, 52, 30, colour, INK, 2.5, 5) + rect(-30, -58, 32, 30, colour, INK, 2.5, 5)
             + rect(-32, -66, 10, 14, colour, INK, 2.5, 3) + rect(-10, -66, 10, 14, colour, INK, 2.5, 3))
        eyes_y, ex, cx = -45, 7, -14
    if eyes:
        for side in (-1, 1):
            g += circle(cx + side * ex, eyes_y, 6.5, "#ffffff", INK, 2) + circle(cx + side * ex + 2 * look, eyes_y + 1, 3, INK)
        if happy:
            g += path(f"M{cx - 5},{eyes_y + 10} q5,5 10,0", "none", INK, 2.2)
    else:   # asleep: closed eyes
        for side in (-1, 1):
            g += path(f"M{cx + side * ex - 5},{eyes_y} q5,4 10,0", "none", INK, 2.2)
    g += rect(-14, -2, 10, 5, dark, None, 0, 2) + rect(4, -2, 10, 5, dark, None, 0, 2)
    return group(g, x, y - hop, s)


def outline_of(x, y, s, kind):
    """An empty glowing outline where a number wanted one more."""
    g = buddy(0, 0, 1.0, "none", kind, False)
    return group(g, x, y, s, 0, 0.45).replace(f'stroke="{INK}"', 'stroke="#ffe08a" stroke-dasharray="5 4"')


def ink_copy(x, y, s, kind, colour="#1f1a2e"):
    return group(buddy(0, 0, 1.0, "#3c3a5a", kind, True), x, y, s, 0, 0.42)


def jumble(x, y, s=1.0, giggle=True):
    """The Jumble: a round ink blob with big white eyes and letter feet."""
    g = path("M-34,0 Q-44,-30 -26,-46 Q-6,-64 18,-52 Q42,-40 36,-14 Q34,6 10,8 Q-14,10 -34,0 z", JUMBLE, INK, 2.5)
    g += circle(-10, -30, 11, "#ffffff", INK, 2) + circle(14, -30, 11, "#ffffff", INK, 2)
    g += circle(-8, -28, 5, INK) + circle(16, -28, 5, INK) + circle(-6, -31, 1.8, "#ffffff") + circle(18, -31, 1.8, "#ffffff")
    if giggle:
        g += path("M-6,-12 q8,10 16,0", "#e85d75", INK, 2)
    g += text(-16, 20, "s", 20, "middle", "bold", JUMBLE) + text(14, 20, "z", 20, "middle", "bold", JUMBLE)
    g += circle(-46, -38, 4, JUMBLE) + circle(48, -50, 3, JUMBLE) + circle(-40, -56, 2.5, JUMBLE)
    return group(g, x, y, s)


def inkwell(x, y, s=1.0):
    g = (rect(-26, -30, 52, 30, "#3a3a5a", INK, 2.5, 8) + rect(-14, -40, 28, 12, "#2a2a44", INK, 2.5, 3)
         + ellipse(0, -40, 13, 4, JUMBLE, None, 0))
    return group(g, x, y, s)


def hoot(x, y, s, wing_up=False):
    """Professor Hoot, the blocky owl, in a purple wizard's hat with gold stars, feet at (x, y)."""
    g = (rect(-22, -60, 44, 56, HOOT, INK, 2.5, 8) + rect(-14, -36, 28, 28, HOOT_LIGHT, None, 0, 6)
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
    g += ellipse(0, -60, 30, 6, HAT_DARK, INK, 2)
    g += path("M-20,-62 Q-4,-70 2,-108 Q8,-100 20,-62 z", HAT, INK, 2.2)
    g += star(-4, -76, 5, GOLD) + star(8, -88, 4, GOLD) + star(10, -68, 3, GOLD)
    return group(g, x, y, s)


def avatar(x, y, s, arm_up=False):
    g = (rect(-10, -40, 20, 26, SHIRT, INK, 2.5, 3) + rect(-9, -14, 8, 14, PANTS, INK, 2, 2) + rect(1, -14, 8, 14, PANTS, INK, 2, 2)
         + rect(-12, -64, 24, 24, SKIN, INK, 2.5, 4) + rect(-12, -66, 24, 8, HAIR, INK, 2, 3)
         + circle(-5, -52, 2.2, INK) + circle(5, -52, 2.2, INK))
    if arm_up:
        g += rect(10, -60, 7, 24, SKIN, INK, 2, 3)
    else:
        g += rect(10, -40, 7, 22, SKIN, INK, 2, 3)
    g += rect(-17, -40, 7, 22, SKIN, INK, 2, 3)
    return group(g, x, y, s)


def bubble(x, y, w, h, body="", tail="left"):
    """A thought bubble; (x, y) is its centre."""
    sx = -1 if tail == "left" else 1
    out = (ellipse(x, y, w / 2, h / 2, "#ffffff", "#9fb4c2", 2.5)
           + circle(x + sx * w * 0.28, y + h / 2 + 10, 7, "#ffffff", "#9fb4c2", 2)
           + circle(x + sx * w * 0.36, y + h / 2 + 24, 4, "#ffffff", "#9fb4c2", 2))
    return out + body


def cheese(x, y, s=1.0):
    return group(poly([(-22, 8), (22, 8), (22, -6), (-22, -14)], "#ffd166", INK, 2.2) + circle(-6, 0, 3, "#e8b84a")
                 + circle(10, -2, 2.5, "#e8b84a"), x, y, s)


def lantern(x, y, s=1.0):
    return group(rect(-8, -22, 16, 22, "#ffcf4d", INK, 2, 4) + rect(-4, -28, 8, 6, INK, None, 0, 2)
                 + circle(0, -11, 14, "url(#glow-gold)", None, 0), x, y, s)


def photo_frame(x, y, w, h, kind):
    """A bubble's time frame: 'past' (an old photo, sepia, a curled corner), 'now', 'future' (dotted, a little sun)."""
    if kind == "past":
        return (rect(x - w / 2, y - h / 2, w, h, "#e9dcc0", "#8a6a40", 3, 4)
                + poly([(x + w / 2 - 18, y + h / 2), (x + w / 2, y + h / 2 - 18), (x + w / 2, y + h / 2)], "#cbb489",
                       "#8a6a40", 2))
    if kind == "future":
        return (rect(x - w / 2, y - h / 2, w, h, "#ffffff", TEAL_DARK, 3, 4, 1, 'stroke-dasharray="8 6"')
                + circle(x + w / 2 - 16, y - h / 2 + 16, 8, GOLD, GOLD_DARK, 1.5))
    return rect(x - w / 2, y - h / 2, w, h, "#ffffff", INK, 3, 4)


# --- Places -----------------------------------------------------------------------------------------------------------
def tower(x, base, s=1.0, lit=True):
    """The Word Tower: a slim cream tower with round windows in a spiral, a dome and a golden quill weathervane."""
    g = ""
    w, h = 90, 420
    g += rect(-w / 2, -h, w, h, "url(#stone)", INK, 3, 6)
    for k in range(6):
        wy = -100 - k * 52
        wx = -22 + (k % 3) * 22
        g += circle(wx, wy, 11, "#ffd58a" if lit else "#556", INK, 2.2)
        if lit:
            g += circle(wx, wy, 22, "url(#glow-warm)", None, 0, 0.6)
    g += rect(-w / 2 - 10, -h - 16, w + 20, 18, STONE_DARK, INK, 2.5, 4)
    g += path(f"M{-w / 2 - 4},{-h - 16} Q0,{-h - 120} {w / 2 + 4},{-h - 16} z", "url(#dome)", INK, 3)
    for sx, sy in ((-18, -h - 50), (10, -h - 70), (22, -h - 36), (-6, -h - 86)):
        g += star(sx, sy, 5, STAR)
    g += line(0, -h - 100, 0, -h - 150, GOLD_DARK, 3)
    g += path(f"M0,{-h - 150} q30,-6 44,-30 q-26,8 -44,22 z", GOLD_LIGHT, GOLD_DARK, 2)
    g += rect(-18, -48, 36, 48, WOOD_DARK, INK, 2.5, 16)
    g += circle(0, -66, 12, GOLD_LIGHT, GOLD_DARK, 2) + path("M-6,-66 L6,-66 M0,-72 L0,-60", "none", WOOD_DARK, 2)
    return group(g, x, base, s)


def lectern(x, y, w, s=1.0):
    g = (rect(-w * 0.2, 0, w * 0.4, 120, "url(#wood)", INK, 3, 6) + rect(-w * 0.32, 112, w * 0.64, 22, WOOD_DARK, INK, 3, 6)
         + poly([(-w / 2, 0), (w / 2, 0), (w / 2 - 20, 24), (-w / 2 + 20, 24)], WOOD, INK, 3))
    return group(g, x, y, s)


# ======================================================================================================================
# The pictures
# ======================================================================================================================
def pic_tower():
    W, H = 1800, 1040
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Word Tower", "The English door of the Discovery Academy. At its top, the Great Book: whatever "
                      "is written true on its ribbon comes true in its valley")
    # left panel: outside at night
    body += rect(30, 120, 640, 880, "url(#sky-night)", None, 0, 26)
    body += circle(560, 220, 46, "#fffbe6") + circle(560, 220, 90, "url(#glow-moon)", None, 0)
    rng = random.Random(3)
    for _ in range(26):
        body += circle(rng.uniform(50, 650), rng.uniform(140, 560), rng.uniform(1, 2.5), "#ffffff", None, 0, 0.8)
    body += rect(30, 830, 640, 170, "#3c5a3a", None, 0, 0)
    body += path("M30,830 Q200,790 360,830 Q520,860 670,820 L670,1000 L30,1000 z", "#4f7a4a", None, 0)
    body += tower(330, 900, 1.25)
    for i, ch in enumerate("abcwordsmagic"):
        lx = 330 + math.sin(i * 1.7) * 120 + i * 6
        ly = 330 - i * 16 + math.cos(i) * 20
        body += text(lx, ly, ch, 18 + (i % 3) * 4, "middle", "bold", "#ffe9a8", op=0.85)
    for gx in (110, 190, 470, 550):
        body += rect(gx - 8, 840, 16, 70, STONE_DARK, INK, 2, 3) + circle(gx, 830, 14, "#ffd58a", INK, 2)
    body += callout(56, 140, ["The Word Tower, at night", "letters drift from its dome"])
    body += callout(56, 900, ["The Academy's English door", "(W1's Word Tower) leads in"], 300, 870)
    # right panel: the top room
    X0 = 700
    body += rect(X0, 120, 1070, 880, "url(#wall-in)", None, 0, 26)
    body += path(f"M{X0},{560} Q{X0 + 535},{40} {X0 + 1070},{560} L{X0 + 1070},{120} L{X0},{120} z", "url(#dome)", None, 0)
    for _ in range(40):
        body += star(rng.uniform(X0 + 40, X0 + 1030), rng.uniform(140, 470), rng.uniform(3, 7), STAR, None, 1,
                     rng.uniform(0.5, 1.0))
    body += circle(X0 + 535, 380, 120, "#2a3a80", "#c9b27a", 6) + circle(X0 + 535, 380, 60, "#fffbe6", None, 0, 0.25)
    # shelves with cards
    for side in (-1, 1):
        sx = X0 + 535 + side * 400
        for row in range(3):
            sy = 420 + row * 110
            body += rect(sx - 110, sy, 220, 14, WOOD, INK, 2.5, 3)
            for k in range(4):
                body += rect(sx - 96 + k * 50, sy - 52, 40, 50, PARCH, PARCH_EDGE, 1.6, 5)
                body += line(sx - 88 + k * 50, sy - 30, sx - 64 + k * 50, sy - 30, WORD_INK, 2.5)
                body += circle(sx - 76 + k * 50, sy - 30, 22, "url(#glow-gold)", None, 0, 0.35)
    body += rect(X0, 860, 1070, 140, "url(#floor)", None, 0, 0)
    # the lectern and the Book with its valley
    body += lectern(X0 + 535, 760, 520)
    body += open_book(X0 + 535, 735, 560, 90)
    body += valley(X0 + 535, 735, 520, colours=0.55, s=1.0)
    body += buddy(X0 + 380, 718, 0.55, "#7bd389", "frog")
    body += buddy(X0 + 470, 724, 0.45, BUDDY_COLOURS[4], "mouse") + buddy(X0 + 500, 724, 0.45, BUDDY_COLOURS[2], "mouse")
    # ribbon
    rb, _ = ribbon(X0 + 250, 800, ["A", ("card", "frog", "", "frog"), ("card", "jumps", "s", "jump"), ], gap_w=120, h=64)
    body += group(rb, 0, 0, 1.0)
    body += inkwell(X0 + 870, 762, 1.0) + jumble(X0 + 900, 700, 0.6)
    body += hoot(X0 + 220, 760, 1.15, True)
    body += callout(X0 + 30, 140, ["The star-domed room", "shelves of word cards that speak"])
    body += callout(X0 + 700, 540, ["The Great Book", "a pop-up valley in pencil,", "blooming into colour where",
                                     "the words come true"], X0 + 640, 650)
    body += callout(X0 + 30, 880, ["The Spell Ribbon and the star", "(the full stop casts the spell)"], X0 + 300, 812)
    body += callout(X0 + 820, 860, ["The Jumble", "lives in the inkwell"], X0 + 900, 700)
    body += callout(X0 + 30, 590, ["Professor Hoot", "in his wizard's hat"], X0 + 220, 680)
    return svg(W, H, body)


def pic_verb():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The verb: write it true",
                      "Look at the wish, touch cards to hear them, lay them on the ribbon, touch the star. The world does "
                      "exactly what the sentence says")
    titles = ["1. The wish", "2. The cards speak", "3. Write it", "4. It comes true"]
    for i, t in enumerate(titles):
        x0 = 34 + i * 436
        body += rect(x0, 120, 418, 640, "#f6efe1", "#e6dcc8", 2, 18)
        body += pill(x0 + 209, 162, t, 22)
    # 1. the wish
    x0 = 34
    body += buddy(x0 + 120, 640, 1.2, BUDDY_COLOURS[0], "pup", look=1)
    bub = (buddy(x0 + 200, 400, 0.55, BUDDY_COLOURS[4], "mouse") + buddy(x0 + 240, 405, 0.55, BUDDY_COLOURS[2], "mouse")
           + buddy(x0 + 280, 400, 0.55, BUDDY_COLOURS[1], "mouse") + cheese(x0 + 245, 430, 1.0))
    body += bubble(x0 + 240, 400, 250, 170, bub)
    body += lines_of_text(x0 + 209, 690, ["a picture, never words; Hoot says", "\"Someone's hungry for cheese!\""], 17,
                          fill=SOFT_INK)
    # 2. the cards speak
    x0 = 34 + 436
    for k, (w_, e_, bd) in enumerate((("three", "", None), ("two", "", None), ("a", "", None))):
        body += word_card(x0 + 90 + k * 120, 300, w_, e_, w=104, h=58, size=24)
    for k, (w_, e_) in enumerate((("mouse", ""), ("mice", ""), ("mouses", "s"))):
        body += word_card(x0 + 209, 410 + k * 82, w_, e_, w=200, h=62, badge_kind="mouse", speaking=(k == 1))
    body += hand_pointer(x0 + 300, 512, 1.0)
    body += text(x0 + 330, 470, "\"mice\"", 22, "start", "bold", GOLD_DARK, italic=True)
    body += lines_of_text(x0 + 209, 690, ["each card says its word when touched;", "the badge shows ONE mouse on all three"],
                          17, fill=SOFT_INK)
    # 3. write it
    x0 = 34 + 872
    rb, end = ribbon(0, 0, [("card", "three", "", None), ("card", "mice", "", "mouse")], gap_w=120, h=66, star_ring=True)
    body += group(rb, x0 + 20, 320, 0.86)
    body += lines_of_text(x0 + 209, 400, ["Three  mice  ate the cheese  ★"], 22, weight="bold", fill=WORD_INK)
    body += note(x0 + 209, 440, "(the frame's words are written on the ribbon too)", 15)
    body += star(x0 + 300, 540, 34, GOLD, GOLD_DARK, 2) + circle(x0 + 300, 540, 48, "url(#glow-teal)", None, 0)
    body += hand_pointer(x0 + 312, 560, 1.2)
    body += lines_of_text(x0 + 209, 690, ["the star lights when every gap is full;", "a touch casts (in VR: the Magic Wand)"],
                          17, fill=SOFT_INK)
    # 4. it comes true
    x0 = 34 + 1308
    body += open_book(x0 + 209, 560, 360, 70)
    body += valley(x0 + 209, 560, 330, colours=1.0, s=0.75)
    for k in range(3):
        body += buddy(x0 + 150 + k * 46, 548, 0.6, BUDDY_COLOURS[(k + 2) % 6], "mouse")
    body += cheese(x0 + 290, 540, 0.9)
    body += curve_arrow(x0 + 80, 250, x0 + 60, 420, x0 + 160, 500, JUMBLE, 7, "ink")
    for k, ch in enumerate("Three mice"):
        body += text(x0 + 70 + k * 18, 240 - k * 4, ch, 22, "middle", "bold", JUMBLE)
    body += sparkle(x0 + 120, 470, 1.3, GOLD) + sparkle(x0 + 330, 480, 1.0, GOLD)
    body += tick(x0 + 360, 300)
    body += lines_of_text(x0 + 209, 690, ["Hoot reads it, each word lighting;", "the ink flies; the meadow blooms"], 17,
                          fill=SOFT_INK)
    # the Jumble's wrong cast
    body += rect(34, 790, 1100, 300, "#f3eefc", "#d9cdf2", 2, 18)
    body += pill(280, 834, "The Jumble's word: \"three mouses\"", 22, LILAC)
    body += inkwell(150, 1010, 1.4) + jumble(180, 920, 1.0)
    body += sparkle(240, 880, 1.0, JUMBLE) + text(250, 900, "ta-da!", 18, "start", "bold", JUMBLE, italic=True)
    body += lines_of_text(330, 900, ["A made-up word is a card like any other (it must be heard or read to be",
                                     "told apart). Cast, it brings the Jumble out of the inkwell instead of mice:",
                                     "it giggles, sneezes ink and hops home. Hoot: \"Oops! That's not a real word.\"",
                                     "Then: \"One mouse, two mice. Some words change inside.\" The ink flows back;",
                                     "nothing is spoilt. A wrong cast costs only that wish's first-time star."], 17,
                          "start")
    body += rect(1160, 790, 606, 300, "#eef7f0", "#cfe6d4", 2, 18)
    body += pill(1463, 834, "Why only the first cast counts", 22, "#3a8a5a")
    body += lines_of_text(1186, 890, ["If the ribbon showed what a spell would do before", "the star, or if second casts "
                                      "counted, trying cards", "until it looks right would win: the model's",
                                      "trial-and-error player then reaches the bar on 100 %", "of visits. With the first cast "
                                      "counting and no preview,", "0 %: the form has to be chosen, which is the grammar."],
                          17, "start")
    return svg(W, H, body)


def mini_ribbon(x, y, words, w=None, size=19):
    """A small ribbon label with a spell's words (the gold parts in gold)."""
    total = sum(len(t) for t, _ in words)
    w = w or total * size * 0.6 + 70
    out = path(f"M{x - w / 2},{y - 20} L{x + w / 2},{y - 20} L{x + w / 2 - 10},{y} L{x + w / 2},{y + 20} L{x - w / 2},{y + 20} "
               f"L{x - w / 2 + 10},{y} z", "url(#gold)", GOLD_DARK, 2)
    out += spans(x - 8, y + 7, [(t, c) for t, c in words], size)
    out += star(x + w / 2 - 22, y, 9, GOLD_LIGHT, GOLD_DARK, 1.2)
    return out


def pic_literal():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The literal world: a wrong word does exactly what it says",
                      "The Spell Reader reads the sentence, not the wish. Every difference of form becomes something "
                      "you can see, and it's funny, never a red cross")
    tiles = [
        ("Five duck flew.", [("Five ", WORD_INK), ("duck", WORD_INK), (" flew.", WORD_INK)], "number: one duck came,",
         "and four empty outlines flap"),
        ("Three mouses …", [("Three ", WORD_INK), ("mouse", WORD_INK), ("s", GOLD_DARK), (" ate …", WORD_INK)],
         "a made-up word: the Jumble", "comes instead of mice"),
        ("The dragons snores.", [("The dragons ", WORD_INK), ("snore", WORD_INK), ("s", GOLD_DARK), (".", WORD_INK)],
         "agreement: one dragon snores,", "the others sleep on"),
        ("The baby sneeze.", [("The baby ", WORD_INK), ("sneeze", WORD_INK), (".", WORD_INK)], "the plain verb: ink copies",
         "join in and sneeze too"),
        ("It sings.", [("A frog sat on a log. ", WORD_INK), ("It", WORD_INK), (" sang.", WORD_INK)], "a pronoun sticks to the",
         "nearest single thing: the log"),
        ("… school with a wagging tail", [("I saw a dog by the school ", WORD_INK), ("with a wagging tail.", GOLD_DARK)],
         "a phrase sticks to the noun", "beside it: the school's tail"),
        ("a cat dog", [("Bring a cat", WORD_INK), (" ", WORD_INK), ("dog and a fish", WORD_INK)],
         "no list comma: a cat and a dog", "fuse into a cat-dog"),
        ("Let's paint Pip!", [("Let's paint", WORD_INK), (" ", WORD_INK), ("Pip!", WORD_INK)], "no comma before a name:",
         "Pip is the thing painted"),
    ]
    for i, (key, words, n1, n2) in enumerate(tiles):
        col, row = i % 4, i // 4
        x0, y0 = 34 + col * 436, 122 + row * 490
        body += rect(x0, y0, 418, 470, "#fffaf2", "#e6dcc8", 2, 18)
        n = len("".join(t for t, _ in words))
        body += mini_ribbon(x0 + 209, y0 + 44, words, 396, 13 if n > 40 else 16 if n > 26 else 19)
        cx, cy = x0 + 209, y0 + 330
        body += ellipse(cx, cy + 6, 170, 26, "#e9e3d3", None, 0)
        if i == 0:
            body += buddy(cx - 110, cy - 30, 0.85, "#ffd166", "duck")
            for k in range(4):
                body += outline_of(cx - 30 + k * 50, cy - 40 - (k % 2) * 18, 0.75, "duck")
            body += hmm(cx + 150, y0 + 110)
        elif i == 1:
            body += inkwell(cx - 70, cy, 1.2) + jumble(cx + 10, cy - 60, 1.2) + cheese(cx + 120, cy - 8, 1.1)
            body += text(cx + 90, cy - 120, "ta-da!", 20, "middle", "bold", JUMBLE, italic=True)
        elif i == 2:
            for k in range(4):
                bx = cx - 120 + k * 80
                body += buddy(bx, cy, 0.7, DRAGON[k], "dragon", eyes=False)
            body += zzz(cx - 140, cy - 60, 1.3, INK)
            body += text(cx + 80, cy - 70, "(quiet)", 16, "middle", "normal", SOFT_INK, italic=True)
        elif i == 3:
            body += buddy(cx - 20, cy, 0.8, "#ff7eb6", "dragon")
            for k, dx in enumerate((-110, 80, 150)):
                body += ink_copy(cx + dx, cy - 6, 0.7, "dragon")
            for dx in (-60, -20, 120, 190):
                body += circle(cx + dx - 40, cy - 70, 7, "#ffb347", None, 0, 0.9)
        elif i == 4:
            body += rect(cx - 120, cy - 40, 240, 40, WOOD, INK, 2.5, 18)
            body += circle(cx - 40, cy - 22, 7, "#ffffff", INK, 2) + circle(cx + 10, cy - 22, 7, "#ffffff", INK, 2)
            body += circle(cx - 38, cy - 21, 3, INK) + circle(cx + 12, cy - 21, 3, INK)
            body += ellipse(cx - 15, cy - 10, 12, 7, "#e85d75", INK, 2)
            body += notes_glyph(cx + 60, cy - 70, 1.3, INK) + notes_glyph(cx + 110, cy - 100, 1.0, INK)
            body += buddy(cx - 140, cy - 40, 0.55, "#7bd389", "frog", look=1)
        elif i == 5:
            body += rect(cx - 90, cy - 120, 180, 120, "#f3dcc0", INK, 3, 4)
            body += poly([(cx - 104, cy - 120), (cx, cy - 175), (cx + 104, cy - 120)], ROOF, INK, 3)
            body += rect(cx - 20, cy - 60, 40, 60, WOOD_DARK, INK, 2.5, 3)
            body += path(f"M{cx + 90},{cy - 40} q60,-10 60,-70 q10,40 -20,80", "#c58a5a", INK, 2.5)
            body += buddy(cx - 150, cy, 0.6, "#c58a5a", "pup")
        elif i == 6:
            g = (rect(-60, -40, 100, 40, "#f2b54a", INK, 2.5, 6) + rect(-72, -70, 34, 32, "#f2b54a", INK, 2.5, 6)
                 + poly([(-72, -70), (-68, -84), (-60, -70)], "#f2b54a", INK, 2) + rect(10, -74, 40, 38, "#c58a5a", INK, 2.5, 6)
                 + rect(18, -84, 10, 14, "#c58a5a", INK, 2, 3) + rect(36, -84, 10, 14, "#c58a5a", INK, 2, 3))
            for ex in (-60, -48, 24, 38):
                g += circle(ex, -56, 5, "#ffffff", INK, 1.6) + circle(ex + 1, -55, 2.2, INK)
            body += group(g, cx, cy, 1.3)
            body += hmm(cx + 150, y0 + 110)
        else:
            body += buddy(cx, cy, 1.0, "#ffd166", "pup")
            for k, (dx, dy, c) in enumerate(((-14, -40, "#ff7eb6"), (10, -20, "#6ec6ff"), (-24, -12, "#7bd389"),
                                             (6, -54, "#b18cff"))):
                body += circle(cx + dx, cy + dy, 9, c, None, 0, 0.85)
            body += buddy(cx - 130, cy, 0.7, BUDDY_COLOURS[1], "bunny") + rect(cx - 104, cy - 50, 8, 40, WOOD, INK, 2, 2)
            body += buddy(cx + 130, cy, 0.7, BUDDY_COLOURS[3], "pup", look=-1)
        body += text(cx, y0 + 420, n1, 17, "middle", "bold", INK)
        body += text(cx, y0 + 444, n2, 17, "middle", "normal", SOFT_INK)
    return svg(W, H, body)


def pic_page():
    W, H = 1800, 920
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The First Page, beat by beat (phase B)",
                      "Four taught moments, eight judged wishes, the Story Parade. The valley turns from pencil to colour "
                      "as the wishes come true")
    beats = [
        ("0:00", "arrival", "up the stair; Hoot", None),
        ("0:20", "T1 ghost", "\"A frog jumps.\"", "frog"),
        ("0:45", "T2 free", "your own spells", "dragon"),
        ("1:50", "T3 ghost", "\"Three frogs swim.\"", "frog"),
        ("2:15", "T4 trap", "one duck, 4 outlines", "duck"),
        ("2:45", "J1", "a fox (one)", "fox"),
        ("3:10", "J2", "boxes (-es)", "box"),
        ("3:35", "J3", "mice (wild)", "mouse"),
        ("4:00", "J4", "a goose (one)", "goose"),
        ("4:25", "J5", "the leaves (-ves)", "leaf"),
        ("4:50", "J6", "ponies (-ies)", "pony"),
        ("5:15", "J7", "children / sheep", "sheep"),
        ("5:40", "J8", "the Story Parade", "star"),
    ]
    y = 330
    x0, x1 = 80, 1720
    body += line(x0, y, x1, y, INK, 4)
    for i, (t, name, desc, kind) in enumerate(beats):
        x = x0 + (x1 - x0) * i / (len(beats) - 1)
        judged = name.startswith("J")
        body += circle(x, y, 20, GOLD if judged else "#ffffff", INK, 3)
        if judged:
            body += star(x, y, 10, "#ffffff")
        body += text(x, y - 40, t, 16, "middle", "bold", SOFT_INK)
        body += text(x, y + 52, name, 17, "middle", "bold", INK)
        for k, r in enumerate(wrap(desc, 13)):
            body += text(x, y + 76 + k * 20, r, 14, "middle", "normal", SOFT_INK)
        if kind:
            body += badge(x, y - 100, 26, kind)
    body += rect(40, 120, 300, 36, "#ffffff", "#9fb4c2", 1.5, 8)
    body += circle(60, 138, 9, GOLD, INK, 2) + text(80, 144, "judged: a SkillShown event", 15, "start")
    # the valley strip blooming
    body += text(80, 520, "The valley, from the first wish to the Parade:", 20, "start", "bold")
    for k in range(5):
        vx = 230 + k * 340
        body += open_book(vx, 760, 300, 46)
        body += valley(vx, 760, 280, colours=k / 4.0, s=0.62)
        body += text(vx, 830, ["pencil", "the pond", "the meadow", "the hills", "all in colour"][k], 16, "middle",
                     "normal", SOFT_INK)
    body += lantern(1590, 700, 1.1) + lantern(1640, 690, 1.1)
    body += buddy(1540, 735, 0.42, "#ffffff", "goose") + buddy(1600, 742, 0.42, "#ffffff", "sheep")
    body += note(W / 2, 880, "About 6-7 minutes for a child who knows the idea; never timed. After two wrong casts the "
                 "ghost lays one card (that wish counts as helped).", 16)
    return svg(W, H, body)


def pic_dragons():
    W, H = 1800, 1060
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The Sleepy Dragons: the transfer (phase B)",
                      "On a noun an s means more; on a verb it means one. The First Page's habit picks the wrong form "
                      "every time")
    for i, (label, spell, good) in enumerate((
            ("The habit: \"an s means more\"", [("The dragons ", WORD_INK), ("snore", WORD_INK), ("s", GOLD_DARK),
                                                (", and the baby ", WORD_INK), ("sneeze", WORD_INK), (".", WORD_INK)], False),
            ("The idea: the verb agrees", [("The dragons ", WORD_INK), ("snore", WORD_INK), (", and the baby ", WORD_INK),
                                           ("sneeze", WORD_INK), ("s", GOLD_DARK), (".", WORD_INK)], True))):
        x0 = 34 + i * 880
        body += rect(x0, 120, 852, 640, "url(#sky-night)", None, 0, 22)
        body += circle(x0 + 600, 420, 40, "#fffbe6") + circle(x0 + 600, 420, 80, "url(#glow-moon)", None, 0)
        body += path(f"M{x0},{620} Q{x0 + 300},{520} {x0 + 560},{600} Q{x0 + 720},{640} {x0 + 852},{590} L{x0 + 852},{760} "
                     f"L{x0},{760} z", "#3c5a3a", None, 0)
        body += pill(x0 + 426, 168, label, 22, LILAC if not good else "#3a8a5a")
        body += mini_ribbon(x0 + 426, 236, spell, 760, 20)
        for k in range(4):
            bx = x0 + 150 + k * 110
            awake = good or k == 0
            body += buddy(bx, 640, 0.95, DRAGON[k], "dragon", eyes=False)
            if awake:
                body += zzz(bx - 10, 560, 1.2, "#ffffff")
        bbx = x0 + 680
        body += buddy(bbx, 660, 0.7, DRAGON[4], "dragon")
        body += circle(bbx - 46, 610, 8, "#ffb347", None, 0) + circle(bbx - 56, 598, 6, "#ff8a2a", None, 0)
        if not good:
            for dx in (-90, 70, 120):
                body += ink_copy(bbx + dx, 660, 0.6, "dragon")
                body += circle(bbx + dx - 34, 618, 6, "#ffb347", None, 0, 0.8)
            body += hmm(x0 + 790, 330)
            body += lines_of_text(x0 + 426, 720, ["one dragon snores, three sleep on; ink copies of the baby sneeze too"],
                                  17, fill="#ffffff")
        else:
            body += tick(x0 + 790, 330)
            body += lines_of_text(x0 + 426, 720, ["all four snore; the baby sneezes alone: the bubble, exactly"], 17,
                                  fill="#ffffff")
        bub = "".join(buddy(x0 + 110 + k * 26, 355, 0.32, DRAGON[k], "dragon", eyes=False) for k in range(4))
        bub += buddy(x0 + 240, 360, 0.3, DRAGON[4], "dragon") + circle(x0 + 222, 338, 4, "#ffb347", None, 0)
        bub += zzz(x0 + 110, 318, 0.6, INK)
        body += bubble(x0 + 175, 340, 230, 110, bub, "right")
    body += rect(34, 790, 1732, 240, "#fffaf2", "#e6dcc8", 2, 18)
    body += word_card(200, 870, "foxes", "es", w=180, badge_kind="fox")
    body += text(200, 940, "a noun: s means MORE", 18, "middle", "bold")
    body += word_card(520, 870, "snores", "s", w=190, badge_kind="snore")
    body += text(520, 940, "a verb: s means ONE", 18, "middle", "bold")
    body += lines_of_text(720, 845, ["Children learn the plural s years before the verb's s (Brown's order of the 14",
                                     "morphemes, §2.1). The dragons' six wishes link two or three choices each (two",
                                     "clauses, or a pronoun and its verb) and have two subjects joined by \"and\"."], 18,
                          "start")
    body += lines_of_text(720, 935, ["The model (1,000 visits, the bar 5 of 6): the First Page's habit 0 %; copies the "
                                     "subject's", "ending 0 %; the nearest noun 0 %; a coin 0.1 %; the idea 100 % "
                                     "(slips 4 %: 89.3 %)."], 18, "start", "bold")
    return svg(W, H, body)


def pic_loop():
    W, H = 1800, 860
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The core loop", "Four rhythms, from a card in the hand to a tower climbed over the school years")
    boxes = [
        ("Every 10 seconds", "a card", ["lift a card: it says", "its word; lay it", "in a gap: click"], "card"),
        ("Every minute", "a wish", ["fill the gaps, touch", "the star: Hoot reads,", "the ink flies, it comes",
                                    "true, the patch blooms"], "wish"),
        ("Every 10 minutes", "a page", ["the valley fills with", "colour; the Story", "Parade; dawn turns", "the page"],
         "page"),
        ("Days and weeks", "the floors", ["a floor a school year:", "new runes and marks,", "new Books; golden words;",
                                          "your own page"], "tower"),
    ]
    for i, (t, sub, rows, kind) in enumerate(boxes):
        x0 = 40 + i * 436
        body += rect(x0, 130, 410, 640, "#fffaf2", "#e6dcc8", 2, 20)
        body += pill(x0 + 205, 172, t, 22)
        body += text(x0 + 205, 228, sub, 26, "middle", "bold", GOLD_DARK)
        cx, cy = x0 + 205, 380
        if kind == "card":
            body += word_card(cx, cy, "mice", "", w=190, badge_kind="mouse", speaking=True)
            body += hand_pointer(cx + 40, cy + 30, 1.3)
        elif kind == "wish":
            rb, _ = ribbon(0, 0, [("card", "three", "", None), ("card", "mice", "", "mouse")], gap_w=110, h=60)
            body += group(rb, cx - 170, cy, 0.68)
            body += curve_arrow(cx, cy + 40, cx + 40, cy + 100, cx + 10, cy + 140, JUMBLE, 5)
            for k in range(3):
                body += buddy(cx - 50 + k * 40, cy + 170, 0.5, BUDDY_COLOURS[k + 1], "mouse")
        elif kind == "page":
            body += open_book(cx, cy + 120, 330, 50)
            body += valley(cx, cy + 120, 310, colours=1.0, s=0.7)
            body += lantern(cx - 60, cy + 100, 0.8) + lantern(cx + 60, cy + 96, 0.8)
        else:
            body += tower(cx, cy + 190, 0.5)
            for k in range(6):
                body += text(cx + 60, cy + 160 - k * 36, f"grade {k + 3}", 15, "start", "normal", SOFT_INK)
        body += lines_of_text(x0 + 205, 640, rows, 18, fill=SOFT_INK)
        if i < 3:
            body += line(x0 + 414, 450, x0 + 432, 450, INK, 4, 1, "ink")
    body += note(W / 2, 820, "Inside a page: a new kind of wish shown once by the ghost, three or four that use it, a mixed "
                 "run, then the Parade. Nothing is ever timed.", 16)
    return svg(W, H, body)


def pic_ladder():
    W, H = 1800, 1180
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The ladder: the tower's six floors, grades 3-8",
                      "One floor a school year, each with its own Great Book; the grade picks the floor after the prologue; "
                      "every floor stays open")
    floors = [
        ("8", "The Rule Stones", "verbals · the Spotlight (voice) · moods and rule stones · pause marks · "
         "word webs", "8.T1 The Valley's Rulebook"),
        ("7", "The Observatory", "clause stars · constellations (sentence kinds) · the Wandering Phrase · "
         "equal charms · the Word Forge III · the Tone Lantern", "7.T1 The Star Charts"),
        ("6", "The Loom", "Who Did It? (pronouns) · the Side-Note Gate · the Loom (combining) · the Word "
         "Forge II · word webs · Mood Dyes", "6.T1 The Museum Labels"),
        ("5", "The Clockwork Library", "the Clock of Before · Either-Or Doors · the Comma Bridge · the "
         "Title Shelves · the Word Forge · two-faced words", "5.T1 The Story Clock"),
        ("4", "The Rune Workshop", "the Ongoing Clock · charm string and place runes · the Which Gate · "
         "sentence seals · the Homophone Hall* · the Quotation Gate · Rune Bench II", "4.T1 The Map Room"),
        ("3", "The Summoning Hall", "THE FIRST PAGE and THE SLEEPY DRAGONS (phase B) · Who's Who · Time Windows "
         "· the Shaping Room · Chain Spells · the Speaking Stones · the Rune Bench · the "
         "Spelling Forge*", "3.T2 The Picnic Notes"),
    ]
    tx, tw = 50, 360
    top = 150
    fh = 150
    body += path(f"M{tx},{top} Q{tx + tw / 2},{top - 90} {tx + tw},{top} z", "url(#dome)", INK, 3)
    for k in range(5):
        body += star(tx + 70 + k * 40, top - 22 - (k % 2) * 16, 5, STAR)
    for i, (g, name, rooms, tr) in enumerate(floors):
        y = top + i * fh
        colour = ["#efe3ff", "#e3eeff", "#e3f7f1", "#fff1d9", "#ffe6e6", "#fff7d1"][i]
        body += rect(tx, y, tw, fh, colour, INK, 3)
        body += circle(tx + 54, y + fh / 2, 34, "#ffffff", INK, 3) + text(tx + 54, y + fh / 2 + 11, g, 32, "middle", "bold")
        body += text(tx + 104, y + fh / 2 - 6, f"Floor {g}", 18, "start", "bold", SOFT_INK)
        body += text(tx + 104, y + fh / 2 + 22, name, 19, "start", "bold")
        body += rect(tx + tw + 20, y + 12, 1330, fh - 24, "#ffffff", "#d7cdb9", 2, 14)
        for k, r in enumerate(wrap(rooms, 112)):
            body += text(tx + tw + 40, y + 46 + k * 26, r, 17, "start")
        body += text(tx + tw + 40, y + fh - 26, "transfer: " + tr, 16, "start", "bold", TEAL_DARK, italic=True)
    body += note(W / 2, top + 6 * fh + 70, "* a reading room (opens at stage 2, when the child's own reading has lit "
                 "enough words). Every transfer page is writing for someone: a buddy reads it and acts it out.", 16)
    body += note(W / 2, top + 6 * fh + 96, "36 units become P1 when their rooms ship (two more are open questions). "
                 "Phase B: the First Page and the Sleepy Dragons; phase C1: floors 3-4; C2: floors 5-8.", 16)
    return svg(W, H, body)


def pic_things():
    W, H = 1800, 1120
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Cards, runes and what they mean",
                      "Shape, motion and sound carry every meaning too; nothing depends on colour alone")
    body += rect(34, 120, 860, 470, "#fffaf2", "#e6dcc8", 2, 18)
    body += pill(464, 160, "A word card", 22)
    body += word_card(330, 330, "foxes", "es", w=330, h=120, size=56, badge_kind="fox", speaking=True)
    body += callout(56, 392, ["The picture badge: ONE fox,", "never how many; fades", "when the word lights"], 175, 280)
    body += callout(560, 200, ["The ending in gold ink", "the part that carries", "the grammar"], 430, 330)
    body += callout(560, 420, ["It speaks when touched", "never by itself"], 520, 290)
    body += word_card(470, 545, "mouses", "s", w=200, badge_kind="mouse")
    body += word_card(660, 545, "mice", "", w=150, badge_kind="mouse")
    body += text(470, 505, "a made-up word looks exactly like a real one", 15, "start", "normal", SOFT_INK)
    body += rect(910, 120, 856, 470, "#fffaf2", "#e6dcc8", 2, 18)
    body += pill(1338, 160, "The ribbon, the star, runes and marks", 22)
    rb, _ = ribbon(0, 0, ["The", ("gap", None), "danced", "."], gap_w=130, h=64, star_lit=False)
    body += group(rb, 950, 250, 0.9)
    body += note(1240, 310, "the star stays dim until every gap holds a card", 15)
    for k, (lab, kind) in enumerate((("un", "prefix"), ("re", "prefix"), ("dis", "prefix"), ("ful", "suffix"),
                                     ("less", "suffix"), ("able", "suffix"))):
        body += rune_tile(990 + k * 120, 390, lab, kind)
    body += note(1320, 440, "prefix runes snap to a card's front, suffix runes to its back (un + lock: the lock opens)", 15)
    marks = [(",", "the comma hook"), ("“ ”", "speech-bubble runes"), ("’", "the owner rune"),
             ("★", "the star: the full stop")]
    for k, (glyph, lab) in enumerate(marks):
        mx = 1000 + k * 200
        body += circle(mx, 510, 30, "url(#gold)", GOLD_DARK, 2) + text(mx, 522, glyph, 30, "middle", "bold", WORD_INK)
        body += text(mx, 562, lab, 14, "middle", "normal", SOFT_INK)
    body += rect(34, 610, 1732, 480, "#fffaf2", "#e6dcc8", 2, 18)
    body += pill(900, 650, "What the world shows", 22)
    items = [
        ("ink", "words fly as ink and dive into the page; a splash"),
        ("bloom", "a pencil patch floods with watercolour"),
        ("outline", "a number not filled: empty glowing outlines"),
        ("copies", "a plain verb with one doer: ink copies join in"),
        ("jumble", "a made-up word: the Jumble comes"),
        ("frames", "when: an old photo (it happened), now, a dotted plan"),
        ("glows", "gold: being said, lit · teal: ready · green: granted · lilac: not yet"),
        ("golden", "a golden word in the Spellbook: read by yourself"),
    ]
    for i, (kind, lab) in enumerate(items):
        col, row = i % 4, i // 4
        cx, cy = 190 + col * 430, 760 + row * 190
        if kind == "ink":
            for k, ch in enumerate("fox"):
                body += text(cx - 40 + k * 22, cy - 20 + k * 10, ch, 24, "middle", "bold", JUMBLE)
            body += curve_arrow(cx + 30, cy, cx + 70, cy + 10, cx + 60, cy + 50, JUMBLE, 5)
        elif kind == "bloom":
            body += circle(cx - 20, cy + 10, 44, PENCIL, PENCIL_LINE, 2) + circle(cx + 10, cy + 10, 34, GRASS, INK, 2)
            body += sparkle(cx + 30, cy - 20, 0.9, GOLD)
        elif kind == "outline":
            body += buddy(cx - 50, cy + 40, 0.6, "#ffd166", "duck")
            body += outline_of(cx + 20, cy + 30, 0.6, "duck") + outline_of(cx + 70, cy + 20, 0.6, "duck")
        elif kind == "copies":
            body += buddy(cx - 40, cy + 40, 0.6, "#ff7eb6", "dragon") + ink_copy(cx + 30, cy + 40, 0.55, "dragon")
            body += ink_copy(cx + 80, cy + 36, 0.5, "dragon")
        elif kind == "jumble":
            body += jumble(cx, cy + 30, 0.9)
        elif kind == "frames":
            for k, fk in enumerate(("past", "now", "future")):
                body += photo_frame(cx - 70 + k * 70, cy + 10, 56, 44, fk)
        elif kind == "glows":
            for k, c in enumerate((GOLD, TEAL, FAIR, LILAC)):
                body += circle(cx - 66 + k * 44, cy + 10, 16, c, INK, 1.5)
        else:
            body += rect(cx - 70, cy - 30, 140, 90, "#fff7e0", PARCH_EDGE, 2, 6)
            body += text(cx, cy + 4, "children", 20, "middle", "bold", GOLD_DARK) + text(cx, cy + 34, "geese", 20, "middle",
                                                                                        "bold", GOLD_DARK)
        for k, r in enumerate(wrap(lab, 46)):
            body += text(cx + 20, cy + 92 + k * 19, r, 15, "middle", "normal", SOFT_INK)
    return svg(W, H, body)


def vr_hand(x, y, s, rot=0, fill="#ffd9b8"):
    g = (rect(-26, -20, 52, 44, fill, INK, 2.5, 14) + rect(-30, -44, 13, 30, fill, INK, 2.2, 6)
         + rect(-15, -50, 13, 34, fill, INK, 2.2, 6) + rect(0, -48, 13, 32, fill, INK, 2.2, 6)
         + rect(15, -42, 12, 28, fill, INK, 2.2, 6))
    return group(g, x, y, s, rot)


def wand(x, y, s=1.0, rot=0):
    g = rect(-4, 0, 8, 120, "#6e4726", INK, 2, 3) + star(0, -6, 14, GOLD, GOLD_DARK, 1.5) + sparkle(16, -24, 0.8, GOLD_LIGHT)
    return group(g, x, y, s, rot)


def pic_vr():
    W, H = 1800, 1040
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("In VR: the cards in your hand, your wand on the star",
                      "The child stands at the lectern (no walking). Cards float in an arc; they speak in the hand; the "
                      "Book's valley is at waist height")
    body += rect(34, 120, 1732, 880, "url(#wall-in)", None, 0, 24)
    body += path("M34,600 Q900,40 1766,600 L1766,120 L34,120 z", "url(#dome)", None, 0)
    rng = random.Random(9)
    for _ in range(50):
        body += star(rng.uniform(60, 1740), rng.uniform(140, 420), rng.uniform(3, 7), STAR, None, 1, rng.uniform(0.5, 1))
    body += rect(34, 860, 1732, 140, "url(#floor)", None, 0)
    body += lectern(900, 760, 760, 1.0)
    body += open_book(900, 735, 820, 120)
    body += valley(900, 735, 760, colours=0.7, s=1.3)
    for k in range(3):
        body += buddy(700 + k * 50, 718, 0.6, BUDDY_COLOURS[k + 1], "mouse")
    body += cheese(860, 712, 1.0)
    words = [("three", "", None), ("mouses", "s", "mouse"), ("two", "", None), ("mouse", "", "mouse"), ("a", "", None)]
    for k, (w_, e_, bd) in enumerate(words):
        ang = -0.9 + k * 0.45
        cx, cy = 900 + math.sin(ang) * 560, 520 - math.cos(ang) * 120
        body += word_card(cx, cy, w_, e_, w=170 if bd else 130, badge_kind=bd, rot=ang * 12)
    body += word_card(470, 640, "mice", "", w=170, badge_kind="mouse", speaking=True, rot=-8)
    body += vr_hand(450, 742, 1.15, -10)
    body += text(470, 580, "\"mice\"", 22, "middle", "bold", GOLD_LIGHT, italic=True)
    rb, _ = ribbon(0, 0, [("card", "three", "", None), ("gap", None)], gap_w=130, h=66)
    body += group(rb, 640, 820, 0.85)
    body += wand(1240, 760, 1.2, -38)
    body += vr_hand(1290, 860, 1.4, 20)
    body += circle(1148, 820, 46, "url(#glow-teal)", None, 0)
    for k, ch in enumerate("Three mice"):
        body += text(980 + k * 22, 300 - k * 10, ch, 26, "middle", "bold", "#ffe9a8", op=0.9 - k * 0.04)
    body += callout(60, 140, ["A card speaks in your hand", "raise it to your ear to hear it again"], 470, 620)
    body += callout(1360, 140, ["Hoot reads the spell", "its words float up past your eyes"], 1100, 260)
    body += callout(1360, 900, ["Your own Magic Wand", "touches the star to cast", "(or a palm press; one-handed: triggers)"],
                    1180, 780)
    body += callout(60, 900, ["Let go over a gap: it settles", "elsewhere: it floats back to the arc"], 700, 820)
    body += hoot(250, 760, 1.2, True)
    return svg(W, H, body)


def pic_fade():
    W, H = 1800, 1160
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("The reading track: from listening to reading",
                      "How a child who can't read yet plays, and how their own reading moves the fade: the voice never "
                      "goes away, pictures leave word by word")
    cols = [
        ("Badges on", "every card speaks; a badge shows", "what the word is about", [("mice", "", "mouse", False)]),
        ("A word lights", "picked right WITHOUT touching it,", "three times in a row, in three wishes",
         [("mice", "", "mouse", True)]),
        ("Words only", "a lit word loses its badge (it still", "speaks when touched)", [("mice", "", None, False)]),
    ]
    for i, (t, l1, l2, cards) in enumerate(cols):
        x0 = 34 + i * 580
        body += rect(x0, 120, 560, 380, "#fffaf2", "#e6dcc8", 2, 18)
        body += pill(x0 + 280, 162, t, 22, GOLD_DARK if i == 1 else INK)
        for w_, e_, bd, lit in cards:
            body += word_card(x0 + 280, 300, w_, e_, w=260, h=96, size=44, badge_kind=bd, lit=lit,
                              speaking=(i == 0))
        if i == 1:
            for k in range(3):
                body += tick(x0 + 200 + k * 80, 395, 0.8)
        body += text(x0 + 280, 445, l1, 17, "middle", "normal", SOFT_INK)
        body += text(x0 + 280, 469, l2, 17, "middle", "normal", SOFT_INK)
        if i < 2:
            body += line(x0 + 562, 300, x0 + 578, 300, INK, 4, 1, "ink")
    # stages
    body += rect(34, 520, 1732, 300, "#f4f8ff", "#d4e0f2", 2, 18)
    body += pill(300, 562, "Stage 1: wrong cards SOUND wrong", 20, "#3a5fb0")
    for k, (w_, e_) in enumerate((("mouse", ""), ("mice", ""), ("mouses", "s"))):
        body += word_card(140 + k * 170, 660, w_, e_, w=150, badge_kind="mouse")
    body += text(300, 760, "a child who listens can tell them apart", 16, "middle", "normal", SOFT_INK)
    body += line(560, 660, 640, 660, INK, 4, 1, "ink")
    body += text(600, 640, "20 lit words", 14, "middle", "bold", SOFT_INK)
    body += pill(900, 562, "Stage 2: look-alikes SOUND right", 20, "#3a5fb0")
    for k, (w_, e_) in enumerate((("pony", ""), ("ponies", "ies"), ("ponys", "s"))):
        body += word_card(740 + k * 140, 660, w_, e_, w=128, badge_kind="pony")
    body += text(900, 760, "\"ponys\" is heard as \"ponies\": only reading tells", 16, "middle", "normal", SOFT_INK)
    body += line(1100, 660, 1180, 660, INK, 4, 1, "ink")
    body += pill(1450, 562, "The reading rooms open", 20, "#3a5fb0")
    for k, w_ in enumerate(("there", "their", "they're")):
        body += word_card(1300 + k * 150, 660, w_, "", w=136)
        body += ripple(1360 + k * 150, 626, 0.6)
    body += text(1450, 760, "the Homophone Hall: all three say the same sound", 16, "middle", "normal", SOFT_INK)
    # the model
    body += rect(34, 840, 1732, 290, "#fffaf2", "#e6dcc8", 2, 18)
    body += pill(420, 882, "The model: does the record follow real reading?", 20)
    rows = [("reads the words", "0", "51 % / 90 % / 99 % of the words it reads"),
            ("never reads: touches every card", "0 (its badges never fade)", "-"),
            ("never touches: guesses", "3 % / 6 % / 7 %", "-"),
            ("first letter and gold ending only", "4.5 % / 9 % / 10 %", "-")]
    body += text(80, 930, "player", 16, "start", "bold", SOFT_INK)
    body += text(620, 930, "words lit it can't read (sessions 1 / 2 / 10)", 16, "start", "bold", SOFT_INK)
    body += text(1180, 930, "words it reads, lit", 16, "start", "bold", SOFT_INK)
    for k, (a, b, c) in enumerate(rows):
        yy = 965 + k * 34
        body += text(80, yy, a, 17, "start") + text(620, yy, b, 17, "start") + text(1180, yy, c, 17, "start")
    body += note(W / 2, 1110, "Every card speaks on touch, for everyone, for ever; a touch is never a mistake, only not "
                 "evidence. Grades 5-8 start with badges hidden (shown on a card touched twice).", 15)
    return svg(W, H, body)


def pic_later():
    W, H = 1800, 1180
    body = rect(0, 0, W, H, PAPER)
    body += title_bar("Later rooms (phase C), each tuned by the ladder's model",
                      "In every room the named habit fails and the idea wins; every hand holds the tempting wrong card")
    rooms = [
        ("Time Windows (3)", "the bubble's frame says when", "adds -ed (runned): 0 %"),
        ("Chain Spells (3, 5)", "dominoes fall in the joining word's order", "because for so: 0 %"),
        ("The Homophone Hall (4)", "all three cards say the same sound", "only listening: 0.1 %"),
        ("The Comma Bridge (5)", "no list comma: a cat-dog", "a comma where you pause: 0 %"),
        ("The Wandering Phrase (7)", "a phrase sticks to the noun beside it", "always at the end: 0 %"),
        ("The Loom (6)", "three things, eight slots: weave them", "and, and, and: 0 %"),
        ("The Spotlight (8)", "the subject stands in the light", "the first noun is the doer: 0 %"),
        ("The Word Forge (5-7)", "two roots name the gadget", "the most familiar roots: 0 %"),
    ]
    for i, (name, line1, model) in enumerate(rooms):
        col, row = i % 4, i // 4
        x0, y0 = 34 + col * 436, 122 + row * 520
        body += rect(x0, y0, 418, 500, "#fffaf2", "#e6dcc8", 2, 18)
        body += pill(x0 + 209, y0 + 40, name, 19)
        cx, cy = x0 + 209, y0 + 250
        if i == 0:
            for k, (fk, kind) in enumerate((("past", "jump"), ("now", "swim"), ("future", "fly"))):
                body += photo_frame(cx - 120 + k * 120, cy, 100, 80, fk)
                body += buddy(cx - 120 + k * 120, cy + 30, 0.5, "#ffd166", "duck")
            body += word_card(cx - 70, cy + 120, "ran", "", w=110) + word_card(cx + 70, cy + 120, "runned", "ed", w=150)
        elif i == 1:
            for k in range(6):
                body += rect(cx - 150 + k * 52, cy - 40 + k * 4, 18, 80, ["#ff9f43", "#6ec6ff", "#7bd389"][k % 3], INK, 2, 3,
                             1, f'transform="rotate({k * 12} {cx - 141 + k * 52} {cy + k * 4})"')
            body += word_card(cx - 70, cy + 110, "so", "", w=100) + word_card(cx + 70, cy + 110, "because", "", w=150)
        elif i == 2:
            for k, w_ in enumerate(("there", "their", "they're")):
                body += word_card(cx - 130 + k * 130, cy, w_, "", w=120)
                body += ripple(cx - 80 + k * 130, cy - 36, 0.6)
            body += text(cx, cy + 90, "\"there\" · \"there\" · \"there\"", 18, "middle", "bold", GOLD_DARK,
                         italic=True)
        elif i == 3:
            g = (rect(-60, -40, 100, 40, "#f2b54a", INK, 2.5, 6) + rect(-72, -70, 34, 32, "#f2b54a", INK, 2.5, 6)
                 + rect(10, -74, 40, 38, "#c58a5a", INK, 2.5, 6))
            body += group(g, cx, cy + 40, 1.2)
            body += mini_ribbon(cx, cy + 110, [("a cat", WORD_INK), (" ", WORD_INK), ("dog", WORD_INK)], 220, 18)
        elif i == 4:
            body += rect(cx - 70, cy - 60, 140, 90, "#f3dcc0", INK, 3, 4)
            body += poly([(cx - 82, cy - 60), (cx, cy - 106), (cx + 82, cy - 60)], ROOF, INK, 3)
            body += path(f"M{cx + 70},{cy - 10} q50,-10 50,-60 q10,36 -18,70", "#c58a5a", INK, 2.5)
            body += buddy(cx - 120, cy + 30, 0.55, "#c58a5a", "pup")
        elif i == 5:
            rb, _ = ribbon(0, 0, [("gap", None)] * 4, gap_w=46, h=50, star_lit=False)
            body += group(rb, cx - 160, cy - 30, 1.0)
            body += text(cx, cy + 50, "The dragon is small and the dragon is", 14, "middle", "normal", SOFT_INK)
            body += text(cx, cy + 70, "green and it sleeps … (falls off the end)", 14, "middle", "normal", SOFT_INK)
            body += text(cx, cy + 110, "The small green dragon sleeps.", 17, "middle", "bold", FAIR)
        elif i == 6:
            body += poly([(cx - 20, cy - 150), (cx + 20, cy - 150), (cx + 90, cy + 40), (cx - 90, cy + 40)], "#fff3b0", None, 0,
                         0.6)
            body += circle(cx, cy + 20, 22, "#ff7eb6", INK, 2.5) + buddy(cx - 120, cy + 50, 0.6, "#c58a5a", "pup")
            body += text(cx, cy + 110, "The ball was chased by the dog.", 16, "middle", "bold", WORD_INK)
        else:
            body += rune_tile(cx - 70, cy - 40, "tele", "prefix") + rune_tile(cx + 70, cy - 40, "scope", "suffix")
            body += line(cx, cy - 10, cx, cy + 20, INK, 3, 1, "ink")
            body += rect(cx - 70, cy + 40, 140, 26, GOLD, INK, 2.5, 8) + rect(cx + 70, cy + 34, 30, 38, GOLD_DARK, INK, 2, 6)
            body += text(cx, cy + 110, "a far-seer appears", 16, "middle", "normal", SOFT_INK)
        body += text(cx, y0 + 430, line1, 16, "middle", "normal", SOFT_INK)
        body += text(cx, y0 + 466, model, 17, "middle", "bold", TEAL_DARK)
    return svg(W, H, body)


# --- Picture 12: the cheat test, computed from the models ---------------------------------------------------------------
def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, "model", name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _rates(mod, room, players, n):
    R = mod.R
    out = []
    for name, player in players:
        solved = []
        for seed in range(n):
            v = R.visit(room, player, seed, random.Random)
            solved.append(sum(1 for _, res in v if res == R.SOLVED))
        out.append((name, 100.0 * sum(1 for s in solved if R.mastered(s, len(room))) / n))
    return out


KNOWS = {"knows how many (reads or listens)", "knows it, slips on 4 % of picks", "knows it (the verb agrees: s means one)"}


def _bars(x0, y0, w, rows, title, subtitle):
    """One small multiple: horizontal bars, 0-100 % on one shared axis (emphasis, thin bars, hairline grid)."""
    out = text(x0, y0, title, 22, "start", "bold", CHART["ink"])
    out += text(x0, y0 + 26, subtitle, 15, "start", "normal", CHART["ink2"])
    label_w = 340
    bx0, bw = x0 + label_w, w - label_w - 70
    top = y0 + 60
    row_h = 36
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
    first = _load("first_page_model")
    dragons = _load("sleepy_dragons_model")
    n = 1000
    f_rows = _rates(first, first.FINAL, first.PLAYERS, n)
    d_rows = _rates(dragons, dragons.FINAL, dragons.PLAYERS, n)
    W, H = 1800, 800
    body = rect(0, 0, W, H, CHART["surface"])
    body += title_bar("The cheat test: only the knowledge wins",
                      f"Share of {n:,} visits that reach the mastery bar (5 of every 6 judged wishes granted at the first "
                      "cast, no help)")
    body += rect(40, 112, 18, 12, CHART["accent"], None, 0, 3) + text(66, 123, "players who know the idea", 15, "start",
                                                                       "normal", CHART["ink2"])
    body += rect(300, 112, 18, 12, CHART["rest"], None, 0, 3) + text(326, 123, "players who try without it", 15, "start",
                                                                      "normal", CHART["ink2"])
    body += _bars(40, 170, 900, f_rows, "The First Page (phase B)", "eight judged wishes; the bar is 7 of 8")
    body += _bars(950, 170, 820, d_rows, "The Sleepy Dragons (the transfer)", "six judged wishes; the bar is 5 of 6")
    body += note(W / 2, H - 46, "From model/first_page_model.py and model/sleepy_dragons_model.py. 'Knows how many' is "
                 "also the child who cannot read yet and listens: the meaning rooms are playable by ear.", 15)
    body += note(W / 2, H - 22, "'Trial and error with a preview' is a ribbon we do not build: it shows why nothing "
                 "previews a spell and only the first cast counts.", 15)
    return svg(W, H, body)


PICTURES = [("01-the-word-tower", pic_tower), ("02-write-it-true", pic_verb), ("03-the-literal-world", pic_literal),
            ("04-the-first-page", pic_page), ("05-the-sleepy-dragons", pic_dragons), ("06-core-loop", pic_loop),
            ("07-the-ladder", pic_ladder), ("08-cards-and-runes", pic_things), ("09-vr", pic_vr),
            ("10-the-reading-track", pic_fade), ("11-later-rooms", pic_later), ("12-cheat-test", pic_cheat)]


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
