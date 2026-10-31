"""The design sketches of Size Magic Voyages: Inside a Leaf (docs/design/games/leaf-voyage.md, phase A).

Draws every picture as SVG in the game's blocky, friendly look and renders each to PNG with rsvg-convert:

    /usr/bin/python3 -I docs/design/games/leaf-voyage/make_pictures.py

The pictures are sketches for grown-ups (the lead, the owner): their words are labels, not the game's screen (the game
shows no words during play). Picture 04's curves come from the phase A model (model/voyage_5_1_model.py).
"""
import importlib.util
import math
import os
import random
import subprocess
import sys

sys.dont_write_bytecode = True   # importing the model must leave no __pycache__ in the docs
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "DejaVu Sans, Arial, sans-serif"

# --- The palette (the meanings of §3.8) ------------------------------------------------------------------------------
INK = "#263238"
SOFT_INK = "#4a5a60"
SKY_HOT = ("#ffc75a", "#fff0c2")
SKY_EVE = ("#f39a6b", "#ffe3c8")
SKY_DAY = ("#8ec5f0", "#e9f3fb")
SKY_NIGHT = ("#0e1b45", "#2c3f7a")
GRASS, GRASS_DARK = "#6abf4b", "#4e9a35"
SOIL_DRY, SOIL_WET = "#cfa77f", "#5b3a26"
POT, POT_DARK = "#d9733b", "#a9531f"
STEM, STEM_DARK = "#5aa83c", "#3d7d28"
LEAF, LEAF_DARK, LEAF_PALE = "#5fb848", "#3e8a2e", "#b5c96c"
PETAL, PETAL_DARK, DISC = "#ffcc1a", "#e09a00", "#6b3e1e"
WATER, WATER_DARK, MIST = "#3fb6ff", "#1f7fc4", "#bfe8ff"
CO2_SHELL, CARBON, OXYGEN, HYDROGEN = "#dfe4e8", "#2c2c2c", "#e2453c", "#ffffff"
NITROGEN = "#6f86b8"
O2_SHELL = "#ffdbe3"
SUGAR, SUGAR_DARK, SUGAR_GLOW = "#ffbe2e", "#c98300", "#fff2b8"
LIGHT = "#ffe27a"
MINERAL = "#9b6bff"
CELL, CELL_RIM, CELL_SAG = "#86d86f", "#4a9e45", "#b9cf86"
PALI = "#6fca5f"
CHLORO, CHLORO_DIM, CHLORO_GLOW = "#22a457", "#5f8a5a", "#b6ffb0"
CAVE = ("#e5f8b0", "#86d46f", "#2d7a5c")
GUARD, GUARD_DARK = "#43d15f", "#1f8a36"
PIPE_BLUE, PIPE_GOLD, SHEATH = "#8fd0ff", "#ffcb4f", "#bfe39a"
MITO, NUCLEUS, VACUOLE = "#ff9a4d", "#9b7bd8", "#c6e9ff"
HOOT, HOOT_LIGHT = "#8a5a35", "#e2c093"
SKIN, SHIRT, PANTS, HAIR = "#f0c8a0", "#2bb3a3", "#3a5fb0", "#5a3b22"
PANEL = "#ffffff"


# --- SVG helpers -----------------------------------------------------------------------------------------------------
def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}{_markers()}</defs>{body}</svg>')


def _markers():
    out = ""
    for name, colour in (("ink", INK), ("water", WATER_DARK), ("gold", SUGAR_DARK), ("grey", "#7a8790"),
                         ("green", GUARD_DARK), ("red", OXYGEN), ("violet", MINERAL), ("white", "#ffffff")):
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
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}"{st} opacity="{op}" {extra}/>'


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


def line(x1, y1, x2, y2, stroke=INK, sw=3, op=1.0, arrow=None, dash=None):
    m = f' marker-end="url(#arrow-{arrow})"' if arrow else ""
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" stroke-width="{sw}" '
            f'stroke-linecap="round" opacity="{op}"{m}{d}/>')


def curve_arrow(x1, y1, cx, cy, x2, y2, stroke, sw=4, arrow="ink", dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<path d="M{x1:.1f},{y1:.1f} Q{cx:.1f},{cy:.1f} {x2:.1f},{y2:.1f}" fill="none" stroke="{stroke}" '
            f'stroke-width="{sw}" stroke-linecap="round" marker-end="url(#arrow-{arrow})"{d}/>')


def text(x, y, s, size=20, anchor="middle", weight="normal", fill=INK, italic=False, op=1.0):
    st = ' font-style="italic"' if italic else ""
    s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}" text-anchor="{anchor}" '
            f'font-weight="{weight}" fill="{fill}"{st} opacity="{op}">{s}</text>')


def lines_of_text(x, y, rows, size=18, anchor="middle", weight="normal", fill=INK, gap=1.3):
    return "".join(text(x, y + i * size * gap, r, size, anchor, weight, fill) for i, r in enumerate(rows))


def group(body, tx=0.0, ty=0.0, s=1.0, rot=0.0, op=1.0):
    return f'<g transform="translate({tx:.1f},{ty:.1f}) rotate({rot:.1f}) scale({s:.3f})" opacity="{op}">{body}</g>'


def card(x, y, w, h, fill=PANEL, stroke="#d0d8dc", rx=18, op=0.94):
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
    out += rect(bx, y, wbox, hbox, "#ffffff", "#9fb4c2", 1.5, 8, 0.95)
    for i, r in enumerate(rows):
        out += text(bx + 11, y + 7 + size + i * size * 1.3, r, size, "start", "bold" if (i == 0 and bold_first) else "normal")
    return out


def pill(x, y, label, size=22, fill=INK, colour="#ffffff"):
    w = len(label) * size * 0.62 + 28
    return rect(x - w / 2, y - size * 1.05, w, size * 1.55, fill, None, 0, size * 0.77, 0.9) + text(x, y + size * 0.1, label, size, "middle", "bold", colour)


def title_bar(w, title, subtitle=""):
    out = text(40, 58, title, 34, "start", "bold")
    if subtitle:
        out += text(40, 92, subtitle, 19, "start", "normal", SOFT_INK)
    return out


# --- Things ------------------------------------------------------------------------------------------------------------
def drop(x, y, r, fill=WATER):
    d = (f"M{x:.1f},{y - 1.6 * r:.1f} C{x + 0.9 * r:.1f},{y - 0.5 * r:.1f} {x + r:.1f},{y:.1f} {x:.1f},{y + r:.1f} "
         f"C{x - r:.1f},{y:.1f} {x - 0.9 * r:.1f},{y - 0.5 * r:.1f} {x:.1f},{y - 1.6 * r:.1f} z")
    return path(d, fill, WATER_DARK, max(1.5, r * 0.18)) + circle(x - 0.35 * r, y - 0.2 * r, r * 0.22, "#ffffff", op=0.8)


def co2(x, y, r, atoms=False):
    if atoms:
        return (circle(x - 1.55 * r, y, r * 0.85, OXYGEN, INK, 2) + circle(x + 1.55 * r, y, r * 0.85, OXYGEN, INK, 2)
                + circle(x, y, r, CARBON, INK, 2) + circle(x - 0.3 * r, y - 0.35 * r, r * 0.22, "#888", op=0.9))
    return (circle(x, y, r, CO2_SHELL, "#8b979e", 2) + circle(x, y, r * 0.28, CARBON)
            + circle(x - r * 0.52, y, r * 0.2, OXYGEN) + circle(x + r * 0.52, y, r * 0.2, OXYGEN))


def o2(x, y, r, atoms=False):
    if atoms:
        return circle(x - 0.75 * r, y, r * 0.85, OXYGEN, INK, 2) + circle(x + 0.75 * r, y, r * 0.85, OXYGEN, INK, 2)
    return circle(x, y, r, O2_SHELL, "#e0a0ae", 2) + circle(x - r * 0.3, y, r * 0.24, OXYGEN) + circle(x + r * 0.3, y, r * 0.24, OXYGEN)


def h2o(x, y, r, charged=False):
    a = math.radians(52)
    hx, hy = math.sin(a) * 1.25 * r, math.cos(a) * 1.25 * r
    h_col = SUGAR if charged else HYDROGEN
    return (circle(x - hx, y + hy, r * 0.6, h_col, INK, 2) + circle(x + hx, y + hy, r * 0.6, h_col, INK, 2)
            + circle(x, y, r, OXYGEN, INK, 2))


def n2(x, y, r):
    return circle(x - 0.72 * r, y, r * 0.8, NITROGEN, INK, 1.5, 0.85) + circle(x + 0.72 * r, y, r * 0.8, NITROGEN, INK, 1.5, 0.85)


def hexagon_points(x, y, r, rot=30):
    return " ".join(f"{x + r * math.cos(math.radians(rot + 60 * i)):.1f},{y + r * math.sin(math.radians(rot + 60 * i)):.1f}"
                    for i in range(6))


def sugar(x, y, r, glow=True):
    out = circle(x, y, r * 1.7, "url(#glow-gold)") if glow else ""
    out += f'<polygon points="{hexagon_points(x, y, r)}" fill="{SUGAR}" stroke="{SUGAR_DARK}" stroke-width="{max(2, r * 0.14):.1f}"/>'
    out += f'<polygon points="{hexagon_points(x - r * 0.12, y - r * 0.12, r * 0.5)}" fill="#ffe08a" opacity="0.8"/>'
    return out


def spark(x, y, r, fill=LIGHT):
    d = (f"M{x:.1f},{y - r:.1f} L{x + 0.25 * r:.1f},{y - 0.25 * r:.1f} L{x + r:.1f},{y:.1f} L{x + 0.25 * r:.1f},{y + 0.25 * r:.1f} "
         f"L{x:.1f},{y + r:.1f} L{x - 0.25 * r:.1f},{y + 0.25 * r:.1f} L{x - r:.1f},{y:.1f} L{x - 0.25 * r:.1f},{y - 0.25 * r:.1f} z")
    return path(d, fill, "#e0a800", 1.5)


def mineral(x, y, r):
    return path(f"M{x},{y - r} L{x + 0.7 * r},{y} L{x},{y + r} L{x - 0.7 * r},{y} z", MINERAL, "#5b33c4", 1.5)


def mist(x, y, length, op=0.75, down=True):
    sgn = 1 if down else -1
    d = (f"M{x:.1f},{y:.1f} C{x + 14:.1f},{y + sgn * length * 0.3:.1f} {x - 14:.1f},{y + sgn * length * 0.6:.1f} "
         f"{x + 4:.1f},{y + sgn * length:.1f}")
    return path(d, "none", MIST, 9, op) + path(d, "none", "#ffffff", 3, op * 0.7)


