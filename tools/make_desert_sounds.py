#!/usr/bin/env python3
"""Generates the Sandstorm Desert's cartoon sounds (M3 Task 2; original work, synthesised here with
tools/make_monster_sounds.py's helpers) into assets/audio/sfx/:

  mummy_moan      a mummy spots you: a wobbly, silly "ooohh"
  scorpion_hiss   a scorpion spots you: a dry hiss with clicking legs
  spit / splat    the poison glob leaves the tail / lands
  serpent_roar    the Sand Serpent rises
  serpent_burst   it bursts out of the sand (a whoosh of sand and a thump)
  serpent_rumble  the warning under the sand before a burst
  dart / trap_click   a pyramid's arrow slit: the click that warns, then the dart's whoosh
  sandstorm       wind for a sandstorm (a seamless loop, looped by its import)

Run from the project root:  python3 tools/make_desert_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20260924)


def moan() -> np.ndarray:
    """A wobbly 'ooohh': a low voice sliding down with a slow wobble and a breathy edge."""
    tt = t(0.9)
    f = 165 - 45 * tt / 0.9 + 9 * np.sin(2 * np.pi * 5.5 * tt)
    voice = lowpass(tone(f, (1.0, 0.7, 0.45, 0.25)), 5)
    breath = lowpass(RNG.standard_normal(tt.size), 12) * 0.25
    return (voice + breath) * env(tt.size, 0.12, 0.3)


def hiss() -> np.ndarray:
    """A dry hiss, then a few quick clicks of little legs."""
    tt = t(0.45)
    noise = RNG.standard_normal(tt.size)
    hissing = (noise - lowpass(noise, 6)) * env(tt.size, 0.03, 0.2)
    clicks = np.zeros(int(RATE * 0.25))
    for i in range(5):
        at = int(RATE * (0.02 + i * 0.045))
        clicks[at:at + 40] += RNG.standard_normal(40) * np.linspace(1, 0, 40) * 0.8
    return np.concatenate([hissing, clicks])


def spit() -> np.ndarray:
    """A wet 'ptoo': a short burst and a rising blip."""
    tt = t(0.16)
    burst = lowpass(RNG.standard_normal(tt.size), 3) * decay(tt.size, 40)
    blip = tone(np.linspace(300, 700, tt.size), (1.0, 0.4)) * env(tt.size, 0.005, 0.08) * 0.6
    return burst + blip


def splat() -> np.ndarray:
    """A squelchy landing: a falling wobble in low noise."""
    tt = t(0.25)
    noise = lowpass(RNG.standard_normal(tt.size), 10) * (0.6 + 0.4 * np.sin(2 * np.pi * 45 * tt))
    body = tone(180 * np.exp(-tt * 6) + 60, (1.0, 0.5)) * 0.5
    return (noise + body) * decay(tt.size, 12) * env(tt.size, 0.003, 0.06)


def serpent_roar() -> np.ndarray:
    """A big, friendly-scary roar: a rough low voice rising and falling, with sand in it."""
    tt = t(1.3)
    f = 70 + 60 * np.sin(np.pi * np.clip(tt / 1.3, 0, 1)) + 6 * np.sin(2 * np.pi * 23 * tt)
    saw = 2 * ((np.cumsum(f) / RATE) % 1) - 1
    rough = lowpass(saw * (0.7 + 0.3 * np.sin(2 * np.pi * 31 * tt)), 6)
    sand = lowpass(RNG.standard_normal(tt.size), 4) * 0.3
    return (rough + sand) * env(tt.size, 0.15, 0.4)


def serpent_burst() -> np.ndarray:
    """Out of the sand: a rushing whoosh of sand and a deep thump."""
    tt = t(1.0)
    noise = RNG.standard_normal(tt.size)
    rush = lowpass(noise, 3) * np.clip(tt / 0.08, 0, 1) * decay(tt.size, 3.5)
    thump = tone(90 * np.exp(-tt * 5) + 35, (1.0, 0.5)) * decay(tt.size, 7)
    return 0.7 * rush + thump


def serpent_rumble() -> np.ndarray:
    """The warning under the sand: a low rumble that swells."""
    tt = t(1.3)
    rumble = lowpass(RNG.standard_normal(tt.size), 60) * 3.0
    hum = tone(48 + 4 * np.sin(2 * np.pi * 3 * tt), (1.0, 0.4)) * 0.5
    return (rumble + hum) * np.clip(tt / 1.1, 0, 1) * env(tt.size, 0.05, 0.15)


def dart() -> np.ndarray:
    """A dart whooshing past: a quick sweep of high noise."""
    tt = t(0.3)
    noise = RNG.standard_normal(tt.size)
    high = noise - lowpass(noise, 3)
    return high * np.sin(np.pi * np.clip(tt / 0.3, 0, 1)) ** 2


def trap_click() -> np.ndarray:
    """A stone clicking into place (the arrow slit warns before it shoots)."""
    tt = t(0.12)
    return (tone(np.full(tt.size, 1400.0), (1.0, 0.5)) * decay(tt.size, 60)
        + lowpass(RNG.standard_normal(tt.size), 2) * decay(tt.size, 90) * 0.8)


def sandstorm() -> np.ndarray:
    """Wind: filtered noise with slow gusts, made to loop (the end fades into the start)."""
    n = int(RATE * 4.0)
    x = RNG.standard_normal(n + RATE)
    wind = lowpass(x, 25) * 3.0 + (x - lowpass(x, 4)) * 0.15
    gust = 0.65 + 0.35 * np.sin(2 * np.pi * np.arange(n + RATE) / (n / 3))
    y = wind * gust
    fade = np.linspace(0, 1, RATE)
    loop = y[:n].copy()
    loop[:RATE] = loop[:RATE] * fade + y[n:n + RATE] * (1 - fade)   # crossfade the tail into the start
    return loop


if __name__ == "__main__":
    for name, fn, peak in [("mummy_moan", moan, 0.75), ("scorpion_hiss", hiss, 0.6), ("spit", spit, 0.7),
            ("splat", splat, 0.7), ("serpent_roar", serpent_roar, 0.8), ("serpent_burst", serpent_burst, 0.85),
            ("serpent_rumble", serpent_rumble, 0.75), ("dart", dart, 0.6), ("trap_click", trap_click, 0.6),
            ("sandstorm", sandstorm, 0.45)]:
        save(name, fn(), peak)
    print("DESERT sounds saved to assets/audio/sfx/")
