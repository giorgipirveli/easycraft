#!/usr/bin/env python3
"""Generates photo mode's shutter sound (M3 Task 16) as a small mono WAV: original procedural work.

shutter: two quick mechanical clicks (filtered noise bursts over a short low knock), like a toy
camera's "click-clack".

Run from the project root:  python3 tools/make_photo_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives an identical file.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(20260916)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def decay(seconds: float, half_life: float) -> np.ndarray:
    return 0.5 ** (t_axis(seconds) / half_life)


def highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    a = np.exp(-2.0 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    low = 0.0
    for i, v in enumerate(x):
        low = (1.0 - a) * v + a * low
        y[i] = v - low
    return y


def click(seconds: float, cutoff: float, knock_hz: float) -> np.ndarray:
    snap = highpass(RNG.uniform(-1.0, 1.0, int(RATE * seconds)), cutoff) * decay(seconds, 0.004)
    knock = np.sin(2.0 * np.pi * knock_hz * t_axis(seconds)) * decay(seconds, 0.012)
    return snap + knock * 0.6


def shutter() -> np.ndarray:
    out = np.zeros(int(RATE * 0.22))
    first = click(0.06, 2500.0, 420.0)
    second = click(0.08, 1800.0, 300.0) * 0.8
    out[: len(first)] += first
    start = int(RATE * 0.085)
    out[start : start + len(second)] += second
    return out


def fade(x: np.ndarray, ms: float = 3.0) -> np.ndarray:
    n = min(int(RATE * ms / 1000.0), len(x) // 2)
    x = x.copy()
    x[:n] *= np.linspace(0.0, 1.0, n)
    x[-n:] *= np.linspace(1.0, 0.0, n)
    return x


def save(name: str, x: np.ndarray, peak: float = 0.7) -> None:
    x = fade(x)
    x = x / max(np.max(np.abs(x)), 1e-9) * peak
    data = (x * 32767.0).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("SFX", name, f"{len(x) / RATE:.2f}s")


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    save("shutter", shutter())


if __name__ == "__main__":
    main()
