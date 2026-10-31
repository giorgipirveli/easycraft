#!/usr/bin/env python3
"""Generates the defense sounds (M2 Task 8; original work, synthesised here) into assets/audio/sfx/:
door_open (a short wooden creak and a latch click), door_close (a soft wooden knock and a click) and
spikes (a quick metal "shing" when a spike trap pops up under a monster).

Run from the project root:  python3 tools/make_defense_sfx.py   (needs numpy)
"""
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx/{}.wav"
RNG = np.random.default_rng(20260926)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def decay(n: int, rate: float) -> np.ndarray:
    return np.exp(-np.arange(n) / RATE * rate)


def lowpass(x: np.ndarray, k: int) -> np.ndarray:
    return np.convolve(x, np.ones(k) / k, mode="same")


def click(seconds: float = 0.03, pitch: float = 2400.0) -> np.ndarray:
    """A small latch: a noise tick with a bright ring."""
    tt = t(seconds)
    noise = RNG.standard_normal(tt.size) * decay(tt.size, 260)
    ring = np.sin(2 * np.pi * pitch * tt) * decay(tt.size, 120) * 0.5
    return noise * 0.6 + ring


def knock(seconds: float = 0.16, pitch: float = 120.0) -> np.ndarray:
    """A soft wooden knock: a low body tone with a dull noise hit."""
    tt = t(seconds)
    body = np.sin(2 * np.pi * pitch * tt) * decay(tt.size, 30) + 0.4 * np.sin(2 * np.pi * pitch * 2.7 * tt) * decay(tt.size, 55)
    hit = lowpass(RNG.standard_normal(tt.size), 12) * decay(tt.size, 70) * 0.8
    return body + hit


def save(name: str, x: np.ndarray, peak: float = 0.75) -> None:
    fade = min(len(x), int(RATE * 0.01))
    x = x.copy()
    x[-fade:] *= np.linspace(1, 0, fade)
    x = x / max(np.max(np.abs(x)), 1e-6) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(OUT.format(name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def door_open() -> np.ndarray:
    """The latch clicks, then a short, friendly creak (a rising, wobbling rasp)."""
    creak_t = t(0.34)
    f = 330 + 160 * creak_t / creak_t[-1] + 25 * np.sin(2 * np.pi * 7 * creak_t)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    rasp = np.sign(np.sin(phase)) * 0.35 + np.sin(phase * 2) * 0.3
    grain = 0.6 + 0.4 * (RNG.random(creak_t.size) > 0.35)   # the stick-slip of a hinge
    env = np.minimum(1.0, creak_t / 0.04) * decay(creak_t.size, 6)
    creak = lowpass(rasp * grain, 6) * env * 0.45
    out = np.zeros(int(RATE * 0.42))
    c = click(0.04, 2200.0)
    out[:c.size] += c
    out[int(RATE * 0.05):int(RATE * 0.05) + creak.size] += creak
    return out


def door_close() -> np.ndarray:
    """A soft wooden knock and the latch catching."""
    out = np.zeros(int(RATE * 0.26))
    k = knock()
    out[:k.size] += k
    c = click(0.03, 2600.0)
    at = int(RATE * 0.07)
    out[at:at + c.size] += c * 0.7
    return out


def spikes() -> np.ndarray:
    """A quick metal shing: bright partials sliding up, with a breathy start."""
    tt = t(0.3)
    f = 1800 + 900 * (1 - np.exp(-tt * 30))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    ring = sum(a * np.sin(k * phase) for k, a in ((1.0, 1.0), (1.51, 0.5), (2.23, 0.3)))
    swish = np.diff(RNG.standard_normal(tt.size + 1)) * decay(tt.size, 40) * 0.3
    return (ring * decay(tt.size, 16) + swish) * np.minimum(1.0, tt / 0.005)


if __name__ == "__main__":
    save("door_open", door_open())
    save("door_close", door_close())
    save("spikes", spikes(), 0.6)
    print("defense sounds saved: door_open, door_close, spikes")
