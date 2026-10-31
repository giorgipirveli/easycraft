#!/usr/bin/env python3
"""Generates the cars' sounds (owner #109) as small mono WAVs: original procedural work, no third-party audio.

car_horn_small: a go-kart's and a race car's quick "meep meep" (two short bright beeps).
car_horn:       a car's two-tone horn (two detuned tones a third apart, buzzy like a reed).
car_horn_big:   a bus's and a monster truck's deep "honk".
car_start:      "vroom": an engine revving up and settling.
car_engine:     a loop (1 s, seamless): a steady engine's hum; Vehicle raises its pitch with the speed.
hover_hum:      a loop (1 s, seamless): a hover car's and a sky taxi's soft whirr of fans.

Run from the project root:  python3 tools/make_car_sfx.py   (needs numpy)
Then `godot --headless --path . --import`; the two loops' .import files say edit/loop_mode=2 (kept in git).
Deterministic (fixed seed), so re-running gives identical files.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(20261016)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def env(t: np.ndarray, attack: float, release: float, length: float) -> np.ndarray:
    a = np.clip(t / attack, 0.0, 1.0)
    r = np.clip((length - t) / release, 0.0, 1.0)
    return a * r


def buzz(freq: np.ndarray | float, t: np.ndarray, harmonics: int = 6, bright: float = 0.6) -> np.ndarray:
    """A reed-like tone: odd and even harmonics falling off (a horn's buzz)."""
    phase = 2.0 * np.pi * np.cumsum(np.broadcast_to(freq, t.shape)) / RATE
    out = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        out += np.sin(k * phase) * (bright ** (k - 1))
    return out


def beep(seconds: float, freq: float) -> np.ndarray:
    t = t_axis(seconds)
    return buzz(freq, t, 5, 0.5) * env(t, 0.008, 0.03, seconds)


def horn_small() -> np.ndarray:
    gap = np.zeros(int(RATE * 0.06))
    return np.concatenate([beep(0.13, 880.0), gap, beep(0.17, 880.0)])


def horn() -> np.ndarray:
    seconds = 0.5
    t = t_axis(seconds)
    tone = buzz(415.0, t, 7, 0.62) + buzz(523.0, t, 7, 0.62) * 0.9
    return tone * env(t, 0.012, 0.06, seconds)


def horn_big() -> np.ndarray:
    seconds = 0.75
    t = t_axis(seconds)
    wobble = 1.0 + 0.004 * np.sin(2.0 * np.pi * 5.0 * t)
    tone = buzz(196.0 * wobble, t, 9, 0.7) + buzz(247.0 * wobble, t, 9, 0.7) * 0.8
    return tone * env(t, 0.03, 0.12, seconds)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    a = np.exp(-2.0 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    prev = 0.0
    for i, v in enumerate(x):
        prev = (1.0 - a) * v + a * prev
        y[i] = prev
    return y


def start() -> np.ndarray:
    seconds = 0.95
    t = t_axis(seconds)
    rev = 55.0 + 95.0 * np.sin(np.pi * np.clip(t / 0.55, 0.0, 1.0)) ** 1.4 + 20.0 * np.clip((t - 0.55) / 0.4, 0, 1)
    engine = buzz(rev, t, 8, 0.72)
    rumble = lowpass(RNG.uniform(-1.0, 1.0, len(t)), 300.0) * 2.5
    return (engine + rumble) * env(t, 0.03, 0.2, seconds)


def loop_fade(x: np.ndarray, ms: float = 60.0) -> np.ndarray:
    """Seamless: the end crossfades into the start."""
    n = int(RATE * ms / 1000.0)
    out = x[: len(x) - n].copy()
    ramp = np.linspace(0.0, 1.0, n)
    out[:n] = x[:n] * ramp + x[len(x) - n:] * (1.0 - ramp)
    return out


def engine_loop() -> np.ndarray:
    seconds = 1.06
    t = t_axis(seconds)
    flutter = 1.0 + 0.25 * np.sin(2.0 * np.pi * 12.0 * t)   # the cylinders' firing
    tone = buzz(64.0, t, 8, 0.7) * flutter
    rumble = lowpass(RNG.uniform(-1.0, 1.0, len(t)), 220.0) * 2.0
    return loop_fade(tone + rumble)


def hover_loop() -> np.ndarray:
    seconds = 1.06
    t = t_axis(seconds)
    whirr = np.sin(2.0 * np.pi * 180.0 * t) * (0.6 + 0.4 * np.sin(2.0 * np.pi * 7.0 * t))
    air = lowpass(RNG.uniform(-1.0, 1.0, len(t)), 900.0) * 3.0
    return loop_fade(whirr * 0.5 + air)


def fade(x: np.ndarray, ms: float = 3.0) -> np.ndarray:
    n = min(int(RATE * ms / 1000.0), len(x) // 2)
    x = x.copy()
    x[:n] *= np.linspace(0.0, 1.0, n)
    x[-n:] *= np.linspace(1.0, 0.0, n)
    return x


def save(name: str, x: np.ndarray, peak: float = 0.7, edges: bool = True) -> None:
    if edges:
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
    save("car_horn_small", horn_small(), 0.6)
    save("car_horn", horn(), 0.6)
    save("car_horn_big", horn_big(), 0.65)
    save("car_start", start(), 0.6)
    save("car_engine", engine_loop(), 0.5, edges=False)
    save("hover_hum", hover_loop(), 0.4, edges=False)


if __name__ == "__main__":
    main()