def sun(x, y, r, rays=True):
    out = circle(x, y, r * 1.9, "url(#glow-sun)")
    if rays:
        for i in range(12):
            a = math.radians(i * 30)
            out += line(x + math.cos(a) * r * 1.2, y + math.sin(a) * r * 1.2, x + math.cos(a) * r * 1.6,
                        y + math.sin(a) * r * 1.6, "#ffb000", 5)
    return out + circle(x, y, r, "#ffd84a", "#f0a000", 4)


def cloud(x, y, s, fill="#ffffff", op=1.0):
    return (ellipse(x, y, 60 * s, 30 * s, fill, "#c9d6de", 2, 0, op) + circle(x - 28 * s, y - 14 * s, 26 * s, fill, None, 0, op)
            + circle(x + 10 * s, y - 24 * s, 32 * s, fill, None, 0, op) + circle(x + 40 * s, y - 8 * s, 22 * s, fill, None, 0, op))


def heat_waves(x, y, w, n=3):
    out = ""
    for i in range(n):
        yy = y + i * 16
        d = f"M{x},{yy} " + " ".join(f"Q{x + (k + 0.5) * w / 6:.1f},{yy - 8 if k % 2 == 0 else yy + 8} {x + (k + 1) * w / 6:.1f},{yy}" for k in range(6))
        out += path(d, "none", "#ff9a3c", 3, 0.6)
    return out


def bee(x, y, s):
    return (ellipse(x - 6 * s, y - 12 * s, 10 * s, 7 * s, "#ffffff", "#9fb4c2", 1.5, -30, 0.9)
            + ellipse(x + 6 * s, y - 12 * s, 10 * s, 7 * s, "#ffffff", "#9fb4c2", 1.5, 30, 0.9)
            + ellipse(x, y, 16 * s, 11 * s, "#ffd21f", INK, 2)
            + line(x - 5 * s, y - 10 * s, x - 5 * s, y + 10 * s, INK, 4 * s) + line(x + 4 * s, y - 10 * s, x + 4 * s, y + 10 * s, INK, 4 * s)
            + circle(x + 14 * s, y - 2 * s, 5 * s, INK))


def ladybird(x, y, s):
    return (ellipse(x, y, 34 * s, 26 * s, "#e23b2e", INK, 3) + line(x, y - 26 * s, x, y + 26 * s, INK, 3)
            + circle(x - 14 * s, y - 6 * s, 6 * s, INK) + circle(x + 14 * s, y - 6 * s, 6 * s, INK)
            + circle(x - 12 * s, y + 12 * s, 5 * s, INK) + circle(x + 12 * s, y + 12 * s, 5 * s, INK)
            + ellipse(x, y - 30 * s, 16 * s, 10 * s, INK))


def avatar(x, y, s, pose="stand", tiny_label=False):
    """The blocky child, feet at (x, y)."""
    out = ""
    if pose == "fly":
        g = (rect(-10, -40, 20, 26, SHIRT, INK, 2.5, 3) + rect(-30, -38, 20, 8, SKIN, INK, 2, 3) + rect(10, -46, 20, 8, SKIN, INK, 2, 3)
             + rect(-9, -14, 8, 22, PANTS, INK, 2.5, 2) + rect(1, -14, 8, 22, PANTS, INK, 2.5, 2)
             + rect(-12, -64, 24, 24, SKIN, INK, 2.5, 3) + rect(-12, -64, 24, 8, HAIR, None, 0, 2)
             + rect(-6, -52, 4, 4, INK) + rect(3, -52, 4, 4, INK))
        out += group(g, x, y, s, -25)
        out += path(f"M{x - 40 * s},{y - 10 * s} l-30,6 M{x - 44 * s},{y - 22 * s} l-26,2", "none", "#ffffff", 3, 0.8)
    else:
        g = (rect(-10, -40, 20, 26, SHIRT, INK, 2.5, 3) + rect(-18, -40, 8, 22, SKIN, INK, 2, 3) + rect(10, -40, 8, 22, SKIN, INK, 2, 3)
             + rect(-9, -14, 8, 14, PANTS, INK, 2.5, 2) + rect(1, -14, 8, 14, PANTS, INK, 2.5, 2)
             + rect(-12, -64, 24, 24, SKIN, INK, 2.5, 3) + rect(-12, -64, 24, 8, HAIR, None, 0, 2)
             + rect(-6, -52, 4, 4, INK) + rect(3, -52, 4, 4, INK) + rect(-4, -45, 8, 2, "#c46a5a"))
        out += group(g, x, y, s)
    return out


def hoot(x, y, s, wing_up=False):
    """Professor Hoot, the blocky owl, feet at (x, y)."""
    g = (rect(-22, -60, 44, 56, HOOT, INK, 2.5, 8) + rect(-14, -36, 28, 28, HOOT_LIGHT, None, 0, 6)
         + path("M-22,-60 L-26,-74 L-10,-60 z M22,-60 L26,-74 L10,-60 z", HOOT, INK, 2.5)
         + circle(-10, -46, 9, "#ffffff", INK, 2) + circle(10, -46, 9, "#ffffff", INK, 2)
         + circle(-9, -45, 4, INK) + circle(11, -45, 4, INK)
         + circle(-10, -46, 12, "none", "#3b3b3b", 1.8) + circle(10, -46, 12, "none", "#3b3b3b", 1.8) + line(-1, -46, 1, -46, "#3b3b3b", 1.8)
         + path("M-4,-36 L4,-36 L0,-29 z", "#ff9f1c", INK, 1.5)
         + line(-8, -4, -8, 2, "#ff9f1c", 4) + line(8, -4, 8, 2, "#ff9f1c", 4))
    if wing_up:
        g += path("M-22,-40 Q-44,-62 -40,-34 Q-34,-28 -22,-30 z", HOOT, INK, 2.5)
        g += path("M22,-40 Q44,-62 40,-34 Q34,-28 22,-30 z", HOOT, INK, 2.5)
    else:
        g += rect(-28, -44, 8, 26, HOOT, INK, 2.5, 4) + rect(20, -44, 8, 26, HOOT, INK, 2.5, 4)
    return group(g, x, y, s)


def speech(x, y, w, rows, size=17):
    h = len(rows) * size * 1.35 + 18
    out = rect(x, y, w, h, "#ffffff", "#9fb4c2", 2, 14)
    out += path(f"M{x + 26},{y + h} l-10,18 l26,-18 z", "#ffffff", "#9fb4c2", 2)
    out += rect(x + 12, y + h - 3, 34, 6, "#ffffff")
    out += text(x + 20, y + 26, "🔊", size, "start") if False else circle(x + 22, y + 22, 8, "#6c8a96") + path(
        f"M{x + 32},{y + 16} q6,6 0,12", "none", "#6c8a96", 2)
    for i, r in enumerate(rows):
        out += text(x + 42, y + 24 + i * size * 1.35, r, size, "start", "normal", INK, True)
    return out


def pot(x, y, w, h, wet=False):
    """A terracotta pot; (x, y) the top centre."""
    out = path(f"M{x - w / 2},{y} L{x + w / 2},{y} L{x + w * 0.38},{y + h} L{x - w * 0.38},{y + h} z", POT, INK, 3)
    out += rect(x - w / 2 - 8, y - 10, w + 16, 22, POT_DARK, INK, 3, 4)
    out += ellipse(x, y - 8, w / 2, 7, SOIL_WET if wet else SOIL_DRY, INK, 2)
    if not wet:
        out += path(f"M{x - w * 0.3},{y - 9} l12,4 l10,-5 M{x + w * 0.05},{y - 6} l14,-4 l8,5", "none", "#9c7454", 2)
    return out


def watering_can(x, y, s):
    g = (rect(-30, -30, 60, 40, "#6fb1d6", INK, 3, 8) + path("M30,-18 L64,-46", "none", INK, 7) + path("M30,-18 L64,-46", "none", "#6fb1d6", 4)
         + rect(58, -56, 16, 10, "#6fb1d6", INK, 2.5, 3) + path("M-20,-30 Q0,-58 20,-30", "none", INK, 5))
    return group(g, x, y, s)


def block_stack(x, y_base, n, colour, size=22, label=None, new=0):
    out = rect(x - size * 0.8, y_base, size * 1.6, 8, "#7a8790", INK, 2, 2)
    for i in range(n):
        yy = y_base - (i + 1) * size
        fresh = i >= n - new
        if fresh:
            out += circle(x, yy + size / 2, size * 0.9, "url(#glow-gold)")
        out += rect(x - size / 2, yy, size, size, "#ffd84d" if fresh else colour, SUGAR_DARK if fresh else INK, 2.5 if fresh else 2, 2)
        out += rect(x - size / 2 + 3, yy + 3, size - 6, 4, "#ffffff", None, 0, 1, 0.35)
    if label:
        out += text(x, y_base + 30, label, 15, "middle", "normal", SOFT_INK)
    return out


