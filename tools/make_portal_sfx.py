#!/usr/bin/env python3
"""Generates the portal sound (M3 Task 5) as a small mono WAV: original procedural work.

portal_whoosh: stepping through a portal: a rushing breath of noise swept up through a band-pass,
               under a shimmer of three bell-like tones gliding up an octave, fading out.

Run from the project root:  python3 tools/make_portal_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(20260925)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


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


def portal_whoosh() -> np.ndarray:
    seconds = 0.9
    t = t_axis(seconds)
    u = np.clip(t / seconds, 0.0, 1.0)
    # the rush: noise through a band-pass sweeping 300 Hz -> 3 kHz, swelling then fading
    sweep = 300.0 + 2700.0 * u ** 1.4
    rush = bandpass(RNG.uniform(-1.0, 1.0, len(t)), sweep, 3.0)
    rush *= np.sin(np.pi * u) ** 0.7
    # the shimmer: three soft tones gliding up an octave, a little apart, with a slow tremolo
    shimmer = np.zeros_like(t)
    for base, delay in ((523.25, 0.0), (659.25, 0.06), (783.99, 0.12)):
        local = np.clip(t - delay, 0.0, None)
        freq = base * (1.0 + local / seconds)
        phase = 2.0 * np.pi * np.cumsum(freq) / RATE
        env = np.where(t >= delay, np.exp(-local / 0.35) * np.minimum(local / 0.02, 1.0), 0.0)
        shimmer += np.sin(phase) * env
    shimmer *= 1.0 + 0.25 * np.sin(2.0 * np.pi * 9.0 * t)
    return rush * 1.2 + shimmer * 0.35


def fade(x: np.ndarray, ms: float = 4.0) -> np.ndarray:
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
    save("portal_whoosh", portal_whoosh(), 0.6)


if __name__ == "__main__":
    main()
