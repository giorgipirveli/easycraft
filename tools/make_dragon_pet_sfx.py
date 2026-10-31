#!/usr/bin/env python3
"""Generates the pet dragon's and the dragon egg's sounds (owner feedback #39) as small mono WAVs: original
procedural work, no third-party audio.

dragon_chirp_1, dragon_chirp_2: a baby dragon's chirp: a warm, slightly raspy tone that jumps up and bends down
                                again (two takes so it does not repeat), with a soft breathy puff under it.
egg_crack:                       a dragon egg hatching: three little shell cracks, then a bright rising sparkle.

Run from the project root:  python3 tools/make_dragon_pet_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(20260939)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def chirp(seconds: float, start: float, peak: float, end: float, rasp: float) -> np.ndarray:
    t = t_axis(seconds)
    u = t / seconds
    freq = np.where(u < 0.3, start + (peak - start) * (u / 0.3), peak + (end - peak) * ((u - 0.3) / 0.7))
    phase = 2.0 * np.pi * np.cumsum(freq) / RATE
    tone = np.sin(phase) + 0.35 * np.sin(2.0 * phase) + 0.12 * np.sin(3.0 * phase)
    tone *= 1.0 + rasp * np.sin(2.0 * np.pi * 38.0 * t)          # a little rasp: a dragon, not a bird
    env = np.minimum(t / 0.015, 1.0) * np.exp(-np.maximum(u - 0.45, 0.0) * 5.0)
    puff = RNG.uniform(-1.0, 1.0, len(t)) * np.exp(-t / 0.05) * 0.25
    return tone * env * 0.8 + puff


def crack(seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    return RNG.uniform(-1.0, 1.0, len(t)) * np.exp(-t / 0.012)


def egg_crack() -> np.ndarray:
    out = np.zeros(int(RATE * 1.1))
    for at in (0.0, 0.16, 0.34):
        c = crack(0.08)
        i = int(at * RATE)
        out[i:i + len(c)] += c
    t = t_axis(0.6)
    sparkle = np.zeros_like(t)
    for base in (880.0, 1318.5, 1760.0):
        freq = base * (1.0 + t)
        sparkle += np.sin(2.0 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t / 0.25)
    i = int(0.45 * RATE)
    out[i:i + len(t)] += sparkle * 0.3
    return out


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
    save("dragon_chirp_1", chirp(0.32, 620.0, 1180.0, 760.0, 0.18), 0.55)
    save("dragon_chirp_2", chirp(0.26, 700.0, 1350.0, 900.0, 0.22), 0.55)
    save("egg_crack", egg_crack(), 0.6)


if __name__ == "__main__":
    main()
