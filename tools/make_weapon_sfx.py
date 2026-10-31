#!/usr/bin/env python3
"""Generates the weapon sound effects (M1b Task 11) as small mono WAVs: original procedural work.

swing_1/2 (sword, hammer, axe and pickaxe swings), bow (string twang), hit_1/2 (a bonk on the practice
dummy), thud (an arrow sticking into a block), smash (the hammer's ground smash), whirr (a flying
boomerang) and ding (a bullseye score).

Run from the project root:  python3 tools/make_weapon_sfx.py   (needs numpy)
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


def noise(seconds: float) -> np.ndarray:
    return RNG.uniform(-1.0, 1.0, int(RATE * seconds))


def bandpass(x: np.ndarray, centre: np.ndarray, q: float) -> np.ndarray:
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


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    a = np.exp(-2.0 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1.0 - a) * v + a * acc
        y[i] = acc
    return y


def sweep(f0: float, f1: float, seconds: float) -> np.ndarray:
    """A sine gliding from f0 to f1 (exponentially)."""
    t = t_axis(seconds)
    f = f0 * (f1 / f0) ** (t / seconds)
    return np.sin(2.0 * np.pi * np.cumsum(f) / RATE)


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


def swing(seconds: float, f0: float, f1: float) -> np.ndarray:
    t = t_axis(seconds)
    env = np.sin(np.pi * t / seconds) ** 2
    centre = f0 * (f1 / f0) ** (t / seconds)
    return bandpass(noise(seconds), centre, 3.0) * env


def bow() -> np.ndarray:
    seconds = 0.4
    period = int(RATE / 196.0)                       # Karplus-Strong string at G3
    buf = RNG.uniform(-1.0, 1.0, period)
    out = np.zeros(int(RATE * seconds))
    for i in range(len(out)):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    snap = lowpass(noise(seconds), 2500.0) * decay(seconds, 0.012)
    return out * 0.8 + snap * 1.5


def hit(f0: float) -> np.ndarray:
    seconds = 0.25
    thump = sweep(f0, f0 * 0.5, seconds) * decay(seconds, 0.05)
    straw = bandpass(noise(seconds), 1800.0, 1.5) * decay(seconds, 0.025)
    return thump + straw * 0.8


def thud() -> np.ndarray:
    seconds = 0.3
    knock = sweep(260.0, 120.0, seconds) * decay(seconds, 0.03)
    click = lowpass(noise(seconds), 4000.0) * decay(seconds, 0.004)
    t = t_axis(seconds)
    wobble = np.sin(2.0 * np.pi * 310.0 * t) * (0.5 + 0.5 * np.sin(2.0 * np.pi * 28.0 * t)) * decay(seconds, 0.08)
    return knock + click * 1.2 + wobble * 0.35


def smash() -> np.ndarray:
    seconds = 0.6
    boom = sweep(95.0, 38.0, seconds) * decay(seconds, 0.14)
    rumble = lowpass(noise(seconds), 380.0) * decay(seconds, 0.12) * 4.0
    crack = bandpass(noise(seconds), 2200.0, 1.2) * decay(seconds, 0.02)
    return boom + rumble + crack * 0.9


def whirr() -> np.ndarray:
    seconds = 0.55
    t = t_axis(seconds)
    blades = 0.55 + 0.45 * np.sin(2.0 * np.pi * 17.0 * t)
    env = np.sin(np.pi * t / seconds)
    return bandpass(noise(seconds), 900.0, 2.5) * blades * env


def ding() -> np.ndarray:
    seconds = 0.9
    t = t_axis(seconds)
    partials = [(1.0, 1.0, 0.35), (2.76, 0.45, 0.18), (5.4, 0.25, 0.08)]
    return sum(a * np.sin(2.0 * np.pi * 1320.0 * f * t) * decay(seconds, h) for f, a, h in partials)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    save("swing_1", swing(0.22, 500.0, 1700.0))
    save("swing_2", swing(0.26, 380.0, 1300.0))
    save("bow", bow())
    save("hit_1", hit(150.0))
    save("hit_2", hit(120.0))
    save("thud", thud())
    save("smash", smash(), 0.8)
    save("whirr", whirr(), 0.5)
    save("ding", ding(), 0.5)


if __name__ == "__main__":
    main()
