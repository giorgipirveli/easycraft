#!/usr/bin/env python3
"""Generates the treasure pack's sound effects (owner feedback #42) as small mono WAVs: original procedural work.

giggle (a friendly ghost's "hee-hee-hee": three breathy, rising little voices with a wobble), coin_toss (a coin
spins through the air and plops into a well's water, with a small sparkle) and rainbow (a soft rising harp
glissando over a shimmer, when a rainbow appears).

Run from the project root:  python3 tools/make_treasure_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files. Uses the helpers of make_weapon_sfx.py and the
bell of make_secret_sfx.py.
"""
import numpy as np

import make_weapon_sfx as sfx
from make_secret_sfx import bell, place
from make_weapon_sfx import bandpass, decay, lowpass, noise, save, sweep, t_axis

sfx.RNG = np.random.default_rng(2026092442)


def hee(f0: float, seconds: float) -> np.ndarray:
    """One breathy "hee": a vowel-like voice (a few harmonics shaped by an 'ee' formant) with a quick wobble."""
    t = t_axis(seconds)
    wobble = 1.0 + 0.04 * np.sin(2.0 * np.pi * 9.0 * t)
    f = f0 * np.linspace(1.0, 1.18, len(t)) * wobble
    phase = 2.0 * np.pi * np.cumsum(f) / sfx.RATE
    voice = sum(a * np.sin(k * phase) for k, a in [(1, 1.0), (2, 0.5), (3, 0.3), (4, 0.18), (5, 0.1)])
    voice = bandpass(voice, np.full(len(t), 2600.0), 1.2) * 0.6 + voice * 0.4       # the "ee"
    breath = bandpass(noise(seconds), np.full(len(t), 3200.0), 1.5) * 0.25
    env = np.minimum(t / 0.015, 1.0) * decay(seconds, 0.07)
    return (voice + breath) * env


def giggle() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 0.75))
    for k, f in enumerate([620.0, 700.0, 780.0]):
        place(out, hee(f, 0.16), 0.02 + 0.17 * k)
    return out


def coin_toss() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 0.9))
    for k in range(5):                                        # the coin spinning up
        place(out, bell(2600.0 + 180.0 * k, 0.12, 0.03) * (0.35 - 0.05 * k), 0.035 * k)
    seconds = 0.35
    plop = sweep(900.0, 260.0, seconds) * decay(seconds, 0.05)                    # into the water
    splash = lowpass(noise(seconds), 2200.0) * decay(seconds, 0.06) * 0.8
    place(out, plop + splash, 0.32)
    for k, f in enumerate([1568.0, 2093.0]):                   # a wish's sparkle
        place(out, bell(f, 0.4, 0.12) * 0.35, 0.5 + 0.07 * k)
    return out


def rainbow() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.8))
    notes = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.5]    # a C major pentatonic run
    for k, f in enumerate(notes):
        place(out, bell(f, 1.0, 0.3) * (0.55 + 0.04 * k), 0.08 * k)
    shimmer = bandpass(noise(1.8), np.full(int(sfx.RATE * 1.8), 6000.0), 2.0) * decay(1.8, 0.5) * 0.15
    return out + shimmer


def main() -> None:
    save("giggle", giggle(), 0.5)
    save("coin_toss", coin_toss(), 0.55)
    save("rainbow", rainbow(), 0.5)


if __name__ == "__main__":
    main()