def sunflower(x, y, h, state="stand", bloom=False, pale=False):
    """A sunflower growing from (x, y) (the soil); state 'droop' or 'stand'."""
    leaf_c = LEAF_PALE if pale else LEAF
    out = ""
    if state == "droop":
        pts = [(x, y), (x + 4, y - h * 0.45), (x + h * 0.12, y - h * 0.82), (x + h * 0.32, y - h * 0.88), (x + h * 0.42, y - h * 0.68)]
        d = f"M{pts[0][0]},{pts[0][1]} C{pts[1][0]},{pts[1][1]} {pts[2][0]},{pts[2][1]} {pts[3][0]},{pts[3][1]} S{pts[4][0] + 6},{pts[4][1] - 30} {pts[4][0]},{pts[4][1]}"
        out += path(d, "none", INK, 14) + path(d, "none", STEM if not pale else "#9cb85a", 9)
        for i, (ax, ay) in enumerate([(x + 1, y - h * 0.22), (x + 3, y - h * 0.4), (x + 6, y - h * 0.56)]):
            side = -1 if i % 2 == 0 else 1
            theta = math.radians(110 if side < 0 else 70)      # hanging: down and out
            cx_, cy_ = ax + math.cos(theta) * 38, ay + math.sin(theta) * 38
            out += ellipse(cx_, cy_, 42, 14, leaf_c, INK, 3, math.degrees(theta))
            out += line(ax, ay, cx_ + math.cos(theta) * 30, cy_ + math.sin(theta) * 30, "#8aa04a" if pale else LEAF_DARK, 2)
        hx, hy = pts[4]
        out += ellipse(hx, hy + 10, 22, 30, "#4f9a35", INK, 3, 20)
        out += path(f"M{hx - 16},{hy + 2} l-10,-12 M{hx + 14},{hy - 2} l12,-10", "none", "#3d7d28", 4)
    else:
        d = f"M{x},{y} C{x + 6},{y - h * 0.4} {x - 6},{y - h * 0.7} {x},{y - h}"
        out += path(d, "none", INK, 15) + path(d, "none", STEM, 10)
        for i, (ly, side) in enumerate([(0.3, -1), (0.42, 1), (0.58, -1), (0.7, 1)]):
            lx, yy = x + side * 40, y - h * ly
            out += ellipse(lx, yy, 44, 17, LEAF, INK, 3, -25 * side)
            out += line(x, yy + 6, lx + side * 30, yy - side * 0 - 8, LEAF_DARK, 2)
        hx, hy = x, y - h
        if bloom:
            for k in range(16):
                a = math.radians(k * 22.5)
                out += ellipse(hx + math.cos(a) * 42, hy + math.sin(a) * 42, 24, 10, PETAL, PETAL_DARK, 2, k * 22.5)
            out += circle(hx, hy, 34, DISC, INK, 3)
            rng = random.Random(4)
            for _ in range(26):
                a, rr = rng.uniform(0, 6.28), rng.uniform(0, 26)
                out += circle(hx + math.cos(a) * rr, hy + math.sin(a) * rr, 2.5, "#3b2210")
        else:
            out += ellipse(hx, hy, 26, 30, "#4f9a35", INK, 3)
            out += path(f"M{hx - 20},{hy + 8} l-12,10 M{hx + 20},{hy + 8} l12,10 M{hx},{hy - 30} l0,-10", "none", "#3d7d28", 4)
    return out


def cell(x, y, rx, ry, sag=False, n=6, glow=True, seed=0, rim=CELL_RIM, fill=CELL):
    rng = random.Random(seed)
    fill_c = CELL_SAG if sag else fill
    k = 10
    pts = []
    for i in range(k):
        a = 2 * math.pi * i / k
        wob = rng.uniform(-0.04, 0.04) + (0.10 * math.sin(3 * a + seed) if sag else 0.0)
        pts.append((x + math.cos(a) * rx * (1 + wob), y + math.sin(a) * ry * (1 + wob) + (ry * 0.12 if sag and math.sin(a) > 0 else 0)))
    d = "M" + " ".join(f"{px:.1f},{py:.1f}" for px, py in pts[:1])
    for i in range(k):
        p0, p1 = pts[i], pts[(i + 1) % k]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        d += f" Q{p0[0]:.1f},{p0[1]:.1f} {mx:.1f},{my:.1f}"
    d += " z"
    out = path(d, fill_c, rim, 3)
    out += ellipse(x - rx * 0.25, y - ry * 0.35, rx * 0.45, ry * 0.18, "#ffffff", None, 0, -15, 0.25)
    if sag:
        out += path(f"M{x - rx * 0.5},{y + ry * 0.1} q{rx * 0.2},{ry * 0.15} {rx * 0.4},0 M{x + rx * 0.05},{y + ry * 0.35} q{rx * 0.2},{-ry * 0.12} {rx * 0.4},0",
                    "none", "#8aa065", 2)
    for i in range(n):
        a = 2 * math.pi * i / n + rng.uniform(-0.3, 0.3)
        cx, cy = x + math.cos(a) * rx * 0.62, y + math.sin(a) * ry * 0.58
        if glow:
            out += circle(cx, cy, min(rx, ry) * 0.24, "url(#glow-green)")
        out += ellipse(cx, cy, min(rx, ry) * 0.16, min(rx, ry) * 0.09, CHLORO if glow else CHLORO_DIM, "#155c32", 1.5, math.degrees(a) + 90)
    return out


def palisade(x, y, w, h, glow=True, seed=0, n=5):
    rng = random.Random(seed)
    out = rect(x, y, w, h, PALI, CELL_RIM, 3, w / 2)
    out += rect(x + w * 0.18, y + 10, w * 0.18, h - 20, "#ffffff", None, 0, 4, 0.18)
    for i in range(n):
        cy = y + h * (0.15 + 0.7 * i / max(1, n - 1))
        cx = x + w * (0.3 if i % 2 == 0 else 0.7) + rng.uniform(-3, 3)
        if glow:
            out += circle(cx, cy, w * 0.26, "url(#glow-green)")
        out += ellipse(cx, cy, w * 0.2, w * 0.11, CHLORO if glow else CHLORO_DIM, "#155c32", 1.5, rng.uniform(-30, 30))
    return out


def door(x, y, w, state="open", scale=1.0):
    """A stoma seen from the side of the floor: two bean-shaped guard cells around a pore at (x, y)."""
    gap = 0.22 * w if state == "open" else 0.02 * w
    out = ellipse(x - gap / 2 - w * 0.22, y, w * 0.26, w * 0.14, GUARD, GUARD_DARK, 3)
    out += ellipse(x + gap / 2 + w * 0.22, y, w * 0.26, w * 0.14, GUARD, GUARD_DARK, 3)
    if state == "open":
        out += ellipse(x, y, gap / 2 + 2, w * 0.08, "#0f3d2a")
    else:
        out += line(x, y - w * 0.1, x, y + w * 0.1, "#0f3d2a", 3)
    return out


def door_top(x, y, w, state="open"):
    """A stoma seen from above: the two guard cells around an oval pore."""
    open_ = state == "open"
    out = ellipse(x, y, w * 0.55, w * 0.42, GUARD, GUARD_DARK, 3)
    out += ellipse(x, y, w * (0.26 if open_ else 0.3), w * (0.12 if open_ else 0.015), "#0f3d2a")
    out += line(x, y - w * 0.42, x, y + w * 0.42, GUARD_DARK, 2)
    return out


def scale_badge(x, y, label, fill="#263238"):
    w = max(84, len(label) * 13 + 26)
    return rect(x - w / 2, y - 18, w, 34, fill, None, 0, 17) + text(x, y + 7, label, 19, "middle", "bold", "#ffffff")


def common_defs():
    return (rad_grad("glow-gold", [(0, "#fff3b0", 0.95), (1, "#fff3b0", 0)])
            + rad_grad("glow-green", [(0, CHLORO_GLOW, 0.9), (1, CHLORO_GLOW, 0)])
            + rad_grad("glow-sun", [(0, "#fff6c9", 0.95), (1, "#fff6c9", 0)])
            + rad_grad("glow-white", [(0, "#ffffff", 0.9), (1, "#ffffff", 0)])
            + lin_grad("sky-hot", [(0, SKY_HOT[0]), (1, SKY_HOT[1])])
            + lin_grad("sky-eve", [(0, SKY_EVE[0]), (1, SKY_EVE[1])])
            + lin_grad("sky-day", [(0, SKY_DAY[0]), (1, SKY_DAY[1])])
            + lin_grad("sky-night", [(0, SKY_NIGHT[0]), (1, SKY_NIGHT[1])])
            + lin_grad("cave", [(0, CAVE[0]), (0.45, CAVE[1]), (1, CAVE[2])])
            + lin_grad("ray", [(0, "#fffbe0"), (1, "#fffbe0")]))


# --- 01: the garden before and after -----------------------------------------------------------------------------------
def pic_garden():
    W, H = 1600, 860
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "The hook and the reward", "Voyage 5.1: a drooping sunflower in the heat; after the voyage, it stands and blooms")
    for px, sky, mode in ((40, "url(#sky-hot)", "before"), (820, "url(#sky-eve)", "after")):
        body += rect(px, 120, 740, 690, sky, "#d8cfc0", 2, 22)
        ground = 640
        body += rect(px, ground, 740, 170, GRASS, None, 0, 0)
        body += rect(px, ground, 740, 14, GRASS_DARK)
        for i in range(9):
            body += rect(px + 30 + i * 80, ground + 30, 60, 16, "#5fae42", None, 0, 4, 0.6)
        body += rect(px + 520, ground - 70, 200, 12, "#b07a4a", INK, 2, 3) + rect(px + 520, ground - 40, 200, 12, "#b07a4a", INK, 2, 3)
        for k in range(5):
            body += rect(px + 525 + k * 46, ground - 90, 12, 90, "#c58a52", INK, 2, 3)
        if mode == "before":
            body += sun(px + 610, 210, 46)
            body += heat_waves(px + 60, ground - 60, 200)
            body += heat_waves(px + 300, ground - 140, 160, 2)
            body += pot(px + 250, ground - 70, 140, 80, wet=False)
            body += sunflower(px + 250, ground - 78, 330, "droop", pale=True)
            body += circle(px + 140, ground + 26, 58, "url(#glow-gold)")
            body += watering_can(px + 120, ground + 50, 1.0)
            body += block_stack(px + 410, ground + 70, 5, SUGAR, 22, "the plant")
            body += block_stack(px + 480, ground + 70, 5, "#8a5a3b", 22, "the soil")
            body += hoot(px + 600, ground - 92, 1.1)
            body += speech(px + 380, 300, 330, ["Oh no! Our sunflower", "is drooping in the heat."])
            body += text(px + 370, ground + 145, "Minute 0: cracked soil, pale leaves, cicadas, heat shimmer; the can glows", 18, "middle", "normal", INK)
        else:
            body += circle(px + 140, 200, 40, "#ffd59a", "#f0a868", 3)
            body += pot(px + 250, ground - 70, 140, 80, wet=True)
            body += sunflower(px + 250, ground - 78, 350, "stand", bloom=True)
            body += bee(px + 330, ground - 430, 1.3)
            body += path(f"M{px + 440},{ground - 470} q-40,10 -80,36", "none", "#7a8790", 2, 0.6, 'stroke-dasharray="6 6"')
            body += hoot(px + 600, ground - 92, 1.1, wing_up=True)
            body += block_stack(px + 410, ground + 70, 7, SUGAR, 22, "the plant", new=2)
            body += block_stack(px + 480, ground + 70, 5, "#8a5a3b", 22, "the soil")
            body += text(px + 372, ground - 80, "+2", 24, "end", "bold", SUGAR_DARK)
            body += speech(px + 380, 300, 340, ["Every petal was built", "from air you let in!"])
            body += text(px + 370, ground + 145, "Minute 6: standing, blooming, a bee; the plant heavier, the soil the same", 18, "middle", "normal", INK)
    body += circle(800, 470, 40, "#ffffff", INK, 3) + spark(800, 470, 22)
    body += line(782, 520, 818, 520, INK, 5, 1, "ink")
    body += text(800, 410, "the voyage", 18, "middle", "bold", INK)
    return svg(W, H, body, common_defs())


