#!/usr/bin/env python3
"""Generates the action kit's sounds (M3 Task 14b; original work, synthesised here) into assets/audio/sfx/:
foam_pop (a toy blaster's soft "pff"), paint_shot (a squishy squirt), bubble_shot (a round "bloop"),
bubble_pop (a tiny bright pop), rocket_whoosh (a fizzy toy rocket launch), confetti_boom (a party popper:
a soft pop and paper rustle), party_horn (a friendly two-note toot when a piñata floats down) and
pinata_burst (a hollow paper thump and a shower of rustles). Cartoon and gentle: nothing sounds like a
real weapon.

Run from the project root:  python3 tools/make_blaster_sfx.py   (needs numpy)
"""
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx/{}.wav"
RNG = np.random.default_rng(20260924)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def decay(n: int, rate: float) -> np.ndarray:
    return np.exp(-np.arange(n) / RATE * rate)


def lowpass(x: np.ndarray, k: int) -> np.ndarray:
    return np.convolve(x, np.ones(k) / k, mode="same")


def highpass(x: np.ndarray, k: int) -> np.ndarray:
    return x - lowpass(x, k)


def sweep(seconds: float, f0: float, f1: float) -> np.ndarray:
    tt = t(seconds)
    f = f0 + (f1 - f0) * tt / max(tt[-1], 1e-6)
    return np.sin(2 * np.pi * np.cumsum(f) / RATE)


def save(name: str, x: np.ndarray, peak: float = 0.7) -> None:
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


def foam_pop() -> np.ndarray:
    """A soft puff of air with a hollow little tone: "pff"."""
    tt = t(0.14)
    air = lowpass(RNG.standard_normal(tt.size), 6) * decay(tt.size, 38)
    tone = sweep(0.14, 420, 260) * decay(tt.size, 45) * 0.5
    return air * 0.8 + tone


def paint_shot() -> np.ndarray:
    """A wet squirt: bubbly noise through a falling tone."""
    tt = t(0.22)
    wob = 1 + 0.5 * np.sin(2 * np.pi * 38 * tt)
    wet = lowpass(RNG.standard_normal(tt.size), 10) * wob * decay(tt.size, 16)
    tone = sweep(0.22, 520, 180) * decay(tt.size, 20) * 0.4
    return wet + tone


def bubble_shot() -> np.ndarray:
    """A round "bloop": a sine that bends up."""
    tt = t(0.2)
    return sweep(0.2, 260, 720) * np.minimum(1.0, tt / 0.02) * decay(tt.size, 14)


def bubble_pop() -> np.ndarray:
    """A tiny bright pop."""
    tt = t(0.08)
    return sweep(0.08, 1500, 900) * decay(tt.size, 60) + highpass(RNG.standard_normal(tt.size), 3) * decay(tt.size, 120) * 0.3


def rocket_whoosh() -> np.ndarray:
    """A fizzy toy rocket: rising filtered noise with a sparkle."""
    tt = t(0.55)
    fizz = highpass(RNG.standard_normal(tt.size), 4) * (0.3 + 0.7 * tt / tt[-1]) * decay(tt.size, 3)
    rise = sweep(0.55, 300, 900) * decay(tt.size, 5) * 0.35
    return lowpass(fizz, 3) + rise


def confetti_boom() -> np.ndarray:
    """A party popper: a soft pop, then paper rustling down."""
    out = np.zeros(int(RATE * 0.9))
    pop = t(0.12)
    thump = np.sin(2 * np.pi * 110 * pop) * decay(pop.size, 30) + lowpass(RNG.standard_normal(pop.size), 5) * decay(pop.size, 45)
    out[:pop.size] += thump
    rus = t(0.8)
    crinkle = highpass(RNG.standard_normal(rus.size), 3) * (RNG.random(rus.size) > 0.7) * decay(rus.size, 4) * 0.35
    out[int(RATE * 0.05):int(RATE * 0.05) + rus.size] += crinkle
    return out


def party_horn() -> np.ndarray:
    """Two friendly toots, going up."""
    out = np.zeros(int(RATE * 0.5))
    for i, f in enumerate([523.0, 659.0]):
        tt = t(0.2)
        buzz = np.sign(np.sin(2 * np.pi * f * tt)) * 0.3 + np.sin(2 * np.pi * f * tt)
        env = np.minimum(1.0, tt / 0.02) * np.minimum(1.0, (tt[-1] - tt) / 0.04)
        seg = lowpass(buzz, 4) * env
        at = int(RATE * 0.22 * i)
        out[at:at + seg.size] += seg
    return out


def pinata_burst() -> np.ndarray:
    """A hollow paper thump, then a shower of rustles and a little sparkle."""
    out = np.zeros(int(RATE * 1.0))
    hit = t(0.2)
    body = np.sin(2 * np.pi * 150 * hit) * decay(hit.size, 22) + lowpass(RNG.standard_normal(hit.size), 8) * decay(hit.size, 30)
    out[:hit.size] += body
    rus = t(0.9)
    shower = highpass(RNG.standard_normal(rus.size), 3) * (RNG.random(rus.size) > 0.6) * decay(rus.size, 3.5) * 0.4
    out[int(RATE * 0.06):int(RATE * 0.06) + rus.size] += shower
    sp = t(0.3)
    sparkle = (np.sin(2 * np.pi * 1760 * sp) + np.sin(2 * np.pi * 2349 * sp)) * decay(sp.size, 12) * 0.15
    out[int(RATE * 0.1):int(RATE * 0.1) + sp.size] += sparkle
    return out


if __name__ == "__main__":
    save("foam_pop", foam_pop())
    save("paint_shot", paint_shot())
    save("bubble_shot", bubble_shot())
    save("bubble_pop", bubble_pop(), 0.6)
    save("rocket_whoosh", rocket_whoosh())
    save("confetti_boom", confetti_boom())
    save("party_horn", party_horn(), 0.6)
    save("pinata_burst", pinata_burst())
    print("action kit sounds written")
