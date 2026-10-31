#!/usr/bin/env python3
"""Generates Frostpeak's cartoon sounds (M3 Task 3; original work, synthesised here with
tools/make_monster_sounds.py's helpers) into assets/audio/sfx/:

  yeti_roar      a yeti spots you: a big, furry, silly "hrrOOAR"
  bat_screech    an ice bat spots you, and screeches before it dives: a thin, wobbly squeak
  snow_throw     a snowball leaves a yeti's hands (a heave and a whoosh)
  snow_splat     a snowball lands: a soft crunchy "pff"
  giant_roar     the Frost Giant wakes up: a deep, rolling roar
  giant_stomp    its stomp lands: a deep thud and cracking ice
  giant_breath   its icy breath: a long, cold hiss with a whistle in it
  ice_crackle    frost spreading over the ground (the stomp's icy ring, the breath's warning)
  snowstorm      wind for a snowstorm: a whistling, gusty loop (looped by its import)

Run from the project root:  python3 tools/make_frost_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20260925)


def saw(f: np.ndarray) -> np.ndarray:
    return 2 * ((np.cumsum(f) / RATE) % 1) - 1


def yeti_roar() -> np.ndarray:
    """A big furry roar: a rough voice that swells up and falls, with a breathy fur of noise."""
    tt = t(1.0)
    f = 95 + 70 * np.sin(np.pi * np.clip(tt / 1.0, 0, 1)) ** 1.5 + 5 * np.sin(2 * np.pi * 19 * tt)
    rough = lowpass(saw(f) * (0.75 + 0.25 * np.sin(2 * np.pi * 27 * tt)), 5)
    breath = lowpass(RNG.standard_normal(tt.size), 6) * 0.3
    return (rough + breath) * env(tt.size, 0.1, 0.3)


def bat_screech() -> np.ndarray:
    """A thin squeak that wobbles up and down twice."""
    tt = t(0.42)
    f = 1900 + 500 * np.sin(2 * np.pi * 5 * tt) + 600 * tt / 0.42
    squeak = tone(f, (1.0, 0.3, 0.1)) * (0.7 + 0.3 * np.sin(2 * np.pi * 38 * tt))
    return squeak * env(tt.size, 0.02, 0.12)


def snow_throw() -> np.ndarray:
    """A heave (a short grunt) and the whoosh of the snowball."""
    tt = t(0.35)
    grunt = lowpass(saw(np.full(tt.size, 120.0)), 6) * env(tt.size, 0.01, 0.1) * np.clip(1 - tt / 0.12, 0, 1)
    noise = RNG.standard_normal(tt.size)
    whoosh = (noise - lowpass(noise, 5)) * np.sin(np.pi * np.clip(tt / 0.35, 0, 1)) ** 2
    return 0.8 * grunt + 0.6 * whoosh


def snow_splat() -> np.ndarray:
    """A soft crunchy 'pff': snow bursting, with little crunches."""
    tt = t(0.3)
    noise = RNG.standard_normal(tt.size)
    puff = lowpass(noise, 4) * decay(tt.size, 14)
    crunch = np.zeros(tt.size)
    for i in range(6):
        at = int(RATE * (0.01 + i * 0.03))
        crunch[at:at + 60] += RNG.standard_normal(60) * np.linspace(1, 0, 60) * 0.5
    return (puff + crunch) * env(tt.size, 0.002, 0.08)


def giant_roar() -> np.ndarray:
    """A deep, rolling roar: very low, rising and falling, with a rumble under it."""
    tt = t(1.6)
    f = 55 + 45 * np.sin(np.pi * np.clip(tt / 1.6, 0, 1)) + 4 * np.sin(2 * np.pi * 17 * tt)
    rough = lowpass(saw(f) * (0.7 + 0.3 * np.sin(2 * np.pi * 21 * tt)), 7)
    rumble = lowpass(RNG.standard_normal(tt.size), 40) * 2.0
    return (rough + rumble) * env(tt.size, 0.2, 0.5)


def giant_stomp() -> np.ndarray:
    """The stomp lands: a deep thud, then ice cracking."""
    tt = t(0.9)
    thud = tone(70 * np.exp(-tt * 6) + 30, (1.0, 0.6)) * decay(tt.size, 6)
    cracks = np.zeros(tt.size)
    for i in range(8):
        at = int(RATE * (0.08 + i * 0.07 + RNG.random() * 0.03))
        n = 90
        cracks[at:at + n] += (RNG.standard_normal(n) - lowpass(RNG.standard_normal(n), 2)) * np.linspace(1, 0, n) * 0.6
    return thud + cracks


def giant_breath() -> np.ndarray:
    """A long, cold hiss that swells, with a high whistle in it."""
    tt = t(1.5)
    noise = RNG.standard_normal(tt.size)
    hiss = (noise - lowpass(noise, 3)) * 0.8 + lowpass(noise, 8) * 0.4
    whistle = tone(2300 + 200 * np.sin(2 * np.pi * 2 * tt), (1.0,)) * 0.15
    return (hiss + whistle) * np.clip(tt / 0.25, 0, 1) * env(tt.size, 0.05, 0.35)


def ice_crackle() -> np.ndarray:
    """Frost spreading: many tiny, bright crackles."""
    tt = t(0.7)
    out = np.zeros(tt.size)
    for i in range(22):
        at = int(RNG.random() * (tt.size - 200))
        n = 40 + int(RNG.random() * 60)
        tick = RNG.standard_normal(n)
        out[at:at + n] += (tick - lowpass(tick, 2)) * np.linspace(1, 0, n) * (0.3 + 0.5 * RNG.random())
    return out * env(tt.size, 0.01, 0.2)


def snowstorm() -> np.ndarray:
    """Wind for a snowstorm: gusty filtered noise with a soft whistle, made to loop."""
    n = int(RATE * 4.0)
    x = RNG.standard_normal(n + RATE)
    wind = lowpass(x, 18) * 3.0 + (x - lowpass(x, 3)) * 0.2
    tt = np.arange(n + RATE) / RATE
    whistle = tone(np.full(n + RATE, 900.0) + 120 * np.sin(2 * np.pi * 0.5 * tt), (1.0,)) * 0.06
    gust = 0.6 + 0.4 * np.sin(2 * np.pi * np.arange(n + RATE) / (n / 4))
    y = (wind + whistle * gust) * gust
    fade = np.linspace(0, 1, RATE)
    loop = y[:n].copy()
    loop[:RATE] = loop[:RATE] * fade + y[n:n + RATE] * (1 - fade)   # crossfade the tail into the start
    return loop


if __name__ == "__main__":
    for name, fn, peak in [("yeti_roar", yeti_roar, 0.8), ("bat_screech", bat_screech, 0.5),
            ("snow_throw", snow_throw, 0.6), ("snow_splat", snow_splat, 0.6), ("giant_roar", giant_roar, 0.85),
            ("giant_stomp", giant_stomp, 0.85), ("giant_breath", giant_breath, 0.6), ("ice_crackle", ice_crackle, 0.5),
            ("snowstorm", snowstorm, 0.45)]:
        save(name, fn(), peak)
    print("FROST sounds saved to assets/audio/sfx/")
