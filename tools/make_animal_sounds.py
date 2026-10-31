#!/usr/bin/env python3
"""Generates the fish's blub (original work, synthesised here) into assets/audio/sfx/animal_blub.wav.

The other animals' cartoon voices below (bark, meow, oink, moo, baa, cluck, squeak) are no longer used:
the audio pass (owner, 2026-09-24: "animals should have sounds, like real ones") replaced them with real
CC0 recordings (tools/make_audio_pass_sfx.py, `animals`). They stay here for reference; `--all` writes them.

Run from the project root:  python3 tools/make_animal_sounds.py   (needs numpy)
"""
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx/animal_{}.wav"
RNG = np.random.default_rng(20260924)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def env(n: int, attack: float = 0.02, release: float = 0.1) -> np.ndarray:
    e = np.ones(n)
    a = max(int(RATE * attack), 1)
    r = max(int(RATE * release), 1)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def tone(freqs: np.ndarray, harmonics=(1.0, 0.5, 0.25)) -> np.ndarray:
    """A voice following a frequency curve (Hz per sample), with a few harmonics."""
    phase = 2 * np.pi * np.cumsum(freqs) / RATE
    return sum(a * np.sin((i + 1) * phase) for i, a in enumerate(harmonics))


def lowpass(x: np.ndarray, k: int) -> np.ndarray:
    return np.convolve(x, np.ones(k) / k, mode="same")


def save(name: str, x: np.ndarray) -> None:
    x = x / max(np.max(np.abs(x)), 1e-6) * 0.8
    data = (x * 32767).astype(np.int16)
    with wave.open(OUT.format(name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def bark() -> np.ndarray:
    parts = []
    for i in range(2):
        tt = t(0.14)
        f = np.linspace(520, 260, tt.size)
        v = tone(f, (1.0, 0.7, 0.4, 0.2)) + 0.6 * lowpass(RNG.standard_normal(tt.size), 6)
        parts += [v * env(tt.size, 0.005, 0.06), np.zeros(int(RATE * 0.08))]
    return np.concatenate(parts)


def meow() -> np.ndarray:
    tt = t(0.62)
    f = 520 + 330 * np.sin(np.pi * tt / tt[-1]) ** 1.5 + 12 * np.sin(2 * np.pi * 6 * tt)
    return tone(f, (1.0, 0.6, 0.3, 0.15)) * env(tt.size, 0.05, 0.2)


def oink() -> np.ndarray:
    parts = []
    for i in range(2):
        tt = t(0.16)
        saw = 2 * ((170 * tt) % 1) - 1
        v = lowpass(saw * (0.6 + 0.4 * np.sin(2 * np.pi * 28 * tt)), 5)
        parts += [v * env(tt.size, 0.01, 0.05), np.zeros(int(RATE * 0.05))]
    return np.concatenate(parts)


def moo() -> np.ndarray:
    tt = t(1.0)
    f = 118 - 22 * tt / tt[-1]
    saw = 2 * ((np.cumsum(f) / RATE) % 1) - 1
    return lowpass(saw, 14) * env(tt.size, 0.15, 0.35)


def baa() -> np.ndarray:
    tt = t(0.7)
    f = 330 + 20 * np.sin(2 * np.pi * 9 * tt)
    return tone(f, (1.0, 0.8, 0.5, 0.3)) * (0.7 + 0.3 * np.sin(2 * np.pi * 9 * tt)) * env(tt.size, 0.04, 0.25)


def cluck() -> np.ndarray:
    parts = []
    for i in range(3):
        tt = t(0.06)
        v = tone(np.linspace(900, 600, tt.size), (1.0, 0.4)) + 0.3 * RNG.standard_normal(tt.size)
        parts += [v * env(tt.size, 0.003, 0.03), np.zeros(int(RATE * 0.07))]
    return np.concatenate(parts)


def squeak() -> np.ndarray:
    tt = t(0.13)
    return tone(np.linspace(1500, 2300, tt.size), (1.0, 0.2)) * env(tt.size, 0.01, 0.05)


def blub() -> np.ndarray:
    parts = []
    for i in range(2):
        tt = t(0.09)
        parts += [np.sin(2 * np.pi * np.cumsum(np.linspace(280, 850, tt.size)) / RATE) * env(tt.size, 0.005, 0.04),
                  np.zeros(int(RATE * 0.06))]
    return np.concatenate(parts)


if __name__ == "__main__":
    import sys
    voices = [("blub", blub)]
    if "--all" in sys.argv:
        voices = [("bark", bark), ("meow", meow), ("oink", oink), ("moo", moo), ("baa", baa),
                  ("cluck", cluck), ("squeak", squeak)] + voices
    for name, fn in voices:
        save(name, fn())
    print("ANIMAL sounds saved to assets/audio/sfx/animal_*.wav")
