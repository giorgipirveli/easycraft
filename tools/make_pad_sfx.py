#!/usr/bin/env python3
"""Generates the Physics Lab pad sounds (M3 Task 6) as small mono WAVs: original procedural work.

boing:  a jump pad's spring: a tone that bends up fast with a wobble (the spring shaking) and rings
        out, over a soft thump.
whoosh: a speed pad's rush: noise through a sweeping band-pass filter that rises and falls.

Run from the project root:  python3 tools/make_pad_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(20260924)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def decay(seconds: float, half_life: float) -> np.ndarray:
    return 0.5 ** (t_axis(seconds) / half_life)


def boing() -> np.ndarray:
    seconds = 0.55
    t = t_axis(seconds)
    # pitch: 170 Hz bending up to 460 Hz within 0.12 s, with a fading 17 Hz wobble
    bend = 170.0 + 290.0 * (1.0 - np.exp(-t / 0.045))
    wobble = 1.0 + 0.09 * np.sin(2.0 * np.pi * 17.0 * t) * np.exp(-t / 0.25)
    phase = 2.0 * np.pi * np.cumsum(bend * wobble) / RATE
    tone = np.sin(phase) + 0.3 * np.sin(2.0 * phase)
    tone *= decay(seconds, 0.13) * np.minimum(t / 0.004, 1.0)
    thump = np.sin(2.0 * np.pi * 70.0 * t) * decay(seconds, 0.025)
    return tone + thump * 0.8


def bandpass(x: np.ndarray, centre: np.ndarray, q: float) -> np.ndarray:
    """A state-variable band-pass whose centre frequency follows `centre` (Hz, per sample)."""
    y = np.zeros_like(x)
    low = band = 0.0
    for i, v in enumerate(x):
        f = 2.0 * np.sin(np.pi * min(centre[i], RATE * 0.2) / RATE)
        high = v - low - band / q
        band += f * high
        low += f * band
        y[i] = band
    return y


def whoosh() -> np.ndarray:
    seconds = 0.5
    t = t_axis(seconds)
    noise = RNG.uniform(-1.0, 1.0, len(t))
    # the filter rises from 400 Hz to 2.6 kHz and falls back, as the rush goes past
    sweep = 400.0 + 2200.0 * np.sin(np.pi * np.clip(t / seconds, 0.0, 1.0)) ** 1.5
    rush = bandpass(noise, sweep, 2.5)
    envelope = np.sin(np.pi * np.clip(t / seconds, 0.0, 1.0)) ** 0.8
    return rush * envelope


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
    save("boing", boing())
    save("whoosh", whoosh(), 0.6)


if __name__ == "__main__":
    main()