# --- 02: the dive --------------------------------------------------------------------------------------------------------
def pic_dive():
    W, H = 1800, 620
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "The dive: Size Magic by tens", "Touch the leaf: a chime at ×10, ×100 and ×1,000, a last one at ×85,000; in VR the garden grows around your feet")
    frames = [("×1", "the garden"), ("×10", "the leaf: a ladybird like a bus"), ("×100", "a leaf hair like a glass tree"),
              ("×1,000", "the skin's cells like paving; the doors"), ("×85,000", "inside: the green cathedral")]
    cx0, cy, R = 190, 340, 150
    for i, (badge, cap) in enumerate(frames):
        cx = cx0 + i * 355
        clip = f"clip{i}"
        body += f'<clipPath id="{clip}"><circle cx="{cx}" cy="{cy}" r="{R}"/></clipPath>'
        inner = ""
        if i == 0:
            inner += rect(cx - R, cy - R, 2 * R, 2 * R, "url(#sky-day)")
            inner += rect(cx - R, cy + 70, 2 * R, 90, GRASS)
            inner += pot(cx, cy + 40, 70, 40, True) + sunflower(cx, cy + 36, 170, "droop")
            inner += avatar(cx + 85, cy + 110, 1.0)
        elif i == 1:
            inner += rect(cx - R, cy - R, 2 * R, 2 * R, "#7fcf5a")
            for k in range(-4, 5):
                inner += line(cx + k * 40, cy - R, cx + k * 40 + 60, cy + R, "#68b84a", 4)
            inner += line(cx - R, cy + 10, cx + R, cy - 20, "#9de07a", 10)
            inner += ladybird(cx - 30, cy - 30, 1.5) + avatar(cx + 70, cy + 60, 0.35)
        elif i == 2:
            inner += rect(cx - R, cy - R, 2 * R, 2 * R, "#9adf74")
            for k in range(5):
                bx = cx - 110 + k * 55
                inner += path(f"M{bx},{cy + 120} L{bx + 6},{cy - 40 - 20 * (k % 2)} L{bx + 14},{cy + 120} z", "#e9fff0", "#9fd0b0", 2, 0.9)
            inner += circle(cx + 40, cy + 60, 34, "#ffd27a", "#d39a3a", 3)
            inner += avatar(cx - 30, cy + 110, 0.5)
        elif i == 3:
            inner += rect(cx - R, cy - R, 2 * R, 2 * R, "#b5e98f")
            rng = random.Random(7)
            for gx in range(-4, 5):
                for gy in range(-4, 5):
                    px, py = cx + gx * 40 + rng.uniform(-6, 6), cy + gy * 34 + rng.uniform(-6, 6)
                    inner += path(f"M{px - 18},{py} q9,-14 18,-16 q14,4 18,14 q-6,14 -18,18 q-14,-2 -18,-16 z", "#c9f3a5", "#8cc56a", 2)
            inner += door_top(cx - 40, cy - 20, 54, "open") + door_top(cx + 60, cy + 50, 54, "closed")
            inner += mist(cx - 40, cy - 10, 60, 0.7)
        else:
            inner += rect(cx - R, cy - R, 2 * R, 2 * R, "url(#cave)")
            for k in range(4):
                inner += path(f"M{cx - 120 + k * 70},{cy - R} l40,0 l-60,{2 * R} l-30,0 z", "#fffbe0", None, 0, 0.25)
            inner += palisade(cx - 120, cy - 150, 46, 120, True, 1) + palisade(cx - 60, cy - 150, 46, 130, True, 2) + palisade(cx + 10, cy - 150, 46, 120, True, 3)
            inner += cell(cx - 70, cy + 60, 50, 42, False, 5, True, 4) + cell(cx + 60, cy + 40, 46, 40, False, 5, True, 5)
            inner += hoot(cx + 20, cy + 120, 0.6) + avatar(cx - 10, cy + 10, 0.7, "fly")
        body += f'<g clip-path="url(#{clip})">{inner}</g>'
        body += circle(cx, cy, R, "none", INK, 5)
        body += scale_badge(cx, cy - R - 4, badge)
        body += text(cx, cy + R + 44, cap, 18, "middle", "normal", INK)
        if i < 4:
            body += line(cx + R + 8, cy, cx + 355 - R - 10, cy, INK, 5, 1, "ink")
            body += spark(cx + 178, cy - 34, 13)
    body += text(W / 2, H - 22, "Sound: Size Magic's sparkle, then one rising chime per step. Hoot: \"Smaller... smaller... we're tinier than a hair!\"", 18, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- 03: inside the leaf -------------------------------------------------------------------------------------------------
def pic_inside():
    W, H = 1800, 1300
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "Inside the leaf (rung 5): the place", "A cross-section at the child's size (about ×85,000): a green cathedral of cells under a glass roof")
    x0, y0, w, h = 40, 120, 1300, 1140
    body += rect(x0, y0, w, h, "url(#cave)", "#2d5d4a", 3, 20)
    # the sky above the roof: the Sun, a cloud, the bud's silhouette (the goal)
    body += rect(x0, y0, w, 124, "url(#sky-day)", None, 0, 20)
    body += sun(x0 + 1250, y0 + 62, 30)
    body += cloud(x0 + 420, y0 + 70, 0.8, "#ffffff", 0.95)
    body += ellipse(x0 + 760, y0 + 58, 190, 56, "#2f5d32", None, 0, 0, 0.32)
    body += ellipse(x0 + 760, y0 + 58, 104, 32, SUGAR, None, 0, 0, 0.55)
    # the glass roof
    body += rect(x0, y0 + 124, w, 26, "#e9fff4", "#8fc9a8", 3, 0, 0.9)
    body += rect(x0, y0 + 124, w, 8, "#ffffff", None, 0, 0, 0.7)
    for k in range(6):
        rx = x0 + 120 + k * 210
        body += path(f"M{rx},{y0 + 150} l70,0 l-120,760 l-60,0 z", "#fffbe0", None, 0, 0.2)
    # the tall columns (palisade)
    for k in range(12):
        body += palisade(x0 + 30 + k * 106, y0 + 156, 74, 262, True, k, 6)
    for k in range(7):
        body += spark(x0 + 70 + k * 190, y0 + 172 + (k % 2) * 26, 11)
    # the round cells around the air cave (spongy); two thirsty ones
    sp = [(140, 520, 82, 64, False), (350, 545, 92, 70, False), (580, 505, 80, 62, False), (800, 540, 92, 70, False),
          (1060, 515, 84, 64, False), (1240, 545, 60, 60, False),
          (130, 760, 80, 62, False), (360, 780, 86, 66, True), (580, 750, 80, 62, True), (800, 785, 88, 66, False)]
    for i, (sx, sy, rx, ry, sag) in enumerate(sp):
        body += cell(x0 + sx, y0 + sy, rx, ry, sag, 6, not sag, 30 + i)
    # the vein: blue and gold pipes in a sheath
    vx, vy = x0 + 1150, y0 + 720
    body += ellipse(vx, vy, 124, 82, SHEATH, CELL_RIM, 3)
    body += circle(vx - 44, vy, 42, PIPE_BLUE, WATER_DARK, 4) + circle(vx + 44, vy, 42, PIPE_GOLD, SUGAR_DARK, 4)
    body += drop(vx - 44, vy + 6, 15) + sugar(vx + 44, vy, 17, False)
    # sugar from the working cells to the gold pipe; water from the blue pipe to a thirsty cell
    body += sugar(x0 + 580, y0 + 432, 17) + sugar(x0 + 1060, y0 + 440, 17)
    body += curve_arrow(x0 + 1075, y0 + 458, x0 + 1200, y0 + 560, vx + 60, vy - 60, SUGAR_DARK, 4, "gold")
    body += curve_arrow(x0 + 600, y0 + 452, x0 + 900, y0 + 620, vx + 30, vy - 78, SUGAR_DARK, 4, "gold", "10 7")
    body += curve_arrow(vx - 92, vy - 6, x0 + 860, y0 + 650, x0 + 650, y0 + 718, WATER_DARK, 4, "water")
    body += drop(x0 + 860, y0 + 668, 9) + drop(x0 + 760, y0 + 676, 8)
    # the floor (lower skin) with six doors
    fy = y0 + 900
    body += rect(x0, fy, w, 34, "#c9f3a5", "#8cc56a", 3)
    doors = [(160, "open"), (370, "closed"), (580, "open"), (790, "closed"), (1000, "open"), (1210, "closed")]
    for dx, st in doors:
        body += door(x0 + dx, fy + 17, 110, st)
    # outside, under the leaf
    body += rect(x0 + 2, fy + 34, w - 4, h - (fy + 34 - y0) - 2, "#e6f5fb", None, 0, 0)
    for dx, st in doors:
        if st == "open":
            body += mist(x0 + dx - 6, fy + 38, 60, 0.85) + mist(x0 + dx + 14, fy + 40, 44, 0.6)
            body += co2(x0 + dx + 34, fy - 34, 14) + co2(x0 + dx - 30, fy - 78, 14)
            body += curve_arrow(x0 + dx + 34, fy - 52, x0 + dx + 64, fy - 120, x0 + dx + 24, fy - 176, "#7a8790", 3, "grey")
        else:
            body += co2(x0 + dx - 24, fy + 62, 14) + co2(x0 + dx + 24, fy + 58, 14) + co2(x0 + dx, fy + 98, 14)
    # the child flies up into an open door, Hoot beside
    body += avatar(x0 + 300, y0 + 1090, 1.05, "fly")
    body += hoot(x0 + 420, y0 + 1110, 0.55, wing_up=True)
    body += curve_arrow(x0 + 260, y0 + 1040, x0 + 160, y0 + 1010, x0 + 160, fy + 44, INK, 3, "ink", "8 6")
    # callouts
    body += callout(x0 + 20, y0 + 14, ["The glass roof", "the leaf's upper skin, waxy"], x0 + 140, y0 + 136)
    body += callout(x0 + 960, y0 + 14, ["The bud's silhouette", "fills with gold: the goal"], x0 + 860, y0 + 60, 15)
    body += callout(x0 + 900, y0 + 432 - 64, ["Tall columns (palisade cells)", "most of the green workshops"], x0 + 970, y0 + 330, 15)
    body += callout(x0 + 30, y0 + 620, ["Round cells around the air cave", "(spongy cells): air flows between"], x0 + 120, y0 + 580, 15)
    body += callout(x0 + 230, y0 + 838, ["A thirsty cell", "wrinkled, its workshops dim"], x0 + 330, y0 + 810, 15)
    body += callout(x0 + 905, y0 + 812, ["The vein", "blue pipe: water in (xylem)", "gold pipe: sugar out (phloem)"], vx - 60, vy + 62, 15)
    body += callout(x0 + 650, fy + 58, ["Open door (stoma)", "air in; water escapes as mist"], x0 + 600, fy + 20, 15)
    body += callout(x0 + 1010, fy + 128, ["Closed door", "water kept; no air in"], x0 + 1210, fy + 24, 15)
    body += callout(x0 + 470, y0 + 1060, ["You: about 18 µm tall", "flying up into a door"], x0 + 330, y0 + 1070, 15)
    # legend
    lx, ly = 1380, 140
    body += card(lx, ly, 380, 1110)
    body += text(lx + 190, ly + 44, "What things look like", 22, "middle", "bold")
    rows = [("water", lambda x, y: drop(x, y + 6, 14), "blue drops; pale blue mist when it escapes"),
            ("air the plant needs (CO2)", lambda x, y: co2(x, y, 16), "a grey puff, dark core, two red dots"),
            ("oxygen", lambda x, y: o2(x, y, 15), "pink-white bubbles leaving"),
            ("sugar", lambda x, y: sugar(x, y, 16), "a gold hexagon that glows"),
            ("light", lambda x, y: spark(x, y, 16), "gold sparks from the roof"),
            ("minerals", lambda x, y: mineral(x, y, 14), "tiny violet sparks"),
            ("a door (stoma)", lambda x, y: door(x, y, 70, "open"), "two green guard cells"),
            ("a green workshop", lambda x, y: circle(x, y, 22, "url(#glow-green)") + ellipse(x, y, 16, 9, CHLORO, "#155c32", 1.5), "a chloroplast, glowing when it works"),
            ("a cell", lambda x, y: cell(x, y, 26, 22, False, 4, True, 99), "plump when full of water"),
            ("a thirsty cell", lambda x, y: cell(x, y, 26, 22, True, 4, False, 98), "wrinkled and pale: the leaf droops"),
            ("the vein's pipes", lambda x, y: circle(x - 14, y, 13, PIPE_BLUE, WATER_DARK, 3) + circle(x + 14, y, 13, PIPE_GOLD, SUGAR_DARK, 3), "blue brings water, gold takes sugar")]
    for i, (name, draw, desc) in enumerate(rows):
        yy = ly + 104 + i * 92
        body += draw(lx + 50, yy)
        body += text(lx + 100, yy - 4, name, 17, "start", "bold")
        body += text(lx + 100, yy + 20, desc, 14, "start", "normal", SOFT_INK)
    return svg(W, H, body, common_defs())


