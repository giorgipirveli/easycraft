#!/usr/bin/env python3
"""Generates the Dragon Realm monsters' cartoon sounds (owner feedback #39; original work, synthesised here with
tools/make_monster_sounds.py's helpers) into assets/audio/sfx/:

  shadow_squeak   a shadow bat spots you, and squeaks as its wings flare before a swoop: a soft, round "peep-eep"
  shadow_flutter  a shadow bat flying about: a few soft wing flaps
  shadow_hurt     a shadow bat is hit: a small, surprised "eep!"
  wisp_chime      a wisp spots you: two bright bell notes
  wisp_charge     a wisp winds up its spark: a hum that rises and shimmers (as long as its signal, 1.2 s)
  wisp_hum        a wisp drifting about: a soft, warm hum with a twinkle
  wisp_hurt       a wisp is hit: a falling tinkle
  spark_pop       a wisp's spark bursts (on a wall, a child or at the end of its flight): a soft crackly pop

Run from the project root:  python3 tools/make_dragon_monster_sounds.py   (needs numpy)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_monster_sounds import RATE, decay, env, lowpass, save, t, tone  # noqa: E402

RNG = np.random.default_rng(20260939)


def bell(freq: float, seconds: float, rate: float = 6.0) -> np.ndarray:
    """A soft bell: a sine with a few inharmonic partials, dying away."""
    tt = t(seconds)
    partials = [(1.0, 1.0), (2.76, 0.35), (5.4, 0.12)]
    x = sum(a * np.sin(2 * np.pi * freq * k * tt) for k, a in partials)
    return x * decay(tt.size, rate)


def shadow_squeak() -> np.ndarray:
    """A soft, round double squeak (lower and rounder than the ice bat's thin screech)."""
    out = []
    for f0, length in [(1150.0, 0.12), (1450.0, 0.16)]:
        tt = t(length)
        f = f0 + 250 * np.sin(np.pi * tt / length)
        out.append(tone(f, (1.0, 0.2)) * env(tt.size, 0.01, 0.05))
        out.append(np.zeros(int(RATE * 0.04)))
    return np.concatenate(out)


def shadow_flutter() -> np.ndarray:
    """A few soft wing flaps: short, low puffs of noise."""
    tt = t(0.5)
    out = np.zeros(tt.size)
    for i in range(4):
        at = int(RATE * (0.02 + i * 0.11))
        n = int(RATE * 0.07)
        puff = lowpass(RNG.standard_normal(n), 12) * np.sin(np.linspace(0, np.pi, n)) ** 2
        out[at:at + n] += puff * (1.0 - 0.15 * i)
    return out


def shadow_hurt() -> np.ndarray:
    """A small, surprised 'eep!' that jumps up."""
    tt = t(0.22)
    f = 900 + 900 * np.clip(tt / 0.06, 0, 1) - 300 * np.clip((tt - 0.1) / 0.12, 0, 1)
    return tone(f, (1.0, 0.3, 0.1)) * env(tt.size, 0.005, 0.08)


def wisp_chime() -> np.ndarray:
    """Two bright bell notes, up a fifth."""
    a = bell(1320.0, 0.6, 5.0)
    b = bell(1980.0, 0.7, 4.5)
    out = np.zeros(int(RATE * 0.85))
    out[:a.size] += a
    at = int(RATE * 0.14)
    out[at:at + b.size] += b[: out.size - at]
    return out * env(out.size, 0.004, 0.2)


def wisp_charge() -> np.ndarray:
    """A hum that rises for its whole 1.2 s signal, with a shimmer that quickens, ending on a bright note."""
    tt = t(1.2)
    f = 330 + 330 * (tt / 1.2) ** 1.5
    hum = tone(f, (1.0, 0.5, 0.25)) * (0.4 + 0.6 * tt / 1.2)
    shimmer_rate = 6 + 18 * tt / 1.2
    shimmer = 0.75 + 0.25 * np.sin(2 * np.pi * np.cumsum(shimmer_rate) / RATE)
    sparkle = np.sin(2 * np.pi * 2640 * tt) * 0.15 * (tt / 1.2) ** 2
    return (hum * shimmer + sparkle) * env(tt.size, 0.05, 0.06)


def wisp_hum() -> np.ndarray:
    """A soft, warm hum that swells and fades, with one twinkle."""
    tt = t(0.9)
    hum = tone(np.full(tt.size, 262.0) + 6 * np.sin(2 * np.pi * 3 * tt), (1.0, 0.4, 0.15))
    swell = np.sin(np.pi * tt / 0.9) ** 2
    tw = np.zeros(tt.size)
    b = bell(2093.0, 0.4, 8.0) * 0.25
    at = int(RATE * 0.35)
    tw[at:at + b.size] += b[: tt.size - at]
    return hum * swell * 0.7 + tw


def wisp_hurt() -> np.ndarray:
    """A falling tinkle: three bell notes going down."""
    out = np.zeros(int(RATE * 0.6))
    for i, f in enumerate([1760.0, 1397.0, 1047.0]):
        b = bell(f, 0.35, 9.0)
        at = int(RATE * i * 0.08)
        out[at:at + b.size] += b[: out.size - at]
    return out * env(out.size, 0.003, 0.15)


def spark_pop() -> np.ndarray:
    """A soft pop with little crackles after it."""
    tt = t(0.35)
    pop = tone(np.full(tt.size, 520.0) * np.exp(-tt * 8), (1.0, 0.4)) * decay(tt.size, 22)
    crackle = np.zeros(tt.size)
    for i in range(9):
        at = int(RATE * (0.02 + RNG.random() * 0.25))
        n = 50
        tick = RNG.standard_normal(n)
        crackle[at:at + n] += (tick - lowpass(tick, 2)) * np.linspace(1, 0, n) * 0.4
    return pop + crackle


if __name__ == "__main__":
    for name, fn, peak in [("shadow_squeak", shadow_squeak, 0.5), ("shadow_flutter", shadow_flutter, 0.45),
            ("shadow_hurt", shadow_hurt, 0.5), ("wisp_chime", wisp_chime, 0.45), ("wisp_charge", wisp_charge, 0.5),
            ("wisp_hum", wisp_hum, 0.4), ("wisp_hurt", wisp_hurt, 0.45), ("spark_pop", spark_pop, 0.55)]:
        save(name, fn(), peak)
    print("DRAGON monster sounds saved to assets/audio/sfx/")
