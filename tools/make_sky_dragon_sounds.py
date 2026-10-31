#!/usr/bin/env python3
"""Generates the Sky Dragon's sounds (owner feedback #39; original work, synthesised here with
tools/make_monster_sounds.py's helpers) into assets/audio/sfx/:

  sky_dragon_roar      it arrives, and it winds up a dive: a big, friendly-fierce rumbling roar that rises and falls
  sky_dragon_wings     a wing beat: a soft, deep whoomp of air
  sky_dragon_dive      it swoops along its line: a rushing whoosh that sweeps up and past
  sky_crystal_hum      crystal towers rise: a shimmering glassy chord that swells
  sky_crystal_shatter  a crystal tower breaks (and, quieter, a hit on one; the dragon beaten): bright glassy shards

Run from the project root:  python3 tools/make_sky_dragon_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20260939)


def glass(freq: float, seconds: float, bright: float = 1.0) -> np.ndarray:
    """A struck glass or crystal: inharmonic partials that ring down, the high ones faster."""
    tt = t(seconds)
    partials = [(1.0, 1.0, 3.0), (2.32, 0.55 * bright, 6.0), (4.25, 0.35 * bright, 10.0), (6.63, 0.2 * bright, 16.0)]
    x = np.zeros(tt.size)
    for ratio, amp, rate in partials:
        x += amp * np.sin(2 * np.pi * freq * ratio * tt) * np.exp(-tt * rate)
    return x * env(tt.size, 0.002, 0.05)


def noise(n: int) -> np.ndarray:
    return RNG.standard_normal(n)


def roar() -> np.ndarray:
    """A rumbling roar: a low voice with a growl (amplitude wobble), rising then falling, with breathy noise."""
    tt = t(1.5)
    k = tt / tt[-1]
    f = 85 + 70 * np.sin(np.pi * np.clip(k * 1.1, 0, 1)) ** 1.5 + 6 * np.sin(2 * np.pi * 5 * tt)
    voice = tone(f, (1.0, 0.8, 0.6, 0.45, 0.3, 0.2))
    growl = 0.65 + 0.35 * np.sin(2 * np.pi * 28 * tt)
    breath = lowpass(noise(tt.size), 6) * 0.5
    shape = env(tt.size, 0.12, 0.45) * (0.6 + 0.4 * np.sin(np.pi * np.clip(k * 1.2, 0, 1)))
    return lowpass(voice * growl + breath, 3) * shape


def wings() -> np.ndarray:
    """One wing beat: a soft thump of air, low-passed noise with a quick swell."""
    tt = t(0.45)
    air = lowpass(noise(tt.size), 30) * 3.0
    thump = tone(70 * np.exp(-tt * 5) + 35, (1.0, 0.3)) * 0.4
    return (air + thump) * env(tt.size, 0.06, 0.25) * decay(tt.size, 4)


def dive() -> np.ndarray:
    """A rushing whoosh: noise through a sweeping band (low to high and back), loudest as it passes."""
    tt = t(1.3)
    k = tt / tt[-1]
    n = noise(tt.size)
    out = np.zeros(tt.size)
    # a crude sweeping band: blend two low-passes whose difference follows the sweep
    wide = lowpass(n, 3)
    narrow = lowpass(n, 18)
    sweep = np.sin(np.pi * k) ** 2
    out = narrow * (1 - sweep) + (wide - narrow) * sweep * 1.4
    whistle = tone(300 + 500 * np.sin(np.pi * k), (1.0,)) * 0.08 * sweep
    return (out + whistle) * env(tt.size, 0.15, 0.3) * (0.3 + 0.7 * sweep)


def crystal_hum() -> np.ndarray:
    """Crystal towers rising: a glassy chord (E5 G#5 B5 E6) that swells with a slow shimmer."""
    tt = t(2.0)
    k = tt / tt[-1]
    x = np.zeros(tt.size)
    for f in [659.25, 830.61, 987.77, 1318.5]:
        x += np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.01 * tt)
    shimmer = 0.75 + 0.25 * np.sin(2 * np.pi * 6 * tt)
    rumble = lowpass(noise(tt.size), 40) * 2.0 * np.exp(-tt * 3)
    return (x * shimmer * np.sin(np.pi * np.clip(k * 1.15, 0, 1)) ** 1.2 + rumble) * env(tt.size, 0.05, 0.4)


def crystal_shatter() -> np.ndarray:
    """A crystal breaks: a bright crack, then a shower of little glassy shards tinkling down."""
    out = np.zeros(int(RATE * 1.2))
    crack = (noise(int(RATE * 0.08)) - lowpass(noise(int(RATE * 0.08)), 3)) * decay(int(RATE * 0.08), 40)
    out[:crack.size] += crack * 1.2
    body = glass(1244.5, 0.9, 1.0)
    out[:body.size] += body * 0.8
    for i in range(16):
        at = int(RATE * (0.03 + RNG.random() * 0.8))
        shard = glass(1800 + RNG.random() * 2600, 0.25, 0.8) * (0.25 + 0.3 * RNG.random())
        end = min(out.size, at + shard.size)
        out[at:end] += shard[:end - at]
    return out


if __name__ == "__main__":
    for name, fn, peak in [("sky_dragon_roar", roar, 0.85), ("sky_dragon_wings", wings, 0.6),
            ("sky_dragon_dive", dive, 0.75), ("sky_crystal_hum", crystal_hum, 0.6),
            ("sky_crystal_shatter", crystal_shatter, 0.75)]:
        save(name, fn(), peak)
    print("SKY DRAGON sounds saved to assets/audio/sfx/")