# --- 04: the doors and the weather (curves from the model) ---------------------------------------------------------------
def _load_model():
    spec = importlib.util.spec_from_file_location("voyage_5_1_model", os.path.join(HERE, "model", "voyage_5_1_model.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _trace(mod, policy, seed):
    rng = random.Random(seed)
    reaction = {"rule": 1.5, "slow": 4.0}.get(policy, 1.5)
    leaf, child = mod.Leaf(), mod.Child(policy, "flat", rng, reaction)
    rows, t = [], 0.0
    total = sum(s for _, s in mod.SCRIPT)
    while t < total:
        kind, since = mod.weather_at(t)
        child.act(leaf, kind, since)
        leaf.step(kind)
        rows.append((t, leaf.W, sum(leaf.open), leaf.sugar))
        t += mod.DT
    return rows


def pic_doors():
    mod = _load_model()
    W, H = 1800, 1040
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "In the cloud, open. In the blaze, close.", "Voyage 5.1, Act 2: the weather is the music; the curves are the phase A model's (one run each)")
    gx, gy, gw, gh = 120, 330, 1580, 330
    total = sum(s for _, s in mod.SCRIPT)
    sx = gw / total
    # weather strip
    t0 = 0.0
    names = {"blaze": "blaze", "cloud": "cloud", "evening": "evening"}
    turn = 0
    for idx, (kind, sec) in enumerate(mod.SCRIPT):
        x = gx + t0 * sx
        wdt = sec * sx
        colour = {"blaze": "#ffe3a3", "cloud": "#dfeefa", "evening": "#f7d9c4"}[kind]
        body += rect(x, 130, wdt - 3, 520 + 30, colour, None, 0, 6, 0.85)
        if kind == "blaze":
            body += sun(x + wdt / 2, 175, 18, True)
        elif kind == "cloud":
            body += cloud(x + wdt / 2, 182, 0.55)
        else:
            body += circle(x + wdt / 2, 178, 16, "#ffcf9a", "#e09a60", 3)
        judged = idx in mod.JUDGED
        tag = "judged" if judged else ("teaching" if kind != "evening" else "")
        if kind == "cloud":
            turn += 1
        label = "the trap" if idx == 0 else names[kind] + (f" {turn}" if kind != "evening" and turn else "")
        body += text(x + wdt / 2, 225, label, 15, "middle", "bold")
        if tag:
            body += text(x + wdt / 2, 246, tag, 13, "middle", "normal", "#1f7a3a" if judged else SOFT_INK, True)
        # doors row
        dy = 280
        if kind == "cloud":
            body += door(x + wdt / 2, dy, 52, "open") + co2(x + wdt / 2 + 30, dy - 22, 9)
        elif kind == "blaze":
            body += door(x + wdt / 2, dy, 52, "closed")
        t0 += sec
    # the graph of leaf water
    body += rect(gx, gy, gw, gh, "#ffffff", "#c7d1d6", 2, 6, 0.9)
    for v in (0.0, 0.25, 0.5, 0.75, 1.0):
        yy = gy + gh - v * gh
        body += line(gx, yy, gx + gw, yy, "#e3e8ea", 1)
        body += text(gx - 10, yy + 5, f"{v:.2f}", 13, "end", "normal", SOFT_INK)
    droop_y = gy + gh - mod.DROOP * gh
    body += line(gx, droop_y, gx + gw, droop_y, "#e2453c", 2, 0.9, None, "10 6")
    body += text(gx + gw - 6, droop_y - 8, "below this the leaf droops", 14, "end", "bold", "#c0392b")
    body += text(gx - 60, gy + gh / 2, "leaf water", 15, "middle", "bold", INK).replace("<text", f'<text transform="rotate(-90 {gx - 60} {gy + gh / 2})"', 1)
    styles = [("rule", 1, WATER_DARK, None, 5, "knows the rule"), ("always_open", 1, "#e2453c", "14 8", 4, "always open"),
              ("random", 3, "#7a8790", "3 7", 4, "random taps")]
    sugar_rows = None
    for policy, seed, colour, dash, sw, label in styles:
        rows = _trace(mod, policy, seed)
        pts = " ".join(f"{gx + r[0] * sx:.1f},{gy + gh - r[1] * gh:.1f}" for r in rows[::3])
        d = f' stroke-dasharray="{dash}"' if dash else ""
        body += f'<polyline points="{pts}" fill="none" stroke="{colour}" stroke-width="{sw}" stroke-linejoin="round"{d}/>'
        if policy == "rule":
            sugar_rows = rows
    # legend for curves (bottom left, clear of the curves)
    lgx = gx + 20
    body += rect(gx + 8, gy + gh - 96, 260, 86, "#ffffff", "#c7d1d6", 1.5, 8, 0.95)
    for i, (policy, seed, colour, dash, sw, label) in enumerate(styles):
        yy = gy + gh - 74 + i * 24
        dd = f' stroke-dasharray="{dash}"' if dash else ""
        body += f'<line x1="{lgx}" y1="{yy}" x2="{lgx + 50}" y2="{yy}" stroke="{colour}" stroke-width="{sw}"{dd}/>'
        body += text(lgx + 60, yy + 5, label, 15, "start", "bold", colour if policy != "random" else SOFT_INK)
    # sugar steps for the rule player
    sy0 = gy + gh + 50
    body += text(gx - 10, sy0 + 26, "sugar", 15, "end", "bold", SUGAR_DARK)
    made_last = 0
    for t, w_, n, s in sugar_rows:
        if int(s) > made_last:
            made_last = int(s)
            body += sugar(gx + t * sx, sy0 + 22, 11, False)
    body += text(gx + gw, sy0 + 70, f"the rule player builds {made_last} sugars: the bud needs 12", 15, "end", "normal", SOFT_INK, True)
    # plant outside
    py = 860
    body += text(gx, py, "Outside, the sunflower:", 18, "start", "bold")
    body += text(gx + 260, py, "the rule keeps it standing; always-open lets it droop four times; always-closed keeps it standing but builds nothing.", 17, "start", "normal", INK)
    body += text(gx, py + 40, "Judged (5 of 6 to master): in each silent cloud, open more than in the blaze before and build at least 2 sugars;", 17, "start", "normal", INK)
    body += text(gx, py + 66, "in each silent blaze, never droop and have at most 2 of 6 doors open in its second half.", 17, "start", "normal", INK)
    body += text(gx, py + 106, "Random taps rarely dry the leaf but get the timing wrong (doors open in the blaze, shut in the cloud): the beats judge the timing.", 17, "start", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- 05: the core loop ---------------------------------------------------------------------------------------------------
def pic_loop():
    W, H = 1500, 1080
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "The core loop", "Every 10 seconds an act, every minute a beat, every 10 minutes a voyage, across days the ladder and the garden")
    cx, cy = 540, 590
    rings = [(430, "#e7f2dc"), (320, "#d6ecf7"), (215, "#fff1c9"), (110, "#ffe0d6")]
    for r, fill in rings:
        body += circle(cx, cy, r, fill, "#b9c6cc", 3)

    def at(radius, deg):
        a = math.radians(deg)
        return cx + math.cos(a) * radius, cy + math.sin(a) * radius

    # clockwise arrows on each band
    for r_mid in (162, 267, 375):
        x1, y1 = at(r_mid, -60)
        x2, y2 = at(r_mid, -30)
        xc, yc = at(r_mid + 18, -45)
        body += curve_arrow(x1, y1, xc, yc, x2, y2, INK, 3)
    # 10 s: one act
    body += pill(cx, cy - 66, "10 s: an act", 15, "#c0563b")
    body += door(cx, cy + 2, 92, "closed") + _vr_hand(cx - 66, cy + 2, 0.55, 80, True) + _vr_hand(cx + 66, cy + 2, 0.55, -80, True)
    body += text(cx, cy + 56, "squeeze a door shut", 14, "middle", "bold")
    # 1 min: a beat (cloud → open → sugar → blaze → closed, carry)
    body += pill(cx, cy - 162, "1 min: a beat", 15, "#b07d00")
    x, y = at(162, 200)
    body += cloud(x, y, 0.32)
    x, y = at(162, 150)
    body += door(x, y, 46, "open") + co2(x + 22, y - 18, 7)
    x, y = at(162, 90)
    body += sugar(x, y, 14)
    x, y = at(162, 30)
    body += sun(x, y, 12, True)
    x, y = at(162, -20)
    body += door(x, y, 46, "closed")
    # 10 min: a voyage
    body += pill(cx, cy - 267, "10 min: a voyage", 15, "#2a6f9a")
    x, y = at(267, 205)
    body += group(sunflower(0, 0, 70, "droop", pale=True), x, y + 36, 0.75)
    x, y = at(267, 235)
    body += spark(x, y, 16) + spark(x + 18, y - 16, 9)
    x, y = at(267, -40)
    body += cell(x, y, 26, 22, False, 4, True, 7)
    x, y = at(267, 10)
    body += door(x, y, 44, "open")
    x, y = at(267, 62)
    body += group(sunflower(0, 0, 70, "stand", bloom=True), x, y + 22, 0.5)
    x, y = at(267, 125)
    body += block_stack(x, y + 30, 4, SUGAR, 12, None, new=1)
    # days: the ladder and the garden
    body += pill(cx, cy - 375, "days: the ladder and the garden", 15, "#2f6b2f")
    for k, deg in enumerate((120, 105, 90, 75, 60)):
        x, y = at(375, deg)
        body += circle(x, y, 22, "#ffffff", INK, 2.5) + text(x, y + 7, str(4 + k), 18, "middle", "bold")
    x, y = at(375, 160)
    body += rect(x - 14, y - 40, 28, 56, "#3f9a5a", INK, 2.5, 13) + rect(x - 30, y - 20, 14, 26, "#3f9a5a", INK, 2, 7)
    x, y = at(375, 200)
    body += ellipse(x, y, 34, 9, "#4fb85a", INK, 2) + circle(x + 18, y - 12, 9, "#ffb7d5", "#d16a98", 2)
    x, y = at(375, 20)
    body += ellipse(x, y, 30, 22, "#ff9a2e", INK, 2.5) + line(x, y - 22, x + 4, y - 32, STEM_DARK, 4)
    x, y = at(375, -20)
    body += path(f"M{x},{y + 24} L{x},{y - 16} M{x},{y - 4} l-14,-14 M{x},{y - 8} l14,-14", "none", "#6b4a2f", 5)
    # legend at right
    lx = 1010
    body += card(lx, 170, 450, 800)
    rows = [("10 s", "#c0563b", "one act with the hands; the world answers at once (a squeak, the mist stops, a cell plumps)"),
            ("1 min", "#b07d00", "one beat; the leaf changes: it lifts, the workshops glow, the bud above fills"),
            ("10 min", "#2a6f9a", "one voyage; the real plant changes for good: it stands, blooms, grows heavy"),
            ("days", "#2f6b2f", "Size Magic goes deeper each grade (rungs 4-8); the garden gains plants (a cactus, a lily, a pumpkin, a tree); friends visit (phase D)")]
    for i, (k, colour, v) in enumerate(rows):
        yy = 230 + i * 185
        body += text(lx + 30, yy, k, 28, "start", "bold", colour)
        body += lines_of_text(lx + 30, yy + 36, wrap(v, 38), 18, "start")
    body += text(W / 2, H - 22, "Inside a leaf the rhythm alternates two jobs: in the cloud, open the doors; in the blaze, close them and carry the sugar.", 18, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- 06: the ladder ------------------------------------------------------------------------------------------------------
def pic_ladder():
    W, H = 1800, 1320
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "The ladder: Size Magic goes deeper each grade", "One plant, five depths; each rung's verbs, its units and its new places (transfer)")
    rungs = [
        ("4", "Plant Explorer", "ant-sized, ×50-300", "the plant is a skyscraper",
         "guide water from soil to leaf · turn leaves to the sun · open petals for the bee",
         "g4.plant_animal_parts (plant half), g3.plants_needs", "the cactus stem · the water lily", "#e8f6dc"),
        ("5", "Built from Air", "cell-sized, ×85,000", "the leaf is a cathedral",
         "open and close the doors by the weather · let air in · carry sugar to the bud · test what builds a plant",
         "g5.plants_air_water, g5.sun_energy_food", "the desert night · the three beans · the pond bubbles", "#d9f0f9"),
        ("6", "One Cell", "inside a cell, ×500,000", "the cell is a palace",
         "fill the water balloon · turn chloroplasts to or away from the light · build the wall to the plan · feed the power stations",
         "g6.cells", "the animal-cell visitor · the onion", "#fff3d1"),
        ("7", "Atom Builders", "molecule-sized, ×2,000,000,000", "atoms like footballs",
         "catch rare CO2 · split water with light · build the sugar ring carbon by carbon · burn it at night",
         "g7.photosynthesis", "the Mars dome · the bread rises", "#fde4dc"),
        ("8", "The Whole Plant", "the plant as a map", "back out: the plant's roads",
         "keep the water rope whole · send sugar where it is needed · grow the giant pumpkin · design a plant",
         "g8.transport_systems (plant half)", "the cactus's secret · the winter tree · the lily's breath", "#ece3f7")]
    y = 130
    for i, (g, name, scale, look, verbs, units, transfer, fill) in enumerate(rungs):
        hgt = 222
        body += rect(60, y, 1680, hgt - 14, fill, "#c9d2d6", 2, 18)
        body += circle(130, y + 100, 52, "#ffffff", INK, 4) + text(130, y + 92, "grade", 15, "middle", "bold") + text(130, y + 124, g, 34, "middle", "bold")
        body += text(210, y + 50, f"Rung {g}: {name}", 28, "start", "bold")
        body += text(210, y + 82, f"{scale}: {look}", 18, "start", "normal", SOFT_INK, True)
        body += text(210, y + 118, "Verbs: " + verbs, 17, "start", "normal")
        body += text(210, y + 148, "Units: " + units, 17, "start", "normal", "#2f6b2f")
        body += text(210, y + 178, "New places: " + transfer, 17, "start", "bold", "#7a3f9e")
        ix = 1560
        if g == "4":
            body += group(sunflower(0, 0, 150, "stand", bloom=True), ix, y + 196, 0.8) + avatar(ix + 70, y + 190, 0.35)
        elif g == "5":
            body += palisade(ix - 60, y + 30, 36, 90, True, 1) + palisade(ix - 16, y + 30, 36, 100, True, 2) + cell(ix + 60, y + 120, 50, 40, False, 5, True, 3)
            body += door(ix, y + 175, 70, "open") + avatar(ix - 70, y + 170, 0.5, "fly")
        elif g == "6":
            body += ellipse(ix, y + 100, 110, 80, "#d9f5c4", "#6aa05a", 6) + ellipse(ix, y + 104, 80, 56, VACUOLE, "#7fb7d9", 3)
            body += ellipse(ix - 70, y + 60, 16, 9, CHLORO, "#155c32", 2, 30) + ellipse(ix + 74, y + 70, 16, 9, CHLORO, "#155c32", 2, -30)
            body += circle(ix + 40, y + 150, 18, NUCLEUS, "#5b3f99", 2) + ellipse(ix - 50, y + 150, 18, 9, MITO, "#c45f14", 2)
        elif g == "7":
            for k in range(6):
                body += circle(ix - 90 + k * 34, y + 90 + (12 if k % 2 else 0), 13, CARBON, INK, 2)
            body += co2(ix - 40, y + 160, 12, True) + h2o(ix + 60, y + 155, 13) + o2(ix + 100, y + 60, 14, True)
        else:
            body += path(f"M{ix},{y + 190} L{ix},{y + 60}", "none", STEM_DARK, 10)
            for k, (dx, dy) in enumerate([(-60, 80), (60, 100), (-50, 130), (55, 150)]):
                body += ellipse(ix + dx, y + dy, 36, 12, LEAF, INK, 2, 20 if dx < 0 else -20)
            body += path(f"M{ix},{y + 190} q-40,20 -70,10 M{ix},{y + 190} q40,24 72,12", "none", "#8a5a3b", 6)
            body += line(ix + 9, y + 182, ix + 9, y + 64, WATER, 6, 1, "water") + line(ix - 9, y + 64, ix - 9, y + 182, SUGAR, 6, 1, "gold")
        if i < 4:
            body += line(130, y + 152, 130, y + hgt + 48, INK, 4, 0.6, "ink", "6 6")
        y += hgt
    body += text(W / 2, H - 40, "Voyage 5.1 is everyone's prologue; the grade picks the default rung; every rung stays open; transfer voyages come after their idea.", 18, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- 07: things and colours ----------------------------------------------------------------------------------------------
def pic_things():
    W, H = 1700, 1000
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "The look of things: one meaning, one colour, one shape, one sound", "Rungs 4-6 show a sign; rung 7 shows the truth underneath (atoms in their real counts)")
    cols = [(330, "rungs 4-6"), (720, "rung 7"), (1180, "its colour and shape"), (1520, "its sound")]
    for x, t in cols:
        body += text(x, 150, t, 20, "middle", "bold", SOFT_INK)
    rows = [("water", lambda x, y: drop(x, y + 6, 20), lambda x, y: h2o(x, y, 18), "bright blue drops; pale blue mist escaping", "drips; a glug climbing"),
            ("air (CO2)", lambda x, y: co2(x, y, 22), lambda x, y: co2(x, y, 16, True), "grey puff, dark core, two red dots", "a soft pop arriving"),
            ("oxygen", lambda x, y: o2(x, y, 20), lambda x, y: o2(x, y, 20, True), "pink-white bubbles leaving", "a bubble"),
            ("sugar", lambda x, y: sugar(x, y, 22), lambda x, y: _ring(x, y), "honey-gold hexagon that glows (stored light)", "a ding; a chord"),
            ("light", lambda x, y: spark(x, y, 22), lambda x, y: spark(x, y, 22), "gold sparks (energy is gold, never a thing)", "a shimmer"),
            ("minerals", lambda x, y: mineral(x, y, 18), lambda x, y: mineral(x, y, 18), "tiny violet sparks: a pinch", "a tick"),
            ("nitrogen", lambda x, y: text(x, y + 6, "(unseen)", 16, "middle", "normal", SOFT_INK, True), lambda x, y: n2(x, y, 18), "blue-grey pairs: most of the air", "a hush")]
    for i, (name, a, b, desc, sound) in enumerate(rows):
        y = 210 + i * 108
        body += rect(60, y - 44, 1580, 96, "#ffffff" if i % 2 == 0 else "#f1f5f3", None, 0, 12)
        body += text(90, y + 6, name, 21, "start", "bold")
        body += a(330, y) + b(720, y)
        body += text(980, y + 6, desc, 17, "start")
        body += text(1520, y + 6, sound, 17, "middle", "normal", SOFT_INK, True)
    body += text(W / 2, H - 30, "Shape and motion carry each meaning too, so nothing depends on colour alone.", 18, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


def _ring(x, y):
    pts = [(x + 26 * math.cos(math.radians(30 + 60 * i)), y + 26 * math.sin(math.radians(30 + 60 * i))) for i in range(6)]
    out = circle(x, y, 42, "url(#glow-gold)")
    out += "".join(line(pts[i][0], pts[i][1], pts[(i + 1) % 6][0], pts[(i + 1) % 6][1], SUGAR_DARK, 4) for i in range(6))
    for i, (px, py) in enumerate(pts):
        out += circle(px, py, 9, OXYGEN if i == 5 else CARBON, INK, 2)
    ax, ay = pts[0][0] + 20, pts[0][1] - 14
    out += line(pts[0][0], pts[0][1], ax, ay, SUGAR_DARK, 4) + circle(ax, ay, 8, CARBON, INK, 2)
    return out


# --- 08: one cell --------------------------------------------------------------------------------------------------------
def pic_cell():
    W, H = 1600, 1000
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "Rung 6, One Cell: inside a palisade cell", "The wall, the soft skin with water gates, the water balloon, chloroplasts that move with the light, power stations, the nucleus")
    cx, cy = 560, 560
    body += rect(cx - 400, cy - 380, 800, 760, "#eaf7dc", "#7fae63", 18, 60)
    for k in range(9):
        body += line(cx - 400 + k * 100, cy - 380, cx - 400 + k * 100, cy + 380, "#c8e3b4", 3)
    body += rect(cx - 370, cy - 350, 740, 700, "#f5fff0", "#9dd08a", 4, 50)
    body += ellipse(cx, cy + 10, 290, 280, VACUOLE, "#7fb7d9", 4, 0, 0.9)
    body += text(cx, cy + 10, "the water balloon (vacuole)", 22, "middle", "bold", "#2a6f9a")
    body += text(cx, cy + 40, "full: it presses the skin against the wall, the leaf stands", 16, "middle", "normal", "#2a6f9a", True)
    for k, (dx, dy, rot) in enumerate([(-300, -300, 0), (-150, -330, 0), (0, -335, 0), (150, -330, 0), (300, -300, 0)]):
        body += circle(cx + dx, cy + dy, 34, "url(#glow-green)") + ellipse(cx + dx, cy + dy, 34, 15, CHLORO, "#155c32", 2.5, rot)
    body += text(cx, cy - 250, "chloroplasts face-on to the lit wall (dim light)", 17, "middle", "bold", "#155c32")
    body += circle(cx + 220, cy + 260, 46, NUCLEUS, "#5b3f99", 3) + circle(cx + 230, cy + 255, 14, "#6c4fb0")
    body += text(cx + 220, cy + 330, "nucleus: the plan", 16, "middle", "bold", "#5b3f99")
    for dx, dy in ((-280, 250), (-180, 300), (300, 120)):
        body += ellipse(cx + dx, cy + dy, 34, 16, MITO, "#c45f14", 2.5, 15)
        body += path(f"M{cx + dx - 20},{cy + dy} q6,-8 12,0 q6,8 12,0 q6,-8 12,0", "none", "#c45f14", 2)
    body += text(cx - 230, cy + 345, "power stations (mitochondria)", 16, "middle", "bold", "#c45f14")
    body += sun(cx + 300, cy - 412, 20)
    for k in range(4):
        body += line(cx + 272 - k * 40, cy - 396, cx + 210 - k * 120, cy - 362, "#ffd44a", 5, 0.8)
    body += avatar(cx - 80, cy - 100, 0.9, "fly") + hoot(cx - 150, cy - 110, 0.5, True)
    body += text(cx - 395, cy - 395, "stiff wall (cellulose: chains of sugar)", 16, "start", "bold", "#4f7a3d")
    body += rect(cx - 380, cy - 40, 22, 60, "#7fd0ff", "#2a6f9a", 2, 6) + text(cx - 340, cy - 50, "water gate", 15, "start", "bold", "#2a6f9a")
    # insets
    ix = 1060
    body += card(ix, 160, 500, 380)
    body += text(ix + 250, 200, "The water balloon, full and empty", 20, "middle", "bold")
    body += rect(ix + 40, 240, 180, 200, "#f5fff0", "#7fae63", 8, 20) + ellipse(ix + 130, 340, 78, 88, VACUOLE, "#7fb7d9", 3)
    body += text(ix + 130, 470, "full: firm", 16, "middle", "bold", "#2a6f9a")
    body += rect(ix + 280, 240, 180, 200, "#f5fff0", "#7fae63", 8, 20) + ellipse(ix + 370, 350, 46, 52, VACUOLE, "#7fb7d9", 3)
    body += path(f"M{ix + 300},{262} q40,30 140,0", "none", "#9dd08a", 3)
    body += text(ix + 370, 470, "empty: the cell sags", 16, "middle", "bold", "#a0522d")
    body += text(ix + 250, 515, "Verb: open the water gates to refill it", 16, "middle", "normal", SOFT_INK, True)
    body += card(ix, 570, 500, 380)
    body += text(ix + 250, 610, "Chloroplasts and the light", 20, "middle", "bold")
    body += sun(ix + 90, 670, 14, False) + text(ix + 130, 676, "dim: face-on, at the lit wall", 15, "start", "bold")
    for k in range(4):
        body += ellipse(ix + 100 + k * 90, 730, 34, 14, CHLORO, "#155c32", 2.5)
    body += sun(ix + 90, 800, 22) + text(ix + 130, 806, "blazing: edge-on, at the side walls", 15, "start", "bold")
    for k in range(4):
        body += ellipse(ix + 100 + k * 90, 870, 8, 26, CHLORO, "#155c32", 2.5)
    body += text(ix + 250, 925, "Wrong way round: they bleach pale (real: Kasahara et al. 2002)", 15, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- 09: VR ----------------------------------------------------------------------------------------------------------------
def _vr_hand(x, y, s, rot=0, grip=False, fill="#ffd9b8"):
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
    W, H = 1800, 760
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "In VR the hands do the idea", "Swim through thick air (you stop when you stop), squeeze a door shut with both hands, carry sugar to the gold pipe")
    panels = [("Swim", "grip and pull: the body glides the other way; let go and the thick air stops you"),
              ("Squeeze a door", "two hands press the two green guard cells together: the mist stops"),
              ("Carry sugar", "take a gold hexagon and push it into the gold pipe: whoosh, a buzz in the hand")]
    for i, (name, desc) in enumerate(panels):
        px = 40 + i * 590
        body += rect(px, 130, 560, 560, "url(#cave)", "#2d5d4a", 3, 20)
        if i == 0:
            body += cell(px + 140, 300, 90, 70, False, 5, True, 1) + cell(px + 420, 260, 80, 64, False, 5, True, 2)
            body += _vr_hand(px + 190, 560, 1.4, -20, True) + _vr_hand(px + 380, 560, 1.4, 20, True)
            body += line(px + 200, 520, px + 160, 640, "#ffffff", 4, 0.8, "white") + line(px + 380, 520, px + 420, 640, "#ffffff", 4, 0.8, "white")
            body += line(px + 280, 420, px + 280, 330, "#ffffff", 6, 0.9, "white")
            body += pill(px + 280, 452, "you glide forward", 16, "#2d5d4a")
        elif i == 1:
            body += rect(px + 20, 430, 520, 60, "#c9f3a5", "#8cc56a", 3)
            body += door(px + 280, 460, 240, "closed")
            body += _vr_hand(px + 150, 400, 1.3, 70, True) + _vr_hand(px + 410, 400, 1.3, -70, True)
            body += line(px + 190, 330, px + 240, 360, "#ffffff", 5, 0.9, "white") + line(px + 370, 330, px + 320, 360, "#ffffff", 5, 0.9, "white")
            body += mist(px + 280, 500, 70, 0.25)
            body += pill(px + 280, 610, "squeak... sigh: shut", 16, "#2d5d4a")
        else:
            body += ellipse(px + 380, 520, 130, 90, SHEATH, CELL_RIM, 3) + circle(px + 330, 520, 48, PIPE_BLUE, WATER_DARK, 4) + circle(px + 430, 520, 48, PIPE_GOLD, SUGAR_DARK, 4)
            body += _vr_hand(px + 210, 330, 1.3, 30, True) + sugar(px + 230, 290, 30)
            body += curve_arrow(px + 260, 300, px + 400, 300, px + 425, 460, "#ffffff", 5, "white")
            body += pill(px + 380, 640, "whoosh: off to the bud", 16, "#2d5d4a")
        body += pill(px + 280, 186, name, 24)
        words, lines_, cur = desc.split(" "), [], ""
        for wd in words:
            if len(cur) + len(wd) > 46:
                lines_.append(cur)
                cur = wd
            else:
                cur = (cur + " " + wd).strip()
        lines_.append(cur)
        body += lines_of_text(px + 280, 712, lines_, 16, "middle", "normal", INK)
    return svg(W, H, body, common_defs())


# --- 10: the transfer worlds ---------------------------------------------------------------------------------------------
def pic_transfer():
    W, H = 1800, 820
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "New places: the rule must change its shape (transfer)", "Each is a voyage where the sunflower's habit fails and the understood idea wins")
    panels = [("The desert night (5.T1, 8.T1)", "No clouds in the desert: open the doors at night, keep the air in jars, build by day behind shut doors. A white flower opens under the stars."),
              ("The water lily (4.T2, 8.T3)", "The leaf floats: its doors are on top. Send air down the long stalk to the roots in the mud."),
              ("The winter tree (8.T2)", "Frozen ground, no water: drop the leaves and live on the store. In spring the store sends sugar up to the buds."),
              ("The Mars dome (7.T1)", "The crew breathes out CO2; the dome's plants build sugar under red and blue lamps and give back oxygen. Balance it.")]
    for i, (name, desc) in enumerate(panels):
        px = 30 + i * 440
        if i == 0:
            body += rect(px, 120, 420, 520, "url(#sky-night)", "#1a2a5a", 3, 18)
            rng = random.Random(3)
            for _ in range(40):
                body += circle(px + rng.uniform(10, 410), 130 + rng.uniform(0, 260), rng.uniform(1, 2.6), "#ffffff", None, 0, 0.9)
            body += circle(px + 340, 190, 26, "#f4f1d0", "#c9c4a0", 2)
            body += rect(px, 520, 420, 120, "#d8b46a", None, 0, 0)
            body += rect(px + 170, 300, 80, 230, "#3f9a5a", INK, 3, 38)
            body += rect(px + 110, 380, 50, 110, "#3f9a5a", INK, 3, 24) + rect(px + 260, 360, 50, 100, "#3f9a5a", INK, 3, 24)
            for k in range(8):
                body += line(px + 180 + (k % 2) * 60, 320 + k * 26, px + 170 + (k % 2) * 80, 314 + k * 26, "#f4f1d0", 2)
            for k in range(10):
                a = math.radians(k * 36)
                body += ellipse(px + 210 + math.cos(a) * 30, 290 + math.sin(a) * 30, 24, 10, "#ffffff", "#cfd6e0", 2, k * 36)
            body += circle(px + 210, 290, 14, "#ffe9a8")
            for k in range(3):
                body += rect(px + 40 + k * 40, 560, 26, 44, "#c9f0ff", "#5aa0c8", 2, 6, 0.9) + rect(px + 40 + k * 40, 584 - k * 8, 26, 20 + k * 8, "#b48cff", None, 0, 4, 0.8)
            body += door_top(px + 360, 590, 40, "open") + co2(px + 360, 548, 10)
            body += text(px + 100, 620, "inside: jars of kept air", 13, "middle", "bold", "#3b2a6b")
        elif i == 1:
            body += rect(px, 120, 420, 520, "url(#sky-day)", "#9ec3dc", 3, 18)
            body += rect(px, 380, 420, 260, "#5aa7c8", None, 0, 0, 0.9)
            body += rect(px, 560, 420, 80, "#6b5340", None, 0, 0)
            body += ellipse(px + 210, 380, 160, 26, "#4fb85a", INK, 3)
            for k in range(3):
                body += door_top(px + 140 + k * 70, 374, 26, "open")
            body += path(f"M{px + 210},{400} C{px + 200},{470} {px + 230},{520} {px + 210},{580}", "none", "#3d7d28", 10)
            for k in range(4):
                body += co2(px + 210 + (k % 2) * 6 - 3, 420 + k * 40, 7)
            body += line(px + 240, 420, px + 240, 560, "#ffffff", 3, 0.9, "white")
            body += ellipse(px + 210, 590, 60, 14, "#8a6a4a", INK, 2)
            body += circle(px + 330, 340, 26, "#ffb7d5", "#d16a98", 3) + circle(px + 330, 340, 10, "#ffe27a")
        elif i == 2:
            body += rect(px, 120, 420, 520, "#dfe9f2", "#a8bccb", 3, 18)
            body += rect(px, 520, 420, 120, "#ffffff", "#c9d6e0", 2, 0)
            body += path(f"M{px + 210},{520} L{px + 210},{300} M{px + 210},{360} L{px + 140},{280} M{px + 210},{340} L{px + 290},{260} M{px + 175},{318} L{px + 150},{250} M{px + 255},{300} L{px + 280},{230}",
                         "none", "#6b4a2f", 12)
            body += path(f"M{px + 210},{520} q-50,40 -110,50 M{px + 210},{520} q60,40 120,46", "none", "#6b4a2f", 8)
            body += ellipse(px + 210, 580, 80, 26, SUGAR, None, 0, 0, 0.45) + sugar(px + 210, 580, 16)
            for k in range(4):
                body += circle(px + 150 + k * 40, 250 + (k % 2) * 20, 9, "#a8e07a", "#5a9a3a", 2)
            body += line(px + 300, 560, px + 300, 290, SUGAR_DARK, 5, 1, "gold")
            body += text(px + 330, 420, "spring", 16, "start", "bold", SUGAR_DARK)
            for k in range(14):
                body += circle(px + 20 + k * 30, 150 + (k * 37) % 300, 4, "#ffffff", "#b7c7d3", 1)
        else:
            body += rect(px, 120, 420, 520, "#c9714b", "#8a4a30", 3, 18)
            body += path(f"M{px + 30},{560} A180,180 0 0 1 {px + 390},{560} z", "#e6f6ff", "#9fc3d8", 4, 0.75)
            body += rect(px + 30, 556, 360, 84, "#a8533a", None, 0, 0)
            for k in range(5):
                body += path(f"M{px + 90 + k * 60},{556} l0,-60", "none", "#4fa83a", 8)
                body += ellipse(px + 90 + k * 60, 490, 14, 10, "#e3c14a", "#a08020", 2)
            body += rect(px + 100, 400, 90, 14, "#ff4d4d", None, 0, 4) + rect(px + 230, 400, 90, 14, "#4d6bff", None, 0, 4)
            body += avatar(px + 340, 556, 0.9) + co2(px + 380, 470, 10) + co2(px + 360, 446, 10)
            body += o2(px + 160, 450, 10) + o2(px + 260, 440, 10)
        words, lines_, cur = desc.split(" "), [], ""
        for wd in words:
            if len(cur) + len(wd) > 40:
                lines_.append(cur)
                cur = wd
            else:
                cur = (cur + " " + wd).strip()
        lines_.append(cur)
        body += text(px + 210, 675, name, 20, "middle", "bold")
        body += lines_of_text(px + 210, 705, lines_, 15, "middle", "normal", INK)
    return svg(W, H, body, common_defs())


