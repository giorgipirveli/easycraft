"""The kit the learning reels are written with (tools/make_learning_reels.py; one module a reel in this folder): a
Short's scenes, stickers and arrows, the 3D stage's models, shapes, moves and camera keys, and the JSON written the way
the other reels look.

Conventions: metres, y up, a block is 1 m; a `blocks` model's cell (x, y, z) fills [x-0.5, x+0.5] x [y, y+1] x
[z-0.5, z+0.5] from the model's `at`. The 9:16 frame: stickers in the top band (y 60-170 of 640), the subject between,
the caption's band from y 440 down: keep the subject above it (project() places 2D arrows on 3D points; the camera's
fov is vertical, so a tall frame shows a narrow slice: about 29 degrees across for 50 up and down).
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "shorts", "cinematic")
STAGE_W, STAGE_H = 360.0, 640.0


# --- Writing JSON the way the other reels look (tabs; short things on one line) ---------------------------------------

def _clean(x):
    if isinstance(x, float):
        r = round(x, 3)
        return int(r) if r == int(r) and abs(r) < 1e9 else r
    if isinstance(x, dict):
        return {k: _clean(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [_clean(v) for v in x]
    return x


def _dump(x, indent=0):
    flat = json.dumps(x, ensure_ascii=False)
    if len(flat) + indent * 4 <= 116 or not isinstance(x, (dict, list)):
        return flat
    pad = "\t" * (indent + 1)
    end = "\t" * indent
    if isinstance(x, dict):
        items = [pad + json.dumps(k, ensure_ascii=False) + ": " + _dump(v, indent + 1) for k, v in x.items()]
        return "{\n" + ",\n".join(items) + "\n" + end + "}"
    items = [pad + _dump(v, indent + 1) for v in x]
    return "[\n" + ",\n".join(items) + "\n" + end + "]"


def write(short):
    short = _clean(short)
    path = os.path.join(OUT, short["id"] + ".json")
    with open(path, "w", encoding="utf-8") as f:
        f.write(_dump(short) + "\n")
    secs = sum(s["seconds"] for s in short["scenes"])
    print("wrote %s (%.1f s, %d models, %d effects, %d camera keys)" % (os.path.relpath(path, ROOT), secs,
        len(short["stage"]["models"]), len(short["stage"].get("effects", [])), len(short["stage"]["camera"])))


# --- 2D: stickers and arrows over the picture -------------------------------------------------------------------------

SAFE_X = (8.0, 352.0)      # ShortStyle.SAFE's left and right
CAPTION_TOP = 440.0


def sticker_width(text, size):
    """A words sticker's width on the stage, a little over (measured on the quality test's boxes: letters and the
    sticker's padding)."""
    return size * (0.6 * len(text) + 2.0)


def words(text, at, size=24, color="white", box="blue", moves=None, **kw):
    """A words sticker, kept whole inside the frame's safe sides and above the caption's band (a projected place near
    an edge is moved in)."""
    half = sticker_width(text, size) / 2.0
    lo, hi = SAFE_X[0] + half + 2, SAFE_X[1] - half - 2
    x = (SAFE_X[0] + SAFE_X[1]) / 2.0 if lo > hi else min(max(float(at[0]), lo), hi)
    y = min(float(at[1]), CAPTION_TOP - size)
    a = {"kind": "words", "text": text, "at": [round(x, 1), round(y, 1)], "size": size, "color": color, "box": box,
        "moves": moves or [pop(0.6)]}
    a.update(kw)
    return a


def pop(at):
    return {"do": "pop", "at": at}


def out(at):
    return {"do": "out", "at": at}


def pulse(at):
    return {"do": "pulse", "at": at}


def slide(at, frm):
    return {"do": "slide", "at": at, "from": list(frm)}


def arrow(frm, to, at, color="white", width=6, bend=0.0, leave=None):
    a = {"kind": "arrow", "from": [round(frm[0]), round(frm[1])], "to": [round(to[0]), round(to[1])], "color": color,
        "width": width, "moves": [{"do": "draw", "at": at}]}
    if bend:
        a["bend"] = bend
    if leave is not None:
        a["moves"].append(out(leave))
    return a


