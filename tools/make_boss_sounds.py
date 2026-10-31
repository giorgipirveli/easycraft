#!/usr/bin/env python3
"""Generates the Stone Golem and portal sounds (M2 Task 10; original work, synthesised here) into
assets/audio/sfx/:
  golem_roar     the Golem wakes and raises its fists: a deep, rumbly (not scary) grumble
  golem_slam     the fists hit the ground: a big low boom with a rumble of pebbles
  golem_throw    a rock leaves its hand: a heavy whoosh
  golem_stomp    it paws the ground before a charge: a short thud
  rock_crash     the rock lands: a crunch of stones
  golem_crumble  the Golem is beaten: rocks tumbling down, then a bright chime
  portal_wind    the portal's desert wind (a seamless 4 s loop; imported with loop_mode forward)

Run from the project root:  python3 tools/make_boss_sounds.py   (needs numpy)
"""
import wave

import numpy as np

RATE = 22050
OUT = "assets/audio/sfx/{}.wav"
RNG = np.random.default_rng(20260926)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(RATE * seconds)) / RATE


def env(n: int, attack: float = 0.01, release: float = 0.08) -> np.ndarray:
    e = np.ones(n)
    a = max(int(RATE * attack), 1)
    r = max(int(RATE * release), 1)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def decay(n: int, rate: float) -> np.ndarray:
    return np.exp(-np.arange(n) / RATE * rate)


def tone(freqs: np.ndarray, harmonics=(1.0, 0.5, 0.25)) -> np.ndarray:
    phase = 2 * np.pi * np.cumsum(freqs) / RATE
    return sum(a * np.sin((i + 1) * phase) for i, a in enumerate(harmonics))


def lowpass(x: np.ndarray, k: int) -> np.ndarray:
    return np.convolve(x, np.ones(k) / k, mode="same")


def noise(n: int, k: int = 1) -> np.ndarray:
    x = RNG.standard_normal(n)
    return lowpass(x, k) if k > 1 else x


def pebbles(seconds: float, count: int, pitch: float = 1.0) -> np.ndarray:
    """Little stone clicks scattered over `seconds`, fewer towards the end."""
    out = np.zeros(int(RATE * seconds))
    for i in range(count):
        at = int(len(out) * (RNG.random() ** 1.6))
        n = int(RATE * 0.03)
        f = RNG.uniform(500, 1400) * pitch
        click = tone(np.full(n, f), (1.0, 0.4)) * decay(n, 120) * RNG.uniform(0.2, 0.6)
        end = min(at + n, len(out))
        out[at:end] += click[: end - at]
    return out


def save(name: str, x: np.ndarray, peak: float = 0.8) -> None:
    x = x / max(np.max(np.abs(x)), 1e-6) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(OUT.format(name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def roar() -> np.ndarray:
    tt = t(0.9)
    f = 70 + 18 * np.sin(2 * np.pi * 3.2 * tt) + 25 * np.exp(-tt * 3)
    body = tone(f, (1.0, 0.7, 0.45, 0.25))
    grit = lowpass(noise(tt.size), 12) * (0.5 + 0.5 * np.sin(2 * np.pi * 23 * tt))
    return (lowpass(body, 3) + 0.35 * grit) * env(tt.size, 0.08, 0.3)


def slam() -> np.ndarray:
    tt = t(1.1)
    boom = tone(55 * np.exp(-tt * 1.2) + 30, (1.0, 0.5)) * decay(tt.size, 4.0)
    thump = lowpass(noise(tt.size), 40) * decay(tt.size, 9.0) * 2.0
    return boom + thump + 0.5 * pebbles(1.1, 26)


def throw() -> np.ndarray:
    tt = t(0.45)
    shape = np.sin(np.pi * np.clip(tt / 0.45, 0, 1)) ** 2
    whoosh = lowpass(noise(tt.size), 10) * shape
    return whoosh + 0.25 * tone(np.linspace(180, 90, tt.size), (1.0,)) * shape


def stomp() -> np.ndarray:
    tt = t(0.3)
    return tone(np.linspace(95, 45, tt.size), (1.0, 0.4)) * decay(tt.size, 14) + \
        0.6 * lowpass(noise(tt.size), 30) * decay(tt.size, 25)


def rock_crash() -> np.ndarray:
    tt = t(0.6)
    crunch = lowpass(noise(tt.size), 6) * decay(tt.size, 10)
    return crunch + 0.8 * pebbles(0.6, 18, 1.2) + 0.5 * tone(np.full(tt.size, 70.0), (1.0,)) * decay(tt.size, 12)


def crumble() -> np.ndarray:
    tt = t(1.4)
    rumble = lowpass(noise(tt.size), 35) * decay(tt.size, 2.2)
    parts = rumble + 0.9 * pebbles(1.4, 60, 0.8)
    tc = t(0.5)
    chime = np.concatenate([np.zeros(int(RATE * 0.9)), sum(
        tone(np.full(tc.size, f), (1.0, 0.3)) * decay(tc.size, 7) * 0.4 for f in (1047.0, 1319.0, 1568.0))])
    chime = chime[: tt.size]
    return parts + np.pad(chime, (0, tt.size - chime.size))


def wind() -> np.ndarray:
    """A 4 s desert wind loop: filtered noise with slow gusts; the ends cross-fade so it loops without a click."""
    seconds = 4.0
    n = int(RATE * seconds)
    fade = int(RATE * 0.5)
    raw = noise(n + fade)
    soft = lowpass(raw, 24) * 0.8 + lowpass(raw, 6) * 0.25
    tt = np.arange(n + fade) / RATE
    gust = 0.55 + 0.3 * np.sin(2 * np.pi * tt / seconds) + 0.15 * np.sin(2 * np.pi * 3 * tt / seconds + 1.0)
    x = soft * gust
    loop = x[:n].copy()
    ramp = np.linspace(0, 1, fade)
    loop[:fade] = x[:fade] * ramp + x[n:n + fade] * (1 - ramp)
    return loop


if __name__ == "__main__":
    for name, fn, peak in [("golem_roar", roar, 0.75), ("golem_slam", slam, 0.9), ("golem_throw", throw, 0.6),
                           ("golem_stomp", stomp, 0.7), ("rock_crash", rock_crash, 0.7),
                           ("golem_crumble", crumble, 0.8), ("portal_wind", wind, 0.35)]:
        save(name, fn(), peak)
    print("BOSS sounds saved to assets/audio/sfx/golem_*.wav, rock_crash.wav and portal_wind.wav")
