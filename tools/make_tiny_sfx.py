#!/usr/bin/env python3
"""Generates the wonder pack's sound effects (M3 Task 21c) as small mono WAVs: original procedural work.

build_note_wood (a soft marimba note, C4: every placed block sings it at its own pitch of the pentatonic scale,
BuildNotes), build_note_bell (a soft celesta bell, C4: glass, crystal, ice and lights), mouse_squeak_1/2 (a mouse
family's happy little squeaks), mimic_hop (a sleepy chest's wooden clop as it hops after you).

Run from the project root:  python3 tools/make_tiny_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files. Uses the helpers of make_weapon_sfx.py and
make_secret_sfx.py; the notes are made at 32 kHz (they are played up to 4.5 times their pitch).
"""
import numpy as np

import make_weapon_sfx as sfx
from make_secret_sfx import place
from make_weapon_sfx import bandpass, decay, lowpass, noise, save, t_axis

sfx.RATE = 32000
sfx.RNG = np.random.default_rng(2026092521)
C4 = 261.63


def marimba(freq: float, seconds: float) -> np.ndarray:
    """A mallet on a wooden bar: the fundamental, its tuned 4th and 10th partials dying fast, a soft knock."""
    t = t_axis(seconds)
    attack = np.minimum(t / 0.004, 1.0)
    body = (np.sin(2.0 * np.pi * freq * t) * decay(seconds, 0.16)
            + 0.35 * np.sin(2.0 * np.pi * freq * 4.0 * t) * decay(seconds, 0.05)
            + 0.12 * np.sin(2.0 * np.pi * freq * 9.9 * t) * decay(seconds, 0.02))
    knock = lowpass(noise(seconds), 1800.0) * decay(seconds, 0.008) * 0.3
    return (body + knock) * attack


def celesta(freq: float, seconds: float) -> np.ndarray:
    """A small, round bell: soft partials, a longer ring."""
    t = t_axis(seconds)
    attack = np.minimum(t / 0.003, 1.0)
    partials = [(1.0, 1.0, 0.35), (2.0, 0.3, 0.2), (3.0, 0.12, 0.12), (4.07, 0.05, 0.08)]
    return attack * sum(a * np.sin(2.0 * np.pi * freq * f * t) * decay(seconds, hl) for f, a, hl in partials)


def squeak(f0: float, f1: float, seconds: float) -> np.ndarray:
    """A mouse's little "eep": a thin rising whistle with a quick wobble."""
    t = t_axis(seconds)
    f = (f0 + (f1 - f0) * (t / seconds) ** 0.7) * (1.0 + 0.03 * np.sin(2.0 * np.pi * 38.0 * t))
    phase = 2.0 * np.pi * np.cumsum(f) / sfx.RATE
    voice = np.sin(phase) + 0.25 * np.sin(2.0 * phase)
    env = np.sin(np.pi * t / seconds) ** 1.5
    return voice * env


def squeaks(pattern: list) -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 0.45))
    for at, f0, f1, s in pattern:
        place(out, squeak(f0, f1, s), at)
    return out


def hop() -> np.ndarray:
    """A small wooden chest landing: a hollow clop, the lid's rattle."""
    seconds = 0.3
    t = t_axis(seconds)
    clop = np.sin(2.0 * np.pi * 170.0 * t) * decay(seconds, 0.03) + 0.5 * np.sin(2.0 * np.pi * 420.0 * t) * decay(seconds, 0.015)
    rattle = bandpass(noise(seconds), np.full(len(t), 2400.0), 3.0) * decay(seconds, 0.02) * 0.4
    out = clop + rattle
    place(out, bandpass(noise(0.06), np.full(int(sfx.RATE * 0.06), 3000.0), 3.0) * decay(0.06, 0.01) * 0.3, 0.07)
    return out


def main() -> None:
    save("build_note_wood", marimba(C4, 0.7), 0.6)
    save("build_note_bell", celesta(C4, 1.1), 0.55)
    save("mouse_squeak_1", squeaks([(0.0, 2600.0, 3300.0, 0.09), (0.12, 2900.0, 3600.0, 0.08)]), 0.45)
    save("mouse_squeak_2", squeaks([(0.0, 3100.0, 2700.0, 0.07), (0.1, 2800.0, 3500.0, 0.1), (0.24, 3200.0, 3900.0, 0.07)]), 0.45)
    save("mimic_hop", hop(), 0.6)


if __name__ == "__main__":
    main()
