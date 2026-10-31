#!/usr/bin/env python3
"""Generates the Candy Kingdom's cartoon sounds (M3 Task 4; original work, synthesised here with
tools/make_monster_sounds.py's helpers) into assets/audio/sfx/:

  gummy_squeak    a gummy bear spots you, or bounces off a wall: a rubbery boing-squeak
  sneaker_jingle  a candy sneaker winds up its lollipop (the fair warning): a quick sparkly tinkle
  cake_roar       the Cake Monster rises: a jolly, wobbly "hoo-hoo-HOO"
  cake_slam       its frosting wave: a big squelchy thump
  cake_throw      a cherry leaves the cake: a cork-like pop
  cherry_splat    a cherry lands: a juicy splat
  layer_pop       a tier falls off: a big pop and crumbs
  fanfare         the last boss beaten: a short bright fanfare (four rising notes and a chord)

Run from the project root:  python3 tools/make_candy_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20260925)


def bell(freq: float, seconds: float, bright: float = 1.0) -> np.ndarray:
    """A small bell or celesta note: a few inharmonic partials that ring down."""
    tt = t(seconds)
    partials = [(1.0, 1.0, 5.0), (2.76, 0.45 * bright, 9.0), (5.4, 0.25 * bright, 14.0), (8.93, 0.12 * bright, 20.0)]
    x = np.zeros(tt.size)
    for ratio, amp, rate in partials:
        x += amp * np.sin(2 * np.pi * freq * ratio * tt) * np.exp(-tt * rate)
    return x * env(tt.size, 0.002, 0.05)


def gummy_squeak() -> np.ndarray:
    """A rubbery boing that squeaks up at the end."""
    tt = t(0.32)
    f = 260 + 240 * np.sin(np.pi * np.clip(tt / 0.32, 0, 1)) ** 2 + 30 * np.sin(2 * np.pi * 18 * tt)
    return tone(f, (1.0, 0.35, 0.15)) * env(tt.size, 0.01, 0.1) * (0.7 + 0.3 * np.sin(2 * np.pi * 9 * tt))


def sneaker_jingle() -> np.ndarray:
    """Four quick sparkly notes going up (E6 G6 B6 E7) over a soft shimmer: a sneaker is about to swing."""
    out = np.zeros(int(RATE * 0.7))
    for i, f in enumerate([1318.5, 1568.0, 1975.5, 2637.0]):
        note = bell(f, 0.4, 0.7)
        at = int(RATE * i * 0.07)
        out[at:at + note.size] += note[:out.size - at]
    shimmer = RNG.standard_normal(out.size)
    shimmer = (shimmer - lowpass(shimmer, 2)) * 0.06 * env(out.size, 0.05, 0.3)
    return out + shimmer


def cake_roar() -> np.ndarray:
    """A jolly, wobbly 'hoo-hoo-HOO': three swelling low voices, the last one higher."""
    out = np.zeros(int(RATE * 1.3))
    for i, (f0, dur) in enumerate([(110, 0.28), (118, 0.28), (150, 0.55)]):
        tt = t(dur)
        f = f0 + 12 * np.sin(2 * np.pi * 6 * tt)
        voice = lowpass(tone(f, (1.0, 0.8, 0.5, 0.3)), 4) * env(tt.size, 0.05, 0.12)
        at = int(RATE * (i * 0.32))
        out[at:at + voice.size] += voice[:out.size - at]
    return out


def cake_slam() -> np.ndarray:
    """A big squelchy thump: a deep drop in pitch and a wet, wobbly burst."""
    tt = t(0.7)
    thump = tone(110 * np.exp(-tt * 6) + 40, (1.0, 0.5)) * decay(tt.size, 5)
    squelch = lowpass(RNG.standard_normal(tt.size), 8) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * tt)) * decay(tt.size, 7)
    return thump + 0.6 * squelch


def cake_throw() -> np.ndarray:
    """A cork-like pop and a short rising whistle."""
    tt = t(0.3)
    pop = lowpass(RNG.standard_normal(tt.size), 2) * decay(tt.size, 60)
    whistle = tone(np.linspace(500, 1100, tt.size), (1.0, 0.3)) * env(tt.size, 0.01, 0.15) * 0.4
    return pop + whistle


def cherry_splat() -> np.ndarray:
    """A juicy landing: a wet burst with a falling wobble."""
    tt = t(0.3)
    noise = lowpass(RNG.standard_normal(tt.size), 6) * (0.6 + 0.4 * np.sin(2 * np.pi * 55 * tt))
    body = tone(220 * np.exp(-tt * 8) + 70, (1.0, 0.5)) * 0.5
    return (noise + body) * decay(tt.size, 10) * env(tt.size, 0.002, 0.06)


def layer_pop() -> np.ndarray:
    """A tier falls off: a big hollow pop, then crumbs pattering down."""
    tt = t(1.0)
    pop = tone(170 * np.exp(-tt * 9) + 60, (1.0, 0.6, 0.3)) * decay(tt.size, 9)
    crumbs = np.zeros(tt.size)
    for i in range(18):
        at = int(RATE * (0.12 + RNG.random() * 0.7))
        n = int(RATE * 0.02)
        crumbs[at:at + n] += lowpass(RNG.standard_normal(n), 2)[:max(0, min(n, tt.size - at))] * np.linspace(0.5, 0, n)[:max(0, min(n, tt.size - at))]
    return pop + 0.6 * crumbs


def fanfare() -> np.ndarray:
    """A short bright fanfare: G5 C6 E6 G6, then a C major chord that rings."""
    out = np.zeros(int(RATE * 2.2))
    for i, f in enumerate([784.0, 1046.5, 1318.5, 1568.0]):
        note = bell(f, 0.5)
        at = int(RATE * i * 0.14)
        out[at:at + note.size] += note[:out.size - at]
    chord = sum(bell(f, 1.6, 0.8) for f in [523.25, 659.25, 783.99, 1046.5]) * 0.6
    at = int(RATE * 0.6)
    out[at:at + chord.size] += chord[:out.size - at]
    return out


if __name__ == "__main__":
    for name, fn, peak in [("gummy_squeak", gummy_squeak, 0.6), ("sneaker_jingle", sneaker_jingle, 0.55),
            ("cake_roar", cake_roar, 0.8), ("cake_slam", cake_slam, 0.85), ("cake_throw", cake_throw, 0.6),
            ("cherry_splat", cherry_splat, 0.7), ("layer_pop", layer_pop, 0.8), ("fanfare", fanfare, 0.7)]:
        save(name, fn(), peak)
    print("CANDY sounds saved to assets/audio/sfx/")