# --- 11: the atom builder ------------------------------------------------------------------------------------------------
def pic_atoms():
    W, H = 1800, 1000
    body = rect(0, 0, W, H, "#f7f4ec")
    body += title_bar(W, "Rung 7, Atom Builders: inside the chloroplast", "Atoms are things you hold; none can be made or thrown away; energy is gold and ends as warmth")
    # 1. the crowd outside the door
    body += rect(40, 130, 520, 800, "#e7eef6", "#a8bccb", 3, 18)
    body += text(300, 175, "1. Catch the rare CO2", 22, "middle", "bold")
    rng = random.Random(11)
    for _ in range(46):
        body += n2(rng.uniform(80, 520), rng.uniform(220, 800), 13)
    for _ in range(12):
        body += o2(rng.uniform(80, 520), rng.uniform(220, 800), 12, True)
    body += circle(300, 560, 56, "#fff6d6", "#f0a000", 4) + co2(300, 560, 15, True)
    body += lines_of_text(300, 850, ["Most of the air is nitrogen (blue-grey pairs);", "about 4 particles in 10,000 are CO2."], 16, "middle", "normal", SOFT_INK)
    # 2. light splits water
    body += rect(600, 130, 520, 800, "#e9f7e3", "#9cc98a", 3, 18)
    body += text(860, 175, "2. Light splits water", 22, "middle", "bold")
    for k in range(5):
        body += rect(660, 260 + k * 36, 400, 26, "#3cb062", "#1d7a3c", 2, 13)
    body += text(860, 470, "the green sails (thylakoids) catch the light", 15, "middle", "normal", "#1d7a3c", True)
    for k in range(6):
        body += spark(700 + k * 64, 230, 14)
    body += h2o(720, 580, 22) + h2o(810, 580, 22)
    body += line(860, 575, 930, 552, INK, 4, 1, "ink") + line(860, 595, 930, 640, INK, 4, 1, "ink")
    body += o2(990, 550, 22, True) + text(990, 512, "oxygen out", 16, "middle", "bold", OXYGEN)
    for k in range(4):
        body += circle(950 + k * 30, 650, 12, SUGAR, INK, 2)
    body += lines_of_text(995, 690, ["hydrogen, charged", "with light (gold)"], 15, "middle", "bold", SUGAR_DARK)
    body += lines_of_text(860, 850, ["Expert secret: the oxygen comes", "from the water (1941's tracer test)"], 16, "middle", "normal", SOFT_INK)
    # 3. six carbons, one ring, a level balance
    body += rect(1160, 130, 600, 800, "#fff6e0", "#e0c58a", 3, 18)
    body += text(1460, 175, "3. Six carbons make one sugar", 22, "middle", "bold")
    for k in range(6):
        cxk = 1285 + k * 70
        body += circle(cxk, 245, 18, CARBON, INK, 2)
        if k < 5:
            body += line(cxk + 18, 245, cxk + 52, 245, SUGAR_DARK, 5)
    body += lines_of_text(1460, 292, ["each carbon comes from one CO2 and links", "with gold hydrogen; one O2 leaves each time"], 15, "middle", "normal", INK)
    body += line(1460, 330, 1460, 372, INK, 4, 1, "ink")
    body += _ring(1460, 420)
    body += lines_of_text(1460, 492, ["the chain curls into a ring: glucose", "(5 carbons and 1 oxygen; the 6th carbon on its arm)"], 15, "middle", "normal", INK)
    bx, by = 1460, 690
    body += line(bx - 190, by, bx + 190, by, INK, 6)
    body += path(f"M{bx},{by} L{bx - 30},{by + 96} L{bx + 30},{by + 96} z", "#9aa6ac", INK, 3)
    for side, label in ((-1, "in: 6 CO2 + 6 H2O"), (1, "out: 1 sugar + 6 O2")):
        px = bx + side * 190
        body += path(f"M{px},{by} l-70,70 l140,0 z", "#ffffff", INK, 3)
        body += text(px + side * -10, by - 60, label, 15, "middle", "bold")
        body += circle(px - 40, by + 52, 9, CARBON, INK, 1.5) + text(px - 26, by + 58, "6", 15, "start", "bold")
        body += circle(px + 2, by + 52, 9, HYDROGEN, INK, 1.5) + text(px + 16, by + 58, "12", 15, "start", "bold")
        body += circle(px - 40, by + 26, 9, OXYGEN, INK, 1.5) + text(px - 26, by + 32, "18", 15, "start", "bold")
    body += text(bx, by + 130, "The balance stays level: every atom is still there.", 17, "middle", "bold", "#2f6b2f")
    body += text(bx, by + 158, "The light's energy is in the ring (gold), never an atom.", 15, "middle", "normal", SOFT_INK, True)
    return svg(W, H, body, common_defs())


# --- Main ---------------------------------------------------------------------------------------------------------------
PICTURES = [("01-garden-before-after", pic_garden), ("02-the-dive", pic_dive), ("03-inside-the-leaf", pic_inside),
            ("04-doors-and-weather", pic_doors), ("05-core-loop", pic_loop), ("06-the-ladder", pic_ladder),
            ("07-things-and-colours", pic_things), ("08-one-cell", pic_cell), ("09-vr", pic_vr),
            ("10-transfer-worlds", pic_transfer), ("11-atom-builder", pic_atoms)]


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
