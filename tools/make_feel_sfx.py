#!/usr/bin/env python3
"""Generates the game-feel sound effects (M2 Task 11) as small mono WAVs: original procedural work.

coin (a coin pickup: two quick bright bell notes, B5 then E6, the classic "bling").

Run from the project root:  python3 tools/make_feel_sfx.py   (needs numpy)
Deterministic (no randomness), so re-running gives identical files.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def bell(freq: float, seconds: float, half_life: float) -> np.ndarray:
    """A small bright bell: the note, its octave and a quiet twelfth, the overtones dying faster."""
    t = t_axis(seconds)
    body = np.sin(2 * np.pi * freq * t) * 0.5 ** (t / half_life)
    octave = 0.35 * np.sin(2 * np.pi * 2 * freq * t) * 0.5 ** (t / (half_life * 0.5))
    twelfth = 0.12 * np.sin(2 * np.pi * 3 * freq * t) * 0.5 ** (t / (half_life * 0.3))
    attack = np.minimum(t / 0.002, 1.0)          # 2 ms, no click
    return (body + octave + twelfth) * attack


def coin() -> np.ndarray:
    seconds = 0.5
    out = np.zeros(int(RATE * seconds))
    first = bell(987.77, 0.12, 0.03)              # B5, short
    second = bell(1318.51, seconds - 0.07, 0.09)  # E6, rings
    out[:len(first)] += first * 0.8
    start = int(RATE * 0.07)
    out[start:start + len(second)] += second
    return out


def fade(x: np.ndarray, ms: float = 4.0) -> np.ndarray:
    n = min(int(RATE * ms / 1000.0), len(x) // 2)
    x = x.copy()
    x[-n:] *= np.linspace(1.0, 0.0, n)
    return x


def save(name: str, x: np.ndarray, peak: float = 0.6) -> None:
    x = fade(x)
    x = x / max(np.max(np.abs(x)), 1e-9) * peak
    data = (x * 32767.0).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("SFX", name, f"{len(x) / RATE:.2f}s")


if __name__ == "__main__":
    save("coin", coin())
