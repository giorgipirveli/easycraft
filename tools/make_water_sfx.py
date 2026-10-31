#!/usr/bin/env python3
"""Generates the water sound effects (M2 Task 14, owner feedback #17) as small mono WAVs: original
procedural work (no third-party audio).

splash_big (a jump or fall into the water), splash_small (running in, an animal), swim_1/2 (a swim
stroke), bubbles (a diver's bubbles) and step_wet_1/2 (wet footsteps and wading).

Run from the project root:  python3 tools/make_water_sfx.py   (needs numpy)
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


def noise(seconds: float) -> np.ndarray:
    return RNG.uniform(-1.0, 1.0, int(RATE * seconds))


def bandpass(x: np.ndarray, centre, q: float) -> np.ndarray:
    """Two-pole resonant band-pass whose centre frequency may change per sample."""
    centre = np.broadcast_to(centre, x.shape)
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    for i, v in enumerate(x):
        w = 2.0 * np.pi * centre[i] / RATE
        r = 1.0 - w / (2.0 * q)
        y0 = v * (1.0 - r) + 2.0 * r * np.cos(w) * y1 - r * r * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y


def lowpass(x: np.ndarray, cutoff) -> np.ndarray:
    """One-pole low-pass whose cutoff may change per sample."""
    cutoff = np.broadcast_to(cutoff, x.shape)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        a = np.exp(-2.0 * np.pi * cutoff[i] / RATE)
        acc = (1.0 - a) * v + a * acc
        y[i] = acc
    return y


def decay(seconds: float, half_life: float) -> np.ndarray:
    return 0.5 ** (t_axis(seconds) / half_life)


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


def bubble(seconds: float, at: float, f0: float, half_life: float) -> np.ndarray:
    """One bubble: a sine whose pitch rises quickly (a bubble near the surface), fading fast."""
    out = np.zeros(int(RATE * seconds))
    start = int(RATE * at)
    n = min(int(RATE * half_life * 8), len(out) - start)
    if n <= 0:
        return out
    t = np.arange(n) / RATE
    f = f0 * (1.0 + 1.8 * t / (half_life * 3.0))
    tone = np.sin(2.0 * np.pi * np.cumsum(f) / RATE) * 0.5 ** (t / half_life)
    out[start:start + n] = tone
    return out


def bubbles_between(seconds: float, count: int, t0: float, t1: float, f_lo: float, f_hi: float,
                    loud: float) -> np.ndarray:
    out = np.zeros(int(RATE * seconds))
    for _ in range(count):
        at = RNG.uniform(t0, t1)
        out += bubble(seconds, at, RNG.uniform(f_lo, f_hi), RNG.uniform(0.012, 0.03)) * RNG.uniform(0.4, 1.0) * loud
    return out


def splash(seconds: float, body: float, bright: float, n_bubbles: int) -> np.ndarray:
    t = t_axis(seconds)
    hit = lowpass(noise(seconds), bright * (0.3 + 0.7 * 0.5 ** (t / 0.08))) * decay(seconds, 0.05)
    slosh = bandpass(noise(seconds), body * (1.0 + 0.6 * np.sin(2.0 * np.pi * 7.0 * t)), 1.4) * decay(seconds, 0.14)
    tail = bubbles_between(seconds, n_bubbles, 0.05, seconds * 0.7, 350.0, 1100.0, 0.6)
    return hit * 1.4 + slosh * 1.2 + tail


def swim(seconds: float, centre: float) -> np.ndarray:
    t = t_axis(seconds)
    env = np.sin(np.pi * t / seconds) ** 1.5
    swish = bandpass(noise(seconds), centre * (0.8 + 0.4 * t / seconds), 1.8) * env
    trickle = bubbles_between(seconds, 4, seconds * 0.4, seconds * 0.9, 600.0, 1400.0, 0.25)
    return swish + trickle


def step_wet(seconds: float, cutoff: float) -> np.ndarray:
    thud = lowpass(noise(seconds), cutoff) * decay(seconds, 0.03) * 3.0
    splat = bandpass(noise(seconds), 1400.0, 1.2) * decay(seconds, 0.045)
    drops = bubbles_between(seconds, 2, 0.02, seconds * 0.6, 700.0, 1300.0, 0.3)
    return thud + splat + drops


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    save("splash_big", splash(0.9, 520.0, 5000.0, 16), 0.8)
    save("splash_small", splash(0.45, 700.0, 3800.0, 6), 0.6)
    save("swim_1", swim(0.42, 650.0), 0.45)
    save("swim_2", swim(0.48, 520.0), 0.45)
    save("bubbles", bubbles_between(0.6, 7, 0.0, 0.45, 450.0, 1200.0, 1.0), 0.5)
    save("step_wet_1", step_wet(0.22, 900.0), 0.55)
    save("step_wet_2", step_wet(0.24, 700.0), 0.55)


if __name__ == "__main__":
    main()