def count(frm, to, at, where, size=34, color="ink", box="yellow", prefix="", suffix="", start=0.5, dur=1.6, decimals=0):
    a = {"kind": "count", "from": frm, "to": to, "at": list(where), "size": size, "color": color, "box": box,
        "moves": [pop(start), {"do": "value", "at": start + 0.3, "dur": dur, "to": to}]}
    if prefix:
        a["prefix"] = prefix
    if suffix:
        a["suffix"] = suffix
    if decimals:
        a["decimals"] = decimals
    return a


def scene(seconds, caption, say, actors=(), sounds=(), background="sky"):
    return {"seconds": seconds, "background": background, "camera": {"zoom": [1.0, 1.0]}, "caption": caption,
        "say": say, "sounds": list(sounds), "actors": list(actors)}


def sound(at, effect):
    return {"at": at, "effect": effect}


def starts(scenes):
    out_, t = [], 0.0
    for s in scenes:
        out_.append(t)
        t += s["seconds"]
    return out_


# --- 3D helpers ---------------------------------------------------------------------------------------------------

def cam(at, pos, look, fov=50, **kw):
    k = {"at": at, "pos": list(pos), "look": list(look), "fov": fov}
    k.update(kw)
    return k


def project(pos, look, fov, point, roll=0.0):
    """Where a 3D point shows on the 360 x 640 stage for a camera at pos looking at look (vertical fov in degrees)."""
    f = [look[i] - pos[i] for i in range(3)]
    n = math.sqrt(sum(v * v for v in f))
    f = [v / n for v in f]
    up = [0.0, 1.0, 0.0] if abs(f[1]) < 0.999 else [0.0, 0.0, 1.0]   # StudioCamera.transform's
    r = [f[1] * up[2] - f[2] * up[1], f[2] * up[0] - f[0] * up[2], f[0] * up[1] - f[1] * up[0]]
    rn = math.sqrt(sum(v * v for v in r))
    r = [v / rn for v in r]
    u = [r[1] * f[2] - r[2] * f[1], r[2] * f[0] - r[0] * f[2], r[0] * f[1] - r[1] * f[0]]
    d = [point[i] - pos[i] for i in range(3)]
    x, y, z = sum(d[i] * r[i] for i in range(3)), sum(d[i] * u[i] for i in range(3)), sum(d[i] * f[i] for i in range(3))
    if roll:   # the picture turned round the view (StudioCamera: basis * Basis(BACK, roll))
        a = math.radians(roll)
        x, y = x * math.cos(a) + y * math.sin(a), -x * math.sin(a) + y * math.cos(a)
    t = math.tan(math.radians(fov) / 2.0)
    sy = y / (z * t)
    sx = x / (z * t * STAGE_W / STAGE_H)
    return (STAGE_W / 2.0 * (1.0 + sx), STAGE_H / 2.0 * (1.0 - sy))


def model(id_, kind, at, **kw):
    m = {"id": id_, "model": kind, "at": list(at)}
    m.update(kw)
    return m


def box(x0, y0, z0, x1, y1, z1, block):
    return {"box": [x0, y0, z0, x1, y1, z1], "block": block}


def disc(x, y, z, r, block):
    return {"disc": [x, y, z, r], "block": block}


def cylinder(x, y, z, r, h, block):
    return {"cylinder": [x, y, z, r, h], "block": block}


def cone(x, y, z, r, h, block):
    return {"cone": [x, y, z, r, h], "block": block}


def ball(x, y, z, r, block):
    return {"ball": [x, y, z, r], "block": block}


def mv(at, to, dur, ease="smooth"):
    return {"do": "move", "at": at, "dur": dur, "to": list(to), "ease": ease}


def turn(at, to, dur, ease="smooth"):
    return {"do": "turn", "at": at, "dur": dur, "to": list(to), "ease": ease}


def short(id_, title, topic, link, still, stage, scenes):
    return {"id": id_, "title": title, "topic": topic, "link": link, "still": still, "stage": stage, "scenes": scenes}
