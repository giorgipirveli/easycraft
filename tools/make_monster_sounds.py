#!/usr/bin/env python3
"""Generates the cartoon monster sounds (M2 Task 4; original work, synthesised here) into
assets/audio/sfx/: monster_squish (a slime hops or touches), monster_growl (a goblin spots you),
monster_pop (a defeat: confetti) and monster_poof (monsters puff away at sunrise). The coin sound is
tools/make_feel_sfx.py's (M2 Task 11).

Run from the project root:  python3 tools/make_monster_sounds.py   (needs numpy)
"""
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx/{}.wav"
RNG = np.random.default_rng(20260925)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def env(n: int, attack: float = 0.01, release: float = 0.08) -> np.ndarray:
    e = np.ones(n)
    a = max(int(RATE * attack), 1)
    r = max(int(RATE * release), 1)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def decay(n: int, rate: float) -> np.ndarray:
    return np.exp(-np.arange(n) / RATE * rate)


def tone(freqs: np.ndarray, harmonics=(1.0, 0.5, 0.25)) -> np.ndarray:
    """A voice following a frequency curve (Hz per sample), with a few harmonics."""
    phase = 2 * np.pi * np.cumsum(freqs) / RATE
    return sum(a * np.sin((i + 1) * phase) for i, a in enumerate(harmonics))


def lowpass(x: np.ndarray, k: int) -> np.ndarray:
    return np.convolve(x, np.ones(k) / k, mode="same")


def save(name: str, x: np.ndarray, peak: float = 0.8) -> None:
    x = x / max(np.max(np.abs(x)), 1e-6) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(OUT.format(name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def squish() -> np.ndarray:
    """A wet, bouncy 'blop': a falling tone with a little bubbly noise."""
    tt = t(0.2)
    f = 260 * np.exp(-tt * 9) + 90
    body = tone(f, (1.0, 0.35))
    bubbles = lowpass(RNG.standard_normal(tt.size), 18) * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * tt))
    return (body + 0.35 * bubbles) * env(tt.size, 0.004, 0.09)


def growl() -> np.ndarray:
    """A silly goblin 'grr-heh': a rough low buzz, then two short 'heh's."""
    tt = t(0.32)
    saw = 2 * ((np.cumsum(np.full(tt.size, 105.0) + 12 * np.sin(2 * np.pi * 27 * tt)) / RATE) % 1) - 1
    grr = lowpass(saw * (0.6 + 0.4 * np.sin(2 * np.pi * 31 * tt)), 7) * env(tt.size, 0.03, 0.08)
    parts = [grr, np.zeros(int(RATE * 0.04))]
    for i in range(2):
        th = t(0.09)
        heh = tone(np.linspace(320, 260, th.size), (1.0, 0.6, 0.3)) + 0.4 * lowpass(RNG.standard_normal(th.size), 4)
        parts += [heh * env(th.size, 0.005, 0.05), np.zeros(int(RATE * 0.05))]
    return np.concatenate(parts)


def pop() -> np.ndarray:
    """A cheerful pop with a sparkle: a quick falling 'pop' and two little chimes."""
    tp = t(0.08)
    popped = tone(np.linspace(900, 260, tp.size), (1.0, 0.3)) * decay(tp.size, 45)
    click = np.zeros(tp.size)
    click[:60] = RNG.standard_normal(60) * np.linspace(1, 0, 60)
    parts = [popped + 0.6 * click]
    for f in (1568.0, 2093.0):   # G6, C7
        tc = t(0.14)
        parts.append(tone(np.full(tc.size, f), (1.0, 0.3)) * decay(tc.size, 22) * 0.45)
    return np.concatenate(parts)


def poof() -> np.ndarray:
    """A soft puff of smoke: filtered noise that swells and fades."""
    tt = t(0.4)
    noise = lowpass(RNG.standard_normal(tt.size), 30)
    shape = np.sin(np.pi * np.clip(tt / 0.4, 0, 1)) ** 1.5
    return noise * shape * env(tt.size, 0.02, 0.12)


if __name__ == "__main__":
    for name, fn in [("monster_squish", squish), ("monster_growl", growl), ("monster_pop", pop),
                     ("monster_poof", poof)]:
        save(name, fn(), 0.6 if name == "monster_poof" else 0.8)
    print("MONSTER sounds saved to assets/audio/sfx/monster_*.wav (coin.wav is make_feel_sfx.py's)")
