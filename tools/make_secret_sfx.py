#!/usr/bin/env python3
"""Generates the secrets' sound effects (M2 Task 16) as small mono WAVs: original procedural work.

sparkle (a find: a rising run of bells), chime (a secret is near: two soft glockenspiel notes), knock (a
hollow knock-knock, then the fake wall crumbles), chest_open (a creak and a ding), star_fall (a long
whoosh with a falling shimmer), star_land (a soft boom with bells), plate_click (a stone plate goes down)
and plate_wrong (a low clunk: the plates pop back up).

Run from the project root:  python3 tools/make_secret_sfx.py   (needs numpy)
Deterministic (fixed seed), so re-running gives identical files. Uses the helpers of make_weapon_sfx.py.
"""
import numpy as np

import make_weapon_sfx as sfx
from make_weapon_sfx import bandpass, decay, lowpass, noise, save, sweep, t_axis

sfx.RNG = np.random.default_rng(2026092416)


def bell(freq: float, seconds: float, half_life: float) -> np.ndarray:
    t = t_axis(seconds)
    partials = [(1.0, 1.0), (2.0, 0.35), (3.01, 0.18), (4.2, 0.08)]
    return sum(a * np.sin(2.0 * np.pi * freq * f * t) * decay(seconds, half_life / f ** 0.5) for f, a in partials)


def place(out: np.ndarray, x: np.ndarray, at: float) -> None:
    i = int(at * sfx.RATE)
    n = min(len(x), len(out) - i)
    out[i:i + n] += x[:n]


def sparkle() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.1))
    for k, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):          # C6 E6 G6 C7
        place(out, bell(f, 0.8, 0.18) * (0.8 + 0.1 * k), 0.07 * k)
    shimmer = bandpass(noise(1.1), 7000.0, 2.0) * decay(1.1, 0.25) * 0.25
    return out + shimmer


def chime() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.4))
    place(out, bell(783.99, 1.2, 0.35), 0.0)                            # G5
    place(out, bell(1174.66, 1.2, 0.35) * 0.9, 0.16)                    # D6
    return out


def knock() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.0))
    for at in (0.0, 0.2):
        seconds = 0.18
        body = np.sin(2.0 * np.pi * 185.0 * t_axis(seconds)) * decay(seconds, 0.025)
        hollow = bandpass(noise(seconds), 420.0, 4.0) * decay(seconds, 0.035) * 2.0
        click = lowpass(noise(seconds), 3500.0) * decay(seconds, 0.003) * 0.8
        place(out, body + hollow + click, at)
    crumble = lowpass(noise(0.55), 900.0) * decay(0.55, 0.12) * 2.5
    place(out, crumble, 0.42)
    return out


def chest_open() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.1))
    seconds = 0.4
    t = t_axis(seconds)
    creak = bandpass(noise(seconds), 380.0 + 260.0 * t / seconds, 6.0) * (0.6 + 0.4 * np.sin(2.0 * np.pi * 34.0 * t))
    creak *= np.sin(np.pi * t / seconds)
    place(out, creak * 2.0, 0.0)
    place(out, bell(1567.98, 0.7, 0.2), 0.36)
    place(out, bell(2093.0, 0.6, 0.18) * 0.8, 0.46)
    return out


def star_fall() -> np.ndarray:
    seconds = 2.2
    t = t_axis(seconds)
    swell = np.sin(np.pi * np.clip(t / seconds, 0, 1)) ** 1.5
    whoosh = bandpass(noise(seconds), 3200.0 * (0.12 ** (t / seconds)), 2.5) * swell
    shimmer = sweep(2600.0, 700.0, seconds) * swell * 0.25
    return whoosh + shimmer


def star_land() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 1.2))
    seconds = 0.6
    place(out, sweep(120.0, 40.0, seconds) * decay(seconds, 0.12) * 1.2, 0.0)
    place(out, lowpass(noise(seconds), 500.0) * decay(seconds, 0.1) * 3.0, 0.0)
    for k, f in enumerate([1318.5, 1568.0, 2093.0]):
        place(out, bell(f, 0.8, 0.2) * 0.5, 0.1 + 0.06 * k)
    return out


def plate_click() -> np.ndarray:
    seconds = 0.22
    thunk = sweep(230.0, 150.0, seconds) * decay(seconds, 0.03)
    click = bandpass(noise(seconds), 1300.0, 2.0) * decay(seconds, 0.012) * 1.5
    return thunk + click


def plate_wrong() -> np.ndarray:
    out = np.zeros(int(sfx.RATE * 0.55))
    for k, f in enumerate([180.0, 120.0]):
        seconds = 0.25
        place(out, sweep(f, f * 0.7, seconds) * decay(seconds, 0.06) + lowpass(noise(seconds), 600.0) * decay(seconds, 0.03), 0.16 * k)
    return out


def main() -> None:
    save("sparkle", sparkle(), 0.55)
    save("chime", chime(), 0.45)
    save("knock", knock(), 0.75)
    save("chest_open", chest_open(), 0.6)
    save("star_fall", star_fall(), 0.5)
    save("star_land", star_land(), 0.7)
    save("plate_click", plate_click(), 0.6)
    save("plate_wrong", plate_wrong(), 0.6)


if __name__ == "__main__":
    main()
