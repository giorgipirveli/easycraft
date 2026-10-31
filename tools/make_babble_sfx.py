#!/usr/bin/env python3
"""Generates the babble voices' syllables (M3 Task 21a, research F7): short, cute nonsense sounds that buddies,
bot friends, Tilly and the story friends, and pets "talk" in (like Animal Crossing). Original procedural work:
a voice (a pulse train with a small rising or falling pitch) shaped by two vowel formants, after a soft
consonant onset. Never real words: single syllables, and Audio never plays the same take twice in a row.

Writes assets/audio/sfx/babble_1.wav .. babble_12.wav (mono, 22.05 kHz). Every speaker plays them at its own pitch
(BabbleRules: tiny ones squeak, giants rumble).

Run from the project root:  python3 tools/make_babble_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files. Uses the helpers of make_weapon_sfx.py.
"""
import numpy as np

import make_weapon_sfx as sfx
from make_weapon_sfx import bandpass, lowpass, noise, save, t_axis

sfx.RNG = np.random.default_rng(2026092521)

# Vowel formants (Hz), a little higher than an adult's: a child-like, friendly colour.
VOWELS = {"a": (900.0, 1500.0), "e": (600.0, 2300.0), "i": (380.0, 2800.0), "o": (560.0, 1050.0),
          "u": (420.0, 1100.0)}
# The twelve syllables: consonant onset, vowel, pitch start and end (× the base), length (s).
SYLLABLES = [
    ("b", "a", 1.00, 1.10, 0.15), ("b", "i", 1.08, 1.20, 0.12), ("b", "o", 1.00, 0.92, 0.16),
    ("d", "a", 1.04, 1.16, 0.14), ("d", "u", 0.96, 0.90, 0.15), ("m", "i", 1.10, 1.22, 0.13),
    ("m", "o", 0.98, 1.06, 0.17), ("n", "u", 1.02, 0.94, 0.14), ("p", "e", 1.06, 1.18, 0.12),
    ("l", "o", 1.00, 1.12, 0.15), ("w", "a", 0.94, 1.08, 0.17), ("t", "i", 1.12, 1.02, 0.11),
]
BASE = 330.0   # Hz: a small, bright voice before each speaker's own pitch


def voice(f0: float, f1: float, seconds: float) -> np.ndarray:
    """A voiced sound: harmonics of a gliding pitch with a little vibrato."""
    t = t_axis(seconds)
    f = np.linspace(f0, f1, len(t)) * (1.0 + 0.025 * np.sin(2.0 * np.pi * 7.0 * t))
    phase = 2.0 * np.pi * np.cumsum(f) / sfx.RATE
    return sum(np.sin(k * phase) / k ** 1.1 for k in range(1, 12))


def syllable(onset: str, vowel: str, p0: float, p1: float, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    v = voice(BASE * p0, BASE * p1, seconds)
    lo, hi = VOWELS[vowel]
    shaped = bandpass(v, np.full(len(t), lo), 2.5) * 0.7 + bandpass(v, np.full(len(t), hi), 3.0) * 0.45 + v * 0.08
    attack = 0.012
    if onset in "bdpt":                       # a small puff before the vowel
        burst_len = 0.012
        burst = bandpass(noise(burst_len), np.full(int(sfx.RATE * burst_len), 2500.0 if onset in "dt" else 900.0), 1.5)
        shaped[:len(burst)] += burst * (0.5 if onset in "pt" else 0.25)
        attack = 0.02
    elif onset in "mnlw":                     # a humming start, darker and softer
        hum = lowpass(v, 500.0) * np.clip(1.0 - t / 0.05, 0.0, 1.0) * 0.5
        shaped = shaped * np.clip(t / 0.04, 0.0, 1.0) + hum
        attack = 0.03
    env = np.minimum(t / attack, 1.0) * np.minimum((seconds - t) / 0.045, 1.0) ** 1.5
    return shaped * env


def main() -> None:
    for i, (c, v, p0, p1, s) in enumerate(SYLLABLES):
        save(f"babble_{i + 1}", syllable(c, v, p0, p1, s), peak=0.6)
    print(f"wrote {len(SYLLABLES)} babble syllables")


if __name__ == "__main__":
    main()
